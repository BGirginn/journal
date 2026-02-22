import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/features/library/theme_picker_dialog.dart';

void main() {
  testWidgets('selecting a theme returns selected value from showThemePicker', (
    tester,
  ) async {
    Future<NotebookTheme?>? pickerFuture;
    final selected = NostalgicThemes.all[1];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  pickerFuture = showThemePicker(
                    context,
                    selectedThemeId: NostalgicThemes.all.first.id,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Tema Seçin'), findsOneWidget);

    await tester.tap(find.text(selected.name).first);
    await tester.pumpAndSettle();

    final result = await pickerFuture;
    expect(result, isNotNull);
    expect(result!.id, selected.id);
    expect(find.text('Tema Seçin'), findsNothing);
  });

  testWidgets('cancel returns null', (tester) async {
    Future<NotebookTheme?>? pickerFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  pickerFuture = showThemePicker(context);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    final result = await pickerFuture;
    expect(result, isNull);
  });
}
