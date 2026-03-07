import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText = 'Search doctors, specialties...',
  });

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.skyBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune_rounded, color: AppTheme.deepBlue),
        ),
      ),
    );
  }
}
