import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasToggle extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasToggle({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasToggle(config: config, ctx: ctx);
  }

  @override
  State<CanvasToggle> createState() => _CanvasToggleState();
}

class _CanvasToggleState extends State<CanvasToggle> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _on = widget.config.props['active'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.props['label'] as String? ?? widget.config.props['text'] as String? ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: ScalarioTypography.bodyMedium),
          const SizedBox(width: ScalarioSpacing.space2),
        ],
        SizedBox(
          height: 32,
          child: Switch(
            value: _on,
            onChanged: (v) => setState(() => _on = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
