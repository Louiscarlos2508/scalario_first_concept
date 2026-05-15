import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import '../component_registry/component_config.dart';
import '../component_registry/component_registry.dart';
import '../error_boundary/bdui_error_boundary.dart';
import '../layout_resolver/layout_resolver.dart';
import '../rule_evaluator/rule_evaluator.dart';
import 'bdui_engine_config.dart';
import 'data_source_resolver.dart';
import 'json_schema_validator.dart';
import 'perf_metrics.dart';
import 'screen_cache.dart';
import 'user_context_provider.dart';

/// Chef d'orchestre du Backend-Driven UI Flutter.
///
/// Pipeline `render(config, ctx)` (AC-04) — ordre strict :
///   1. **Parse + validate** : exécutés à `loadScreen` (cache-aware).
///   2. **Rules** : `RuleEvaluator` filtre les composants `visible_if = false`.
///   3. **Data** : les sources sont résolues à `loadScreen` (Phase 1) puis
///      injectées dans `props['_data']` ; pour Phase 3 (Drift), la résolution
///      bascule en runtime via DI sans toucher l'API.
///   4. **Components** : instanciés à la demande par le `LayoutResolver` via
///      le `ComponentRegistry`.
///   5. **Layout** : `LayoutResolver.resolve` structure les zones.
///   6. Le tout enveloppé dans un `BDUIErrorBoundary` global (STORY-010).
///
/// Aucune logique métier dans ce package (AC-06).
@immutable
final class BDUIEngine {
  BDUIEngine({
    required this.registry,
    required this.evaluator,
    required this.layoutResolver,
    required this.dataResolver,
    required this.userContextProvider,
    required this.validator,
    this.config = BDUIEngineConfig.defaults,
  })  : _cache = ScreenCache(maxSize: config.screenCacheSize),
        _metrics = PerfMetrics(config: config);

  final ComponentRegistry registry;
  final RuleEvaluator evaluator;
  final LayoutResolver layoutResolver;
  final DataSourceResolver dataResolver;
  final UserContextProvider userContextProvider;
  final JsonSchemaValidator validator;
  final BDUIEngineConfig config;

  final ScreenCache _cache;
  final PerfMetrics _metrics;

  @visibleForTesting
  ScreenCache get cache => _cache;

  /// Charge un screen depuis le cache mémoire, sinon depuis le
  /// [DataSourceResolver]. Valide le JSON, résout les sources de données des
  /// composants, met en cache (AC-02).
  Future<ScreenConfig> loadScreen(String screenId) {
    return _metrics.timeSyncAsync('loadScreen', () async {
      final ScreenConfig? cached = _cache.get(screenId);
      if (cached != null) return cached;

      final Map<String, dynamic> raw = await _metrics
          .timeSyncAsync('parse', () => dataResolver.loadScreenJson(screenId));
      _metrics.timeSync('validate', () => validator.validateScreen(raw));
      final ScreenConfig parsed = ScreenConfig.fromJson(raw);
      final ScreenConfig enriched =
          await _metrics.timeSyncAsync('data', () => _resolveData(parsed));
      _cache.put(screenId, enriched);
      return enriched;
    });
  }

  /// Vide le cache mémoire — utile au logout (sécurité multi-tenant).
  void invalidate() => _cache.clear();

  /// Pipeline `render` synchrone (AC-01, AC-04).
  Widget render(ScreenConfig config, BuildContext ctx) {
    return _metrics.timeSync('render', () {
      try {
        final ScreenConfig filtered = _metrics.timeSync(
          'rules',
          () => _filterByVisibility(config, userContextProvider.current),
        );
        final Widget tree = _metrics.timeSync(
          'layout',
          () => layoutResolver.resolve(filtered.layout, filtered, ctx),
        );
        return BDUIErrorBoundary(
          screenId: config.screen,
          child: tree,
        );
      } catch (e, st) {
        _logRenderError(config.screen, e, st);
        rethrow;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<ScreenConfig> _resolveData(ScreenConfig parsed) async {
    final ScreenZones zones = parsed.zones;
    final List<ComponentConfig>? kpis = await _resolveZoneData(zones.kpis);
    final List<ComponentConfig>? main = await _resolveZoneData(zones.main);
    final List<ComponentConfig>? aside = await _resolveZoneData(zones.aside);
    final List<ComponentConfig>? actions =
        await _resolveZoneData(zones.actions);
    return ScreenConfig(
      screen: parsed.screen,
      schemaVersion: parsed.schemaVersion,
      layout: parsed.layout,
      title: parsed.title,
      i18nKey: parsed.i18nKey,
      zones: ScreenZones(
        kpis: kpis,
        main: main,
        aside: aside,
        actions: actions,
      ),
    );
  }

  Future<List<ComponentConfig>?> _resolveZoneData(
    List<ComponentConfig>? zone,
  ) async {
    if (zone == null) return null;
    final List<ComponentConfig> out = <ComponentConfig>[];
    for (final ComponentConfig component in zone) {
      if (component.source == null) {
        out.add(component);
        continue;
      }
      try {
        final Object? data =
            await dataResolver.resolveDataSource(component.source!);
        if (data == null) {
          out.add(component); // AC-15 — substitute null silently, no crash.
          continue;
        }
        final Map<String, dynamic> nextProps =
            Map<String, dynamic>.from(component.props)..['_data'] = data;
        out.add(component.copyWith(props: nextProps));
      } catch (e, st) {
        developer.log(
          'DataSource resolution failed for ${component.type}#${component.id}',
          name: 'BDUI.Engine',
          level: 1000,
          error: e,
          stackTrace: st,
        );
        out.add(component);
      }
    }
    return out;
  }

  ScreenConfig _filterByVisibility(ScreenConfig parsed, UserContext userCtx) {
    final ScreenZones z = parsed.zones;
    return ScreenConfig(
      screen: parsed.screen,
      schemaVersion: parsed.schemaVersion,
      layout: parsed.layout,
      title: parsed.title,
      i18nKey: parsed.i18nKey,
      zones: ScreenZones(
        kpis: _filterZone(z.kpis, userCtx),
        main: _filterZone(z.main, userCtx),
        aside: _filterZone(z.aside, userCtx),
        actions: _filterZone(z.actions, userCtx),
      ),
    );
  }

  List<ComponentConfig>? _filterZone(
    List<ComponentConfig>? zone,
    UserContext userCtx,
  ) {
    if (zone == null) return null;
    final List<ComponentConfig> out = <ComponentConfig>[];
    for (final ComponentConfig c in zone) {
      if (c.visibleIf == null) {
        out.add(c);
        continue;
      }
      try {
        final Rule rule = Rule.fromJson(c.visibleIf!);
        if (evaluator.evaluate(rule, userCtx)) {
          out.add(c);
        }
      } catch (e, st) {
        developer.log(
          'visible_if parse failure for ${c.type}#${c.id} — defaulting hidden',
          name: 'BDUI.Engine',
          level: 900,
          error: e,
          stackTrace: st,
        );
        // Fail-closed for malformed visible_if (defensive).
      }
    }
    return out.isEmpty ? null : out;
  }

  void _logRenderError(String screenId, Object error, StackTrace st) {
    developer.log(
      'BDUI render failure for screen=$screenId step=render',
      name: 'BDUI.Engine',
      level: 1000,
      error: error,
      stackTrace: st,
    );
  }
}
