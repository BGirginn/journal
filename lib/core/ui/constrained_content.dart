import 'package:flutter/material.dart';

/// Wrapper that constrains child content to a maximum width for tablet/landscape layouts.
/// Use on form-style screens for max 800px and on grid/list screens for max 1200px.
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Form-style constraint (e.g. profile, settings, dialogs).
  const ConstrainedContent.form({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  }) : maxWidth = 800;

  /// Grid/list-style constraint (e.g. journal library, friends list).
  const ConstrainedContent.grid({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  }) : maxWidth = 1200;

  /// Custom constraint.
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
