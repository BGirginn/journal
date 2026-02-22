import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/sync/hlc.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final oplogDao = ref.watch(oplogDaoProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return FirestoreService(authService, oplogDao.insertOplog, prefs);
});

class FirestoreService {
  final AuthService _authService;
  final Future<void> Function(OplogEntry) _insertOplog;
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  final String? Function()? _currentUidProvider;
  static const _deviceIdKey = 'sync_device_id';
  static const _lastHlcKey = 'sync_last_hlc';

  FirestoreService(
    this._authService,
    this._insertOplog,
    this._prefs, {
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUidProvider = currentUidProvider;

  String get _userId {
    final uid = _currentUidProvider?.call() ?? _authService.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(
        code: 'auth/unauthenticated',
        message: 'FirestoreService user is not authenticated.',
      );
    }
    return uid;
  }

  // --- Journals ---

  Future<void> createJournal(Journal journal) async {
    final uid = _userId;
    await _createOplog(
      journalId: journal.id,
      opType: OplogType.create,
      entityType: 'journal',
      payload: _journalSyncPayload(journal),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journal.id)
        .set(_journalToMap(journal));
  }

  Future<void> updateJournal(Journal journal) async {
    final uid = _userId;
    await _createOplog(
      journalId: journal.id,
      opType: OplogType.update,
      entityType: 'journal',
      payload: _journalSyncPayload(journal),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journal.id)
        .update(_journalToMap(journal));
  }

  Future<void> deleteJournal(String journalId) async {
    final uid = _userId;
    await _createOplog(
      journalId: journalId,
      opType: OplogType.delete,
      entityType: 'journal',
      payload: {'id': journalId},
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journalId)
        .delete();
  }

  // --- Pages ---

  Future<void> createPage(Page page) async {
    final uid = _userId;
    await _createOplog(
      journalId: page.journalId,
      pageId: page.id,
      opType: OplogType.create,
      entityType: 'page',
      payload: _pageSyncPayload(page),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(page.journalId)
        .collection(FirestorePaths.pages)
        .doc(page.id)
        .set(_pageToMap(page));
  }

  Future<void> updatePage(Page page) async {
    final uid = _userId;
    await _createOplog(
      journalId: page.journalId,
      pageId: page.id,
      opType: OplogType.update,
      entityType: 'page',
      payload: _pageSyncPayload(page),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(page.journalId)
        .collection(FirestorePaths.pages)
        .doc(page.id)
        .update(_pageToMap(page));
  }

  // --- Blocks ---

  Future<void> createBlock(Block block, {String? journalId}) async {
    final uid = _userId;
    await _createOplog(
      journalId: journalId ?? 'unknown',
      pageId: block.pageId,
      blockId: block.id,
      opType: OplogType.create,
      entityType: 'block',
      payload: _blockSyncPayload(block),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(block.id)
        .set(_blockToMap(block));
  }

  Future<void> updateBlock(Block block, {String? journalId}) async {
    final uid = _userId;
    await _createOplog(
      journalId: journalId ?? 'unknown',
      pageId: block.pageId,
      blockId: block.id,
      opType: OplogType.update,
      entityType: 'block',
      payload: _blockSyncPayload(block),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(block.id)
        .set(_blockToMap(block), SetOptions(merge: true));
  }

  Future<void> deleteBlock(
    String blockId, {
    String? journalId,
    String? pageId,
  }) async {
    final uid = _userId;
    await _createOplog(
      journalId: journalId ?? 'unknown',
      pageId: pageId,
      blockId: blockId,
      opType: OplogType.delete,
      entityType: 'block',
      payload: {'id': blockId, 'pageId': pageId, 'journalId': journalId},
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(blockId)
        .delete();
  }

  // --- Helpers ---

  Future<OplogEntry> _createOplog({
    required String journalId,
    String? pageId,
    String? blockId,
    required OplogType opType,
    required String entityType,
    required Map<String, dynamic> payload,
  }) async {
    final uid = _userId;
    final entry = OplogEntry.create(
      journalId: journalId,
      pageId: pageId,
      blockId: blockId,
      opType: opType,
      hlc: _nextHlc(),
      deviceId: _deviceId,
      userId: uid,
      payloadJson: jsonEncode({
        'schemaVersion': 1,
        'entity': entityType,
        'operation': opType.name,
        'recordedAt': DateTime.now().toIso8601String(),
        'data': payload,
      }),
    );
    await _insertOplog(entry);
    return entry;
  }

  String get _deviceId {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    _prefs.setString(_deviceIdKey, created);
    return created;
  }

  Hlc _nextHlc() {
    final raw = _prefs.getString(_lastHlcKey);
    final current = Hlc.tryParse(raw) ?? Hlc.now(_deviceId);
    final next = current.send(DateTime.now().millisecondsSinceEpoch);
    _prefs.setString(_lastHlcKey, next.toString());
    return next;
  }

  Map<String, dynamic> _journalSyncPayload(Journal journal) {
    return {
      'id': journal.id,
      'title': journal.title,
      'coverStyle': journal.coverStyle,
      'teamId': journal.teamId,
      'ownerId': journal.ownerId,
      'schemaVersion': journal.schemaVersion,
      'createdAt': journal.createdAt.toIso8601String(),
      'updatedAt': journal.updatedAt.toIso8601String(),
      'deletedAt': journal.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _pageSyncPayload(Page page) {
    return {
      'id': page.id,
      'journalId': page.journalId,
      'pageIndex': page.pageIndex,
      'backgroundStyle': page.backgroundStyle,
      'thumbnailAssetId': page.thumbnailAssetId,
      'inkData': page.inkData,
      'schemaVersion': page.schemaVersion,
      'createdAt': page.createdAt.toIso8601String(),
      'updatedAt': page.updatedAt.toIso8601String(),
      'deletedAt': page.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _blockSyncPayload(Block block) {
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
      'state': block.state.name,
      'payloadJson': block.payloadJson,
      'schemaVersion': block.schemaVersion,
      'createdAt': block.createdAt.toIso8601String(),
      'updatedAt': block.updatedAt.toIso8601String(),
      'deletedAt': block.deletedAt?.toIso8601String(),
    };
  }

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
