// lib/models/user_model.dart

enum UserType { student, admin }

class User {
  final String name;
  final String surname;
  final String email;
  final String phone;
  final UserType userType;

  // Campos específicos de estudante
  final String? course;
  final String? registrationNumber; // Matrícula
  final String? institution;
  final String? route; // Rota
  final String? period;

  User({
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.userType,
    this.course,
    this.registrationNumber,
    this.institution,
    this.route,
    this.period,
  });
}
