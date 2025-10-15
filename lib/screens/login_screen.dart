// lib/screens/login_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/auth_provider.dart';
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/screens/student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _auroraController;
  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO CORRIGIDA ---
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await DatabaseService.instance.loginUser(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // CORREÇÃO 1: Verifica se a tela ainda existe após a busca no banco
        if (!mounted) return;

        if (user != null) {
          _showFeedbackSnackBar('Login realizado com sucesso!');
          await Future.delayed(const Duration(seconds: 1));

          // CORREÇÃO 2: Verifica se a tela ainda existe após a pausa
          if (!mounted) return;

          if (user.userType == UserType.admin) {
            Navigator.pushReplacementNamed(context, '/admin_home');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AuthProvider(user: user, child: const StudentHomeScreen()),
              ),
            );
          }
        } else {
          _showFeedbackSnackBar('Email ou senha inválidos.', isError: true);
        }
      } catch (e) {
        _showFeedbackSnackBar(
          'Ocorreu um erro. Tente novamente.',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Verificação de segurança
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top,
                child: Form(
                  key: _formKey,
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
                        controller: _emailController,
                        hintText: 'Email Institucional',
                        icon: Icons.alternate_email,
                        isEmail: true,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
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
                              color: primaryAccentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildGlassButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          style: _getTextStyle(fontSize: 16),
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (isEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
              return 'Por favor, insira um email válido';
            }
            return null;
          },
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
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
    required VoidCallback? onPressed,
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
                ? primaryAccentColor.withAlpha(200)
                : Colors.white.withAlpha(26),
            foregroundColor: isPrimary ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPrimary
                    ? primaryAccentColor
                    : Colors.white.withAlpha(51),
                width: 1.5,
              ),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: _isLoading && isPrimary
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black,
                  ),
                )
              : Text(
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
