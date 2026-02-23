enum AppThemeVariant {
  calmEditorialPremium('calm_editorial_premium'),
  inkPurple('ink_purple'),
  deepDarkCreator('deep_dark_creator'),
  neoAnalogJournal('neo_analog_journal'),
  minimalProductivityPro('minimal_productivity_pro'),
  midnightTealJournal('midnight_teal_journal'),
  violetNebulaJournal('violet_nebula_journal'),
  testedTheme('tested_theme');

  const AppThemeVariant(this.storageValue);

  final String storageValue;

  static AppThemeVariant fromStorage(String? value) {
    return switch (value) {
      'calm_editorial_premium' => AppThemeVariant.calmEditorialPremium,
      'ink_purple' => AppThemeVariant.inkPurple,
      'deep_dark_creator' => AppThemeVariant.deepDarkCreator,
      'neo_analog_journal' => AppThemeVariant.neoAnalogJournal,
      'minimal_productivity_pro' => AppThemeVariant.minimalProductivityPro,
      'midnight_teal_journal' => AppThemeVariant.midnightTealJournal,
      'violet_nebula_journal' => AppThemeVariant.violetNebulaJournal,
      'tested_theme' => AppThemeVariant.testedTheme,
      // Backward compatibility for older palette keys.
      'classic' => AppThemeVariant.calmEditorialPremium,
      _ => AppThemeVariant.calmEditorialPremium,
    };
  }
}
