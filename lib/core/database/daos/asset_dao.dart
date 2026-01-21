import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/assets_table.dart';
import '../../models/asset.dart' as model;

part 'asset_dao.g.dart';

@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  /// Get asset by ID
  Future<model.Asset?> getById(String id) async {
    final query = select(assets)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get assets for a block
  Future<List<model.Asset>> getAssetsForBlock(String blockId) async {
    final query = select(assets)
      ..where((t) => t.ownerBlockId.equals(blockId) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_rowToModel).toList();
  }

  /// Insert a new asset
  Future<void> insertAsset(model.Asset asset) async {
    await into(assets).insert(_modelToCompanion(asset));
  }

  /// Update an existing asset
  Future<void> updateAsset(model.Asset asset) async {
    await (update(assets)..where((t) => t.id.equals(asset.id))).write(
      _modelToCompanion(asset.copyWith(updatedAt: DateTime.now())),
    );
  }

  /// Update local path
  Future<void> updateLocalPath(String id, String localPath) async {
    await (update(assets)..where((t) => t.id.equals(id))).write(
      AssetsCompanion(
        localPath: Value(localPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete an asset
  Future<void> softDelete(String id) async {
    await (update(assets)..where((t) => t.id.equals(id))).write(
      AssetsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  model.Asset _rowToModel(Asset row) {
    return model.Asset(
      id: row.id,
      ownerBlockId: row.ownerBlockId,
      kind: _parseAssetKind(row.kind),
      localPath: row.localPath,
      remoteUrl: row.remoteUrl,
      metaJson: row.metaJson,
      checksum: row.checksum,
      sizeBytes: row.sizeBytes,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  AssetsCompanion _modelToCompanion(model.Asset asset) {
    return AssetsCompanion(
      id: Value(asset.id),
      ownerBlockId: Value(asset.ownerBlockId),
      kind: Value(asset.kind.name),
      localPath: Value(asset.localPath),
      remoteUrl: Value(asset.remoteUrl),
      metaJson: Value(asset.metaJson),
      checksum: Value(asset.checksum),
      sizeBytes: Value(asset.sizeBytes),
      schemaVersion: Value(asset.schemaVersion),
      createdAt: Value(asset.createdAt),
      updatedAt: Value(asset.updatedAt),
      deletedAt: Value(asset.deletedAt),
    );
  }

  model.AssetKind _parseAssetKind(String kind) {
    return model.AssetKind.values.firstWhere(
      (e) => e.name == kind,
      orElse: () => model.AssetKind.image,
    );
  }
}
