import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_uniway/services/database_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados da tela
  // 0 = digitar email
  // 1 = digitar código
  // 2 = digitar nova senha
  int _currentStep = 0;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Código de verificação
  String _generatedCode = '';
  String _userName = '';
  String _oldPassword = ''; // Senha antiga para comparação

  // EmailJS credentials
  static const String _serviceId = 'service_rr0f6ga';
  static const String _templateId = 'template_oibwz2s';
  static const String _publicKey = 'GtYZcWZY8HAfOy3ZQ';

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
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Gera código de 6 dígitos
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Envia email via EmailJS
  Future<bool> _sendVerificationEmail(String toEmail, String toName, String code) async {
    try {
      debugPrint('📧 Enviando email para: $toEmail');
      debugPrint('📧 Nome: $toName');
      debugPrint('📧 Código: $code');
      
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'verification_code': code,
          },
        }),
      );

      debugPrint('📧 Status: ${response.statusCode}');
      debugPrint('📧 Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('📧 Erro: $e');
      return false;
    }
  }

  // Step 1: Verificar email e enviar código
  Future<void> _handleSendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      
      // Verifica se o email existe no banco
      final userExists = await DatabaseService.instance.checkUserExists(email);
      
      if (!userExists) {
        _showFeedbackSnackBar('Email não encontrado.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Busca o nome do usuário e senha antiga
      final user = await DatabaseService.instance.getUserByEmail(email);
      _userName = user?.name ?? 'Usuário';
      _oldPassword = user?.password ?? ''; // Salva a senha antiga

      // Gera o código
      _generatedCode = _generateVerificationCode();

      // Envia o email
      final emailSent = await _sendVerificationEmail(email, _userName, _generatedCode);

      if (emailSent) {
        _showFeedbackSnackBar('Código enviado para $email');
        setState(() {
          _currentStep = 1;
        });
      } else {
        _showFeedbackSnackBar('Erro ao enviar email. Tente novamente.', isError: true);
      }
    } catch (e) {
      _showFeedbackSnackBar('Erro inesperado. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 2: Verificar código
  void _handleVerifyCode() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final enteredCode = _codeController.text.trim();

    if (enteredCode == _generatedCode) {
      _showFeedbackSnackBar('Código verificado com sucesso!');
      setState(() {
        _currentStep = 2;
      });
    } else {
      _showFeedbackSnackBar('Código inválido. Tente novamente.', isError: true);
    }
  }

  // Step 3: Atualizar senha
  Future<void> _handleUpdatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPassword = _passwordController.text;

    // Verifica se a nova senha é igual à antiga
    if (newPassword == _oldPassword) {
      _showFeedbackSnackBar('A nova senha não pode ser igual à senha anterior.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      await DatabaseService.instance.updateUserPassword(email, newPassword);

      _showFeedbackSnackBar('Senha alterada com sucesso!');
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showFeedbackSnackBar('Erro ao atualizar senha.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reenviar código
  Future<void> _handleResendCode() async {
    setState(() => _isLoading = true);

    _generatedCode = _generateVerificationCode();
    final email = _emailController.text.trim();

    final emailSent = await _sendVerificationEmail(email, _userName, _generatedCode);

    if (emailSent) {
      _showFeedbackSnackBar('Novo código enviado!');
    } else {
      _showFeedbackSnackBar('Erro ao reenviar. Tente novamente.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  // Voltar para o passo anterior
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _codeController.clear();
        }
      });
    } else {
      Navigator.pop(context);
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
          // Aurora blobs
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
          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildStepIndicator(),
                    const SizedBox(height: 32),
                    _buildIcon(),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 32),
                    _buildCurrentStepContent(),
                    const SizedBox(height: 24),
                    _buildActionButton(),
                    if (_currentStep == 1) ...[
                      const SizedBox(height: 16),
                      _buildResendButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: _handleBack,
        ),
        Expanded(
          child: Text(
            'Recuperar Senha',
            style: _getTextStyle(isTitle: true, fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0),
        _buildStepLine(0),
        _buildStepDot(1),
        _buildStepLine(1),
        _buildStepDot(2),
      ],
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? primaryAccentColor : Colors.white.withAlpha(51),
        border: Border.all(
          color: isActive ? primaryAccentColor : Colors.white.withAlpha(51),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? primaryAccentColor : Colors.white.withAlpha(51),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (_currentStep) {
      case 0:
        icon = Icons.email_outlined;
        break;
      case 1:
        icon = Icons.pin_outlined;
        break;
      case 2:
        icon = Icons.lock_open_outlined;
        break;
      default:
        icon = Icons.email_outlined;
    }

    return Icon(
      icon,
      size: 80,
      color: primaryAccentColor,
    );
  }

  Widget _buildTitle() {
    String title;
    switch (_currentStep) {
      case 0:
        title = 'Digite seu Email';
        break;
      case 1:
        title = 'Verifique seu Email';
        break;
      case 2:
        title = 'Nova Senha';
        break;
      default:
        title = '';
    }

    return Text(
      title,
      style: _getTextStyle(isTitle: true, fontSize: 22),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    String subtitle;
    switch (_currentStep) {
      case 0:
        subtitle = 'Enviaremos um código de verificação para o seu email cadastrado.';
        break;
      case 1:
        subtitle = 'Digite o código de 6 dígitos enviado para ${_emailController.text}';
        break;
      case 2:
        subtitle = 'Crie uma nova senha segura para sua conta.';
        break;
      default:
        subtitle = '';
    }

    return Text(
      subtitle,
      style: _getTextStyle(alpha: 179, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailField();
      case 1:
        return _buildCodeField();
      case 2:
        return _buildPasswordFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      hintText: 'Email',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite seu email';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField() {
    return _buildTextField(
      controller: _codeController,
      hintText: 'Código de 6 dígitos',
      keyboardType: TextInputType.number,
      prefixIcon: Icons.pin_outlined,
      maxLength: 6,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o código';
        }
        if (value.length != 6) {
          return 'O código deve ter 6 dígitos';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _passwordController,
          hintText: 'Nova Senha',
          isPassword: true,
          isPasswordField: true,
          prefixIcon: Icons.lock_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite a nova senha';
            }
            if (value.length < 8) {
              return 'Mínimo 8 caracteres';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Precisa ter letra maiúscula';
            }
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return 'Precisa ter letra minúscula';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Precisa ter um número';
            }
            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
              return 'Precisa ter caractere especial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirme a Nova Senha',
          isPassword: true,
          isConfirmPassword: true,
          prefixIcon: Icons.lock_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirme a senha';
            }
            if (value != _passwordController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sua senha precisa ter:",
          style: _getTextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "· Mínimo 8 caracteres\n· Letras maiúsculas e minúsculas\n· Pelo menos 1 número e 1 caractere especial",
          style: _getTextStyle(fontSize: 11, alpha: 150),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = 'Enviar Código';
        onPressed = _isLoading ? null : _handleSendCode;
        break;
      case 1:
        buttonText = 'Verificar Código';
        onPressed = _isLoading ? null : _handleVerifyCode;
        break;
      case 2:
        buttonText = 'Alterar Senha';
        onPressed = _isLoading ? null : _handleUpdatePassword;
        break;
      default:
        buttonText = '';
        onPressed = null;
    }

    return _buildGlassButton(
      onPressed: onPressed,
      text: buttonText,
      isPrimary: true,
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleResendCode,
      child: Text(
        'Não recebeu? Reenviar código',
        style: _getTextStyle(
          color: primaryAccentColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordField = false,
    bool isConfirmPassword = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (isConfirmPassword ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: _getTextStyle(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _getTextStyle(alpha: 150, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withAlpha(26),
            counterText: '',
            prefixIcon: Icon(prefixIcon, color: Colors.white.withAlpha(179)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withAlpha(179),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
              borderSide: const BorderSide(color: primaryAccentColor, width: 1.5),
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
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPrimary ? primaryAccentColor : Colors.white.withAlpha(51),
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
}