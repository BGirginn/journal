import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

// Keys for SharedPreferences
const _kThemeModeKey = 'theme_mode';
const _kThemeVariantKey = 'theme_variant';

class ThemeSettings {
  final ThemeMode mode;
  final AppThemeVariant? variant;

  const ThemeSettings({
    this.mode = ThemeMode.light,
    this.variant = AppThemeVariant.calmEditorialPremium,
  });

  AppThemeVariant get effectiveVariant {
    final current = variant;
    if (current == null) {
      return AppThemeVariant.calmEditorialPremium;
    }
    for (final known in AppThemeVariant.values) {
      if (known == current) {
        return known;
      }
    }
    // Hot-reload safety: stale enum instance falls back to default variant.
    return AppThemeVariant.calmEditorialPremium;
  }

  ThemeSettings copyWith({ThemeMode? mode, AppThemeVariant? variant}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant ?? AppThemeVariant.calmEditorialPremium,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(const ThemeSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final modeIndex = _prefs.getInt(_kThemeModeKey);
    final storedVariant = _prefs.getString(_kThemeVariantKey);
    final mode = modeIndex == ThemeMode.dark.index
        ? ThemeMode.dark
        : ThemeMode.light;
    state = ThemeSettings(
      mode: mode,
      variant: AppThemeVariant.fromStorage(storedVariant),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setInt(_kThemeModeKey, mode.index);
  }

  Future<void> setThemeVariant(AppThemeVariant variant) async {
    state = state.copyWith(variant: variant);
    await _prefs.setString(_kThemeVariantKey, variant.storageValue);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
