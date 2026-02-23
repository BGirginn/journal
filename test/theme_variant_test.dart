import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

void main() {
  test('fromStorage resolves violet nebula variant', () {
    expect(
      AppThemeVariant.fromStorage('violet_nebula_journal'),
      AppThemeVariant.violetNebulaJournal,
    );
  });

  test('fromStorage resolves midnight teal variant', () {
    expect(
      AppThemeVariant.fromStorage('midnight_teal_journal'),
      AppThemeVariant.midnightTealJournal,
    );
  });

  test('fromStorage resolves tested theme variant', () {
    expect(
      AppThemeVariant.fromStorage('tested_theme'),
      AppThemeVariant.testedTheme,
    );
  });

  test('fromStorage falls back to calm editorial on unknown value', () {
    expect(
      AppThemeVariant.fromStorage('unknown_variant_value'),
      AppThemeVariant.calmEditorialPremium,
    );
  });
}
