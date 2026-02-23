import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'nostalgic_themes.dart';

/// Premium notebook page painter with nostalgic details
class NostalgicPagePainter extends CustomPainter {
  final NotebookTheme theme;
  final ui.Image? preloadedImage;

  NostalgicPagePainter({required this.theme, this.preloadedImage});

  @override
  void paint(Canvas canvas, Size size) {
    final visuals = theme.visuals;

    final hasImageTheme = visuals.assetPath != null;

    // If an image asset is provided and preloaded, draw it and skip procedural textures.
    if (hasImageTheme && preloadedImage != null) {
      _drawImageBackground(canvas, size, preloadedImage!);
      return;
    }

    // Background Color
    if (visuals.pageColor != Colors.transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = visuals.pageColor,
      );
    }

    // Image theme fallback when asset loading fails.
    if (hasImageTheme && preloadedImage == null) {
      final fallbackColor = visuals.pageColor == Colors.transparent
          ? const Color(0xFFF7EFE2)
          : visuals.pageColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = fallbackColor,
      );
      _drawFallbackLines(canvas, size);
      return;
    }

    // Add texture overlay based on type
    _drawTexture(canvas, size);

    // Draw pattern based on texture type
    switch (theme.texture) {
      case NotebookTexture.smooth:
        _drawLines(canvas, size);
        break;
      case NotebookTexture.aged:
        _drawAgedLines(canvas, size);
        break;
      case NotebookTexture.craft:
        _drawCraftTexture(canvas, size);
        break;
      case NotebookTexture.watercolor:
        // No lines for sketchbook
        break;
      case NotebookTexture.grid:
        _drawGrid(canvas, size);
        break;
      case NotebookTexture.dotted:
        _drawDots(canvas, size);
        break;
      case NotebookTexture.blank:
        // No pattern
        break;
    }

    // Margin line
    if (visuals.hasMarginLine && visuals.marginColor != null) {
      canvas.drawLine(
        Offset(visuals.marginLeft, 0),
        Offset(visuals.marginLeft, size.height),
        Paint()
          ..color = visuals.marginColor!
          ..strokeWidth = 1.5,
      );
    }

    // Spiral holes
    if (visuals.hasHoles) {
      _drawSpiralHoles(canvas, size);
    }
  }

  void _drawTexture(Canvas canvas, Size size) {
    // Subtle paper texture
    final random = Random(42); // Fixed seed for consistent texture
    final paint = Paint()..color = Colors.black.withAlpha(3);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.4, paint);
    }
  }

  void _drawImageBackground(Canvas canvas, Size size, ui.Image image) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }

  void _drawFallbackLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8C6B0)
      ..strokeWidth = 0.8;
    const spacing = 30.0;
    const startY = 52.0;
    for (double y = startY; y < size.height - 16; y += spacing) {
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
    }
  }

  void _drawLines(Canvas canvas, Size size) {
    final lineColor = theme.visuals.lineColor;
    if (lineColor == null) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    final spacing = theme.visuals.lineSpacing;
    const startY = 60.0; // Header space

    for (double y = startY; y < size.height - 20; y += spacing) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
  }

  void _drawAgedLines(Canvas canvas, Size size) {
    final lineColor = theme.visuals.lineColor;
    if (lineColor == null) return;

    final paint = Paint()
      ..color = lineColor.withAlpha(150)
      ..strokeWidth = 0.6;

    final spacing = theme.visuals.lineSpacing;
    const startY = 50.0;
    final random = Random(123);

    for (double y = startY; y < size.height - 20; y += spacing) {
      // Significantly simplify the path for and aged effect
      final path = Path()..moveTo(20, y);
      const segmentWidth = 60.0;
      for (
        double x = 20 + segmentWidth;
        x < size.width - 20;
        x += segmentWidth
      ) {
        final wobble = (random.nextDouble() - 0.5) * 1.5;
        path.lineTo(x, y + wobble);
      }
      path.lineTo(size.width - 20, y);
      canvas.drawPath(path, paint);
    }
  }

  void _drawCraftTexture(Canvas canvas, Size size) {
    // Fiber texture for kraft paper
    final random = Random(789);
    final paint = Paint()
      ..color = Colors.brown.withAlpha(15)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 100; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final angle = random.nextDouble() * pi;
      final length = 10 + random.nextDouble() * 20;

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x1 + cos(angle) * length, y1 + sin(angle) * length),
        paint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final lineColor = theme.visuals.lineColor;
    if (lineColor == null) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final spacing = theme.visuals.lineSpacing;

    // Vertical lines
    for (double x = 20; x < size.width - 10; x += spacing) {
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), paint);
    }

    // Horizontal lines
    for (double y = 20; y < size.height - 10; y += spacing) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size) {
    final lineColor = theme.visuals.lineColor;
    if (lineColor == null) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final spacing = theme.visuals.lineSpacing;

    for (double x = 30; x < size.width - 20; x += spacing) {
      for (double y = 40; y < size.height - 20; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  void _drawSpiralHoles(Canvas canvas, Size size) {
    final holePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(30)
      ..style = PaintingStyle.fill;

    const holeRadius = 5.0;
    const holeSpacing = 28.0;
    const leftOffset = 18.0;

    for (double y = 40; y < size.height - 30; y += holeSpacing) {
      // Hole shadow
      canvas.drawCircle(Offset(leftOffset + 1, y + 1), holeRadius, shadowPaint);
      // Hole
      canvas.drawCircle(Offset(leftOffset, y), holeRadius, holePaint);
      // Inner shadow
      canvas.drawCircle(
        Offset(leftOffset, y),
        holeRadius - 1,
        Paint()..color = Colors.grey.shade500,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NostalgicPagePainter old) =>
      old.theme.id != theme.id || old.preloadedImage != preloadedImage;
}
