import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color skyBlue = Color(0xFF5CC8FF);
  static const Color deepBlue = Color(0xFF3A7BD5);
  static const Color periwinkle = Color(0xFF7C83FF);
  static const Color softBlue = Color(0xFFB9DDFF);
  static const Color background = Color(0xFFF4F8FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2B41);
  static const Color textMuted = Color(0xFF6B7A90);
  static const Color border = Color(0xFFE0E7FF);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A3A7BD5),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: skyBlue,
        secondary: periwinkle,
        surface: card,
        background: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        shadowColor: const Color(0x1A3A7BD5),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge?.copyWith(color: textPrimary),
        backgroundColor: Colors.white,
        selectedColor: skyBlue.withOpacity(0.16),
        disabledColor: border,
        shape: StadiumBorder(side: BorderSide(color: border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: skyBlue.withOpacity(0.16),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final base =
              textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
          if (states.contains(MaterialState.selected)) {
            return base?.copyWith(color: deepBlue);
          }
          return base?.copyWith(color: textMuted);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: deepBlue);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: skyBlue, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
