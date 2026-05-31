import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/widgets.dart';

import '../../core/bdui/validation/bdui_type.dart';
import '../../core/bdui/validation/bdui_validator.dart' as bdui;
import '../../core/bdui/validation/validation_result.dart';
import '../../core/bdui/fallback_screen.dart';
import '../canvas_registry/component_config.dart';
import '../canvas_registry/component_schema.dart';
import '../canvas_registry/scalario_canvas_registry.dart';
import '../error_boundary/bdui_error_boundary.dart';
import '../error_boundary/error_logger.dart';
import '../error_boundary/error_payload.dart';
import '../canvas_layout/scalario_canvas_layout.dart';
import '../canvas_rule/scalario_canvas_rule.dart';
import 'scalario_canvas_config.dart';
import 'bdui_invalid_payload_exception.dart';
import 'data_source_resolver.dart';
import 'json_schema_validator.dart';
import 'perf_metrics.dart';
import 'screen_cache.dart';
import 'user_context_provider.dart';

/// Chef d'orchestre du Backend-Driven UI Flutter.
///
/// Pipeline `render(config, ctx)` (AC-04) — ordre strict :
///   1. **Parse + validate** : exécutés à `loadScreen` (cache-aware).
///   2. **Rules** : `ScalarioCanvasRule` filtre les composants `visible_if = false`.
///   3. **Data** : les sources sont résolues à `loadScreen` (Phase 1) puis
///      injectées dans `props['_data']` ; pour Phase 3 (Drift), la résolution
///      bascule en runtime via DI sans toucher l'API.
///   4. **Components** : instanciés à la demande par le `ScalarioCanvasLayout` via
///      le `ScalarioCanvasRegistry`.
///   5. **Layout** : `ScalarioCanvasLayout.resolve` structure les zones.
///   6. Le tout enveloppé dans un `BDUIErrorBoundary` global (STORY-010).
///
/// Aucune logique métier dans ce package (AC-06).
@immutable
final class ScalarioCanvas {
  ScalarioCanvas({
    required this.registry,
    required this.evaluator,
    required this.layoutResolver,
    required this.dataResolver,
    required this.userContextProvider,
    required this.validator,
    this.config = ScalarioCanvasConfig.defaults,
  })  : _cache = ScreenCache(maxSize: config.screenCacheSize),
        _metrics = PerfMetrics(config: config);

  final ScalarioCanvasRegistry registry;
  final ScalarioCanvasRule evaluator;
  final ScalarioCanvasLayout layoutResolver;
  final DataSourceResolver dataResolver;
  final UserContextProvider userContextProvider;
  final JsonSchemaValidator validator;
  final ScalarioCanvasConfig config;

  final ScreenCache _cache;
  final PerfMetrics _metrics;

  @visibleForTesting
  ScreenCache get cache => _cache;

  /// Charge un screen depuis le cache mémoire, sinon depuis le
  /// [DataSourceResolver]. Valide le JSON, résout les sources de données des
  /// composants, met en cache (AC-02).
  ///
  /// STORY-026 : validation JSON Schema via [BduiValidator] AVANT parsing.
  /// Si invalide, log structuré + throw [BduiInvalidPayloadException] — le
  /// caller (BDUIScreen) capture et affiche [FallbackScreen].
  Future<ScreenConfig> loadScreen(String screenId) {
    return _metrics.timeSyncAsync('loadScreen', () async {
      final ScreenConfig? cached = _cache.get(screenId);
      if (cached != null) return cached;

      final Map<String, dynamic> raw = await _metrics
          .timeSyncAsync('fetch', () => dataResolver.loadScreenJson(screenId));

      _metrics.timeSync('bdui-validate', () => _validateWithBdui(raw, screenId));

      _metrics.timeSync('structural-validate', () => validator.validateScreen(raw));
      final ScreenConfig parsed = ScreenConfig.fromJson(raw);
      final ScreenConfig enriched =
          await _metrics.timeSyncAsync('data', () => _resolveData(parsed));
      _metrics.timeSync('schema-validate', () => _validateSchemas(enriched, screenId));
      _cache.put(screenId, enriched);
      return enriched;
    });
  }

  void _validateWithBdui(Map<String, dynamic> raw, String screenId) {
    if (!bdui.BduiValidator.isInitialized) {
      developer.log(
        'BduiValidator not initialized — skipping JSON Schema validation',
        name: 'BDUI.Validation',
        level: 900,
      );
      return;
    }
    final result = bdui.BduiValidator.I.validate(raw, BduiType.screenConfig);
    if (result is Invalid) {
      final hash = sha256.convert(utf8.encode(jsonEncode(raw))).toString().substring(0, 16);
      _logInvalidPayload(screenId, result.errors, hash, raw);
      throw BduiInvalidPayloadException(
        errors: result.errors,
        screenId: screenId,
        payloadHash: hash,
      );
    }
  }

  void _logInvalidPayload(
    String screenId,
    List<ValidationError> errors,
    String hash,
    Map<String, dynamic> raw,
  ) {
    final meta = {
      'event': 'bdui.invalid_payload',
      'screen_id': screenId,
      'errors_count': errors.length,
      'errors_paths': errors.take(10).map((e) => e.path).toList(),
      'payload_hash': hash,
      'schema_version_received': raw['schema_version'],
    };
    developer.log(
      jsonEncode(meta),
      name: 'BDUI.Validation',
      level: 1000,
    );
    ErrorLogger.instance.log(ErrorPayload(
      error: BduiInvalidPayloadException(
        errors: errors,
        screenId: screenId,
        payloadHash: hash,
      ),
      stack: StackTrace.current,
      componentType: 'ScalarioCanvas',
      screenId: screenId,
    ));
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

  /// Valide un JSON brut puis rend l'écran — STORY-026 AC-09.
  ///
  /// Si le JSON est invalide, retourne [FallbackScreen] au lieu de parser.
  /// Ne throw jamais — les erreurs sont capturées et affichées gracieusement.
  Widget renderRaw(Map<String, dynamic> rawJson, BuildContext ctx) {
    return _metrics.timeSync('renderRaw', () {
      if (bdui.BduiValidator.isInitialized) {
        final result = bdui.BduiValidator.I.validate(rawJson, BduiType.screenConfig);
        if (result is Invalid) {
          final hash = sha256.convert(utf8.encode(jsonEncode(rawJson))).toString().substring(0, 16);
          _logInvalidPayload(_safeScreenId(rawJson), result.errors, hash, rawJson);
          return FallbackScreen(
            errors: result.errors,
            errorId: hash,
          );
        }
      }
      try {
        final config = ScreenConfig.fromJson(rawJson);
        _metrics.timeSync('schema-validate', () => _validateSchemas(config, _safeScreenId(rawJson)));
        return render(config, ctx);
      } catch (e, st) {
        _logRenderError(_safeScreenId(rawJson), e, st);
        rethrow;
      }
    });
  }

  String _safeScreenId(Map<String, dynamic> json) {
    final raw = json['screen'];
    if (raw is String) return raw;
    return '<raw>';
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _validateSchemas(ScreenConfig screen, String screenId) {
    final errors = <SchemaValidationError>[];
    final mode = config.schemaValidationMode;

    void walk(List<ComponentConfig>? components) {
      if (components == null) return;
      for (final c in components) {
        errors.addAll(registry.validate(c, mode: mode));
        if (c.children != null) walk(c.children!);
      }
    }

    walk(screen.zones.kpis);
    walk(screen.zones.main);
    walk(screen.zones.aside);
    walk(screen.zones.actions);

    registry.recordValidationErrors(screenId, errors);

    if (errors.isNotEmpty) {
      developer.log(
        '[SchemaValidation] screen=$screenId errors=${errors.length} mode=$mode',
        name: 'BDUI.Validation',
        level: mode == SchemaValidationMode.strict ? 1000 : 900,
      );
      for (final e in errors) {
        developer.log(e.toString(), name: 'BDUI.Validation', level: 900);
      }
    }
  }

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
