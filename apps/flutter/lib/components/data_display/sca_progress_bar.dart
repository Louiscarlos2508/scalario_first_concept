import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';

class ScaProgressBar extends StatelessWidget {
  final ComponentConfig config;

  const ScaProgressBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final value = (config.props['value'] as num?)?.toDouble() ?? 0.0;
    final showLabel = (config.props['show_label'] as bool?) ?? false;
    final colorStr = config.props['color'] as String? ?? 'primary';
    final Color barColor = colorStr == 'success'
        ? Colors.green[500]!
        : colorStr == 'warning'
            ? Colors.orange[500]!
            : colorStr == 'error'
                ? Colors.red[500]!
                : ScalarioColors.primary500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: ScalarioColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: ScalarioColors.neutral100,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
