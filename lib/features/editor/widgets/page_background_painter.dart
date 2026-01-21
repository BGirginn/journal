import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/journal_theme.dart';

/// Custom painter for page background patterns
class PageBackgroundPainter extends CustomPainter {
  final JournalTheme theme;

  PageBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()..color = theme.pageBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw pattern based on style
    switch (theme.pageStyle) {
      case PageBackgroundStyle.lined:
        _drawLinedPattern(canvas, size);
        break;
      case PageBackgroundStyle.grid:
        _drawGridPattern(canvas, size);
        break;
      case PageBackgroundStyle.dotted:
        _drawDottedPattern(canvas, size);
        break;
      case PageBackgroundStyle.blank:
        // No pattern
        break;
    }
  }

  void _drawLinedPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.lineColor
      ..strokeWidth = 1;

    const lineSpacing = 28.0;
    const marginTop = 50.0;
    const marginLeft = 40.0;

    // Horizontal lines
    for (double y = marginTop; y < size.height - 20; y += lineSpacing) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }

    // Red margin line
    final marginPaint = Paint()
      ..color = Colors.red.withAlpha(40)
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(marginLeft, 0),
      Offset(marginLeft, size.height),
      marginPaint,
    );
  }

  void _drawGridPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.lineColor
      ..strokeWidth = 0.5;

    const gridSpacing = 20.0;

    // Vertical lines
    for (double x = 20; x < size.width - 20; x += gridSpacing) {
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), paint);
    }

    // Horizontal lines
    for (double y = 20; y < size.height - 20; y += gridSpacing) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
  }

  void _drawDottedPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.lineColor
      ..style = PaintingStyle.fill;

    const dotSpacing = 20.0;
    const dotRadius = 1.5;

    for (double x = 30; x < size.width - 20; x += dotSpacing) {
      for (double y = 30; y < size.height - 20; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PageBackgroundPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id;
  }
}
