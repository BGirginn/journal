import 'package:drift/drift.dart';
import 'package:journal_app/core/database/app_database.dart';
import 'package:journal_app/core/database/tables/oplogs_table.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/sync/hlc.dart';

part 'oplog_dao.g.dart';

@DriftAccessor(tables: [Oplogs])
class OplogDao extends DatabaseAccessor<AppDatabase> with _$OplogDaoMixin {
  OplogDao(super.db);

  Future<void> insertOplog(OplogEntry entry) {
    return into(oplogs).insert(
      OplogsCompanion.insert(
        opId: entry.opId,
        journalId: entry.journalId,
        pageId: Value(entry.pageId),
        blockId: Value(entry.blockId),
        opType: entry.opType.name,
        hlc: entry.hlc.toString(),
        deviceId: entry.deviceId,
        userId: entry.userId,
        payloadJson: entry.payloadJson,
        status: entry.status.name,
        createdAt: entry.createdAt,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<OplogEntry>> getPendingOplogs() async {
    final rows =
        await (select(oplogs)
              ..where((t) => t.status.equals(OplogStatus.pending.name))
              ..orderBy([(t) => OrderingTerm(expression: t.hlc)]))
            .get();

    return rows.map((row) => _mapToEntry(row)).toList();
  }

  Future<void> updateOplogStatus(String opId, OplogStatus status) {
    return (update(oplogs)..where((t) => t.opId.equals(opId))).write(
      OplogsCompanion(status: Value(status.name)),
    );
  }

  OplogEntry _mapToEntry(Oplog row) {
    return OplogEntry(
      opId: row.opId,
      journalId: row.journalId,
      pageId: row.pageId,
      blockId: row.blockId,
      opType: OplogType.values.byName(row.opType),
      hlc: Hlc.parse(row.hlc),
      deviceId: row.deviceId,
      userId: row.userId,
      payloadJson: row.payloadJson,
      status: OplogStatus.values.byName(row.status),
      createdAt: row.createdAt,
    );
  }
}
