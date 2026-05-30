import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasBadge extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasBadge({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasBadge(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final label = config.props['label'] as String? ?? config.props['text'] as String? ?? '';
    final colorName = config.props['color'] as String? ?? 'default';
    final variant = config.props['variant'] as String? ?? 'filled';

    final (Color bg, Color fg) = _colorsFor(colorName, context, variant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ScalarioSpacing.space2, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ScalarioRadius.full),
        border: variant == 'outlined' ? Border.all(color: fg) : null,
      ),
      child: Text(
        label,
        style: ScalarioTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(String name, BuildContext context, String variant) {
    final cs = Theme.of(context).colorScheme;
    Color bg, fg;
    switch (name) {
      case 'success':
        bg = ScalarioColors.success100; fg = ScalarioColors.success700;
      case 'warning':
        bg = ScalarioColors.warning100; fg = ScalarioColors.warning700;
      case 'danger':
        bg = ScalarioColors.danger100; fg = ScalarioColors.danger500;
      case 'info':
        bg = ScalarioColors.info100; fg = ScalarioColors.info500;
      case 'primary':
        bg = ScalarioColors.primary100; fg = ScalarioColors.primary700;
      default:
        bg = cs.surfaceContainerHighest; fg = cs.onSurfaceVariant;
    }
    if (variant == 'dot') {
      return (fg, fg);
    }
    return (bg, fg);
  }
}
