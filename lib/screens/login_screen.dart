// lib/screens/login_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;

  bool _isPasswordVisible = false;

  // Paleta de Cores Corporativa
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color subtleLightColor = Color(0xFF4A4A58);
  static const Color darkAccentColor = Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _animationBlob1 =
        Tween<Offset>(
          begin: const Offset(-0.2, -0.8),
          end: const Offset(0.2, 0.8),
        ).animate(
          CurvedAnimation(parent: _auroraController, curve: Curves.easeInOut),
        );

    _animationBlob2 = Tween<Offset>(
      begin: const Offset(1.2, 0.3),
      end: const Offset(-1.2, -0.3),
    ).animate(CurvedAnimation(parent: _auroraController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          backgroundColor, // Pode ser a cor de fundo para evitar piscar
      body: Stack(
        children: [
          // FUNDO ANIMADO
          SlideTransition(
            position: _animationBlob1,
            child: _buildAuroraBlob(
              color: darkAccentColor,
              width: size.width * 1.5,
            ),
          ),
          SlideTransition(
            position: _animationBlob2,
            child: _buildAuroraBlob(color: subtleLightColor, width: size.width),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/noise_texture.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // CONTEÚDO DO LOGIN
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      'Bem-vindo de volta.',
                      style: _getTextStyle(isTitle: true, fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para continuar.',
                      style: _getTextStyle(fontSize: 16, alpha: 179),
                    ),
                    const SizedBox(height: 48),
                    _buildTextField(
                      hintText: 'Email Institucional',
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      hintText: 'Senha',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Esqueceu a senha?',
                          style: _getTextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGlassButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/student_home',
                        );
                      },
                      text: 'Entrar',
                      isPrimary: true,
                    ),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildSocialButton(),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
          // Botão de voltar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNÇÕES HELPER ---

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          obscureText: isPassword ? !_isPasswordVisible : false,
          style: _getTextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _getTextStyle(alpha: 150),
            filled: true,
            fillColor: Colors.white.withAlpha(26),
            prefixIcon: Icon(icon, color: Colors.white.withAlpha(179)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withAlpha(179),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primaryAccentColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withAlpha(77))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('OU', style: _getTextStyle(alpha: 179)),
        ),
        Expanded(child: Divider(color: Colors.white.withAlpha(77))),
      ],
    );
  }

  Widget _buildSocialButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.white.withAlpha(77)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          icon: const FaIcon(
            FontAwesomeIcons.google,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            'Entrar com Google',
            style: _getTextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  TextStyle _getTextStyle({
    bool isTitle = false,
    double fontSize = 15,
    int alpha = 255,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      color: color ?? Colors.white.withAlpha(alpha),
      fontSize: fontSize,
      fontWeight: isTitle ? FontWeight.bold : fontWeight,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: const Color.fromARGB(255, 255, 255, 255).withAlpha(77),
          offset: const Offset(2.0, 2.0),
        ),
      ],
    );
  }

  Widget _buildAuroraBlob({required Color color, required double width}) {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120.0, sigmaY: 120.0),
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
      ),
    );
  }

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
                    ? const Color.fromARGB(7, 6, 39, 1)
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
