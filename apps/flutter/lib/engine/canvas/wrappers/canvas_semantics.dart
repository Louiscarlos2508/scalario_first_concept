import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';

class CanvasSemantics extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasSemantics({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasSemantics(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final label = config.props['label'] as String? ?? '';
    final hint = config.props['hint'] as String?;
    final isButton = config.props['button'] == true;
    final isHeader = config.props['header'] == true;
    final exclude = config.props['exclude_semantics'] == true;
    if (exclude) return const SizedBox.shrink();

    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      child: const SizedBox.shrink(),
    );
  }
}
