import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/actions/scalario_action_engine.dart';
import '../../engine/canvas_registry/bdui_action.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class ScalarioButton extends StatefulWidget {
  const ScalarioButton._({
    required this.props,
    required this.variant,
    this.actions,
  });

  final Map<String, dynamic> props;
  final String variant;
  final List<BduiAction>? actions;

  /// Hook global optionnel (utilisé par la Sandbox pour surcharger le moteur)
  static Future<void> Function(BuildContext context, List<BduiAction> actions)? onAction;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'ScalarioButton',
      screenWidth: MediaQuery.of(ctx).size.width,
    );

    return ScalarioButton._(
      props: config.props,
      variant: config.variant,
      actions: config.parsedActions,
    );
  }

  @override
  State<ScalarioButton> createState() => _ScalarioButtonState();
}

class _ScalarioButtonState extends State<ScalarioButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    final actions = widget.actions;
    if (actions == null || actions.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (ScalarioButton.onAction != null) {
        await ScalarioButton.onAction!(context, actions);
      } else {
        await ScalarioActionEngine.execute(context, actions);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = (widget.props['label'] ?? widget.props['text'] ?? '') as String;
    final borderRadius = BorderRadius.circular(6.0);
    final padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    Widget buildChild(Color color) {
      if (_isLoading) {
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      }
      return Text(label, softWrap: false, overflow: TextOverflow.ellipsis);
    }

    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;
    final VoidCallback? onPressed = (hasActions && !_isLoading) ? _handlePress : null;

    if (widget.variant == 'icon-only') {
      return IconButton(
        icon: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.more_horiz, color: ScalarioColors.textSecondary),
        onPressed: onPressed,
        splashRadius: 20,
      );
    }

    Widget button;
    switch (widget.variant) {
      case 'secondary':
        button = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ScalarioColors.textPrimary,
            side: const BorderSide(color: ScalarioColors.borderDefault),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: padding,
            elevation: 0,
          ),
          onPressed: onPressed,
          child: buildChild(ScalarioColors.textPrimary),
        );
        break;
      case 'danger':
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ScalarioColors.danger500,
            foregroundColor: ScalarioColors.white,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: padding,
            elevation: 0,
          ),
          onPressed: onPressed,
          child: buildChild(ScalarioColors.white),
        );
        break;
      case 'ghost':
        button = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ScalarioColors.textSecondary,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: padding,
          ),
          onPressed: onPressed,
          child: buildChild(ScalarioColors.textSecondary),
        );
        break;
      case 'primary':
      default:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ScalarioColors.interactivePrimary,
            foregroundColor: ScalarioColors.white,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: padding,
            elevation: 0,
          ),
          onPressed: onPressed,
          child: buildChild(ScalarioColors.white),
        );
        break;
    }

    return IntrinsicWidth(child: button);
  }
}

