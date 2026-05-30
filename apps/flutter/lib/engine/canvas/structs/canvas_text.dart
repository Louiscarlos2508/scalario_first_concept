import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasText extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasText({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasText(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final text = config.props['text'] as String? ?? config.props['label'] as String? ?? '';
    final styleName = config.props['style'] as String?;

    final style = _resolveStyle(styleName)?.copyWith(color: null);

    return Text(text, style: style, overflow: TextOverflow.ellipsis);
  }

  TextStyle? _resolveStyle(String? name) {
    switch (name) {
      case 'display':
      case 'headlineLarge':
        return ScalarioTypography.display;
      case 'headline':
      case 'headlineMedium':
        return ScalarioTypography.headline;
      case 'title':
      case 'headlineSmall':
      case 'titleLarge':
        return ScalarioTypography.title;
      case 'bodyLarge':
      case 'bodyLg':
        return ScalarioTypography.bodyLg;
      case 'body':
      case 'bodyMedium':
      case 'titleMedium':
      case 'titleSmall':
        return ScalarioTypography.bodyMedium;
      case 'caption':
      case 'labelSmall':
      case 'overline':
        return ScalarioTypography.caption;
      default:
        return null;
    }
  }
}
