import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';

class ScaChip extends StatelessWidget {
  final ComponentConfig config;

  const ScaChip({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final label = (config.props['label'] as String?) ?? '';
    final variant = config.props['variant'] ?? 'default'; // default, success, warning, error, info
    
    Color bgColor = ScalarioColors.neutral100;
    Color textColor = ScalarioColors.neutral700;
    Color borderColor = ScalarioColors.neutral200;

    if (variant == 'success') {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      borderColor = Colors.green[200]!;
    } else if (variant == 'warning') {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
      borderColor = Colors.orange[200]!;
    } else if (variant == 'error') {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      borderColor = Colors.red[200]!;
    } else if (variant == 'info') {
      bgColor = Colors.blue[50]!;
      textColor = Colors.blue[700]!;
      borderColor = Colors.blue[200]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4), // Flat styling comme Twenty
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
