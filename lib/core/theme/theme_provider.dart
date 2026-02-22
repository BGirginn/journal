import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences
const _kThemeModeKey = 'theme_mode';

class ThemeSettings {
  final ThemeMode mode;

  const ThemeSettings({this.mode = ThemeMode.light});

  ThemeSettings copyWith({ThemeMode? mode}) {
    return ThemeSettings(mode: mode ?? this.mode);
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(const ThemeSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final modeIndex = _prefs.getInt(_kThemeModeKey);
    final mode = modeIndex == ThemeMode.dark.index
        ? ThemeMode.dark
        : ThemeMode.light;
    state = ThemeSettings(mode: mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setInt(_kThemeModeKey, mode.index);
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
