import 'dart:math';
import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';

/// Hit-test service for detecting block selection
/// Uses z-index ordering: higher z-index blocks are tested first
/// Uses AABB (fast) then OBB (accurate) for rotated blocks
class HitTestService {
  /// Touch tolerance in logical pixels
  static const double touchTolerance = 10.0;

  /// Minimum percentage of block that must be inside page bounds
  static const double minInsideRatio = 0.1;

  /// Find the block at the given point
  /// Returns null if no block is at the point
  /// Blocks are tested in reverse z-order (highest first)
  static Block? hitTest({
    required List<Block> blocks,
    required Offset point,
    required Size pageSize,
  }) {
    // Sort by z-index descending (highest first)
    final sortedBlocks = List<Block>.from(blocks)
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (final block in sortedBlocks) {
      if (isPointInBlock(block, point, pageSize)) {
        return block;
      }
    }

    return null;
  }

  /// Check if a point is inside a block
  static bool isPointInBlock(Block block, Offset point, Size pageSize) {
    // Convert normalized coordinates to page coordinates
    final blockRect = Rect.fromLTWH(
      block.x * pageSize.width,
      block.y * pageSize.height,
      block.width * pageSize.width,
      block.height * pageSize.height,
    );

    // Expand rect by touch tolerance
    final expandedRect = blockRect.inflate(touchTolerance);

    // Fast AABB check first
    if (!_aabbContains(expandedRect, point, block.rotation)) {
      return false;
    }

    // If block is not rotated, AABB is sufficient
    if (block.rotation == 0) {
      return expandedRect.contains(point);
    }

    // For rotated blocks, do precise OBB check
    return _obbContains(blockRect, point, block.rotation);
  }

  /// Fast axis-aligned bounding box check
  /// For rotated blocks, this checks the bounding box of the rotated rect
  static bool _aabbContains(Rect rect, Offset point, double rotationDeg) {
    if (rotationDeg == 0) {
      return rect.contains(point);
    }

    // Get rotated bounding box
    final center = rect.center;
    final corners = _getRotatedCorners(rect, center, rotationDeg);

    double minX = corners[0].dx;
    double maxX = corners[0].dx;
    double minY = corners[0].dy;
    double maxY = corners[0].dy;

    for (final corner in corners) {
      minX = min(minX, corner.dx);
      maxX = max(maxX, corner.dx);
      minY = min(minY, corner.dy);
      maxY = max(maxY, corner.dy);
    }

    final aabb = Rect.fromLTRB(minX, maxX, minY, maxY);
    return aabb.inflate(touchTolerance).contains(point);
  }

  /// Precise oriented bounding box check for rotated blocks
  static bool _obbContains(Rect rect, Offset point, double rotationDeg) {
    final center = rect.center;
    final rotationRad = rotationDeg * pi / 180;

    // Transform point to block's local coordinate system
    // Rotate point around block center in opposite direction
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    final cosAngle = cos(-rotationRad);
    final sinAngle = sin(-rotationRad);

    final localX = dx * cosAngle - dy * sinAngle + center.dx;
    final localY = dx * sinAngle + dy * cosAngle + center.dy;

    final localPoint = Offset(localX, localY);

    // Check if point is in non-rotated rect
    return rect.inflate(touchTolerance).contains(localPoint);
  }

  /// Get corners of rotated rect
  static List<Offset> _getRotatedCorners(
    Rect rect,
    Offset center,
    double rotationDeg,
  ) {
    final rotationRad = rotationDeg * pi / 180;
    final cosAngle = cos(rotationRad);
    final sinAngle = sin(rotationRad);

    Offset rotatePoint(Offset point) {
      final dx = point.dx - center.dx;
      final dy = point.dy - center.dy;
      return Offset(
        dx * cosAngle - dy * sinAngle + center.dx,
        dx * sinAngle + dy * cosAngle + center.dy,
      );
    }

    return [
      rotatePoint(rect.topLeft),
      rotatePoint(rect.topRight),
      rotatePoint(rect.bottomRight),
      rotatePoint(rect.bottomLeft),
    ];
  }

  /// Check if point is near a resize handle
  /// Returns the handle position if hit, null otherwise
  static HandlePosition? hitTestHandle({
    required Block block,
    required Offset point,
    required Size pageSize,
    double handleSize = 24.0,
  }) {
    final blockRect = Rect.fromLTWH(
      block.x * pageSize.width,
      block.y * pageSize.height,
      block.width * pageSize.width,
      block.height * pageSize.height,
    );

    final center = blockRect.center;
    final rotationRad = block.rotation * pi / 180;

    // Get handle positions
    final handles = {
      HandlePosition.topLeft: blockRect.topLeft,
      HandlePosition.topRight: blockRect.topRight,
      HandlePosition.bottomLeft: blockRect.bottomLeft,
      HandlePosition.bottomRight: blockRect.bottomRight,
      HandlePosition.rotate: Offset(blockRect.center.dx, blockRect.top - 30),
    };

    for (final entry in handles.entries) {
      // Rotate handle position
      final handle = entry.value;
      final dx = handle.dx - center.dx;
      final dy = handle.dy - center.dy;

      final rotatedHandle = Offset(
        dx * cos(rotationRad) - dy * sin(rotationRad) + center.dx,
        dx * sin(rotationRad) + dy * cos(rotationRad) + center.dy,
      );

      // Check if point is within handle area
      final handleRect = Rect.fromCenter(
        center: rotatedHandle,
        width: handleSize,
        height: handleSize,
      );

      if (handleRect.contains(point)) {
        return entry.key;
      }
    }

    return null;
  }
}

/// Handle positions for resize/rotate
enum HandlePosition { topLeft, topRight, bottomLeft, bottomRight, rotate }
