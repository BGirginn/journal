import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'journal_theme.dart';

/// Theme state notifier
class ThemeNotifier extends StateNotifier<JournalTheme> {
  ThemeNotifier() : super(BuiltInThemes.defaultTheme);

  /// Set theme by ID
  void setTheme(String themeId) {
    state = BuiltInThemes.getById(themeId);
  }

  /// Set theme directly
  void setThemeObject(JournalTheme theme) {
    state = theme;
  }
}

/// Global theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, JournalTheme>((ref) {
  return ThemeNotifier();
});

/// All available themes provider
final availableThemesProvider = Provider<List<JournalTheme>>((ref) {
  return BuiltInThemes.all;
});
