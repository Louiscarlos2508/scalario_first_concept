import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/spacing_resolver.dart';

class CanvasRow extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasRow({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasRow(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final gap = resolveGap(config.props['gap'] ?? 8);
    final children = config.children ?? [];

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Flexible(
            fit: FlexFit.tight,
            child: ScalarioCanvasRegistry.instance?.build(children[i], context) ?? const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
