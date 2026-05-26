import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar._({required this.variant, this.props = const {}});

  final String variant;
  final Map<String, dynamic> props;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'SyncStatusBar',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    return SyncStatusBar._(variant: config.variant, props: config.props);
  }

  @override
  Widget build(BuildContext context) {
    final style = switch (variant) {
      'synced' => (ScalarioColors.success500, Icons.check_circle, 'Synchronisé'),
      'syncing' => (ScalarioColors.primary500, Icons.sync, 'Synchronisation...'),
      'conflict' => (ScalarioColors.warning500, Icons.warning, 'Conflits à résoudre'),
      'offline' => (ScalarioColors.textDisabled, Icons.cloud_off, 'Hors ligne'),
      _ => (ScalarioColors.textDisabled, Icons.cloud_off, 'Hors ligne'),
    };
    final (color, icon, label) = style;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space3,
        vertical: ScalarioSpacing.space1,
      ),
      color: color.withAlpha(30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: ScalarioSpacing.space1),
          Text(label, style: ScalarioTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
