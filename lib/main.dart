import 'package:flutter/material.dart';
import 'app.dart';
import 'core/auth_controller.dart';
import 'core/session_store.dart';
import 'data/healthreach_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStore = SessionStore.instance;
  await sessionStore.init();
  final api = HealthReachApi(sessionStore: sessionStore);
  final authController = AuthController(api: api, sessionStore: sessionStore);
  await authController.bootstrap();
  runApp(HealthReachApp(authController: authController));
}
