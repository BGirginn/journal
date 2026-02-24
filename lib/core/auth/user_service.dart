import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';

final userServiceProvider = Provider<UserService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
  return UserService(authService, isAvailable: isFirebaseAvailable);
});

final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Watch auth state changes so the profile stream updates on login/logout
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return Stream.value(null);

  return ref.watch(userServiceProvider).myProfileStream;
});

class UserProfile {
  final String uid;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final String? preferredLanguage;
  final List<String> friends;
  final List<String> receivedFriendRequests;
  final List<String> sentFriendRequests;
  final bool isProfileComplete;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    this.preferredLanguage,
    required this.friends,
    this.receivedFriendRequests = const [],
    this.sentFriendRequests = const [],
    this.isProfileComplete = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'Anonim',
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
      photoUrl: map['photoUrl'],
      preferredLanguage: map['preferredLanguage'],
      friends: List<String>.from(map['friends'] ?? []),
      receivedFriendRequests: List<String>.from(
        map['receivedFriendRequests'] ?? [],
      ),
      sentFriendRequests: List<String>.from(map['sentFriendRequests'] ?? []),
      isProfileComplete: map['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'photoUrl': photoUrl,
      'preferredLanguage': preferredLanguage,
      'friends': friends,
      'receivedFriendRequests': receivedFriendRequests,
      'sentFriendRequests': sentFriendRequests,
      'isProfileComplete': isProfileComplete,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? firstName,
    String? lastName,
    String? username,
    String? photoUrl,
    String? preferredLanguage,
    List<String>? friends,
    List<String>? receivedFriendRequests,
    List<String>? sentFriendRequests,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      friends: friends ?? this.friends,
      receivedFriendRequests:
          receivedFriendRequests ?? this.receivedFriendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}

class UserService {
  final AuthService _authService;
  final bool _isAvailable;
  final FirebaseFirestore? _firestore;
  final String? Function()? _currentUidProvider;

  UserService(
    this._authService, {
    bool isAvailable = true,
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
  }) : _isAvailable = isAvailable,
       _firestore = isAvailable
           ? (firestore ?? FirebaseFirestore.instance)
           : null,
       _currentUidProvider = currentUidProvider;

  String? get _currentUid =>
      _currentUidProvider?.call() ?? _authService.currentUser?.uid;

  /// Returns `true` only for first-time users that do not yet have a profile document.
  /// Existing users are allowed to continue directly without onboarding gate.
  Future<bool> ensureProfileExistsAndNeedsSetup() async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return false;

    final uid = _currentUid;
    if (uid == null) return false;
    final userRef = firestore.collection(FirestorePaths.users).doc(uid);

    debugPrint('Ensuring profile exists for $uid...');
    try {
      final doc = await userRef.get().timeout(const Duration(seconds: 10));

      if (doc.exists) {
        debugPrint('Profile exists for $uid.');
        return false;
      }

      debugPrint('Profile does not exist for $uid. Creating new profile.');
      final user = _authService.currentUser;
      final profile = UserProfile(
        uid: uid,
        displayName: user?.displayName ?? 'Yeni Kullanıcı',
        photoUrl: user?.photoURL,
        friends: const [],
        isProfileComplete: false,
      );
      await userRef.set(profile.toMap()).timeout(const Duration(seconds: 10));
      debugPrint('New profile created for $uid.');
      return true;
    } catch (e) {
      debugPrint('Error or timeout checking profile for $uid: $e');
      throw Exception('Profil kontrolu basarisiz: $e');
    }
  }

  /// Ensures user has a Firestore profile.
  Future<UserProfile?> ensureProfileExists() async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final uid = _currentUid;
    if (uid == null) return null;

    final doc = await firestore.collection(FirestorePaths.users).doc(uid).get();

    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }

    // Create new profile (without username - will be set in profile setup)
    final user = _authService.currentUser;

    final profile = UserProfile(
      uid: uid,
      displayName: user?.displayName ?? 'Yeni Kullanıcı',
      photoUrl: user?.photoURL,
      friends: [],
    );

    await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(profile.toMap());

    return profile;
  }

  /// Search for a user by username
  Future<UserProfile?> searchByUsername(String username) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final normalizedUsername = username.toLowerCase().trim();
    if (normalizedUsername.isEmpty) return null;

    // Look up username in usernames collection
    final doc = await firestore
        .collection(FirestorePaths.usernames)
        .doc(normalizedUsername)
        .get();
    if (!doc.exists) return null;

    final uid = doc.data()!['uid'];
    final userDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    if (!userDoc.exists) return null;

    return UserProfile.fromMap(userDoc.data()!);
  }

  /// Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final doc = await firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  /// Get multiple profiles by UIDs
  Future<List<UserProfile>> getProfiles(List<String> uids) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null || uids.isEmpty) return [];

    // Firestore 'whereIn' supports up to 10 items.
    // If list is larger, we need to batch or loop.
    // For simplicity, we'll fetch in batches of 10.
    final profiles = <UserProfile>[];

    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 < uids.length) ? i + 10 : uids.length;
      final batch = uids.sublist(i, end);

      final querySnapshot = await firestore
          .collection(FirestorePaths.users)
          .where('uid', whereIn: batch)
          .get();

      profiles.addAll(
        querySnapshot.docs.map((doc) => UserProfile.fromMap(doc.data())),
      );
    }

    return profiles;
  }

  /// Send a friend request to a user
  Future<void> sendFriendRequest(String targetUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;
    if (targetUid == uid) {
      throw Exception('Kendinize arkadaş isteği gönderemezsiniz.');
    }

    final myRef = firestore.collection(FirestorePaths.users).doc(uid);
    final targetRef = firestore.collection(FirestorePaths.users).doc(targetUid);
    final snapshots = await Future.wait([myRef.get(), targetRef.get()]);
    if (!snapshots[0].exists || !snapshots[1].exists) {
      throw Exception('Profil bulunamadı.');
    }

    final myProfile = UserProfile.fromMap(snapshots[0].data()!);
    if (myProfile.friends.contains(targetUid)) {
      throw Exception('Bu kullanıcı zaten arkadaş listenizde.');
    }
    if (myProfile.sentFriendRequests.contains(targetUid)) {
      throw Exception('Bu kullanıcıya zaten istek gönderildi.');
    }
    if (myProfile.receivedFriendRequests.contains(targetUid)) {
      throw Exception('Bu kullanıcıdan zaten bir isteğiniz var.');
    }

    final batch = firestore.batch();

    // Add to my sent requests
    batch.update(myRef, {
      'sentFriendRequests': FieldValue.arrayUnion([targetUid]),
    });

    // Add to their received requests
    batch.update(targetRef, {
      'receivedFriendRequests': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String senderUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final batch = firestore.batch();

    // Update me: remove request, add friend
    final myRef = firestore.collection(FirestorePaths.users).doc(uid);
    batch.update(myRef, {
      'receivedFriendRequests': FieldValue.arrayRemove([senderUid]),
      'friends': FieldValue.arrayUnion([senderUid]),
    });

    // Update them: remove sent request, add friend
    final senderRef = firestore.collection(FirestorePaths.users).doc(senderUid);
    batch.update(senderRef, {
      'sentFriendRequests': FieldValue.arrayRemove([uid]),
      'friends': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String senderUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final batch = firestore.batch();

    // Remove from my received requests
    final myRef = firestore.collection(FirestorePaths.users).doc(uid);
    batch.update(myRef, {
      'receivedFriendRequests': FieldValue.arrayRemove([senderUid]),
    });

    // Remove from their sent requests
    final senderRef = firestore.collection(FirestorePaths.users).doc(senderUid);
    batch.update(senderRef, {
      'sentFriendRequests': FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest(String targetUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final batch = firestore.batch();

    // Remove from my sent requests
    final myRef = firestore.collection(FirestorePaths.users).doc(uid);
    batch.update(myRef, {
      'sentFriendRequests': FieldValue.arrayRemove([targetUid]),
    });

    // Remove from their received requests
    final targetRef = firestore.collection(FirestorePaths.users).doc(targetUid);
    batch.update(targetRef, {
      'receivedFriendRequests': FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  /// Remove a friend
  Future<void> removeFriend(String friendUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final batch = firestore.batch();

    // Start with me
    final myRef = firestore.collection(FirestorePaths.users).doc(uid);
    batch.update(myRef, {
      'friends': FieldValue.arrayRemove([friendUid]),
    });

    // Then them
    final friendRef = firestore.collection(FirestorePaths.users).doc(friendUid);
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  Stream<UserProfile?> get myProfileStream {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return Stream.value(null);

    final uid = _currentUid;
    if (uid == null) return Stream.value(null);
    return firestore.collection(FirestorePaths.users).doc(uid).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!);
    });
  }

  /// Update user's profile photo URL
  Future<void> updateProfilePhoto(String photoUrl) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    await firestore.collection(FirestorePaths.users).doc(uid).update({
      'photoUrl': photoUrl,
    });
  }

  /// Update user's display name
  Future<void> updateDisplayName(String displayName) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    await firestore.collection(FirestorePaths.users).doc(uid).update({
      'displayName': displayName,
    });
  }

  Future<void> updatePreferredLanguage(String code) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final normalized = code.trim().toLowerCase();
    final supported = normalized.startsWith('en') ? 'en' : 'tr';

    await firestore.collection(FirestorePaths.users).doc(uid).update({
      'preferredLanguage': supported,
    });
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) {
      throw Exception('Servis bağlantısı yok');
    }

    final normalizedUsername = username.toLowerCase().trim();
    if (normalizedUsername.length < 3) return false;

    final doc = await firestore
        .collection(FirestorePaths.usernames)
        .doc(normalizedUsername)
        .get();
    return !doc.exists;
  }

  /// Complete profile setup for new users
  Future<UserProfile?> completeProfile({
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final uid = _currentUid;
    if (uid == null) return null;

    final normalizedUsername = username.toLowerCase().trim();

    // Reserve username atomically with a transaction
    await firestore.runTransaction((transaction) async {
      final usernameDoc = firestore
          .collection(FirestorePaths.usernames)
          .doc(normalizedUsername);
      final snapshot = await transaction.get(usernameDoc);

      if (snapshot.exists) {
        throw Exception('Bu kullanıcı adı zaten alınmış');
      }

      transaction.set(usernameDoc, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(firestore.collection(FirestorePaths.users).doc(uid), {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': normalizedUsername,
        'displayName': '$firstName $lastName',
        'isProfileComplete': true,
      });
    });

    // Fetch and return updated profile
    final doc = await firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
