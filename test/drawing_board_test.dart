import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/ui/drawing_board.dart';

void main() {
  test('controller tracks points and exports image', () async {
    final controller = DrawingController();

    expect(controller.isEmpty, isTrue);
    expect(await controller.toImage(const Size(200, 200)), isNull);

    controller.addPoint(const Offset(10, 10));
    controller.addPoint(const Offset(40, 40));

    expect(controller.isEmpty, isFalse);
    final image = await controller.toImage(const Size(200, 200));
    expect(image, isNotNull);

    controller.clear();
    expect(controller.isEmpty, isTrue);
    expect(await controller.toImage(const Size(200, 200)), isNull);
  });

  testWidgets('drawing board records pan updates and stroke end', (
    tester,
  ) async {
    final controller = DrawingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 240,
            child: DrawingBoard(controller: controller),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawingBoard));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(30, 20));
    await gesture.up();
    await tester.pump();

    expect(controller.isEmpty, isFalse);

    final image = await controller.toImage(const Size(240, 240));
    expect(image, isNotNull);
  });
}
