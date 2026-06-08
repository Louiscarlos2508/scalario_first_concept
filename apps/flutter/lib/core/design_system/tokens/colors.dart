import 'package:flutter/material.dart';

/// Tokens couleurs Scalario.
///
/// Source de vérité : `design-process/D-Design-System/tokens/colors.md`
/// (validée 2026-05-09). Tout ajout/modif ici doit être miroir du markdown,
/// sinon les snapshot tests échouent.
abstract final class ScalarioColors {
  // ---------------------------------------------------------------------------
  // Palette primaire
  // ---------------------------------------------------------------------------
  static const Color primary50 = Color(0xFFEBF5FB);
  static const Color primary100 = Color(0xFFD6EAF8);
  static const Color primary300 = Color(0xFF85C1E9);
  static const Color primary400 = Color(0xFF5DADE2);
  static const Color primary500 = Color(0xFF2980B9);
  static const Color primary700 = Color(0xFF1E5F8E);
  static const Color primary900 = Color(0xFF1A3A5C);

  // ---------------------------------------------------------------------------
  // Sémantiques — Succès
  // ---------------------------------------------------------------------------
  static const Color success100 = Color(0xFFD5F5E3);
  static const Color success500 = Color(0xFF27AE60);
  static const Color success700 = Color(0xFF1D6A35);

  // ---------------------------------------------------------------------------
  // Sémantiques — Warning
  // ---------------------------------------------------------------------------
  static const Color warning100 = Color(0xFFFDEBD0);
  static const Color warning500 = Color(0xFFE67E22);
  static const Color warning700 = Color(0xFF935116);

  // ---------------------------------------------------------------------------
  // Sémantiques — Danger
  // ---------------------------------------------------------------------------
  static const Color danger50 = Color(0xFFFEF5F5);
  static const Color danger100 = Color(0xFFFADBD8);
  static const Color danger300 = Color(0xFFF1948A);
  static const Color danger500 = Color(0xFFE74C3C);
  static const Color danger700 = Color(0xFF922B21);
  static const Color danger900 = Color(0xFF6B1A14);

  // ---------------------------------------------------------------------------
  // Sémantiques — Info
  // ---------------------------------------------------------------------------
  static const Color info50 = Color(0xFFF4F9FC);
  static const Color info100 = Color(0xFFD6EAF8);
  static const Color info300 = Color(0xFF7FBADA);
  static const Color info500 = Color(0xFF2471A3);
  static const Color info900 = Color(0xFF154360);

  // ---------------------------------------------------------------------------
  // Neutres
  // ---------------------------------------------------------------------------
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral750 = Color(0xFF1E293B);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral850 = Color(0xFF0F172A);
  static const Color neutral900 = Color(0xFF020617);
  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Tokens d'application — Light (mode par défaut)
  // ---------------------------------------------------------------------------
  static const Color bgPage = neutral50;
  static const Color bgCard = white;
  static const Color bgOverlay = Color(0x80000000); // rgba(0,0,0,0.5)
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textDisabled = neutral500;
  static const Color borderDefault = neutral300;
  static const Color borderFocus = primary500;
  static const Color interactivePrimary = primary500;
  static const Color interactiveDanger = danger500;

  // ---------------------------------------------------------------------------
  // Tokens d'application — Dark (placeholders, finalisés en STORY-002)
  // ---------------------------------------------------------------------------
  // Palette dark-first : on inverse les neutres et on assombrit la surface.
  // Les hex spécifiques seront affinés par STORY-002 (ColorScheme.dark + ThemeExtensions).
  static const Color bgPageDark = neutral900;
  static const Color bgCardDark = Color(0xFF22223A); // neutral-900 + 1 step lighter
  static const Color textPrimaryDark = neutral50;
  static const Color textSecondaryDark = neutral300;
  static const Color textDisabledDark = neutral500;
  static const Color borderDefaultDark = neutral700;
}
