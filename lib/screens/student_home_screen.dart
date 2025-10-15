import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/auth_provider.dart'; // Importa o AuthProvider

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);

  @override
  Widget build(BuildContext context) {
    // --- ALTERAÇÃO PRINCIPAL AQUI ---
    // Busca os dados do usuário logado através do AuthProvider
    final user = AuthProvider.of(context)?.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      // Passa os dados do usuário para o Drawer
      drawer: _buildAppDrawer(context, user),
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
          Center(
            // Exibe o nome real do usuário
            child: Text(
              'Bem vindo, ${user?.name ?? 'estudante'}.',
              style: const TextStyle(
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

  Widget _buildAppDrawer(BuildContext context, User? user) {
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
                if (user != null) // Só mostra o cabeçalho se o usuário existir
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      '${user.name} ${user.surname}', // Usa o nome real
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    accountEmail: Text(
                      user.email,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ), // Usa o email real
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: primaryAccentColor,
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
                      color: Colors.white.withAlpha(15),
                    ),
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
                    if (user != null) {
                      Navigator.pop(context); // Fecha o menu
                      Navigator.pushNamed(context, '/profile', arguments: user);
                    }
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
