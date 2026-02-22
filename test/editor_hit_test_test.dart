import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/engine/hit_test.dart';

Block _block({
  required String id,
  required int z,
  double x = 0.1,
  double y = 0.1,
  double width = 0.4,
  double height = 0.4,
  double rotation = 0,
}) {
  return Block(
    id: id,
    pageId: 'p1',
    type: BlockType.text,
    x: x,
    y: y,
    width: width,
    height: height,
    rotation: rotation,
    zIndex: z,
    payloadJson: '{}',
  );
}

void main() {
  const pageSize = Size(200, 200);

  test('hitTest returns top-most block at point', () {
    final low = _block(id: 'low', z: 1);
    final high = _block(id: 'high', z: 5);

    final hit = HitTestService.hitTest(
      blocks: [low, high],
      point: const Offset(60, 60),
      pageSize: pageSize,
    );

    expect(hit?.id, equals('high'));
  });

  test('isPointInBlock works for rotated block', () {
    final block = _block(id: 'r1', z: 1, rotation: 30);

    expect(
      HitTestService.isPointInBlock(block, const Offset(80, 80), pageSize),
      isTrue,
    );
    expect(
      HitTestService.isPointInBlock(block, const Offset(190, 190), pageSize),
      isFalse,
    );
  });

  test('hitTestHandle detects resize and rotate handles', () {
    final block = _block(
      id: 'h1',
      z: 1,
      x: 0.2,
      y: 0.2,
      width: 0.3,
      height: 0.3,
    );

    final topLeft = HitTestService.hitTestHandle(
      block: block,
      point: const Offset(40, 40),
      pageSize: pageSize,
    );

    final rotate = HitTestService.hitTestHandle(
      block: block,
      point: const Offset(70, 10),
      pageSize: pageSize,
    );

    expect(topLeft, equals(HandlePosition.topLeft));
    expect(rotate, equals(HandlePosition.rotate));
  });

  test('hitTest returns null when nothing hit', () {
    final hit = HitTestService.hitTest(
      blocks: [_block(id: 'b', z: 1)],
      point: const Offset(190, 10),
      pageSize: pageSize,
    );

    expect(hit, isNull);
  });
}
