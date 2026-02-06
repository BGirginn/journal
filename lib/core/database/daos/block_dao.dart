import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/blocks_table.dart';
import '../../models/block.dart' as model;

part 'block_dao.g.dart';

@DriftAccessor(tables: [Blocks])
class BlockDao extends DatabaseAccessor<AppDatabase> with _$BlockDaoMixin {
  BlockDao(super.db);

  /// Watch all non-deleted blocks for a page, ordered by z-index
  Stream<List<model.Block>> watchBlocksForPage(String pageId) {
    return (select(blocks)
          ..where((t) => t.pageId.equals(pageId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Get all non-deleted blocks for a page, ordered by z-index
  Future<List<model.Block>> getBlocksForPage(String pageId) async {
    final rows =
        await (select(blocks)
              ..where((t) => t.pageId.equals(pageId) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.zIndex)]))
            .get();
    return rows.map(_rowToModel).toList();
  }

  /// Search text blocks
  Future<List<model.Block>> searchBlocks(String query) async {
    final rows =
        await (select(blocks)..where(
              (t) =>
                  t.type.equals('text') &
                  t.payloadJson.like('%$query%') &
                  t.deletedAt.isNull(),
            ))
            .get();
    return rows.map(_rowToModel).toList();
  }

  /// Get a single block by ID
  Future<model.Block?> getById(String id) async {
    final query = select(blocks)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get the maximum z-index for a page
  Future<int> getMaxZIndex(String pageId) async {
    final query = selectOnly(blocks)
      ..addColumns([blocks.zIndex.max()])
      ..where(blocks.pageId.equals(pageId) & blocks.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(blocks.zIndex.max()) ?? 0;
  }

  /// Get the minimum z-index for a page
  Future<int> getMinZIndex(String pageId) async {
    final query = selectOnly(blocks)
      ..addColumns([blocks.zIndex.min()])
      ..where(blocks.pageId.equals(pageId) & blocks.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(blocks.zIndex.min()) ?? 0;
  }

  /// Insert a new block
  Future<void> insertBlock(model.Block block) async {
    await into(
      blocks,
    ).insert(_modelToCompanion(block), mode: InsertMode.insertOrReplace);
  }

  /// Update an existing block
  Future<void> updateBlock(model.Block block) async {
    await (update(blocks)..where((t) => t.id.equals(block.id))).write(
      _modelToCompanion(block.copyWith(updatedAt: DateTime.now())),
    );
  }

  /// Update multiple blocks in a single transaction
  Future<void> updateBlocks(List<model.Block> blockList) async {
    await batch((b) {
      for (final block in blockList) {
        b.update(
          blocks,
          _modelToCompanion(block.copyWith(updatedAt: DateTime.now())),
          where: (t) => t.id.equals(block.id),
        );
      }
    });
  }

  /// Update block transform (position, size, rotation)
  Future<void> updateTransform(
    String id, {
    required double x,
    required double y,
    required double width,
    required double height,
    required double rotation,
  }) async {
    await (update(blocks)..where((t) => t.id.equals(id))).write(
      BlocksCompanion(
        x: Value(x),
        y: Value(y),
        width: Value(width),
        height: Value(height),
        rotation: Value(rotation),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update block z-index
  Future<void> updateZIndex(String id, int zIndex) async {
    await (update(blocks)..where((t) => t.id.equals(id))).write(
      BlocksCompanion(zIndex: Value(zIndex), updatedAt: Value(DateTime.now())),
    );
  }

  /// Update block payload
  Future<void> updatePayload(String id, String payloadJson) async {
    await (update(blocks)..where((t) => t.id.equals(id))).write(
      BlocksCompanion(
        payloadJson: Value(payloadJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete a block
  Future<void> softDelete(String id) async {
    await (update(blocks)..where((t) => t.id.equals(id))).write(
      BlocksCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  model.Block _rowToModel(Block row) {
    return model.Block(
      id: row.id,
      pageId: row.pageId,
      type: _parseBlockType(row.type),
      x: row.x,
      y: row.y,
      width: row.width,
      height: row.height,
      rotation: row.rotation,
      zIndex: row.zIndex,
      state: _parseBlockState(row.state),
      payloadJson: row.payloadJson,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  BlocksCompanion _modelToCompanion(model.Block block) {
    return BlocksCompanion(
      id: Value(block.id),
      pageId: Value(block.pageId),
      type: Value(block.type.name),
      x: Value(block.x),
      y: Value(block.y),
      width: Value(block.width),
      height: Value(block.height),
      rotation: Value(block.rotation),
      zIndex: Value(block.zIndex),
      state: Value(block.state.name),
      payloadJson: Value(block.payloadJson),
      schemaVersion: Value(block.schemaVersion),
      createdAt: Value(block.createdAt),
      updatedAt: Value(block.updatedAt),
      deletedAt: Value(block.deletedAt),
    );
  }

  model.BlockType _parseBlockType(String type) {
    return model.BlockType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => model.BlockType.text,
    );
  }

  model.BlockState _parseBlockState(String state) {
    return model.BlockState.values.firstWhere(
      (e) => e.name == state,
      orElse: () => model.BlockState.normal,
    );
  }
}
