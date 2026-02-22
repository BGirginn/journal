import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/engine/gesture_handler.dart';

Block _block() {
  return Block(
    id: 'b1',
    pageId: 'p1',
    type: BlockType.text,
    x: 0.2,
    y: 0.2,
    width: 0.2,
    height: 0.2,
    payloadJson: '{}',
  );
}

void main() {
  const pageSize = Size(100, 100);

  test('selects and drags a block', () {
    final handler = GestureHandler();
    final block = _block();
    Block? transformed;

    handler.onBlockTransformed = (oldBlock, newBlock) {
      transformed = newBlock;
    };

    handler.onPointerDown(
      position: const Offset(25, 25),
      blocks: [block],
      pageSize: pageSize,
    );

    expect(handler.selectedBlock?.id, equals(block.id));
    expect(handler.gestureState, equals(GestureState.dragging));

    final moved = handler.onPointerMove(
      position: const Offset(35, 35),
      pageSize: pageSize,
    );

    expect(moved, isNotNull);
    expect(moved!.x, greaterThan(block.x));

    handler.onPointerUp();

    expect(handler.gestureState, equals(GestureState.idle));
    expect(transformed, isNotNull);
  });

  test('pen mode enters drawing state', () {
    final handler = GestureHandler()..setMode(EditorMode.pen);

    handler.onPointerDown(
      position: const Offset(10, 10),
      blocks: const [],
      pageSize: pageSize,
    );

    expect(handler.gestureState, equals(GestureState.drawing));
  });

  test('tapping empty area clears selection', () {
    final handler = GestureHandler();
    final block = _block();

    handler.onPointerDown(
      position: const Offset(25, 25),
      blocks: [block],
      pageSize: pageSize,
    );
    expect(handler.selectedBlock, isNotNull);

    handler.onPointerDown(
      position: const Offset(95, 95),
      blocks: [block],
      pageSize: pageSize,
    );

    expect(handler.selectedBlock, isNull);
    expect(handler.gestureState, equals(GestureState.idle));
  });

  test('dragging from handle enters resizing state', () {
    final handler = GestureHandler();
    final block = _block();

    handler.selectBlock(block);
    handler.onPointerDown(
      position: const Offset(20, 20),
      blocks: [block],
      pageSize: pageSize,
    );

    expect(handler.gestureState, equals(GestureState.resizing));
  });
}
