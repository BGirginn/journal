import 'package:journal_app/core/sync/hlc.dart';

enum OplogStatus { pending, sent, acked, applied, failed }

enum OplogType { create, update, delete }

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
}
