import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

// Keys for SharedPreferences
const _kThemeModeKey = 'theme_mode';
const _kColorThemeKey = 'color_theme';

class ThemeSettings {
  final ThemeMode mode;
  final AppColorTheme colorTheme;

  const ThemeSettings({
    this.mode = ThemeMode.dark,
    this.colorTheme = AppColorTheme.gold,
  });

  ThemeSettings copyWith({ThemeMode? mode, AppColorTheme? colorTheme}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      colorTheme: colorTheme ?? this.colorTheme,
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
    final colorIndex = _prefs.getInt(_kColorThemeKey);

    final mode = modeIndex != null
        ? ThemeMode.values[modeIndex]
        : ThemeMode.system;
    final colorTheme = colorIndex != null
        ? AppColorTheme.values[colorIndex]
        : AppColorTheme.purple;

    state = ThemeSettings(mode: mode, colorTheme: colorTheme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setInt(_kThemeModeKey, mode.index);
  }

  Future<void> setColorTheme(AppColorTheme colorTheme) async {
    state = state.copyWith(colorTheme: colorTheme);
    await _prefs.setInt(_kColorThemeKey, colorTheme.index);
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
