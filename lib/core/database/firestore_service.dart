import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/models/block.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirestoreService(authService);
});

class FirestoreService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(this._authService);

  String get _userId {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      throw StateError('FirestoreService: User is not authenticated');
    }
    return uid;
  }

  // --- Journals ---

  Future<void> createJournal(Journal journal) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journal.id)
        .set(_journalToMap(journal));
  }

  Future<void> updateJournal(Journal journal) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journal.id)
        .update(_journalToMap(journal));
  }

  Future<void> deleteJournal(String journalId) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journalId)
        .delete();
  }

  // --- Pages ---

  Future<void> createPage(Page page) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(page.journalId)
        .collection('pages')
        .doc(page.id)
        .set(_pageToMap(page));
  }

  Future<void> updatePage(Page page) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(page.journalId)
        .collection('pages')
        .doc(page.id)
        .update(_pageToMap(page));
  }

  // --- Blocks ---

  Future<void> createBlock(Block block) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .doc(block.id)
        .set(_blockToMap(block));
  }

  Future<void> deleteBlock(String blockId) async {
    final uid = _userId;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .doc(blockId)
        .delete();
  }

  // --- Helpers ---

  Map<String, dynamic> _journalToMap(Journal journal) {
    return {
      'id': journal.id,
      'title': journal.title,
      'coverStyle': journal.coverStyle,
      'createdAt': Timestamp.fromDate(journal.createdAt),
      'updatedAt': Timestamp.fromDate(journal.updatedAt),
      'deletedAt': journal.deletedAt != null
          ? Timestamp.fromDate(journal.deletedAt!)
          : null,
    };
  }

  Map<String, dynamic> _pageToMap(Page page) {
    return {
      'id': page.id,
      'journalId': page.journalId,
      'pageIndex': page.pageIndex,
      'backgroundStyle': page.backgroundStyle,
      'thumbnailAssetId': page.thumbnailAssetId,
      'inkData': page.inkData,
      'createdAt': Timestamp.fromDate(page.createdAt),
      'updatedAt': Timestamp.fromDate(page.updatedAt),
    };
  }

  Map<String, dynamic> _blockToMap(Block block) {
    return {
      'id': block.id,
      'pageId': block.pageId,
      'type': block.type.name,
      'x': block.x,
      'y': block.y,
      'width': block.width,
      'height': block.height,
      'rotation': block.rotation,
      'zIndex': block.zIndex,
      'payloadJson': block.payloadJson,
      'createdAt': Timestamp.fromDate(block.createdAt),
      'updatedAt': Timestamp.fromDate(block.updatedAt),
    };
  }
}
