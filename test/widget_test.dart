import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journal_app/main.dart';

void main() {
  testWidgets('App renders loading state initially', (
    WidgetTester tester,
  ) async {
    // 1. Wrap in ProviderScope because JournalApp is a ConsumerWidget
    await tester.pumpWidget(
      const ProviderScope(child: JournalApp(isFirebaseAvailable: false)),
    );

    // 2. The initial state of authStateProvider is loading, so we expect a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
