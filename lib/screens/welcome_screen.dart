// lib/screens/welcome_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late AnimationController _logoController;

  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;
  late Animation<double> _logoAnimation;

  // Paleta de Cores Corporativa
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color.fromARGB(255, 157, 132, 183);
  static const Color subtleLightColor = Color(0xFF4A4A58);
  static const Color darkAccentColor = Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    _logoController = AnimationController(
      duration: const Duration(seconds: 4),
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
    _logoAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // FUNDO E TEXTURA
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
          // CONTEÚDO PRINCIPAL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoAnimation.value),
                        // CORREÇÃO AQUI: Adicionamos o "null check operator" (!) para garantir
                        // que o 'child' não é nulo neste ponto.
                        child: child!,
                      );
                    },
                    child: Image.asset(
                      'assets/images/smart_uniway_logo.png',
                      height: 150,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Smart Uniway',
                    textAlign: TextAlign.center,
                    style: _getTextStyle(isTitle: true),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Acesse horários, confirme sua presença e gerencie sua rota de forma fácil e rápida.',
                    textAlign: TextAlign.center,
                    style: _getTextStyle(),
                  ),
                  const Spacer(flex: 3),
                  _buildGlassButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registration');
                    },
                    text: 'Criar Conta',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  _buildGlassButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    text: 'Já tenho uma conta',
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNÇÕES HELPER ---
  TextStyle _getTextStyle({bool isTitle = false}) {
    return TextStyle(
      fontFamily: 'Poppins',
      color: Colors.white,
      fontSize: isTitle ? 26 : 15,
      fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black.withAlpha(77),
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
