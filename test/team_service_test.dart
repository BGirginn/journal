import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/models/team.dart';
import 'package:journal_app/core/models/team_member.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/team/team_service.dart';

Future<void> _waitUntil(Future<bool> Function() check) async {
  for (var i = 0; i < 30; i++) {
    if (await check()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Condition was not met in time');
}

void main() {
  test('createTeam writes local and remote state', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var currentUid = 'owner_1';
    final service = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => currentUid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final team = await service.createTeam(
      name: 'Core Team',
      description: 'Ops',
    );

    final localTeam = await db.teamDao.getTeamById(team.id);
    final localMember = await db.teamDao.getMember(team.id, currentUid);
    expect(localTeam, isNotNull);
    expect(localMember, isNotNull);
    expect(localMember!.role, JournalRole.owner);

    final remoteTeam = await firestore
        .collection(FirestorePaths.teams)
        .doc(team.id)
        .get();
    final remoteMembers = await firestore
        .collection(FirestorePaths.teamMembers)
        .where('teamId', isEqualTo: team.id)
        .where('userId', isEqualTo: currentUid)
        .get();
    expect(remoteTeam.exists, isTrue);
    expect(remoteMembers.docs, hasLength(1));
  });

  test('onAuthStateChanged starts sync and hydrates team data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var currentUid = 'member_1';
    final service = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => currentUid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final team = Team(name: 'Remote Team', ownerId: 'owner_2');
    final member = TeamMember(
      teamId: team.id,
      userId: currentUid,
      role: JournalRole.editor,
    );

    await firestore
        .collection(FirestorePaths.teams)
        .doc(team.id)
        .set(team.toJson());
    await firestore
        .collection(FirestorePaths.teamMembers)
        .doc(member.id)
        .set(member.toJson());

    service.onAuthStateChanged(currentUid);

    await _waitUntil(() async {
      final localTeam = await db.teamDao.getTeamById(team.id);
      final localMember = await db.teamDao.getMember(team.id, currentUid);
      return localTeam != null && localMember != null;
    });
  });

  test('addMember writes local and remote', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    final service = TeamService(
      db.teamDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => 'owner_3',
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    await service.addMember(
      teamId: 'team_123',
      userId: 'member_3',
      role: JournalRole.viewer,
    );

    final localMember = await db.teamDao.getMember('team_123', 'member_3');
    expect(localMember, isNotNull);
    expect(localMember!.role, JournalRole.viewer);

    final remoteMembers = await firestore
        .collection(FirestorePaths.teamMembers)
        .where('teamId', isEqualTo: 'team_123')
        .where('userId', isEqualTo: 'member_3')
        .get();
    expect(remoteMembers.docs, hasLength(1));
  });
}
