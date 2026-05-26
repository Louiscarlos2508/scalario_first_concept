import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_registry.dart';

class CatalogScreen extends StatefulWidget {
  final String jsonAssetPath;
  const CatalogScreen({super.key, required this.jsonAssetPath});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Map<String, dynamic>? _module;
  int _screenIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  Future<void> _loadModule() async {
    final raw = await rootBundle.loadString(widget.jsonAssetPath);
    setState(() => _module = jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    if (_module == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screens = _module!['screens'] as List? ?? [];
    if (screens.isEmpty) return const Scaffold(body: Center(child: Text('Aucun ecran defini')));

    final screen = screens[_screenIndex.clamp(0, screens.length - 1)] as Map<String, dynamic>;
    final title = screen['title'] as String? ?? _module!['name'] as String? ?? 'Scalario';
    final layout = screen['layout'] as String? ?? 'dashboard';
    final zones = screen['zones'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildZones(context, zones, layout),
      bottomNavigationBar: _screenTabs(screens),
    );
  }

  Widget _buildZones(BuildContext context, Map<String, dynamic> zones, String layout) {
    final registry = GetIt.I<ScalarioCanvasRegistry>();
    final kpis = _parseComponents(zones['kpis']);
    final main = _parseComponents(zones['main']);
    final aside = _parseComponents(zones['aside']);
    final actions = _parseComponents(zones['actions']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (kpis.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: kpis.map((c) => SizedBox(
            width: layout == 'dashboard' ? (MediaQuery.of(context).size.width - 48) / 2 : double.infinity,
            child: registry.build(c, context),
          )).toList()),
        if (main.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...main.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: registry.build(c, context),
          )),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: actions.map((c) => registry.build(c, context)).toList()),
        ],
      ]),
    );
  }

  List<ComponentConfig> _parseComponents(dynamic zone) {
    if (zone is! List) return [];
    return zone.map((c) => ComponentConfig.fromJson(c as Map<String, dynamic>)).toList();
  }

  Widget _screenTabs(List screens) {
    if (screens.length <= 1) return const SizedBox.shrink();
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _screenIndex,
      onTap: (i) => setState(() => _screenIndex = i),
      items: screens.map((s) {
        final sc = s as Map<String, dynamic>;
        return BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: (sc['title'] as String? ?? '').length > 10 ? '${(sc['title'] as String).substring(0, 8)}...' : sc['title'] as String? ?? '',
        );
      }).toList(),
    );
  }
}
