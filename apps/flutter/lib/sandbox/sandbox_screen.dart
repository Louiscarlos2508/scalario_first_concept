// Sandbox dev-only (kDebugMode).
//
// Supporte deux modes de rendu :
//   BDUI — charge des fixtures ScreenConfig et les rend via ScalarioCanvas
//   A2UI — charge des messages A2UI et les rend via A2UICanvas
//
// Header : sélecteur de fixture + UserContext + breakpoint + mode.
// Body   : rendu BDUI ou A2UI dans un viewport breakpoint contraint.
// Footer : console structurée (logs sandbox).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../components/actions/scalario_button.dart';
import '../core/ai_relay/ai_relay_client.dart';
import '../engine/canvas/scalario_canvas.dart';
import '../engine/canvas/data_source_resolver.dart';
import '../engine/canvas/json_schema_validator.dart';
import '../engine/canvas_registry/scalario_canvas_registry.dart';
import '../engine/canvas_rule/scalario_canvas_rule.dart';
import '../engine/canvas_layout/screen_config.dart';
import '../engine/a2ui/a2ui_canvas.dart';
import 'sandbox_a2ui_loader.dart';
import 'sandbox_action_dispatcher.dart';
import 'sandbox_breakpoint_overlay.dart';
import 'sandbox_console.dart';
import 'sandbox_error_view.dart';
import 'sandbox_file_watcher.dart';
import 'sandbox_json_loader.dart';
import 'sandbox_user_context.dart';

/// Route canonique du sandbox (enregistrée seulement en `kDebugMode`).
const String kSandboxRouteName = '/dev/sandbox';

enum _SandboxMode { bdui, a2ui }

enum _SandboxSource { static, live }

/// IDs de toutes les fixtures disponibles (BDUI + A2UI).
List<String> get _allFixtureIds =>
    [...kSandboxFixtureIds, ...kA2uiFixtureIds];

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({
    super.key,
    this.loader,
    this.watcher,
    this.userContext,
    this.console,
    this.componentRegistry,
    this.initialFixtureId,
  });

  final SandboxJsonLoader? loader;
  final SandboxFileWatcher? watcher;
  final SandboxUserContextProvider? userContext;
  final SandboxConsoleController? console;
  final ScalarioCanvasRegistry? componentRegistry;
  final String? initialFixtureId;

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  late final SandboxJsonLoader _loader;
  late final A2uiSandboxLoader _a2uiLoader;
  late final SandboxFileWatcher _watcher;
  late final SandboxUserContextProvider _userCtx;
  late final SandboxConsoleController _console;
  late final ScalarioCanvas _engine;
  late final ScalarioCanvasRegistry _registry;

  String _fixtureId = _allFixtureIds.first;
  _SandboxMode _mode = _SandboxMode.bdui;
  _SandboxSource _source = _SandboxSource.static;
  SandboxBreakpoint _breakpoint = SandboxBreakpoint.desktop;
  bool _reloading = false;
  Timer? _reloadIndicatorTimer;

  // BDUI state
  Future<ScreenConfig>? _bduiFuture;

  // A2UI state
  List<Map<String, dynamic>>? _a2uiMessages;
  String? _a2uiErrorMessage;

  // Live mode state
  String _token = '';
  String _loginEmail = 'owner@blandine.bf';
  String _loginPassword = 'owner123';
  String? _loginError;

  bool get _isBduiMode => _mode == _SandboxMode.bdui;

  final TextEditingController _customCtxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loader = widget.loader ?? const SandboxJsonLoader();
    _a2uiLoader = const A2uiSandboxLoader();
    _watcher = widget.watcher ?? const NoopFileWatcher();
    _userCtx = widget.userContext ?? SandboxUserContextProvider();
    _console = widget.console ?? SandboxConsoleController();
    _fixtureId = widget.initialFixtureId ?? _allFixtureIds.first;
    _mode = _detectMode(_fixtureId);

    _registry =
        widget.componentRegistry ?? GetIt.I<ScalarioCanvasRegistry>();
    _engine = _SandboxBDUIEngineFactory.build(
      registry: _registry,
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

  _SandboxMode _detectMode(String fixtureId) =>
      fixtureId.startsWith('a2ui_') ? _SandboxMode.a2ui : _SandboxMode.bdui;

  void _onUserCtxChanged() {
    _console.log(
      SandboxLogLevel.info,
      'UserContext',
      'preset=${_userCtx.preset.name} roles=${_userCtx.current.roles}',
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadFixture(String fixtureId) async {
    _watcher.stop();
    final mode = _detectMode(fixtureId);

    if (mode == _SandboxMode.bdui) {
      if (_source == _SandboxSource.live && _token.isNotEmpty) {
        _loadLiveBdui(fixtureId);
      } else {
        final future = _loadBdui(fixtureId);
        setState(() {
          _fixtureId = fixtureId;
          _mode = mode;
          _a2uiMessages = null;
          _a2uiErrorMessage = null;
          _bduiFuture = future;
        });
      }
    } else if (_source == _SandboxSource.live) {
      _loadLiveA2ui(fixtureId);
      return;
    } else {
      setState(() {
        _fixtureId = fixtureId;
        _mode = mode;
        _a2uiMessages = null;
        _a2uiErrorMessage = null;
        _bduiFuture = null;
      });
    }

    unawaited(_attachWatcher(fixtureId));
  }

  Future<void> _loadLiveA2ui(String fixtureId) async {
    setState(() {
      _fixtureId = fixtureId;
      _mode = _SandboxMode.a2ui;
      _a2uiMessages = null;
      _a2uiErrorMessage = null;
      _bduiFuture = null;
    });

    try {
      final client = GetIt.I<AiRelayClient>();
      final response = await client.generate(
        tenantId: 'dev',
        surfaceId: fixtureId,
        intent: 'Show $fixtureId dashboard with KPIs and actions',
      );

      if (!mounted) return;
      setState(() {
        _a2uiMessages = response.messages;
        _console.log(
          SandboxLogLevel.info,
          'MindEngine',
          'generated surface=${response.surfaceId} model=${response.model} degraded=${response.degraded} messages=${response.messages.length}',
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _a2uiErrorMessage = e.toString());
      _console.log(SandboxLogLevel.error, 'MindEngine', 'generation failed', error: e);
    }
  }

  Future<void> _loadLiveBdui(String fixtureId) async {
    setState(() {
      _fixtureId = fixtureId;
      _mode = _SandboxMode.bdui;
      _bduiFuture = _fetchBduiScreen(fixtureId);
    });
  }

  Future<ScreenConfig> _fetchBduiScreen(String screenId) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000',
      headers: {'Authorization': 'Bearer $_token'},
    ));
    final resp = await dio.get('/api/v1/api/v1/blandine/layout/$screenId');
    _console.log(SandboxLogLevel.info, 'API', 'loaded $screenId (${resp.statusCode})');
    return ScreenConfig.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> _login() async {
    setState(() => _loginError = null);
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final resp = await dio.post('/api/v1/auth/login', data: {
        'email': _loginEmail,
        'password': _loginPassword,
        'tenant_slug': 'blandine',
      });
      _token = resp.data['access_token'] as String;
      _console.log(SandboxLogLevel.info, 'API', 'login OK');
      setState(() {});
    } catch (e) {
      final msg = e is DioException ? (e.response?.data?['message'] as String? ?? e.message ?? '') : e.toString();
      setState(() => _loginError = msg);
      _console.log(SandboxLogLevel.error, 'API', 'login failed $msg');
    }
  }

  Future<void> _attachWatcher(String fixtureId) async {
    try {
      await _watcher.start(_loader.describePath(fixtureId), _reload);
    } on UnsupportedError catch (e) {
      _console.log(SandboxLogLevel.warning, 'FileWatcher', e.message ?? 'n/a');
    }
  }

  Future<ScreenConfig> _loadBdui(String fixtureId) async {
    final raw = await _loader.load(fixtureId);
    return ScreenConfig.fromJson(raw);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _reloading = true);
    _loadFixture(_fixtureId).then((_) {
      if (mounted) {
        _reloadIndicatorTimer?.cancel();
        _reloadIndicatorTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _reloading = false);
        });
      }
    });
    _console.log(SandboxLogLevel.info, 'Sandbox', 'reload $_fixtureId');
  }

  void _reset() {
    _customCtxController.clear();
    _userCtx.selectPreset(SandboxUserPreset.owner);
    final firstId = _allFixtureIds.first;
    setState(() {
      _breakpoint = SandboxBreakpoint.desktop;
      _fixtureId = firstId;
      _mode = _detectMode(firstId);
      _source = _SandboxSource.static;
      _a2uiMessages = null;
      _a2uiErrorMessage = null;
      _bduiFuture = _loadBdui(firstId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          _mode == _SandboxMode.a2ui
              ? 'A2UI Sandbox (dev)'
              : 'Scalario Sandbox (dev)',
        ),
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
                _buildBody(context),
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
          _modeIndicator(),
          if (_mode == _SandboxMode.a2ui || _mode == _SandboxMode.bdui) _sourceDropdown(),
          if (_source == _SandboxSource.live) _loginPanel(),
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

  Widget _modeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _mode == _SandboxMode.a2ui
            ? Colors.blue.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mode == _SandboxMode.a2ui
              ? Colors.blue.shade300
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        _mode == _SandboxMode.a2ui ? 'A2UI' : 'BDUI',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _mode == _SandboxMode.a2ui ? Colors.blue.shade700 : null,
        ),
      ),
    );
  }

  Widget _sourceDropdown() {
    return DropdownButton<_SandboxSource>(
      key: const Key('sandbox.dropdown.source'),
      value: _source,
      onChanged: (_SandboxSource? v) {
        if (v == null || v == _source) return;
        setState(() => _source = v);
        _loadFixture(_fixtureId);
      },
      items: const [
        DropdownMenuItem(value: _SandboxSource.static, child: Text('Static')),
        DropdownMenuItem(value: _SandboxSource.live, child: Text('Live')),
      ],
    );
  }

  Widget _loginPanel() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _token.isEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Email', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                  controller: TextEditingController(text: _loginEmail),
                  onChanged: (v) => _loginEmail = v,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 120,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Password', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                  obscureText: true,
                  controller: TextEditingController(text: _loginPassword),
                  onChanged: (v) => _loginPassword = v,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(onPressed: _login, child: const Text('Login')),
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(_loginError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                ),
            ])
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text('JWT ${_token.substring(0, 12)}...', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              TextButton(onPressed: () => setState(() => _token = ''), child: const Text('Logout', style: TextStyle(fontSize: 11))),
            ]),
    );
  }

  Widget _fixtureDropdown() {
    final ids = _allFixtureIds;
    return DropdownButton<String>(
      key: const Key('sandbox.dropdown.fixture'),
      value: _fixtureId,
      onChanged: (String? v) {
        if (v != null) _loadFixture(v);
      },
      items: <DropdownMenuItem<String>>[
        for (final String id in ids) //
          DropdownMenuItem<String>(
            value: id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (id.startsWith('a2ui_'))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.auto_awesome, size: 16, color: Colors.blue.shade400),
                  ),
                Text(id),
              ],
            ),
          ),
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

  Widget _buildBody(BuildContext context) {
    if (_mode == _SandboxMode.a2ui) {
      return _buildA2uiBody(context);
    }
    return _buildBduiBody();
  }

  Widget _buildBduiBody() {
    return FutureBuilder<ScreenConfig>(
      future: _bduiFuture,
      builder: (BuildContext ctx, AsyncSnapshot<ScreenConfig> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          _postError(snap.error);
          return SandboxErrorView(error: snap.error!, onRetry: _reload);
        }
        return SandboxBreakpointOverlay(
          breakpoint: _breakpoint,
          child: _renderBduiSafe(snap.data!, ctx),
        );
      },
    );
  }

  Widget _buildA2uiBody(BuildContext context) {
    final messages = _a2uiMessages;
    if (messages == null && _a2uiErrorMessage == null) {
      final label = _source == _SandboxSource.live ? 'Contacting MindEngine...' : null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      );
    }

    if (_a2uiErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('MindEngine error', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _a2uiErrorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (messages == null || messages.isEmpty) {
      return const Center(child: Text('No A2UI messages'));
    }

    final dispatcher = SandboxActionDispatcher(
      console: _console,
      scaffoldMessenger: ScaffoldMessenger.of(context),
    );

    ScalarioButton.onAction = dispatcher.dispatch;

    final liveStream = _createSimulatedLiveStream();

    return SandboxBreakpointOverlay(
      breakpoint: _breakpoint,
      child: A2UICanvas(
        registry: _registry,
        initialMessages: messages,
        messageStream: liveStream,
        onAction: dispatcher.dispatch,
      ),
    );
  }

  /// Crée un stream simulé qui émet des updates dataModel toutes les 5s.
  Stream<Map<String, dynamic>> _createSimulatedLiveStream() {
    final rng = math.Random(42);
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => <String, dynamic>{
        'version': 'v0.9',
        'updateDataModel': <String, dynamic>{
          'surfaceId': 'dashboard',
          'value': <String, dynamic>{
            'kpi': <String, dynamic>{
              'ca_jour': 145000 + rng.nextInt(30000),
              'commandes_jour': 28 + rng.nextInt(6),
            },
          },
        },
      },
    );
  }

  void _postError(Object? error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _console.log(
        SandboxLogLevel.error,
        'Sandbox',
        'load failure for $_fixtureId',
        error: error,
      );
    });
  }

  Widget _renderBduiSafe(ScreenConfig config, BuildContext ctx) {
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
      debugPrint('Sandbox render failure: $e');
      return SandboxErrorView(error: e, onRetry: _reload);
    }
  }
}

/// Construit un [ScalarioCanvas] dédié au sandbox qui consulte le
/// [SandboxUserContextProvider] mutable plutôt que celui de production.
abstract class _SandboxBDUIEngineFactory {
  static ScalarioCanvas build({
    required ScalarioCanvasRegistry registry,
    required SandboxUserContextProvider userContext,
  }) {
    return ScalarioCanvas(
      registry: registry,
      evaluator: const ScalarioCanvasRule(),
      dataResolver: _UnusedDataResolver(),
      userContextProvider: userContext,
      validator: const _PassthroughValidator(),
    );
  }
}

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
  void validateScreen(Map<String, dynamic> json) {}
}
