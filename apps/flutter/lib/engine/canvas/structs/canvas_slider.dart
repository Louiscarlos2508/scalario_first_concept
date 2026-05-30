import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasSlider extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasSlider({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasSlider(config: config, ctx: ctx);
  }

  @override
  State<CanvasSlider> createState() => _CanvasSliderState();
}

class _CanvasSliderState extends State<CanvasSlider> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    _value = (widget.config.props['value'] as num? ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.props['label'] as String? ?? widget.config.props['text'] as String? ?? '';
    final min = (widget.config.props['min'] as num? ?? 0).toDouble();
    final max = (widget.config.props['max'] as num? ?? 100).toDouble();
    final divisions = widget.config.props['divisions'] as int?;
    final showValue = widget.config.props['showValue'] as bool? ?? true;
    final suffix = widget.config.props['suffix'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label.isNotEmpty) Text(label, style: ScalarioTypography.fontKpiLabel),
            if (showValue)
              Text(
                '${_value.toStringAsFixed(0)}$suffix',
                style: ScalarioTypography.fontKpiValue.copyWith(fontSize: 13),
              ),
          ],
        ),
        Slider(
          value: _value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onChanged: (v) => setState(() => _value = v),
        ),
      ],
    );
  }
}
