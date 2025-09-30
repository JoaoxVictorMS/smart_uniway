// lib/main.dart

import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/screens/login_screen.dart';
import 'package:smart_uniway/screens/registration_screen.dart';
import 'package:smart_uniway/screens/welcome_screen.dart';
import 'package:smart_uniway/screens/student_home_screen.dart';
import 'package:smart_uniway/screens/admin_home_screen.dart';
import 'package:smart_uniway/screens/profile_screen.dart';
import 'package:smart_uniway/screens/student_list_screen.dart';
import 'package:smart_uniway/screens/attendance_screen.dart';

void main() {
  runApp(const SmartUniwayApp());
}

class SmartUniwayApp extends StatelessWidget {
  const SmartUniwayApp({super.key});

  // Paleta de Cores para fácil acesso
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color(0xFFE9B44C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Uniway',
      debugShowCheckedModeBanner: false,

      // Define o tema global do aplicativo
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccentColor,
          brightness: Brightness.dark,
          background: backgroundColor,
        ),
        useMaterial3: true,
      ),

      // A tela inicial continua sendo a WelcomeScreen
      home: const WelcomeScreen(),

      // Usamos onGenerateRoute para lidar com rotas que precisam de argumentos
      onGenerateRoute: (settings) {
        switch (settings.name) {
          // As rotas simples continuam funcionando
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/registration':
            return MaterialPageRoute(
              builder: (_) => const RegistrationScreen(),
            );
          case '/student_home':
            return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
          case '/admin_home':
            return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
          case '/student_list':
            return MaterialPageRoute(builder: (_) => const StudentListScreen());
          case '/attendance':
            return MaterialPageRoute(builder: (_) => const AttendanceScreen());

          // Rota especial para o perfil, que verifica o argumento
          case '/profile':
            // Verifica se o argumento passado é do tipo User
            if (settings.arguments is User) {
              final user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (_) => ProfileScreen(user: user),
              );
            }
            return null; // Rota não encontrada se o argumento for inválido

          default:
            // Rota não encontrada
            return null;
        }
      },
    );
  }
}
