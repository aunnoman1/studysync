import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF111827);
  static const Color surface = Color(0xFF1F2937);
  static const Color border = Color(0xFF374151);
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueHover = Color(0xFF1D4ED8);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        secondary: blue,
        surface: surface,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: Color(0xFF60A5FA),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: surface,
      dividerColor: border,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textSecondary),
        bodyLarge: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}


