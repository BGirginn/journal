import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The modern design system for Journal V2
class AppTheme {
  // Colors - Modern 2025 Palette
  static const Color primary = Color(0xFF6C63FF); // Vibrant Purple
  static const Color secondary = Color(0xFF00BFA6); // Teal
  static const Color backgroundLight = Color(0xFFF7F9FC); // Cool Grey
  static const Color backgroundDark = Color(0xFF121212); // Deep Black
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Glassmorphism tokens
  static const double glassBlur = 15.0;
  static const double glassOpacity = 0.65;
  static final Color glassBorder = Colors.white.withValues(alpha: 0.2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography - Outfit / Plus Jakarta Sans Style (Bold, Dynamic)
  static TextTheme get textTheme => GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    bodyLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.outfit(
      // Button text
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Card Theme
  static BoxDecoration glassDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: (isDark ? Colors.black : Colors.white).withValues(
        alpha: glassOpacity,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surfaceLight,
    ),
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surfaceDark,
    ),
    textTheme: textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
