import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return StorageService(authService);
});

class StorageService {
  final AuthService _authService;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  StorageService(this._authService);

  String? get _userId => _authService.currentUser?.uid;

  /// Uploads a file to Firebase Storage and returns the full storage path
  /// (e.g., "users/123/uploads/image.jpg")
  Future<String?> uploadFile(File file, {String? customPath}) async {
    final uid = _userId;
    if (uid == null) return null;

    final fileName =
        customPath ??
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storagePath = 'users/$uid/uploads/$fileName';
    final ref = _storage.ref().child(storagePath);

    try {
      await ref.putFile(file);
      return storagePath;
    } catch (e) {
      // Handle upload error (e.g. offline)
      // Since we want offline-first, these errors should ideally be queued.
      // For MVP, we return null and retry later logic would be needed.
      return null;
    }
  }

  /// Gets the download URL for a given storage path
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Delete a file
  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      // Ignore
    }
  }
}
