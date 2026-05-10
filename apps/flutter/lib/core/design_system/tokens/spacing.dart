import 'package:flutter/material.dart';

/// Tokens espacements Scalario — grille 4px.
///
/// Source de vérité : `design-process/D-Design-System/tokens/spacing.md`
/// (validée 2026-05-09).
abstract final class ScalarioSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
}

/// Tokens border-radius.
abstract final class ScalarioRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;
}

/// Tokens d'élévation — `BoxShadow`s prêts à l'emploi.
///
/// Chaque token retourne une `List<BoxShadow>` (vide pour `e0`).
abstract final class ScalarioElevation {
  static const List<BoxShadow> e0 = <BoxShadow>[];

  static const List<BoxShadow> e1 = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,0.08)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> e2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000), // rgba(0,0,0,0.12)
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> e3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x29000000), // rgba(0,0,0,0.16)
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> e4 = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000), // rgba(0,0,0,0.20)
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}

/// Tokens layout — dimensions de chrome (padding page, sidebar, navs).
///
/// Sépare les chiffres mobiles des chiffres web pour éviter les magic numbers
/// dans les Scaffolds et CustomScrollViews.
abstract final class ScalarioLayout {
  // Mobile (Android)
  static const double mobilePagePaddingH = 16;
  static const double mobilePagePaddingTop = 16;

  // Web (Flutter PWA / Desktop)
  static const double webMaxWidth = 1200;
  static const double webPagePaddingH = 32;
  static const double sidebarWidth = 240;

  // Chromes communs
  static const double bottomNavHeight = 56;
  static const double syncBarHeight = 28;
  static const double appBarHeight = 56;
  static const double listRowHeight = 56;

  // Composants
  static const double buttonHeightPrimary = 48;
  static const double buttonHeightSecondary = 40;
  static const double inputHeight = 48;
  static const double chipHeight = 32;
}
