import 'package:flutter/material.dart';
import 'component_config.dart';
import 'scalario_canvas_registry.dart';
import 'scalario_canvas_resolver.dart';

class CanvasGrid extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasGrid({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasGrid(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final columns = (config.props['columns'] as List?)?.cast<int>() ?? [1];
    final gap = (config.props['gap'] as num?)?.toDouble() ?? 8;
    final responsive = config.props['responsive'] as Map<String, dynamic>?;
    final screenWidth = MediaQuery.of(context).size.width;

    List<int> effectiveColumns = columns;
    if (responsive != null) {
      if (screenWidth < 600 && responsive['mobile'] != null) {
        effectiveColumns = (responsive['mobile'] as Map)['columns'] as List<int>;
      } else if (screenWidth < 1024 && responsive['tablet'] != null) {
        effectiveColumns = (responsive['tablet'] as Map)['columns'] as List<int>;
      } else if (responsive['desktop'] != null) {
        effectiveColumns = (responsive['desktop'] as Map)['columns'] as List<int>;
      }
    }

    final children = config.children ?? [];
    final registry = ctx is BuildContext ? _registry : null;
    if (registry == null || children.isEmpty) return const SizedBox.shrink();

    final colCount = effectiveColumns.length > 0 ? effectiveColumns[0] : 1;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: children.map((c) {
        return SizedBox(
          width: (screenWidth - (gap * (colCount + 1))) / colCount,
          child: registry.build(c, context as BuildContext),
        );
      }).toList(),
    );
  }
}

ScalarioCanvasRegistry? get _registry {
  try {
    return _registryInstance;
  } catch (_) {
    return null;
  }
}

ScalarioCanvasRegistry? _registryInstance;
void setCanvasRegistry(ScalarioCanvasRegistry r) => _registryInstance = r;
