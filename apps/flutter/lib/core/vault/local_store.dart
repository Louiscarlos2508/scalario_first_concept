import 'database.dart';
import 'dao/tenant_config_dao.dart';
import 'dao/cached_layout_dao.dart';
import 'dao/local_data_dao.dart';
import 'dao/sync_queue_dao.dart';
import 'dao/conflict_dao.dart';

/// Façade singleton exposant tous les DAOs au reste de l'app.
///
/// Enregistrée via [GetIt] dans `main()` avant `runApp()`.
/// Chaque DAO est un [DatabaseAccessor] valable toute la durée de vie
/// de la connexion Drift.
final class LocalStore {
  LocalStore(ScalarioDatabase db)
      : tenantConfigDao = TenantConfigDao(db),
        cachedLayoutDao = CachedLayoutDao(db),
        localDataDao = LocalDataDao(db),
        syncQueueDao = SyncQueueDao(db),
        conflictDao = ConflictDao(db);

  final TenantConfigDao tenantConfigDao;
  final CachedLayoutDao cachedLayoutDao;
  final LocalDataDao localDataDao;
  final SyncQueueDao syncQueueDao;
  final ConflictDao conflictDao;
}
