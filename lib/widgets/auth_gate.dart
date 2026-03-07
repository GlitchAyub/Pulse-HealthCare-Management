import 'package:flutter/material.dart';
import '../core/auth_controller.dart';
import '../pages/auth_screen.dart';
import '../pages/splash_page.dart';
import 'app_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (_showSplash || widget.controller.isInitializing) {
          return const SplashPage();
        }
        if (widget.controller.user == null) {
          return AuthScreen(controller: widget.controller);
        }
        return const AppShell();
      },
    );
  }
}
