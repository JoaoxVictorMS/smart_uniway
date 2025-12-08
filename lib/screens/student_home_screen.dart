// lib/screens/student_home_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:smart_uniway/services/auth_provider.dart';
import 'package:smart_uniway/services/database_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color primaryAccentColor = Color.fromARGB(255, 157, 132, 183);
  static const Color presentColor = Colors.green;
  static const Color absentColor = Colors.red;

  late Future<List<Map<String, dynamic>>> _historyFuture;
  User? _currentUser;
  String? _profileImagePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = AuthProvider.of(context)?.user;
    if (_currentUser != null) {
      _historyFuture = DatabaseService.instance.getAttendanceHistoryForStudent(
        _currentUser!.id!,
      );
      _loadProfileImage();
    } else {
      _historyFuture = Future.value([]);
    }
  }

  // Carrega a foto de perfil salva
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${_currentUser!.id}');
    
    setState(() {
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImagePath = imagePath;
      } else {
        // Remove a referência se o arquivo não existir ou foi removido
        _profileImagePath = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      drawer: _buildAppDrawer(context, _currentUser),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Bem-vindo, ${_currentUser?.name ?? ''}!',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu histórico de presença recente:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white.withAlpha(179),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryAccentColor,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar histórico.',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum registro de presença encontrado.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final history = snapshot.data!;
                      return ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.white.withAlpha(51)),
                        itemBuilder: (context, index) {
                          final record = history[index];
                          return _buildHistoryListItem(record);
                        },
                      );
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

  Widget _buildHistoryListItem(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final date = DateTime.parse(record['date'] as String);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    IconData icon;
    Color color;
    String statusText;

    switch (status) {
      case 'present':
        icon = Icons.check_circle;
        color = presentColor;
        statusText = 'Presente';
        break;
      case 'absent':
        icon = Icons.cancel;
        color = absentColor;
        statusText = 'Ausente';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        statusText = 'Não Marcado';
    }

    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(
        formattedDate,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(statusText, style: TextStyle(color: color)),
    );
  }

  Widget _buildAppDrawer(BuildContext context, User? user) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            color: backgroundColor.withAlpha(200),
            child: Column(
              children: [
                if (user != null)
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      '${user.name} ${user.surname}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    accountEmail: Text(
                      user.email,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: primaryAccentColor,
                      backgroundImage: _profileImagePath != null
                          ? FileImage(File(_profileImagePath!))
                          : null,
                      child: _profileImagePath == null
                          ? Text(
                              '${user.name[0]}${user.surname[0]}',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                    ),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Meu Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () async {
                    if (user != null) {
                      Navigator.pop(context);
                      await Navigator.pushNamed(context, '/profile', arguments: user);
                      // Recarrega a foto após voltar da tela de perfil
                      _loadProfileImage();
                    }
                  },
                ),
                const Spacer(),
                const Divider(color: Colors.white30, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}