import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/team_dao.dart';
import 'package:journal_app/core/models/team.dart' as model;
import 'package:journal_app/core/models/team_member.dart' as member_model;

final teamServiceProvider = Provider<TeamService>((ref) {
  final teamDao = ref.watch(databaseProvider).teamDao;
  final authService = ref.read(authServiceProvider);
  return TeamService(teamDao, authService);
});

class TeamService {
  final TeamDao _teamDao;
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subscription cache to avoid multiple listeners
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _membersSubscription;
  final Map<String, StreamSubscription> _teamSyncSubscriptions = {};
  final Map<String, StreamSubscription> _memberSyncSubscriptions = {};

  TeamService(this._teamDao, this._authService) {
    _initSync();
  }

  void _initSync() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    // Listen to teams where I am a member (via TeamMembers collection queries ideally)
    // For now, simpler approach: query 'team_members' where userId == me
    // Then fetch those teams.

    // Actually, following the "Offline First" pattern:
    // We should listen to Firestore and update Local DB.
    // The UI should listen to Local DB (Drift).

    _startTeamSync(uid);
  }

  void _startTeamSync(String uid) {
    // 1. Listen to my memberships to know which teams to sync
    _membersSubscription?.cancel();
    _membersSubscription = _firestore
        .collection('team_members')
        .where('userId', isEqualTo: uid)
        .where('deletedAt', isNull: true)
        .snapshots()
        .listen((snapshot) async {
          // For each membership, insert/update local
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added ||
                doc.type == DocumentChangeType.modified) {
              final member = member_model.TeamMember.fromJson(doc.doc.data()!);
              await _teamDao.insertMember(member);

              // Also fetch/sync the team itself
              _syncTeam(member.teamId);
              // And sync other members of this team
              _syncTeamMembers(member.teamId);
            } else if (doc.type == DocumentChangeType.removed) {
              final member = member_model.TeamMember.fromJson(doc.doc.data()!);
              await _teamDao.removeMember(member.teamId, member.userId);
            }
          }
        });
  }

  void _syncTeam(String teamId) {
    if (_teamSyncSubscriptions.containsKey(teamId)) return;
    _teamSyncSubscriptions[teamId] = _firestore
        .collection('teams')
        .doc(teamId)
        .snapshots()
        .listen((doc) async {
      if (doc.exists) {
        final team = model.Team.fromJson(doc.data()!);
        await _teamDao.insertTeam(team);
      } else {
        await _teamDao.softDeleteTeam(teamId);
      }
    });
  }

  void _syncTeamMembers(String teamId) {
    if (_memberSyncSubscriptions.containsKey(teamId)) return;
    _memberSyncSubscriptions[teamId] = _firestore
        .collection('team_members')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snapshot) async {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added ||
                doc.type == DocumentChangeType.modified) {
              final member = member_model.TeamMember.fromJson(doc.doc.data()!);
              await _teamDao.insertMember(member);
            }
          }
        });
  }

  // --- Actions ---

  Future<model.Team> createTeam({
    required String name,
    String? description,
  }) async {
    final uid = _authService.currentUser?.uid;
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

      final teamRef = _firestore.collection('teams').doc(team.id);
      batch.set(teamRef, team.toJson());

      final memberRef = _firestore.collection('team_members').doc(member.id);
      batch.set(memberRef, member.toJson());

      await batch.commit();
    } catch (e) {
      // Revert local? Or user queue?
      // For now, simple error throw.
      debugPrint('Error syncing createTeam: $e');
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
        .collection('team_members')
        .doc(member.id)
        .set(member.toJson());
  }

  // Expose Local Data Streams
  Stream<List<model.Team>> watchMyTeams() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _teamDao.watchMyTeams(uid);
  }

  Stream<List<member_model.TeamMember>> watchMembers(String teamId) {
    return _teamDao.watchTeamMembers(teamId);
  }

  void dispose() {
    _teamsSubscription?.cancel();
    _membersSubscription?.cancel();
    for (final sub in _teamSyncSubscriptions.values) {
      sub.cancel();
    }
    _teamSyncSubscriptions.clear();
    for (final sub in _memberSyncSubscriptions.values) {
      sub.cancel();
    }
    _memberSyncSubscriptions.clear();
  }
}
