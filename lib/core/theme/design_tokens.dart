import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';

/// Backward-compatible token entrypoint used by legacy screens.
///
/// New code should consume token classes under `core/theme/tokens/*`.
class AppColorTokens {
  const AppColorTokens._();

  // Legacy aliases
  static const Color amber = BrandColors.primary600;
  static const Color coral = BrandColors.warmAccent;
  static const Color gold = BrandColors.mutedRose;

  static const Color lightBackground = BrandColors.lightBackground;
  static const Color lightSurface = BrandColors.lightCard;
  static const Color lightSurfaceContainer = BrandColors.lightElevated;
  static const Color lightSurfaceContainerAlt = BrandColors.lightDivider;

  static const Color darkBackground = BrandColors.darkBackground;
  static const Color darkSurface = BrandColors.darkCard;
  static const Color darkSurfaceContainer = BrandColors.darkElevated;
  static const Color darkSurfaceContainerAlt = BrandColors.darkDivider;

  static const ColorScheme lightScheme = BrandColors.lightScheme;
  static const ColorScheme darkScheme = BrandColors.darkScheme;
}
