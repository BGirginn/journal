import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';

/// Renders an image with various frame styles
class ImageFrameWidget extends StatelessWidget {
  final ImageProvider imageProvider;
  final String frameStyle;
  final double width;
  final double height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  const ImageFrameWidget({
    super.key,
    required this.imageProvider,
    required this.frameStyle,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);

    final image = Image(
      image: (cacheWidth != null || cacheHeight != null)
          ? ResizeImage(imageProvider, width: cacheWidth, height: cacheHeight)
          : imageProvider,
      fit: fit,
      width: width,
      height: height,
    );

    switch (frameStyle) {
      case ImageFrameStyles.polaroid:
        return _buildPolaroid(image, colorScheme);
      case ImageFrameStyles.tape:
        return _buildTape(image, colorScheme);
      case ImageFrameStyles.shadow:
        return _buildShadow(image, colorScheme);
      case ImageFrameStyles.simpleBorder:
        return _buildSimpleBorder(image, colorScheme);
      case ImageFrameStyles.circle:
        return _buildCircle(image, colorScheme);
      case ImageFrameStyles.rounded:
        return _buildRounded(image, colorScheme);
      case ImageFrameStyles.stacked:
        return _buildStacked(image, colorScheme, semantic);
      case ImageFrameStyles.film:
        return _buildFilm(image, colorScheme);
      case ImageFrameStyles.sticker:
        return _buildSticker(image, colorScheme);
      case ImageFrameStyles.gradient:
        return _buildGradient(image);
      case ImageFrameStyles.vintage:
        return _buildVintage(image);
      case ImageFrameStyles.layered:
        return _buildLayered(image);
      case ImageFrameStyles.tapeCorners:
        return _buildTapeCorners(image, colorScheme);
      case ImageFrameStyles.polaroidClassic:
        return _buildPolaroidClassic(image, colorScheme);
      case ImageFrameStyles.vintageEdge:
        return _buildVintageEdge(image, colorScheme);
      case ImageFrameStyles.none:
      default:
        return ClipRRect(borderRadius: BorderRadius.circular(4), child: image);
    }
  }

  Widget _buildPolaroid(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: image,
    );
  }

  Widget _buildTape(Widget image, ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 5,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: image,
        ),
        Positioned(
          top: -10,
          left: (width / 2) - 30,
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              width: 60,
              height: 25,
              decoration: BoxDecoration(
                color: BrandColors.warmAccent.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShadow(Widget image, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.26),
            blurRadius: 15,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: image),
    );
  }

  Widget _buildSimpleBorder(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: image,
    );
  }

  Widget _buildCircle(Widget image, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.surface, width: 4),
      ),
      child: ClipOval(child: image),
    );
  }

  Widget _buildRounded(Widget image, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: image),
    );
  }

  Widget _buildStacked(
    Widget image,
    ColorScheme colorScheme,
    JournalSemanticColors semantic,
  ) {
    return Stack(
      children: [
        Transform.rotate(
          angle: 0.05,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
          ),
        ),
        Transform.rotate(
          angle: -0.03,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: semantic.card),
          child: image,
        ),
      ],
    );
  }

  Widget _buildFilm(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: colorScheme.onSurface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilmHoles(colorScheme.surface),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: image,
          ),
          _buildFilmHoles(colorScheme.surface),
        ],
      ),
    );
  }

  Widget _buildFilmHoles(Color holeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        8,
        (_) => Container(
          width: 8,
          height: 12,
          decoration: BoxDecoration(
            color: holeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSticker(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.18),
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
          colors: [BrandColors.primary600, BrandColors.primary500, BrandColors.mutedRose],
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
        Color(0xFF704214),
        BlendMode.overlay,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6),
          border: Border.all(color: const Color(0xFF8D6E63), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8D6E63).withValues(alpha: 0.25),
              blurRadius: 6,
            ),
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
            color: BrandColors.primary600.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: Container(
            width: width,
            height: height,
            color: BrandColors.mutedRose.withValues(alpha: 0.16),
          ),
        ),
        image,
      ],
    );
  }

  Widget _buildTapeCorners(Widget image, ColorScheme colorScheme) {
    Widget tape(double angle) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: width * 0.18,
          height: height * 0.08,
          decoration: BoxDecoration(
            color: BrandColors.warmAccent.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: image,
        ),
        Positioned(top: -8, left: -6, child: tape(-0.18)),
        Positioned(top: -8, right: -6, child: tape(0.14)),
        Positioned(bottom: -8, left: -6, child: tape(0.12)),
        Positioned(bottom: -8, right: -6, child: tape(-0.16)),
      ],
    );
  }

  Widget _buildPolaroidClassic(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 34),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.8), width: 0.8),
        ),
        child: image,
      ),
    );
  }

  Widget _buildVintageEdge(Widget image, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4D2E), Color(0xFF4B3421)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0CDA5), width: 2),
        ),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.9,
            0.0,
            0.0,
            0.0,
            8.0,
            0.0,
            0.82,
            0.0,
            0.0,
            6.0,
            0.0,
            0.0,
            0.7,
            0.0,
            -8.0,
            0.0,
            0.0,
            0.0,
            1.0,
            0.0,
          ]),
          child: image,
        ),
      ),
    );
  }
}
