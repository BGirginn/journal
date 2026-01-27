import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/journal_theme.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';
import 'package:journal_app/providers/journal_providers.dart';

/// A card that displays a live preview of the journal's first page
class JournalPreviewCard extends ConsumerWidget {
  final Journal journal;
  final JournalTheme theme; // Keeping this for cover fallback or borders
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const JournalPreviewCard({
    super.key,
    required this.journal,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area (Replaces the gradient cover)
              Expanded(flex: 7, child: _buildPreviewArea(context, ref)),

              // Title Area
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      journal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(journal.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPreviewArea(BuildContext context, WidgetRef ref) {
    // Watch pages for this journal
    final pagesAsync = ref.watch(pagesProvider(journal.id));

    return pagesAsync.when(
      data: (pages) {
        if (pages.isEmpty) {
          return _buildCoverFallback();
        }

        final firstPage = pages.first;
        final blocksAsync = ref.watch(blocksProvider(firstPage.id));

        return blocksAsync.when(
          data: (blocks) => _buildLivePreview(context, ref, firstPage, blocks),
          loading: () => _buildCoverFallback(isLoading: true),
          error: (_, _) => _buildCoverFallback(),
        );
      },
      loading: () => _buildCoverFallback(isLoading: true),
      error: (_, _) => _buildCoverFallback(),
    );
  }

  Widget _buildLivePreview(
    BuildContext context,
    WidgetRef ref,
    dynamic page,
    List<Block> blocks,
  ) {
    // Use the journal's theme for the page background
    final notebookTheme = NostalgicThemes.getById(journal.coverStyle);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use cached decoded ink strokes for better performance
    final strokes = ref.watch(decodedInkProvider(page.inkData as String));

    // Reference size for scaling (average mobile screen)
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
            clipBehavior: Clip.none,
            children: [
              // Page Background
              RepaintBoundary(
                child: CustomPaint(
                  painter: NostalgicPagePainter(theme: notebookTheme),
                  size: Size.infinite,
                ),
              ),

              // Ink Strokes
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

              // Blocks
              RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: blocks.map((block) {
                    return BlockWidget(
                      block: block,
                      pageSize: referenceSize,
                      isSelected: false,
                      onDoubleTap: null,
                      cacheWidth: 300, // Optimize memory for grid previews
                    );
                  }).toList(),
                ),
              ),

              // Transparent overlay
              if (isDark) Container(color: Colors.black.withValues(alpha: 0.1)),

              // Touch interceptor
              Container(color: Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.coverGradient,
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                theme.coverIcon,
                size: 48,
                color: Colors.white.withValues(alpha: 0.8), // Flutter 3 updated
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
