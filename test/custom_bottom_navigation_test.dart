import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('shows selected label and reports taps', (tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 0,
            onItemSelected: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Günlükler'), findsOneWidget);
    expect(find.text('Anasayfa'), findsNothing);
    expect(find.byIcon(LucideIcons.sticker), findsOneWidget);
    expect(find.byIcon(LucideIcons.user), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.user));
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
    expect(find.text('Günlükler'), findsOneWidget);
  });
}
