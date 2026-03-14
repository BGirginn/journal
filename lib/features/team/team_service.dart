import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/team_dao.dart';
import 'package:journal_app/core/models/team.dart' as model;
import 'package:journal_app/core/models/team_member.dart' as member_model;
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/database/daos/journal_dao.dart';
import 'package:journal_app/features/journal/journal_member_service.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  final teamDao = ref.watch(databaseProvider).teamDao;
  final journalDao = ref.watch(databaseProvider).journalDao;
  final authService = ref.read(authServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  final memberService = ref.watch(journalMemberServiceProvider);
  final service = TeamService(
    teamDao,
    authService,
    logger,
    telemetry,
    journalDao: journalDao,
    journalMemberService: memberService,
  );
  ref.listen(authStateProvider, (_, next) {
    service.onAuthStateChanged(next.value?.uid);
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});

class TeamService {
  final TeamDao _teamDao;
  final AuthService _authService;
  final AppLogger _logger;
  final TelemetryService _telemetry;
  final FirebaseFirestore _firestore;
  final String? Function()? _currentUidProvider;
  final JournalDao? _journalDao;
  final JournalMemberService? _journalMemberService;

  // Subscription cache to avoid multiple listeners
  StreamSubscription? _membersSubscription;
  final Map<String, StreamSubscription> _teamSyncSubscriptions = {};
  final Map<String, StreamSubscription> _memberSyncSubscriptions = {};
  String? _activeUid;

  TeamService(
    this._teamDao,
    this._authService,
    this._logger,
    this._telemetry, {
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
    JournalDao? journalDao,
    JournalMemberService? journalMemberService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUidProvider = currentUidProvider,
       _journalDao = journalDao,
       _journalMemberService = journalMemberService;

  String? get _currentUid =>
      _currentUidProvider?.call() ?? _authService.currentUser?.uid;

  void _reportTeamIssue({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typed = SyncError(
      code: 'team_$operation',
      message: 'Team service operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    _logger.warn(
      'team_service_issue',
      data: {'operation': operation, ...extra},
      error: typed,
      stackTrace: stackTrace,
    );
    _telemetry.track(
      'team_service_issue',
      params: {'operation': operation, 'error_code': typed.code, ...extra},
    );
  }

  void onAuthStateChanged(String? uid) {
    if (_activeUid == uid) return;
    _stopSync();
    _activeUid = uid;
    if (uid != null) {
      _startTeamSync(uid);
    }
  }

  void _stopSync() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
    for (final sub in _teamSyncSubscriptions.values) {
      sub.cancel();
    }
    _teamSyncSubscriptions.clear();
    for (final sub in _memberSyncSubscriptions.values) {
      sub.cancel();
    }
    _memberSyncSubscriptions.clear();
  }

  void _startTeamSync(String uid) {
    // 1. Listen to my memberships to know which teams to sync
    _membersSubscription?.cancel();
    _membersSubscription = _firestore
        .collection(FirestorePaths.teamMembers)
        .where('userId', isEqualTo: uid)
        .where('deletedAt', isNull: true)
        .snapshots()
        .listen(
          (snapshot) async {
            // For each membership, insert/update local
            for (var doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added ||
                  doc.type == DocumentChangeType.modified) {
                final member = member_model.TeamMember.fromJson(
                  doc.doc.data()!,
                );
                await _teamDao.insertMember(member);

                // Also fetch/sync the team itself
                _syncTeam(member.teamId);
                // And sync other members of this team
                _syncTeamMembers(member.teamId);
              } else if (doc.type == DocumentChangeType.removed) {
                final member = member_model.TeamMember.fromJson(
                  doc.doc.data()!,
                );
                await _teamDao.removeMember(member.teamId, member.userId);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportTeamIssue(
              operation: 'listen_memberships',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _syncTeam(String teamId) {
    if (_teamSyncSubscriptions.containsKey(teamId)) return;
    _teamSyncSubscriptions[teamId] = _firestore
        .collection(FirestorePaths.teams)
        .doc(teamId)
        .snapshots()
        .listen(
          (doc) async {
            if (doc.exists) {
              final team = model.Team.fromJson(doc.data()!);
              await _teamDao.insertTeam(team);
            } else {
              await _teamDao.softDeleteTeam(teamId);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportTeamIssue(
              operation: 'listen_team_doc',
              error: error,
              stackTrace: stackTrace,
              extra: {'team_id': teamId},
            );
          },
        );
  }

  void _syncTeamMembers(String teamId) {
    if (_memberSyncSubscriptions.containsKey(teamId)) return;
    _memberSyncSubscriptions[teamId] = _firestore
        .collection(FirestorePaths.teamMembers)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen(
          (snapshot) async {
            for (var doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added ||
                  doc.type == DocumentChangeType.modified) {
                final member = member_model.TeamMember.fromJson(
                  doc.doc.data()!,
                );
                await _teamDao.insertMember(member);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportTeamIssue(
              operation: 'listen_team_members',
              error: error,
              stackTrace: stackTrace,
              extra: {'team_id': teamId},
            );
          },
        );
  }

  // --- Actions ---

  Future<model.Team> createTeam({
    required String name,
    String? description,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final team = model.Team(name: name, ownerId: uid, description: description);

    final member = member_model.TeamMember(
      teamId: team.id,
      userId: uid,
      role: model.JournalRole.owner,
    );

    // 1. Local Save
    await _teamDao.insertTeam(team);
    await _teamDao.insertMember(member);

    // 2. Remote Save
    try {
      final batch = _firestore.batch();

      final teamRef = _firestore.collection(FirestorePaths.teams).doc(team.id);
      batch.set(teamRef, team.toJson());

      final memberRef = _firestore
          .collection(FirestorePaths.teamMembers)
          .doc(member.id);
      batch.set(memberRef, member.toJson());

      await batch.commit();
    } catch (e, st) {
      _reportTeamIssue(
        operation: 'create_team_remote',
        error: e,
        stackTrace: st,
        extra: {'team_id': team.id},
      );
      rethrow;
    }

    return team;
  }

  Future<void> addMember({
    required String teamId,
    required String userId,
    required model.JournalRole role,
  }) async {
    await _ensureLocalTeamAvailable(teamId);

    final member = member_model.TeamMember(
      teamId: teamId,
      userId: userId,
      role: role,
    );

    // 1. Local
    await _teamDao.insertMember(member);

    // 2. Remote
    await _firestore
        .collection(FirestorePaths.teamMembers)
        .doc(member.id)
        .set(member.toJson());

    // Auto-propagate membership to all journals linked to this team.
    await _syncJournalMembersForTeam(teamId);
  }

  /// Creates a journal linked to a team and auto-adds all current team members.
  Future<Journal> createTeamJournal({
    required String teamId,
    required String title,
    String coverStyle = 'default',
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final journal = Journal(
      title: title,
      coverStyle: coverStyle,
      teamId: teamId,
      ownerId: uid,
    );

    // 1. Local save via JournalDao
    if (_journalDao != null) {
      await _journalDao.insertJournal(journal);
    }

    // 2. Remote save
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc(journal.id)
          .set(journal.toJson());
    } catch (e, st) {
      _reportTeamIssue(
        operation: 'create_team_journal_remote',
        error: e,
        stackTrace: st,
        extra: {'team_id': teamId, 'journal_id': journal.id},
      );
    }

    // 3. Auto-add all team members as journal collaborators.
    await _syncJournalMembersForTeam(teamId, singleJournalId: journal.id);

    return journal;
  }

  /// Syncs team members → journal collaborators for all (or a single) team journal.
  Future<void> _syncJournalMembersForTeam(
    String teamId, {
    String? singleJournalId,
  }) async {
    final memberService = _journalMemberService;
    final journalDao = _journalDao;
    if (memberService == null || journalDao == null) return;

    // Fetch team members from local DB.
    final members = await _teamDao.getTeamMembers(teamId);

    // Find journals linked to this team.
    List<Journal> journals;
    if (singleJournalId != null) {
      final j = await journalDao.getJournalById(singleJournalId);
      journals = j != null ? [j] : [];
    } else {
      journals = await journalDao.getJournalsByTeamId(teamId);
    }

    for (final journal in journals) {
      for (final m in members) {
        try {
          await memberService.addMember(
            journalId: journal.id,
            userId: m.userId,
            role: m.role,
          );
        } catch (e, st) {
          _reportTeamIssue(
            operation: 'sync_journal_member',
            error: e,
            stackTrace: st,
            extra: {
              'journal_id': journal.id,
              'user_id': m.userId,
            },
          );
        }
      }
    }
  }

  // Expose Local Data Streams
  Stream<List<model.Team>> watchMyTeams() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);
    return _teamDao.watchMyTeams(uid);
  }

  Stream<List<member_model.TeamMember>> watchMembers(String teamId) {
    return _teamDao.watchTeamMembers(teamId);
  }

  Future<model.Team?> getTeamById(String teamId) {
    return _teamDao.getTeamById(teamId);
  }

  Future<void> deleteTeam(String teamId) async {
    final uid = _currentUid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    model.Team? team = await _teamDao.getTeamById(teamId);
    if (team == null) {
      final remoteTeamDoc = await _firestore
          .collection(FirestorePaths.teams)
          .doc(teamId)
          .get();
      if (!remoteTeamDoc.exists) {
        return;
      }
      team = model.Team.fromJson(remoteTeamDoc.data()!);
    }

    if (team.ownerId != uid) {
      throw Exception('Bu takımı silme yetkiniz yok.');
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    await _teamDao.softDeleteTeam(teamId);
    await _teamDao.softDeleteMembersByTeam(teamId);

    try {
      final batch = _firestore.batch();
      final teamRef = _firestore.collection(FirestorePaths.teams).doc(teamId);
      batch.set(teamRef, {
        'deletedAt': nowIso,
        'updatedAt': nowIso,
      }, SetOptions(merge: true));

      final membersSnapshot = await _firestore
          .collection(FirestorePaths.teamMembers)
          .where('teamId', isEqualTo: teamId)
          .get();
      for (final doc in membersSnapshot.docs) {
        batch.set(doc.reference, {
          'deletedAt': nowIso,
          'updatedAt': nowIso,
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (error, stackTrace) {
      _reportTeamIssue(
        operation: 'delete_team_remote',
        error: error,
        stackTrace: stackTrace,
        extra: {'team_id': teamId},
      );
      rethrow;
    } finally {
      await _teamSyncSubscriptions.remove(teamId)?.cancel();
      await _memberSyncSubscriptions.remove(teamId)?.cancel();
    }
  }

  void dispose() {
    _stopSync();
  }

  Future<void> _ensureLocalTeamAvailable(String teamId) async {
    final localTeam = await _teamDao.getTeamById(teamId);
    if (localTeam != null) {
      return;
    }

    try {
      final remoteTeamDoc = await _firestore
          .collection(FirestorePaths.teams)
          .doc(teamId)
          .get();
      if (!remoteTeamDoc.exists) {
        return;
      }

      final map = remoteTeamDoc.data() ?? const <String, dynamic>{};
      if (!_isDocActive(map['deletedAt'])) {
        return;
      }
      await _teamDao.insertTeam(model.Team.fromJson(map));
    } catch (error, stackTrace) {
      _reportTeamIssue(
        operation: 'hydrate_team_for_member',
        error: error,
        stackTrace: stackTrace,
        extra: {'team_id': teamId},
      );
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
}
