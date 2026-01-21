import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/database/app_database.dart';

/// Global database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Journal DAO provider
final journalDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).journalDao;
});

/// Page DAO provider
final pageDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).pageDao;
});

/// Block DAO provider
final blockDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).blockDao;
});

/// Asset DAO provider
final assetDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).assetDao;
});
