import 'package:flutter/material.dart';

class AppTheme {
  // Shared brand colors (Tailwind blue-600/700)
  static const Color blue = Color(0xFF2563EB);
  static const Color blueHover = Color(0xFF1D4ED8);

  // Dark palette (current)
  static const Color darkBackground = Color(0xFF111827); // gray-900
  static const Color darkSurface = Color(0xFF1F2937); // gray-800
  static const Color darkBorder = Color(0xFF374151); // gray-700
  static const Color darkTextPrimary = Color(0xFFE5E7EB); // gray-200
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // gray-400

  // Light palette to match the React design
  static const Color lightBackground = Color(0xFFF3F4F6); // gray-100
  static const Color lightSurface = Color(0xFFFFFFFF); // white
  static const Color lightBorder = Color(0xFFE5E7EB); // gray-200
  static const Color lightTextPrimary = Color(0xFF1F2937); // gray-800
  static const Color lightTextSecondary = Color(0xFF4B5563); // gray-600
  static const Color lightInputFill = Color(0xFFF9FAFB); // gray-50
  static const Color lightInputBorder = Color(0xFFD1D5DB); // gray-300

  // Back-compat aliases used across pages (light theme defaults)
  // These allow usage like `AppTheme.textPrimary` in const expressions.
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color surface = lightSurface;
  static const Color border = lightBorder;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        secondary: blue,
        surface: darkSurface,
        background: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: Color(0xFF60A5FA),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: darkSurface,
      dividerColor: darkBorder,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: darkTextSecondary),
        bodyLarge: TextStyle(color: darkTextPrimary),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        secondary: blue,
        surface: lightSurface,
        background: lightBackground,
        onSurface: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: blue, // brand title similar to React mobile header
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: lightSurface,
      dividerColor: lightBorder,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: lightTextSecondary),
        bodyLarge: TextStyle(color: lightTextPrimary),
        titleLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
