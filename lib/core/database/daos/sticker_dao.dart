import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_stickers_table.dart';
import '../../models/user_sticker.dart' as model;

part 'sticker_dao.g.dart';

@DriftAccessor(tables: [UserStickers])
class StickerDao extends DatabaseAccessor<AppDatabase> with _$StickerDaoMixin {
  StickerDao(super.db);

  /// Insert or update sticker
  Future<void> insertSticker(model.UserSticker sticker) async {
    await into(
      userStickers,
    ).insert(_modelToCompanion(sticker), mode: InsertMode.insertOrReplace);
  }

  /// Get all stickers for user (not deleted)
  Stream<List<model.UserSticker>> watchMyStickers(String userId) {
    return (select(userStickers)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Delete sticker (soft delete)
  Future<void> deleteSticker(String id) async {
    await (update(userStickers)..where((t) => t.id.equals(id))).write(
      UserStickersCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  model.UserSticker _rowToModel(UserSticker row) {
    return model.UserSticker(
      id: row.id,
      userId: row.userId,
      type: model.StickerType.values.firstWhere((e) => e.name == row.type),
      content: row.content,
      localPath: row.localPath,
      category: row.category,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  UserStickersCompanion _modelToCompanion(model.UserSticker sticker) {
    return UserStickersCompanion(
      id: Value(sticker.id),
      userId: Value(sticker.userId),
      type: Value(sticker.type.name),
      content: Value(sticker.content),
      localPath: Value(sticker.localPath),
      category: Value(sticker.category),
      schemaVersion: Value(sticker.schemaVersion),
      createdAt: Value(sticker.createdAt),
      updatedAt: Value(sticker.updatedAt),
      deletedAt: Value(sticker.deletedAt),
    );
  }
}
