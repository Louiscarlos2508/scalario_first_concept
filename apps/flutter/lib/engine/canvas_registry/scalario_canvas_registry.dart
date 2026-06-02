import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import '../error_boundary/error_boundary.dart';
import 'component_builder.dart';
import 'component_config.dart';
import 'component_schema.dart';
import 'unknown_component.dart';

/// Registry extensible — mappe un `type` string vers un [ComponentBuilder].
///
/// Contrat fort :
/// - [build] ne throw jamais : un type inconnu retourne [UnknownComponent].
/// - Un second [register] sur le même type override silencieusement
///   (utile pour hot reload dev) avec un warning log (AC-04).
/// - [registeredTypes] retourne la liste triée alphabétiquement (AC-08).
///
/// Usage DI (singleton via get_it) :
/// ```dart
/// final registry = ScalarioCanvasRegistry();
/// GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
/// RegistryBootstrap.registerPhase1(registry);
/// ```
/// Registry extensible — mappe un `type` string vers un [ComponentBuilder].
///
/// Contrat fort :
/// - [build] ne throw jamais : un type inconnu retourne [UnknownComponent].
/// - Un second [register] sur le même type override silencieusement
///   (utile pour hot reload dev) avec un warning log (AC-04).
/// - [registeredTypes] retourne la liste triée alphabétiquement (AC-08).
///
/// Validation de schéma :
/// - Chaque composant peut avoir un [ComponentSchema] optionnel.
/// - [validate] compare un [ComponentConfig] au schéma enregistré.
/// - [SchemaValidationMode.strict] throw sur la première erreur.
/// - [SchemaValidationMode.lenient] collecte toutes les erreurs sans throw.
///
/// Usage DI (singleton via get_it) :
/// ```dart
/// final registry = ScalarioCanvasRegistry();
/// GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
/// RegistryBootstrap.registerPhase1(registry);
/// ```
class ScalarioCanvasRegistry {
  ScalarioCanvasRegistry();

  static ScalarioCanvasRegistry? instance;

  final Map<String, ComponentBuilder> _builders = {};
  final Map<String, ComponentSchema> _schemas = {};
  final Map<String, String> _aliases = {};

  /// Enregistre ou override le builder pour [type].
  ///
  /// AC-04 : second register → warning log, pas d'exception.
  void register(String type, ComponentBuilder builder, {ComponentSchema? schema}) {
    if (_builders.containsKey(type)) {
      developer.log(
        'Override builder for type "$type"',
        name: 'BDUI',
        level: 900, // warning
      );
    }
    _builders[type] = builder;
    if (schema != null) {
      _schemas[type] = schema;
    }
  }

  /// Enregistre un alias [alias] pointant vers [targetType].
  void registerAlias(String alias, String targetType) {
    _aliases[alias] = targetType;
    if (_builders.containsKey(targetType)) {
      _builders[alias] = _builders[targetType]!;
    }
  }

  /// Retourne le schéma enregistré pour [type], ou `null`.
  ComponentSchema? schema(String type) => _schemas[type];

  /// Valide [config] contre le schéma enregistré.
  ///
  /// Retourne une liste (vide si tout est ok).
  /// En mode [SchemaValidationMode.strict], throw [SchemaValidationException]
  /// dès la première erreur.
  List<SchemaValidationError> validate(
    ComponentConfig config, {
    SchemaValidationMode mode = SchemaValidationMode.lenient,
  }) {
    final errors = <SchemaValidationError>[];
    final s = _schemas[config.type];
    if (s == null) return errors;

    final props = config.props;

    // Required props
    for (final def in s.props) {
      if (!def.required) continue;
      final value = props[def.name];
      if (value == null || (value is String && value.isEmpty)) {
        errors.add(SchemaValidationError(
          componentId: config.id ?? '',
          type: config.type,
          field: def.name,
          message: 'Required property "${def.name}" is missing',
        ));
      }
    }

    // Type checking & allowed values
    for (final def in s.props) {
      if (!props.containsKey(def.name)) continue;
      final value = props[def.name];
      if (value == null) continue;

      if (def.allowedValues != null && def.allowedValues!.isNotEmpty) {
        if (!def.allowedValues!.contains(value)) {
          errors.add(SchemaValidationError(
            componentId: config.id ?? '',
            type: config.type,
            field: def.name,
            message: '"${def.name}" value "$value" is not allowed. Allowed: ${def.allowedValues!.join(', ')}',
          ));
        }
      }
    }

    // Children bounds
    if (s.minChildren != null) {
      final count = config.children?.length ?? 0;
      if (count < s.minChildren!) {
        errors.add(SchemaValidationError(
          componentId: config.id ?? '',
          type: config.type,
          message: 'Minimum ${s.minChildren} child(ren) required, got $count',
        ));
      }
    }
    if (s.maxChildren != null) {
      final count = config.children?.length ?? 0;
      if (count > s.maxChildren!) {
        errors.add(SchemaValidationError(
          componentId: config.id ?? '',
          type: config.type,
          message: 'Maximum ${s.maxChildren} child(ren) allowed, got $count',
        ));
      }
    }

    if (mode == SchemaValidationMode.strict && errors.isNotEmpty) {
      throw SchemaValidationException(errors);
    }

    return errors;
  }

  /// Retire le builder et le schéma pour [type] — utile en tests (AC-05).
  void unregister(String type) {
    _builders.remove(type);
    _schemas.remove(type);
    _aliases.removeWhere((_, v) => v == type);
  }

  /// Retourne `true` si [type] a un builder enregistré (AC-07).
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Liste triée alphabétiquement des types enregistrés (AC-08).
  List<String> get registeredTypes => _builders.keys.toList()..sort();

  /// Liste des alias enregistrés.
  Map<String, String> get aliases => Map.unmodifiable(_aliases);

  /// Dernières erreurs de validation par screenId — utilisée par le debug overlay.
  final Map<String, List<SchemaValidationError>> _lastValidationErrors = {};

  /// Enregistre les erreurs de validation pour [screenId].
  void recordValidationErrors(String screenId, List<SchemaValidationError> errors) {
    _lastValidationErrors[screenId] = errors;
  }

  /// Retourne les dernières erreurs de validation pour [screenId].
  List<SchemaValidationError> lastValidationErrors(String screenId) =>
      _lastValidationErrors[screenId] ?? const [];

  /// Liste de tous les screenIds avec des erreurs de validation.
  List<String> get screensWithErrors =>
      _lastValidationErrors.keys.where((k) => _lastValidationErrors[k]!.isNotEmpty).toList();

  /// Construit le widget pour [config].
  ///
  /// AC-06 : ne throw jamais.
  /// AC-09 : enveloppe le résultat dans [ErrorBoundary].
  Widget build(ComponentConfig config, BuildContext ctx, [String zone = '']) {
    final ComponentBuilder? builder = _builders[config.type];
    if (builder == null) {
      return UnknownComponent(config.type);
    }

    if (config.actions != null && config.actions!.isNotEmpty) {
      final errors = validate(config, mode: SchemaValidationMode.strict);
      if (errors.isNotEmpty) {
        return UnknownComponent(config.type, message: errors.first.message);
      }
    }

    return ErrorBoundary(componentType: config.type, child: builder(config, ctx));
  }
}

/// Exception levée par [ScalarioCanvasRegistry.validate] en mode strict.
class SchemaValidationException implements Exception {
  final List<SchemaValidationError> errors;
  const SchemaValidationException(this.errors);

  @override
  String toString() {
    final buf = StringBuffer('SchemaValidationException (${errors.length} error(s)):\n');
    for (final e in errors) {
      buf.writeln('  $e');
    }
    return buf.toString();
  }
}
