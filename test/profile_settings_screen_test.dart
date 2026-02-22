import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('provider badges and Apple link button visibility', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LinkedAccountsSection(
          providerIds: {'google.com'},
          showAppleLinkButton: true,
          isLinkingApple: false,
          onLinkApple: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked Accounts'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Link Apple Account'), findsOneWidget);
  });

  testWidgets('Apple link button is hidden when account is already linked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LinkedAccountsSection(
          providerIds: {'google.com', 'apple.com'},
          showAppleLinkButton: false,
          isLinkingApple: false,
          onLinkApple: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsNWidgets(2));
    expect(find.text('Link Apple Account'), findsNothing);
  });
}
