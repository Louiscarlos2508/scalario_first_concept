import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';

/// Construit les `ColorScheme` Material 3 light + dark à partir de
/// `ScalarioColors`.
///
/// On **ne passe pas par `ColorScheme.fromSeed`** : `fromSeed` génère une
/// palette algorithmique qui dévie des hex Scalario. On instancie le
/// `ColorScheme` à la main, en mappant chaque slot M3 sur un token précis.
///
/// Spec : `STORY-002` AC-01, AC-02, AC-03.
abstract final class ScalarioColorSchemeBuilder {
  static ColorScheme light() => const ColorScheme(
        brightness: Brightness.light,
        // Primary
        primary: ScalarioColors.primary500,
        onPrimary: ScalarioColors.white,
        primaryContainer: ScalarioColors.primary100,
        onPrimaryContainer: ScalarioColors.primary900,
        // Secondary — primary300 (teinte plus claire, usage outlined / chips)
        secondary: ScalarioColors.primary300,
        onSecondary: ScalarioColors.textPrimary,
        secondaryContainer: ScalarioColors.primary50,
        onSecondaryContainer: ScalarioColors.primary900,
        // Tertiary — réutilisé pour "info" Scalario
        tertiary: ScalarioColors.info500,
        onTertiary: ScalarioColors.white,
        tertiaryContainer: ScalarioColors.info100,
        onTertiaryContainer: ScalarioColors.primary900,
        // Error
        error: ScalarioColors.danger500,
        onError: ScalarioColors.white,
        errorContainer: ScalarioColors.danger100,
        onErrorContainer: ScalarioColors.danger700,
        // Surface — bgCard (white) pour les cards / dialogs / menus
        surface: ScalarioColors.bgCard,
        onSurface: ScalarioColors.textPrimary,
        surfaceContainerLowest: ScalarioColors.white,
        surfaceContainerLow: ScalarioColors.neutral50,
        surfaceContainer: ScalarioColors.neutral50,
        surfaceContainerHigh: ScalarioColors.neutral100,
        surfaceContainerHighest: ScalarioColors.neutral100,
        onSurfaceVariant: ScalarioColors.textSecondary,
        // Outline / borders
        outline: ScalarioColors.borderDefault,
        outlineVariant: ScalarioColors.neutral100,
        // Inverse / shadow / scrim
        inverseSurface: ScalarioColors.neutral900,
        onInverseSurface: ScalarioColors.neutral50,
        inversePrimary: ScalarioColors.primary300,
        shadow: Colors.black,
        scrim: Colors.black,
      );

  static ColorScheme dark() => const ColorScheme(
        brightness: Brightness.dark,
        primary: ScalarioColors.primary300,
        onPrimary: ScalarioColors.primary900,
        primaryContainer: ScalarioColors.primary700,
        onPrimaryContainer: ScalarioColors.primary50,
        secondary: ScalarioColors.primary300,
        onSecondary: ScalarioColors.primary900,
        secondaryContainer: ScalarioColors.primary700,
        onSecondaryContainer: ScalarioColors.primary50,
        tertiary: ScalarioColors.info300,
        onTertiary: ScalarioColors.info900,
        tertiaryContainer: ScalarioColors.primary700,
        onTertiaryContainer: ScalarioColors.info50,
        error: ScalarioColors.danger300,
        onError: ScalarioColors.danger900,
        errorContainer: ScalarioColors.danger700,
        onErrorContainer: ScalarioColors.danger50,
        surface: ScalarioColors.neutral800,
        onSurface: ScalarioColors.neutral50,
        surfaceContainerLowest: ScalarioColors.neutral900,
        surfaceContainerLow: ScalarioColors.neutral850,
        surfaceContainer: ScalarioColors.neutral800,
        surfaceContainerHigh: ScalarioColors.neutral750,
        surfaceContainerHighest: ScalarioColors.neutral700,
        onSurfaceVariant: ScalarioColors.neutral200,
        outline: ScalarioColors.neutral600,
        outlineVariant: ScalarioColors.neutral700,
        inverseSurface: ScalarioColors.neutral50,
        onInverseSurface: ScalarioColors.neutral900,
        inversePrimary: ScalarioColors.primary400,
        shadow: Colors.black,
        scrim: Colors.black,
      );
}
