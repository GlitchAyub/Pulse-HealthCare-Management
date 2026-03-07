import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/vital_stat.dart';

class VitalCard extends StatelessWidget {
  const VitalCard({
    super.key,
    required this.stat,
    required this.icon,
  });

  final VitalStat stat;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.title,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Text(
                  '${stat.value} ${stat.unit}',
                  style: textTheme.titleMedium,
                ),
                Text(
                  stat.trendLabel,
                  style: textTheme.labelSmall
                      ?.copyWith(color: AppTheme.deepBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
