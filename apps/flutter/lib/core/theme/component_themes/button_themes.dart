import 'package:flutter/material.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Theme `FilledButton` (action primaire par défaut).
///
/// Hauteur 48px, padding horizontal `space4`, radius `md`, fond primary,
/// typo `fontButton`. Spec STORY-002 AC-06.
FilledButtonThemeData buildFilledButtonTheme(ColorScheme colors) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      disabledBackgroundColor: ScalarioColors.neutral300,
      disabledForegroundColor: ScalarioColors.textDisabled,
      minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      textStyle: ScalarioTypography.fontButton,
      // Pas de teinte M3 — palette Scalario brut.
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// Theme `OutlinedButton` (action secondaire). Bordure 1.5px, fond
/// transparent, texte primary. Spec STORY-002 AC-07.
OutlinedButtonThemeData buildOutlinedButtonTheme(ColorScheme colors) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: colors.primary,
      disabledForegroundColor: ScalarioColors.textDisabled,
      minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
      ),
      side: BorderSide(
        color: colors.outline,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      textStyle: ScalarioTypography.fontButton,
    ),
  );
}

/// Theme `TextButton` (ghost). Pas de fond/bordure, texte primary, hauteur
/// 40px (plus dense que primary). Spec STORY-002 AC-08.
TextButtonThemeData buildTextButtonTheme(ColorScheme colors) {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: colors.primary,
      disabledForegroundColor: ScalarioColors.textDisabled,
      minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightSecondary),
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      textStyle: ScalarioTypography.fontButton,
    ),
  );
}

/// Theme `ElevatedButton` — gardé pour cohérence M3 mais aligné sur le style
/// `FilledButton` (Scalario n'utilise pas la distinction M3 elevated/filled).
ElevatedButtonThemeData buildElevatedButtonTheme(ColorScheme colors) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      disabledBackgroundColor: ScalarioColors.neutral300,
      disabledForegroundColor: ScalarioColors.textDisabled,
      elevation: 1,
      minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      textStyle: ScalarioTypography.fontButton,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
