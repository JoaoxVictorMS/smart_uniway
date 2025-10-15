// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_uniway/services/database_service.dart';

class ReportScreen extends StatefulWidget {
  final String institution;

  const ReportScreen({super.key, required this.institution});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Future<Map<String, Map<String, int>>> _reportFuture;

  // Paleta de Cores
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color presentColor = Colors.green;
  static const Color absentColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _reportFuture = DatabaseService.instance.getAttendanceReport(
      widget.institution,
      7,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Relatório de ${widget.institution}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/noise_texture.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FutureBuilder<Map<String, Map<String, int>>>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryAccentColor),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum dado de chamada encontrado para gerar o relatório.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final reportData = snapshot.data!;
                return Column(
                  children: [
                    Text(
                      'Frequência nos últimos 7 dias',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(reportData),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    _bottomTitles(value, meta, reportData),
                                reservedSize: 38,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: _leftTitles,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _generateBarGroups(reportData),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildIndicators(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(Map<String, Map<String, int>> data) {
    double maxY = 0;
    data.forEach((date, status) {
      final total = (status['present'] ?? 0) + (status['absent'] ?? 0);
      if (total > maxY) {
        maxY = total.toDouble();
      }
    });
    return (maxY * 1.2).ceilToDouble() < 5 ? 5 : (maxY * 1.2).ceilToDouble();
  }

  // CORREÇÃO DEFINITIVA AQUI
  Widget _leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white70, fontSize: 12);
    // Não mostramos todos os valores para não poluir o eixo
    if (value % 2 != 0 && value != 1 && value != meta.max) {
      return const Text('');
    }
    return Text(
      value.toInt().toString(),
      style: style,
      textAlign: TextAlign.right,
    );
  }

  // CORREÇÃO DEFINITIVA AQUI
  Widget _bottomTitles(
    double value,
    TitleMeta meta,
    Map<String, Map<String, int>> data,
  ) {
    final sortedDates = data.keys.toList()..sort();
    const style = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    if (value.toInt() >= sortedDates.length) {
      return const Text('');
    }

    final dateString = sortedDates[value.toInt()];
    final date = DateTime.parse(dateString);
    final formattedDate = DateFormat('dd/MM').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(formattedDate, style: style),
    );
  }

  List<BarChartGroupData> _generateBarGroups(
    Map<String, Map<String, int>> data,
  ) {
    final sortedDates = data.keys.toList()..sort();
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final dateString = sortedDates[i];
      final presentCount = data[dateString]?['present']?.toDouble() ?? 0;
      final absentCount = data[dateString]?['absent']?.toDouble() ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: presentCount,
              color: presentColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: absentCount,
              color: absentColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicator('Presentes', presentColor),
        const SizedBox(width: 24),
        _buildIndicator('Ausentes', absentColor),
      ],
    );
  }

  Widget _buildIndicator(String text, Color color) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }
}
