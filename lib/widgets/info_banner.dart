import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'primary_pill_button.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaLabel = 'View All',
  });

  final String title;
  final String subtitle;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.skyBlue.withOpacity(0.2),
            AppTheme.periwinkle.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on_rounded,
                    color: AppTheme.deepBlue),
              ),
              const SizedBox(width: 10),
              Text('24/7 Available',
                  style: textTheme.labelLarge
                      ?.copyWith(color: AppTheme.deepBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          PillButton(label: ctaLabel, onPressed: () {}, compact: true),
        ],
      ),
    );
  }
}
