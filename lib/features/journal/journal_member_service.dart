import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/models/team.dart';

final journalMemberServiceProvider = Provider<JournalMemberService>((ref) {
  return JournalMemberService();
});

class JournalCollaborator {
  final String id;
  final String journalId;
  final String userId;
  final JournalRole role;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  JournalCollaborator({
    required this.id,
    required this.journalId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory JournalCollaborator.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    return JournalCollaborator(
      id: map['id']?.toString() ?? '',
      journalId: map['journalId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      role: JournalRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => JournalRole.viewer,
      ),
      joinedAt: parseDate(map['joinedAt'], now),
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
      deletedAt: map['deletedAt'] == null
          ? null
          : parseDate(map['deletedAt'], now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journalId': journalId,
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

class JournalMemberService {
  final FirebaseFirestore _firestore;

  JournalMemberService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<JournalCollaborator>> watchMembers(String journalId) {
    return _firestore
        .collection(FirestorePaths.journalMembers)
        .where('journalId', isEqualTo: journalId)
        .snapshots()
        .map((snapshot) {
          final members =
              snapshot.docs
                  .map((doc) => JournalCollaborator.fromMap(doc.data()))
                  .where((member) => member.deletedAt == null)
                  .toList()
                ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
          return members;
        });
  }

  Future<void> addMember({
    required String journalId,
    required String userId,
    required JournalRole role,
  }) async {
    final now = DateTime.now();
    final id = _memberId(journalId, userId);
    final member = JournalCollaborator(
      id: id,
      journalId: journalId,
      userId: userId,
      role: role,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    await _firestore
        .collection(FirestorePaths.journalMembers)
        .doc(id)
        .set(member.toMap(), SetOptions(merge: true));
  }

  Future<void> removeMember({
    required String journalId,
    required String userId,
  }) async {
    final now = DateTime.now();
    await _firestore
        .collection(FirestorePaths.journalMembers)
        .doc(_memberId(journalId, userId))
        .set({
          'deletedAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));
  }

  String _memberId(String journalId, String userId) => '${journalId}_$userId';
}
