import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/database/firestore_service.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'database_providers.dart';

import 'package:journal_app/core/auth/auth_service.dart';

/// Stream of all journals
final journalsProvider = StreamProvider<List<Journal>>((ref) {
  final dao = ref.watch(journalDaoProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;

  // If no user is logged in, show nothing or guest data?
  // User asked for journals to be private to users.
  // If userId is null (guest?), maybe showing empty or guest journals is fine.
  // But for now let's pass whatever we have.
  return dao.watchAllJournals(userId: userId);
});

/// Total non-deleted page count across all journals of the current user
final totalPageCountProvider = FutureProvider<int>((ref) async {
  final pageDao = ref.watch(pageDaoProvider);
  final journals = await ref.watch(journalsProvider.future);

  var total = 0;
  for (final journal in journals) {
    total += await pageDao.getPageCount(journal.id);
  }

  return total;
});

/// Stream of a single journal by ID
final journalProvider = StreamProvider.family<Journal?, String>((ref, id) {
  final dao = ref.watch(journalDaoProvider);
  return dao.watchById(id);
});

/// Create a new journal
final createJournalProvider = Provider((ref) {
  final dao = ref.read(journalDaoProvider);
  final pageDao = ref.read(pageDaoProvider);
  final authService = ref.read(authServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  return ({
    required String title,
    String coverStyle = 'default',
    String? teamId,
  }) async {
    final userId = authService.currentUser?.uid;
    final journal = Journal(
      title: title,
      coverStyle: coverStyle,
      teamId: teamId,
      ownerId: userId, // Set ownerId
    );
    await dao.insertJournal(journal);

    // Create first page automatically
    final firstPage = model.Page(journalId: journal.id, pageIndex: 0);
    await pageDao.insertPage(firstPage);

    // Sync to Firestore
    try {
      await firestoreService.createJournal(journal);
      await firestoreService.createPage(firstPage);
    } catch (e) {
      // Ignore cloud errors for offline-first resilience
    }

    return journal;
  };
});

/// Quick-entry flow: creates journal + first page + first text block.
final createQuickJournalEntryProvider = Provider((ref) {
  final journalDao = ref.read(journalDaoProvider);
  final pageDao = ref.read(pageDaoProvider);
  final blockDao = ref.read(blockDaoProvider);
  final authService = ref.read(authServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  return (String entryText) async {
    final normalizedText = entryText.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError('Entry text must not be empty.');
    }

    final now = DateTime.now();
    final title = () {
      try {
        return DateFormat('d MMMM y', 'tr_TR').format(now);
      } catch (_) {
        return DateFormat('d MMMM y').format(now);
      }
    }();
    final userId = authService.currentUser?.uid;

    final journal = Journal(
      title: title,
      coverStyle: 'default',
      ownerId: userId,
    );
    final firstPage = model.Page(journalId: journal.id, pageIndex: 0);
    final firstBlock = Block(
      pageId: firstPage.id,
      type: BlockType.text,
      x: 0.08,
      y: 0.08,
      width: 0.84,
      height: 0.74,
      zIndex: 0,
      payloadJson: TextBlockPayload(
        content: normalizedText,
        fontSize: 18,
        color: '#111827',
      ).toJsonString(),
    );

    await journalDao.insertJournal(journal);
    await pageDao.insertPage(firstPage);
    await blockDao.insertBlock(firstBlock);

    try {
      await firestoreService.createJournal(journal);
      await firestoreService.createPage(firstPage);
      await firestoreService.createBlock(firstBlock, journalId: journal.id);
    } catch (_) {
      // Keep local entry creation resilient when cloud sync is unavailable.
    }

    return journal.id;
  };
});

/// Delete a journal
final deleteJournalProvider = Provider((ref) {
  final dao = ref.read(journalDaoProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  return (String id) async {
    await dao.softDelete(id);
    try {
      await firestoreService.deleteJournal(id);
    } catch (e) {
      // Ignore errors
    }
  };
});

/// Update an existing journal
final updateJournalProvider = Provider((ref) {
  final dao = ref.read(journalDaoProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  return (Journal journal) async {
    await dao.updateJournal(journal);
    try {
      await firestoreService.updateJournal(journal);
    } catch (e) {
      // Offline-first: local update stays as source of truth
    }
  };
});

/// Stream of pages for a specific journal
final pagesProvider = StreamProvider.family<List<model.Page>, String>((
  ref,
  journalId,
) {
  final dao = ref.watch(pageDaoProvider);
  return dao.watchPagesForJournal(journalId);
});

/// Stream of blocks for a specific page
final blocksProvider = StreamProvider.family<List<Block>, String>((
  ref,
  pageId,
) {
  final dao = ref.watch(blockDaoProvider);
  return dao.watchBlocksForPage(pageId);
});

/// Caches decoded ink strokes to avoid repeated JSON decoding
final decodedInkProvider = Provider.family<List<InkStrokeData>, String>((
  ref,
  inkData,
) {
  if (inkData.isEmpty) return [];
  return InkStrokeData.decodeStrokes(inkData);
});

/// Create a new page in a journal
final createPageProvider = Provider((ref) {
  final pageDao = ref.read(pageDaoProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  return (String journalId) async {
    final maxIndex = await pageDao.getMaxPageIndex(journalId);
    final newPage = model.Page(journalId: journalId, pageIndex: maxIndex + 1);
    await pageDao.insertPage(newPage);
    try {
      await firestoreService.createPage(newPage);
    } catch (_) {
      // Offline-first: local page creation stays available.
    }
    return newPage;
  };
});
