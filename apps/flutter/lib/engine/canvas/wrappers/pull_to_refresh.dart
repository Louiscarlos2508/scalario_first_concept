import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasPullToRefresh extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasPullToRefresh({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasPullToRefresh(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: r.build(config.children?.first ?? config, ctx),
      ),
    );
  }
}
