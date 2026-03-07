import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/auth_scope.dart';
import 'core/auth_controller.dart';
import 'widgets/auth_gate.dart';

class HealthReachApp extends StatelessWidget {
  const HealthReachApp({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: authController,
      child: MaterialApp(
        title: 'HealthReach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: AuthGate(controller: authController),
      ),
    );
  }
}
