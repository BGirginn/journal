import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/auth/auth_service.dart';

import 'package:journal_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Wrap in ProviderScope with required overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAvailableProvider.overrideWith((ref) => false),
          firebaseErrorProvider.overrideWith((ref) => null),
        ],
        child: const JournalApp(),
      ),
    );

    // Allow time for async operations
    await tester.pump();

    // Verify the app renders (MaterialApp exists)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
