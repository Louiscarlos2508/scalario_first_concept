import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cached_layouts.dart';

/// DAO pour [CachedLayouts] — screen configs BDUI cache local.
///
/// AC-19 : `select by screenId` répond en < 30ms.
/// AC-20 : LRU éviction via `lastFetchAt` ordonné.
final class CachedLayoutDao extends DatabaseAccessor<ScalarioDatabase> {
  CachedLayoutDao(super.attachedDatabase);

  Future<CachedLayout?> getByScreenId(String screenId) =>
      (select(db.cachedLayouts)
            ..where((t) => t.screenId.equals(screenId)))
          .getSingleOrNull();

  Future<List<CachedLayout>> getByTenant(String tenantId) =>
      (select(db.cachedLayouts)
            ..where((t) => t.tenantId.equals(tenantId)))
          .get();

  Future<List<CachedLayout>> getLruOrdered(String tenantId) =>
      (select(db.cachedLayouts)
            ..where((t) => t.tenantId.equals(tenantId))
            ..orderBy(
              [(t) => OrderingTerm(expression: t.lastFetchAt)],
            ))
          .get();

  Future<int> totalBytesForTenant(String tenantId) =>
      (selectOnly(db.cachedLayouts)
            ..addColumns([db.cachedLayouts.bytesSize.sum()])
            ..where(db.cachedLayouts.tenantId.equals(tenantId)))
          .map((row) => row.read(db.cachedLayouts.bytesSize.sum()) ?? 0)
          .getSingle();

  Future<void> upsert(CachedLayoutsCompanion layout) =>
      into(db.cachedLayouts).insertOnConflictUpdate(layout);

  Future<void> deleteByScreenId(String screenId) =>
      (delete(db.cachedLayouts)..where((t) => t.screenId.equals(screenId)))
          .go();

  Future<void> deleteAll() => delete(db.cachedLayouts).go();
}
