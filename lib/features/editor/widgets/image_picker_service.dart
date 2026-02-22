import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Image picker service for adding photos
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  String? lastErrorMessage;

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    lastErrorMessage = null;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      lastErrorMessage = _toUserMessage(e, source: 'Galeri');
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    lastErrorMessage = null;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      lastErrorMessage = _toUserMessage(e, source: 'Kamera');
      debugPrint('Error picking image from camera: $e');
    }
    return null;
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    lastErrorMessage = null;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      lastErrorMessage = _toUserMessage(e, source: 'Galeri');
      debugPrint('Error picking video from gallery: $e');
    }
    return null;
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    lastErrorMessage = null;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      lastErrorMessage = _toUserMessage(e, source: 'Kamera');
      debugPrint('Error picking video from camera: $e');
    }
    return null;
  }

  String _toUserMessage(Object error, {required String source}) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission') || code.contains('denied')) {
        return '$source izni reddedildi. Ayarlardan izin verip tekrar deneyin.';
      }
    }
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission') || raw.contains('denied')) {
      return '$source izni reddedildi. Ayarlardan izin verip tekrar deneyin.';
    }
    return '$source secimi basarisiz oldu. Lutfen tekrar deneyin.';
  }
}

/// Image source picker dialog
Future<File?> showImageSourcePicker(BuildContext context) async {
  final service = ImagePickerService();

  return showModalBottomSheet<File?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Resim Ekle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library, color: Colors.blue),
            ),
            title: const Text('Galeriden Seç'),
            subtitle: const Text('Mevcut fotoğraflardan birini seç'),
            onTap: () async {
              final file = await service.pickFromGallery();
              if (context.mounted &&
                  file == null &&
                  service.lastErrorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(service.lastErrorMessage!)),
                );
              }
              if (context.mounted) Navigator.pop(context, file);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.green),
            ),
            title: const Text('Fotoğraf Çek'),
            subtitle: const Text('Kamera ile yeni fotoğraf çek'),
            onTap: () async {
              final file = await service.pickFromCamera();
              if (context.mounted &&
                  file == null &&
                  service.lastErrorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(service.lastErrorMessage!)),
                );
              }
              if (context.mounted) Navigator.pop(context, file);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
