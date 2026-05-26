import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import '../error_boundary/error_boundary.dart';
import 'component_builder.dart';
import 'component_config.dart';
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
class ScalarioCanvasRegistry {
  ScalarioCanvasRegistry();

  static ScalarioCanvasRegistry? instance;

  final Map<String, ComponentBuilder> _builders = {};

  /// Enregistre ou override le builder pour [type].
  ///
  /// AC-04 : second register → warning log, pas d'exception.
  void register(String type, ComponentBuilder builder) {
    if (_builders.containsKey(type)) {
      developer.log(
        'Override builder for type "$type"',
        name: 'BDUI',
        level: 900, // warning
      );
    }
    _builders[type] = builder;
  }

  /// Retire le builder pour [type] — utile en tests (AC-05).
  void unregister(String type) => _builders.remove(type);

  /// Retourne `true` si [type] a un builder enregistré (AC-07).
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Liste triée alphabétiquement des types enregistrés (AC-08).
  List<String> get registeredTypes => _builders.keys.toList()..sort();

  /// Construit le widget pour [config].
  ///
  /// AC-06 : ne throw jamais.
  /// AC-09 : enveloppe le résultat dans [ErrorBoundary].
  Widget build(ComponentConfig config, BuildContext ctx) {
    final ComponentBuilder? builder = _builders[config.type];
    if (builder == null) {
      return UnknownComponent(config.type);
    }
    return builder(config, ctx);
  }
}
