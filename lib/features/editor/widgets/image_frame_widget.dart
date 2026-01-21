import 'dart:io';

import 'package:flutter/material.dart';

/// Renders an image with various frame styles
class ImageFrameWidget extends StatelessWidget {
  final String path;
  final String frameStyle;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageFrameWidget({
    super.key,
    required this.path,
    required this.frameStyle,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!File(path).existsSync()) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    final image = Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
    );

    switch (frameStyle) {
      case 'polaroid':
        return _buildPolaroid(image);
      case 'tape':
        return _buildTape(image);
      case 'shadow':
        return _buildShadow(image);
      case 'simple_border':
        return _buildSimpleBorder(image);
      case 'none':
      default:
        return ClipRRect(borderRadius: BorderRadius.circular(4), child: image);
    }
  }

  Widget _buildPolaroid(Widget image) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: image,
    );
  }

  Widget _buildTape(Widget image) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 5,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: image,
        ),
        // Tape effect on top center
        Positioned(
          top: -10,
          left: (width / 2) - 30, // Approximate center
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              width: 60,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xAAFFE082), // Semi-transparent yellow tape
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShadow(Widget image) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 15,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: image),
    );
  }

  Widget _buildSimpleBorder(Widget image) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4),
        ],
      ),
      child: image,
    );
  }
}
