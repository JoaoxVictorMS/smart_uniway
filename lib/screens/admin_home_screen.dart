// lib/screens/admin_home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/auth_provider.dart';
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/services/report_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);

  // Cores do Gráfico
  static const Color ifspColor = Color(0xFFD94E4E);
  static const Color cetecColor = Color(0xFF4ECFD9);
  static const Color fatecColor = Color(0xFF4ED964);
  static const Color unifipaColor = Color(0xFFD9D34E);
  static const Color etecColor = Color(0xFFD97F4E);
  static const Color imesColor = Color(0xFF8A4ED9);
  static const Color otherColor = Color(0xFF9E9E9E);

  late Future<Map<String, int>> _chartDataFuture;
  int touchedIndex = -1;

  // --- VARIÁVEL QUE FALTAVA ---
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = DatabaseService.instance.getStudentCountByInstitution();
  }

  Map<String, Color> get institutionColorMap => {
    'IFSP': ifspColor,
    'CETEC': cetecColor,
    'FATEC': fatecColor,
    'UNIFIPA': unifipaColor,
    'ETEC': etecColor,
    'IMES': imesColor,
  };

  Future<void> _handleGlobalReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    try {
      final reportData = await DatabaseService.instance
          .getGlobalAttendanceReport(startDate, endDate);

      if (reportData.isEmpty && mounted) {
        _showFeedbackSnackBar(
          'Não há dados de chamada para gerar o relatório.',
          isError: true,
        );
        setState(() {
          _isGeneratingReport = false;
        });
        return;
      }

      await ReportService.generateGlobalAttendancePdf(reportData);
    } catch (e) {
      _showFeedbackSnackBar('Erro ao gerar o relatório.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
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
    final user = AuthProvider.of(context)?.user;
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeColors.onSurface,
          size: 28,
        ), // Corrigido para tema
      ),
      drawer: _buildAppDrawer(context, user),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Olá, ${user?.name ?? 'Administrador'}!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeColors.onSurface,
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: FutureBuilder<Map<String, int>>(
                    future: _chartDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: themeColors.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum aluno cadastrado.',
                            style: TextStyle(
                              color: themeColors.onSurface.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final chartData = snapshot.data!;
                      return Column(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection ==
                                                  null) {
                                            touchedIndex = -1;
                                            return;
                                          }
                                          touchedIndex = pieTouchResponse
                                              .touchedSection!
                                              .touchedSectionIndex;
                                        });
                                      },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                sections: _buildChartSections(chartData),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDynamicIndicators(chartData),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> data) {
    final totalStudents = data.values.fold(0, (sum, count) => sum + count);
    if (totalStudents == 0) return [];
    List<PieChartSectionData> sections = [];
    int index = 0;
    data.forEach((institution, count) {
      final isTouched = touchedIndex == index;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final percentage = (count / totalStudents) * 100;
      sections.add(
        PieChartSectionData(
          color: institutionColorMap[institution] ?? otherColor,
          value: percentage,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
      index++;
    });
    return sections;
  }

  Widget _buildDynamicIndicators(Map<String, int> data) {
    final themeColors = Theme.of(context).colorScheme;
    List<Widget> indicators = [];
    data.forEach((institution, count) {
      indicators.add(
        _buildIndicator(
          institution,
          institutionColorMap[institution] ?? otherColor,
          themeColors.onSurface,
        ),
      );
    });
    // Usa Wrap para quebrar a linha se não houver espaço
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.0,
      runSpacing: 8.0,
      children: indicators,
    );
  }

  Widget _buildIndicator(String text, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAppDrawer(BuildContext context, User? user) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final drawerBackgroundColor = isDark
        ? backgroundColor.withAlpha(200)
        : themeColors.surface.withAlpha(240); // Corrigido para modo claro

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          backgroundColor: drawerBackgroundColor,
          child: Column(
            children: [
              if (user != null)
                UserAccountsDrawerHeader(
                  accountName: Text(
                    '${user.name} ${user.surname}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: themeColors.onSurface,
                    ),
                  ),
                  accountEmail: Text(
                    user.email,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: themeColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: themeColors.primary,
                    child: Text(
                      '${user.name[0]}${user.surname[0]}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.onSurface.withAlpha(15),
                  ),
                ),
              ListTile(
                leading: Icon(
                  Icons.people_outline,
                  color: themeColors.onSurface,
                ),
                title: Text(
                  'Lista de Alunos',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/student_list');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.fact_check_outlined,
                  color: themeColors.onSurface,
                ),
                title: Text(
                  'Fazer Chamada',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/attendance');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.bar_chart_outlined,
                  color: themeColors.onSurface,
                ),
                title: Text(
                  'Relatório por Instituição',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/report');
                },
              ),
              ListTile(
                leading: _isGeneratingReport
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: themeColors.onSurface,
                        ),
                      )
                    : Icon(
                        Icons.picture_as_pdf_outlined,
                        color: themeColors.onSurface,
                      ),
                title: Text(
                  'Gerar PDF Global (30 dias)',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: _isGeneratingReport ? null : _handleGlobalReport,
              ),

              Divider(
                color: themeColors.onSurface.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: themeColors.onSurface,
                ),
                title: Text(
                  'Meu Perfil',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  if (user != null) {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile', arguments: user);
                  }
                },
              ),
              const Spacer(),
              Divider(
                color: themeColors.onSurface.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: Icon(Icons.logout, color: themeColors.onSurface),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: themeColors.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
