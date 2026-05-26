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
        final screens = data['screens'] as List? ?? [];
        if (screens.isEmpty) return const Scaffold(body: Center(child: Text('No screens')));

        final screen = screens[0] as Map<String, dynamic>;
        final registry = GetIt.I<ScalarioCanvasRegistry>();
        final root = ComponentConfig.fromJson(screen['root'] as Map<String, dynamic>? ?? screen);

        return registry.build(root, context);
      },
    );
  }
}
