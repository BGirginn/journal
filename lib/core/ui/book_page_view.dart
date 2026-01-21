import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that simulates a realistic book page turn effect
class BookPageView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;
  final int initialPage;

  const BookPageView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.initialPage = 0,
  });

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView>
    with TickerProviderStateMixin {
  late int _currentPage;
  double _dragOffset = 0.0;
  AnimationController? _settleAnimation;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    _settleAnimation?.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_settleAnimation?.isAnimating == true) return;

    setState(() {
      // Normalize drag by width
      double delta = details.primaryDelta! / maxWidth;
      _dragOffset += delta;

      // Limit drag to reasonable bounds
      // Can't drag left if on first page
      if (_currentPage == 0 && _dragOffset > 0) _dragOffset = 0;
      // Can't drag right if on last page
      if (_currentPage == widget.itemCount - 1 && _dragOffset < 0) {
        _dragOffset = 0;
      }

      // Clamp to -1 (full next) to 1 (full prev)
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_settleAnimation?.isAnimating == true) return;

    final velocity = details.primaryVelocity ?? 0;
    double target = 0.0;

    // Determine snap target
    if (_dragOffset < -0.3 || velocity < -500) {
      target = -1.0; // Next page
    } else if (_dragOffset > 0.3 || velocity > 500) {
      target = 1.0; // Previous page
    } else {
      target = 0.0; // Revert
    }

    // Bounds check
    if (_currentPage == 0 && target > 0) target = 0.0;
    if (_currentPage == widget.itemCount - 1 && target < 0) target = 0.0;

    _settleAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _dragOffset,
    );

    _settleAnimation!.addListener(() {
      setState(() {
        _dragOffset = _settleAnimation!.value;
      });
    });

    _settleAnimation!.animateTo(target, curve: Curves.easeOutQuad).then((_) {
      if (target.abs() == 1.0) {
        setState(() {
          if (target < 0) {
            _currentPage++;
          } else {
            _currentPage--;
          }
          _dragOffset = 0.0;
        });
        widget.onPageChanged?.call(_currentPage);
      }
      _settleAnimation?.dispose();
      _settleAnimation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (d) =>
              _handleDragUpdate(d, constraints.maxWidth),
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            children: [
              // Bottom layer (Next or Previous page)
              if (_dragOffset < 0 && _currentPage < widget.itemCount - 1)
                Positioned.fill(
                  child: widget.itemBuilder(context, _currentPage + 1),
                ),
              if (_dragOffset > 0 && _currentPage > 0)
                Positioned.fill(
                  child: widget.itemBuilder(context, _currentPage - 1),
                ),

              // Top layer (Current page being flipped)
              if (_dragOffset == 0)
                Positioned.fill(
                  child: widget.itemBuilder(context, _currentPage),
                )
              else
                _buildFlippingPage(constraints),

              // Static current page (if dragging right/prev, we need the "destination" page to be static and current one to flip away?
              // Actually logic:
              // Drag Left (<0): Current Page peels off to reveal Next Page.
              // Drag Right (>0): Previous Page peels ONTO Current Page.
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlippingPage(BoxConstraints constraints) {
    // If dragging LEFT (<0): flipping CURRENT page to reveal NEXT.
    // Origin: Left edge. Angle: 0 to -180.
    if (_dragOffset < 0) {
      final percent = _dragOffset.abs();
      // Rotation: 0 to -pi
      // But for a realistic curl, we might just rotate Y.
      // 0 -> 0 deg, -1 -> -100 deg (partial) then snap?
      // Let's do full 100 deg rotation visually.
      final angle =
          _dragOffset * pi * 0.6; // Not full flip, just enough to clear

      return Stack(
        children: [
          // The page content
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            alignment: Alignment.centerLeft,
            child: widget.itemBuilder(context, _currentPage),
          ),

          // Shadow overlay
          // Opacity increases as we flip
          if (percent > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.3 * percent),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    // If dragging RIGHT (>0): Previous page flips ONTO current page.
    // Origin: Left edge. Angle: starts at -100 deg (mostly open) to 0.
    else {
      final percent = 1.0 - _dragOffset; // 1.0 at start, 0.0 at end
      final angle = -percent * pi * 0.6;

      return Stack(
        children: [
          // Bottom page is Current Page (static) - already rendered in Stack [0] if we adjusted logic?
          // Wait, logic above:
          // if drag > 0: Bottom layer is PREVIOUS (index - 1).
          // NO. If drag > 0 (back), Bottom is CURRENT (index). Top is PREV (index-1) coming in.

          // Fix stack logic:
          // If drag > 0:
          //    Bottom: Current Page (_currentPage)
          //    Top: Previous Page (_currentPage - 1) rotating in.

          // In main build:
          // if (_dragOffset > 0) Positioned.fill(child: widget.itemBuilder(context, _currentPage)), --> Bottom

          // Here:
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.centerLeft,
            child: widget.itemBuilder(context, _currentPage - 1),
          ),
        ],
      );
    }
  }
}
