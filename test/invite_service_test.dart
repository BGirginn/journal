import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/features/journal/journal_member_service.dart';
import 'package:journal_app/features/team/team_service.dart';

Future<void> _waitUntil(Future<bool> Function() check) async {
  for (var i = 0; i < 30; i++) {
    if (await check()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Condition was not met in time');
}

void main() {
  test('createInvite writes invite to firestore', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'inviter_1';
    final teamService = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    final inviteService = InviteService(
      db.inviteDao,
      AuthService(isFirebaseAvailable: false),
      teamService,
      JournalMemberService(firestore: firestore),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      inviteService.dispose();
      teamService.dispose();
      await db.close();
    });

    final invite = await inviteService.createInvite(
      type: InviteType.team,
      targetId: 'team_create_1',
      inviteeId: 'invitee_1',
      role: JournalRole.editor,
    );

    final doc = await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['targetId'], equals('team_create_1'));
    expect(doc.data()!['inviterId'], equals(uid));
  });

  test('onAuthStateChanged hydrates pending invites to local dao', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'invitee_sync_1';
    final teamService = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    final inviteService = InviteService(
      db.inviteDao,
      AuthService(isFirebaseAvailable: false),
      teamService,
      JournalMemberService(firestore: firestore),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      inviteService.dispose();
      teamService.dispose();
      await db.close();
    });

    final invite = Invite(
      type: InviteType.team,
      targetId: 'team_sync_1',
      inviterId: 'owner_sync_1',
      inviteeId: uid,
      role: JournalRole.viewer,
      expiresAt: DateTime.now().add(const Duration(days: 2)),
    );
    await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .set(invite.toJson());

    inviteService.onAuthStateChanged(uid);

    await _waitUntil(
      () async => (await db.inviteDao.getById(invite.id)) != null,
    );
  });

  test('acceptInvite updates invite and adds team member', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'invitee_accept_1';
    final teamService = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    final inviteService = InviteService(
      db.inviteDao,
      AuthService(isFirebaseAvailable: false),
      teamService,
      JournalMemberService(firestore: firestore),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      inviteService.dispose();
      teamService.dispose();
      await db.close();
    });

    final invite = Invite(
      type: InviteType.team,
      targetId: 'team_accept_1',
      inviterId: 'owner_accept_1',
      inviteeId: uid,
      role: JournalRole.editor,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .set(invite.toJson());

    await inviteService.acceptInvite(invite);

    final inviteDoc = await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .get();
    expect(inviteDoc.data()!['status'], InviteStatus.accepted.name);

    final localMember = await db.teamDao.getMember(invite.targetId, uid);
    expect(localMember, isNotNull);

    final remoteMembers = await firestore
        .collection(FirestorePaths.teamMembers)
        .where('teamId', isEqualTo: invite.targetId)
        .where('userId', isEqualTo: uid)
        .get();
    expect(remoteMembers.docs, hasLength(1));
  });

  test('acceptInvite updates invite and adds journal collaborator', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'invitee_journal_1';
    final teamService = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    final inviteService = InviteService(
      db.inviteDao,
      AuthService(isFirebaseAvailable: false),
      teamService,
      JournalMemberService(firestore: firestore),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      inviteService.dispose();
      teamService.dispose();
      await db.close();
    });

    final invite = Invite(
      type: InviteType.journal,
      targetId: 'journal_accept_1',
      inviterId: 'owner_journal_1',
      inviteeId: uid,
      role: JournalRole.editor,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .set(invite.toJson());

    await inviteService.acceptInvite(invite);

    final inviteDoc = await firestore
        .collection(FirestorePaths.invites)
        .doc(invite.id)
        .get();
    expect(inviteDoc.data()!['status'], InviteStatus.accepted.name);

    final memberDoc = await firestore
        .collection(FirestorePaths.journalMembers)
        .doc('${invite.targetId}_$uid')
        .get();
    expect(memberDoc.exists, isTrue);
    expect(memberDoc.data()!['journalId'], invite.targetId);
    expect(memberDoc.data()!['userId'], uid);
  });
}
