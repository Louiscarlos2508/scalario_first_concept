import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class StatCard extends StatelessWidget {
  const StatCard._({required this.props, required this.variant});

  final Map<String, dynamic> props;
  final String variant;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'StatCard',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    return StatCard._(props: config.props, variant: config.variant);
  }

  @override
  Widget build(BuildContext context) {
    final label = props['label'] as String? ?? '';
    final value = props['value'] as String? ?? '—';
    final delta = props['delta'] as String?;
    final deltaPos = props['delta_positive'] as bool? ?? true;

    final arrow = variant == 'trend-up'
        ? Icon(Icons.arrow_upward, size: 14, color: ScalarioColors.success500)
        : variant == 'trend-down'
            ? Icon(Icons.arrow_downward, size: 14, color: ScalarioColors.danger500)
            : null;

    final backgroundColor = variant == 'flat' ? ScalarioColors.bgCard : null;

    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space3),
      decoration: BoxDecoration(
        color: backgroundColor ?? ScalarioColors.bgCard,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: ScalarioTypography.caption),
        const SizedBox(height: ScalarioSpacing.space1),
        Row(children: [
          Text(value, style: ScalarioTypography.fontKpiValue),
          if (arrow != null) ...[const SizedBox(width: 4), arrow],
        ]),
        if (delta != null) Text(delta, style: ScalarioTypography.caption),
      ]),
    );
  }
}
