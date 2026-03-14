import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/daos/journal_dao.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/database/daos/page_dao.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/invite_dao.dart';
import 'package:journal_app/features/journal/journal_member_service.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:journal_app/core/models/invite.dart';

final inviteServiceProvider = Provider<InviteService>((ref) {
  final db = ref.watch(databaseProvider);
  final inviteDao = db.inviteDao;
  final journalDao = db.journalDao;
  final pageDao = db.pageDao;
  final authService = ref.read(authServiceProvider);
  final teamService = ref.read(teamServiceProvider);
  final journalMemberService = ref.read(journalMemberServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  final service = InviteService(
    inviteDao,
    authService,
    teamService,
    journalMemberService,
    logger,
    telemetry,
    journalDao: journalDao,
    pageDao: pageDao,
  );
  ref.listen(authStateProvider, (_, next) {
    service.onAuthStateChanged(next.value?.uid);
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});

final myPendingInvitesProvider = StreamProvider<List<Invite>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) {
    return Stream.value(const <Invite>[]);
  }
  return ref.watch(inviteServiceProvider).watchMyInvites();
});

class InviteService {
  final InviteDao _inviteDao;
  final AuthService _authService;
  final TeamService _teamService;
  final JournalMemberService _journalMemberService;
  final JournalDao? _journalDao;
  final PageDao? _pageDao;
  final AppLogger _logger;
  final TelemetryService _telemetry;
  final FirebaseFirestore _firestore;
  final String? Function()? _currentUidProvider;

  StreamSubscription? _invitesSubscription;
  String? _activeUid;

  InviteService(
    this._inviteDao,
    this._authService,
    this._teamService,
    this._journalMemberService,
    this._logger,
    this._telemetry, {
    JournalDao? journalDao,
    PageDao? pageDao,
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _journalDao = journalDao,
       _pageDao = pageDao,
       _currentUidProvider = currentUidProvider;

  String? get _currentUid =>
      _currentUidProvider?.call() ?? _authService.currentUser?.uid;

  void _reportInviteIssue({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typed = SyncError(
      code: 'invite_$operation',
      message: 'Invite service operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    _logger.warn(
      'invite_service_issue',
      data: {'operation': operation, ...extra},
      error: typed,
      stackTrace: stackTrace,
    );
    _telemetry.track(
      'invite_service_issue',
      params: {'operation': operation, 'error_code': typed.code, ...extra},
    );
  }

  void onAuthStateChanged(String? uid) {
    if (_activeUid == uid) return;
    _activeUid = uid;
    _stopSync();
    if (uid == null) return;
    _invitesSubscription?.cancel();
    _invitesSubscription = _firestore
        .collection(FirestorePaths.invites)
        .where('inviteeId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) async {
            for (var doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added ||
                  doc.type == DocumentChangeType.modified) {
                final invite = Invite.fromJson(doc.doc.data()!);
                await _inviteDao.insertInvite(invite);
              } else if (doc.type == DocumentChangeType.removed) {
                // Soft delete or hard delete?
                await _inviteDao.deleteInvite(doc.doc.id);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportInviteIssue(
              operation: 'listen_pending_invites',
              error: error,
              stackTrace: stackTrace,
              extra: {'uid': uid},
            );
          },
        );
  }

  void _stopSync() {
    _invitesSubscription?.cancel();
    _invitesSubscription = null;
  }

  Stream<List<Invite>> watchMyInvites() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);
    return _inviteDao.watchMyInvites(uid);
  }

  Future<Invite?> fetchInviteById(String inviteId) async {
    final doc = await _firestore
        .collection(FirestorePaths.invites)
        .doc(inviteId)
        .get();
    if (!doc.exists) {
      return null;
    }
    return Invite.fromJson(doc.data()!);
  }

  Future<Invite> createInvite({
    required InviteType type,
    required String targetId,
    String? inviteeId, // Null for public link
    required JournalRole role,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not logged in');
    final normalizedInviteeId = _cleanOptionalText(inviteeId);

    await _validateInviteCanBeCreated(
      type: type,
      targetId: targetId,
      inviterUid: uid,
      inviteeId: normalizedInviteeId,
    );

    final metadata = type == InviteType.journal
        ? await _resolveJournalInviteMetadata(targetId)
        : (title: null, coverStyle: null);

    final invite = Invite(
      type: type,
      targetId: targetId,
      targetTitle: metadata.title,
      targetCoverStyle: metadata.coverStyle,
      inviterId: uid,
      inviteeId: normalizedInviteeId,
      role: role,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    // Save to Firestore (Local will sync via listener if invitee is me, otherwise no need to local save invite I SENT unless needed)
    // Actually, saving inviter's sent invites locally is good too.
    // But DAO watchMyInvites filters by inviteeId.

    await _firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .set(invite.toJson());

    return invite;
  }

  Future<void> acceptInvite(Invite invite) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not logged in');

    // Verify invite
    if (invite.status != InviteStatus.pending) {
      throw Exception('Invite not pending');
    }
    if (invite.expiresAt.isBefore(DateTime.now())) {
      throw Exception('Invite expired');
    }
    if (invite.inviteeId != null && invite.inviteeId != uid) {
      throw Exception('Invite not for you');
    }

    // Add to Team/Journal
    if (invite.type == InviteType.team) {
      await _teamService.addMember(
        teamId: invite.targetId,
        userId: uid,
        role: invite.role,
      );
    } else if (invite.type == InviteType.journal) {
      await _ensureJournalVisibleForInvitee(invite: invite, inviteeUid: uid);
      await _journalMemberService.addMember(
        journalId: invite.targetId,
        userId: uid,
        role: invite.role,
      );
    }

    // Update Invite Status
    // Use Firestore update
    await _firestore.collection(FirestorePaths.invites).doc(invite.id).update({
      'status': InviteStatus.accepted.name,
      'inviteeId': uid, // Set invitee if it was public
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Local DB will update via sync listener?
    // If status changes to accepted, my listener (where status==pending) might remove it?
    // Yes, listener filters 'pending'. So it will be removed/deleted from local pending list.
    // That's correct behavior for "My Pending Invites".
  }

  Future<void> rejectInvite(Invite invite) async {
    await _firestore.collection(FirestorePaths.invites).doc(invite.id).update({
      'status': InviteStatus.rejected.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  void dispose() {
    _stopSync();
  }

  Future<({String? title, String? coverStyle})> _resolveJournalInviteMetadata(
    String targetId,
  ) async {
    final localJournal = await _journalDao?.getById(targetId);
    if (localJournal != null) {
      return (
        title: _cleanOptionalText(localJournal.title),
        coverStyle: _cleanOptionalText(localJournal.coverStyle),
      );
    }

    final uid = _currentUid;
    if (uid == null) {
      return (title: null, coverStyle: null);
    }

    try {
      final journalDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc(targetId)
          .get();
      if (!journalDoc.exists) {
        return (title: null, coverStyle: null);
      }

      final map = journalDoc.data() ?? const <String, dynamic>{};
      return (
        title: _cleanOptionalText(map['title']?.toString()),
        coverStyle: _cleanOptionalText(map['coverStyle']?.toString()),
      );
    } catch (error, stackTrace) {
      _reportInviteIssue(
        operation: 'resolve_journal_invite_metadata',
        error: error,
        stackTrace: stackTrace,
        extra: {'target_id': targetId},
      );
      return (title: null, coverStyle: null);
    }
  }

  Future<void> _ensureJournalVisibleForInvitee({
    required Invite invite,
    required String inviteeUid,
  }) async {
    final now = DateTime.now();
    final title = _cleanOptionalText(invite.targetTitle) ?? 'Paylasilan Gunluk';
    final coverStyle = _cleanOptionalText(invite.targetCoverStyle) ?? 'default';

    final existingLocalJournal = await _journalDao?.getById(invite.targetId);
    final localJournal = Journal(
      id: invite.targetId,
      title: existingLocalJournal?.title ?? title,
      coverStyle: existingLocalJournal?.coverStyle ?? coverStyle,
      ownerId: inviteeUid,
      createdAt: existingLocalJournal?.createdAt ?? now,
      updatedAt: now,
    );
    await _journalDao?.insertJournal(localJournal);

    var localPage = await _pageDao?.getPageByJournalAndIndex(
      invite.targetId,
      0,
    );
    localPage ??= model.Page(journalId: invite.targetId, pageIndex: 0);
    await _pageDao?.insertPage(localPage);

    final userJournalRef = _firestore
        .collection(FirestorePaths.users)
        .doc(inviteeUid)
        .collection(FirestorePaths.journals)
        .doc(invite.targetId);

    await userJournalRef.set({
      'id': localJournal.id,
      'title': localJournal.title,
      'coverStyle': localJournal.coverStyle,
      'createdAt': Timestamp.fromDate(localJournal.createdAt),
      'updatedAt': Timestamp.fromDate(localJournal.updatedAt),
      'deletedAt': null,
    }, SetOptions(merge: true));

    await userJournalRef
        .collection(FirestorePaths.pages)
        .doc(localPage.id)
        .set({
          'id': localPage.id,
          'journalId': localPage.journalId,
          'pageIndex': localPage.pageIndex,
          'backgroundStyle': localPage.backgroundStyle,
          'thumbnailAssetId': localPage.thumbnailAssetId,
          'inkData': localPage.inkData,
          'createdAt': Timestamp.fromDate(localPage.createdAt),
          'updatedAt': Timestamp.fromDate(localPage.updatedAt),
        }, SetOptions(merge: true));
  }

  String? _cleanOptionalText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _validateInviteCanBeCreated({
    required InviteType type,
    required String targetId,
    required String inviterUid,
    required String? inviteeId,
  }) async {
    if (type == InviteType.team) {
      await _validateTeamInviteContext(
        targetId: targetId,
        inviterUid: inviterUid,
      );
      if (inviteeId == null) {
        throw Exception('Takım daveti için bir arkadaş seçmelisiniz.');
      }
    }

    if (inviteeId == null) {
      return;
    }
    if (inviteeId == inviterUid) {
      throw Exception('Kendinize davet gönderemezsiniz.');
    }

    final pendingForInvitee = await _firestore
        .collection(FirestorePaths.invites)
        .where('inviteeId', isEqualTo: inviteeId)
        .get();
    final hasPendingDuplicate = pendingForInvitee.docs.any((doc) {
      final map = doc.data();
      final sameType = map['type']?.toString() == type.name;
      final sameTarget = map['targetId']?.toString() == targetId;
      final isPending = map['status']?.toString() == InviteStatus.pending.name;
      return sameType &&
          sameTarget &&
          isPending &&
          _isDocActive(map['deletedAt']);
    });
    if (hasPendingDuplicate) {
      throw Exception('Bu kullanıcıya zaten bekleyen bir davet gönderildi.');
    }

    if (type == InviteType.team) {
      final memberships = await _firestore
          .collection(FirestorePaths.teamMembers)
          .where('userId', isEqualTo: inviteeId)
          .get();
      final isAlreadyMember = memberships.docs.any((doc) {
        final map = doc.data();
        return map['teamId']?.toString() == targetId &&
            _isDocActive(map['deletedAt']);
      });
      if (isAlreadyMember) {
        throw Exception('Bu kullanıcı zaten takım üyesi.');
      }
    }

    if (type == InviteType.journal) {
      final collaborators = await _firestore
          .collection(FirestorePaths.journalMembers)
          .where('userId', isEqualTo: inviteeId)
          .get();
      final isAlreadyCollaborator = collaborators.docs.any((doc) {
        final map = doc.data();
        return map['journalId']?.toString() == targetId &&
            _isDocActive(map['deletedAt']);
      });
      if (isAlreadyCollaborator) {
        throw Exception('Bu kullanıcı zaten günlüğün katılımcısı.');
      }
    }
  }

  bool _isDocActive(Object? deletedAt) {
    if (deletedAt == null) {
      return true;
    }
    if (deletedAt is String) {
      return deletedAt.trim().isEmpty;
    }
    return false;
  }

  Future<void> _validateTeamInviteContext({
    required String targetId,
    required String inviterUid,
  }) async {
    final teamDoc = await _firestore
        .collection(FirestorePaths.teams)
        .doc(targetId)
        .get();
    if (!teamDoc.exists) {
      throw Exception('Takım bulunamadı.');
    }
    final teamData = teamDoc.data() ?? const <String, dynamic>{};
    if (!_isDocActive(teamData['deletedAt'])) {
      throw Exception('Bu takım artık aktif değil.');
    }

    final ownerId = _cleanOptionalText(teamData['ownerId']?.toString());
    if (ownerId == null) {
      throw Exception('Takım bilgisi eksik.');
    }
    if (ownerId == inviterUid) {
      return;
    }

    final memberships = await _firestore
        .collection(FirestorePaths.teamMembers)
        .where('userId', isEqualTo: inviterUid)
        .get();
    final isInviterActiveMember = memberships.docs.any((doc) {
      final data = doc.data();
      return data['teamId']?.toString() == targetId &&
          _isDocActive(data['deletedAt']);
    });
    if (!isInviterActiveMember) {
      throw Exception('Bu takım için davet gönderme yetkiniz yok.');
    }
  }
}
