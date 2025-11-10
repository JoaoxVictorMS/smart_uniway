// lib/screens/attendance_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/services/report_service.dart'; // Importa o serviço de relatório

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
  bool _isGeneratingReport = false;
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final List<String> institutions = [
    'IFSP',
    'CETEC',
    'FATEC',
    'UNIFIPA',
    'ETEC',
    'IMES',
  ];

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

  // --- FUNÇÃO ATUALIZADA ---
  Future<void> _handleGlobalReportButton() async {
    setState(() {
      _isGeneratingReport = true;
    });
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final reportData = await DatabaseService.instance
          .getGlobalAttendanceReport(startDate, endDate);

      if (reportData.isEmpty && mounted) {
        _showFeedbackSnackBar(
          'Não há dados de chamada para gerar o relatório.',
          isError: true,
        );
        setState(() {
          _isGeneratingReport = false;
        });
        return;
      }

      await ReportService.generateGlobalAttendancePdf(reportData);
    } catch (e) {
      _showFeedbackSnackBar('Erro ao gerar o relatório.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
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
    final relevantStatuses = _attendanceStatus.values;
    int presentCount = relevantStatuses
        .where((s) => s == AttendanceStatus.present)
        .length;
    int absentCount = relevantStatuses
        .where((s) => s == AttendanceStatus.absent)
        .length;
    int totalInInstitution = _studentsForSelectedInstitution.length;
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Chamada'),
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
                _buildInstitutionSelector(),
                const SizedBox(height: 24),

                // Botão para o relatório visual (de instituição única)
                if (_selectedInstitution != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildGlassButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/report',
                          arguments: _selectedInstitution,
                        );
                      },
                      text: 'Ver Gráfico da Instituição',
                      isPrimary: false,
                    ),
                  ),

                // Botão para Relatório Global em PDF
                _buildGlassButton(
                  onPressed: _isGeneratingReport
                      ? null
                      : _handleGlobalReportButton,
                  text: 'Gerar PDF Global (30 dias)',
                  isPrimary: true,
                ),

                const SizedBox(height: 24),

                // Painel de resumo da chamada atual
                if (_selectedInstitution != null)
                  _buildSummaryBar(
                    presentCount,
                    absentCount,
                    totalInInstitution,
                  ),

                if (_selectedInstitution != null) const SizedBox(height: 24),

                // Lista de alunos
                if (_selectedInstitution != null)
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: themeColors.primary,
                            ),
                          )
                        : _studentsForSelectedInstitution.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum aluno encontrado.',
                              style: TextStyle(
                                color: themeColors.onSurface.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _studentsForSelectedInstitution.length,
                            separatorBuilder: (context, index) => Divider(
                              color: themeColors.onSurface.withOpacity(0.2),
                            ),
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

                if (_selectedInstitution == null)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Selecione uma instituição para iniciar a chamada.',
                        style: TextStyle(
                          color: themeColors.onSurface.withOpacity(0.7),
                          fontSize: 16,
                        ),
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

  Widget _buildInstitutionSelector() {
    return _buildDropdownField(
      hintText: 'Selecione a Instituição',
      items: institutions,
      value: _selectedInstitution,
      onChanged: (value) => _onInstitutionSelected(value),
    );
  }

  Widget _buildSummaryBar(int present, int absent, int total) {
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 5.0 : 0.0,
          sigmaY: isDark ? 5.0 : 0.0,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                total.toString(),
                themeColors.onSurface,
              ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceListItem(User student, AttendanceStatus status) {
    final themeColors = Theme.of(context).colorScheme;
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
          ),
        ),
        subtitle: Text(
          'Rota: ${student.route}',
          style: TextStyle(color: themeColors.onSurface.withOpacity(0.7)),
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
    final themeColors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? darkAccentColor.withAlpha(220) : Colors.white,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 5.0 : 0.0,
            sigmaY: isDark ? 5.0 : 0.0,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: themeColors.onSurface,
              fontSize: 14,
            ),
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
                borderSide: BorderSide(color: themeColors.primary, width: 1.5),
              ),
            ),
            hint: Text(
              hintText,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: themeColors.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            dropdownColor: isDark
                ? darkAccentColor.withAlpha(240)
                : themeColors.surface,
            icon: Icon(Icons.keyboard_arrow_down, color: themeColors.onSurface),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = Theme.of(context).colorScheme;
    final isLoading =
        (text == 'Gerar PDF Global (30 dias)' && _isGeneratingReport);
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
                ? themeColors.primary.withAlpha(200)
                : (isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(5)),
            foregroundColor: isPrimary ? Colors.black : themeColors.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
          child: isLoading
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
