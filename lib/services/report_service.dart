import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportService {
  /// Gera um PDF com o relatório de presença por instituição
  static Future<void> generateAttendancePdf(
    String institution,
    Map<String, Map<String, int>> reportData,
  ) async {
    final pdf = pw.Document();

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
        header: (context) => _buildHeader(institution),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(totalPresent, totalAbsent, presenceRate),
          pw.SizedBox(height: 20),
          _buildDataTable(sortedDates, reportData),
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
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(globalPresent, globalAbsent, presenceRate),
          pw.SizedBox(height: 20),
          // Tabela por instituição
          ...reportData.entries.map((entry) {
            final institution = entry.key;
            final dates = entry.value;
            final sortedDates = dates.keys.toList()..sort();
            
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
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#9D84B7'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        institution,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Presenças: $instPresent | Faltas: $instAbsent',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildGlobalDataTable(sortedDates, dates),
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
                    color: PdfColor.fromHex('#9D84B7'),
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
        pw.Divider(color: PdfColor.fromHex('#9D84B7'), thickness: 2),
      ],
    );
  }

  static pw.Widget _buildGlobalDataTable(
    List<String> sortedDates,
    Map<String, Map<String, int>> dateData,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey700,
      ),
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

  static pw.Widget _buildHeader(String institution) {
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
                    color: PdfColor.fromHex('#9D84B7'),
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
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Instituição: $institution',
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
        pw.Divider(color: PdfColor.fromHex('#9D84B7'), thickness: 2),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Smart UniWay - Sistema de Transporte Universitário',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
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
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Presenças', '$totalPresent', PdfColors.green),
          _buildSummaryItem('Total Faltas', '$totalAbsent', PdfColors.red),
          _buildSummaryItem('Taxa de Presença', '$presenceRate%', PdfColor.fromHex('#9D84B7')),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
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
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable(
    List<String> sortedDates,
    Map<String, Map<String, int>> reportData,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#9D84B7'),
      ),
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

  static Future<void> _saveAndOpenPdf(pw.Document pdf, String institution) async {
    try {
      debugPrint('📄 Iniciando salvamento do PDF...');
      final output = await getTemporaryDirectory();
      debugPrint('📄 Diretório: ${output.path}');
      
      final fileName = 'relatorio_${institution.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Relatório Smart UniWay',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao salvar/abrir PDF: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }
}