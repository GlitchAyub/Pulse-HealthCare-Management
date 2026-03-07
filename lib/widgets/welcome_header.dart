import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/auth_scope.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = AuthScope.of(context).user;
    final name = _displayName(user?.firstName, user?.lastName, user?.email);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.skyBlue, AppTheme.periwinkle],
            ),
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded, color: AppTheme.deepBlue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back',
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                name,
                style: textTheme.titleMedium
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        _iconButton(context, Icons.search_rounded),
        const SizedBox(width: 8),
        _iconButton(context, Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _iconButton(BuildContext context, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, color: AppTheme.deepBlue),
    );
  }

  String _displayName(String? first, String? last, String? email) {
    final full = '${first ?? ''} ${last ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (email != null && email.isNotEmpty) return email;
    return 'Welcome';
  }
}
