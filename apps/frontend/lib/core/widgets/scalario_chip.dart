import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Variantes du chip Scalario.
/// Source : Figma node 4:2 — section 7 (Chips & badges).
enum ScalarioChipVariant { success, warning, error, action }

/// Chip / badge Scalario — taille fixe 32h, radius 16, label 12 Medium.
///
/// - Variantes `success`/`warning`/`error` : status (puce `●` par défaut).
/// - Variante `action` : action ajoutable (préfixe `+` par défaut, tinte primary).
///
/// Pour personnaliser le préfixe, passer [leadingIcon] (rendu via Icon)
/// ou [leadingText] (rendu via Text).
class ScalarioChip extends StatelessWidget {
  const ScalarioChip({
    super.key,
    required this.label,
    required this.variant,
    this.leadingIcon,
    this.leadingText,
    this.onTap,
  });

  final String label;
  final ScalarioChipVariant variant;
  final IconData? leadingIcon;
  final String? leadingText;
  final VoidCallback? onTap;

  _ChipColors get _colors {
    switch (variant) {
      case ScalarioChipVariant.success:
        return const _ChipColors(
          bg: AppColors.chipSuccessBg,
          border: AppColors.chipSuccessBorder,
          text: AppColors.chipSuccessText,
        );
      case ScalarioChipVariant.warning:
        return const _ChipColors(
          bg: AppColors.chipWarningBg,
          border: AppColors.chipWarningBorder,
          text: AppColors.chipWarningText,
        );
      case ScalarioChipVariant.error:
        return const _ChipColors(
          bg: AppColors.chipErrorBg,
          border: AppColors.chipErrorBorder,
          text: AppColors.chipErrorText,
        );
      case ScalarioChipVariant.action:
        return const _ChipColors(
          bg: AppColors.chipActionBg,
          border: AppColors.chipActionBorder,
          text: AppColors.chipActionText,
        );
    }
  }

  String get _defaultPrefix =>
      variant == ScalarioChipVariant.action ? '+ ' : '● ';

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: c.text,
      height: 1.0,
    );

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 14, color: c.text),
          const SizedBox(width: 6),
        ] else if (leadingText != null) ...[
          Text(leadingText!, style: textStyle),
          const SizedBox(width: 6),
        ] else
          Text(_defaultPrefix, style: textStyle),
        Text(label, style: textStyle),
      ],
    );

    final chip = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: content,
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: chip,
    );
  }
}

class _ChipColors {
  final Color bg;
  final Color border;
  final Color text;
  const _ChipColors({
    required this.bg,
    required this.border,
    required this.text,
  });
}
