// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
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
import 'package:smart_uniway/services/database_service.dart';
import 'package:smart_uniway/services/theme_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DatabaseService.instance.database;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartUniwayApp(),
    ),
  );

  FlutterNativeSplash.remove();
}

class SmartUniwayApp extends StatelessWidget {
  const SmartUniwayApp({super.key});

  // --- CORREÇÃO AQUI ---
  // As cores são definidas aqui, na classe principal
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color primaryAccent = Color(0xFFE9B44C);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const _SmartUniwayCore(),
    );
  }
}

class _SmartUniwayCore extends StatelessWidget {
  const _SmartUniwayCore();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- TEMA ESCURO ---
    final darkTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      // --- CORREÇÃO AQUI ---
      // Acessa as cores da classe SmartUniwayApp
      scaffoldBackgroundColor: SmartUniwayApp.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 28),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: SmartUniwayApp.primaryAccent,
        brightness: Brightness.dark,
        surface: SmartUniwayApp.darkBackground,
      ),
    );

    // --- TEMA CLARO ---
    final lightTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      // --- CORREÇÃO AQUI ---
      scaffoldBackgroundColor: SmartUniwayApp.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black, size: 28),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 20,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: SmartUniwayApp.primaryAccent,
        brightness: Brightness.light,
        surface: SmartUniwayApp.lightBackground,
        primary: SmartUniwayApp.primaryAccent,
      ),
    );

    return MaterialApp(
      title: 'Smart Uniway',
      debugShowCheckedModeBanner: false,

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,

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
            if (settings.arguments is User) {
              final user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (_) =>
                    AuthProvider(user: user, child: const StudentHomeScreen()),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/admin_home':
            if (settings.arguments is User) {
              final user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (_) =>
                    AuthProvider(user: user, child: const AdminHomeScreen()),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
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
        return null;
      },
    );
  }
}
