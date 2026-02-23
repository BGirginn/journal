import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/theme/theme_variant.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';

void main() {
  test('violet nebula palette resolves correctly', () {
    final palette = BrandPalettes.of(AppThemeVariant.violetNebulaJournal);

    expect(palette.darkScheme.primary, const Color(0xFF8B5CF6));
    expect(palette.darkScheme.secondary, const Color(0xFFB794F4));
    expect(palette.darkScheme.surface, const Color(0xFF121826));

    expect(palette.darkSemantic.background, const Color(0xFF0B1020));
    expect(palette.darkSemantic.card, const Color(0xFF121826));
    expect(palette.darkSemantic.elevated, const Color(0xFF0E1420));
    expect(palette.darkSemantic.divider, const Color(0xFF2A3346));
  });

  test('violet nebula light semantic tokens are populated', () {
    final palette = BrandPalettes.of(AppThemeVariant.violetNebulaJournal);

    expect(palette.lightSemantic.background, isNot(Colors.transparent));
    expect(palette.lightSemantic.card, isNot(Colors.transparent));
    expect(palette.lightSemantic.elevated, isNot(Colors.transparent));
    expect(palette.lightSemantic.divider, isNot(Colors.transparent));
    expect(palette.lightScheme.onSurface.computeLuminance(), lessThan(0.3));
  });

  test('tested theme palette resolves correctly', () {
    final palette = BrandPalettes.of(AppThemeVariant.testedTheme);

    expect(palette.darkScheme.primary, const Color(0xFF8B5CF6));
    expect(palette.darkScheme.secondary, const Color(0xFF38BDF8));
    expect(palette.darkSemantic.background, const Color(0xFF070B16));
    expect(palette.darkSemantic.card, const Color(0xFF121826));
    expect(palette.darkSemantic.divider, const Color(0xFF2A3346));
  });
}
