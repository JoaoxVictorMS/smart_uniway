// lib/models/user_model.dart

enum UserType { student, admin }

class User {
  final int? id;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String password;
  final UserType userType;
  final String? course;
  final String? registrationNumber;
  final String? institution;
  final String? route;
  final String? period;

  User({
    this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.password,
    required this.userType,
    this.course,
    this.registrationNumber,
    this.institution,
    this.route,
    this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'password': password,
      'userType': userType.toString().split('.').last,
      'course': course,
      'registrationNumber': registrationNumber,
      'institution': institution,
      'route': route,
      'period': period,
    };
  }

  // --- NOVO MÉTODO ADICIONADO ---
  // Constrói um objeto User a partir de um Map vindo do banco de dados
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      userType: map['userType'] == 'admin' ? UserType.admin : UserType.student,
      course: map['course'],
      registrationNumber: map['registrationNumber'],
      institution: map['institution'],
      route: map['route'],
      period: map['period'],
    );
  }

  

}


