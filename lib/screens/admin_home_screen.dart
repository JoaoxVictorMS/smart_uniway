// lib/screens/admin_home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_uniway/models/user_model.dart';

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

  int touchedIndex = -1;

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
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
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
                      sections: _buildChartSections(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIndicator('IFSP', darkAccentColor),
                    const SizedBox(width: 16),
                    _buildIndicator('FATEC', subtleLightColor),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    final isTouchedIFSP = touchedIndex == 0;
    final isTouchedFATEC = touchedIndex == 1;
    final fontSize = isTouchedIFSP || isTouchedFATEC ? 20.0 : 16.0;
    final radius = isTouchedIFSP || isTouchedFATEC ? 110.0 : 100.0;
    final titleStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xffffffff),
      shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
    );

    return [
      PieChartSectionData(
        color: darkAccentColor,
        value: 65,
        title: '65%',
        radius: isTouchedIFSP ? radius : 100.0,
        titleStyle: titleStyle,
      ),
      PieChartSectionData(
        color: subtleLightColor,
        value: 35,
        title: '35%',
        radius: isTouchedFATEC ? radius : 100.0,
        titleStyle: titleStyle,
      ),
    ];
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
                    Navigator.pop(context); // Fecha o menu primeiro
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
                    Navigator.pop(context); // Fecha o menu primeiro
                    Navigator.pushNamed(context, '/attendance');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.bar_chart_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Gerar Relatório',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
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
                    // LÓGICA DE NAVEGAÇÃO PARA O PERFIL
                    final mockAdmin = User(
                      name: 'Admin',
                      surname: 'Master',
                      email: 'admin@smartuniway.com',
                      phone: '(17) 00000-0000',
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
                    // LÓGICA DE LOGOUT
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
