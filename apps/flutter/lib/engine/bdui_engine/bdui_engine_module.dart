import 'package:get_it/get_it.dart';

import '../../core/bdui/validation/bdui_validator.dart' as bdui;
import '../component_registry/component_registry.dart';
import '../layout_resolver/layout_resolver.dart';
import '../rule_evaluator/rule_evaluator.dart';
import 'bdui_engine.dart';
import 'bdui_engine_config.dart';
import 'data_source_resolver.dart';
import 'json_schema_validator.dart';
import 'user_context_provider.dart';

/// Bootstrap DI du `BDUIEngine` — AC-05.
///
/// Doit être appelé **après** [RegistryBootstrap.registerPhase1] et après
/// l'enregistrement de [LayoutResolver]. Consomme les singletons existants.
abstract final class BDUIEngineModule {
  /// Enregistre toutes les dépendances de l'Engine sur le [GetIt] fourni.
  ///
  /// Paramètres surchargeables pour tests/showcase :
  /// - [dataResolver] — défaut `FixtureDataSourceResolver` (assets/sandbox/).
  /// - [userContextProvider] — défaut `DemoUserContextProvider` (OWNER demo).
  /// - [validator] — défaut `StructuralScreenValidator` (Phase 1).
  /// - [config] — défaut `BDUIEngineConfig.defaults`.
  /// Initialise le [BduiValidator] singleton (charge les schémas depuis
  /// les assets) puis enregistre toutes les dépendances de l'Engine.
  ///
  /// Doit être appelée avec `await` dans `main()`.
  static Future<void> register(
    GetIt getIt, {
    DataSourceResolver? dataResolver,
    UserContextProvider? userContextProvider,
    JsonSchemaValidator? validator,
    BDUIEngineConfig config = BDUIEngineConfig.defaults,
  }) async {
    // STORY-026 — initialiser le validateur JSON Schema avant tout rendu.
    // Les schémas sont chargés une seule fois depuis assets/bdui-schemas/.
    await bdui.BduiValidator.init();

    final DataSourceResolver resolver =
        dataResolver ?? FixtureDataSourceResolver();
    final UserContextProvider userCtx =
        userContextProvider ?? const DemoUserContextProvider();
    final JsonSchemaValidator schemaValidator =
        validator ?? const StructuralScreenValidator();

    getIt
      ..registerSingleton<DataSourceResolver>(resolver)
      ..registerSingleton<UserContextProvider>(userCtx)
      ..registerSingleton<JsonSchemaValidator>(schemaValidator)
      ..registerSingleton<BDUIEngineConfig>(config)
      ..registerSingleton<BDUIEngine>(
        BDUIEngine(
          registry: getIt<ComponentRegistry>(),
          evaluator: const RuleEvaluator(),
          layoutResolver: getIt<LayoutResolver>(),
          dataResolver: resolver,
          userContextProvider: userCtx,
          validator: schemaValidator,
          config: config,
        ),
      );
  }
}
