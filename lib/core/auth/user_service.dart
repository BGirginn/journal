import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'dart:math';

final userServiceProvider = Provider<UserService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
  return UserService(authService, isAvailable: isFirebaseAvailable);
});

class UserProfile {
  final String uid;
  final String displayId;
  final String displayName;
  final String? photoUrl;
  final List<String> friends;

  UserProfile({
    required this.uid,
    required this.displayId,
    required this.displayName,
    this.photoUrl,
    required this.friends,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayId: map['displayId'] ?? '',
      displayName: map['displayName'] ?? 'Anonim',
      photoUrl: map['photoUrl'],
      friends: List<String>.from(map['friends'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayId': displayId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'friends': friends,
    };
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
}
