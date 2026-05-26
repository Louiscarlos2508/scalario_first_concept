import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/spacing_resolver.dart';

class CanvasStack extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasStack({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasStack(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final layers = config.children ?? [];
    final r = ScalarioCanvasRegistry.instance;
    if (r == null || layers.isEmpty) return const SizedBox.shrink();

    return Stack(children: layers.map((layer) {
      final position = layer.props['position'] as String? ?? '';
      final padding = resolvePadding(layer.props['padding'] ?? 'none');
      final margin = resolveGap(layer.props['margin'] ?? 'none');
      final child = Padding(padding: EdgeInsets.all(padding), child: r.build(layer, ctx));

      return switch (position) {
        'top' => Positioned(top: margin, left: margin, right: margin, child: child),
        'bottom' => Positioned(bottom: margin, left: margin, right: margin, child: child),
        'bottom_right' => Positioned(bottom: margin, right: margin, child: child),
        'fill' => Positioned.fill(child: child),
        _ => Positioned(child: child),
      };
    }).toList());
  }
}
