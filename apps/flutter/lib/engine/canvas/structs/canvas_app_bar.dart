import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasAppBar({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasAppBar(config: config, ctx: ctx);
  }

  @override
  Size get preferredSize {
    final variant = config.variant;
    return Size.fromHeight(variant == 'large' ? 112 : variant == 'search' ? 56 : kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final variant = config.variant;
    final title = config.props['title'] as String? ?? '';

    return switch (variant) {
      'large' => _buildLarge(title),
      'transparent' => _buildTransparent(title),
      'search' => _buildSearch(title),
      'minimal' => _buildMinimal(title),
      _ => _buildDefault(title),
    };
  }

  AppBar _buildDefault(String title) {
    return AppBar(title: Text(title), centerTitle: config.props['centerTitle'] as bool? ?? false, actions: _buildActions());
  }

  AppBar _buildLarge(String title) {
    return AppBar(toolbarHeight: 112, title: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        if (config.props['subtitle'] != null) Text(config.props['subtitle'] as String, style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)))],
    ), actions: _buildActions());
  }

  AppBar _buildTransparent(String title) {
    return AppBar(title: Text(title), backgroundColor: Colors.transparent, elevation: 0, actions: _buildActions());
  }

  AppBar _buildSearch(String title) {
    return AppBar(title: TextField(decoration: InputDecoration(hintText: config.props['hint'] as String? ?? 'Rechercher...', border: InputBorder.none)), actions: _buildActions());
  }

  AppBar _buildMinimal(String title) {
    return AppBar(title: Text(title), automaticallyImplyLeading: false, actions: null);
  }

  List<Widget>? _buildActions() {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return null;
    final actions = config.props['actions'] as List? ?? [];
    if (actions.isEmpty) return null;
    return actions.map((a) => r.build(ComponentConfig.fromJson(a as Map<String, dynamic>), ctx)).toList();
  }
}
