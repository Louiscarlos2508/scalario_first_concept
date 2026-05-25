import 'dart:developer' as developer;

import 'database.dart';
import 'dao/cached_layout_dao.dart';
import 'dao/local_data_dao.dart';
import 'dao/tenant_config_dao.dart';

/// Service LRU de nettoyage du cache `cached_layouts`.
///
/// AC-20 : si la taille totale `cached_layouts` dépasse `cache_limit_mb`,
/// suppression LRU (par `lastFetchAt`) jusqu'à 80% du quota.
///
/// AC-21 : `local_data` n'est PAS soumis au LRU. Si quota global explose,
/// log warning + métrique télémétrie, pas de blocage utilisateur.
final class CacheCleaner {
  CacheCleaner({
    required TenantConfigDao tenantConfigDao,
    required CachedLayoutDao cachedLayoutDao,
    required LocalDataDao localDataDao,
  })  : _tenantConfigDao = tenantConfigDao,
        _cachedLayoutDao = cachedLayoutDao,
        _localDataDao = localDataDao;

  final TenantConfigDao _tenantConfigDao;
  final CachedLayoutDao _cachedLayoutDao;
  final LocalDataDao _localDataDao;

  static const double _targetRatio = 0.8;
  static const int _sizeThresholdBytes = 1024 * 1024;

  /// AC-20 — exécute le nettoyage LRU.
  ///
  /// À appeler au démarrage app + après chaque écriture > 1MB.
  Future<void> cleanIfNeeded() async {
    final TenantConfig? tenant = await _tenantConfigDao.getActive();
    if (tenant == null) return;

    final int limitBytes = tenant.cacheLimitMb * 1024 * 1024;
    final int currentBytes =
        await _cachedLayoutDao.totalBytesForTenant(tenant.tenantId);

    if (currentBytes <= limitBytes) return;

    final int targetBytes = (limitBytes * _targetRatio).toInt();

    developer.log(
      'CacheCleaner: $currentBytes bytes > $limitBytes limit, '
      'LRU eviction to $targetBytes',
      name: 'Scalario.Offline.CacheCleaner',
      level: 800,
    );

    final List<CachedLayout> layouts =
        await _cachedLayoutDao.getLruOrdered(tenant.tenantId);

    int runningBytes = currentBytes;
    for (final CachedLayout layout in layouts) {
      if (runningBytes <= targetBytes) break;
      await _cachedLayoutDao.deleteByScreenId(layout.screenId);
      runningBytes -= layout.bytesSize;
    }
  }

  /// AC-20 — nettoyage déclenché après une écriture.
  Future<void> onLayoutWritten(int bytesWritten) async {
    if (bytesWritten > _sizeThresholdBytes) {
      await cleanIfNeeded();
    }
  }

  /// AC-21 — `local_data` exempté de LRU.
  Future<void> checkLocalDataQuota(int maxRows) async {
    final TenantConfig? tenant = await _tenantConfigDao.getActive();
    if (tenant == null) return;

    final int rowCount =
        await _localDataDao.totalRowsForTenant(tenant.tenantId);

    if (rowCount > maxRows) {
      developer.log(
        'local_data quota warning: $rowCount rows > $maxRows max '
        'for tenant ${tenant.slug}',
        name: 'Scalario.Offline.CacheCleaner',
        level: 900,
      );
    }
  }
}
