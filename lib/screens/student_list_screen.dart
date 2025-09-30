// lib/screens/student_list_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';

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

  // Lista original de todos os alunos (dados mock)
  late List<User> _allStudents;
  // Lista que será exibida e filtrada pela busca
  List<User> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();

  // Variáveis de estado para os filtros
  String? _selectedInstitution;
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _allStudents = _getMockStudents();
    _filteredStudents = _allStudents;

    _searchController.addListener(() {
      _filterStudents();
    });
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
        // Lógica de filtro combinada (busca E filtros de chip)
        final institutionMatch =
            _selectedInstitution == null ||
            student.institution == _selectedInstitution;
        final routeMatch =
            _selectedRoute == null || 'Rota ${student.route}' == _selectedRoute;

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
          // Textura de fundo
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/noise_texture.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // Conteúdo principal
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
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum aluno encontrado.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentListItem(student);
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

  // --- FUNÇÕES HELPER ---

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
                _filterStudents();
              });
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
                _filterStudents();
              });
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
                    _filterStudents();
                  });
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

  // ESTA FUNÇÃO FOI ATUALIZADA PARA ESTILIZAR O MENU
  Widget _buildFilterPopupMenu({
    required String hint,
    required IconData icon,
    required String? selectedValue,
    required Set<String> items,
    required ValueChanged<String> onSelected,
  }) {
    // Envolvemos o botão em um widget Theme para customizar o menu
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: darkAccentColor.withAlpha(220), // Cor de fundo do menu
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withAlpha(51)),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return items.map((String choice) {
            return PopupMenuItem<String>(value: choice, child: Text(choice));
          }).toList();
        },
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
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  List<User> _getMockStudents() {
    return [
      User(
        name: 'João Victor',
        surname: 'Santos',
        email: 'joao@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '1',
      ),
      User(
        name: 'Gustavo',
        surname: 'Mendes',
        email: 'gustavo@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '2',
      ),
      User(
        name: 'Felipe',
        surname: 'Fernandes',
        email: 'felipe@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '1',
      ),
      User(
        name: 'Ana Carolina',
        surname: 'Souza',
        email: 'ana@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '3',
      ),
      User(
        name: 'Lucas',
        surname: 'Pereira',
        email: 'lucas@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '2',
      ),
      User(
        name: 'Mariana',
        surname: 'Lima',
        email: 'mariana@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '1',
      ),
    ];
  }
}
