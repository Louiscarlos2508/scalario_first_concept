// STORY-009 — Sandbox dev-only (kDebugMode).
//
// Écran principal de la sandbox BDUI. Compose :
//  - Header : 3 sélecteurs (fichier, UserContext, breakpoint) + Reload/Reset.
//  - Body   : rendu BDUI dans un viewport breakpoint contraint.
//  - Footer : console structurée (logs sandbox).
//
// Accessible uniquement quand `kDebugMode` est vrai (cf. route conditionnelle
// dans `main.dart`).

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../engine/bdui_engine/bdui_engine.dart';
import '../engine/bdui_engine/data_source_resolver.dart';
import '../engine/bdui_engine/json_schema_validator.dart';
import '../engine/component_registry/component_registry.dart';
import '../engine/layout_resolver/layout_resolver.dart';
import '../engine/rule_evaluator/rule_evaluator.dart';
import 'sandbox_breakpoint_overlay.dart';
import 'sandbox_console.dart';
import 'sandbox_error_view.dart';
import 'sandbox_file_watcher.dart';
import 'sandbox_json_loader.dart';
import 'sandbox_user_context.dart';

/// Route canonique du sandbox (enregistrée seulement en `kDebugMode`).
const String kSandboxRouteName = '/dev/sandbox';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({
    super.key,
    this.loader,
    this.watcher,
    this.userContext,
    this.console,
    this.componentRegistry,
    this.layoutResolver,
    this.initialFixtureId,
  });

  /// Override pour tests (par défaut [BundleJsonSource]).
  final SandboxJsonLoader? loader;

  /// Override pour tests (par défaut [NoopFileWatcher] — le file watcher
  /// natif requiert un path filesystem, non disponible avec rootBundle).
  final SandboxFileWatcher? watcher;

  final SandboxUserContextProvider? userContext;
  final SandboxConsoleController? console;
  final ComponentRegistry? componentRegistry;
  final LayoutResolver? layoutResolver;
  final String? initialFixtureId;

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  late final SandboxJsonLoader _loader;
  late final SandboxFileWatcher _watcher;
  late final SandboxUserContextProvider _userCtx;
  late final SandboxConsoleController _console;
  late final BDUIEngine _engine;

  String _fixtureId = kSandboxFixtureIds.first;
  SandboxBreakpoint _breakpoint = SandboxBreakpoint.desktop;
  Future<ScreenConfig>? _future;
  bool _reloading = false;
  Timer? _reloadIndicatorTimer;

  final TextEditingController _customCtxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loader = widget.loader ?? const SandboxJsonLoader();
    _watcher = widget.watcher ?? const NoopFileWatcher();
    _userCtx = widget.userContext ?? SandboxUserContextProvider();
    _console = widget.console ?? SandboxConsoleController();
    _fixtureId = widget.initialFixtureId ?? kSandboxFixtureIds.first;

    final ComponentRegistry registry =
        widget.componentRegistry ?? GetIt.I<ComponentRegistry>();
    final LayoutResolver resolver =
        widget.layoutResolver ?? GetIt.I<LayoutResolver>();
    _engine = _SandboxBDUIEngineFactory.build(
      registry: registry,
      layoutResolver: resolver,
      userContext: _userCtx,
    );

    _userCtx.addListener(_onUserCtxChanged);
    _loadFixture(_fixtureId);
  }

  @override
  void dispose() {
    _userCtx.removeListener(_onUserCtxChanged);
    _watcher.stop();
    _reloadIndicatorTimer?.cancel();
    _customCtxController.dispose();
    super.dispose();
  }

  void _onUserCtxChanged() {
    _console.log(
      SandboxLogLevel.info,
      'UserContext',
      'preset=${_userCtx.preset.name} roles=${_userCtx.current.roles}',
    );
    // Re-render via setState — `engine.render` consultera `userContext.current`.
    if (mounted) setState(() {});
  }

  Future<void> _loadFixture(String fixtureId) async {
    _watcher.stop();
    setState(() {
      _fixtureId = fixtureId;
      _future = _loadAndParse(fixtureId);
    });
    unawaited(_attachWatcher(fixtureId));
  }

  Future<void> _attachWatcher(String fixtureId) async {
    try {
      await _watcher.start(_loader.describePath(fixtureId), _reload);
    } on UnsupportedError catch (e) {
      _console.log(SandboxLogLevel.warning, 'FileWatcher', e.message ?? 'n/a');
    }
  }

  Future<ScreenConfig> _loadAndParse(String fixtureId) async {
    final Map<String, dynamic> raw = await _loader.load(fixtureId);
    // Validation structurelle minimaliste : reproduit ce que fait l'engine
    // mais on garde la maîtrise sur le message d'erreur pour le sandbox.
    final ScreenConfig config = ScreenConfig.fromJson(raw);
    return config;
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _reloading = true;
      _future = _loadAndParse(_fixtureId);
    });
    _reloadIndicatorTimer?.cancel();
    _reloadIndicatorTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _reloading = false);
    });
    _console.log(SandboxLogLevel.info, 'Sandbox', 'reload $_fixtureId');
  }

  void _reset() {
    _customCtxController.clear();
    _userCtx.selectPreset(SandboxUserPreset.owner);
    setState(() {
      _breakpoint = SandboxBreakpoint.desktop;
      _fixtureId = kSandboxFixtureIds.first;
      _future = _loadAndParse(_fixtureId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BDUI Sandbox (dev)'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt),
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: <Widget>[
                _buildBody(),
                if (_reloading)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 140,
            child: SandboxConsole(controller: _console),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _fixtureDropdown(),
          _userContextDropdown(),
          _breakpointDropdown(),
          if (_userCtx.preset == SandboxUserPreset.custom)
            SizedBox(
              width: 320,
              child: TextField(
                controller: _customCtxController,
                onSubmitted: _userCtx.applyCustomJson,
                decoration: InputDecoration(
                  labelText: 'UserContext JSON',
                  hintText: '{"roles":["MANAGER"]}',
                  errorText: _userCtx.customError,
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fixtureDropdown() {
    return DropdownButton<String>(
      key: const Key('sandbox.dropdown.fixture'),
      value: _fixtureId,
      onChanged: (String? v) {
        if (v != null) _loadFixture(v);
      },
      items: <DropdownMenuItem<String>>[
        for (final String id in kSandboxFixtureIds)
          DropdownMenuItem<String>(value: id, child: Text(id)),
      ],
    );
  }

  Widget _userContextDropdown() {
    return DropdownButton<SandboxUserPreset>(
      key: const Key('sandbox.dropdown.userctx'),
      value: _userCtx.preset,
      onChanged: (SandboxUserPreset? p) {
        if (p != null) _userCtx.selectPreset(p);
      },
      items: <DropdownMenuItem<SandboxUserPreset>>[
        for (final SandboxUserPreset p in SandboxUserPreset.values)
          DropdownMenuItem<SandboxUserPreset>(value: p, child: Text(p.label)),
      ],
    );
  }

  Widget _breakpointDropdown() {
    return DropdownButton<SandboxBreakpoint>(
      key: const Key('sandbox.dropdown.breakpoint'),
      value: _breakpoint,
      onChanged: (SandboxBreakpoint? b) {
        if (b != null) setState(() => _breakpoint = b);
      },
      items: <DropdownMenuItem<SandboxBreakpoint>>[
        for (final SandboxBreakpoint bp in SandboxBreakpoint.values)
          DropdownMenuItem<SandboxBreakpoint>(value: bp, child: Text(bp.label)),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<ScreenConfig>(
      future: _future,
      builder: (BuildContext ctx, AsyncSnapshot<ScreenConfig> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _console.log(
              SandboxLogLevel.error,
              'Sandbox',
              'load failure for $_fixtureId',
              error: snap.error,
            );
          });
          return SandboxErrorView(error: snap.error!, onRetry: _reload);
        }
        return SandboxBreakpointOverlay(
          breakpoint: _breakpoint,
          child: _renderSafe(snap.data!, ctx),
        );
      },
    );
  }

  Widget _renderSafe(ScreenConfig config, BuildContext ctx) {
    try {
      return _engine.render(config, ctx);
    } catch (e, st) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _console.log(
          SandboxLogLevel.error,
          'Engine.render',
          'rendering threw',
          error: e,
        );
      });
      developer.log(
        'Sandbox render failure',
        name: 'BDUI.Sandbox',
        error: e,
        stackTrace: st,
      );
      return SandboxErrorView(error: e, onRetry: _reload);
    }
  }
}

/// Construit un [BDUIEngine] dédié au sandbox qui consulte le
/// [SandboxUserContextProvider] mutable plutôt que celui de production.
///
/// On évite GetIt pour ce composant car il diffère par instance.
abstract class _SandboxBDUIEngineFactory {
  static BDUIEngine build({
    required ComponentRegistry registry,
    required LayoutResolver layoutResolver,
    required SandboxUserContextProvider userContext,
  }) {
    return BDUIEngine(
      registry: registry,
      evaluator: const RuleEvaluator(),
      layoutResolver: layoutResolver,
      dataResolver: _UnusedDataResolver(),
      userContextProvider: userContext,
      validator: const _PassthroughValidator(),
    );
  }
}

/// Stub — la sandbox parse le JSON elle-même via [SandboxJsonLoader] ; cette
/// implémentation ne devrait jamais être appelée. Si elle l'est, on émet une
/// erreur explicite pour faciliter le debug.
class _UnusedDataResolver implements DataSourceResolver {
  @override
  Future<Map<String, dynamic>> loadScreenJson(String screenId) =>
      throw StateError('Sandbox loads JSON directly — bypass DataResolver.');

  @override
  Future<Object?> resolveDataSource(Map<String, dynamic> source) async => null;
}

class _PassthroughValidator implements JsonSchemaValidator {
  const _PassthroughValidator();
  @override
  void validateScreen(Map<String, dynamic> json) {
    // Pas de validation supplémentaire ; le `ScreenConfig.fromJson` détecte
    // déjà les mismatches structurels majeurs.
  }
}
