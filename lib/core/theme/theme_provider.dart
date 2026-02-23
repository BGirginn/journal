import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/core/theme/theme_variant.dart';

// Keys for SharedPreferences
const _kThemeModeKey = 'theme_mode';
const _kThemeVariantKey = 'theme_variant';
const _kForceTestedThemeOnceKey = 'force_tested_theme_once_v1';

class ThemeSettings {
  final ThemeMode mode;
  final AppThemeVariant? variant;

  const ThemeSettings({
    this.mode = ThemeMode.light,
    this.variant = AppThemeVariant.testedTheme,
  });

  AppThemeVariant get effectiveVariant {
    final current = variant;
    if (current == null) {
      return AppThemeVariant.testedTheme;
    }
    for (final known in AppThemeVariant.values) {
      if (known == current) {
        return known;
      }
    }
    // Hot-reload safety: stale enum instance falls back to default variant.
    return AppThemeVariant.testedTheme;
  }

  ThemeSettings copyWith({ThemeMode? mode, AppThemeVariant? variant}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant ?? AppThemeVariant.testedTheme,
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

    final isForceApplied = _prefs.getBool(_kForceTestedThemeOnceKey) ?? false;
    if (!isForceApplied) {
      state = ThemeSettings(mode: mode, variant: AppThemeVariant.testedTheme);
      unawaited(
        Future.wait([
          _prefs.setString(
            _kThemeVariantKey,
            AppThemeVariant.testedTheme.storageValue,
          ),
          _prefs.setBool(_kForceTestedThemeOnceKey, true),
        ]),
      );
      return;
    }

    final resolvedVariant = storedVariant == null
        ? AppThemeVariant.testedTheme
        : AppThemeVariant.fromStorage(storedVariant);
    state = ThemeSettings(mode: mode, variant: resolvedVariant);
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
