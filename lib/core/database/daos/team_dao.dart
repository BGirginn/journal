import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/teams_table.dart';
import '../tables/team_members_table.dart';
import '../../models/team.dart' as model;
import '../../models/team_member.dart' as member_model;

part 'team_dao.g.dart';

@DriftAccessor(tables: [Teams, TeamMembers])
class TeamDao extends DatabaseAccessor<AppDatabase> with _$TeamDaoMixin {
  TeamDao(super.db);

  // --- Teams ---

  Stream<List<model.Team>> watchMyTeams(String userId) {
    // Join Teams with TeamMembers to find teams where the user is a member
    final query =
        select(teams).join([
          innerJoin(teamMembers, teamMembers.teamId.equalsExp(teams.id)),
        ])..where(
          teamMembers.userId.equals(userId) &
              teams.deletedAt.isNull() &
              teamMembers.deletedAt.isNull(),
        );

    return query.watch().map((rows) {
      return rows.map((row) => _rowToTeamModel(row.readTable(teams))).toList();
    });
  }

  Future<model.Team?> getTeamById(String id) async {
    final query = select(teams)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _rowToTeamModel(row) : null;
  }

  Future<void> insertTeam(model.Team team) async {
    await into(
      teams,
    ).insert(_teamModelToCompanion(team), mode: InsertMode.insertOrReplace);
  }

  Future<void> updateTeam(model.Team team) async {
    await (update(teams)..where((t) => t.id.equals(team.id))).write(
      _teamModelToCompanion(team.copyWith(updatedAt: DateTime.now())),
    );
  }

  Future<void> softDeleteTeam(String id) async {
    await (update(teams)..where((t) => t.id.equals(id))).write(
      TeamsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Team Members ---

  Stream<List<member_model.TeamMember>> watchTeamMembers(String teamId) {
    return (select(teamMembers)
          ..where((t) => t.teamId.equals(teamId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.joinedAt)]))
        .watch()
        .map((rows) => rows.map(_rowToMemberModel).toList());
  }

  Future<void> insertMember(member_model.TeamMember member) async {
    await into(
      teamMembers,
    ).insert(_memberModelToCompanion(member), mode: InsertMode.insertOrReplace);
  }

  Future<void> updateMember(member_model.TeamMember member) async {
    await (update(teamMembers)..where((t) => t.id.equals(member.id))).write(
      _memberModelToCompanion(member.copyWith(updatedAt: DateTime.now())),
    );
  }

  Future<void> removeMember(String teamId, String userId) async {
    await (update(
      teamMembers,
    )..where((t) => t.teamId.equals(teamId) & t.userId.equals(userId))).write(
      TeamMembersCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<member_model.TeamMember?> getMember(
    String teamId,
    String userId,
  ) async {
    final query = select(teamMembers)
      ..where(
        (t) =>
            t.teamId.equals(teamId) &
            t.userId.equals(userId) &
            t.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row != null ? _rowToMemberModel(row) : null;
  }

  // --- Helpers ---

  model.Team _rowToTeamModel(Team row) {
    return model.Team(
      id: row.id,
      name: row.name,
      ownerId: row.ownerId,
      description: row.description,
      avatarUrl: row.avatarUrl,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  TeamsCompanion _teamModelToCompanion(model.Team team) {
    return TeamsCompanion(
      id: Value(team.id),
      name: Value(team.name),
      ownerId: Value(team.ownerId),
      description: Value(team.description),
      avatarUrl: Value(team.avatarUrl),
      schemaVersion: Value(team.schemaVersion),
      createdAt: Value(team.createdAt),
      updatedAt: Value(team.updatedAt),
      deletedAt: Value(team.deletedAt),
    );
  }

  member_model.TeamMember _rowToMemberModel(TeamMember row) {
    return member_model.TeamMember(
      id: row.id,
      teamId: row.teamId,
      userId: row.userId,
      role: model.JournalRole.values.firstWhere(
        (e) => e.name == row.role,
        orElse: () => model.JournalRole.viewer,
      ),
      joinedAt: row.joinedAt,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  TeamMembersCompanion _memberModelToCompanion(member_model.TeamMember member) {
    return TeamMembersCompanion(
      id: Value(member.id),
      teamId: Value(member.teamId),
      userId: Value(member.userId),
      role: Value(member.role.name),
      joinedAt: Value(member.joinedAt),
      schemaVersion: Value(member.schemaVersion),
      createdAt: Value(member.createdAt),
      updatedAt: Value(member.updatedAt),
      deletedAt: Value(member.deletedAt),
    );
  }
}
