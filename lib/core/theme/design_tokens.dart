import 'package:flutter/material.dart';

/// Centralized semantic tokens for the warm and vibrant Journal App brand.
class AppColorTokens {
  const AppColorTokens._();

  // Brand accents
  static const Color amber = Color(0xFFC97A1E);
  static const Color coral = Color(0xFFE86D50);
  static const Color gold = Color(0xFFCF9A2E);

  // Light surfaces
  static const Color lightBackground = Color(0xFFFFF6EC);
  static const Color lightSurface = Color(0xFFFFFBF6);
  static const Color lightSurfaceContainer = Color(0xFFF9ECDA);
  static const Color lightSurfaceContainerAlt = Color(0xFFF2DFCA);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF1F1915);
  static const Color darkSurface = Color(0xFF2A221D);
  static const Color darkSurfaceContainer = Color(0xFF3A2E25);
  static const Color darkSurfaceContainerAlt = Color(0xFF4B3A2D);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: amber,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFEDDB4),
    onPrimaryContainer: Color(0xFF3F2500),
    secondary: coral,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9CF),
    onSecondaryContainer: Color(0xFF472018),
    tertiary: gold,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF5E1B7),
    onTertiaryContainer: Color(0xFF3F2E09),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: lightSurface,
    onSurface: Color(0xFF2F241C),
    onSurfaceVariant: Color(0xFF5E4A3D),
    outline: Color(0xFF9A7D66),
    outlineVariant: Color(0xFFD8C0AD),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF3F3127),
    onInverseSurface: Color(0xFFFFEDE0),
    inversePrimary: Color(0xFFFFB76B),
    surfaceTint: amber,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB76B),
    onPrimary: Color(0xFF4E2800),
    primaryContainer: Color(0xFF6D3E00),
    onPrimaryContainer: Color(0xFFFFDDB5),
    secondary: Color(0xFFFFA790),
    onSecondary: Color(0xFF5A1E11),
    secondaryContainer: Color(0xFF7A3121),
    onSecondaryContainer: Color(0xFFFFDBD2),
    tertiary: Color(0xFFF1C86E),
    onTertiary: Color(0xFF433106),
    tertiaryContainer: Color(0xFF5E4610),
    onTertiaryContainer: Color(0xFFFFE3A6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: darkSurface,
    onSurface: Color(0xFFF7E8D9),
    onSurfaceVariant: Color(0xFFE2C9B3),
    outline: Color(0xFFB89A83),
    outlineVariant: Color(0xFF5A4638),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF8E7D7),
    onInverseSurface: Color(0xFF2B2119),
    inversePrimary: amber,
    surfaceTint: Color(0xFFFFB76B),
  );
}
