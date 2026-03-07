import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.skyBlue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppTheme.deepBlue
                            : AppTheme.textMuted,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
