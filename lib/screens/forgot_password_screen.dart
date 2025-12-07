// lib/screens/forgot_password_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/services/database_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _emailVerified = false;

  late AnimationController _auroraController;
  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;

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
    _animationBlob1 = Tween<Offset>(
      begin: const Offset(-0.2, -0.8),
      end: const Offset(0.2, 0.8),
    ).animate(
      CurvedAnimation(parent: _auroraController, curve: Curves.easeInOut),
    );
    _animationBlob2 = Tween<Offset>(
      begin: const Offset(1.2, 0.3),
      end: const Offset(-1.2, -0.3),
    ).animate(
      CurvedAnimation(parent: _auroraController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userExists = await DatabaseService.instance.checkUserExists(
          _emailController.text.trim(),
        );

        if (!mounted) return;

        if (userExists) {
          setState(() {
            _emailVerified = true;
          });
          _showFeedbackSnackBar('Email verificado! Defina sua nova senha.');
        } else {
          _showFeedbackSnackBar(
            'Email não encontrado no sistema.',
            isError: true,
          );
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

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseService.instance.updateUserPassword(
          _emailController.text.trim(),
          _newPasswordController.text,
        );

        if (!mounted) return;

        _showFeedbackSnackBar('Senha alterada com sucesso!');
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        Navigator.pop(context);
      } catch (e) {
        _showFeedbackSnackBar(
          'Erro ao alterar senha. Tente novamente.',
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
                      _buildIcon(),
                      const SizedBox(height: 32),
                      Text(
                        'Redefinir Senha',
                        style: _getTextStyle(isTitle: true, fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _emailVerified
                            ? 'Digite sua nova senha abaixo.'
                            : 'Digite seu email para verificar sua conta.',
                        style: _getTextStyle(fontSize: 14, alpha: 179),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email Institucional',
                        icon: Icons.alternate_email,
                        isEmail: true,
                        enabled: !_emailVerified,
                      ),
                      if (_emailVerified) ...[
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _newPasswordController,
                          hintText: 'Nova Senha',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isNewPassword: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirme a Nova Senha',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isConfirmPassword: true,
                        ),
                        const SizedBox(height: 24),
                        _buildPasswordRequirements(),
                      ],
                      const SizedBox(height: 32),
                      _buildGlassButton(
                        onPressed: _isLoading
                            ? null
                            : (_emailVerified ? _resetPassword : _verifyEmail),
                        text: _emailVerified ? 'Alterar Senha' : 'Verificar Email',
                        isPrimary: true,
                      ),
                      if (_emailVerified) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _emailVerified = false;
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                          child: Text(
                            'Usar outro email',
                            style: _getTextStyle(
                              color: primaryAccentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryAccentColor.withAlpha(50),
        border: Border.all(
          color: primaryAccentColor.withAlpha(100),
          width: 2,
        ),
      ),
      child: Icon(
        _emailVerified ? Icons.lock_open : Icons.lock_reset,
        color: primaryAccentColor,
        size: 40,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
    bool isNewPassword = false,
    bool isConfirmPassword = false,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword
              ? (isConfirmPassword
                  ? !_isConfirmPasswordVisible
                  : !_isNewPasswordVisible)
              : false,
          style: _getTextStyle(
            fontSize: 16,
            alpha: enabled ? 255 : 150,
          ),
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (isEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
              return 'Por favor, insira um email válido';
            }
            if (isNewPassword) {
              if (value.length < 8) {
                return 'A senha deve ter no mínimo 8 caracteres';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'A senha deve ter pelo menos uma letra maiúscula';
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'A senha deve ter pelo menos uma letra minúscula';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'A senha deve ter pelo menos um número';
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'A senha deve ter pelo menos um caractere especial';
              }
            }
            if (isConfirmPassword && value != _newPasswordController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _getTextStyle(alpha: 150),
            filled: true,
            fillColor: enabled
                ? Colors.white.withAlpha(26)
                : Colors.white.withAlpha(13),
            prefixIcon: Icon(icon, color: Colors.white.withAlpha(179)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirmPassword
                              ? _isConfirmPasswordVisible
                              : _isNewPasswordVisible)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withAlpha(179),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        } else {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        }
                      });
                    },
                  )
                : (enabled
                    ? null
                    : Icon(
                        Icons.check_circle,
                        color: Colors.green.withAlpha(200),
                      )),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.withAlpha(100)),
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

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sua nova senha precisa ter:",
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
          child: _isLoading
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