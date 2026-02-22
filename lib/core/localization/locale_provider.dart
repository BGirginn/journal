import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale_code';

class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(null) {
    _load();
  }

  void _load() {
    final code = _prefs.getString(_localeKey);
    if (code == null || code.isEmpty) {
      state = null;
      return;
    }
    state = Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(_localeKey);
      return;
    }
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
