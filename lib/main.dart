// lib/main.dart

import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/screens/admin_home_screen.dart';
import 'package:smart_uniway/screens/attendance_screen.dart';
import 'package:smart_uniway/screens/login_screen.dart';
import 'package:smart_uniway/screens/profile_screen.dart';
import 'package:smart_uniway/screens/registration_screen.dart';
import 'package:smart_uniway/screens/report_screen.dart';
import 'package:smart_uniway/screens/student_home_screen.dart';
import 'package:smart_uniway/screens/student_list_screen.dart';
import 'package:smart_uniway/screens/welcome_screen.dart';
import 'package:smart_uniway/services/auth_provider.dart';

void main() {
  runApp(const SmartUniwayApp());
}

class SmartUniwayApp extends StatelessWidget {
  const SmartUniwayApp({super.key});

  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Uniway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccentColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A2E), // CORRIGIDO: de 'background' para 'surface'
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/registration':
            return MaterialPageRoute(
              builder: (_) => const RegistrationScreen(),
            );
          case '/student_home':
            // Assumimos que a navegação para student_home sempre usará AuthProvider
            // Se o argumento for nulo, redirecionamos para o login
            if (settings.arguments is User) {
              final user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (_) =>
                    AuthProvider(user: user, child: const StudentHomeScreen()),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/admin_home':
            return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
          case '/student_list':
            return MaterialPageRoute(builder: (_) => const StudentListScreen());
          case '/attendance':
            return MaterialPageRoute(builder: (_) => const AttendanceScreen());
          case '/report':
            if (settings.arguments is String) {
              final institution = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ReportScreen(institution: institution),
              );
            }
            break;
          case '/profile':
            if (settings.arguments is User) {
              final user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (_) => ProfileScreen(user: user),
              );
            }
            break;
        }
        // CORRIGIDO: Garante que um valor é retornado caso nenhuma rota corresponda.
        // Retornar null é o comportamento padrão para rota não encontrada.
        return null;
      },
    );
  }
}
