import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
        final formattedDate = DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(date);
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
      final output = await getTemporaryDirectory();
      final fileName = 'relatorio_${institution.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('📄 PDF salvo em: ${file.path}');
      
      // Abre o PDF
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('❌ Erro ao salvar/abrir PDF: $e');
      rethrow;
    }
  }
}