import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'dart:math';

final userServiceProvider = Provider<UserService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
  return UserService(authService, isAvailable: isFirebaseAvailable);
});

final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(userServiceProvider).myProfileStream;
});

class UserProfile {
  final String uid;
  final String displayId;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final List<String> friends;
  final bool isProfileComplete;

  UserProfile({
    required this.uid,
    required this.displayId,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    required this.friends,
    this.isProfileComplete = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayId: map['displayId'] ?? '',
      displayName: map['displayName'] ?? 'Anonim',
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
      photoUrl: map['photoUrl'],
      friends: List<String>.from(map['friends'] ?? []),
      isProfileComplete: map['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayId': displayId,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'photoUrl': photoUrl,
      'friends': friends,
      'isProfileComplete': isProfileComplete,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? firstName,
    String? lastName,
    String? username,
    String? photoUrl,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      uid: uid,
      displayId: displayId,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      friends: friends,
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

  /// Ensures user has a Firestore profile and a unique display ID.
  Future<UserProfile?> ensureProfileExists() async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final uid = _currentUid;
    if (uid == null) return null;

    final doc = await firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }

    // Create new profile
    final displayId = await _generateUniqueDisplayId();
    final user = _authService.currentUser;

    final profile = UserProfile(
      uid: uid,
      displayId: displayId,
      displayName: user?.displayName ?? 'Yeni Kullanıcı',
      photoUrl: user?.photoURL,
      friends: [],
    );

    await firestore.collection('users').doc(uid).set(profile.toMap());

    // Reverse lookup for uniqueness
    await firestore.collection('displayIds').doc(displayId).set({'uid': uid});

    return profile;
  }

  Future<String> _generateUniqueDisplayId() async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return 'J-0000';

    final random = Random();
    while (true) {
      final id = 'J-${random.nextInt(9000) + 1000}'; // J-1000 to J-9999
      final doc = await firestore.collection('displayIds').doc(id).get();
      if (!doc.exists) return id;
    }
  }

  Future<UserProfile?> searchByDisplayId(String displayId) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return null;

    final doc = await firestore
        .collection('displayIds')
        .doc(displayId.toUpperCase())
        .get();
    if (!doc.exists) return null;

    final uid = doc.data()!['uid'];
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    return UserProfile.fromMap(userDoc.data()!);
  }

  Future<void> addFriend(String friendUid) async {
    final firestore = _firestore;
    if (!_isAvailable || firestore == null) return;

    final uid = _currentUid;
    if (uid == null) return;

    // Add to my friends
    await firestore.collection('users').doc(uid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });

    // Add me to their friends (Optional, but good for mutual)
    await firestore.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayUnion([uid]),
    });
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
