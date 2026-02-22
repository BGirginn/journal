import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Full-screen drawing canvas for journal pages
class DrawingCanvasScreen extends StatefulWidget {
  final String? existingImagePath;

  const DrawingCanvasScreen({super.key, this.existingImagePath});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _undoneStrokes = [];
  DrawingStroke? _currentStroke;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  final GlobalKey _canvasKey = GlobalKey();

  final _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.teal,
    Colors.white,
  ];

  final _strokeWidths = [1.5, 3.0, 5.0, 8.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Çizim'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty
                ? null
                : () {
                    setState(() {
                      _undoneStrokes.add(_strokes.removeLast());
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoneStrokes.isEmpty
                ? null
                : () {
                    setState(() {
                      _strokes.add(_undoneStrokes.removeLast());
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _strokes.isEmpty
                ? null
                : () {
                    setState(() {
                      _strokes.clear();
                      _undoneStrokes.clear();
                    });
                  },
          ),
          FilledButton.icon(
            onPressed: _strokes.isEmpty ? null : _saveAndReturn,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Kaydet'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: Container(
                color: Colors.white,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = DrawingStroke(
                        color: _isEraser ? Colors.white : _selectedColor,
                        width: _isEraser ? _strokeWidth * 3 : _strokeWidth,
                        points: [details.localPosition],
                      );
                    });
                  },
                  onPanUpdate: (details) {
                    if (_currentStroke != null) {
                      setState(() {
                        _currentStroke!.points.add(details.localPosition);
                      });
                    }
                  },
                  onPanEnd: (details) {
                    if (_currentStroke != null) {
                      setState(() {
                        _strokes.add(_currentStroke!);
                        _currentStroke = null;
                        _undoneStrokes.clear();
                      });
                    }
                  },
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

          // Tool bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Eraser toggle
                        GestureDetector(
                          onTap: () => setState(() => _isEraser = !_isEraser),
                          child: Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isEraser
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                              border: Border.all(
                                color: _isEraser
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_fix_high,
                              size: 18,
                              color: _isEraser
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Colors
                        ..._colors.map((color) {
                          final isSelected =
                              !_isEraser && _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stroke width picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _strokeWidths.map((width) {
                      final isSelected = _strokeWidth == width;
                      return GestureDetector(
                        onTap: () => setState(() => _strokeWidth = width),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: width + 4,
                              height: width + 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isEraser ? Colors.grey : _selectedColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndReturn() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'drawing_${const Uuid().v4()}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydetme hatası: $e')));
      }
    }
  }
}

/// Represents a single stroke
class DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

/// Custom painter for drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
