/// Barrel export du package `bdui_engine` (STORY-008).
///
/// Consommé par `main.dart`, les tests et les routes Flutter via :
/// ```dart
/// import 'package:scalario/engine/canvas/bdui_engine_exports.dart';
/// ```
library;

export 'scalario_canvas.dart';
export 'scalario_canvas_config.dart';
export 'scalario_canvas_module.dart';
export 'bdui_error_screen.dart';
export 'bdui_invalid_payload_exception.dart';
export 'bdui_screen.dart';
export 'data_source_resolver.dart';
export 'json_schema_validator.dart';
export 'perf_metrics.dart';
export 'screen_cache.dart';
export 'user_context_provider.dart';
