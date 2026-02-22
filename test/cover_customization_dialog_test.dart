import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/features/library/cover_customization_dialog.dart';

void main() {
  testWidgets('applies selected theme and returns map result', (tester) async {
    Future<Map<String, String?>?>? dialogFuture;
    final targetTheme = NostalgicThemes.all[2];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    dialogFuture = showCoverCustomization(
                      context,
                      currentCoverStyle: NostalgicThemes.all.first.id,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Kapak Özelleştir'), findsOneWidget);

    await tester.tap(find.text(targetTheme.name).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    final result = await dialogFuture;
    expect(result, isNotNull);
    expect(result!['coverStyle'], targetTheme.id);
    expect(result['coverImageUrl'], isNull);
  });

  testWidgets('close button dismisses dialog with null result', (tester) async {
    Future<Map<String, String?>?>? dialogFuture;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    dialogFuture = showCoverCustomization(
                      context,
                      currentCoverStyle: NostalgicThemes.all.first.id,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final result = await dialogFuture;
    expect(result, isNull);
  });
}
