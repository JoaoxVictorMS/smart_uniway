// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:smart_uniway/models/user_model.dart';

class AuthProvider extends InheritedWidget {
  final User user;

  const AuthProvider({super.key, required this.user, required super.child});

  // Este método permite que qualquer widget filho acesse os dados do usuário.
  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return user.id != oldWidget.user.id;
  }
}
