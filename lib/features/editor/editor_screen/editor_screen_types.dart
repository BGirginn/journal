part of '../editor_screen.dart';

class _EraserPreviewPainter extends CustomPainter {
  final Offset point;
  final double radius;
  final Color color;

  const _EraserPreviewPainter({
    required this.point,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerStroke = Paint()
      ..color = (color == Colors.white ? Colors.black : Colors.white)
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(point, radius, outerStroke);
    canvas.drawCircle(point, radius, fill);
    canvas.drawCircle(point, radius, stroke);
  }

  @override
  bool shouldRepaint(covariant _EraserPreviewPainter oldDelegate) {
    return oldDelegate.point != point ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

enum EditorMode { select, text, draw, erase }

enum _HandleType { topLeft, topRight, bottomLeft, bottomRight, rotate }

enum _ScaleTarget { none, page, block }

class _BlockScaleSnapshot {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const _BlockScaleSnapshot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
  });

  factory _BlockScaleSnapshot.fromBlock(Block block) {
    return _BlockScaleSnapshot(
      x: block.x,
      y: block.y,
      width: block.width,
      height: block.height,
      rotation: block.rotation,
    );
  }
}

class _InsertPlacement {
  final double x;
  final double y;
  final double width;
  final double height;

  const _InsertPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolBtn(this.icon, this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String currentValue;

  const _FrameOption(this.label, this.value, this.icon, this.currentValue);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: colorScheme.primary) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
