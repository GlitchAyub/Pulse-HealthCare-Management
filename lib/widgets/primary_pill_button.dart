import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    if (icon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deepBlue,
          padding: padding,
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.deepBlue,
        padding: padding,
        shape: const StadiumBorder(),
      ),
    );
  }
}
