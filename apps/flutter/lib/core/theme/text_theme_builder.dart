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
/// regular (AC-05). Les couleurs sont **rebindées au ColorScheme actif** :
/// styles principaux → `onSurface`, styles secondaires (caption / overline) →
/// `onSurfaceVariant`. Sans ça, le texte resterait `textPrimary` (sombre)
/// même en dark mode → invisible.
abstract final class ScalarioTextThemeBuilder {
  static TextTheme build(ColorScheme colors) {
    final Color primary = colors.onSurface;
    final Color secondary = colors.onSurfaceVariant;
    return TextTheme(
      // Display — KPI géants, écrans hero
      displayLarge: ScalarioTypography.display.copyWith(color: primary),
      displayMedium: ScalarioTypography.display.copyWith(color: primary),
      displaySmall: ScalarioTypography.headline.copyWith(color: primary),
      // Headline — titres de page
      headlineLarge: ScalarioTypography.headline.copyWith(color: primary),
      headlineMedium: ScalarioTypography.headline.copyWith(color: primary),
      headlineSmall: ScalarioTypography.title.copyWith(color: primary),
      // Title — titres de section / cards
      titleLarge: ScalarioTypography.title.copyWith(color: primary),
      titleMedium: ScalarioTypography.bodyMedium.copyWith(color: primary),
      titleSmall: ScalarioTypography.captionMedium.copyWith(color: primary),
      // Body — corps de texte
      bodyLarge: ScalarioTypography.bodyLg.copyWith(color: primary),
      bodyMedium: ScalarioTypography.body.copyWith(color: primary),
      bodySmall: ScalarioTypography.caption.copyWith(color: secondary),
      // Label — chips, badges, boutons (M3 utilise labelLarge pour boutons)
      labelLarge: ScalarioTypography.bodyMedium.copyWith(color: primary),
      labelMedium: ScalarioTypography.overline.copyWith(color: secondary),
      labelSmall: ScalarioTypography.captionMedium.copyWith(color: primary),
    );
  }
}
