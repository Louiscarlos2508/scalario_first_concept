import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/spacing_resolver.dart';

class CanvasColumn extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasColumn({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasColumn(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final gap = resolveGap(config.props['gap'] ?? 8);
    final children = config.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.map((c) => Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: ScalarioCanvasRegistry.instance?.build(c, context) ?? const SizedBox.shrink(),
      )).toList(),
    );
  }
}
