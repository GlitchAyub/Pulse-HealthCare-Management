import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final days = const [17, 18, 19, 20, 21, 22, 23];
    final weekdays = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('December 2026', style: textTheme.titleSmall),
              TextButton(onPressed: () {}, child: const Text('View Calendar')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final isSelected = days[index] == 20;
              return Column(
                children: [
                  Text(weekdays[index],
                      style: textTheme.labelSmall
                          ?.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.deepBlue
                          : AppTheme.background,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        days[index].toString(),
                        style: textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
