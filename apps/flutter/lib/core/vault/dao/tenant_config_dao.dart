import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/tenant_configs.dart';

/// DAO pour [TenantConfigs] — config tenant chiffrée.
///
/// La table contient exactement 1 ligne (le tenant actif).
/// Sur `insertOrReplace`, le singleton tenant est mis à jour.
final class TenantConfigDao extends DatabaseAccessor<ScalarioDatabase> {
  TenantConfigDao(super.attachedDatabase);

  Future<TenantConfig?> getActive() =>
      (select(db.tenantConfigs)..limit(1)).getSingleOrNull();

  Future<void> upsert(TenantConfigsCompanion config) =>
      into(db.tenantConfigs).insertOnConflictUpdate(config);

  Future<void> deleteAll() => delete(db.tenantConfigs).go();
}
