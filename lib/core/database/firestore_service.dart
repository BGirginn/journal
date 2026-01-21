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

  String? get _userId => _authService.currentUser?.uid;

  // --- Journals ---

  Future<void> createJournal(Journal journal) async {
    final uid = _userId;
    if (uid == null) return; // Silent return or throw?

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journal.id)
        .set(_journalToMap(journal));
  }

  Future<void> updateJournal(Journal journal) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journal.id)
        .update(_journalToMap(journal));
  }

  Future<void> deleteJournal(String journalId) async {
    final uid = _userId;
    if (uid == null) return;

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
    if (uid == null) return;

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
    if (uid == null) return;

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
    if (uid == null) return;

    // We need to fetch the journalId for the block, which is tricky as Block only knows PageId.
    // Ideally, we pass journalId or we have a flat blocks collection (sub-optimal).
    // Better strategy: Store blocks in a top-level collection `users/{uid}/blocks`
    // OR fetch the page first to get journalId.
    // For performance, let's assume we can query efficiently or pass context.
    // For now, let's put blocks under pages: `.../pages/{pageId}/blocks/{blockId}`.
    // But we need journalId to construct the path.
    // Workaround: We will use a top-level collection group query OR change schema.
    // Simplified Schema for MVP: `users/{uid}/pages/{pageId}/blocks`.
    // BUT we stuck to the hierarchy in the plan.
    // Let's modify the plan: Blocks will be subcollection of Pages.
    // We need `journalId` to traverse.
    // Option: `users/{uid}/blocks` with `pageId` field. Easier for writes.

    await _firestore.collection('users').doc(uid).set(_blockToMap(block));
  }

  Future<void> deleteBlock(String blockId) async {
    final uid = _userId;
    if (uid == null) return;

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
      'type': block.type.name, // Enum to string
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
