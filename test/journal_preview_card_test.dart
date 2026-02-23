import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/features/library/widgets/journal_preview_card.dart';
import 'package:journal_app/providers/journal_providers.dart';

const NotebookTheme _testTheme = NotebookTheme(
  id: 'test-theme',
  name: 'Test Theme',
  description: 'theme for tests',
  visuals: NotebookVisuals(
    coverGradient: [Color(0xFF123456), Color(0xFF654321)],
    pageColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF000000),
  ),
  texture: NotebookTexture.smooth,
);

Widget _buildCard({
  required Journal journal,
  required Stream<List<model.Page>> Function(String) pageStream,
  required Stream<List<Block>> Function(String) blockStream,
  JournalCardVisualMode visualMode = JournalCardVisualMode.coverFirst,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  return ProviderScope(
    overrides: [
      pagesProvider.overrideWith((ref, journalId) => pageStream(journalId)),
      blocksProvider.overrideWith((ref, pageId) => blockStream(pageId)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 260,
          height: 260,
          child: JournalPreviewCard(
            journal: journal,
            theme: _testTheme,
            visualMode: visualMode,
            onTap: onTap ?? () {},
            onLongPress: onLongPress ?? () {},
          ),
        ),
      ),
    ),
  );
}

String _fmtDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}

void main() {
  testWidgets('cover-first card renders title/date and supports gestures', (
    tester,
  ) async {
    var tapped = false;
    var longPressed = false;

    final journal = Journal(
      id: 'j1',
      title: 'Memory Book',
      coverStyle: 'non_existing_theme',
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      _buildCard(
        journal: journal,
        pageStream: (_) => Stream.value(const <model.Page>[]),
        blockStream: (_) => Stream.value(const <Block>[]),
        onTap: () => tapped = true,
        onLongPress: () => longPressed = true,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Memory Book'), findsOneWidget);
    expect(find.text(_fmtDate(journal.updatedAt)), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(JournalPreviewCard));
    await tester.pump();
    expect(tapped, isTrue);

    await tester.longPress(find.byType(JournalPreviewCard));
    await tester.pump();
    expect(longPressed, isTrue);
  });

  testWidgets('page count placeholder resolves after stream emits', (
    tester,
  ) async {
    final journal = Journal(
      id: 'j2',
      title: 'Journal',
      coverStyle: 'non_existing_theme',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    Stream<List<model.Page>> delayedPages(_) async* {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield const <model.Page>[];
    }

    await tester.pumpWidget(
      _buildCard(
        journal: journal,
        pageStream: delayedPages,
        blockStream: (_) => Stream.value(const <Block>[]),
      ),
    );

    expect(find.text('...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('live preview mode falls back safely when pages stream errors', (tester) async {
    final journal = Journal(
      id: 'j3',
      title: 'Archive',
      coverStyle: 'non_existing_theme',
      updatedAt: DateTime.now().subtract(const Duration(days: 9)),
    );

    Stream<List<model.Page>> failingPages(_) async* {
      throw StateError('boom');
    }

    await tester.pumpWidget(
      _buildCard(
        journal: journal,
        pageStream: failingPages,
        blockStream: (_) => Stream.value(const <Block>[]),
        visualMode: JournalCardVisualMode.livePreview,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('StateError: boom'), findsNothing);
  });
}
