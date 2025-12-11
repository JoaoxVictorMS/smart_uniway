import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportService {
  // Mapa de cores por instituição (cores prioritárias reais)
  static final Map<String, PdfColor> institutionColors = {
    'IFSP': PdfColor.fromHex('#2E7D32'), // Verde
    'CETEC': PdfColor.fromHex('#1565C0'), // Azul
    'FATEC': PdfColor.fromHex('#616161'), // Cinza
    'UNIFIPA': PdfColor.fromHex('#0D47A1'), // Azul
    'ETEC': PdfColor.fromHex('#757575'), // Cinza
    'IMES': PdfColor.fromHex('#C62828'), // Vermelho (cor principal)
  };

  // URLs das logos das instituições (PNG sem fundo)
  static final Map<String, String> institutionLogoUrls = {
    'IFSP':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Logotipo_IFSP.svg/200px-Logotipo_IFSP.svg.png',
    'CETEC': 'https://www.catanduva.sp.gov.br/portal/servicos/266/cetec-1.png',
    'FATEC':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/FATEC.svg/200px-FATEC.svg.png',
    'UNIFIPA':
        'https://unifipa.com.br/wp-content/uploads/2023/03/logo-unifipa-azul.png',
    'ETEC':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Logo_ETEC.svg/200px-Logo_ETEC.svg.png',
    'IMES': 'https://imes.edu.br/wp-content/uploads/2020/05/logo-imes.png',
  };

  // Cor padrão (roxo do app)
  static final PdfColor defaultColor = PdfColor.fromHex('#9D84B7');

  // Cache de logos carregadas
  static final Map<String, Uint8List?> _logoCache = {};

  // Obtém a cor da instituição
  static PdfColor getInstitutionColor(String institution) {
    return institutionColors[institution.toUpperCase()] ?? defaultColor;
  }

  // Carrega a logo da instituição via web
  static Future<pw.ImageProvider?> _loadInstitutionLogo(
    String institution,
  ) async {
    try {
      final upperInst = institution.toUpperCase();

      // Verifica cache
      if (_logoCache.containsKey(upperInst)) {
        final cached = _logoCache[upperInst];
        if (cached != null) {
          return pw.MemoryImage(cached);
        }
        return null;
      }

      final logoUrl = institutionLogoUrls[upperInst];
      if (logoUrl == null) {
        _logoCache[upperInst] = null;
        return null;
      }

      debugPrint('🖼️ Baixando logo de $institution: $logoUrl');

      final response = await http
          .get(
            Uri.parse(logoUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _logoCache[upperInst] = bytes;
        debugPrint('✅ Logo de $institution carregada (${bytes.length} bytes)');
        return pw.MemoryImage(bytes);
      } else {
        debugPrint(
          '⚠️ Erro ao baixar logo de $institution: ${response.statusCode}',
        );
        _logoCache[upperInst] = null;
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar logo de $institution: $e');
      _logoCache[institution.toUpperCase()] = null;
      return null;
    }
  }

  /// Gera um PDF com o relatório de presença por instituição
  static Future<void> generateAttendancePdf(
    String institution,
    Map<String, Map<String, int>> reportData,
  ) async {
    final pdf = pw.Document();
    final color = getInstitutionColor(institution);
    final logo = await _loadInstitutionLogo(institution);

    // Ordena as datas
    final sortedDates = reportData.keys.toList()..sort();

    // Calcula totais
    int totalPresent = 0;
    int totalAbsent = 0;
    for (var dateData in reportData.values) {
      totalPresent += dateData['present'] ?? 0;
      totalAbsent += dateData['absent'] ?? 0;
    }
    final totalRecords = totalPresent + totalAbsent;
    final presenceRate = totalRecords > 0
        ? (totalPresent / totalRecords * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(institution, color, logo),
        footer: (context) => _buildFooter(context, color),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(totalPresent, totalAbsent, presenceRate, color),
          pw.SizedBox(height: 20),
          _buildDataTable(sortedDates, reportData, color),
        ],
      ),
    );

    // Salva o arquivo
    await _saveAndOpenPdf(pdf, institution);
  }

  /// Gera um PDF com o relatório GLOBAL de todas as instituições
  static Future<void> generateGlobalAttendancePdf(
    Map<String, Map<String, Map<String, int>>> reportData,
  ) async {
    final pdf = pw.Document();

    // Pré-carrega todas as logos
    final Map<String, pw.ImageProvider?> logos = {};
    for (var institution in reportData.keys) {
      logos[institution] = await _loadInstitutionLogo(institution);
    }

    // Calcula totais globais
    int globalPresent = 0;
    int globalAbsent = 0;

    reportData.forEach((institution, dates) {
      dates.forEach((date, status) {
        globalPresent += status['present'] ?? 0;
        globalAbsent += status['absent'] ?? 0;
      });
    });

    final totalRecords = globalPresent + globalAbsent;
    final presenceRate = totalRecords > 0
        ? (globalPresent / totalRecords * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildGlobalHeader(),
        footer: (context) => _buildFooter(context, defaultColor),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(
            globalPresent,
            globalAbsent,
            presenceRate,
            defaultColor,
          ),
          pw.SizedBox(height: 20),
          // Tabela por instituição
          ...reportData.entries.map((entry) {
            final institution = entry.key;
            final dates = entry.value;
            final sortedDates = dates.keys.toList()..sort();
            final color = getInstitutionColor(institution);
            final logo = logos[institution];

            // Calcula totais da instituição
            int instPresent = 0;
            int instAbsent = 0;
            dates.forEach((date, status) {
              instPresent += status['present'] ?? 0;
              instAbsent += status['absent'] ?? 0;
            });

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInstitutionHeader(
                  institution,
                  instPresent,
                  instAbsent,
                  color,
                  logo,
                ),
                pw.SizedBox(height: 8),
                _buildGlobalDataTable(sortedDates, dates, color),
                pw.SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );

    // Salva o arquivo
    await _saveAndOpenPdf(pdf, 'global');
  }

  // Header da instituição no relatório global
  static pw.Widget _buildInstitutionHeader(
    String institution,
    int present,
    int absent,
    PdfColor color,
    pw.ImageProvider? logo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          // Logo da instituição
          if (logo != null) ...[
            pw.Container(
              width: 30,
              height: 30,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              padding: const pw.EdgeInsets.all(2),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 10),
          ] else ...[
            // Placeholder se não tiver logo
            pw.Container(
              width: 30,
              height: 30,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  institution[0],
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 10),
          ],
          // Nome da instituição
          pw.Expanded(
            child: pw.Text(
              institution,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          // Estatísticas
          pw.Text(
            'Presenças: $present | Faltas: $absent',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGlobalHeader() {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Smart UniWay',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: defaultColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Relatório Global de Presença (30 dias)',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Todas as Instituições',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Gerado em: $formattedDate',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: defaultColor, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildGlobalDataTable(
    List<String> sortedDates,
    Map<String, Map<String, int>> dateData,
    PdfColor color,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: pw.BoxDecoration(color: color.shade(0.2)),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerHeight: 28,
      cellHeight: 24,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['Data', 'Presenças', 'Faltas', 'Total'],
      data: sortedDates.map((dateString) {
        final date = DateTime.parse(dateString);
        final formattedDate = DateFormat('dd/MM/yyyy').format(date);
        final present = dateData[dateString]?['present'] ?? 0;
        final absent = dateData[dateString]?['absent'] ?? 0;
        final total = present + absent;

        return [
          formattedDate,
          present.toString(),
          absent.toString(),
          total.toString(),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildHeader(
    String institution,
    PdfColor color,
    pw.ImageProvider? logo,
  ) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                // Logo da instituição
                if (logo != null) ...[
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: color, width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                ] else ...[
                  // Placeholder com inicial
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        institution[0],
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      institution,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: color,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Relatório de Presença',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Smart UniWay',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: defaultColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Gerado em: $formattedDate',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: color, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor color) {
    return pw.Column(
      children: [
        pw.Divider(color: color.shade(0.5)),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Smart UniWay - Sistema de Transporte Universitário',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    int totalPresent,
    int totalAbsent,
    String presenceRate,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Presenças',
            '$totalPresent',
            PdfColors.green,
          ),
          _buildSummaryItem('Total Faltas', '$totalAbsent', PdfColors.red),
          _buildSummaryItem('Taxa de Presença', '$presenceRate%', color),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable(
    List<String> sortedDates,
    Map<String, Map<String, int>> reportData,
    PdfColor color,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: color),
      headerHeight: 35,
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['Data', 'Presenças', 'Faltas', 'Total'],
      data: sortedDates.map((dateString) {
        final date = DateTime.parse(dateString);
        final formattedDate = DateFormat('dd/MM/yyyy').format(date);
        final present = reportData[dateString]?['present'] ?? 0;
        final absent = reportData[dateString]?['absent'] ?? 0;
        final total = present + absent;

        return [
          formattedDate,
          present.toString(),
          absent.toString(),
          total.toString(),
        ];
      }).toList(),
    );
  }

  static Future<void> _saveAndOpenPdf(
    pw.Document pdf,
    String institution,
  ) async {
    try {
      debugPrint('📄 Iniciando salvamento do PDF...');
      final output = await getTemporaryDirectory();
      debugPrint('📄 Diretório: ${output.path}');

      final fileName =
          'relatorio_${institution.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');

      debugPrint('📄 Gerando bytes do PDF...');
      final bytes = await pdf.save();
      debugPrint('📄 Bytes gerados: ${bytes.length}');

      await file.writeAsBytes(bytes);
      debugPrint('📄 PDF salvo em: ${file.path}');

      // Tenta abrir o PDF
      debugPrint('📄 Abrindo PDF...');
      final result = await OpenFilex.open(file.path);
      debugPrint('📄 Resultado: ${result.type} - ${result.message}');

      // Se não conseguiu abrir, compartilha
      if (result.type != ResultType.done) {
        debugPrint('📄 Abrindo compartilhamento...');
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Relatório Smart UniWay');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao salvar/abrir PDF: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }
}
