import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';

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
  late final FirebaseFirestore? _firestore;

  UserService(this._authService, {bool isAvailable = true})
    : _isAvailable = isAvailable,
      _firestore = isAvailable ? FirebaseFirestore.instance : null;

  String? get _currentUid => _authService.currentUser?.uid;

  /// Ensures user has a Firestore profile.
  Future<UserProfile?> ensureProfileExists() async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final uid = _currentUid;
    if (uid == null) return null;

    final doc = await firestore.collection('users').doc(uid).get();

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

    await firestore.collection('users').doc(uid).set(profile.toMap());

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
        .collection('usernames')
        .doc(normalizedUsername)
        .get();
    if (!doc.exists) return null;

    final uid = doc.data()!['uid'];
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    return UserProfile.fromMap(userDoc.data()!);
  }

  /// Send a friend request to a user
  Future<void> sendFriendRequest(String targetUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    final batch = firestore.batch();

    // Add to my sent requests
    final myRef = firestore.collection('users').doc(uid);
    batch.update(myRef, {
      'sentFriendRequests': FieldValue.arrayUnion([targetUid]),
    });

    // Add to their received requests
    final targetRef = firestore.collection('users').doc(targetUid);
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
    final myRef = firestore.collection('users').doc(uid);
    batch.update(myRef, {
      'receivedFriendRequests': FieldValue.arrayRemove([senderUid]),
      'friends': FieldValue.arrayUnion([senderUid]),
    });

    // Update them: remove sent request, add friend
    final senderRef = firestore.collection('users').doc(senderUid);
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
    final myRef = firestore.collection('users').doc(uid);
    batch.update(myRef, {
      'receivedFriendRequests': FieldValue.arrayRemove([senderUid]),
    });

    // Remove from their sent requests
    final senderRef = firestore.collection('users').doc(senderUid);
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
    final myRef = firestore.collection('users').doc(uid);
    batch.update(myRef, {
      'sentFriendRequests': FieldValue.arrayRemove([targetUid]),
    });

    // Remove from their received requests
    final targetRef = firestore.collection('users').doc(targetUid);
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
    final myRef = firestore.collection('users').doc(uid);
    batch.update(myRef, {
      'friends': FieldValue.arrayRemove([friendUid]),
    });

    // Then them
    final friendRef = firestore.collection('users').doc(friendUid);
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
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!);
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
        .collection('usernames')
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

    // Reserve username
    await firestore.collection('usernames').doc(normalizedUsername).set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update profile
    final displayName = '$firstName $lastName';
    await firestore.collection('users').doc(uid).update({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'username': normalizedUsername,
      'displayName': displayName,
      'isProfileComplete': true,
    });

    // Fetch and return updated profile
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
