import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';

import 'auth_storage.dart';
import 'dao/cached_layout_dao.dart';
import 'dao/local_data_dao.dart';
import 'dao/tenant_config_dao.dart';
import 'database.dart';

/// Exception levée quand le bootstrap initial échoue définitivement.
final class BootstrapFailedException implements Exception {
  const BootstrapFailedException(this.reason);
  final String reason;
  @override
  String toString() => 'BootstrapFailedException: $reason';
}

/// Service de bootstrap initial (premier lancement, online obligatoire).
///
/// AC-15 : appelle `GET /api/v1/{tenantSlug}/bootstrap` → écrit en transaction
/// Drift atomique (tout ou rien).
/// AC-16 : retry 3x avec backoff exponentiel (1s → 4s → 16s).
/// AC-17 : après succès, `tenantConfigs` + `cachedLayouts` + `localData`
/// contiennent au moins 1 entrée chacun.
final class BootstrapService {
  BootstrapService({
    required this.db,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final ScalarioDatabase db;
  final HttpClient _httpClient;

  static const int _maxRetries = 3;
  static const List<int> _backoffSeconds = [1, 4, 16];

  /// AC-15, AC-16 — fetch initial avec retry + backoff.
  Future<void> fetchInitial({
    required String tenantSlug,
    required String baseUrl,
  }) async {
    final String? accessToken = await AuthStorage().readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const BootstrapFailedException(
        'No access token available — user must login first',
      );
    }

    final Uri uri = Uri.parse('$baseUrl/api/v1/$tenantSlug/bootstrap');

    Map<String, dynamic>? bootstrapData;
    Exception? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final HttpClientRequest request = await _httpClient.getUrl(uri);
        request.headers
          ..set('Authorization', 'Bearer $accessToken')
          ..set('Content-Type', 'application/json');
        final HttpClientResponse response = await request.close();
        final String body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final Object? decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            bootstrapData = decoded;
            break;
          }
          lastError = const FormatException(
            'Bootstrap response is not a JSON object',
          );
        } else {
          lastError = Exception(
            'Bootstrap returned ${response.statusCode}: $body',
          );
        }
      } catch (e) {
        lastError = e is Exception
            ? e
            : Exception('Bootstrap attempt $attempt failed: $e');
      }

      if (attempt < _maxRetries - 1) {
        developer.log(
          'Bootstrap attempt ${attempt + 1}/$_maxRetries failed, '
          'retrying in ${_backoffSeconds[attempt]}s: $lastError',
          name: 'Scalario.Offline.Bootstrap',
          level: 800,
        );
        await Future<void>.delayed(
          Duration(seconds: _backoffSeconds[attempt]),
        );
      }
    }

    if (bootstrapData == null) {
      _httpClient.close();
      throw BootstrapFailedException(
        lastError?.toString() ?? 'Unknown bootstrap error',
      );
    }

    try {
      await _writeBootstrapData(bootstrapData, tenantSlug);
    } finally {
      _httpClient.close();
    }
  }

  /// AC-15, AC-17 — écriture atomique en transaction unique.
  Future<void> _writeBootstrapData(
    Map<String, dynamic> data,
    String tenantSlug,
  ) async {
    await db.transaction(() async {
      final TenantConfigDao configDao = TenantConfigDao(db);
      final CachedLayoutDao layoutDao = CachedLayoutDao(db);
      final LocalDataDao dataDao = LocalDataDao(db);

      // 1. Tenant config
      final Map<String, dynamic> tenantConfig =
          (data['tenant_config'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
      await configDao.upsert(TenantConfigsCompanion(
        tenantId: Value(tenantConfig['tenant_id'] as String? ?? tenantSlug),
        slug: Value(tenantSlug),
        configJson: Value(jsonEncode(tenantConfig)),
        cacheLimitMb: Value(
          (tenantConfig['cache_limit_mb'] as int?) ?? 500,
        ),
        version: Value(tenantConfig['version'] as String? ?? '1'),
        lastFetchAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. Cached layouts
      final List<dynamic> layouts =
          (data['layouts'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic layout in layouts) {
        if (layout is Map<String, dynamic>) {
          final String layoutJson = jsonEncode(layout);
          await layoutDao.upsert(CachedLayoutsCompanion(
            screenId: Value(layout['screen_id'] as String? ?? 'unknown'),
            tenantId: Value(tenantSlug),
            layoutJson: Value(layoutJson),
            etag: Value(layout['etag'] as String?),
            lastFetchAt: Value(DateTime.now()),
            bytesSize: Value(layoutJson.length),
          ));
        }
      }

      // 3. Initial data
      final List<dynamic> initialData =
          (data['initial_data'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic record in initialData) {
        if (record is Map<String, dynamic>) {
          final Map<String, dynamic> entityData =
              (record['data'] as Map<String, dynamic>?) ?? record;
          await dataDao.upsertCompanion(LocalDataCompanion(
            id: Value(record['id'] as String? ?? _uuid()),
            tenantId: Value(tenantSlug),
            moduleId: Value(record['module_id'] as String? ?? 'unknown'),
            entityType: Value(record['entity_type'] as String? ?? 'unknown'),
            dataJson: Value(jsonEncode(entityData)),
            baseUpdatedAt: Value(
              record['updated_at'] != null
                  ? DateTime.tryParse(record['updated_at'] as String)
                  : null,
            ),
            localUpdatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
          ));
        }
      }
    });
  }
}

String _uuid() {
  final Random rng = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  return bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .replaceRange(20, 21, '-')
      .replaceRange(16, 17, '-')
      .replaceRange(12, 13, '-')
      .replaceRange(8, 9, '-');
}
