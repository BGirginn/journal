import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/features/onboarding/onboarding_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('shows localized onboarding pages and advances', (tester) async {
    await tester.pumpWidget(buildApp(OnboardingScreen(onComplete: () {})));

    expect(find.text('Capture Your Memories'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Share Together'), findsOneWidget);
  });

  testWidgets('skip completes onboarding and writes preference', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      buildApp(
        OnboardingScreen(
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(completed, isTrue);
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });
}
