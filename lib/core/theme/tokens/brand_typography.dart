import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

class BrandTypography {
  const BrandTypography._();

  static TextTheme textTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
    required AppThemeVariant variant,
  }) {
    return switch (variant) {
      AppThemeVariant.calmEditorialPremium => _calmEditorialTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.inkPurple => _calmEditorialTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.deepDarkCreator => _deepDarkCreatorTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.neoAnalogJournal => _neoAnalogTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.minimalProductivityPro => _minimalProductivityTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.midnightTealJournal => _midnightTealTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.violetNebulaJournal => _violetNebulaTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
      AppThemeVariant.testedTheme => _testedTheme(
        brightness: brightness,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
      ),
    };
  }

  static TextTheme _calmEditorialTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _deepDarkCreatorTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.3,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        height: 1.3,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _neoAnalogTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.dmSerifText(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.dmSerifText(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.dmSerifText(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.dmSerifText(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _minimalProductivityTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(
      brightness: brightness,
    ).textTheme.apply(bodyColor: textColor, displayColor: textColor);

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: textColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: textColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: secondaryTextColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _midnightTealTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.25,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.15,
        height: 1.25,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.28,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _violetNebulaTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.08,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.32,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme _testedTheme({
    required Brightness brightness,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return inter.copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.08,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.32,
        color: secondaryTextColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: secondaryTextColor,
      ),
    );
  }
}
