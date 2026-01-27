import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/invites_table.dart';
import '../../models/invite.dart' as model;

part 'invite_dao.g.dart';

@DriftAccessor(tables: [Invites])
class InviteDao extends DatabaseAccessor<AppDatabase> with _$InviteDaoMixin {
  InviteDao(super.db);

  /// Create or update invite
  Future<void> insertInvite(model.Invite invite) async {
    await into(
      invites,
    ).insert(_modelToCompanion(invite), mode: InsertMode.insertOrReplace);
  }

  /// Get invites for user (by inviteeId)
  Stream<List<model.Invite>> watchMyInvites(String userId) {
    return (select(invites)..where(
          (t) =>
              t.inviteeId.equals(userId) &
              t.status.equals(model.InviteStatus.pending.name) &
              t.deletedAt.isNull(),
        ))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Get invite by ID
  Future<model.Invite?> getById(String id) async {
    final query = select(invites)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  Future<void> deleteInvite(String id) async {
    await (delete(invites)..where((t) => t.id.equals(id))).go();
  }

  model.Invite _rowToModel(Invite row) {
    return model.Invite(
      id: row.id,
      type: model.InviteType.values.firstWhere((e) => e.name == row.type),
      targetId: row.targetId,
      inviterId: row.inviterId,
      inviteeId: row.inviteeId,
      status: model.InviteStatus.values.firstWhere((e) => e.name == row.status),
      role: model.JournalRole.values.firstWhere(
        (e) => e.name == row.role,
      ), // Ensure JournalRole is available via invite.dart or separate import
      expiresAt: row.expiresAt,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  InvitesCompanion _modelToCompanion(model.Invite invite) {
    return InvitesCompanion(
      id: Value(invite.id),
      type: Value(invite.type.name),
      targetId: Value(invite.targetId),
      inviterId: Value(invite.inviterId),
      inviteeId: Value(invite.inviteeId),
      status: Value(invite.status.name),
      role: Value(invite.role.name),
      expiresAt: Value(invite.expiresAt),
      schemaVersion: Value(invite.schemaVersion),
      createdAt: Value(invite.createdAt),
      updatedAt: Value(invite.updatedAt),
      deletedAt: Value(invite.deletedAt),
    );
  }
}
