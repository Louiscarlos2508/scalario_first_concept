import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Direction du delta affiché sous la valeur d'un KPI.
enum KpiDeltaDirection { up, down, neutral }

/// KPI card Scalario — version publique avec delta optionnel.
/// Source : Figma node 4:2 — section 8 (KPI Cards).
///
/// Layout :
/// - Icône 24×24 dans un carré 40×40 (radius 8) bg `chipActionBg` (par défaut)
/// - Valeur (mono Bold 20) sur 1 ligne (ellipsis si overflow)
/// - Label (12 secondary)
/// - Delta optionnel (`▲` / `▼` + texte) coloré success/error/secondary
class ScalarioKpiCard extends StatelessWidget {
  const ScalarioKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.deltaText,
    this.deltaDirection,
    this.iconBgColor,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? deltaText;
  final KpiDeltaDirection? deltaDirection;
  final Color? iconBgColor;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  Color _deltaColor() {
    switch (deltaDirection) {
      case KpiDeltaDirection.up:
        return AppColors.success;
      case KpiDeltaDirection.down:
        return AppColors.error;
      case KpiDeltaDirection.neutral:
      case null:
        return AppColors.textSecondary;
    }
  }

  String _deltaArrow() {
    switch (deltaDirection) {
      case KpiDeltaDirection.up:
        return '▲ ';
      case KpiDeltaDirection.down:
        return '▼ ';
      case KpiDeltaDirection.neutral:
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor ?? AppColors.chipActionBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineLarge.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
          if (deltaText != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_deltaArrow()}$deltaText',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _deltaColor(),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    final card = Card(child: body);
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}
