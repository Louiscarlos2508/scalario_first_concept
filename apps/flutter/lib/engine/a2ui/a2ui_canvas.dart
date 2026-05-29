import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

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
            surface.surfaceId,
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

    final kpis = zones.kpis
        ?.map((c) => registry.build(c, context))
        .toList();
    final main = zones.main
        ?.map((c) => registry.build(c, context))
        .toList();

    return Scaffold(
      appBar: config.title != null ? AppBar(title: Text(config.title!)) : null,
      body: Column(
        children: [
          if (kpis != null && kpis.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: kpis),
          if (main != null && main.isNotEmpty)
            Expanded(child: ListView(children: main)),
        ],
      ),
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
