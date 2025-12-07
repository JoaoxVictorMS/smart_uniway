// lib/screens/profile_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // Cor personalizada para modo escuro
  static const Color primaryAccentColor = Color.fromARGB(255, 157, 132, 183);

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _courseController;
  late TextEditingController _registrationController;
  late TextEditingController _institutionController;
  late TextEditingController _periodController;
  late TextEditingController _routeController;

  // Variável para armazenar o caminho da foto de perfil
  String? _profileImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileImage();
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

  // Carrega a foto de perfil salva
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.user.id}');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  // Salva o caminho da foto de perfil
  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_${widget.user.id}', path);
  }

  // Abre o seletor de imagem
  Future<void> _pickImage() async {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Escolher foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Tirar foto',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Escolher da galeria',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Remover foto',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtém a imagem da câmera ou galeria
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Salva a imagem no diretório do app
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String savedPath = '${directory.path}/$fileName';

        // Copia o arquivo para o novo local
        await File(pickedFile.path).copy(savedPath);

        // Remove a foto antiga se existir
        if (_profileImagePath != null && File(_profileImagePath!).existsSync()) {
          await File(_profileImagePath!).delete();
        }

        // Salva o caminho e atualiza a UI
        await _saveProfileImagePath(savedPath);
        setState(() {
          _profileImagePath = savedPath;
        });

        _showFeedbackSnackBar('Foto de perfil atualizada!');
      }
    } catch (e) {
      _showFeedbackSnackBar('Erro ao selecionar imagem.', isError: true);
    }
  }

  // Remove a foto de perfil
  Future<void> _removeImage() async {
    try {
      if (_profileImagePath != null && File(_profileImagePath!).existsSync()) {
        await File(_profileImagePath!).delete();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_${widget.user.id}');
      
      setState(() {
        _profileImagePath = null;
      });
      
      _showFeedbackSnackBar('Foto de perfil removida!');
    } catch (e) {
      _showFeedbackSnackBar('Erro ao remover imagem.', isError: true);
    }
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
                      child: GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Stack(
                          children: [
                            // Avatar com foto ou iniciais
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: isDark ? primaryAccentColor : themeColors.primary,
                              backgroundImage: _profileImagePath != null
                                  ? FileImage(File(_profileImagePath!))
                                  : null,
                              child: _profileImagePath == null
                                  ? (widget.user.userType == UserType.admin
                                      ? Icon(
                                          Icons.admin_panel_settings,
                                          size: 50,
                                          color: isDark ? Colors.white : Colors.black,
                                        )
                                      : Text(
                                          '${widget.user.name[0]}${widget.user.surname[0]}',
                                          style: TextStyle(
                                            fontSize: 40,
                                            color: isDark ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ))
                                  : null,
                            ),
                            // Ícone de câmera (só aparece no modo de edição para alunos)
                            if (_isEditing && widget.user.userType == UserType.student)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? primaryAccentColor : themeColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: themeColors.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildThemeToggle(ThemeProvider themeProvider, ColorScheme colors) {
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: isDark ? primaryAccentColor : colors.primary,
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
        isDark ? 'Ativado' : 'Desativado',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: colors.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (bool value) {
          themeProvider.toggleTheme();
        },
        activeThumbColor: primaryAccentColor,
        activeTrackColor: primaryAccentColor.withOpacity(0.5),
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

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String text,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = Theme.of(context).colorScheme;
    final buttonColor = isDark ? primaryAccentColor : themeColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10.0 : 0.0,
          sigmaY: isDark ? 10.0 : 0.0,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? buttonColor.withAlpha(200)
                : (isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(5)),
            foregroundColor: isPrimary ? Colors.white : themeColors.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPrimary
                    ? buttonColor
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
                    color: Colors.white,
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