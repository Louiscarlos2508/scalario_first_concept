import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/local_data.dart';

/// DAO pour [LocalData] — entités métier en JSONB local.
///
/// AC-06 : mirror du modèle JSONB serveur.
/// AC-21 : non soumis au LRU (données métier).
final class LocalDataDao extends DatabaseAccessor<ScalarioDatabase> {
  LocalDataDao(super.attachedDatabase);

  Future<LocalDataRecord?> getById(String id) =>
      (select(db.localData)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<LocalDataRecord>> getByModule(
    String tenantId,
    String moduleId, {
    String? entityType,
  }) {
    final query = select(db.localData)
      ..where(
        (t) => t.tenantId.equals(tenantId) & t.moduleId.equals(moduleId),
      );
    if (entityType != null) {
      query.where((t) => t.entityType.equals(entityType));
    }
    return query.get();
  }

  Future<List<LocalDataRecord>> getPendingSync(String tenantId) =>
      (select(db.localData)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.syncStatus.equals('pending_sync')))
          .get();

  Future<int> totalRowsForTenant(String tenantId) =>
      (selectOnly(db.localData)
            ..addColumns([countAll()])
            ..where(db.localData.tenantId.equals(tenantId)))
          .map((row) => row.read(countAll())!)
          .getSingle();

  Future<void> upsert(LocalDataRecord record) =>
      into(db.localData).insertOnConflictUpdate(
        LocalDataCompanion(
          id: Value(record.id),
          tenantId: Value(record.tenantId),
          moduleId: Value(record.moduleId),
          entityType: Value(record.entityType),
          dataJson: Value(record.dataJson),
          baseUpdatedAt: Value(record.baseUpdatedAt),
          localUpdatedAt: Value(record.localUpdatedAt),
          syncStatus: Value(record.syncStatus),
        ),
      );

  Future<void> upsertCompanion(LocalDataCompanion record) =>
      into(db.localData).insertOnConflictUpdate(record);

  Future<void> deleteById(String id) =>
      (delete(db.localData)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(db.localData).go();

  Future<void> updateSyncStatus(String id, String syncStatus) =>
      (update(db.localData)..where((t) => t.id.equals(id)))
          .write(LocalDataCompanion(
            syncStatus: Value(syncStatus),
            localUpdatedAt: Value(DateTime.now()),
          ));
}
