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
  final String tooltip;
  final bool isSelected;
  final bool isDanger;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final iconColor = isSelected
        ? Colors.white
        : isDanger
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : isDanger
                ? colorScheme.errorContainer.withValues(alpha: 0.4)
                : semantic.elevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(radius.medium),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isDanger
                  ? colorScheme.error.withValues(alpha: 0.3)
                  : semantic.divider,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 22),
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
