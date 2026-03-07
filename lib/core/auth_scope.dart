import 'package:flutter/widgets.dart';
import 'auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AuthController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree.');
    return scope!.notifier!;
  }
}
