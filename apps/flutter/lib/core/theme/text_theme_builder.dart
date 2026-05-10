import 'package:flutter/material.dart';

import '../design_system/tokens/typography.dart';

/// Construit le `TextTheme` Material 3 à partir des 9 styles de
/// `ScalarioTypography`.
///
/// Mapping spec STORY-002 AC-04 :
/// - `displayLarge`  → `display`
/// - `headlineLarge` → `headline`
/// - `titleLarge`    → `title`
/// - `bodyLarge`     → `bodyLg`
/// - `bodyMedium`    → `body`
/// - `labelLarge`    → `bodyMedium` (label dense)
/// - `bodySmall`     → `caption`
/// - `labelSmall`    → `captionMedium`
/// - `labelMedium`   → `overline`
///
/// Note : `Theme.of(context).textTheme.bodyMedium` doit rendre Inter 14sp
/// regular (AC-05). Le `colorScheme` n'est pas injecté dans le `TextTheme` —
/// les couleurs viennent déjà des tokens `ScalarioTypography`. Les composants
/// individuels qui veulent rebrand la couleur le font via `style.copyWith`.
abstract final class ScalarioTextThemeBuilder {
  static TextTheme build() => TextTheme(
        // Display — KPI géants, écrans hero
        displayLarge: ScalarioTypography.display,
        displayMedium: ScalarioTypography.display,
        displaySmall: ScalarioTypography.headline,
        // Headline — titres de page
        headlineLarge: ScalarioTypography.headline,
        headlineMedium: ScalarioTypography.headline,
        headlineSmall: ScalarioTypography.title,
        // Title — titres de section / cards
        titleLarge: ScalarioTypography.title,
        titleMedium: ScalarioTypography.bodyMedium,
        titleSmall: ScalarioTypography.captionMedium,
        // Body — corps de texte
        bodyLarge: ScalarioTypography.bodyLg,
        bodyMedium: ScalarioTypography.body,
        bodySmall: ScalarioTypography.caption,
        // Label — chips, badges, boutons (M3 utilise labelLarge pour boutons)
        labelLarge: ScalarioTypography.bodyMedium,
        labelMedium: ScalarioTypography.overline,
        labelSmall: ScalarioTypography.captionMedium,
      );
}
