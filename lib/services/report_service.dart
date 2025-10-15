// lib/services/report_service.dart

import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateAttendancePdf(
    String institution,
    Map<String, Map<String, int>> reportData,
  ) async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final headers = ['Data', 'Presentes', 'Ausentes', 'Total'];
    final List<List<String>> data = [];

    reportData.forEach((date, status) {
      final formattedDate = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.parse(date));
      final present = status['present'] ?? 0;
      final absent = status['absent'] ?? 0;
      final total = present + absent;
      data.add([
        formattedDate,
        present.toString(),
        absent.toString(),
        total.toString(),
      ]);
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Relatório de Presença - Smart Uniway',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Gerado em: $today'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Instituição: $institution',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // CORRIGIDO: Usando TableHelper.fromTextArray
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/relatorio_presenca.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }
}
