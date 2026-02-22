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

final teamServiceProvider = Provider<TeamService>((ref) {
  final teamDao = ref.watch(databaseProvider).teamDao;
  final authService = ref.read(authServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  final service = TeamService(teamDao, authService, logger, telemetry);
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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUidProvider = currentUidProvider;

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

  void dispose() {
    _stopSync();
  }
}
