import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

class BrandColors {
  const BrandColors._();

  // Default exported scale maps to Concept 1 (Calm Editorial Premium)
  static const Color primary900 = Color(0xFF1F2240);
  static const Color primary800 = Color(0xFF2C2F63);
  static const Color primary700 = Color(0xFF3A3ECF);
  static const Color primary600 = Color(0xFF4C4FF6);
  static const Color primary500 = Color(0xFF6366FF);

  static const Color warmAccent = Color(0xFFFFB84D);
  static const Color softMint = Color(0xFF5CC8A1);
  static const Color mutedRose = Color(0xFFC76D5A);

  static const Color lightBackground = Color(0xFFF7F6F3);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE8EAF2);

  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkCard = Color(0xFF1A1D26);
  static const Color darkElevated = Color(0xFF222534);
  static const Color darkDivider = Color(0xFF2A2E3D);

  static const Color gray300 = Color(0xFFCDD2DF);
  static const Color gray500 = Color(0xFF7B8095);

  // Concept 1 - Calm Editorial Premium
  static const ColorScheme calmEditorialLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4C4FF6),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8E9FF),
    onPrimaryContainer: Color(0xFF1F2240),
    secondary: Color(0xFF5CC8A1),
    onSecondary: Color(0xFF0B2B20),
    secondaryContainer: Color(0xFFDAF4EA),
    onSecondaryContainer: Color(0xFF183B30),
    tertiary: Color(0xFFFFB84D),
    onTertiary: Color(0xFF3B2A07),
    tertiaryContainer: Color(0xFFFFE7BE),
    onTertiaryContainer: Color(0xFF5C4108),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF14161C),
    onSurfaceVariant: Color(0xFF7B8095),
    outline: Color(0xFFE8EAF2),
    outlineVariant: Color(0xFFE8EAF2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1A1D26),
    onInverseSurface: Color(0xFFF7F6F3),
    inversePrimary: Color(0xFF6366FF),
    surfaceTint: Color(0xFF4C4FF6),
  );

  static const ColorScheme calmEditorialDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6366FF),
    onPrimary: Color(0xFF0F1117),
    primaryContainer: Color(0xFF2C2F63),
    onPrimaryContainer: Color(0xFFE8E9FF),
    secondary: Color(0xFF5CC8A1),
    onSecondary: Color(0xFF0B2B20),
    secondaryContainer: Color(0xFF1D4A38),
    onSecondaryContainer: Color(0xFFDAF4EA),
    tertiary: Color(0xFFFFB84D),
    onTertiary: Color(0xFF3B2A07),
    tertiaryContainer: Color(0xFF6A4A11),
    onTertiaryContainer: Color(0xFFFFE7BE),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF1A1D26),
    onSurface: Color(0xFFF5F6FA),
    onSurfaceVariant: Color(0xFF8C91A4),
    outline: Color(0xFF2A2E3D),
    outlineVariant: Color(0xFF2A2E3D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF7F6F3),
    onInverseSurface: Color(0xFF14161C),
    inversePrimary: Color(0xFF4C4FF6),
    surfaceTint: Color(0xFF6366FF),
  );

  // Legacy palette - Ink & Purple
  static const ColorScheme inkPurpleLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7C3AED),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEDE9FE),
    onPrimaryContainer: Color(0xFF3B0764),
    secondary: Color(0xFF14B8A6),
    onSecondary: Color(0xFF042F2E),
    secondaryContainer: Color(0xFFCCFBF1),
    onSecondaryContainer: Color(0xFF134E4A),
    tertiary: Color(0xFFF97316),
    onTertiary: Color(0xFF431407),
    tertiaryContainer: Color(0xFFFFEDD5),
    onTertiaryContainer: Color(0xFF7C2D12),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFE5E7EB),
    outlineVariant: Color(0xFFE5E7EB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFFA855F7),
    surfaceTint: Color(0xFF7C3AED),
  );

  static const ColorScheme inkPurpleDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA855F7),
    onPrimary: Color(0xFF0A0A0F),
    primaryContainer: Color(0xFF6D28D9),
    onPrimaryContainer: Color(0xFFF3E8FF),
    secondary: Color(0xFF2DD4BF),
    onSecondary: Color(0xFF042F2E),
    secondaryContainer: Color(0xFF115E59),
    onSecondaryContainer: Color(0xFFCCFBF1),
    tertiary: Color(0xFFFB923C),
    onTertiary: Color(0xFF431407),
    tertiaryContainer: Color(0xFF9A3412),
    onTertiaryContainer: Color(0xFFFFEDD5),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF14141A),
    onSurface: Color(0xFFF9FAFB),
    onSurfaceVariant: Color(0xFFC7CAD1),
    outline: Color(0xFF2A2A33),
    outlineVariant: Color(0xFF2A2A33),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF9FAFB),
    onInverseSurface: Color(0xFF0A0A0F),
    inversePrimary: Color(0xFF7C3AED),
    surfaceTint: Color(0xFFA855F7),
  );

  // Concept 2 - Deep Dark Creator
  static const ColorScheme deepDarkCreatorLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4C4FF6),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3E4FF),
    onPrimaryContainer: Color(0xFF1F2240),
    secondary: Color(0xFF5FF2C3),
    onSecondary: Color(0xFF003828),
    secondaryContainer: Color(0xFFC9FFE9),
    onSecondaryContainer: Color(0xFF004D37),
    tertiary: Color(0xFFFFB84D),
    onTertiary: Color(0xFF3B2A07),
    tertiaryContainer: Color(0xFFFFE7BE),
    onTertiaryContainer: Color(0xFF5C4108),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF14161C),
    onSurfaceVariant: Color(0xFF72798D),
    outline: Color(0xFFDCE0EA),
    outlineVariant: Color(0xFFDCE0EA),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1A1D26),
    onInverseSurface: Color(0xFFF5F6FA),
    inversePrimary: Color(0xFF6366FF),
    surfaceTint: Color(0xFF4C4FF6),
  );

  static const ColorScheme deepDarkCreatorDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6366FF),
    onPrimary: Color(0xFF0E0F14),
    primaryContainer: Color(0xFF2B2F73),
    onPrimaryContainer: Color(0xFFE3E4FF),
    secondary: Color(0xFF5FF2C3),
    onSecondary: Color(0xFF003828),
    secondaryContainer: Color(0xFF0E5F49),
    onSecondaryContainer: Color(0xFFC9FFE9),
    tertiary: Color(0xFFFFB84D),
    onTertiary: Color(0xFF3B2A07),
    tertiaryContainer: Color(0xFF6A4A11),
    onTertiaryContainer: Color(0xFFFFE7BE),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF1A1D26),
    onSurface: Color(0xFFF5F6FA),
    onSurfaceVariant: Color(0xFF8C91A4),
    outline: Color(0xFF2A2E3D),
    outlineVariant: Color(0xFF2A2E3D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF5F6FA),
    onInverseSurface: Color(0xFF0E0F14),
    inversePrimary: Color(0xFF4C4FF6),
    surfaceTint: Color(0xFF6366FF),
  );

  // Concept 3 - Neo Analog Journal
  static const ColorScheme neoAnalogLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F6D7A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCE7EB),
    onPrimaryContainer: Color(0xFF2F2A3A),
    secondary: Color(0xFFC76D5A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6DDD6),
    onSecondaryContainer: Color(0xFF5A2E25),
    tertiary: Color(0xFF7B8F71),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0EAD9),
    onTertiaryContainer: Color(0xFF2F3C2A),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFAF8F3),
    onSurface: Color(0xFF2F2A3A),
    onSurfaceVariant: Color(0xFF7A7585),
    outline: Color(0xFFE6E1D7),
    outlineVariant: Color(0xFFE6E1D7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2B2735),
    onInverseSurface: Color(0xFFFAF8F3),
    inversePrimary: Color(0xFF4F6D7A),
    surfaceTint: Color(0xFF4F6D7A),
  );

  static const ColorScheme neoAnalogDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF89A1AC),
    onPrimary: Color(0xFF1E1B26),
    primaryContainer: Color(0xFF3F5561),
    onPrimaryContainer: Color(0xFFDCE7EB),
    secondary: Color(0xFFD98A78),
    onSecondary: Color(0xFF2B1A15),
    secondaryContainer: Color(0xFF6D3B2F),
    onSecondaryContainer: Color(0xFFF6DDD6),
    tertiary: Color(0xFF9AAE90),
    onTertiary: Color(0xFF1E2A1A),
    tertiaryContainer: Color(0xFF4D5E45),
    onTertiaryContainer: Color(0xFFE0EAD9),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF2B2735),
    onSurface: Color(0xFFF1ECE3),
    onSurfaceVariant: Color(0xFFB4AEBE),
    outline: Color(0xFF3A3447),
    outlineVariant: Color(0xFF3A3447),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFAF8F3),
    onInverseSurface: Color(0xFF2F2A3A),
    inversePrimary: Color(0xFF4F6D7A),
    surfaceTint: Color(0xFF89A1AC),
  );

  // Concept 4 - Minimal Productivity Pro
  static const ColorScheme minimalProductivityLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: Color(0xFF10B981),
    onSecondary: Color(0xFF022C22),
    secondaryContainer: Color(0xFFD1FAE5),
    onSecondaryContainer: Color(0xFF065F46),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Color(0xFF452B00),
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF78350F),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFE5E7EB),
    outlineVariant: Color(0xFFE5E7EB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFF3B82F6),
    surfaceTint: Color(0xFF2563EB),
  );

  static const ColorScheme minimalProductivityDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF3B82F6),
    onPrimary: Color(0xFF0A1F44),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF03261D),
    secondaryContainer: Color(0xFF065F46),
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF422006),
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFEF3C7),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF1F2937),
    onSurface: Color(0xFFF9FAFB),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF374151),
    outlineVariant: Color(0xFF374151),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF111827),
    inversePrimary: Color(0xFF2563EB),
    surfaceTint: Color(0xFF3B82F6),
  );

  // Concept 5 - Midnight Teal Journal
  static const ColorScheme midnightTealJournalLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCCFBF1),
    onPrimaryContainer: Color(0xFF134E4A),
    secondary: Color(0xFF059669),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1FAE5),
    onSecondaryContainer: Color(0xFF065F46),
    tertiary: Color(0xFF0891B2),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCFFAFE),
    onTertiaryContainer: Color(0xFF164E63),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFD1D5DB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1A1D24),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF2DD4BF),
    surfaceTint: Color(0xFF0F766E),
  );

  static const ColorScheme midnightTealJournalDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4BF),
    onPrimary: Color(0xFF042F2E),
    primaryContainer: Color(0xFF115E59),
    onPrimaryContainer: Color(0xFFCCFBF1),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF03261D),
    secondaryContainer: Color(0xFF065F46),
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: Color(0xFF67E8F9),
    onTertiary: Color(0xFF083344),
    tertiaryContainer: Color(0xFF155E75),
    onTertiaryContainer: Color(0xFFCFFAFE),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF2A2E35),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF374151),
    outlineVariant: Color(0xFF374151),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF1F2937),
    inversePrimary: Color(0xFF0F766E),
    surfaceTint: Color(0xFF2DD4BF),
  );

  // Concept 6 - Violet Nebula Journal
  static const ColorScheme violetNebulaJournalLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6D28D9),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEDE9FE),
    onPrimaryContainer: Color(0xFF3B0764),
    secondary: Color(0xFF8B5CF6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF1E8FF),
    onSecondaryContainer: Color(0xFF3C1D63),
    tertiary: Color(0xFFB794F4),
    onTertiary: Color(0xFF2B124B),
    tertiaryContainer: Color(0xFFF3E8FF),
    onTertiaryContainer: Color(0xFF3C1D63),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B1630),
    onSurfaceVariant: Color(0xFF5E5A72),
    outline: Color(0xFFD9D6E9),
    outlineVariant: Color(0xFFDED9EE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF121826),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF8B5CF6),
    surfaceTint: Color(0xFF6D28D9),
  );

  static const ColorScheme violetNebulaJournalDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFF1B1033),
    primaryContainer: Color(0xFF5A3AB4),
    onPrimaryContainer: Color(0xFFEDE4FF),
    secondary: Color(0xFFB794F4),
    onSecondary: Color(0xFF24113D),
    secondaryContainer: Color(0xFF5A3B7D),
    onSecondaryContainer: Color(0xFFF3E9FF),
    tertiary: Color(0xFFA78BFA),
    onTertiary: Color(0xFF1B1033),
    tertiaryContainer: Color(0xFF4B2A7E),
    onTertiaryContainer: Color(0xFFEDE4FF),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF121826),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFFACB4C8),
    outline: Color(0xFF2A3346),
    outlineVariant: Color(0xFF2A3346),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF121826),
    inversePrimary: Color(0xFF6D28D9),
    surfaceTint: Color(0xFF8B5CF6),
  );

  // Concept 7 - Tested Theme
  static const ColorScheme testedThemeLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEDE9FE),
    onPrimaryContainer: Color(0xFF2E1065),
    secondary: Color(0xFF38BDF8),
    onSecondary: Color(0xFF082F49),
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondaryContainer: Color(0xFF0C4A6E),
    tertiary: Color(0xFFB794F4),
    onTertiary: Color(0xFF2B124B),
    tertiaryContainer: Color(0xFFF3E8FF),
    onTertiaryContainer: Color(0xFF3C1D63),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B1630),
    onSurfaceVariant: Color(0xFF5E5A72),
    outline: Color(0xFFD9D6E9),
    outlineVariant: Color(0xFFDED9EE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF121826),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF8B5CF6),
    surfaceTint: Color(0xFF8B5CF6),
  );

  static const ColorScheme testedThemeDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFF1B1033),
    primaryContainer: Color(0xFF5A3AB4),
    onPrimaryContainer: Color(0xFFEDE4FF),
    secondary: Color(0xFF38BDF8),
    onSecondary: Color(0xFF042F4B),
    secondaryContainer: Color(0xFF0C4A6E),
    onSecondaryContainer: Color(0xFFE0F2FE),
    tertiary: Color(0xFFB794F4),
    onTertiary: Color(0xFF24113D),
    tertiaryContainer: Color(0xFF5A3B7D),
    onTertiaryContainer: Color(0xFFF3E9FF),
    error: Color(0xFFFB7185),
    onError: Color(0xFF500724),
    errorContainer: Color(0xFF881337),
    onErrorContainer: Color(0xFFFFE4E6),
    surface: Color(0xFF121826),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFFACB4C8),
    outline: Color(0xFF2A3346),
    outlineVariant: Color(0xFF2A3346),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF121826),
    inversePrimary: Color(0xFF7C3AED),
    surfaceTint: Color(0xFF8B5CF6),
  );

  // Backward-compatible aliases used by legacy tokens.
  static const ColorScheme lightScheme = calmEditorialLightScheme;
  static const ColorScheme darkScheme = calmEditorialDarkScheme;
}

class BrandPalette {
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;
  final JournalSemanticColors lightSemantic;
  final JournalSemanticColors darkSemantic;

  const BrandPalette({
    required this.lightScheme,
    required this.darkScheme,
    required this.lightSemantic,
    required this.darkSemantic,
  });
}

class BrandPalettes {
  const BrandPalettes._();

  static const BrandPalette calmEditorialPremium = BrandPalette(
    lightScheme: BrandColors.calmEditorialLightScheme,
    darkScheme: BrandColors.calmEditorialDarkScheme,
    lightSemantic: JournalSemanticColors.lightCalmEditorialPremium,
    darkSemantic: JournalSemanticColors.darkCalmEditorialPremium,
  );

  static const BrandPalette inkPurple = BrandPalette(
    lightScheme: BrandColors.inkPurpleLightScheme,
    darkScheme: BrandColors.inkPurpleDarkScheme,
    lightSemantic: JournalSemanticColors.lightInkPurple,
    darkSemantic: JournalSemanticColors.darkInkPurple,
  );

  static const BrandPalette deepDarkCreator = BrandPalette(
    lightScheme: BrandColors.deepDarkCreatorLightScheme,
    darkScheme: BrandColors.deepDarkCreatorDarkScheme,
    lightSemantic: JournalSemanticColors.lightDeepDarkCreator,
    darkSemantic: JournalSemanticColors.darkDeepDarkCreator,
  );

  static const BrandPalette neoAnalogJournal = BrandPalette(
    lightScheme: BrandColors.neoAnalogLightScheme,
    darkScheme: BrandColors.neoAnalogDarkScheme,
    lightSemantic: JournalSemanticColors.lightNeoAnalogJournal,
    darkSemantic: JournalSemanticColors.darkNeoAnalogJournal,
  );

  static const BrandPalette minimalProductivityPro = BrandPalette(
    lightScheme: BrandColors.minimalProductivityLightScheme,
    darkScheme: BrandColors.minimalProductivityDarkScheme,
    lightSemantic: JournalSemanticColors.lightMinimalProductivityPro,
    darkSemantic: JournalSemanticColors.darkMinimalProductivityPro,
  );

  static const BrandPalette midnightTealJournal = BrandPalette(
    lightScheme: BrandColors.midnightTealJournalLightScheme,
    darkScheme: BrandColors.midnightTealJournalDarkScheme,
    lightSemantic: JournalSemanticColors.lightMidnightTealJournal,
    darkSemantic: JournalSemanticColors.darkMidnightTealJournal,
  );

  static const BrandPalette violetNebulaJournal = BrandPalette(
    lightScheme: BrandColors.violetNebulaJournalLightScheme,
    darkScheme: BrandColors.violetNebulaJournalDarkScheme,
    lightSemantic: JournalSemanticColors.lightVioletNebulaJournal,
    darkSemantic: JournalSemanticColors.darkVioletNebulaJournal,
  );

  static const BrandPalette testedTheme = BrandPalette(
    lightScheme: BrandColors.testedThemeLightScheme,
    darkScheme: BrandColors.testedThemeDarkScheme,
    lightSemantic: JournalSemanticColors.lightTestedTheme,
    darkSemantic: JournalSemanticColors.darkTestedTheme,
  );

  static BrandPalette of(AppThemeVariant? variant) {
    if (variant == AppThemeVariant.inkPurple) {
      return inkPurple;
    }
    if (variant == AppThemeVariant.deepDarkCreator) {
      return deepDarkCreator;
    }
    if (variant == AppThemeVariant.neoAnalogJournal) {
      return neoAnalogJournal;
    }
    if (variant == AppThemeVariant.minimalProductivityPro) {
      return minimalProductivityPro;
    }
    if (variant == AppThemeVariant.midnightTealJournal) {
      return midnightTealJournal;
    }
    if (variant == AppThemeVariant.violetNebulaJournal) {
      return violetNebulaJournal;
    }
    if (variant == AppThemeVariant.testedTheme) {
      return testedTheme;
    }
    // Includes null or stale hot-reload enum values.
    return calmEditorialPremium;
  }
}

class JournalSemanticColors extends ThemeExtension<JournalSemanticColors> {
  final Color primaryStrong;
  final Color primaryHover;
  final Color warmAccent;
  final Color softMint;
  final Color mutedRose;
  final Color background;
  final Color card;
  final Color elevated;
  final Color divider;
  final Color floatingToolbar;
  final Color selectedGlow;

  const JournalSemanticColors({
    required this.primaryStrong,
    required this.primaryHover,
    required this.warmAccent,
    required this.softMint,
    required this.mutedRose,
    required this.background,
    required this.card,
    required this.elevated,
    required this.divider,
    required this.floatingToolbar,
    required this.selectedGlow,
  });

  static const lightCalmEditorialPremium = JournalSemanticColors(
    primaryStrong: Color(0xFF14161C),
    primaryHover: Color(0xFF3A3ECF),
    warmAccent: Color(0xFFFFB84D),
    softMint: Color(0xFF5CC8A1),
    mutedRose: Color(0xFFC76D5A),
    background: Color(0xFFF7F6F3),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    divider: Color(0xFFE8EAF2),
    floatingToolbar: Color(0xEEFFFFFF),
    selectedGlow: Color(0x334C4FF6),
  );

  static const darkCalmEditorialPremium = JournalSemanticColors(
    primaryStrong: Color(0xFFF5F6FA),
    primaryHover: Color(0xFF6366FF),
    warmAccent: Color(0xFFFFB84D),
    softMint: Color(0xFF5CC8A1),
    mutedRose: Color(0xFFD98A78),
    background: Color(0xFF0F1117),
    card: Color(0xFF1A1D26),
    elevated: Color(0xFF222534),
    divider: Color(0xFF2A2E3D),
    floatingToolbar: Color(0xEE222534),
    selectedGlow: Color(0x446366FF),
  );

  static const lightInkPurple = JournalSemanticColors(
    primaryStrong: Color(0xFF1F2937),
    primaryHover: Color(0xFF6D28D9),
    warmAccent: Color(0xFFF97316),
    softMint: Color(0xFF14B8A6),
    mutedRose: Color(0xFFFB923C),
    background: Color(0xFFF5F3FF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    divider: Color(0xFFE5E7EB),
    floatingToolbar: Color(0xEEFFFFFF),
    selectedGlow: Color(0x337C3AED),
  );

  static const darkInkPurple = JournalSemanticColors(
    primaryStrong: Color(0xFFF9FAFB),
    primaryHover: Color(0xFFA855F7),
    warmAccent: Color(0xFFFB923C),
    softMint: Color(0xFF2DD4BF),
    mutedRose: Color(0xFFFB923C),
    background: Color(0xFF0A0A0F),
    card: Color(0xFF14141A),
    elevated: Color(0xFF1C1C24),
    divider: Color(0xFF2A2A33),
    floatingToolbar: Color(0xEE1C1C24),
    selectedGlow: Color(0x44A855F7),
  );

  static const lightDeepDarkCreator = JournalSemanticColors(
    primaryStrong: Color(0xFF14161C),
    primaryHover: Color(0xFF4C4FF6),
    warmAccent: Color(0xFFFFB84D),
    softMint: Color(0xFF5FF2C3),
    mutedRose: Color(0xFF8C91A4),
    background: Color(0xFFF5F6FA),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF8F9FD),
    divider: Color(0xFFDCE0EA),
    floatingToolbar: Color(0xEEF8F9FD),
    selectedGlow: Color(0x334C4FF6),
  );

  static const darkDeepDarkCreator = JournalSemanticColors(
    primaryStrong: Color(0xFFF5F6FA),
    primaryHover: Color(0xFF6366FF),
    warmAccent: Color(0xFFFFB84D),
    softMint: Color(0xFF5FF2C3),
    mutedRose: Color(0xFF8C91A4),
    background: Color(0xFF0E0F14),
    card: Color(0xFF1A1D26),
    elevated: Color(0xFF222534),
    divider: Color(0xFF2A2E3D),
    floatingToolbar: Color(0xCC1A1D26),
    selectedGlow: Color(0x666366FF),
  );

  static const lightNeoAnalogJournal = JournalSemanticColors(
    primaryStrong: Color(0xFF2F2A3A),
    primaryHover: Color(0xFF4A4556),
    warmAccent: Color(0xFFC76D5A),
    softMint: Color(0xFF7B8F71),
    mutedRose: Color(0xFF4F6D7A),
    background: Color(0xFFF4F1EA),
    card: Color(0xFFFAF8F3),
    elevated: Color(0xFFFAF8F3),
    divider: Color(0xFFE6E1D7),
    floatingToolbar: Color(0xEEFAF8F3),
    selectedGlow: Color(0x334F6D7A),
  );

  static const darkNeoAnalogJournal = JournalSemanticColors(
    primaryStrong: Color(0xFFF1ECE3),
    primaryHover: Color(0xFFB4AEBE),
    warmAccent: Color(0xFFD98A78),
    softMint: Color(0xFF9AAE90),
    mutedRose: Color(0xFF89A1AC),
    background: Color(0xFF1E1B26),
    card: Color(0xFF2B2735),
    elevated: Color(0xFF2B2735),
    divider: Color(0xFF3A3447),
    floatingToolbar: Color(0xEE2B2735),
    selectedGlow: Color(0x4489A1AC),
  );

  static const lightMinimalProductivityPro = JournalSemanticColors(
    primaryStrong: Color(0xFF111827),
    primaryHover: Color(0xFF2563EB),
    warmAccent: Color(0xFFF59E0B),
    softMint: Color(0xFF10B981),
    mutedRose: Color(0xFF6B7280),
    background: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF3F4F6),
    divider: Color(0xFFE5E7EB),
    floatingToolbar: Color(0xEEF3F4F6),
    selectedGlow: Color(0x332563EB),
  );

  static const darkMinimalProductivityPro = JournalSemanticColors(
    primaryStrong: Color(0xFFF9FAFB),
    primaryHover: Color(0xFF3B82F6),
    warmAccent: Color(0xFFFBBF24),
    softMint: Color(0xFF34D399),
    mutedRose: Color(0xFF9CA3AF),
    background: Color(0xFF111827),
    card: Color(0xFF1F2937),
    elevated: Color(0xFF1F2937),
    divider: Color(0xFF374151),
    floatingToolbar: Color(0xEE1F2937),
    selectedGlow: Color(0x443B82F6),
  );

  static const lightMidnightTealJournal = JournalSemanticColors(
    primaryStrong: Color(0xFF1F2937),
    primaryHover: Color(0xFF0F766E),
    warmAccent: Color(0xFF0EA5E9),
    softMint: Color(0xFF10B981),
    mutedRose: Color(0xFF64748B),
    background: Color(0xFFF4FAFA),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF8FBFB),
    divider: Color(0xFFDCE6E7),
    floatingToolbar: Color(0xEEF8FBFB),
    selectedGlow: Color(0x330F766E),
  );

  static const darkMidnightTealJournal = JournalSemanticColors(
    primaryStrong: Color(0xFFF8FAFC),
    primaryHover: Color(0xFF2DD4BF),
    warmAccent: Color(0xFF67E8F9),
    softMint: Color(0xFF34D399),
    mutedRose: Color(0xFF9CA3AF),
    background: Color(0xFF1A1D24),
    card: Color(0xFF2A2E35),
    elevated: Color(0xFF1F2937),
    divider: Color(0xFF374151),
    floatingToolbar: Color(0xEE2A2E35),
    selectedGlow: Color(0x4434D399),
  );

  static const lightVioletNebulaJournal = JournalSemanticColors(
    primaryStrong: Color(0xFF1E1A33),
    primaryHover: Color(0xFF6D28D9),
    warmAccent: Color(0xFF8B5CF6),
    softMint: Color(0xFFB794F4),
    mutedRose: Color(0xFF716A92),
    background: Color(0xFFF6F3FF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF9F7FF),
    divider: Color(0xFFDDD8EE),
    floatingToolbar: Color(0xEEF9F7FF),
    selectedGlow: Color(0x336D28D9),
  );

  static const darkVioletNebulaJournal = JournalSemanticColors(
    primaryStrong: Color(0xFFF8FAFC),
    primaryHover: Color(0xFF8B5CF6),
    warmAccent: Color(0xFFB794F4),
    softMint: Color(0xFFA78BFA),
    mutedRose: Color(0xFF7C66B1),
    background: Color(0xFF0B1020),
    card: Color(0xFF121826),
    elevated: Color(0xFF0E1420),
    divider: Color(0xFF2A3346),
    floatingToolbar: Color(0xEE0E1420),
    selectedGlow: Color(0x448B5CF6),
  );

  static const lightTestedTheme = JournalSemanticColors(
    primaryStrong: Color(0xFF1E1A33),
    primaryHover: Color(0xFF7C3AED),
    warmAccent: Color(0xFF8B5CF6),
    softMint: Color(0xFF38BDF8),
    mutedRose: Color(0xFF716A92),
    background: Color(0xFFF6F3FF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF9F7FF),
    divider: Color(0xFFDDD8EE),
    floatingToolbar: Color(0xEEF9F7FF),
    selectedGlow: Color(0x337C3AED),
  );

  static const darkTestedTheme = JournalSemanticColors(
    primaryStrong: Color(0xFFF8FAFC),
    primaryHover: Color(0xFF8B5CF6),
    warmAccent: Color(0xFFB794F4),
    softMint: Color(0xFF38BDF8),
    mutedRose: Color(0xFF7C66B1),
    background: Color(0xFF070B16),
    card: Color(0xFF121826),
    elevated: Color(0xFF0E1420),
    divider: Color(0xFF2A3346),
    floatingToolbar: Color(0xEE121826),
    selectedGlow: Color(0x447C3AED),
  );

  // Backward compatible aliases for existing usages.
  static const light = lightCalmEditorialPremium;
  static const dark = darkCalmEditorialPremium;

  @override
  JournalSemanticColors copyWith({
    Color? primaryStrong,
    Color? primaryHover,
    Color? warmAccent,
    Color? softMint,
    Color? mutedRose,
    Color? background,
    Color? card,
    Color? elevated,
    Color? divider,
    Color? floatingToolbar,
    Color? selectedGlow,
  }) {
    return JournalSemanticColors(
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primaryHover: primaryHover ?? this.primaryHover,
      warmAccent: warmAccent ?? this.warmAccent,
      softMint: softMint ?? this.softMint,
      mutedRose: mutedRose ?? this.mutedRose,
      background: background ?? this.background,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      divider: divider ?? this.divider,
      floatingToolbar: floatingToolbar ?? this.floatingToolbar,
      selectedGlow: selectedGlow ?? this.selectedGlow,
    );
  }

  @override
  ThemeExtension<JournalSemanticColors> lerp(
    covariant ThemeExtension<JournalSemanticColors>? other,
    double t,
  ) {
    if (other is! JournalSemanticColors) {
      return this;
    }
    return JournalSemanticColors(
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      warmAccent: Color.lerp(warmAccent, other.warmAccent, t)!,
      softMint: Color.lerp(softMint, other.softMint, t)!,
      mutedRose: Color.lerp(mutedRose, other.mutedRose, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      floatingToolbar: Color.lerp(floatingToolbar, other.floatingToolbar, t)!,
      selectedGlow: Color.lerp(selectedGlow, other.selectedGlow, t)!,
    );
  }
}
