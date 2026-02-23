import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/theme/app_theme.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('violet nebula uses violet login background gradient', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'theme_variant': 'violet_nebula_journal',
      'theme_mode': ThemeMode.dark.index,
      'force_tested_theme_once_v1': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAvailableProvider.overrideWith((ref) => false),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final themeSettings = ref.watch(themeProvider);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.getTheme(
                Brightness.light,
                variant: themeSettings.effectiveVariant,
              ),
              darkTheme: AppTheme.getTheme(
                Brightness.dark,
                variant: themeSettings.effectiveVariant,
              ),
              themeMode: themeSettings.mode,
              home: const LoginScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final backgroundGradientFinder = find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      final gradient = decoration.gradient;
      if (gradient is! LinearGradient) return false;
      if (gradient.stops == null || gradient.stops!.length != 3) return false;
      return gradient.colors.length == 3 &&
          gradient.colors[0] == const Color(0xFF0B1020) &&
          gradient.colors[1] == const Color(0xFF13112B) &&
          gradient.colors[2] == const Color(0xFF2A145C);
    });

    expect(backgroundGradientFinder, findsOneWidget);

    final bookIcons = tester
        .widgetList<Icon>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon && widget.icon == Icons.menu_book_rounded,
          ),
        )
        .toList();
    expect(
      bookIcons.any((icon) => icon.color == const Color(0xFF8B5CF6)),
      isTrue,
    );
  });
}
