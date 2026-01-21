import 'package:flutter/material.dart';

/// Notebook visual style definitions
enum NotebookStyle {
  classic, // Okul defteri - çizgili
  moleskine, // Premium siyah deri - krem sayfa
  bullet, // Noktalı sayfa - minimal
  scrapbook, // Renkli - yapıştırma alanları
  kraft, // Kraft kağıt - vintage
  watercolor, // Boş beyaz - suluboya için
}

/// Notebook style configuration
class NotebookConfig {
  final NotebookStyle style;
  final String name;
  final Color coverColor;
  final Color pageColor;
  final Color? accentColor;
  final bool hasSpiral;
  final bool hasRippedEdge;
  final double cornerRadius;
  final EdgeDecoration? edgeDecoration;

  const NotebookConfig({
    required this.style,
    required this.name,
    required this.coverColor,
    required this.pageColor,
    this.accentColor,
    this.hasSpiral = false,
    this.hasRippedEdge = false,
    this.cornerRadius = 8,
    this.edgeDecoration,
  });
}

enum EdgeDecoration { spiral, stitched, ripped, clean }

/// Built-in notebook styles
class NotebookStyles {
  static const classic = NotebookConfig(
    style: NotebookStyle.classic,
    name: 'Klasik Defter',
    coverColor: Color(0xFF7C4DFF),
    pageColor: Colors.white,
    hasSpiral: true,
    cornerRadius: 0,
    edgeDecoration: EdgeDecoration.spiral,
  );

  static const moleskine = NotebookConfig(
    style: NotebookStyle.moleskine,
    name: 'Moleskine',
    coverColor: Color(0xFF1A1A1A),
    pageColor: Color(0xFFFFF8E7),
    accentColor: Color(0xFFB8860B),
    cornerRadius: 4,
    edgeDecoration: EdgeDecoration.stitched,
  );

  static const bullet = NotebookConfig(
    style: NotebookStyle.bullet,
    name: 'Bullet Journal',
    coverColor: Color(0xFF37474F),
    pageColor: Color(0xFFFAFAFA),
    cornerRadius: 0,
    edgeDecoration: EdgeDecoration.clean,
  );

  static const scrapbook = NotebookConfig(
    style: NotebookStyle.scrapbook,
    name: 'Scrapbook',
    coverColor: Color(0xFFE91E63),
    pageColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFFF80AB),
    hasRippedEdge: true,
    cornerRadius: 0,
    edgeDecoration: EdgeDecoration.ripped,
  );

  static const kraft = NotebookConfig(
    style: NotebookStyle.kraft,
    name: 'Kraft',
    coverColor: Color(0xFF8D6E63),
    pageColor: Color(0xFFD7CCC8),
    cornerRadius: 0,
    edgeDecoration: EdgeDecoration.ripped,
  );

  static const watercolor = NotebookConfig(
    style: NotebookStyle.watercolor,
    name: 'Watercolor',
    coverColor: Color(0xFF90CAF9),
    pageColor: Colors.white,
    cornerRadius: 12,
    edgeDecoration: EdgeDecoration.clean,
  );

  static List<NotebookConfig> get all => [
    classic,
    moleskine,
    bullet,
    scrapbook,
    kraft,
    watercolor,
  ];

  static NotebookConfig getByStyle(NotebookStyle style) {
    return all.firstWhere(
      (config) => config.style == style,
      orElse: () => classic,
    );
  }
}

/// Notebook edge painter
class NotebookEdgePainter extends CustomPainter {
  final NotebookConfig config;

  NotebookEdgePainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    switch (config.edgeDecoration) {
      case EdgeDecoration.spiral:
        _drawSpiral(canvas, size);
        break;
      case EdgeDecoration.stitched:
        _drawStitches(canvas, size);
        break;
      case EdgeDecoration.ripped:
        _drawRippedEdge(canvas, size);
        break;
      case EdgeDecoration.clean:
        // No decoration
        break;
      case null:
        break;
    }
  }

  void _drawSpiral(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const ringSpacing = 20.0;
    const ringRadius = 6.0;
    const leftOffset = 20.0;

    for (double y = 30; y < size.height - 20; y += ringSpacing) {
      canvas.drawCircle(Offset(leftOffset, y), ringRadius, paint);
    }
  }

  void _drawStitches(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = config.accentColor ?? Colors.amber[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const stitchLength = 8.0;
    const stitchSpacing = 6.0;
    const margin = 8.0;

    // Top edge
    for (
      double x = margin;
      x < size.width - margin;
      x += stitchLength + stitchSpacing
    ) {
      canvas.drawLine(
        Offset(x, margin),
        Offset(x + stitchLength, margin),
        paint,
      );
    }

    // Bottom edge
    for (
      double x = margin;
      x < size.width - margin;
      x += stitchLength + stitchSpacing
    ) {
      canvas.drawLine(
        Offset(x, size.height - margin),
        Offset(x + stitchLength, size.height - margin),
        paint,
      );
    }
  }

  void _drawRippedEdge(Canvas canvas, Size size) {
    // Simulated ripped edge on top
    final paint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    double x = 0;
    while (x < size.width) {
      path.lineTo(x, 3 + (x.hashCode % 5));
      x += 8;
    }
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NotebookEdgePainter oldDelegate) {
    return oldDelegate.config.style != config.style;
  }
}
