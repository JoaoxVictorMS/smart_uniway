// lib/screens/report_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/services/report_service.dart';

class ReportScreen extends StatefulWidget {
  final String institution;
  const ReportScreen({super.key, required this.institution});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // O Future agora começa nulo e só é chamado após clicar em "Gerar"
  Future<Map<String, Map<String, int>>>? _reportFuture;
  bool _isGeneratingPdf = false;

  // Estados para as datas selecionadas
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color presentColor = Colors.green;
  static const Color absentColor = Colors.red;

  // Função chamada para buscar os dados
  void _fetchReport() {
    setState(() {
      _reportFuture = DatabaseService.instance.getAttendanceReport(
        widget.institution,
        _startDate,
        _endDate,
      );
    });
  }

  // Função para abrir o seletor de data
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleExportPdf() async {
    if (_reportFuture == null) {
      _showFeedbackSnackBar(
        'Gere um relatório antes de exportar.',
        isError: true,
      );
      return;
    }
    setState(() {
      _isGeneratingPdf = true;
    });
    try {
      final reportData = await _reportFuture!;
      if (reportData.isEmpty) {
        _showFeedbackSnackBar('Não há dados para exportar.', isError: true);
        return;
      }
      await ReportService.generateAttendancePdf(widget.institution, reportData);
    } catch (e) {
      _showFeedbackSnackBar('Erro ao gerar o relatório em PDF.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de ${widget.institution}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isGeneratingPdf
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 28),
                    onPressed: _handleExportPdf,
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isDark)
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // --- NOVOS SELETORES DE DATA ---
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        context,
                        'Data Início',
                        _startDate,
                        () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateButton(
                        context,
                        'Data Fim',
                        _endDate,
                        () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGlassButton(
                  onPressed: _fetchReport, // Botão para acionar a busca
                  text: 'Gerar Relatório',
                  isPrimary: true,
                ),
                const SizedBox(height: 24),

                // --- GRÁFICO AGORA DENTRO DO EXPANDED ---
                Expanded(
                  child: _reportFuture == null
                      ? const Center(
                          child: Text(
                            'Selecione um intervalo de datas.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : FutureBuilder<Map<String, Map<String, int>>>(
                          future: _reportFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: primaryAccentColor,
                                ),
                              );
                            }
                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nenhum dado encontrado para este período.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            final reportData = snapshot.data!;
                            return Column(
                              children: [
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
                                                _bottomTitles(
                                                  value,
                                                  meta,
                                                  reportData,
                                                ),
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
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NOVA FUNÇÃO HELPER ---
  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onPressed,
  ) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(51)
                : Colors.black.withAlpha(20),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: themeColors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(
                color: themeColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNÇÃO HELPER COPIADA DA TELA DE PERFIL ---
  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String text,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10.0 : 0.0,
          sigmaY: isDark ? 10.0 : 0.0,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? themeColors.primary.withAlpha(200)
                : (isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(5)),
            foregroundColor: isPrimary ? Colors.black : themeColors.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPrimary
                    ? themeColors.primary
                    : (isDark
                          ? Colors.white.withAlpha(51)
                          : Colors.black.withAlpha(20)),
                width: 1.5,
              ),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

  Widget _leftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      fontSize: 12,
    );
    if (value % 2 != 0 && value != 1 && value != meta.max) {
      return const Text('');
    }
    return Text(
      value.toInt().toString(),
      style: style,
      textAlign: TextAlign.right,
    );
  }

  Widget _bottomTitles(
    double value,
    TitleMeta meta,
    Map<String, Map<String, int>> data,
  ) {
    final sortedDates = data.keys.toList()..sort();
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
