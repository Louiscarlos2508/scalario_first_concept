import 'package:flutter/material.dart';
import '../canvas_registry/component_config.dart';
import '../canvas_registry/scalario_canvas_registry.dart';

class CanvasRow extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasRow({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasRow(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final gap = (config.props['gap'] as num?)?.toDouble() ?? 8;
    final children = config.children ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children.map((c) => Padding(
          padding: EdgeInsets.only(right: gap),
          child: ScalarioCanvasRegistry.instance?.build(c, context) ?? const SizedBox.shrink(),
        )).toList(),
      ),
    );
  }
}
