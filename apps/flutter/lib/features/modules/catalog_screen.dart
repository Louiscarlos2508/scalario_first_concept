import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_registry.dart';

class CatalogScreen extends StatelessWidget {
  final String jsonAssetPath;
  const CatalogScreen({super.key, required this.jsonAssetPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: rootBundle.loadStructuredData<Map<String, dynamic>>(jsonAssetPath, (raw) async => jsonDecode(raw) as Map<String, dynamic>),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!;

        // Format 1: direct screen { "screen": "...", "root": {...} }
        if (data.containsKey('root')) {
          return _render(data, context);
        }

        // Format 2: module { "screens": [{ "root": {...} }, ...] } — inline screens
        if (data.containsKey('screens')) {
          final screens = data['screens'];
          if (screens is List && screens.isNotEmpty) {
            final first = screens[0];
            // Inline screen object
            if (first is Map) return _render(first as Map<String, dynamic>, context);
            // String path reference
            if (first is String) return _loadScreen(first, data['id'] as String? ?? 'blandine');
          }
        }

        return const Scaffold(body: Center(child: Text('No screen found')));
      },
    );
  }

  Widget _render(Map<String, dynamic> screenData, BuildContext context) {
    final registry = GetIt.I<ScalarioCanvasRegistry>();
    final rootJson = screenData['root'] as Map<String, dynamic>? ?? screenData;
    final root = ComponentConfig.fromJson(rootJson);
    return registry.build(root, context);
  }

  Widget _loadScreen(String screenPath, String moduleId) {
    final assetPath = 'assets/catalog/tenants/$moduleId/$screenPath';
    return _AssetLoader(assetPath: assetPath);
  }
}

class _AssetLoader extends StatefulWidget {
  final String assetPath;
  const _AssetLoader({required this.assetPath});

  @override
  State<_AssetLoader> createState() => _AssetLoaderState();
}

class _AssetLoaderState extends State<_AssetLoader> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      setState(() => _data = jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_data!.containsKey('root')) return const Scaffold(body: Center(child: Text('Invalid screen')));
    final registry = GetIt.I<ScalarioCanvasRegistry>();
    final root = ComponentConfig.fromJson(_data!['root'] as Map<String, dynamic>);
    return registry.build(root, context);
  }
}
