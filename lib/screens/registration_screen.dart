import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _courseController = TextEditingController();
  final _registrationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  // Variáveis de estado para Dropdowns
  String? _selectedCity;
  String? _selectedInstitution;
  String? _selectedRoute;
  String? _selectedSemester;

  // Outras variáveis de estado
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  
  // Estados para verificação de email
  bool _showVerificationScreen = false;
  String _generatedCode = '';

  // EmailJS credentials
  static const String _serviceId = 'service_rr0f6ga';
  static const String _templateId = 'template_o2wz7xm';
  static const String _publicKey = 'GtYZcWZY8HAfOy3ZQ';

  late AnimationController _auroraController;
  late Animation<Offset> _animationBlob1;
  late Animation<Offset> _animationBlob2;

  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color.fromARGB(255, 157, 132, 183);
  static const Color subtleLightColor = Color(0xFF4A4A58);
  static const Color darkAccentColor = Color(0xFF16213E);

  final List<String> institutions = [
    'IFSP',
    'CETEC',
    'FATEC',
    'UNIFIPA',
    'ETEC',
    'IMES',
  ];
  final List<String> semesters = List.generate(10, (i) => '${i + 1}º Semestre');

  // Mapa de rotas por cidade (trajeto realista baseado na geografia)
  final Map<String, List<String>> routesByCity = {
    'Novo Horizonte': [
      'Rota NH-1: IMES → FATEC → UNIFIPA',
      'Rota NH-2: IMES → IFSP → ETEC',
    ],
    'Pindorama': [
      'Rota PI-1: ETEC → FATEC → UNIFIPA',
      'Rota PI-2: IFSP → IMES',
    ],
    'Catanduva': [
      'Rota CT-1: Centro → FATEC → UNIFIPA → ETEC',
      'Rota CT-2: Centro → IMES → IFSP',
    ],
    'Palmares': [
      'Rota PA-1: UNIFIPA → FATEC → IMES',
      'Rota PA-2: ETEC → IFSP',
    ],
    'Elisiário': [
      'Rota EL-1: IMES → IFSP → FATEC',
      'Rota EL-2: UNIFIPA → ETEC',
    ],
  };

  // Retorna as rotas disponíveis para a cidade selecionada
  List<String> get availableRoutes {
    if (_selectedCity == null) return [];
    return routesByCity[_selectedCity] ?? [];
  }

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
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _courseController.dispose();
    _registrationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
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
      debugPrint('📧 Enviando email de confirmação para: $toEmail');
      
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
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('📧 Erro: $e');
      return false;
    }
  }

  // Primeira etapa: validar formulário e enviar código
  Future<void> _handleSendVerificationCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    if (!_agreedToTerms) {
      _showFeedbackSnackBar(
        'Você precisa aceitar os Termos de Uso.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      
      // Verifica se o email já existe
      final emailExists = await DatabaseService.instance.checkUserExists(email);
      if (emailExists) {
        _showFeedbackSnackBar('Este email já está cadastrado.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Gera e envia o código
      _generatedCode = _generateVerificationCode();
      final emailSent = await _sendVerificationEmail(
        email,
        _nameController.text.trim(),
        _generatedCode,
      );

      if (emailSent) {
        _showFeedbackSnackBar('Código enviado para $email');
        setState(() {
          _showVerificationScreen = true;
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

  // Segunda etapa: verificar código e criar conta
  Future<void> _handleVerifyAndCreateAccount() async {
    final enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      _showFeedbackSnackBar('Digite o código de verificação.', isError: true);
      return;
    }

    if (enteredCode != _generatedCode) {
      _showFeedbackSnackBar('Código inválido. Tente novamente.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newUser = User(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: UserType.student,
        course: _courseController.text.trim(),
        registrationNumber: _registrationController.text.trim(),
        institution: _selectedInstitution,
        period: _selectedSemester,
        route: _selectedRoute,
      );

      await DatabaseService.instance.createUser(newUser);
      _showFeedbackSnackBar('Conta criada com sucesso!');
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } on UserCreationException catch (e) {
      _showFeedbackSnackBar(e.message, isError: true);
    } catch (e) {
      _showFeedbackSnackBar(
        'Ocorreu um erro inesperado. Tente novamente.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reenviar código
  Future<void> _handleResendCode() async {
    setState(() => _isLoading = true);

    _generatedCode = _generateVerificationCode();
    final emailSent = await _sendVerificationEmail(
      _emailController.text.trim(),
      _nameController.text.trim(),
      _generatedCode,
    );

    if (emailSent) {
      _showFeedbackSnackBar('Novo código enviado!');
    } else {
      _showFeedbackSnackBar('Erro ao reenviar. Tente novamente.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  // Voltar para o formulário
  void _handleBackToForm() {
    setState(() {
      _showVerificationScreen = false;
      _codeController.clear();
    });
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
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
            child: _showVerificationScreen
                ? _buildVerificationScreen()
                : _buildRegistrationForm(),
          ),
        ],
      ),
    );
  }

  // Tela de verificação de código
  Widget _buildVerificationScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: _handleBackToForm,
              ),
              Expanded(
                child: Text(
                  'Verificar Email',
                  style: _getTextStyle(isTitle: true, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 48),
          const Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: primaryAccentColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Verifique seu Email',
            style: _getTextStyle(isTitle: true, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Digite o código de 6 dígitos enviado para ${_emailController.text}',
            style: _getTextStyle(alpha: 179, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCodeField(),
          const SizedBox(height: 24),
          _buildGlassButton(
            onPressed: _isLoading ? null : _handleVerifyAndCreateAccount,
            text: 'Confirmar e Criar Conta',
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _handleResendCode,
            child: Text(
              'Não recebeu? Reenviar código',
              style: _getTextStyle(
                color: primaryAccentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: _getTextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: _getTextStyle(alpha: 100, fontSize: 24),
            filled: true,
            fillColor: Colors.white.withAlpha(26),
            counterText: '',
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
          ),
        ),
      ),
    );
  }

  // Formulário de registro original
  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          hintText: 'Nome',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _surnameController,
                          hintText: 'Sobrenome',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          hintText: 'Telefone',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          hintText: 'Cidade',
                          items: ['Catanduva', 'Elisiário', 'Novo Horizonte', 'Palmares', 'Pindorama'],
                          value: _selectedCity,
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                              // Limpa a rota quando muda a cidade
                              _selectedRoute = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _courseController,
                          hintText: 'Curso',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _registrationController,
                          hintText: 'Matrícula',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rota só aparece se tiver cidade selecionada
                  if (_selectedCity != null) ...[
                    _buildDropdownField(
                      hintText: 'Selecione a Rota',
                      items: availableRoutes,
                      value: _selectedRoute,
                      onChanged: (value) =>
                          setState(() => _selectedRoute = value),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Instituição
                  _buildDropdownField(
                    hintText: 'Instituição',
                    items: institutions,
                    value: _selectedInstitution,
                    onChanged: (value) =>
                        setState(() => _selectedInstitution = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    hintText: 'Semestre',
                    items: semesters,
                    value: _selectedSemester,
                    onChanged: (value) =>
                        setState(() => _selectedSemester = value),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Senha',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
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
                    onPressed: _isLoading ? null : _handleSendVerificationCode,
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
    );
  }

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
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isConfirm = false,
    bool isEmail = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          style: _getTextStyle(fontSize: 14),
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
            if (isPassword && !isConfirm) {
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
            if (isConfirm && value != _passwordController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
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

  Widget _buildDropdownField({
    required String hintText,
    required List<String> items,
    String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: DropdownButtonFormField<String>(
          value: value,
          style: _getTextStyle(fontSize: 14),
          validator: (value) => value == null ? 'Campo obrigatório' : null,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          hint: Text(hintText, style: _getTextStyle(alpha: 150, fontSize: 14)),
          dropdownColor: darkAccentColor,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: items
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: onChanged,
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
          onChanged: (bool? value) => setState(() => _agreedToTerms = value!),
          checkColor: backgroundColor,
          activeColor: primaryAccentColor,
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
                    color: primaryAccentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' e nossa '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: _getTextStyle(
                    fontSize: 12,
                    color: primaryAccentColor,
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
            foregroundColor: isPrimary ? Colors.white : Colors.white,
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
                  child: CircularProgressIndicator(color: Colors.white),
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