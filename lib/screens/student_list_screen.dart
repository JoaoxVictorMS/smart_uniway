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
  // Paleta de Cores
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color subtleLightColor = Color(0xFF4A4A58);
  static const Color darkAccentColor = Color(0xFF16213E);

  late Future<List<User>> _studentsFuture;
  List<User> _allStudents = [];
  List<User> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedInstitution;
  String? _selectedRoute;

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
            student.route == _selectedRoute?.replaceAll('Rota ', '');

        return fullName.contains(query) && institutionMatch && routeMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Alunos',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryAccentColor,
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
                        return const Center(
                          child: Text(
                            'Nenhum aluno cadastrado.',
                            style: TextStyle(
                              color: Colors.white70,
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
            color: Colors.white.withAlpha(150),
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
            items: {'IFSP', 'FATEC'},
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
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: darkAccentColor.withAlpha(220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withAlpha(51)),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? primaryAccentColor.withAlpha(200)
                : Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? primaryAccentColor : Colors.white.withAlpha(51),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextFormField(
          controller: _searchController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nome...',
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(150),
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.white.withAlpha(26),
            prefixIcon: Icon(Icons.search, color: Colors.white.withAlpha(179)),
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

  Widget _buildStudentListItem(User student) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryAccentColor,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Text(
                '${student.institution} - Rota: ${student.route}',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontFamily: 'Poppins',
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                Navigator.pushNamed(context, '/profile', arguments: student);
              },
            ),
          ),
        ),
      ),
    );
  }
}
