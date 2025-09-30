// lib/screens/attendance_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';

// Enum para controlar os estados de presença
enum AttendanceStatus { present, absent, unmarked }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Paleta de Cores
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color darkAccentColor = Color(0xFF16213E);
  static const Color presentColor = Colors.green;
  static const Color absentColor = Colors.red;

  // Dados Mock
  final List<User> _allStudents = _getMockStudents();
  List<User> _studentsForSelectedInstitution = [];

  // Mapa para controlar o status de cada aluno
  final Map<String, AttendanceStatus> _attendanceStatus = {};

  String? _selectedInstitution;

  @override
  void initState() {
    super.initState();
    // Inicializa o status de todos os alunos como "unmarked"
    for (var student in _allStudents) {
      _attendanceStatus[student.registrationNumber!] =
          AttendanceStatus.unmarked;
    }
  }

  void _onInstitutionSelected(String? institution) {
    setState(() {
      _selectedInstitution = institution;
      if (institution != null) {
        _studentsForSelectedInstitution = _allStudents
            .where((s) => s.institution == institution)
            .toList();
      } else {
        _studentsForSelectedInstitution = [];
      }
      // Reseta o status da chamada ao trocar de instituição
      _attendanceStatus.updateAll((key, value) => AttendanceStatus.unmarked);
    });
  }

  void _markAttendance(String studentId, AttendanceStatus status) {
    setState(() {
      // Alterna o status se o mesmo botão for clicado novamente
      if (_attendanceStatus[studentId] == status) {
        _attendanceStatus[studentId] = AttendanceStatus.unmarked;
      } else {
        _attendanceStatus[studentId] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtra os status apenas para os alunos da instituição selecionada
    final relevantStatuses = _studentsForSelectedInstitution.map(
      (s) => _attendanceStatus[s.registrationNumber!],
    );
    int presentCount = relevantStatuses
        .where((s) => s == AttendanceStatus.present)
        .length;
    int absentCount = relevantStatuses
        .where((s) => s == AttendanceStatus.absent)
        .length;
    int totalInInstitution = _studentsForSelectedInstitution.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fazer Chamada',
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
                _buildInstitutionSelector(),
                const SizedBox(height: 24),

                if (_selectedInstitution != null) ...[
                  _buildSummaryBar(
                    presentCount,
                    absentCount,
                    totalInInstitution,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _studentsForSelectedInstitution.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.white.withAlpha(51)),
                      itemBuilder: (context, index) {
                        final student = _studentsForSelectedInstitution[index];
                        final status =
                            _attendanceStatus[student.registrationNumber!] ??
                            AttendanceStatus.unmarked;
                        return _buildAttendanceListItem(student, status);
                      },
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Selecione uma instituição para iniciar a chamada.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildInstitutionSelector() {
    return _buildDropdownField(
      hintText: 'Selecione a Instituição',
      items: ['IFSP', 'FATEC'], // Opções de instituições
      value: _selectedInstitution,
      onChanged: (value) => _onInstitutionSelected(value),
    );
  }

  Widget _buildSummaryBar(int present, int absent, int total) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', total.toString(), Colors.white),
              _buildSummaryItem('Presentes', present.toString(), presentColor),
              _buildSummaryItem('Ausentes', absent.toString(), absentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAttendanceListItem(User student, AttendanceStatus status) {
    Color borderColor;
    switch (status) {
      case AttendanceStatus.present:
        borderColor = presentColor;
        break;
      case AttendanceStatus.absent:
        borderColor = absentColor;
        break;
      case AttendanceStatus.unmarked:
        borderColor = Colors.transparent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 4)),
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
          ),
        ),
        subtitle: Text(
          'Rota: ${student.route}', // Agora mostramos a rota como info secundária
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: presentColor.withOpacity(
                  status == AttendanceStatus.present ? 1.0 : 0.4,
                ),
              ),
              onPressed: () => _markAttendance(
                student.registrationNumber!,
                AttendanceStatus.present,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.cancel,
                color: absentColor.withOpacity(
                  status == AttendanceStatus.absent ? 1.0 : 0.4,
                ),
              ),
              onPressed: () => _markAttendance(
                student.registrationNumber!,
                AttendanceStatus.absent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ESTA FUNÇÃO FOI ATUALIZADA PARA ESTILIZAR O MENU
  Widget _buildDropdownField({
    required String hintText,
    required List<String> items,
    String? value,
    required ValueChanged<String?> onChanged,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14,
            ),
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
            ),
            hint: Text(
              hintText,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withAlpha(150),
                fontSize: 14,
              ),
            ),
            dropdownColor: darkAccentColor.withAlpha(
              240,
            ), // Cor de fundo do menu
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            items: items.map((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  static List<User> _getMockStudents() {
    return [
      User(
        name: 'João Victor',
        surname: 'Santos',
        email: 'joao@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '1',
        registrationNumber: 'SP001',
      ),
      User(
        name: 'Gustavo',
        surname: 'Mendes',
        email: 'gustavo@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '2',
        registrationNumber: 'SP002',
      ),
      User(
        name: 'Felipe',
        surname: 'Fernandes',
        email: 'felipe@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '1',
        registrationNumber: 'SP003',
      ),
      User(
        name: 'Ana Carolina',
        surname: 'Souza',
        email: 'ana@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '3',
        registrationNumber: 'SP004',
      ),
      User(
        name: 'Lucas',
        surname: 'Pereira',
        email: 'lucas@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '2',
        registrationNumber: 'SP005',
      ),
      User(
        name: 'Mariana',
        surname: 'Lima',
        email: 'mariana@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'FATEC',
        route: '1',
        registrationNumber: 'SP006',
      ),
      User(
        name: 'Carlos',
        surname: 'Eduardo',
        email: 'carlos@email.com',
        phone: '123',
        userType: UserType.student,
        institution: 'IFSP',
        route: '3',
        registrationNumber: 'SP007',
      ),
    ];
  }
}
