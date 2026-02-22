import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';

void main() {
  const me = 'user_me';
  const other = 'user_other';

  late FakeFirebaseFirestore firestore;
  late AuthService authService;
  late UserService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    authService = AuthService(isFirebaseAvailable: false);
    service = UserService(
      authService,
      isAvailable: true,
      firestore: firestore,
      currentUidProvider: () => me,
    );
  });

  test('ensureProfileExistsAndNeedsSetup creates profile once', () async {
    final first = await service.ensureProfileExistsAndNeedsSetup();
    final second = await service.ensureProfileExistsAndNeedsSetup();

    final doc = await firestore.collection(FirestorePaths.users).doc(me).get();

    expect(first, isTrue);
    expect(second, isFalse);
    expect(doc.exists, isTrue);
    expect(doc.data()!['displayName'], equals('Yeni Kullanıcı'));
    expect(doc.data()!['isProfileComplete'], isFalse);
  });

  test('ensureProfileExists returns existing profile', () async {
    await firestore.collection(FirestorePaths.users).doc(me).set({
      'uid': me,
      'displayName': 'Alice',
      'friends': [other],
      'isProfileComplete': true,
    });

    final profile = await service.ensureProfileExists();

    expect(profile, isNotNull);
    expect(profile!.uid, equals(me));
    expect(profile.displayName, equals('Alice'));
    expect(profile.friends, contains(other));
    expect(profile.isProfileComplete, isTrue);
  });

  test('searchByUsername finds mapped profile', () async {
    await firestore.collection(FirestorePaths.usernames).doc('ali').set({
      'uid': other,
    });
    await firestore.collection(FirestorePaths.users).doc(other).set({
      'uid': other,
      'displayName': 'Ali User',
      'friends': const <String>[],
    });

    final profile = await service.searchByUsername(' Ali ');

    expect(profile, isNotNull);
    expect(profile!.uid, equals(other));
    expect(profile.displayName, equals('Ali User'));
  });

  test('getProfiles batches whereIn queries over 10 users', () async {
    final uids = <String>[];
    for (var i = 0; i < 12; i++) {
      final uid = 'u_$i';
      uids.add(uid);
      await firestore.collection(FirestorePaths.users).doc(uid).set({
        'uid': uid,
        'displayName': 'User $i',
        'friends': const <String>[],
      });
    }

    final profiles = await service.getProfiles(uids);
    final profileUids = profiles.map((e) => e.uid).toSet();

    expect(profiles.length, equals(12));
    expect(profileUids.containsAll(uids), isTrue);
  });

  test('friend request lifecycle works end-to-end', () async {
    await firestore.collection(FirestorePaths.users).doc(me).set({
      'uid': me,
      'displayName': 'Me',
      'friends': const <String>[],
      'receivedFriendRequests': const <String>[],
      'sentFriendRequests': const <String>[],
    });
    await firestore.collection(FirestorePaths.users).doc(other).set({
      'uid': other,
      'displayName': 'Other',
      'friends': const <String>[],
      'receivedFriendRequests': const <String>[],
      'sentFriendRequests': const <String>[],
    });

    await service.sendFriendRequest(other);

    var meDoc = await firestore.collection(FirestorePaths.users).doc(me).get();
    var otherDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(other)
        .get();

    expect(meDoc.data()!['sentFriendRequests'], contains(other));
    expect(otherDoc.data()!['receivedFriendRequests'], contains(me));

    await service.cancelFriendRequest(other);

    meDoc = await firestore.collection(FirestorePaths.users).doc(me).get();
    otherDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(other)
        .get();

    expect(meDoc.data()!['sentFriendRequests'], isNot(contains(other)));
    expect(otherDoc.data()!['receivedFriendRequests'], isNot(contains(me)));

    await service.sendFriendRequest(other);

    final otherService = UserService(
      authService,
      isAvailable: true,
      firestore: firestore,
      currentUidProvider: () => other,
    );

    await otherService.acceptFriendRequest(me);

    meDoc = await firestore.collection(FirestorePaths.users).doc(me).get();
    otherDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(other)
        .get();

    expect(meDoc.data()!['friends'], contains(other));
    expect(otherDoc.data()!['friends'], contains(me));

    await service.removeFriend(other);

    meDoc = await firestore.collection(FirestorePaths.users).doc(me).get();
    otherDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(other)
        .get();

    expect(meDoc.data()!['friends'], isNot(contains(other)));
    expect(otherDoc.data()!['friends'], isNot(contains(me)));
  });

  test(
    'completeProfile reserves username and marks profile complete',
    () async {
      await firestore.collection(FirestorePaths.users).doc(me).set({
        'uid': me,
        'displayName': 'Starter',
        'friends': const <String>[],
        'isProfileComplete': false,
      });

      final profile = await service.completeProfile(
        firstName: 'Jane',
        lastName: 'Doe',
        username: 'Jane_Doe',
      );

      final usernameDoc = await firestore
          .collection(FirestorePaths.usernames)
          .doc('jane_doe')
          .get();
      final userDoc = await firestore
          .collection(FirestorePaths.users)
          .doc(me)
          .get();

      expect(profile, isNotNull);
      expect(profile!.firstName, equals('Jane'));
      expect(profile.lastName, equals('Doe'));
      expect(profile.username, equals('jane_doe'));
      expect(profile.isProfileComplete, isTrue);
      expect(usernameDoc.exists, isTrue);
      expect(usernameDoc.data()!['uid'], equals(me));
      expect(userDoc.data()!['displayName'], equals('Jane Doe'));
    },
  );

  test('isUsernameAvailable checks usernames index', () async {
    await firestore.collection(FirestorePaths.usernames).doc('taken_name').set({
      'uid': other,
    });

    final shortName = await service.isUsernameAvailable('ab');
    final taken = await service.isUsernameAvailable('taken_name');
    final free = await service.isUsernameAvailable('new_name');

    expect(shortName, isFalse);
    expect(taken, isFalse);
    expect(free, isTrue);
  });

  test('unavailable service returns null or safe defaults', () async {
    final unavailable = UserService(
      authService,
      isAvailable: false,
      currentUidProvider: () => me,
    );

    expect(await unavailable.ensureProfileExists(), isNull);
    expect(await unavailable.searchByUsername('any'), isNull);
    expect(await unavailable.getUserProfile(me), isNull);
    expect(await unavailable.getProfiles([me, other]), isEmpty);
    expect(await unavailable.ensureProfileExistsAndNeedsSetup(), isFalse);
    expect(unavailable.myProfileStream, emits(null));
  });
}
