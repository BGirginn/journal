import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/engine/hit_test.dart';
import 'package:journal_app/features/editor/engine/transform_math.dart';

Block _block({
  double x = 0.2,
  double y = 0.2,
  double width = 0.2,
  double height = 0.2,
  double rotation = 0,
}) {
  return Block(
    id: 'b1',
    pageId: 'p1',
    type: BlockType.text,
    x: x,
    y: y,
    width: width,
    height: height,
    rotation: rotation,
    payloadJson: '{}',
  );
}

void main() {
  test('moveBlock clamps within minimum inside ratio', () {
    final moved = TransformMath.moveBlock(
      block: _block(),
      deltaNormalized: const Offset(2, 2),
      minInsideRatio: 0.1,
    );

    expect(moved.x, closeTo(0.98, 0.0001));
    expect(moved.y, closeTo(0.98, 0.0001));
  });

  test('resizeBlock enforces minimum size', () {
    final resized = TransformMath.resizeBlock(
      block: _block(),
      handle: HandlePosition.topLeft,
      newHandlePositionNormalized: const Offset(0.39, 0.39),
      pageSize: const Size(100, 100),
    );

    expect(resized.width, greaterThanOrEqualTo(TransformMath.minWidth));
    expect(resized.height, greaterThanOrEqualTo(TransformMath.minHeight));
  });

  test('rotateBlock snaps when enabled', () {
    final block = _block();
    final center = Offset(
      block.x + block.width / 2,
      block.y + block.height / 2,
    );

    final rotated = TransformMath.rotateBlock(
      block: block,
      dragPositionNormalized: Offset(center.dx + 0.1, center.dy + 0.08),
      snap: true,
    );

    expect(rotated.rotation % TransformMath.snapAngle, equals(0));
  });

  test('viewport and normalized conversions round-trip', () {
    const pageSize = Size(400, 800);
    const viewport = Offset(120, 500);

    final normalized = TransformMath.viewportToNormalized(viewport, pageSize);
    final roundTrip = TransformMath.normalizedToViewport(normalized, pageSize);

    expect(roundTrip.dx, closeTo(viewport.dx, 0.0001));
    expect(roundTrip.dy, closeTo(viewport.dy, 0.0001));
  });

  test('rotated bounding box grows for angled block', () {
    const pageSize = Size(300, 300);
    final normal = TransformMath.getRotatedBoundingBox(_block(), pageSize);
    final rotated = TransformMath.getRotatedBoundingBox(
      _block(rotation: 45),
      pageSize,
    );

    expect(rotated.width, greaterThan(normal.width));
    expect(rotated.height, greaterThan(normal.height));
  });
}
