import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Tokens typographie Scalario.
///
/// Source de vérité : `design-process/D-Design-System/tokens/typography.md`
/// (validée 2026-05-09).
///
/// Familles :
/// - **Inter** (via `GoogleFonts.inter`) — labels, titres, corps de texte.
/// - **Roboto Mono** (via `GoogleFonts.robotoMono`) — montants FCFA, KPI values,
///   totaux POS, codes PIN. Tout chiffre temps réel doit éviter le layout shift.
///
/// Convention : tout token suffixé `*Mono` ou contenant un montant utilise
/// Roboto Mono. Les autres utilisent Inter.
///
/// Note d'implémentation : tous les styles sont des `static final` pour être
/// mémoïsés. Cela évite de relancer un `GoogleFonts.inter(...)` (et donc une
/// requête de chargement) à chaque accès — important pour les tests et les
/// builds widgets répétés.
abstract final class ScalarioTypography {
  static const String interFamily = 'Inter';
  static const String robotoMonoFamily = 'Roboto Mono';

  // Fallback explicite pour les surfaces sans connexion lors du tout premier
  // chargement. `google_fonts` cache les polices après la première session.
  static const List<String> fallback = <String>[
    'system-ui',
    '-apple-system',
    'sans-serif',
  ];

  // ---------------------------------------------------------------------------
  // Échelle typographique — 9 styles
  // ---------------------------------------------------------------------------
  static final TextStyle display = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle headline = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle title = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ScalarioColors.textSecondary,
  );

  static final TextStyle captionMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle overline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
    color: ScalarioColors.textSecondary,
  );

  // ---------------------------------------------------------------------------
  // Variantes Mono — toute valeur numérique temps réel
  // ---------------------------------------------------------------------------
  static final TextStyle displayMono = GoogleFonts.robotoMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle bodyMono = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle bodyMediumMono = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: ScalarioColors.textPrimary,
  );

  static final TextStyle captionMono = GoogleFonts.robotoMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ScalarioColors.textSecondary,
  );

  // ---------------------------------------------------------------------------
  // Tokens d'application — alias sémantiques
  // ---------------------------------------------------------------------------
  /// Valeur numérique principale d'un KPICard (Roboto Mono, anti-layout-shift).
  static TextStyle get fontKpiValue => displayMono;

  /// Label sous la valeur d'un KPICard.
  static TextStyle get fontKpiLabel => caption;

  /// Variation vs hier dans un KPICard (`+12%`, `−3%`).
  static TextStyle get fontKpiDelta => captionMedium;

  /// Label d'un ActionButton.
  static TextStyle get fontButton => bodyMedium;

  /// Label au-dessus d'un input.
  static TextStyle get fontInputLabel => captionMedium;

  /// Valeur saisie dans un input (Roboto Mono si numérique, sinon body).
  static TextStyle get fontInputValue => body;

  /// Hint / placeholder dans un input.
  static TextStyle get fontInputHint => caption;

  /// Texte d'un AlertBanner.
  static TextStyle get fontBannerText => bodyMedium;

  /// Ligne principale d'un item de liste.
  static TextStyle get fontListPrimary => bodyMedium;

  /// Ligne secondaire d'un item de liste (timestamp, métadata).
  static TextStyle get fontListSecondary => caption;

  /// Titre de section (intra-page).
  static TextStyle get fontSectionTitle => title;

  /// Titre de page (top-level).
  static TextStyle get fontPageTitle => headline;
}
