import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../canvas_registry/component_config.dart';
import '../canvas_registry/scalario_canvas_registry.dart';
import '../canvas_layout/screen_config.dart';
import 'a2ui_component.dart';
import 'a2ui_message.dart';
import 'component_translator.dart';

class A2UICanvas extends StatefulWidget {
  const A2UICanvas({
    super.key,
    required this.registry,
    this.initialMessages,
    this.messageStream,
    this.onAction,
  });

  final ScalarioCanvasRegistry registry;
  final List<Map<String, dynamic>>? initialMessages;
  final Stream<Map<String, dynamic>>? messageStream;
  final void Function(Map<String, dynamic> action)? onAction;

  @override
  State<A2UICanvas> createState() => _A2UICanvasState();
}

class _A2UICanvasState extends State<A2UICanvas> {
  final _surfaces = <String, _SurfaceState>{};
  late final A2UIComponentTranslator _translator;
  String? _activeSurface;
  StreamSubscription<Map<String, dynamic>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _translator = A2UIComponentTranslator(widget.registry);
    _initMessages();
    _streamSub = widget.messageStream?.listen(
      (raw) => processMessage(raw),
    );
  }

  void _initMessages() {
    if (widget.initialMessages != null) {
      for (final raw in widget.initialMessages!) {
        _processMessage(A2UIMessage.fromJson(raw));
      }
    }
  }

  @override
  void didUpdateWidget(A2UICanvas old) {
    super.didUpdateWidget(old);
    if (widget.registry != old.registry) {
      _translator.updateRegistry(widget.registry);
    }
    if (widget.messageStream != old.messageStream) {
      _streamSub?.cancel();
      _streamSub = widget.messageStream?.listen(
        (raw) => processMessage(raw),
      );
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void processMessage(Map<String, dynamic> raw) {
    try {
      final msg = A2UIMessage.fromJson(raw);
      setState(() => _processMessage(msg));
    } catch (e) {
      developer.log('A2UI message parse failed: $e', name: 'A2UI');
    }
  }

  void _processMessage(A2UIMessage msg) {
    switch (msg.type) {
      case A2UIMessageType.createSurface:
        final cs = msg.createSurface!;
        _surfaces[cs.surfaceId] = _SurfaceState(
          surfaceId: cs.surfaceId,
          catalogId: cs.catalogId,
          theme: cs.theme,
          dataModel: A2UIDataModel(),
        );
        _activeSurface ??= cs.surfaceId;

      case A2UIMessageType.updateComponents:
        final uc = msg.updateComponents!;
        final surface = _surfaces[uc.surfaceId];
        if (surface != null) {
          final config = _translator.translate(
            uc,
            surface.layout,
            null,
          );
          _surfaces[uc.surfaceId] = surface.copyWith(config: config);
          _activeSurface ??= uc.surfaceId;
        }

      case A2UIMessageType.updateDataModel:
        final dm = msg.updateDataModel!;
        final surface = _surfaces[dm.surfaceId];
        if (surface != null) {
          if (dm.path != null) {
            surface.dataModel.update(dm.path!, dm.value);
          } else {
            surface.dataModel.update('/', dm.value);
          }
          _surfaces[dm.surfaceId] = surface.copyWith();
        }

      case A2UIMessageType.deleteSurface:
        final ds = msg.deleteSurface!;
        _surfaces.remove(ds.surfaceId);
        if (_activeSurface == ds.surfaceId) {
          _activeSurface = _surfaces.keys.isNotEmpty ? _surfaces.keys.first : null;
        }

      case A2UIMessageType.error:
        developer.log(
          'A2UI error: ${msg.error?.code} — ${msg.error?.message}',
          name: 'A2UI',
          level: 1000,
        );
    }
  }

  /// Résout tous les marqueurs `_a2ui_path` dans les props d'un
  /// [ComponentConfig] contre le [dataModel], récursivement dans les enfants.
  ComponentConfig _resolveConfig(ComponentConfig config, A2UIDataModel dataModel) {
    Map<String, dynamic> resolvedProps = {};
    for (final entry in config.props.entries) {
      resolvedProps[entry.key] = _resolveDataBinding(entry.value, dataModel);
    }

    List<ComponentConfig>? resolvedChildren;
    if (config.children != null) {
      resolvedChildren = config.children!
          .map((c) => _resolveConfig(c, dataModel))
          .toList();
    }

    return config.copyWith(props: resolvedProps, children: resolvedChildren);
  }

  /// Résout une valeur qui pourrait être un marqueur de data binding.
  dynamic _resolveDataBinding(dynamic value, A2UIDataModel dataModel) {
    if (value is Map<String, dynamic> && value.containsKey('_a2ui_path')) {
      final path = value['_a2ui_path'] as String;
      final result = dataModel.resolve(path);
      if (result == null) return null;
      if (result is num) {
        if (result == result.roundToDouble()) {
          return result.toInt().toString();
        }
        return result.toString();
      }
      if (result is String) return result;
      if (result is List || result is Map) return result;
      return result.toString();
    }
    if (value is Map<String, dynamic>) {
      Map<String, dynamic> resolved = {};
      for (final entry in value.entries) {
        resolved[entry.key] = _resolveDataBinding(entry.value, dataModel);
      }
      return resolved;
    }
    if (value is List) {
      return value.map((e) => _resolveDataBinding(e, dataModel)).toList();
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final surface = _activeSurface != null
        ? _surfaces[_activeSurface]
        : null;

    if (surface == null || surface.config == null) {
      return const Center(child: Text('No A2UI surface'));
    }

    final registry = widget.registry;
    final config = surface.config!;
    final zones = config.zones;
    final dataModel = surface.dataModel;

    final kpis = config.kpis
        ?.map((c) => registry.build(_resolveConfig(c, dataModel), context))
        .toList();
    final mainContent = config.main
        ?.map((c) => registry.build(_resolveConfig(c, dataModel), context))
        .toList();

    final bodyContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (config.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(config.title!, style: Theme.of(context).textTheme.titleLarge),
            ),
          if (kpis != null && kpis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(children: kpis.map((k) => Padding(padding: const EdgeInsets.only(bottom: 8), child: k)).toList()),
            ),
          if (mainContent != null && mainContent.isNotEmpty) ...mainContent,
        ],
      ),
    );

    final sc = config.scaffoldConfig;
    if (sc == null) return bodyContent;

    return _buildScaffold(context, registry, sc, bodyContent);
  }

  Widget _buildScaffold(
    BuildContext context,
    ScalarioCanvasRegistry registry,
    Map<String, dynamic> sc,
    Widget body,
  ) {
    Widget? buildSub(dynamic childConfig) {
      if (childConfig == null) return null;
      if (childConfig is ComponentConfig) {
        return registry.build(childConfig, context);
      }
      if (childConfig is Map<String, dynamic>) {
        return registry.build(ComponentConfig.fromJson(childConfig), context);
      }
      return null;
    }

    final appBar = buildSub(sc['appBar']);
    final sidebar = buildSub(sc['sidebar']);
    final drawer = buildSub(sc['drawer']);
    final bottomNav = buildSub(sc['bottomNav']);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    Widget bodyWidget = body;
    if (sidebar != null && isDesktop) {
      bodyWidget = Row(
        children: [
          SizedBox(width: 240, child: sidebar),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: appBar is PreferredSizeWidget ? appBar : null,
      body: bodyWidget,
      bottomNavigationBar: bottomNav,
      drawer: drawer != null && !isDesktop ? Drawer(child: drawer) : null,
    );
  }
}

class _SurfaceState {
  _SurfaceState({
    required this.surfaceId,
    this.catalogId,
    this.theme,
    this.config,
    A2UIDataModel? dataModel,
    this.layout = 'dashboard',
  }) : dataModel = dataModel ?? A2UIDataModel();

  final String surfaceId;
  final String? catalogId;
  final Map<String, dynamic>? theme;
  final ScreenConfig? config;
  final A2UIDataModel dataModel;
  final String layout;

  _SurfaceState copyWith({
    ScreenConfig? config,
    A2UIDataModel? dataModel,
    String? layout,
  }) {
    return _SurfaceState(
      surfaceId: surfaceId,
      catalogId: catalogId,
      theme: theme,
      config: config ?? this.config,
      dataModel: dataModel ?? this.dataModel,
      layout: layout ?? this.layout,
    );
  }
}
