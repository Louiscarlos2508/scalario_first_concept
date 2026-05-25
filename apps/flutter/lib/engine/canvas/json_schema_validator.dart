import '../error_boundary/bdui_error_boundary.dart';

/// Validateur structurel d'un `ScreenConfig` JSON.
///
/// STORY-008 — Sprint 2 : implémentation **structurelle minimaliste** (pas de
/// JSON Schema officiel encore — STORY-023 le fournira et `JsonSchemaValidator`
/// sera remplacé par un wrapper `json_schema_dart` sans changer l'API.
///
/// Vérifications Phase 1 (AC-11, AC-12) :
/// - `screen` : string non-vide
/// - `schema_version` : string, format `vX.Y.Z` ou `X.Y.Z` toléré
/// - `layout` : ∈ { dashboard, list, form, detail }
/// - `zones` : object (si présent)
/// - Pour chaque component dans chaque zone : `type` string non-vide
///
/// Erreur → [BDUIValidationException] avec `jsonPath` pointant le noeud fautif.
abstract interface class JsonSchemaValidator {
  /// Valide un screen JSON brut. Throw [BDUIValidationException] sur échec.
  void validateScreen(Map<String, dynamic> json);
}

/// Implémentation structurelle Sprint 2.
final class StructuralScreenValidator implements JsonSchemaValidator {
  const StructuralScreenValidator();

  static const Set<String> _allowedLayouts = <String>{
    'dashboard',
    'list',
    'form',
    'detail',
  };

  static const List<String> _zoneNames = <String>[
    'kpis',
    'main',
    'aside',
    'actions',
  ];

  @override
  void validateScreen(Map<String, dynamic> json) {
    final Object? screen = json['screen'];
    if (screen is! String || screen.isEmpty) {
      throw const BDUIValidationException(
        'Field "screen" is required and must be a non-empty string',
        jsonPath: 'screen',
      );
    }

    final Object? schemaVersion = json['schema_version'];
    if (schemaVersion is! String || schemaVersion.isEmpty) {
      throw const BDUIValidationException(
        'Field "schema_version" is required and must be a non-empty string',
        jsonPath: 'schema_version',
      );
    }

    final Object? layout = json['layout'];
    if (layout is! String || !_allowedLayouts.contains(layout)) {
      throw BDUIValidationException(
        'Field "layout" must be one of $_allowedLayouts (got: $layout)',
        jsonPath: 'layout',
      );
    }

    final Object? zones = json['zones'];
    if (zones != null) {
      if (zones is! Map<String, dynamic>) {
        throw const BDUIValidationException(
          'Field "zones" must be an object',
          jsonPath: 'zones',
        );
      }
      for (final String zoneName in _zoneNames) {
        final Object? zone = zones[zoneName];
        if (zone == null) continue;
        if (zone is! List) {
          throw BDUIValidationException(
            'Field "zones.$zoneName" must be an array of component configs',
            jsonPath: 'zones.$zoneName',
          );
        }
        for (int i = 0; i < zone.length; i++) {
          final Object? component = zone[i];
          if (component is! Map<String, dynamic>) {
            throw BDUIValidationException(
              'Component must be an object',
              jsonPath: 'zones.$zoneName[$i]',
            );
          }
          final Object? type = component['type'];
          if (type is! String || type.isEmpty) {
            throw BDUIValidationException(
              'Component "type" is required and must be a non-empty string',
              jsonPath: 'zones.$zoneName[$i].type',
            );
          }
        }
      }
    }
  }
}
