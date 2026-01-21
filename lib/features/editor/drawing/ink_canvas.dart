import 'package:flutter/material.dart';

/// Ink stroke data
class InkStroke {
  final List<InkPoint> points;
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;

  InkStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.strokeCap = StrokeCap.round,
  });

  InkStroke copyWith({
    List<InkPoint>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return InkStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap,
    );
  }
}

/// Single point in an ink stroke
class InkPoint {
  final Offset position;
  final double pressure;
  final double timestamp;

  const InkPoint({
    required this.position,
    this.pressure = 1.0,
    this.timestamp = 0,
  });
}

/// Ink drawing canvas widget
class InkCanvas extends StatefulWidget {
  final Color strokeColor;
  final double strokeWidth;
  final List<InkStroke> strokes;
  final void Function(List<InkStroke>) onStrokesChanged;
  final bool isEnabled;

  const InkCanvas({
    super.key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    required this.strokes,
    required this.onStrokesChanged,
    this.isEnabled = true,
  });

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> {
  InkStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.isEnabled ? _onPanStart : null,
      onPanUpdate: widget.isEnabled ? _onPanUpdate : null,
      onPanEnd: widget.isEnabled ? _onPanEnd : null,
      child: CustomPaint(
        painter: InkPainter(
          strokes: widget.strokes,
          currentStroke: _currentStroke,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = InkStroke(
        points: [
          InkPoint(
            position: details.localPosition,
            timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
          ),
        ],
        color: widget.strokeColor,
        strokeWidth: widget.strokeWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [
          ..._currentStroke!.points,
          InkPoint(
            position: details.localPosition,
            timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
          ),
        ],
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke == null) return;

    final newStrokes = [...widget.strokes, _currentStroke!];
    widget.onStrokesChanged(newStrokes);

    setState(() {
      _currentStroke = null;
    });
  }
}

/// Ink stroke painter
class InkPainter extends CustomPainter {
  final List<InkStroke> strokes;
  final InkStroke? currentStroke;

  InkPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, InkStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = stroke.strokeCap
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(
      stroke.points.first.position.dx,
      stroke.points.first.position.dy,
    );

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1].position;
      final p1 = stroke.points[i].position;

      // Smooth curve using quadratic bezier
      final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}

/// Pen toolbar for color and size selection
class PenToolbar extends StatelessWidget {
  final Color selectedColor;
  final double selectedWidth;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool canUndo;

  const PenToolbar({
    super.key,
    required this.selectedColor,
    required this.selectedWidth,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onUndo,
    required this.onClear,
    this.canUndo = false,
  });

  static const colors = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  static const widths = [1.0, 2.0, 4.0, 8.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Colors
          ...colors.map(
            (color) => GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: color == selectedColor
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: color == selectedColor
                      ? [BoxShadow(color: color, blurRadius: 8)]
                      : null,
                ),
              ),
            ),
          ),

          const VerticalDivider(width: 24),

          // Widths
          ...widths.map(
            (width) => GestureDetector(
              onTap: () => onWidthChanged(width),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: width == selectedWidth
                      ? Colors.deepPurple.withAlpha(30)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Container(
                    width: width * 2,
                    height: width * 2,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Undo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? onUndo : null,
          ),

          // Clear
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
