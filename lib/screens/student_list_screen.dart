// lib/screens/student_list_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color darkAccentColor = Color(0xFF16213E);
  static const Color absentColor = Colors.red;

  late Future<List<User>> _studentsFuture;
  List<User> _allStudents = [];
  List<User> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedInstitution;
  String? _selectedRoute;

  // --- NOVA LISTA DE OPÇÕES ---
  final Set<String> institutions = {
    'IFSP',
    'CETEC',
    'FATEC',
    'UNIFIPA',
    'ETEC',
    'IMES',
  };

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  Future<List<User>> _loadStudents() async {
    final students = await DatabaseService.instance.getAllStudents();
    setState(() {
      _allStudents = students;
      _filteredStudents = students;
    });
    return students;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final fullName =
            '${student.name.toLowerCase()} ${student.surname.toLowerCase()}';
        final institutionMatch =
            _selectedInstitution == null ||
            student.institution == _selectedInstitution;
        final routeMatch =
            _selectedRoute == null ||
            'Rota ${student.route}' == _selectedRoute?.replaceAll('Rota ', '');
        return fullName.contains(query) && institutionMatch && routeMatch;
      }).toList();
    });
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? darkAccentColor : themeColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withAlpha(51)
                    : Colors.black.withAlpha(20),
              ),
            ),
            title: Text(
              'Confirmar Exclusão',
              style: TextStyle(
                color: themeColors.onSurface,
                fontFamily: 'Poppins',
              ),
            ),
            content: Text(
              'Você tem certeza que deseja remover este aluno? Esta ação não pode ser desfeita.',
              style: TextStyle(
                color: themeColors.onSurface.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: themeColors.onSurface.withOpacity(0.7),
                    fontFamily: 'Poppins',
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Excluir',
                  style: TextStyle(
                    color: absentColor,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );
    return confirm ?? false;
  }

  void _handleDeleteStudent(User student) async {
    if (student.id == null) return;
    try {
      await DatabaseService.instance.deleteUser(student.id!);
      setState(() {
        _allStudents.remove(student);
        _filteredStudents.remove(student);
      });
      _showFeedbackSnackBar('Aluno removido com sucesso.');
    } catch (e) {
      _showFeedbackSnackBar('Erro ao remover aluno.', isError: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Alunos'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder<List<User>>(
                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar alunos: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum aluno cadastrado.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      return _buildStudentListView();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListView() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty ||
                  _selectedInstitution != null ||
                  _selectedRoute != null
              ? 'Nenhum aluno encontrado com os filtros aplicados.'
              : 'Nenhum aluno cadastrado.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentListItem(student);
      },
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: absentColor,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListItem(User student) {
    if (student.id == null) {
      return _buildStudentCard(student);
    }
    return Dismissible(
      key: Key(student.id.toString()),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (direction) async {
        bool confirm = await _showDeleteConfirmationDialog();
        if (confirm) {
          _handleDeleteStudent(student);
        }
        return false;
      },
      child: _buildStudentCard(student),
    );
  }

  Widget _buildStudentCard(User student) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 5.0 : 0.0,
            sigmaY: isDark ? 5.0 : 0.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(30)
                    : Colors.black.withAlpha(10),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: themeColors.primary,
                child: Text(
                  '${student.name[0]}${student.surname[0]}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${student.name} ${student.surname}',
                style: TextStyle(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Text(
                '${student.institution ?? 'N/A'} - Rota: ${student.route ?? 'N/A'}',
                style: TextStyle(
                  color: themeColors.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: themeColors.onSurface.withOpacity(0.7),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/profile', arguments: student);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterPopupMenu(
            hint: 'Instituição',
            icon: Icons.school_outlined,
            selectedValue: _selectedInstitution,
            items: institutions,
            onSelected: (value) {
              setState(() {
                _selectedInstitution = value;
              });
              _filterStudents();
            },
          ),
          const SizedBox(width: 12),
          _buildFilterPopupMenu(
            hint: 'Rota',
            icon: Icons.alt_route_outlined,
            selectedValue: _selectedRoute,
            items: {'Rota 1', 'Rota 2', 'Rota 3'},
            onSelected: (value) {
              setState(() {
                _selectedRoute = value;
              });
              _filterStudents();
            },
          ),
          if (_selectedInstitution != null || _selectedRoute != null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedInstitution = null;
                    _selectedRoute = null;
                  });
                  _filterStudents();
                },
                child: _buildChip(
                  label: 'Limpar',
                  icon: Icons.clear,
                  isActive: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPopupMenu({
    required String hint,
    required IconData icon,
    String? selectedValue,
    required Set<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? darkAccentColor.withAlpha(220) : themeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(51)
                  : Colors.black.withAlpha(20),
            ),
          ),
          textStyle: TextStyle(
            color: themeColors.onSurface,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => items
            .map(
              (String choice) =>
                  PopupMenuItem<String>(value: choice, child: Text(choice)),
            )
            .toList(),
        child: _buildChip(
          label: selectedValue ?? hint,
          icon: icon,
          isActive: selectedValue != null,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    bool isActive = false,
  }) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 5.0 : 0.0,
          sigmaY: isDark ? 5.0 : 0.0,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? themeColors.primary.withAlpha(200)
                : (isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(10)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? themeColors.primary
                  : (isDark
                        ? Colors.white.withAlpha(51)
                        : Colors.black.withAlpha(20)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : themeColors.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : themeColors.onSurface,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 5.0 : 0.0,
          sigmaY: isDark ? 5.0 : 0.0,
        ),
        child: TextFormField(
          controller: _searchController,
          style: TextStyle(
            color: themeColors.onSurface,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nome...',
            hintStyle: TextStyle(
              color: themeColors.onSurface.withOpacity(0.6),
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withAlpha(26)
                : Colors.black.withAlpha(10),
            prefixIcon: Icon(
              Icons.search,
              color: themeColors.onSurface.withOpacity(0.7),
            ),
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
              borderSide: BorderSide(color: themeColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
