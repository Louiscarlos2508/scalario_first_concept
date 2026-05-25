import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Exception levée quand un `screenId` ou un `dataSource` est introuvable.
final class DataSourceNotFoundException implements Exception {
  const DataSourceNotFoundException(this.message);
  final String message;
  @override
  String toString() => 'DataSourceNotFoundException: $message';
}

/// Interface de résolution des sources de données du [ScalarioCanvas].
///
/// STORY-008 Phase 1 — Sprint 2 : implémentation [FixtureDataSourceResolver]
/// qui lit `assets/sandbox/`. STORY-033 Sprint 3 — `DriftDataSourceResolver`
/// remplace au DI bootstrap, l'API reste identique (AC-02).
abstract interface class DataSourceResolver {
  /// Charge un screen JSON brut depuis sa source (fixture / Drift / backend).
  Future<Map<String, dynamic>> loadScreenJson(String screenId);

  /// Résout les données pour un composant qui a un champ `source` dans son
  /// JSON (ex: KPICard pointant vers `kpi_ventes`). Retourne `null` si la
  /// source est inconnue → l'Engine substituera un `EmptyState` (AC-15).
  Future<Object?> resolveDataSource(Map<String, dynamic> source);
}

/// Implémentation Phase 1 — lit `assets/sandbox/<screenId>.json` pour les
/// screens et `assets/sandbox/data/<id>.json` pour les data sources.
final class FixtureDataSourceResolver implements DataSourceResolver {
  FixtureDataSourceResolver({
    AssetBundle? bundle,
    this.screenAssetPrefix = 'assets/sandbox/',
    this.dataAssetPrefix = 'assets/sandbox/data/',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String screenAssetPrefix;
  final String dataAssetPrefix;

  @override
  Future<Map<String, dynamic>> loadScreenJson(String screenId) async {
    final String path = '$screenAssetPrefix$screenId.json';
    try {
      final String raw = await _bundle.loadString(path);
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw DataSourceNotFoundException(
          'Fixture $path is not a JSON object (got ${decoded.runtimeType})',
        );
      }
      return decoded;
    } on DataSourceNotFoundException {
      rethrow;
    } catch (e) {
      throw DataSourceNotFoundException(
        'Failed to load screen fixture $path: $e',
      );
    }
  }

  @override
  Future<Object?> resolveDataSource(Map<String, dynamic> source) async {
    // Phase 1 contract: `source` = { "id": "kpi_ventes", "type": "fixture" }.
    final String? id = source['id'] as String?;
    if (id == null || id.isEmpty) {
      developer.log(
        'DataSource missing "id" field — substituting null',
        name: 'BDUI.DataSourceResolver',
        level: 900,
      );
      return null;
    }
    final String path = '$dataAssetPrefix$id.json';
    try {
      final String raw = await _bundle.loadString(path);
      return jsonDecode(raw);
    } catch (e) {
      developer.log(
        'DataSource $id not found at $path: $e',
        name: 'BDUI.DataSourceResolver',
        level: 900,
      );
      return null;
    }
  }
}

/// Stub in-memory pour tests unitaires et goldens.
///
/// Permet d'injecter screens et data fixtures sans toucher `rootBundle`.
final class InMemoryDataSourceResolver implements DataSourceResolver {
  InMemoryDataSourceResolver({
    Map<String, Map<String, dynamic>>? screens,
    Map<String, Object?>? dataSources,
  })  : _screens = <String, Map<String, dynamic>>{...?screens},
        _dataSources = <String, Object?>{...?dataSources};

  final Map<String, Map<String, dynamic>> _screens;
  final Map<String, Object?> _dataSources;

  void registerScreen(String screenId, Map<String, dynamic> json) {
    _screens[screenId] = json;
  }

  void registerDataSource(String id, Object? value) {
    _dataSources[id] = value;
  }

  @override
  Future<Map<String, dynamic>> loadScreenJson(String screenId) async {
    final Map<String, dynamic>? json = _screens[screenId];
    if (json == null) {
      throw DataSourceNotFoundException('No in-memory screen "$screenId"');
    }
    return json;
  }

  @override
  Future<Object?> resolveDataSource(Map<String, dynamic> source) async {
    final String? id = source['id'] as String?;
    if (id == null) return null;
    return _dataSources[id];
  }
}
