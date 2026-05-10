import 'package:flutter/material.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Theme `DataTable`. Headings denses (overline 12sp), data 14sp body,
/// background neutre, divider 1px max — pas de chrome inutile.
/// Spec STORY-002 AC-14, edge case "DataTable Material 3 sur Web".
DataTableThemeData buildDataTableTheme(ColorScheme colors) {
  return DataTableThemeData(
    headingTextStyle: ScalarioTypography.captionMedium,
    dataTextStyle: ScalarioTypography.body,
    headingRowColor: WidgetStateProperty.all(colors.surfaceContainerHighest),
    dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.hovered)) {
        return colors.surfaceContainer;
      }
      return null;
    }),
    headingRowHeight: ScalarioLayout.listRowHeight,
    dataRowMinHeight: ScalarioLayout.listRowHeight,
    dataRowMaxHeight: ScalarioLayout.listRowHeight,
    horizontalMargin: ScalarioSpacing.space4,
    columnSpacing: ScalarioSpacing.space6,
    dividerThickness: 1,
  );
}

/// Theme `BottomNavigationBar` — usage mobile (web utilisera NavigationRail
/// configuré ailleurs). Spec STORY-002 AC-14.
BottomNavigationBarThemeData buildBottomNavTheme(ColorScheme colors) {
  return BottomNavigationBarThemeData(
    backgroundColor: colors.surface,
    selectedItemColor: colors.primary,
    unselectedItemColor: ScalarioColors.textSecondary,
    selectedLabelStyle: ScalarioTypography.overline.copyWith(
      color: colors.primary,
    ),
    unselectedLabelStyle: ScalarioTypography.overline,
    type: BottomNavigationBarType.fixed,
    elevation: 4,
    showUnselectedLabels: true,
  );
}

/// Theme `NavigationBar` (M3) — variante moderne du BottomNavigationBar.
NavigationBarThemeData buildNavigationBarTheme(ColorScheme colors) {
  return NavigationBarThemeData(
    backgroundColor: colors.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: colors.primaryContainer,
    height: ScalarioLayout.bottomNavHeight + ScalarioSpacing.space2,
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
      if (states.contains(WidgetState.selected)) {
        return ScalarioTypography.overline.copyWith(color: colors.primary);
      }
      return ScalarioTypography.overline;
    }),
  );
}

/// Theme `FloatingActionButton`. Couleur primary, radius `lg`, label
/// `bodyMedium`. Spec STORY-002 AC-13.
FloatingActionButtonThemeData buildFabTheme(ColorScheme colors) {
  return FloatingActionButtonThemeData(
    backgroundColor: colors.primary,
    foregroundColor: colors.onPrimary,
    elevation: 4,
    focusElevation: 4,
    hoverElevation: 6,
    highlightElevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.lg),
    ),
    extendedTextStyle: ScalarioTypography.bodyMedium.copyWith(
      color: colors.onPrimary,
    ),
  );
}

/// Theme `Chip` — utilisé pour filtres, tags, statuts compacts.
ChipThemeData buildChipTheme(ColorScheme colors) {
  return ChipThemeData(
    backgroundColor: colors.surfaceContainer,
    selectedColor: colors.primaryContainer,
    disabledColor: ScalarioColors.neutral100,
    labelStyle: ScalarioTypography.captionMedium,
    secondaryLabelStyle: ScalarioTypography.captionMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space2,
      vertical: ScalarioSpacing.space1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.full),
      side: BorderSide(color: colors.outlineVariant),
    ),
  );
}

/// Theme `ListTile`.
ListTileThemeData buildListTileTheme(ColorScheme colors) {
  return ListTileThemeData(
    iconColor: colors.onSurface,
    textColor: colors.onSurface,
    titleTextStyle: ScalarioTypography.fontListPrimary,
    subtitleTextStyle: ScalarioTypography.fontListSecondary,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space4,
      vertical: ScalarioSpacing.space2,
    ),
    minVerticalPadding: ScalarioSpacing.space2,
  );
}
