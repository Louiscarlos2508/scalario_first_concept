import 'package:flutter/material.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/icons.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Theme `Badge` (M3). Petites pastilles de notification.
/// Spec STORY-002 AC-14.
BadgeThemeData buildBadgeTheme(ColorScheme colors) {
  return BadgeThemeData(
    backgroundColor: colors.error,
    textColor: colors.onError,
    smallSize: 8,
    largeSize: 16,
    textStyle: ScalarioTypography.overline.copyWith(
      color: colors.onError,
    ),
  );
}

/// Theme `Divider` — flat 1px, couleur outline.
/// Spec STORY-002 AC-14.
DividerThemeData buildDividerTheme(ColorScheme colors) {
  return DividerThemeData(
    color: colors.outline,
    thickness: 1,
    space: 1,
  );
}

/// Theme `Icon` global — taille `md` par défaut, couleur onSurface.
/// Spec STORY-002 AC-14.
IconThemeData buildIconTheme(ColorScheme colors) {
  return IconThemeData(
    color: colors.onSurface,
    size: ScalarioIconSize.md,
  );
}

/// Theme `SnackBar` — Scalario typographie + radius `md`.
SnackBarThemeData buildSnackBarTheme(ColorScheme colors) {
  return SnackBarThemeData(
    backgroundColor: colors.inverseSurface,
    contentTextStyle: ScalarioTypography.body.copyWith(
      color: colors.onInverseSurface,
    ),
    actionTextColor: colors.inversePrimary,
    behavior: SnackBarBehavior.floating,
    elevation: 2,
  );
}

/// Theme `Tooltip` — fond inverse, padding compact.
TooltipThemeData buildTooltipTheme(ColorScheme colors) {
  return TooltipThemeData(
    decoration: BoxDecoration(
      color: ScalarioColors.neutral900.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
    ),
    textStyle: ScalarioTypography.caption.copyWith(
      color: ScalarioColors.white,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space2,
      vertical: ScalarioSpacing.space1,
    ),
  );
}
