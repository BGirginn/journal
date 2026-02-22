import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/ui/book_page_view.dart';

Widget _buildHarness({
  required int itemCount,
  int initialPage = 0,
  ValueChanged<int>? onPageChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 480,
          child: BookPageView(
            itemCount: itemCount,
            initialPage: initialPage,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) => ColoredBox(
              color: Colors.white,
              child: Center(child: Text('Page $index')),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('swiping left moves to next page and notifies callback', (
    tester,
  ) async {
    int? pageChanged;

    await tester.pumpWidget(
      _buildHarness(
        itemCount: 3,
        onPageChanged: (index) => pageChanged = index,
      ),
    );

    expect(find.text('Page 0'), findsOneWidget);

    await tester.drag(find.byType(BookPageView), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(pageChanged, 1);
    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('swiping right on first page keeps page index unchanged', (
    tester,
  ) async {
    int callbackCount = 0;

    await tester.pumpWidget(
      _buildHarness(
        itemCount: 3,
        onPageChanged: (_) {
          callbackCount++;
        },
      ),
    );

    await tester.drag(find.byType(BookPageView), const Offset(260, 0));
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
    expect(find.text('Page 0'), findsOneWidget);
  });

  testWidgets('swiping right from middle page moves to previous page', (
    tester,
  ) async {
    int? pageChanged;

    await tester.pumpWidget(
      _buildHarness(
        itemCount: 3,
        initialPage: 1,
        onPageChanged: (index) => pageChanged = index,
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);

    await tester.drag(find.byType(BookPageView), const Offset(260, 0));
    await tester.pumpAndSettle();

    expect(pageChanged, 0);
    expect(find.text('Page 0'), findsOneWidget);
  });
}
