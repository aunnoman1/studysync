import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lightweight value-notifier so any widget can toggle light ↔ dark.
class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  ThemeModeNotifier([super.value = ThemeMode.light]);

  void toggle() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

class AppTheme {
  // ──────────────────── Brand colours ────────────────────
  static const Color blue = Color(0xFF2563EB);
  static const Color blueHover = Color(0xFF1D4ED8);
  static const Color blueLight = Color(0xFF60A5FA);

  // ──────────────────── Dark palette ────────────────────
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D2E);
  static const Color darkBorder = Color(0xFF2A2D3E);
  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ──────────────────── Light palette ────────────────────
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightInputFill = Color(0xFFF9FAFB);
  static const Color lightInputBorder = Color(0xFFD1D5DB);

  // Back-compat aliases (light defaults)
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color surface = lightSurface;
  static const Color border = lightBorder;

  // ──────────────────── Animation tokens ────────────────────
  static const Duration duration = Duration(milliseconds: 220);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOutCubic;

  // ──────────────────── Radius ────────────────────
  static const double radius = 14.0;
  static const double radiusSm = 10.0;

  // ──────────────────── Shadows ────────────────────
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get darkShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lightShadowHover => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ──────────────────── Card decoration helper ────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    bool hovered = false,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? darkSurface : lightSurface),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (isDark ? darkBorder : lightBorder).withValues(alpha: hovered ? 1.0 : 0.8),
      ),
      boxShadow: hovered
          ? (isDark ? darkShadow : lightShadowHover)
          : (isDark ? darkShadow : lightShadow),
    );
  }

  // ──────────────────── Text theme ────────────────────
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }

  // ──────────────────── DARK theme ────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(color: darkTextSecondary),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: darkTextPrimary),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        secondary: blue,
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBackground,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: blueLight,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: darkSurface,
      dividerColor: darkBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF232636),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  // ──────────────────── LIGHT theme ────────────────────
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(color: lightTextSecondary),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: lightTextPrimary),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        secondary: blue,
        surface: lightSurface,
        onSurface: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBackground,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: blue,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: lightSurface,
      dividerColor: lightBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: lightInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: lightInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
