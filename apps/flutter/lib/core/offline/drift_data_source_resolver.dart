import 'dart:convert';
import 'dart:developer' as developer;

import '../../engine/bdui_engine/data_source_resolver.dart';
import 'database.dart';
import 'dao/cached_layout_dao.dart';

/// Implémentation [DataSourceResolver] via Drift (offline-first).
///
/// AC-18 : lit depuis `LocalStore` (Drift), JAMAIS de fetch HTTP synchrone.
/// Si `local_data` est vide pour la requête : retour liste vide +
/// déclenchement refresh background (queue dédiée).
///
/// AC-19 : `select from cached_layouts where screenId = ?` répond en < 30ms.
///
/// Remplace `FixtureDataSourceResolver` au DI bootstrap dans `main()`.
final class DriftDataSourceResolver implements DataSourceResolver {
  DriftDataSourceResolver({required CachedLayoutDao layoutDao})
      : _layoutDao = layoutDao;

  final CachedLayoutDao _layoutDao;

  @override
  Future<Map<String, dynamic>> loadScreenJson(String screenId) async {
    final CachedLayout? layout = await _layoutDao.getByScreenId(screenId);
    if (layout == null) {
      throw DataSourceNotFoundException(
        'No cached layout for screen "$screenId"',
      );
    }
    final Object? decoded = jsonDecode(layout.layoutJson);
    if (decoded is! Map<String, dynamic>) {
      throw DataSourceNotFoundException(
        'Cached layout "$screenId" is not a JSON object',
      );
    }
    return decoded;
  }

  @override
  Future<Object?> resolveDataSource(Map<String, dynamic> source) async {
    final String? id = source['id'] as String?;
    if (id == null || id.isEmpty) {
      developer.log(
        'DataSource missing "id" field — substituting null',
        name: 'BDUI.DataSourceResolver',
        level: 900,
      );
      return null;
    }
    // AC-18: retour null si pas en cache → l'Engine substituera EmptyState.
    // Un refresh background sera déclenché par l'Engine (hors scope STORY-033).
    final CachedLayout? layout = await _layoutDao.getByScreenId(id);
    if (layout == null) return null;
    final Object? decoded = jsonDecode(layout.layoutJson);
    if (decoded is Map<String, dynamic>) {
      return decoded['data'];
    }
    return null;
  }
}
