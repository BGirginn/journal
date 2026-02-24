part of '../editor_screen.dart';

extension _EditorActionsExtension on _EditorScreenState {
  Future<void> _handleStickerPicker() async {
    final sticker = await showStickerPicker(context);
    if (sticker != null) {
      _insertSticker(sticker);
    }
  }

  void _insertSticker(Sticker sticker) {
    if (!mounted) return;

    final id = const Uuid().v4();
    final placement = sticker.isCustom
        ? _computeInsertPlacement(baseWidth: 0.4, baseHeight: 0.4)
        : _computeInsertPlacement(baseWidth: 0.2, baseHeight: 0.1);
    Block block;

    if (sticker.isCustom) {
      // Custom sticker treated as Image Block
      block = Block(
        id: id,
        pageId: widget.page.id,
        type: BlockType.image,
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
        rotation: 0,
        zIndex: _blocks.length,
        payloadJson: ImageBlockPayload(path: sticker.asset).toJsonString(),
      );
    } else {
      // Built-in sticker (Emoji/Text) treated as Text Block
      // We center it roughly
      block = Block(
        id: id,
        pageId: widget.page.id,
        type: BlockType.text,
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
        rotation: 0,
        zIndex: _blocks.length,
        payloadJson: TextBlockPayload(
          content: sticker.asset,
          fontSize: 48, // Large font for stickers
          textAlign: 'center',
          color:
              '#${(sticker.color ?? Colors.black).toARGB32().toRadixString(16).padLeft(8, '0')}',
        ).toJsonString(),
      );
    }

    _applyState(() {
      _blocks.add(block);
      _isDirty = true;
    });

    _insertBlockWithSync(block);
  }

  void _showTagEditor() {
    final l10n = AppLocalizations.of(context)!;
    final currentTags = widget.page.tagList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.editorPageTags,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TagEditorWidget(
              tags: currentTags,
              onTagsChanged: (newTags) {
                final tagsStr = newTags.join(',');
                final pageDao = ref.read(pageDaoProvider);
                pageDao.updatePage(
                  widget.page.copyWith(
                    tags: tagsStr,
                    updatedAt: DateTime.now(),
                  ),
                );
                _applyState(() => _isDirty = true);
              },
            ),
            const SizedBox(height: 8),
            const TagSuggestions(
              suggestions: [
                'anı',
                'seyahat',
                'yemek',
                'spor',
                'müzik',
                'iş',
                'aile',
              ],
              selectedTags: [],
              onTagTapped: _noOp,
            ),
          ],
        ),
      ),
    );
  }

  static void _noOp(String tag) {}

  Future<void> _addVideoBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final service = ImagePickerService();
    // Show dialog to choose source for video
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(l10n.editorVideoFromGallery),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickVideoFromGallery();
                if (file != null) {
                  _insertVideoBlock(file);
                } else if (mounted && service.lastErrorMessage != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(service.lastErrorMessage!)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.editorVideoFromCamera),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickVideoFromCamera();
                if (file != null) {
                  _insertVideoBlock(file);
                } else if (mounted && service.lastErrorMessage != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(service.lastErrorMessage!)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertVideoBlock(File file) {
    if (!mounted) return;
    final placement = _computeInsertPlacement(baseWidth: 0.8, baseHeight: 0.3);

    // Create audio/video block
    // We reuse logic similar to Image but for Video
    final id = const Uuid().v4();
    final block = Block(
      id: id,
      pageId: widget.page.id,
      type: BlockType.video,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      rotation: 0,
      zIndex: _blocks.length,
      payloadJson: VideoBlockPayload(
        path: file.path,
        storagePath: null, // To be uploaded
      ).toJsonString(),
    );

    _applyState(() {
      _blocks.add(block);
      _isDirty = true;
    });

    _insertBlockWithSync(block);
  }

  void _addTextBlock() async {
    final pageLooksDark =
        _theme.visuals.assetPath != null ||
        _theme.visuals.pageColor.computeLuminance() < 0.35;
    final initialPayload = TextBlockPayload(
      content: '',
      color: pageLooksDark ? '#FFFFFF' : '#111827',
    );
    final textPayload = await showDialog<TextBlockPayload>(
      context: context,
      builder: (context) => TextEditDialog(initialPayload: initialPayload),
    );
    if (!mounted || textPayload == null) {
      return;
    }

    final normalizedContent = textPayload.content.trim();
    if (normalizedContent.isEmpty) {
      return;
    }

    final placement = _computeInsertPlacement(baseWidth: 0.4, baseHeight: 0.08);
    final block = Block(
      pageId: widget.page.id,
      type: BlockType.text,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      zIndex: _blocks.length,
      payloadJson: TextBlockPayload(
        content: normalizedContent,
        fontSize: textPayload.fontSize,
        color: textPayload.color,
        fontFamily: textPayload.fontFamily,
        textAlign: textPayload.textAlign,
      ).toJsonString(),
    );

    await _insertBlockWithSync(block);
    _applyState(() => _isDirty = true);
  }

  void _addImage() async {
    final file = await showImageSourcePicker(context);
    if (file == null) return;
    final placement = _computeInsertPlacement(
      baseWidth: 0.35,
      baseHeight: 0.25,
    );

    final block = Block(
      pageId: widget.page.id,
      type: BlockType.image,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      zIndex: _blocks.length,
      payloadJson: ImageBlockPayload(
        assetId: null,
        path: file.path,
      ).toJsonString(),
    );

    await _insertBlockWithSync(block);

    // Upload to Firebase Storage & Sync Database
    _uploadAndSyncBlock(block, file);

    _applyState(() => _isDirty = true);
  }

  Future<void> _uploadAndSyncBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // 1. Upload File
      final storagePath = await storageService.uploadFile(file);

      if (storagePath != null) {
        // 2. Update Local Block with Storage Path
        final currentPayload = ImageBlockPayload.fromJson(block.payload);
        final newPayload = ImageBlockPayload(
          assetId: currentPayload.assetId,
          path: currentPayload.path,
          originalWidth: currentPayload.originalWidth,
          originalHeight: currentPayload.originalHeight,
          caption: currentPayload.caption,
          frameStyle: currentPayload.frameStyle,
          storagePath: storagePath,
        );

        // Update local DB
        await _updatePayloadWithSync(block.id, newPayload.toJsonString());

        // Update valid block reference for Firestore sync
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      // 3. Sync Block Metadata to Firestore
      await firestoreService.createBlock(
        block,
        journalId: widget.page.journalId,
      );
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'upload_image_block',
        error: e,
        stackTrace: st,
        extra: {'block_id': block.id},
      );
    }
  }

  Future<void> _uploadAndSyncAudioBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final storagePath = await storageService.uploadFile(file);

      if (storagePath != null) {
        final currentPayload = AudioBlockPayload.fromJson(block.payload);
        final newPayload = AudioBlockPayload(
          assetId: currentPayload.assetId,
          path: currentPayload.path,
          durationMs: currentPayload.durationMs,
          storagePath: storagePath,
        );

        await _updatePayloadWithSync(block.id, newPayload.toJsonString());
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      await firestoreService.createBlock(
        block,
        journalId: widget.page.journalId,
      );
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'upload_audio_block',
        error: e,
        stackTrace: st,
        extra: {'block_id': block.id},
      );
    }
  }

  void _recordAudio() async {
    final l10n = AppLocalizations.of(context)!;
    final service = AudioRecorderService();

    try {
      if (!await service.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editorMicPermissionRequired)),
          );
        }
        return;
      }

      await service.startRecording();

      if (!mounted) return;

      final path = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AudioRecordingDialog(recorder: service),
      );

      await service.dispose();

      if (path != null) {
        final placement = _computeInsertPlacement(
          baseWidth: 0.6,
          baseHeight: 0.1,
        );
        final block = Block(
          id: const Uuid().v4(),
          pageId: widget.page.id,
          type: BlockType.audio,
          x: placement.x,
          y: placement.y,
          width: placement.width,
          height: placement.height,
          zIndex: _blocks.length,
          payloadJson: AudioBlockPayload(
            path: path,
            durationMs: service.currentDuration.inMilliseconds,
          ).toJsonString(),
        );

        _applyState(() {
          _blocks.add(block);
          _isDirty = true;
        });

        _insertBlockWithSync(block);
        _uploadAndSyncAudioBlock(block, File(path));
      }
    } catch (e, st) {
      _reportSyncIssue(operation: 'record_audio', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editorRecordError(e.toString()))),
        );
      }
    }
  }

  void _showFramePicker() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedBlockId == null) return;

    final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
    final currentPayload = ImageBlockPayload.fromJson(block.payload);

    final style = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
          children: [
            Text(
              l10n.editorFrameSelect,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FrameOption(
                    l10n.editorFrameNone,
                    ImageFrameStyles.none,
                    Icons.crop_square,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameRound,
                    ImageFrameStyles.circle,
                    Icons.circle,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameRounded,
                    ImageFrameStyles.rounded,
                    Icons.rounded_corner,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFramePolaroid,
                    ImageFrameStyles.polaroid,
                    Icons.photo,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameTape,
                    ImageFrameStyles.tape,
                    Icons.horizontal_rule,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameShadow,
                    ImageFrameStyles.shadow,
                    Icons.layers,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameFilm,
                    ImageFrameStyles.film,
                    Icons.movie,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameStacked,
                    ImageFrameStyles.stacked,
                    Icons.filter_none,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameSticker,
                    ImageFrameStyles.sticker,
                    Icons.label,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameBorder,
                    ImageFrameStyles.simpleBorder,
                    Icons.crop_free,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameGradient,
                    ImageFrameStyles.gradient,
                    Icons.gradient,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameVintage,
                    ImageFrameStyles.vintage,
                    Icons.history,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameLayered,
                    ImageFrameStyles.layered,
                    Icons.layers_outlined,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameTapeCorner,
                    ImageFrameStyles.tapeCorners,
                    Icons.bookmark,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFramePolaroidClassic,
                    ImageFrameStyles.polaroidClassic,
                    Icons.photo_size_select_actual,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    l10n.editorFrameVintageEdge,
                    ImageFrameStyles.vintageEdge,
                    Icons.photo_filter,
                    currentPayload.frameStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (style != null) {
      final newPayload = ImageBlockPayload(
        assetId: currentPayload.assetId,
        path: currentPayload.path,
        originalWidth: currentPayload.originalWidth,
        originalHeight: currentPayload.originalHeight,
        caption: currentPayload.caption,
        frameStyle: style,
        storagePath: currentPayload.storagePath,
      );

      await _updatePayloadWithSync(
        _selectedBlockId!,
        newPayload.toJsonString(),
      );

      _applyState(() => _isDirty = true);
    }
  }

  void _deleteSelectedBlock() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedBlockId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editorDeleteBlockTitle),
        content: Text(l10n.editorDeleteBlockMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.editorDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(blockDaoProvider).softDelete(_selectedBlockId!);

      // Sync deletion to Firestore
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteBlock(
          _selectedBlockId!,
          journalId: widget.page.journalId,
          pageId: widget.page.id,
        );
      } catch (e, st) {
        _reportSyncIssue(
          operation: 'delete_block',
          error: e,
          stackTrace: st,
          extra: {'block_id': _selectedBlockId},
        );
      }

      _applyState(() {
        _blocks.removeWhere((b) => b.id == _selectedBlockId);
        _selectedBlockId = null;
        _isDirty = true;
      });
    }
  }

  void _showRotateDialog() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedBlockId == null) return;

    final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
    double newRotation = block.rotation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.editorRotateImageTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.editorCurrentAngle(newRotation.toInt())),
                const SizedBox(height: 16),
                // Preview
                Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: newRotation * pi / 180,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _buildBlockContent(block, const Size(150, 150)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quick actions
                Wrap(
                  spacing: 8,
                  children: [0, 90, 180, 270].map((angle) {
                    return ElevatedButton(
                      onPressed: () {
                        setDialogState(() => newRotation = angle.toDouble());
                      },
                      child: Text('$angle°'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Slider
                Slider(
                  value: newRotation,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  label: '${newRotation.toInt()}°',
                  onChanged: (value) {
                    setDialogState(() => newRotation = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  _rotateImageBlock(newRotation);
                  Navigator.pop(context);
                },
                child: Text(l10n.editorApply),
              ),
            ],
          );
        },
      ),
    );
  }

  void _rotateImageBlock(double angle) {
    if (_selectedBlockId == null) return;

    final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (index == -1) return;

    _applyState(() {
      _blocks[index] = _blocks[index].copyWith(rotation: angle);
      _isDirty = true;
    });

    _updateBlockWithSync(_blocks[index]);
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editorUnsavedTitle),
        content: Text(l10n.editorUnsavedMessage),
        actions: [
          // Exit without saving
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.editorExitWithoutSave),
          ),
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          // Save and Exit
          FilledButton(
            onPressed: () async {
              await _save();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(l10n.editorSaveAndExit),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
