import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasHeading extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasHeading({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasHeading(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final title = config.props['title'] as String? ?? config.props['text'] as String? ?? '';
    final subtitle = config.props['subtitle'] as String?;
    final iconName = config.props['icon'] as String?;
    final divider = config.props['divider'] as bool? ?? true;

    final icon = iconName != null ? _iconFor(iconName) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: ScalarioIconSize.sm, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: ScalarioSpacing.space2),
            ],
            Expanded(
              child: Text(
                title,
                style: ScalarioTypography.title,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: ScalarioSpacing.space1),
          Text(subtitle, style: ScalarioTypography.caption),
        ],
        if (divider) ...[
          const SizedBox(height: ScalarioSpacing.space3),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ],
    );
  }

  static IconData _iconFor(String name) {
    switch (name) {
      case 'dashboard': return Icons.dashboard;
      case 'show_chart': return Icons.show_chart;
      case 'trending_up': return Icons.trending_up;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'inventory': return Icons.inventory;
      case 'receipt': return Icons.receipt;
      case 'calendar_month': return Icons.calendar_month;
      case 'attach_money': return Icons.attach_money;
      case 'people': return Icons.people;
      case 'settings': return Icons.settings;
      case 'info': return Icons.info;
      case 'warning': return Icons.warning;
      case 'check_circle': return Icons.check_circle;
      case 'star': return Icons.star;
      default: return Icons.dashboard;
    }
  }
}
