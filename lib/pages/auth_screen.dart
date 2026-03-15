import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/auth_controller.dart';
import '../widgets/app_select.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  void _toggle() {
    widget.controller.clearError();
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.skyBlue.withOpacity(0.1),
              AppTheme.periwinkle.withOpacity(0.15),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final cardWidth = maxWidth >= 520 ? 420.0 : maxWidth * 0.92;

              return Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -10,
                    child:
                        _softSquare(color: AppTheme.skyBlue.withOpacity(0.18)),
                  ),
                  Positioned(
                    top: 40,
                    left: 40,
                    child: _softSquare(
                        color: AppTheme.periwinkle.withOpacity(0.16)),
                  ),
                  Positioned(
                    top: 110,
                    right: 70,
                    child:
                        _softSquare(color: AppTheme.skyBlue.withOpacity(0.12)),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Container(
                        width: cardWidth,
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _isLogin
                              ? LoginForm(
                                  key: const ValueKey('login'),
                                  controller: widget.controller,
                                  onToggle: _toggle,
                                )
                              : SignupForm(
                                  key: const ValueKey('signup'),
                                  controller: widget.controller,
                                  onToggle: _toggle,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _softSquare({required Color color}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.controller,
    required this.onToggle,
  });

  final AuthController controller;
  final VoidCallback onToggle;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      await _showErrorDialog(context, 'Email and password are required');
      return;
    }

    widget.controller.clearError();
    final success =
        await widget.controller.login(email: email, password: password);
    if (!mounted || success) return;

    final error = widget.controller.error;
    if (error != null && error.isNotEmpty) {
      await _showErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isBusy = widget.controller.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: AppTheme.deepBlue, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text('Welcome User',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Sign in to continue',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forget Password ?'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : _submit,
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SIGN IN'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No account?',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                TextButton(
                    onPressed: widget.onToggle, child: const Text('Sign up')),
              ],
            ),
          ],
        );
      },
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({
    super.key,
    required this.controller,
    required this.onToggle,
  });

  final AuthController controller;
  final VoidCallback onToggle;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'patient';
  bool _obscure = true;

  static const String _patientSignupMessage =
      'Patient access is created by clinic staff. Ask your provider or organization admin to register your account and share your login details.';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_role == 'patient') {
      await _showErrorDialog(context, _patientSignupMessage);
      return;
    }

    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      await _showErrorDialog(context, 'All fields are required');
      return;
    }

    if (password.length < 6) {
      await _showErrorDialog(
        context,
        'Password must be at least 6 characters',
      );
      return;
    }

    widget.controller.clearError();
    final success = await widget.controller.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: _role,
    );
    if (!mounted || success) return;

    final error = widget.controller.error;
    if (error != null && error.isNotEmpty) {
      await _showErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isBusy = widget.controller.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: AppTheme.deepBlue, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text('Create Account',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Join HealthReach today',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppDropdownFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(
                  value: 'patient',
                  child: Text('Patient (Clinic-created)'),
                ),
                DropdownMenuItem(
                    value: 'medical_professional',
                    child: Text('Medical Professional')),
                DropdownMenuItem(
                    value: 'institutional_partner',
                    child: Text('Institutional Partner')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            if (_role == 'patient') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _patientSignupMessage,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : _submit,
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _role == 'patient'
                            ? 'HOW TO GET ACCESS'
                            : 'CREATE ACCOUNT',
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                TextButton(
                    onPressed: widget.onToggle, child: const Text('Sign in')),
              ],
            ),
          ],
        );
      },
    );
  }
}

Future<void> _showErrorDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
