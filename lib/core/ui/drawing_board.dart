import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingBoard extends StatefulWidget {
  final DrawingController controller;

  const DrawingBoard({super.key, required this.controller});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class DrawingController extends ChangeNotifier {
  List<Offset?> _points = [];
  Color color = Colors.black;
  double strokeWidth = 5.0;

  void addPoint(Offset? point) {
    _points.add(point);
    notifyListeners();
  }

  void clear() {
    _points.clear();
    notifyListeners();
  }

  bool get isEmpty => _points.isEmpty;

  Future<ui.Image?> toImage(Size size) async {
    if (_points.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final painter = _DrawingPainter(_points, color, strokeWidth);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }
}

class _DrawingBoardState extends State<DrawingBoard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_redraw);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_redraw);
    super.dispose();
  }

  void _redraw() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        widget.controller.addPoint(
          renderBox.globalToLocal(details.globalPosition),
        );
      },
      onPanEnd: (details) {
        widget.controller.addPoint(null); // End of stroke
      },
      child: CustomPaint(
        painter: _DrawingPainter(
          widget.controller._points,
          widget.controller.color,
          widget.controller.strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  _DrawingPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) =>
      oldDelegate.points.length != points.length;
}
