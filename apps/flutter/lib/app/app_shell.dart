import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'home_screen.dart';

enum _AppState { login, home }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppState _state = _AppState.login;
  String? _token;
  String? _tenantSlug;

  void _onLogin(String token, String tenantSlug) {
    setState(() {
      _token = token;
      _tenantSlug = tenantSlug;
      _state = _AppState.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _AppState.login => LoginScreen(onLogin: _onLogin),
      _AppState.home => HomeScreen(
          key: ValueKey('$_token-$_tenantSlug'),
          token: _token!,
          tenantSlug: _tenantSlug!,
        ),
    };
  }
}
