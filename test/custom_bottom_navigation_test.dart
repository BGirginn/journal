import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';

void main() {
  testWidgets('shows selected label and reports taps', (tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 1,
            onItemSelected: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Günlükler'), findsOneWidget);
    expect(find.text('Anasayfa'), findsNothing);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.sticky_note_2_rounded));
    await tester.pumpAndSettle();

    expect(tappedIndex, 4);
  });

  testWidgets('renders in dark theme too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 0,
            onItemSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CustomBottomNavigation), findsOneWidget);
    expect(find.text('Anasayfa'), findsOneWidget);
  });
}
