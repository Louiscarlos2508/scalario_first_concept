import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_registry.dart';

class CatalogScreen extends StatelessWidget {
  final String jsonAssetPath;
  final int screenIndex;

  const CatalogScreen({super.key, required this.jsonAssetPath, this.screenIndex = 0});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: rootBundle.loadStructuredData<Map<String, dynamic>>(jsonAssetPath, (raw) async => jsonDecode(raw) as Map<String, dynamic>),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!;

        // Multiple screens: use screenIndex
        if (data.containsKey('screens') && data['screens'] is List) {
          final screens = data['screens'] as List;
          if (screens.isEmpty) return const Scaffold(body: Center(child: Text('No screens')));
          final idx = screenIndex.clamp(0, screens.length - 1);
          final screenRef = screens[idx];

          // String path reference
          if (screenRef is String) {
            final assetPath = 'assets/catalog/tenants/blandine/$screenRef';
            return _SingleScreenLoader(assetPath: assetPath);
          }
          // Inline screen object
          if (screenRef is Map) {
            return _render(screenRef as Map<String, dynamic>, context);
          }
          return const Scaffold(body: Center(child: Text('Invalid screen')));
        }

        // Single screen: { "root": {...} }
        if (data.containsKey('root')) {
          return _render(data, context);
        }

        return const Scaffold(body: Center(child: Text('Invalid config')));
      },
    );
  }
}

Widget _render(Map<String, dynamic> screenData, BuildContext context) {
  final registry = GetIt.I<ScalarioCanvasRegistry>();
  final rootJson = screenData['root'] as Map<String, dynamic>? ?? screenData;
  final root = ComponentConfig.fromJson(rootJson);
  return registry.build(root, context);
}

class _SingleScreenLoader extends StatelessWidget {
  final String assetPath;
  const _SingleScreenLoader({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: rootBundle.loadStructuredData<Map<String, dynamic>>(assetPath, (raw) async => jsonDecode(raw) as Map<String, dynamic>),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!;
        if (!data.containsKey('root')) return const Scaffold(body: Center(child: Text('Invalid screen')));
        return _render(data, context);
      },
    );
  }
}
