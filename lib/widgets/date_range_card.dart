import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class DateRangeCard extends StatelessWidget {
  const DateRangeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.periwinkle.withOpacity(0.85),
            AppTheme.deepBlue.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sep 02 - Sep 09',
                  style: textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('24h',
                style: textTheme.labelLarge?.copyWith(color: AppTheme.deepBlue)),
          ),
        ],
      ),
    );
  }
}
