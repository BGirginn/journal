import 'package:journal_app/core/sync/hlc.dart';

enum OplogStatus { pending, sent, acked, applied, failed }

enum OplogType { create, update, delete }

class OplogStatusMachine {
  const OplogStatusMachine._();

  static bool canTransition(OplogStatus from, OplogStatus to) {
    if (from == to) return true;
    switch (from) {
      case OplogStatus.pending:
        return to == OplogStatus.sent || to == OplogStatus.failed;
      case OplogStatus.sent:
        return to == OplogStatus.acked || to == OplogStatus.failed;
      case OplogStatus.acked:
        return to == OplogStatus.applied || to == OplogStatus.failed;
      case OplogStatus.applied:
        return false;
      case OplogStatus.failed:
        return to == OplogStatus.pending || to == OplogStatus.sent;
    }
  }

  static OplogStatus enforce(OplogStatus from, OplogStatus to) {
    if (!canTransition(from, to)) {
      throw StateError('Invalid oplog status transition: $from -> $to');
    }
    return to;
  }
}

/// Represents a single operation in the sync log (Operation Log).
///
/// Corresponds to the 'oplogs' table in the local database and the Firestore 'oplog' structure.
class OplogEntry {
  final String opId;
  final String journalId;
  final String? pageId;
  final String? blockId;
  final OplogType opType;
  final Hlc hlc;
  final String deviceId;
  final String userId;
  final String payloadJson;
  final OplogStatus status;
  final DateTime createdAt;

  const OplogEntry({
    required this.opId,
    required this.journalId,
    this.pageId,
    this.blockId,
    required this.opType,
    required this.hlc,
    required this.deviceId,
    required this.userId,
    required this.payloadJson,
    required this.status,
    required this.createdAt,
  });

  /// Create a fresh OplogEntry for a local action
  factory OplogEntry.create({
    required String journalId,
    String? pageId,
    String? blockId,
    required OplogType opType,
    required Hlc hlc,
    required String deviceId,
    required String userId,
    required String payloadJson,
  }) {
    return OplogEntry(
      opId: '${hlc.toString()}-$deviceId', // Simple deterministic opId
      journalId: journalId,
      pageId: pageId,
      blockId: blockId,
      opType: opType,
      hlc: hlc,
      deviceId: deviceId,
      userId: userId,
      payloadJson: payloadJson,
      status: OplogStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opId': opId,
      // Keep actorId for Firestore rules compatibility.
      'actorId': userId,
      'journalId': journalId,
      'pageId': pageId,
      'blockId': blockId,
      'opType': opType.name,
      'hlc': hlc.toString(),
      'deviceId': deviceId,
      'userId': userId,
      'payloadJson': payloadJson,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OplogEntry copyWith({
    String? opId,
    String? journalId,
    String? pageId,
    String? blockId,
    OplogType? opType,
    Hlc? hlc,
    String? deviceId,
    String? userId,
    String? payloadJson,
    OplogStatus? status,
    DateTime? createdAt,
  }) {
    return OplogEntry(
      opId: opId ?? this.opId,
      journalId: journalId ?? this.journalId,
      pageId: pageId ?? this.pageId,
      blockId: blockId ?? this.blockId,
      opType: opType ?? this.opType,
      hlc: hlc ?? this.hlc,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
