import 'package:get_it/get_it.dart';

import '../../core/bdui/validation/bdui_validator.dart' as bdui;
import '../canvas_registry/scalario_canvas_registry.dart';
import '../canvas_layout/scalario_canvas_layout.dart';
import '../canvas_rule/scalario_canvas_rule.dart';
import 'scalario_canvas.dart';
import 'scalario_canvas_config.dart';
import 'data_source_resolver.dart';
import 'json_schema_validator.dart';
import 'user_context_provider.dart';

/// Bootstrap DI du `ScalarioCanvas` — AC-05.
///
/// Doit être appelé **après** [RegistryBootstrap.registerPhase1] et après
/// l'enregistrement de [ScalarioCanvasLayout]. Consomme les singletons existants.
abstract final class ScalarioCanvasModule {
  /// Enregistre toutes les dépendances de l'Engine sur le [GetIt] fourni.
  ///
  /// Paramètres surchargeables pour tests/showcase :
  /// - [dataResolver] — défaut `FixtureDataSourceResolver` (assets/sandbox/).
  /// - [userContextProvider] — défaut `DemoUserContextProvider` (OWNER demo).
  /// - [validator] — défaut `StructuralScreenValidator` (Phase 1).
  /// - [config] — défaut `ScalarioCanvasConfig.defaults`.
  /// Initialise le [BduiValidator] singleton (charge les schémas depuis
  /// les assets) puis enregistre toutes les dépendances de l'Engine.
  ///
  /// Doit être appelée avec `await` dans `main()`.
  static Future<void> register(
    GetIt getIt, {
    DataSourceResolver? dataResolver,
    UserContextProvider? userContextProvider,
    JsonSchemaValidator? validator,
    ScalarioCanvasConfig config = ScalarioCanvasConfig.defaults,
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
      ..registerSingleton<ScalarioCanvasConfig>(config)
      ..registerSingleton<ScalarioCanvas>(
        ScalarioCanvas(
          registry: getIt<ScalarioCanvasRegistry>(),
          evaluator: const ScalarioCanvasRule(),
          layoutResolver: getIt<ScalarioCanvasLayout>(),
          dataResolver: resolver,
          userContextProvider: userCtx,
          validator: schemaValidator,
          config: config,
        ),
      );
  }
}
