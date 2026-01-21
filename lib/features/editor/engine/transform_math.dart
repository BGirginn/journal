import 'dart:math';
import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';
import 'hit_test.dart' show HandlePosition;

/// Transform math utilities for block manipulation
/// All coordinates are normalized [0..1] for cross-device compatibility
class TransformMath {
  /// Minimum block size (normalized)
  static const double minWidth = 0.06;
  static const double minHeight = 0.06;

  /// Maximum rotation snap angle in degrees
  static const double snapAngle = 15.0;

  /// Move a block by delta, keeping at least minInsideRatio inside bounds
  static Block moveBlock({
    required Block block,
    required Offset deltaNormalized,
    double minInsideRatio = 0.1,
  }) {
    double newX = block.x + deltaNormalized.dx;
    double newY = block.y + deltaNormalized.dy;

    // Clamp to keep minimum portion inside [0..1]
    final minAllowedX = -block.width * (1 - minInsideRatio);
    final maxAllowedX = 1 - block.width * minInsideRatio;
    final minAllowedY = -block.height * (1 - minInsideRatio);
    final maxAllowedY = 1 - block.height * minInsideRatio;

    newX = newX.clamp(minAllowedX, maxAllowedX);
    newY = newY.clamp(minAllowedY, maxAllowedY);

    return block.copyWith(x: newX, y: newY, updatedAt: DateTime.now());
  }

  /// Resize a block from a handle
  /// Anchor is the opposite corner which stays fixed
  static Block resizeBlock({
    required Block block,
    required HandlePosition handle,
    required Offset newHandlePositionNormalized,
    required Size pageSize,
  }) {
    // Get the anchor corner (opposite to the handle being dragged)
    final blockRect = Rect.fromLTWH(
      block.x,
      block.y,
      block.width,
      block.height,
    );

    Offset anchor;
    switch (handle) {
      case HandlePosition.topLeft:
        anchor = blockRect.bottomRight;
        break;
      case HandlePosition.topRight:
        anchor = blockRect.bottomLeft;
        break;
      case HandlePosition.bottomLeft:
        anchor = blockRect.topRight;
        break;
      case HandlePosition.bottomRight:
        anchor = blockRect.topLeft;
        break;
      case HandlePosition.rotate:
        return block; // Rotate doesn't resize
    }

    // If block is rotated, transform the new position to local coords
    Offset localNewPos = newHandlePositionNormalized;
    if (block.rotation != 0) {
      localNewPos = _rotatePointAroundCenter(
        newHandlePositionNormalized,
        Offset(block.x + block.width / 2, block.y + block.height / 2),
        -block.rotation,
      );
    }

    // Calculate new rect from anchor and new handle position
    double newX = min(anchor.dx, localNewPos.dx);
    double newY = min(anchor.dy, localNewPos.dy);
    double newWidth = (anchor.dx - localNewPos.dx).abs();
    double newHeight = (anchor.dy - localNewPos.dy).abs();

    // Enforce minimum size
    if (newWidth < minWidth) {
      newWidth = minWidth;
      if (localNewPos.dx < anchor.dx) {
        newX = anchor.dx - minWidth;
      }
    }
    if (newHeight < minHeight) {
      newHeight = minHeight;
      if (localNewPos.dy < anchor.dy) {
        newY = anchor.dy - minHeight;
      }
    }

    return block.copyWith(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
      updatedAt: DateTime.now(),
    );
  }

  /// Rotate a block based on drag position
  static Block rotateBlock({
    required Block block,
    required Offset dragPositionNormalized,
    Offset? initialDragOffset,
    bool snap = false,
  }) {
    final center = Offset(
      block.x + block.width / 2,
      block.y + block.height / 2,
    );

    // Calculate angle from center to drag position
    final dx = dragPositionNormalized.dx - center.dx;
    final dy = dragPositionNormalized.dy - center.dy;

    // atan2 gives angle in radians, convert to degrees
    // Subtract 90 degrees because 0° should be pointing up
    double angleDeg = atan2(dy, dx) * 180 / pi + 90;

    // Normalize to 0-360 range
    while (angleDeg < 0) {
      angleDeg += 360;
    }
    while (angleDeg >= 360) {
      angleDeg -= 360;
    }

    // Apply snapping if enabled
    if (snap) {
      angleDeg = (angleDeg / snapAngle).round() * snapAngle;
    }

    return block.copyWith(rotation: angleDeg, updatedAt: DateTime.now());
  }

  /// Convert viewport coordinates to normalized page coordinates
  static Offset viewportToNormalized(Offset viewportPoint, Size pageSize) {
    return Offset(
      viewportPoint.dx / pageSize.width,
      viewportPoint.dy / pageSize.height,
    );
  }

  /// Convert normalized coordinates to viewport coordinates
  static Offset normalizedToViewport(Offset normalizedPoint, Size pageSize) {
    return Offset(
      normalizedPoint.dx * pageSize.width,
      normalizedPoint.dy * pageSize.height,
    );
  }

  /// Convert a delta in viewport pixels to normalized delta
  static Offset viewportDeltaToNormalized(Offset viewportDelta, Size pageSize) {
    return Offset(
      viewportDelta.dx / pageSize.width,
      viewportDelta.dy / pageSize.height,
    );
  }

  /// Rotate a point around a center by given degrees
  static Offset _rotatePointAroundCenter(
    Offset point,
    Offset center,
    double degrees,
  ) {
    final radians = degrees * pi / 180;
    final cos_ = cos(radians);
    final sin_ = sin(radians);

    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    return Offset(
      dx * cos_ - dy * sin_ + center.dx,
      dx * sin_ + dy * cos_ + center.dy,
    );
  }

  /// Calculate the bounding box of a rotated block
  static Rect getRotatedBoundingBox(Block block, Size pageSize) {
    final rect = Rect.fromLTWH(
      block.x * pageSize.width,
      block.y * pageSize.height,
      block.width * pageSize.width,
      block.height * pageSize.height,
    );

    if (block.rotation == 0) {
      return rect;
    }

    final center = rect.center;
    final radians = block.rotation * pi / 180;
    final cos_ = cos(radians);
    final sin_ = sin(radians);

    Offset rotateCorner(Offset corner) {
      final dx = corner.dx - center.dx;
      final dy = corner.dy - center.dy;
      return Offset(
        dx * cos_ - dy * sin_ + center.dx,
        dx * sin_ + dy * cos_ + center.dy,
      );
    }

    final corners = [
      rotateCorner(rect.topLeft),
      rotateCorner(rect.topRight),
      rotateCorner(rect.bottomLeft),
      rotateCorner(rect.bottomRight),
    ];

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

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
