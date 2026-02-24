part of '../editor_screen.dart';

extension _EditorGesturesExtension on _EditorScreenState {
  bool _isPointInsideAnyBlock(Offset scenePoint, Size pageSize) {
    for (final block in _blocks) {
      final hit = _isPointInsideBlock(
        scenePoint: scenePoint,
        block: block,
        pageSize: pageSize,
      );
      if (hit) {
        return true;
      }
    }
    return false;
  }

  void _onCanvasDoubleTap(TapDownDetails details, Size pageSize) {
    final scenePoint = _toScene(details.localPosition);
    final hitAnyBlock = _isPointInsideAnyBlock(scenePoint, pageSize);
    if (!hitAnyBlock) {
      _resetPageZoom();
    }
  }

  void _onTapDown(TapDownDetails details, Size pageSize) {
    final scenePoint = _toScene(details.localPosition);
    if (_mode == EditorMode.select) {
      final sorted = List<Block>.from(_blocks)
        ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
      String? hitBlockId;
      for (final block in sorted) {
        final hit = _isPointInsideBlock(
          scenePoint: scenePoint,
          block: block,
          pageSize: pageSize,
        );
        if (hit) {
          hitBlockId = block.id;
          break;
        }
      }
      _applyState(() => _selectedBlockId = hitBlockId);
      return;
    }

    if (_mode == EditorMode.erase) {
      _eraseAtPoint(scenePoint);
    }
  }

  void _onTapUp(TapUpDetails details, Size pageSize) {
    if (_mode == EditorMode.select) {
      return;
    }

    if (_mode == EditorMode.erase && _eraserPreviewPoint != null) {
      _applyState(() => _eraserPreviewPoint = null);
    }
  }

  void _onPanStart(DragStartDetails details, Size pageSize) {
    if (_mode == EditorMode.select &&
        (_activePointerCount >= 2 || _activeScaleTarget != _ScaleTarget.none)) {
      return;
    }
    final scenePoint = _toScene(details.localPosition);
    if (_mode == EditorMode.draw) {
      // Start a new immutable stroke list so painter sees a changed reference.
      final point = scenePoint;
      final stroke = InkStrokeData(
        points: [point],
        colorValue: _penColor.toARGB32(),
        width: _penWidth,
      );
      _applyState(() {
        _strokes = [..._strokes, stroke];
        _isDirty = true;
      });
    } else if (_mode == EditorMode.erase) {
      _eraseAtPoint(scenePoint);
    } else if (_mode == EditorMode.select && _selectedBlockId != null) {
      // Start dragging selected block
      _dragStart = scenePoint;
      final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
      _originalPosition = Offset(block.x, block.y);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size pageSize) {
    if (_mode == EditorMode.draw && _strokes.isNotEmpty) {
      // Append point immutably so CustomPainter always repaints immediately.
      final point = _toScene(details.localPosition);
      final lastStroke = _strokes.last;
      final updatedLastStroke = InkStrokeData(
        points: [...lastStroke.points, point],
        colorValue: lastStroke.colorValue,
        width: lastStroke.width,
      );
      _applyState(() {
        _strokes = [
          ..._strokes.sublist(0, _strokes.length - 1),
          updatedLastStroke,
        ];
        _isDirty = true;
      });
    } else if (_mode == EditorMode.erase) {
      _eraseAtPoint(_toScene(details.localPosition));
    } else if (_mode == EditorMode.select &&
        _selectedBlockId != null &&
        _dragStart != null &&
        _activeHandle == null) {
      // Move block
      final scenePosition = _toScene(details.localPosition);
      final delta = scenePosition - _dragStart!;
      final dx = delta.dx / pageSize.width;
      final dy = delta.dy / pageSize.height;

      _applyState(() {
        final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
        if (index != -1) {
          _blocks[index] = _blocks[index].copyWith(
            x: (_originalPosition!.dx + dx).clamp(
              0.0,
              1.0 - _blocks[index].width,
            ),
            y: (_originalPosition!.dy + dy).clamp(
              0.0,
              1.0 - _blocks[index].height,
            ),
          );
          _isDirty = true;
        }
      });
    }
  }

  void _onPanEnd() {
    _dragStart = null;
    _originalPosition = null;
    if (_eraserPreviewPoint != null) {
      _applyState(() => _eraserPreviewPoint = null);
    }
  }

  double get _eraseRadius => (_penWidth * 6).clamp(10.0, 36.0).toDouble();

  void _eraseAtPoint(Offset point) {
    final eraseRadius = _eraseRadius;
    final eraseRadiusSq = eraseRadius * eraseRadius;
    var changed = false;
    final next = <InkStrokeData>[];

    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

      final hit = stroke.points.any((p) {
        final dx = p.dx - point.dx;
        final dy = p.dy - point.dy;
        return (dx * dx) + (dy * dy) <= eraseRadiusSq;
      });

      if (!hit) {
        next.add(stroke);
        continue;
      }

      changed = true;
      var segment = <Offset>[];

      for (final p in stroke.points) {
        final dx = p.dx - point.dx;
        final dy = p.dy - point.dy;
        final inside = (dx * dx) + (dy * dy) <= eraseRadiusSq;

        if (inside) {
          if (segment.isNotEmpty) {
            next.add(
              InkStrokeData(
                points: List<Offset>.from(segment),
                colorValue: stroke.colorValue,
                width: stroke.width,
              ),
            );
            segment = <Offset>[];
          }
          continue;
        }

        segment.add(p);
      }

      if (segment.isNotEmpty) {
        next.add(
          InkStrokeData(
            points: List<Offset>.from(segment),
            colorValue: stroke.colorValue,
            width: stroke.width,
          ),
        );
      }
    }

    final previewPoint = _eraserPreviewPoint;
    final previewMoved =
        previewPoint == null ||
        ((previewPoint.dx - point.dx).abs() > 0.5 ||
            (previewPoint.dy - point.dy).abs() > 0.5);

    if (changed || previewMoved) {
      _applyState(() {
        _eraserPreviewPoint = point;
        if (changed) {
          _strokes = next;
          _isDirty = true;
        }
      });
    }
  }

  void _onResize(
    Block block,
    DragUpdateDetails details,
    _HandleType type,
    Size pageSize,
  ) {
    final sceneDelta = _toSceneDelta(details.delta);
    final delta = Offset(
      sceneDelta.dx / pageSize.width,
      sceneDelta.dy / pageSize.height,
    );

    _applyState(() {
      final index = _blocks.indexWhere((b) => b.id == block.id);
      if (index == -1) return;

      var newBlock = _blocks[index];

      switch (type) {
        case _HandleType.bottomRight:
          newBlock = newBlock.copyWith(
            width: (newBlock.width + delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height + delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.topLeft:
          newBlock = newBlock.copyWith(
            x: (newBlock.x + delta.dx).clamp(0.0, 0.9),
            y: (newBlock.y + delta.dy).clamp(0.0, 0.9),
            width: (newBlock.width - delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height - delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.topRight:
          newBlock = newBlock.copyWith(
            y: (newBlock.y + delta.dy).clamp(0.0, 0.9),
            width: (newBlock.width + delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height - delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.bottomLeft:
          newBlock = newBlock.copyWith(
            x: (newBlock.x + delta.dx).clamp(0.0, 0.9),
            width: (newBlock.width - delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height + delta.dy).clamp(0.05, 0.9),
          );
          break;
        default:
          break;
      }

      _blocks[index] = newBlock;
      _isDirty = true;
    });
  }

  void _onRotate(Block block, DragUpdateDetails details, Size pageSize) {
    final center = Offset(
      block.x * pageSize.width + block.width * pageSize.width / 2,
      block.y * pageSize.height + block.height * pageSize.height / 2,
    );

    final angle =
        atan2(
              details.localPosition.dy - center.dy,
              details.localPosition.dx - center.dx,
            ) *
            180 /
            pi +
        90;

    _applyState(() {
      final index = _blocks.indexWhere((b) => b.id == block.id);
      if (index != -1) {
        _blocks[index] = _blocks[index].copyWith(rotation: angle);
        _isDirty = true;
      }
    });
  }
}
