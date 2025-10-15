// lib/screens/admin_home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart'; // Importa o serviço

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Paleta de Cores
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color subtleLightColor = Color(0xFF4A4A58);
  static const Color darkAccentColor = Color(0xFF16213E);

  // Future para buscar os dados do gráfico
  late Future<Map<String, int>> _chartDataFuture;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Inicia a busca pelos dados assim que a tela é criada
    _chartDataFuture = DatabaseService.instance.getStudentCountByInstitution();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      drawer: _buildAppDrawer(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Olá, Administrador',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  // --- ALTERAÇÃO PRINCIPAL AQUI ---
                  child: FutureBuilder<Map<String, int>>(
                    future: _chartDataFuture,
                    builder: (context, snapshot) {
                      // Enquanto carrega
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryAccentColor,
                          ),
                        );
                      }
                      // Se deu erro
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar dados',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      // Se não há dados ou o mapa está vazio
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum aluno cadastrado para exibir no gráfico.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Se os dados chegaram
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
                          // Legendas agora são geradas dinamicamente
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

  // Função ATUALIZADA para receber os dados reais
  List<PieChartSectionData> _buildChartSections(Map<String, int> data) {
    final colorMap = {'IFSP': darkAccentColor, 'FATEC': subtleLightColor};
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
          color: colorMap[institution] ?? Colors.grey,
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

  // NOVA Função para gerar legendas dinamicamente
  Widget _buildDynamicIndicators(Map<String, int> data) {
    final colorMap = {'IFSP': darkAccentColor, 'FATEC': subtleLightColor};
    List<Widget> indicators = [];
    data.forEach((institution, count) {
      indicators.add(
        _buildIndicator(institution, colorMap[institution] ?? Colors.grey),
      );
      indicators.add(const SizedBox(width: 16));
    });
    // Remove o último SizedBox
    if (indicators.isNotEmpty) {
      indicators.removeLast();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indicators,
    );
  }

  Widget _buildIndicator(String text, Color color) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            color: backgroundColor.withAlpha(200),
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: const Text(
                    'Admin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  accountEmail: const Text(
                    'admin@smartuniway.com',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: primaryAccentColor,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(15)),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Lista de Alunos',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/student_list');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Fazer Chamada',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/attendance');
                  },
                ),
                const Divider(color: Colors.white30, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Meu Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    final mockAdmin = User(
                      name: 'Admin',
                      surname: 'Master',
                      email: 'admin@smartuniway.com',
                      phone: '(17) 00000-0000',
                      password: 'admin',
                      userType: UserType.admin,
                    );
                    Navigator.pushNamed(
                      context,
                      '/profile',
                      arguments: mockAdmin,
                    );
                  },
                ),
                const Spacer(),
                const Divider(color: Colors.white30, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
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
      ),
    );
  }
}
