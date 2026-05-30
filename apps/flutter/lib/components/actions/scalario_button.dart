import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class ScalarioButton extends StatelessWidget {
  const ScalarioButton._({
    required this.props,
    required this.variant,
    this.onPressed,
  });

  final Map<String, dynamic> props;
  final String variant;
  final VoidCallback? onPressed;

  /// Hook global pour dispatcher les actions A2UI.
  /// Sera appelé quand un bouton avec `config.actions` est pressé.
  static void Function(Map<String, dynamic> action)? onAction;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'ScalarioButton',
      screenWidth: MediaQuery.of(ctx).size.width,
    );

    VoidCallback? onPressed;
    final actions = config.actions;
    if (actions != null && actions.isNotEmpty && onAction != null) {
      final action = actions.first;
      onPressed = () => onAction!(action);
    }

    return ScalarioButton._(
      props: config.props,
      variant: config.variant,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = (props['label'] ?? props['text'] ?? '') as String;
    final style = switch (variant) {
      'primary' => ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black),
      'secondary' => OutlinedButton.styleFrom(),
      'danger' => ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
      'ghost' => TextButton.styleFrom(),
      'icon-only' => null,
      _ => ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black),
    };

    if (variant == 'icon-only') {
      return IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: onPressed,
      );
    }

    return IntrinsicWidth(
      child: ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: Text(label, softWrap: false, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
