import 'dart:convert';
import 'package:flutter/material.dart';

/// Optimized ink stroke storage
class InkStrokeData {
  final List<Offset> points; // Mutable for performance during drawing
  final int colorValue;
  final double width;

  InkStrokeData({
    List<Offset>? points,
    required this.colorValue,
    required this.width,
  }) : points = points ?? [];

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'color': colorValue,
    'width': width,
  };

  factory InkStrokeData.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List).map((p) {
      final coords = p as List;
      return Offset(coords[0].toDouble(), coords[1].toDouble());
    }).toList();

    return InkStrokeData(
      points: pointsList,
      colorValue: json['color'] as int,
      width: (json['width'] as num).toDouble(),
    );
  }

  static String encodeStrokes(List<InkStrokeData> strokes) {
    return jsonEncode(strokes.map((s) => s.toJson()).toList());
  }

  static List<InkStrokeData> decodeStrokes(String json) {
    if (json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((item) => InkStrokeData.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Lightweight ink painter - optimized for performance
class OptimizedInkPainter extends CustomPainter {
  final List<InkStrokeData> strokes;
  final InkStrokeData? currentStroke;

  OptimizedInkPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, InkStrokeData stroke) {
    if (stroke.points.length < 2) {
      if (stroke.points.length == 1) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width
          ..style = PaintingStyle.fill;
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
      }
      return;
    }

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }

    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OptimizedInkPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentStroke != currentStroke;
}
