// lib/screens/attendance_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';

enum AttendanceStatus { present, absent, unmarked }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color primaryAccentColor = Color(0xFFE9B44C);
  static const Color darkAccentColor = Color(0xFF16213E);
  static const Color presentColor = Colors.green;
  static const Color absentColor = Colors.red;

  List<User> _studentsForSelectedInstitution = [];
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  String? _selectedInstitution;
  bool _isLoading = false;

  // CORRECTED HERE: The variable was missing
  final bool _isGeneratingReport = false;

  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _onInstitutionSelected(String? institution) async {
    if (institution == null) return;
    setState(() {
      _isLoading = true;
      _selectedInstitution = institution;
      _studentsForSelectedInstitution = [];
    });

    final studentsFuture = DatabaseService.instance.getStudentsByInstitution(
      institution,
    );
    final attendanceFuture = DatabaseService.instance.getAttendanceForDate(
      _today,
    );

    final results = await Future.wait([studentsFuture, attendanceFuture]);
    final students = results[0] as List<User>;
    final todaysAttendance = results[1] as Map<int, String>;

    if (mounted) {
      setState(() {
        _studentsForSelectedInstitution = students;
        _attendanceStatus.clear();
        for (var student in students) {
          if (student.registrationNumber != null && student.id != null) {
            final savedStatus = todaysAttendance[student.id];
            if (savedStatus == 'present') {
              _attendanceStatus[student.registrationNumber!] =
                  AttendanceStatus.present;
            } else if (savedStatus == 'absent') {
              _attendanceStatus[student.registrationNumber!] =
                  AttendanceStatus.absent;
            } else {
              _attendanceStatus[student.registrationNumber!] =
                  AttendanceStatus.unmarked;
            }
          }
        }
        _isLoading = false;
      });
    }
  }

  void _markAttendance(User student, AttendanceStatus status) {
    if (student.registrationNumber == null || student.id == null) return;

    String studentRegNumber = student.registrationNumber!;
    AttendanceStatus newStatus;

    if (_attendanceStatus[studentRegNumber] == status) {
      newStatus = AttendanceStatus.unmarked;
    } else {
      newStatus = status;
    }

    setState(() {
      _attendanceStatus[studentRegNumber] = newStatus;
    });

    DatabaseService.instance.saveAttendanceRecord(
      student.id!,
      _today,
      newStatus.toString().split('.').last,
    );
  }

  void _handleReportButton() {
    if (_selectedInstitution != null) {
      Navigator.pushNamed(context, '/report', arguments: _selectedInstitution);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relevantStatuses = _attendanceStatus.values;
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
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryAccentColor,
                            ),
                          )
                        : _studentsForSelectedInstitution.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum aluno encontrado para esta instituição.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _studentsForSelectedInstitution.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: Colors.white.withAlpha(51)),
                            itemBuilder: (context, index) {
                              final student =
                                  _studentsForSelectedInstitution[index];
                              final status =
                                  _attendanceStatus[student
                                      .registrationNumber!] ??
                                  AttendanceStatus.unmarked;
                              return _buildAttendanceListItem(student, status);
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: _buildGlassButton(
                      onPressed: _handleReportButton,
                      text: 'Ver Relatório Completo',
                      isPrimary: true,
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

  // --- HELPER FUNCTIONS ---

  Widget _buildInstitutionSelector() {
    return _buildDropdownField(
      hintText: 'Selecione a Instituição',
      items: ['IFSP', 'FATEC'],
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
          'Rota: ${student.route}',
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
              onPressed: () =>
                  _markAttendance(student, AttendanceStatus.present),
            ),
            IconButton(
              icon: Icon(
                Icons.cancel,
                color: absentColor.withOpacity(
                  status == AttendanceStatus.absent ? 1.0 : 0.4,
                ),
              ),
              onPressed: () =>
                  _markAttendance(student, AttendanceStatus.absent),
            ),
          ],
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
            initialValue: value,
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
            dropdownColor: darkAccentColor.withAlpha(240),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            items: items
                .map(
                  (String val) =>
                      DropdownMenuItem<String>(value: val, child: Text(val)),
                )
                .toList(),
            onChanged: onChanged,
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
