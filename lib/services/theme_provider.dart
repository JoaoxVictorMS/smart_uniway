// lib/services/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Chave para salvar a preferência no dispositivo
  static const String _themePrefKey = 'isDarkTheme';

  // O estado padrão é o nosso tema escuro original
  ThemeMode _themeMode = ThemeMode.dark;

  // Getter público para que as telas possam ler o estado atual
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme(); // Carrega a preferência assim que o app inicia
  }

  // Carrega a preferência salva no dispositivo
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Lê a preferência. Se não houver nada salvo (!), o padrão é 'true' (escuro).
    bool isDark = prefs.getBool(_themePrefKey) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Função para alternar o tema
  Future<void> toggleTheme() async {
    // Alterna o estado
    _themeMode = (_themeMode == ThemeMode.dark)
        ? ThemeMode.light
        : ThemeMode.dark;

    // Salva a nova preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _themeMode == ThemeMode.dark);

    // Notifica todas as telas que estão "ouvindo" para que elas se redesenhem
    notifyListeners();
  }
}
