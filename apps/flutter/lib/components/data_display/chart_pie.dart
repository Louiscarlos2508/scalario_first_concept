import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class ChartPie extends StatelessWidget {
  const ChartPie._({
    required this.props,
    required this.variant,
  });

  final Map<String, dynamic> props;
  final String variant;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    final variant = ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'ChartPie',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    try {
      return ChartPie._(props: config.props, variant: variant);
    } on Exception {
      return const ChartPie._(props: {}, variant: 'default');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case 'donut':
        return _buildDonut(context);
      case 'mini-legend':
        return _buildMiniLegend(context);
      default:
        return _buildDefault(context);
    }
  }

  Widget _buildDefault(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: ScalarioColors.bgCard,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      child: Column(children: [
        Icon(Icons.pie_chart, size: 48, color: ScalarioColors.primary500),
        const SizedBox(height: ScalarioSpacing.space2),
        Text(props['title'] as String? ?? 'Répartition', style: ScalarioTypography.caption),
      ]),
    );
  }

  Widget _buildDonut(BuildContext context) {
    return SizedBox(
      height: 120, width: 120,
      child: CircularProgressIndicator(value: 0.7, color: ScalarioColors.primary500),
    );
  }

  Widget _buildMiniLegend(BuildContext context) {
    return Row(children: [
      Icon(Icons.pie_chart_outline, size: 32, color: ScalarioColors.primary500),
      const SizedBox(width: ScalarioSpacing.space2),
      Text(props['title'] as String? ?? '', style: ScalarioTypography.caption),
    ]);
  }
}
