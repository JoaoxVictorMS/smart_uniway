// lib/screens/registration_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

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
      backgroundColor: backgroundColor,
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

          // CONTEÚDO DO REGISTRO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CABEÇALHO CORRIGIDO
                  _buildHeader(),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSocialButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: _buildTextField(hintText: 'Nome')),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(hintText: 'Sobrenome'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(hintText: 'Telefone'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                hintText: 'Cidade',
                                items: ['Catanduva', 'Pindorama', 'Palmares'],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(hintText: 'Curso')),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(hintText: 'Matrícula'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(hintText: 'Instituição'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                hintText: 'Rota',
                                items: ['Rota 1', 'Rota 2', 'Rota 3'],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(hintText: 'Período'),
                        const SizedBox(height: 16),
                        _buildTextField(hintText: 'Email'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Senha',
                          isPassword: true,
                          isConfirm: false,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Confirme sua Senha',
                          isPassword: true,
                          isConfirm: true,
                        ),

                        const SizedBox(height: 24),
                        _buildPasswordRequirements(),
                        const SizedBox(height: 16),
                        _buildTermsAndConditions(),
                        const SizedBox(height: 32),

                        _buildGlassButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/admin_home',
                            );
                          },
                          text: 'Criar Conta',
                          isPrimary: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            'Criar Conta',
            style: _getTextStyle(isTitle: true, fontSize: 28),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildTextField({
    required String hintText,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          style: _getTextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _getTextStyle(alpha: 150, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withAlpha(26),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirm
                              ? _isConfirmPasswordVisible
                              : _isPasswordVisible)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withAlpha(179),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
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

  Widget _buildDropdownField({
    required String hintText,
    required List<String> items,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: DropdownButtonFormField<String>(
          style: _getTextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(26),
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
          hint: Text(hintText, style: _getTextStyle(alpha: 150, fontSize: 14)),
          dropdownColor: darkAccentColor,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sua Senha precisa ter:",
          style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "· Mínimo 8 caracteres",
          style: _getTextStyle(fontSize: 12, alpha: 179),
        ),
        const SizedBox(height: 4),
        Text(
          "· Letras maiúsculas (A-Z) e minúsculas (a-z)",
          style: _getTextStyle(fontSize: 12, alpha: 179),
        ),
        const SizedBox(height: 4),
        Text(
          "· Pelo menos 1 caractere especial e 1 número",
          style: _getTextStyle(fontSize: 12, alpha: 179),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (bool? value) {
            setState(() {
              _agreedToTerms = value!;
            });
          },
          checkColor: backgroundColor,
          activeColor: const Color.fromARGB(255, 255, 255, 255),
          side: BorderSide(color: Colors.white.withAlpha(179)),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Ao criar a conta, você concorda com os nossos ',
              style: _getTextStyle(fontSize: 12, alpha: 179),
              children: <TextSpan>[
                TextSpan(
                  text: 'Termos de Uso',
                  style: _getTextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' e nossa '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: _getTextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withAlpha(77))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Ou então', style: _getTextStyle(alpha: 179)),
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
            'Criar conta usando Google',
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
