import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/commands/command_history.dart';

Block _block() {
  return Block(
    id: 'b1',
    pageId: 'p1',
    type: BlockType.text,
    x: 0.1,
    y: 0.1,
    width: 0.2,
    height: 0.2,
    payloadJson: '{}',
  );
}

class _NoopCommand extends EditorCommand {
  @override
  String get description => 'noop';

  @override
  void execute() {}

  @override
  void undo() {}
}

void main() {
  test('add command supports undo/redo', () {
    final items = <Block>[];
    final history = CommandHistory();
    final block = _block();

    final command = AddBlockCommand(
      block: block,
      onAdd: items.add,
      onRemove: (id) => items.removeWhere((e) => e.id == id),
    );

    history.execute(command);
    expect(items, [block]);
    expect(history.canUndo, isTrue);

    history.undo();
    expect(items, isEmpty);
    expect(history.canRedo, isTrue);

    history.redo();
    expect(items, [block]);
  });

  test('move commands merge while dragging', () {
    final history = CommandHistory();
    final positions = <double>[];

    history.execute(
      MoveBlockCommand(
        blockId: 'b1',
        oldX: 0.1,
        oldY: 0.1,
        newX: 0.2,
        newY: 0.2,
        onMove: (id, x, y) => positions.add(x),
      ),
    );

    history.execute(
      MoveBlockCommand(
        blockId: 'b1',
        oldX: 0.2,
        oldY: 0.2,
        newX: 0.3,
        newY: 0.3,
        onMove: (id, x, y) => positions.add(x),
      ),
    );

    expect(history.undoCount, equals(1));
    expect(history.undoDescription, equals('Move block'));
  });

  test('history keeps max size', () {
    final history = CommandHistory();

    for (var i = 0; i < 120; i++) {
      history.execute(_NoopCommand());
    }

    expect(history.undoCount, equals(CommandHistory.maxHistorySize));
  });

  test('redo stack clears when new command is executed', () {
    final history = CommandHistory();

    history.execute(_NoopCommand());
    history.undo();
    expect(history.canRedo, isTrue);

    history.execute(_NoopCommand());
    expect(history.canRedo, isFalse);
  });
}
