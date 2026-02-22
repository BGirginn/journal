import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/widgets/text_edit_dialog.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('returns updated payload when save is pressed', (tester) async {
    Future<TextBlockPayload?>? dialogFuture;

    final initialPayload = TextBlockPayload(
      content: 'Merhaba',
      fontSize: 16,
      color: '#000000',
      fontFamily: 'default',
      textAlign: 'left',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    dialogFuture = showDialog<TextBlockPayload>(
                      context: context,
                      builder: (_) =>
                          TextEditDialog(initialPayload: initialPayload),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Metni Düzenle'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Yeni içerik');

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final result = await dialogFuture;
    expect(result, isNotNull);
    expect(result!.content, 'Yeni içerik');
    expect(result.fontFamily, 'Roboto');
    expect(result.textAlign, 'left');
    expect(result.fontSize, 16);
    expect(result.color, '#000000');
  });

  testWidgets('falls back to left alignment for unknown initial alignment', (
    tester,
  ) async {
    Future<TextBlockPayload?>? dialogFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  dialogFuture = showDialog<TextBlockPayload>(
                    context: context,
                    builder: (_) => TextEditDialog(
                      initialPayload: TextBlockPayload(
                        content: 'x',
                        color: 'not-a-hex-color',
                        fontFamily: 'default',
                        textAlign: 'unsupported',
                      ),
                    ),
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

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final result = await dialogFuture;
    expect(result, isNotNull);
    expect(result!.textAlign, 'left');
  });
}
