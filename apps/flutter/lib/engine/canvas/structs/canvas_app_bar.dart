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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final title = config.props['title'] as String? ?? '';
    final centerTitle = config.props['centerTitle'] as bool? ?? false;

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return [];
    final actions = config.props['actions'] as List? ?? [];
    return actions.map((a) => r!.build(ComponentConfig.fromJson(a as Map<String, dynamic>), context)).toList();
  }
}
