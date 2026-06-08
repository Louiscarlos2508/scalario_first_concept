import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';

class ScaTypography extends StatelessWidget {
  final ComponentConfig config;

  const ScaTypography({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final text = (config.props['text'] as String?) ?? '';
    final variant = (config.props['variant'] as String?) ?? 'body';
    final colorProp = config.props['color'] as String?;
    final alignProp = (config.props['align'] as String?) ?? 'left';

    TextStyle style;
    switch (variant) {
      case 'h1':
        style = const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
        break;
      case 'h2':
        style = const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
        break;
      case 'h3':
        style = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
        break;
      case 'subtitle':
        style = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ScalarioColors.neutral500);
        break;
      case 'caption':
        style = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: ScalarioColors.neutral500);
        break;
      case 'body':
      default:
        style = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: ScalarioColors.neutral900);
        break;
    }

    if (colorProp != null) {
      if (colorProp == 'primary') style = style.copyWith(color: ScalarioColors.primary500);
      else if (colorProp == 'error') style = style.copyWith(color: Colors.red[600]);
      else if (colorProp == 'muted') style = style.copyWith(color: ScalarioColors.neutral500);
    }

    TextAlign textAlign = TextAlign.left;
    if (alignProp == 'center') textAlign = TextAlign.center;
    if (alignProp == 'right') textAlign = TextAlign.right;

    return Text(
      text,
      style: style,
      textAlign: textAlign,
    );
  }
}
