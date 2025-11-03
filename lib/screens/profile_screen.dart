// lib/screens/profile_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColors = Theme.of(context).colorScheme;
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
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
          if (isDark)
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
                        backgroundColor: themeColors.primary,
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeColors.onSurface,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: themeColors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Divider(),
                    _buildThemeToggle(themeProvider, themeColors),
                    const Divider(),
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
                      const Divider(),
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

  // --- FUNÇÃO CORRIGIDA ---
  Widget _buildThemeToggle(ThemeProvider themeProvider, ColorScheme colors) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        themeProvider.themeMode == ThemeMode.dark
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: colors.primary,
        size: 28,
      ),
      title: Text(
        'Modo Escuro',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        themeProvider.themeMode == ThemeMode.dark ? 'Ativado' : 'Desativado',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: colors.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: themeProvider.themeMode == ThemeMode.dark,
        onChanged: (bool value) {
          themeProvider.toggleTheme();
        },
        // CORRIGIDO: Usa a cor do tema
        activeColor: colors.primary,
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
  }) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: themeColors.onSurface.withOpacity(0.6),
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          _isEditing
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isDark ? 5.0 : 0.0,
                      sigmaY: isDark ? 5.0 : 0.0,
                    ),
                    child: TextFormField(
                      controller: controller,
                      style: TextStyle(
                        color: themeColors.onSurface,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Campo não pode ser vazio'
                          : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withAlpha(26)
                            : Colors.black.withAlpha(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withAlpha(51)
                                : Colors.black.withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withAlpha(51)
                                : Colors.black.withAlpha(20),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Text(
                  controller.text.isNotEmpty ? controller.text : 'N/A',
                  style: TextStyle(color: themeColors.onSurface, fontSize: 16),
                ),
        ],
      ),
    );
  }

  // --- FUNÇÃO CORRIGIDA ---
  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String text,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10.0 : 0.0,
          sigmaY: isDark ? 10.0 : 0.0,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            // CORRIGIDO: Usa a cor do tema
            backgroundColor: isPrimary
                ? themeColors.primary.withAlpha(200)
                : (isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(5)),
            foregroundColor: isPrimary ? Colors.black : themeColors.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              // CORRIGIDO: Usa a cor do tema
              side: BorderSide(
                color: isPrimary
                    ? themeColors.primary
                    : (isDark
                          ? Colors.white.withAlpha(51)
                          : Colors.black.withAlpha(20)),
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
