import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_elevation.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/providers/journal_providers.dart';

enum JournalCardVisualMode { coverFirst, livePreview }

/// Journal card with two visual modes:
/// - coverFirst (default): clean premium cover + metadata
/// - livePreview: legacy page preview mode used in secondary flows
class JournalPreviewCard extends ConsumerWidget {
  final Journal journal;
  final NotebookTheme theme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final JournalCardVisualMode visualMode;

  const JournalPreviewCard({
    super.key,
    required this.journal,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
    this.visualMode = JournalCardVisualMode.coverFirst,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final elevation =
        Theme.of(context).extension<JournalElevationScale>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalElevationScale.dark
            : JournalElevationScale.light);
    final pagesAsync = ref.watch(pagesProvider(journal.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: semantic.card,
          borderRadius: BorderRadius.circular(radius.large),
          border: Border.all(color: semantic.divider.withValues(alpha: 0.8)),
          boxShadow: elevation.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: visualMode == JournalCardVisualMode.livePreview
                    ? _buildLivePreviewArea(context, ref, pagesAsync)
                    : _buildCoverFirstArea(context),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                color: semantic.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      journal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: semantic.primaryStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(journal.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildPageBadge(context, pagesAsync),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFirstArea(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: theme.visuals.coverGradient,
    );

    Widget cover;
    if (journal.coverImageUrl != null && journal.coverImageUrl!.isNotEmpty) {
      cover = Image.network(
        journal.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildGradientCover(gradient),
      );
    } else if (theme.visuals.assetPath != null) {
      cover = Image.asset(theme.visuals.assetPath!, fit: BoxFit.cover);
    } else {
      cover = _buildGradientCover(gradient);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        cover,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: semantic.elevated.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              theme.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: semantic.primaryStrong,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientCover(Gradient gradient) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Text(
          journal.title.isNotEmpty ? journal.title.substring(0, 1).toUpperCase() : '',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewArea(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<model.Page>> pagesAsync,
  ) {
    return pagesAsync.when(
      data: (pages) {
        if (pages.isEmpty) {
          return _buildCoverFirstArea(context);
        }
        final firstPage = pages.first;
        final blocksAsync = ref.watch(blocksProvider(firstPage.id));
        return blocksAsync.when(
          data: (blocks) => _buildLivePreview(context, ref, firstPage, blocks),
          loading: () => _buildCoverFirstArea(context),
          error: (_, _) => _buildCoverFirstArea(context),
        );
      },
      loading: () => _buildCoverFirstArea(context),
      error: (_, _) => _buildCoverFirstArea(context),
    );
  }

  Widget _buildLivePreview(
    BuildContext context,
    WidgetRef ref,
    model.Page page,
    List<Block> blocks,
  ) {
    final notebookTheme = NostalgicThemes.getById(journal.coverStyle);
    final strokes = ref.watch(decodedInkProvider(page.inkData));
    final sortedBlocks = List<Block>.from(blocks)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    const referenceSize = Size(360, 640);

    return Container(
      color: notebookTheme.visuals.pageColor,
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: referenceSize.width,
          height: referenceSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: notebookTheme.visuals.assetPath != null
                    ? Image.asset(
                        notebookTheme.visuals.assetPath!,
                        fit: BoxFit.cover,
                      )
                    : CustomPaint(
                        painter: NostalgicPagePainter(theme: notebookTheme),
                        size: Size.infinite,
                      ),
              ),
              RepaintBoundary(
                child: Stack(
                  children: sortedBlocks
                      .map(
                        (block) => BlockWidget(
                          block: block,
                          pageSize: referenceSize,
                          isSelected: false,
                          onDoubleTap: null,
                          cacheWidth: 300,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (strokes.isNotEmpty)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: OptimizedInkPainter(
                      strokes: strokes,
                      currentStroke: null,
                    ),
                    size: Size.infinite,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageBadge(
    BuildContext context,
    AsyncValue<List<model.Page>> pagesAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = pagesAsync.valueOrNull?.length;
    final label = count == null ? '...' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 12, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
