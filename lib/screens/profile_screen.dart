// lib/screens/profile_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryAccentColor = Color(0xFFE9B44C);

  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _courseController;
  late TextEditingController _registrationController;
  late TextEditingController _institutionController;
  late TextEditingController _periodController;
  late TextEditingController _routeController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _surnameController = TextEditingController(text: widget.user.surname);
    _phoneController = TextEditingController(text: widget.user.phone);
    _courseController = TextEditingController(text: widget.user.course);
    _registrationController = TextEditingController(
      text: widget.user.registrationNumber,
    );
    _institutionController = TextEditingController(
      text: widget.user.institution,
    );
    _periodController = TextEditingController(text: widget.user.period);
    _routeController = TextEditingController(text: widget.user.route);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _courseController.dispose();
    _registrationController.dispose();
    _institutionController.dispose();
    _periodController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      final updatedUser = User(
        id: widget.user.id,
        email: widget.user.email,
        password: widget.user.password,
        userType: widget.user.userType,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        course: _courseController.text.trim(),
        registrationNumber: _registrationController.text.trim(),
        institution: _institutionController.text.trim(),
        period: _periodController.text.trim(),
        route: _routeController.text.trim(),
      );
      try {
        await DatabaseService.instance.updateUser(updatedUser);
        _showFeedbackSnackBar('Perfil atualizado com sucesso!');
        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        _showFeedbackSnackBar('Erro ao atualizar o perfil.', isError: true);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
                size: 26,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _initializeControllers();
                  }
                });
              },
            ),
          ),
        ],
      ),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryAccentColor,
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
                        '${_nameController.text} ${_surnameController.text}',
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
                    _buildProfileField(
                      controller: _nameController,
                      label: 'Nome',
                    ),
                    _buildProfileField(
                      controller: _surnameController,
                      label: 'Sobrenome',
                    ),
                    _buildProfileField(
                      controller: _phoneController,
                      label: 'Telefone',
                    ),
                    if (widget.user.userType == UserType.student) ...[
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        controller: _institutionController,
                        label: 'Instituição',
                      ),
                      _buildProfileField(
                        controller: _courseController,
                        label: 'Curso',
                      ),
                      _buildProfileField(
                        controller: _registrationController,
                        label: 'Matrícula',
                      ),
                      _buildProfileField(
                        controller: _routeController,
                        label: 'Rota',
                      ),
                      _buildProfileField(
                        controller: _periodController,
                        label: 'Período',
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (_isEditing)
                      _buildGlassButton(
                        onPressed: _isLoading ? null : _handleSaveChanges,
                        text: 'Salvar Alterações',
                        isPrimary: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          _isEditing
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: TextFormField(
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Campo não pode ser vazio'
                          : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withAlpha(26),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(51),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(51),
                          ),
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
                )
              : Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ],
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
