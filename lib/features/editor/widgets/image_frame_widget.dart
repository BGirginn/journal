import 'package:flutter/material.dart';

/// Renders an image with various frame styles
class ImageFrameWidget extends StatelessWidget {
  final ImageProvider imageProvider;
  final String frameStyle;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageFrameWidget({
    super.key,
    required this.imageProvider,
    required this.frameStyle,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image(
      image: imageProvider,
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
      case 'circle':
        return _buildCircle(image);
      case 'rounded':
        return _buildRounded(image);
      case 'stacked':
        return _buildStacked(image);
      case 'film':
        return _buildFilm(image);
      case 'sticker':
        return _buildSticker(image);
      case 'gradient':
        return _buildGradient(image);
      case 'vintage':
        return _buildVintage(image);
      case 'layered':
        return _buildLayered(image);
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
          left: (width / 2) - 30,
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              width: 60,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xAAFFE082),
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
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4),
        ],
      ),
      child: image,
    );
  }

  Widget _buildCircle(Widget image) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: ClipOval(child: image),
    );
  }

  Widget _buildRounded(Widget image) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: image),
    );
  }

  Widget _buildStacked(Widget image) {
    return Stack(
      children: [
        Transform.rotate(
          angle: 0.05,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
        ),
        Transform.rotate(
          angle: -0.03,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white),
          child: image,
        ),
      ],
    );
  }

  Widget _buildFilm(Widget image) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2), // Film holes spacing
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top holes
          _buildFilmHoles(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: image,
          ),
          // Bottom holes
          _buildFilmHoles(),
        ],
      ),
    );
  }

  Widget _buildFilmHoles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        8,
        (index) => Container(
          width: 8,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSticker(Widget image) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
    );
  }

  Widget _buildGradient(Widget image) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: image),
    );
  }

  Widget _buildVintage(Widget image) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFF704214), // Sepia tone
        BlendMode.overlay,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6), // Old lace
          border: Border.all(color: Colors.brown, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.brown.withAlpha(40), blurRadius: 6),
          ],
        ),
        child: image,
      ),
    );
  }

  Widget _buildLayered(Widget image) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            width: width,
            height: height,
            color: Colors.blue.withOpacity(0.2),
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: Container(
            width: width,
            height: height,
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        image,
      ],
    );
  }
}
