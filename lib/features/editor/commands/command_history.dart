import 'package:flutter/foundation.dart';
import 'package:journal_app/core/models/block.dart';

/// Base class for all editor commands
/// Implements the Command pattern for undo/redo
abstract class EditorCommand {
  /// Execute the command
  void execute();

  /// Undo the command
  void undo();

  /// Command description for debugging
  String get description;

  /// Timestamp when command was created
  final DateTime createdAt = DateTime.now();

  /// Whether this command can be merged with another
  bool canMerge(EditorCommand other) => false;

  /// Merge with another command (for coalescing)
  EditorCommand? merge(EditorCommand other) => null;
}

/// Command for adding a block
class AddBlockCommand extends EditorCommand {
  final Block block;
  final void Function(Block) onAdd;
  final void Function(String) onRemove;

  AddBlockCommand({
    required this.block,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  void execute() => onAdd(block);

  @override
  void undo() => onRemove(block.id);

  @override
  String get description => 'Add ${block.type.name} block';
}

/// Command for deleting a block
class DeleteBlockCommand extends EditorCommand {
  final Block block;
  final void Function(Block) onAdd;
  final void Function(String) onRemove;

  DeleteBlockCommand({
    required this.block,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  void execute() => onRemove(block.id);

  @override
  void undo() => onAdd(block);

  @override
  String get description => 'Delete ${block.type.name} block';
}

/// Command for moving a block
class MoveBlockCommand extends EditorCommand {
  final String blockId;
  final double oldX;
  final double oldY;
  final double newX;
  final double newY;
  final void Function(String, double, double) onMove;

  MoveBlockCommand({
    required this.blockId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
    required this.onMove,
  });

  @override
  void execute() => onMove(blockId, newX, newY);

  @override
  void undo() => onMove(blockId, oldX, oldY);

  @override
  String get description => 'Move block';

  @override
  bool canMerge(EditorCommand other) {
    return other is MoveBlockCommand &&
        other.blockId == blockId &&
        (other.createdAt.difference(createdAt).inMilliseconds < 500);
  }

  @override
  EditorCommand? merge(EditorCommand other) {
    if (other is MoveBlockCommand && other.blockId == blockId) {
      return MoveBlockCommand(
        blockId: blockId,
        oldX: oldX,
        oldY: oldY,
        newX: other.newX,
        newY: other.newY,
        onMove: onMove,
      );
    }
    return null;
  }
}

/// Command for resizing a block
class ResizeBlockCommand extends EditorCommand {
  final String blockId;
  final double oldX, oldY, oldWidth, oldHeight;
  final double newX, newY, newWidth, newHeight;
  final void Function(String, double, double, double, double) onResize;

  ResizeBlockCommand({
    required this.blockId,
    required this.oldX,
    required this.oldY,
    required this.oldWidth,
    required this.oldHeight,
    required this.newX,
    required this.newY,
    required this.newWidth,
    required this.newHeight,
    required this.onResize,
  });

  @override
  void execute() => onResize(blockId, newX, newY, newWidth, newHeight);

  @override
  void undo() => onResize(blockId, oldX, oldY, oldWidth, oldHeight);

  @override
  String get description => 'Resize block';

  @override
  bool canMerge(EditorCommand other) {
    return other is ResizeBlockCommand &&
        other.blockId == blockId &&
        (other.createdAt.difference(createdAt).inMilliseconds < 500);
  }

  @override
  EditorCommand? merge(EditorCommand other) {
    if (other is ResizeBlockCommand && other.blockId == blockId) {
      return ResizeBlockCommand(
        blockId: blockId,
        oldX: oldX,
        oldY: oldY,
        oldWidth: oldWidth,
        oldHeight: oldHeight,
        newX: other.newX,
        newY: other.newY,
        newWidth: other.newWidth,
        newHeight: other.newHeight,
        onResize: onResize,
      );
    }
    return null;
  }
}

/// Command for rotating a block
class RotateBlockCommand extends EditorCommand {
  final String blockId;
  final double oldRotation;
  final double newRotation;
  final void Function(String, double) onRotate;

  RotateBlockCommand({
    required this.blockId,
    required this.oldRotation,
    required this.newRotation,
    required this.onRotate,
  });

  @override
  void execute() => onRotate(blockId, newRotation);

  @override
  void undo() => onRotate(blockId, oldRotation);

  @override
  String get description => 'Rotate block';

  @override
  bool canMerge(EditorCommand other) {
    return other is RotateBlockCommand &&
        other.blockId == blockId &&
        (other.createdAt.difference(createdAt).inMilliseconds < 500);
  }

  @override
  EditorCommand? merge(EditorCommand other) {
    if (other is RotateBlockCommand && other.blockId == blockId) {
      return RotateBlockCommand(
        blockId: blockId,
        oldRotation: oldRotation,
        newRotation: other.newRotation,
        onRotate: onRotate,
      );
    }
    return null;
  }
}

/// Command for updating block z-index
class ReorderZCommand extends EditorCommand {
  final String blockId;
  final int oldZIndex;
  final int newZIndex;
  final void Function(String, int) onReorder;

  ReorderZCommand({
    required this.blockId,
    required this.oldZIndex,
    required this.newZIndex,
    required this.onReorder,
  });

  @override
  void execute() => onReorder(blockId, newZIndex);

  @override
  void undo() => onReorder(blockId, oldZIndex);

  @override
  String get description => 'Reorder block z-index';
}

/// Command for updating block payload
class UpdatePayloadCommand extends EditorCommand {
  final String blockId;
  final String oldPayload;
  final String newPayload;
  final void Function(String, String) onUpdate;

  UpdatePayloadCommand({
    required this.blockId,
    required this.oldPayload,
    required this.newPayload,
    required this.onUpdate,
  });

  @override
  void execute() => onUpdate(blockId, newPayload);

  @override
  void undo() => onUpdate(blockId, oldPayload);

  @override
  String get description => 'Update block content';
}

/// Command history manager for undo/redo
class CommandHistory extends ChangeNotifier {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  /// Maximum history size
  static const int maxHistorySize = 100;

  /// Whether there are commands to undo
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands to redo
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of commands in undo stack
  int get undoCount => _undoStack.length;

  /// Number of commands in redo stack
  int get redoCount => _redoStack.length;

  /// Execute a command and add to history
  void execute(EditorCommand command) {
    command.execute();

    // Try to merge with last command (coalescing)
    if (_undoStack.isNotEmpty && _undoStack.last.canMerge(command)) {
      final merged = _undoStack.last.merge(command);
      if (merged != null) {
        _undoStack.removeLast();
        _undoStack.add(merged);
        _redoStack.clear();
        notifyListeners();
        return;
      }
    }

    _undoStack.add(command);
    _redoStack.clear();

    // Limit history size
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Undo the last command
  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    notifyListeners();
  }

  /// Redo the last undone command
  void redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    notifyListeners();
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Get description of command to undo
  String? get undoDescription => canUndo ? _undoStack.last.description : null;

  /// Get description of command to redo
  String? get redoDescription => canRedo ? _redoStack.last.description : null;
}
