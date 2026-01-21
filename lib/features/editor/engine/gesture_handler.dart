import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';
import 'hit_test.dart';
import 'transform_math.dart';

/// Editor modes
enum EditorMode {
  view, // Page navigation, no block interaction
  edit, // Block selection, move, resize, rotate
  pen, // Ink drawing mode
}

/// Gesture handler for the editor
/// Handles touch/pointer events and delegates to appropriate handlers
class GestureHandler extends ChangeNotifier {
  /// Current editor mode
  EditorMode _mode = EditorMode.edit;
  EditorMode get mode => _mode;

  /// Currently selected block
  Block? _selectedBlock;
  Block? get selectedBlock => _selectedBlock;

  /// Active handle being dragged
  HandlePosition? _activeHandle;
  HandlePosition? get activeHandle => _activeHandle;

  /// Gesture state
  GestureState _gestureState = GestureState.idle;
  GestureState get gestureState => _gestureState;

  /// Drag start position (normalized)
  Offset? _dragStartNormalized;

  /// Block state at drag start (for undo)
  Block? _blockAtDragStart;

  /// Callbacks for state changes
  void Function(Block oldBlock, Block newBlock)? onBlockTransformed;
  void Function(Block)? onBlockSelected;
  void Function()? onSelectionCleared;
  void Function()? onGestureEnd;

  /// Set editor mode
  void setMode(EditorMode mode) {
    if (_mode != mode) {
      _mode = mode;
      if (mode != EditorMode.edit) {
        clearSelection();
      }
      notifyListeners();
    }
  }

  /// Select a block
  void selectBlock(Block block) {
    _selectedBlock = block;
    onBlockSelected?.call(block);
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    if (_selectedBlock != null) {
      _selectedBlock = null;
      onSelectionCleared?.call();
      notifyListeners();
    }
  }

  /// Handle pointer down event
  void onPointerDown({
    required Offset position,
    required List<Block> blocks,
    required Size pageSize,
  }) {
    if (_mode == EditorMode.view) return;
    if (_mode == EditorMode.pen) {
      // Pen mode: start ink stroke
      _gestureState = GestureState.drawing;
      notifyListeners();
      return;
    }

    // Edit mode
    final normalizedPos = TransformMath.viewportToNormalized(
      position,
      pageSize,
    );

    // Check if we're hitting a handle on selected block
    if (_selectedBlock != null) {
      final handle = HitTestService.hitTestHandle(
        block: _selectedBlock!,
        point: position,
        pageSize: pageSize,
      );

      if (handle != null) {
        _activeHandle = handle;
        _gestureState = handle == HandlePosition.rotate
            ? GestureState.rotating
            : GestureState.resizing;
        _dragStartNormalized = normalizedPos;
        _blockAtDragStart = _selectedBlock;
        notifyListeners();
        return;
      }
    }

    // Hit test for block selection
    final hitBlock = HitTestService.hitTest(
      blocks: blocks,
      point: position,
      pageSize: pageSize,
    );

    if (hitBlock != null) {
      if (_selectedBlock?.id != hitBlock.id) {
        selectBlock(hitBlock);
      }
      _gestureState = GestureState.dragging;
      _dragStartNormalized = normalizedPos;
      _blockAtDragStart = hitBlock;
    } else {
      clearSelection();
      _gestureState = GestureState.idle;
    }

    notifyListeners();
  }

  /// Handle pointer move event
  Block? onPointerMove({required Offset position, required Size pageSize}) {
    if (_gestureState == GestureState.idle) return null;
    if (_selectedBlock == null || _dragStartNormalized == null) return null;

    final currentNormalized = TransformMath.viewportToNormalized(
      position,
      pageSize,
    );

    Block? newBlock;

    switch (_gestureState) {
      case GestureState.dragging:
        final delta = Offset(
          currentNormalized.dx - _dragStartNormalized!.dx,
          currentNormalized.dy - _dragStartNormalized!.dy,
        );
        newBlock = TransformMath.moveBlock(
          block: _blockAtDragStart!,
          deltaNormalized: delta,
        );
        break;

      case GestureState.resizing:
        if (_activeHandle != null) {
          newBlock = TransformMath.resizeBlock(
            block: _blockAtDragStart!,
            handle: _activeHandle!,
            newHandlePositionNormalized: currentNormalized,
            pageSize: pageSize,
          );
        }
        break;

      case GestureState.rotating:
        newBlock = TransformMath.rotateBlock(
          block: _blockAtDragStart!,
          dragPositionNormalized: currentNormalized,
        );
        break;

      case GestureState.drawing:
        // Ink drawing handled elsewhere
        break;

      case GestureState.idle:
        break;
    }

    if (newBlock != null) {
      _selectedBlock = newBlock;
      notifyListeners();
    }

    return newBlock;
  }

  /// Handle pointer up event
  void onPointerUp() {
    if (_gestureState != GestureState.idle) {
      // Notify about gesture end for command creation
      if (_blockAtDragStart != null && _selectedBlock != null) {
        onBlockTransformed?.call(_blockAtDragStart!, _selectedBlock!);
      }

      onGestureEnd?.call();
    }

    _gestureState = GestureState.idle;
    _activeHandle = null;
    _dragStartNormalized = null;
    _blockAtDragStart = null;

    notifyListeners();
  }

  /// Cancel current gesture
  void cancelGesture() {
    if (_blockAtDragStart != null) {
      _selectedBlock = _blockAtDragStart;
    }

    _gestureState = GestureState.idle;
    _activeHandle = null;
    _dragStartNormalized = null;
    _blockAtDragStart = null;

    notifyListeners();
  }

  /// Check if a gesture is in progress
  bool get isGestureActive => _gestureState != GestureState.idle;
}

/// Gesture state enum
enum GestureState { idle, dragging, resizing, rotating, drawing }
