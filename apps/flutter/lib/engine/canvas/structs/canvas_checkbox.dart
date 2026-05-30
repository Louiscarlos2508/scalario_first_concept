import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasCheckbox extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasCheckbox({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasCheckbox(config: config, ctx: ctx);
  }

  @override
  State<CanvasCheckbox> createState() => _CanvasCheckboxState();
}

class _CanvasCheckboxState extends State<CanvasCheckbox> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checked = widget.config.props['checked'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.props['label'] as String? ?? widget.config.props['text'] as String? ?? '';

    return InkWell(
      onTap: () => setState(() => _checked = !_checked),
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ScalarioSpacing.space1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _checked,
                onChanged: (v) => setState(() => _checked = v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: ScalarioSpacing.space2),
              Text(label, style: ScalarioTypography.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
