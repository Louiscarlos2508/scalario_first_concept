import 'package:flutter/material.dart';

import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Theme `Card`. Surface tint coupé (palette neutre Scalario), élévation 1,
/// radius `md`, padding 0 (le contenu gère son propre padding).
/// Spec STORY-002 AC-09.
CardThemeData buildCardTheme(ColorScheme colors) {
  return CardThemeData(
    color: colors.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: colors.shadow,
    elevation: 1,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    clipBehavior: Clip.antiAlias,
  );
}

/// Theme `Dialog` / `AlertDialog`. Radius `lg`, fond surface, élévation `e3`,
/// padding `space5`. Spec STORY-002 AC-11.
DialogThemeData buildDialogTheme(ColorScheme colors) {
  return DialogThemeData(
    backgroundColor: colors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.lg),
    ),
    titleTextStyle: ScalarioTypography.title,
    contentTextStyle: ScalarioTypography.body,
    actionsPadding: const EdgeInsets.fromLTRB(
      ScalarioSpacing.space5,
      ScalarioSpacing.space2,
      ScalarioSpacing.space5,
      ScalarioSpacing.space5,
    ),
  );
}

/// Theme `AppBar`. Fond `bgPage`, élévation 0, titre `fontPageTitle`.
/// Spec STORY-002 AC-12.
AppBarTheme buildAppBarTheme(ColorScheme colors) {
  return AppBarTheme(
    backgroundColor: colors.surface,
    foregroundColor: colors.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: ScalarioTypography.fontPageTitle.copyWith(
      color: colors.onSurface,
    ),
    iconTheme: IconThemeData(
      color: colors.onSurface,
      size: 24,
    ),
    toolbarHeight: ScalarioLayout.appBarHeight,
  );
}

/// Theme `BottomSheet`. Surface tint coupé (cohérence neutre Scalario).
BottomSheetThemeData buildBottomSheetTheme(ColorScheme colors) {
  return BottomSheetThemeData(
    backgroundColor: colors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    modalElevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ScalarioRadius.lg),
      ),
    ),
  );
}
