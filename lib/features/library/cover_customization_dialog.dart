import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/l10n/app_localizations.dart';

/// Dialog for customizing journal cover with themes or custom photo
class CoverCustomizationDialog extends ConsumerStatefulWidget {
  final String currentCoverStyle;
  final String? currentCoverImageUrl;

  const CoverCustomizationDialog({
    super.key,
    required this.currentCoverStyle,
    this.currentCoverImageUrl,
  });

  @override
  ConsumerState<CoverCustomizationDialog> createState() =>
      _CoverCustomizationDialogState();
}

class _CoverCustomizationDialogState
    extends ConsumerState<CoverCustomizationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedThemeId;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  File? _selectedImage;

  Color _coverTextColor(NotebookTheme theme) {
    final sample = theme.visuals.coverGradient.reduce(
      (a, b) => Color.lerp(a, b, 0.5)!,
    );
    return ThemeData.estimateBrightnessForColor(sample) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedThemeId = widget.currentCoverStyle;
    _uploadedImageUrl = widget.currentCoverImageUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Giriş yapılmamış');

      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/covers/$fileName',
      );

      await storageRef.putFile(_selectedImage!);
      final url = await storageRef.getDownloadURL();

      setState(() {
        _uploadedImageUrl = url;
        _selectedThemeId = 'custom_image';
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.libraryUploadError(e.toString()) ?? 'Yükleme hatası: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final themes = NostalgicThemes.all;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n?.libraryCoverCustomizeTitle ?? 'Kapak Özelleştir',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Live preview
            Container(
              height: 140,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPreview(),
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n?.libraryThemeTab ?? 'Temalar'),
                Tab(text: l10n?.libraryPhotoTab ?? 'Fotoğraf'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Themes grid
                  GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: themes.length,
                    itemBuilder: (context, index) {
                      final theme = themes[index];
                      final isSelected = _selectedThemeId == theme.id;
                      final coverTextColor = _coverTextColor(theme);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedThemeId = theme.id;
                            _uploadedImageUrl = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: theme.visuals.coverGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            image: theme.visuals.assetPath != null
                                ? DecorationImage(
                                    image: AssetImage(theme.visuals.assetPath!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                theme.name,
                                style: TextStyle(
                                  color: coverTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x33000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: coverTextColor,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Photo upload
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_selectedImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _pickAndUploadImage,
                            icon: _isUploading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.photo_library),
                            label: Text(
                              _isUploading
                                  ? (l10n?.libraryUploading ?? 'Yukleniyor...')
                                  : (l10n?.librarySelectFromGallery ??
                                        'Galeriden Seç'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.libraryCustomCoverHint ??
                                'Özel kapak fotoğrafı yükleyin',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'coverStyle': _selectedThemeId,
                      'coverImageUrl': _uploadedImageUrl,
                    });
                  },
                  child: Text(l10n?.editorApply ?? 'Uygula'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_selectedThemeId == 'custom_image' && _selectedImage != null) {
      return Image.file(
        _selectedImage!,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (_uploadedImageUrl != null && _selectedThemeId == 'custom_image') {
      return Image.network(
        _uploadedImageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final theme = NostalgicThemes.getById(_selectedThemeId);
    final coverTextColor = _coverTextColor(theme);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.visuals.coverGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: theme.visuals.assetPath != null
            ? DecorationImage(
                image: AssetImage(theme.visuals.assetPath!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              theme.name,
              style: TextStyle(
                color: coverTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show cover customization dialog and return result
Future<Map<String, String?>?> showCoverCustomization(
  BuildContext context, {
  required String currentCoverStyle,
  String? currentCoverImageUrl,
}) {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (context) => CoverCustomizationDialog(
      currentCoverStyle: currentCoverStyle,
      currentCoverImageUrl: currentCoverImageUrl,
    ),
  );
}
