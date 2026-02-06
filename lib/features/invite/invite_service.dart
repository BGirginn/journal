import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/invite_dao.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:journal_app/core/models/invite.dart';

final inviteServiceProvider = Provider<InviteService>((ref) {
  final inviteDao = ref.watch(databaseProvider).inviteDao;
  final authService = ref.read(authServiceProvider);
  final teamService = ref.read(teamServiceProvider);
  return InviteService(inviteDao, authService, teamService);
});

class InviteService {
  final InviteDao _inviteDao;
  final AuthService _authService;
  final TeamService _teamService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _invitesSubscription;

  InviteService(this._inviteDao, this._authService, this._teamService) {
    _initSync();
  }

  void _initSync() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _invitesSubscription?.cancel();
    _invitesSubscription = _firestore
        .collection('invites')
        .where('inviteeId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
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
        });
  }

  Stream<List<Invite>> watchMyInvites() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _inviteDao.watchMyInvites(uid);
  }

  Future<Invite> createInvite({
    required InviteType type,
    required String targetId,
    String? inviteeId, // Null for public link
    required JournalRole role,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final invite = Invite(
      type: type,
      targetId: targetId,
      inviterId: uid,
      inviteeId: inviteeId,
      role: role,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    // Save to Firestore (Local will sync via listener if invitee is me, otherwise no need to local save invite I SENT unless needed)
    // Actually, saving inviter's sent invites locally is good too.
    // But DAO watchMyInvites filters by inviteeId.

    await _firestore.collection('invites').doc(invite.id).set(invite.toJson());

    return invite;
  }

  Future<void> acceptInvite(Invite invite) async {
    final uid = _authService.currentUser?.uid;
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
    } else {
      // Handle Journal invite
      // For now mostly teams.
    }

    // Update Invite Status
    // Use Firestore update
    await _firestore.collection('invites').doc(invite.id).update({
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
    await _firestore.collection('invites').doc(invite.id).update({
      'status': InviteStatus.rejected.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
