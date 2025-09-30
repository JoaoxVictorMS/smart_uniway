// lib/screens/student_home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  // Paleta de Cores herdada do tema
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);

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
          const Center(
            child: Text(
              'Bem vindo, estudante.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
                    'João Victor Santos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  accountEmail: const Text(
                    'joao.santos@email.com',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=joao',
                    ),
                  ),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(15)),
                ),
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
                    final mockStudent = User(
                      name: 'João Victor',
                      surname: 'Santos',
                      email: 'joao.santos@email.com',
                      phone: '(17) 99999-9999',
                      userType: UserType.student,
                      institution: 'IFSP',
                      course: 'Análise e Desenv. de Sistemas',
                      registrationNumber: 'SP123456',
                      route: 'Rota 1',
                      period: 'Noturno',
                    );
                    Navigator.pushNamed(
                      context,
                      '/profile',
                      arguments: mockStudent,
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
