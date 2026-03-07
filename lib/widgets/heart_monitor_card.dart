import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class HeartMonitorCard extends StatelessWidget {
  const HeartMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heart Health Monitor',
                        style: textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Real-time vitals tracking',
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textMuted)),
                    const SizedBox(height: 14),
                    _statChip(
                      context,
                      label: 'HRV',
                      value: '84 ms',
                      note: 'Excellent',
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.skyBlue.withOpacity(0.3),
                      AppTheme.periwinkle.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppTheme.deepBlue, size: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  context,
                  title: 'Blood Pressure',
                  value: '120/80',
                  note: 'Normal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  context,
                  title: 'Cholesterol',
                  value: '166',
                  note: 'mg/dl',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context,
      {required String label, required String value, required String note}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleSmall),
          Text(note,
              style: textTheme.labelSmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context,
      {required String title, required String value, required String note}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: textTheme.labelSmall?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: textTheme.titleSmall),
          Text(note,
              style: textTheme.labelSmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
