// lib/screens/profile_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart'; // Importa nosso modelo

class ProfileScreen extends StatefulWidget {
  final User user; // A tela recebe um objeto User para saber quem exibir

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Paleta de Cores
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
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
          // Textura de fundo
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/noise_texture.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryAccentColor,
                      // Lógica para mostrar foto ou ícone
                      child: widget.user.userType == UserType.admin
                          ? const Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: Colors.black,
                            )
                          : Text(
                              '${widget.user.name[0]}${widget.user.surname[0]}',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${widget.user.name} ${widget.user.surname}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Campos de texto com os dados do usuário
                  _buildProfileInfoField(
                    label: 'Nome',
                    value: widget.user.name,
                  ),
                  _buildProfileInfoField(
                    label: 'Sobrenome',
                    value: widget.user.surname,
                  ),
                  _buildProfileInfoField(
                    label: 'Telefone',
                    value: widget.user.phone,
                  ),

                  // --- LÓGICA CONDICIONAL ---
                  // Mostra campos extras apenas se o usuário for um estudante
                  if (widget.user.userType == UserType.student) ...[
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    _buildProfileInfoField(
                      label: 'Instituição',
                      value: widget.user.institution ?? 'N/A',
                    ),
                    _buildProfileInfoField(
                      label: 'Curso',
                      value: widget.user.course ?? 'N/A',
                    ),
                    _buildProfileInfoField(
                      label: 'Matrícula',
                      value: widget.user.registrationNumber ?? 'N/A',
                    ),
                    _buildProfileInfoField(
                      label: 'Rota',
                      value: widget.user.route ?? 'N/A',
                    ),
                    _buildProfileInfoField(
                      label: 'Período',
                      value: widget.user.period ?? 'N/A',
                    ),
                  ],

                  const SizedBox(height: 40),
                  _buildGlassButton(
                    onPressed: () {
                      /* TODO: Lógica para salvar */
                    },
                    text: 'Salvar Alterações',
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNÇÕES HELPER ---

  Widget _buildProfileInfoField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Copie esta função da sua welcome_screen para cá
  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required String text,
    bool isPrimary = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? const Color.fromARGB(255, 157, 132, 183).withAlpha(200)
                : Colors.white.withAlpha(26),
            foregroundColor: isPrimary
                ? const Color.fromARGB(255, 255, 255, 255)
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPrimary
                    ? const Color.fromARGB(255, 157, 132, 183)
                    : Colors.white.withAlpha(51),
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
}
