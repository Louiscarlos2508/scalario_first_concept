import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/spacing_resolver.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasGrid extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasGrid({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasGrid(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final gap = resolveGap(config.props['gap'] ?? 'sm');
    final columns = config.props['columns'] as int? ?? 2;
    final responsive = config.props['responsive'] as Map<String, dynamic>?;
    final screenWidth = MediaQuery.of(context).size.width;
    final items = config.children ?? [];
    final r = ScalarioCanvasRegistry.instance;
    if (r == null || items.isEmpty) return const SizedBox.shrink();

    int colCount = columns;
    if (responsive != null) {
      if (screenWidth < 600) colCount = responsive['mobile']?['columns'] as int? ?? colCount;
      else if (screenWidth < 1024) colCount = responsive['tablet']?['columns'] as int? ?? colCount;
      else colCount = responsive['desktop']?['columns'] as int? ?? colCount;
    }

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final span = (item.props['span'] as dynamic) ?? 1;
        int effectiveSpan;
        if (span == 'full') {
          effectiveSpan = colCount;
        } else {
          effectiveSpan = (span as num).toInt().clamp(1, colCount);
        }
        return SizedBox(
          width: ((screenWidth - (gap * (colCount + 1))) / colCount) * effectiveSpan + (gap * (effectiveSpan - 1)),
          child: RepaintBoundary(child: r.build(item, ctx)),
        );
      }),
    );
  }
}
