import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppColorTheme {
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  purple('Purple', Colors.deepPurple),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  teal('Teal', Colors.teal),
  pink('Pink', Colors.pink),
  gold('Gold', Color(0xFFFFD700));

  final String label;
  final Color color;

  const AppColorTheme(this.label, this.color);
}

class AppTheme {
  static ThemeData getTheme(AppColorTheme colorTheme, Brightness brightness) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: colorTheme.color,
      brightness: brightness,
    );

    // Deepen the dark mode for a more "luxurious black/grey" feel
    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
        background: const Color(0xFF101010),
        onBackground: Colors.white,
        surfaceVariant: const Color(0xFF1E1E1E),
        onSurfaceVariant: Colors.white70,
        primary: colorTheme == AppColorTheme.gold
            ? const Color(0xFFFFD700)
            : colorScheme.primary,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
