import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';
import 'package:journal_app/providers/journal_providers.dart';

/// A card that displays a live preview of the journal's first page
class JournalPreviewCard extends ConsumerWidget {
  final Journal journal;
  final NotebookTheme theme; // Keeping this for cover fallback or borders
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.14),
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
                color: colorScheme.surfaceContainer,
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
          return _buildCoverFallback(context);
        }

        final firstPage = pages.first;
        final blocksAsync = ref.watch(blocksProvider(firstPage.id));

        return blocksAsync.when(
          data: (blocks) => _buildLivePreview(context, ref, firstPage, blocks),
          loading: () => _buildCoverFallback(context, isLoading: true),
          error: (_, _) => _buildCoverFallback(context),
        );
      },
      loading: () => _buildCoverFallback(context, isLoading: true),
      error: (_, _) => _buildCoverFallback(context),
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
    final sortedBlocks = List<Block>.from(blocks)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

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

              // Blocks
              RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: sortedBlocks.map((block) {
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

              // Ink Strokes should stay above blocks so annotations remain visible.
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

              // Transparent overlay
              if (isDark)
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.12),
                ),

              // Touch interceptor
              Container(color: Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback(BuildContext context, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.visuals.coverGradient,
        ),
        image: theme.visuals.assetPath != null
            ? DecorationImage(
                image: AssetImage(theme.visuals.assetPath!),
                fit: BoxFit.cover,
              )
            : null,
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
            : theme.visuals.assetPath == null
            ? Text(
                journal.title.isNotEmpty
                    ? journal.title.substring(0, 1).toUpperCase()
                    : '',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withAlpha(200),
                ),
              )
            : null,
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
