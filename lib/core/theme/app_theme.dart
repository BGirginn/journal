import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_elevation.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/theme/tokens/brand_spacing.dart';
import 'package:journal_app/core/theme/tokens/brand_typography.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

class AppTheme {
  static ThemeData getTheme(
    Brightness brightness, {
    AppThemeVariant variant = AppThemeVariant.testedTheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final isMinimal = variant == AppThemeVariant.minimalProductivityPro;
    final isGlassTheme =
        variant == AppThemeVariant.violetNebulaJournal ||
        variant == AppThemeVariant.testedTheme;
    final palette = BrandPalettes.of(variant);
    final colorScheme = isDark ? palette.darkScheme : palette.lightScheme;
    final semantic = isDark ? palette.darkSemantic : palette.lightSemantic;
    final spacing = _spacingFor(variant);
    final radius = _radiusFor(variant);
    final elevation = _elevationFor(variant, isDark);
    final textTheme = BrandTypography.textTheme(
      brightness: brightness,
      textColor: colorScheme.onSurface,
      secondaryTextColor: colorScheme.onSurfaceVariant,
      variant: variant,
    );

    final buttonStateOverlay = WidgetStateProperty.resolveWith<Color?>((
      states,
    ) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return colorScheme.primary.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.pressed)) {
        return colorScheme.primary.withValues(alpha: 0.24);
      }
      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: semantic.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        semantic,
        spacing,
        radius,
        elevation,
      ],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.14),
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.34 : 0.22,
            ),
            width: 1,
          ),
        ),
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: semantic.card,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.large),
          side: (isMinimal || isGlassTheme)
              ? BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isGlassTheme ? (isDark ? 0.95 : 0.88) : 0.9,
                  ),
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.large),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semantic.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radius.modal),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isMinimal
            ? colorScheme.surfaceContainerLow
            : semantic.elevated,
        contentPadding: EdgeInsets.all(spacing.md),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.medium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.42 : 0.55,
              );
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: isDark ? 0.9 : 0.86);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant;
            }
            return colorScheme.onPrimary;
          }),
          overlayColor: buttonStateOverlay,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.medium),
            ),
          ),
          elevation: WidgetStateProperty.all(0),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.medium),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.medium),
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return semantic.elevated;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimaryContainer;
            }
            return colorScheme.onSurfaceVariant;
          }),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: semantic.elevated,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.medium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isMinimal ? colorScheme.surface : semantic.elevated,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 22);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.large),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isMinimal
            ? colorScheme.surfaceContainerLow
            : semantic.elevated,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium!,
      ),
    );
  }

  static JournalSpacingScale _spacingFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.calmEditorialPremium:
        return JournalSpacingScale.standard;
      case AppThemeVariant.inkPurple:
        return JournalSpacingScale.standard;
      case AppThemeVariant.deepDarkCreator:
        return const JournalSpacingScale(
          xxs: 4,
          xs: 8,
          sm: 12,
          md: 16,
          lg: 24,
          xl: 32,
          xxl: 40,
          xxxl: 48,
        );
      case AppThemeVariant.neoAnalogJournal:
        return const JournalSpacingScale(
          xxs: 8,
          xs: 12,
          sm: 16,
          md: 24,
          lg: 32,
          xl: 48,
          xxl: 56,
          xxxl: 64,
        );
      case AppThemeVariant.minimalProductivityPro:
        return const JournalSpacingScale(
          xxs: 4,
          xs: 8,
          sm: 12,
          md: 16,
          lg: 20,
          xl: 24,
          xxl: 32,
          xxxl: 40,
        );
      case AppThemeVariant.midnightTealJournal:
        return const JournalSpacingScale(
          xxs: 4,
          xs: 8,
          sm: 12,
          md: 16,
          lg: 24,
          xl: 32,
          xxl: 40,
          xxxl: 48,
        );
      case AppThemeVariant.violetNebulaJournal:
        return const JournalSpacingScale(
          xxs: 4,
          xs: 8,
          sm: 12,
          md: 16,
          lg: 24,
          xl: 32,
          xxl: 40,
          xxxl: 48,
        );
      case AppThemeVariant.testedTheme:
        return const JournalSpacingScale(
          xxs: 4,
          xs: 8,
          sm: 12,
          md: 16,
          lg: 24,
          xl: 32,
          xxl: 40,
          xxxl: 48,
        );
    }
  }

  static JournalRadiusScale _radiusFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.calmEditorialPremium:
        return JournalRadiusScale.standard;
      case AppThemeVariant.inkPurple:
        return JournalRadiusScale.standard;
      case AppThemeVariant.deepDarkCreator:
        return const JournalRadiusScale(
          small: 12,
          medium: 16,
          large: 16,
          modal: 24,
        );
      case AppThemeVariant.neoAnalogJournal:
        return const JournalRadiusScale(
          small: 12,
          medium: 20,
          large: 20,
          modal: 24,
        );
      case AppThemeVariant.minimalProductivityPro:
        return const JournalRadiusScale(
          small: 12,
          medium: 14,
          large: 16,
          modal: 16,
        );
      case AppThemeVariant.midnightTealJournal:
        return const JournalRadiusScale(
          small: 12,
          medium: 18,
          large: 24,
          modal: 28,
        );
      case AppThemeVariant.violetNebulaJournal:
        return const JournalRadiusScale(
          small: 12,
          medium: 16,
          large: 20,
          modal: 24,
        );
      case AppThemeVariant.testedTheme:
        return const JournalRadiusScale(
          small: 12,
          medium: 16,
          large: 24,
          modal: 24,
        );
    }
  }

  static JournalElevationScale _elevationFor(
    AppThemeVariant variant,
    bool isDark,
  ) {
    switch (variant) {
      case AppThemeVariant.calmEditorialPremium:
        return isDark
            ? JournalElevationScale.dark
            : JournalElevationScale.light;
      case AppThemeVariant.inkPurple:
        return isDark
            ? JournalElevationScale.dark
            : JournalElevationScale.light;
      case AppThemeVariant.deepDarkCreator:
        return isDark
            ? const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x4A000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              )
            : const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              );
      case AppThemeVariant.neoAnalogJournal:
        return isDark
            ? const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x2B000000),
                    blurRadius: 22,
                    offset: Offset(0, 6),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x3A000000),
                    blurRadius: 26,
                    offset: Offset(0, 8),
                  ),
                ],
              )
            : const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              );
      case AppThemeVariant.minimalProductivityPro:
        return const JournalElevationScale(
          cardShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
          toolShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        );
      case AppThemeVariant.midnightTealJournal:
        return isDark
            ? const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x54000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              )
            : const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              );
      case AppThemeVariant.violetNebulaJournal:
        return isDark
            ? const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x52000000),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x5C000000),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              )
            : const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              );
      case AppThemeVariant.testedTheme:
        return isDark
            ? const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x70000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              )
            : const JournalElevationScale(
                cardShadow: [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
                toolShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              );
    }
  }
}
