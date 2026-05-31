import 'package:meta/meta.dart';

import '../canvas_registry/component_schema.dart';

/// Configuration runtime du [ScalarioCanvas].
///
/// STORY-008 — budgets et tailles de cache documentés (NFR-001 architecture).
/// Toutes les valeurs sont des plafonds, pas des cibles.
@immutable
final class ScalarioCanvasConfig {
  const ScalarioCanvasConfig({
    this.screenCacheSize = 20,
    this.coldRenderBudgetMs = 200,
    this.hotRenderBudgetMs = 50,
    this.enableTimeline = true,
    this.schemaValidationMode = SchemaValidationMode.lenient,
  });

  /// Nombre max d'entries dans le cache mémoire LRU `Map<screenId, ScreenConfig>`.
  final int screenCacheSize;

  /// Plafond cold render (cache vide → fixture/Drift → render complet).
  /// Mesuré sur émulateur Snapdragon 680 — AC-07.
  final int coldRenderBudgetMs;

  /// Plafond hot render (cache mémoire hit) — AC-08.
  final int hotRenderBudgetMs;

  /// Active `Timeline.timeSync` pour profiling Flutter DevTools — AC-09.
  /// `false` en `kReleaseMode` pour zero overhead production.
  final bool enableTimeline;

  /// Mode de validation des schémas de composants.
  ///
  /// - [SchemaValidationMode.strict] : throw au premier échec.
  /// - [SchemaValidationMode.lenient] : log les erreurs, continue le rendu.
  final SchemaValidationMode schemaValidationMode;

  static const ScalarioCanvasConfig defaults = ScalarioCanvasConfig();
}
