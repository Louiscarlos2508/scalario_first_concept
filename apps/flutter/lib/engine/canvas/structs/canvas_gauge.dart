import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasGauge extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasGauge({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasGauge(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final label = config.props['label'] as String? ?? config.props['text'] as String? ?? '';
    final value = config.props['value'] as num? ?? 0;
    final min = config.props['min'] as num? ?? 0;
    final max = config.props['max'] as num? ?? 100;
    final suffix = config.props['suffix'] as String? ?? '%';
    final variant = config.props['variant'] as String? ?? 'linear';
    final colorName = config.props['color'] as String?;
    final height = config.props['height'] as num? ?? 10;

    final normalized = ((value - min) / math.max(max - min, 1)).clamp(0.0, 1.0);
    final barColor = _colorFor(colorName, normalized);

    switch (variant) {
      case 'circular':
        return _buildCircular(context, label, normalized, barColor, suffix);
      default:
        return _buildLinear(context, label, normalized, barColor, suffix, height.toDouble());
    }
  }

  Widget _buildLinear(
    BuildContext context,
    String label,
    double fraction,
    Color color,
    String suffix,
    double height,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ScalarioTypography.fontKpiLabel),
            Text(
              '${(fraction * 100).toStringAsFixed(0)}$suffix',
              style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: ScalarioSpacing.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(ScalarioRadius.full),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(ScalarioRadius.full),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircular(
    BuildContext context,
    String label,
    double fraction,
    Color color,
    String suffix,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${(fraction * 100).toStringAsFixed(0)}$suffix',
                style: ScalarioTypography.fontKpiValue.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: ScalarioSpacing.space1),
        Text(label, style: ScalarioTypography.fontKpiLabel),
      ],
    );
  }

  Color _colorFor(String? name, double fraction) {
    if (name != null) {
      switch (name) {
        case 'primary': return ScalarioColors.primary500;
        case 'success': return ScalarioColors.success500;
        case 'warning': return ScalarioColors.warning500;
        case 'danger': return ScalarioColors.danger500;
        case 'info': return ScalarioColors.info500;
      }
    }
    if (fraction < 0.33) return ScalarioColors.danger500;
    if (fraction < 0.66) return ScalarioColors.warning500;
    return ScalarioColors.success500;
  }
}
