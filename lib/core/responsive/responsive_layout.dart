import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Responsive layout helper
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200 && desktop != null) {
      return desktop!;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}

/// Screen size breakpoints
class Breakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Zoomable and pannable page view
class ZoomablePageView extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final bool enablePan;
  final bool enableZoom;

  const ZoomablePageView({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.enablePan = true,
    this.enableZoom = true,
  });

  @override
  State<ZoomablePageView> createState() => _ZoomablePageViewState();
}

class _ZoomablePageViewState extends State<ZoomablePageView> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        panEnabled: widget.enablePan,
        scaleEnabled: widget.enableZoom,
        onInteractionEnd: (details) {
          setState(() {
            _currentScale = _controller.value.getMaxScaleOnAxis();
          });
        },
        child: widget.child,
      ),
    );
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.0) {
      // Reset to normal
      _controller.value = Matrix4.identity();
      _currentScale = 1.0;
    } else {
      // Zoom to 2x
      final center = MediaQuery.of(context).size.center(Offset.zero);
      final matrix = Matrix4.identity()
        ..translateByVector3(vector.Vector3(center.dx, center.dy, 0.0))
        ..scaleByVector3(vector.Vector3(2.0, 2.0, 1.0))
        ..translateByVector3(vector.Vector3(-center.dx, -center.dy, 0.0));
      _controller.value = matrix;
      _currentScale = 2.0;
    }
    setState(() {});
  }
}

/// Two-page spread view for landscape tablet mode
class TwoPageSpread extends StatelessWidget {
  final Widget leftPage;
  final Widget rightPage;
  final double gutter;

  const TwoPageSpread({
    super.key,
    required this.leftPage,
    required this.rightPage,
    this.gutter = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: leftPage),
        SizedBox(width: gutter),
        Expanded(child: rightPage),
      ],
    );
  }
}

/// Book view widget for tablet landscape
class BookView extends StatefulWidget {
  final List<Widget> pages;
  final int initialSpread;
  final void Function(int)? onSpreadChanged;

  const BookView({
    super.key,
    required this.pages,
    this.initialSpread = 0,
    this.onSpreadChanged,
  });

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  late PageController _controller;
  int _currentSpread = 0;

  int get spreadCount => (widget.pages.length / 2).ceil();

  @override
  void initState() {
    super.initState();
    _currentSpread = widget.initialSpread;
    _controller = PageController(initialPage: _currentSpread);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: spreadCount,
            onPageChanged: (index) {
              setState(() => _currentSpread = index);
              widget.onSpreadChanged?.call(index);
            },
            itemBuilder: (context, spreadIndex) {
              final leftIndex = spreadIndex * 2;
              final rightIndex = leftIndex + 1;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: TwoPageSpread(
                  leftPage: leftIndex < widget.pages.length
                      ? widget.pages[leftIndex]
                      : _emptyPage(),
                  rightPage: rightIndex < widget.pages.length
                      ? widget.pages[rightIndex]
                      : _emptyPage(),
                ),
              );
            },
          ),
        ),
        // Spread indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sayfa ${_currentSpread * 2 + 1}-${(_currentSpread * 2 + 2).clamp(1, widget.pages.length)} / ${widget.pages.length}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _emptyPage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Orientation-aware journal view
class AdaptiveJournalView extends StatelessWidget {
  final List<Widget> pages;
  final int currentPage;
  final void Function(int) onPageChanged;

  const AdaptiveJournalView({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveLayout.isLandscape(context);
    final isTablet =
        ResponsiveLayout.isTablet(context) ||
        ResponsiveLayout.isDesktop(context);

    if (isLandscape && isTablet) {
      // Two-page book view
      return BookView(
        pages: pages,
        initialSpread: currentPage ~/ 2,
        onSpreadChanged: (spread) => onPageChanged(spread * 2),
      );
    }

    // Single page view
    return PageView.builder(
      itemCount: pages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) => pages[index],
    );
  }
}
