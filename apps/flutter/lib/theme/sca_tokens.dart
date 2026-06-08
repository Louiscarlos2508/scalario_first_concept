// ============================================================
// sca_tokens.dart
// Design Tokens extraits du Figma Twenty (file: xt8O9mFeLl46C5InWwoMrN)
// Source of truth pour TOUS les composants Scalario.
// ============================================================
import 'package:flutter/material.dart';

/// Border Radius — extrait du Figma Twenty
abstract class ScaRadius {
  static const double xs = 2.0;   // border.radius.xs
  static const double sm = 4.0;   // border.radius.sm
  static const double md = 6.0;   // border.radius.md
  static const double lg = 8.0;   // border.radius.lg
  static const double xl = 12.0;  // border.radius.xl
  static const double full = 9999.0; // pill
}

/// Spacing Scale — extrait du Figma Twenty
abstract class ScaSpacing {
  static const double s05 = 2.0;   // spacing[0.5]
  static const double s1 = 4.0;    // spacing[1]
  static const double s15 = 6.0;   // spacing[1.5]
  static const double s2 = 8.0;    // spacing[2]
  static const double s3 = 12.0;   // spacing[3]
  static const double s4 = 16.0;   // spacing[4]
  static const double s5 = 20.0;   // spacing[5]
  static const double s6 = 24.0;   // spacing[6]
  static const double s7 = 28.0;   // spacing[7] = item height normal
  static const double s8 = 32.0;   // spacing[8] = item height mobile
  static const double s10 = 40.0;  // spacing[10]
  static const double s12 = 48.0;  // spacing[12]
}

/// Animation — extrait du Figma Twenty
abstract class ScaAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300); // animation.duration.normal
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}

/// Shadows — extrait du Figma Twenty (BoxShadow light/dark/Strong/SuperHeavy)
abstract class ScaShadows {
  /// BoxShadow/light/Light — utilisé pour cartes, dropdowns légers
  static const List<BoxShadow> light = [
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity black
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity black
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// BoxShadow/light/Strong — utilisé pour modals, right-drawer
  static const List<BoxShadow> strong = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity black
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x14000000), // 8% opacity black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// BoxShadow/dark/SuperHeavy — utilisé pour menus contextuels
  static const List<BoxShadow> superHeavy = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity black
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity black
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];
}

/// Couleurs sémantiques extraites du Figma Twenty
abstract class ScaColors {
  // Neutrals (identiques à colors.dart mais ici centralisés)
  static const Color bgPrimary = Color(0xFFFFFFFF);     // background.primary
  static const Color bgSecondary = Color(0xFFF9F9F9);   // background.secondary
  static const Color bgTertiary = Color(0xFFF3F3F3);    // background.tertiary

  static const Color transparentLight = Color(0x0A000000); // background.transparent.light
  static const Color transparentMedium = Color(0x14000000); // background.transparent.medium

  // Borders
  static const Color borderLight = Color(0xFFE8E8E8);   // border.color.light
  static const Color borderMedium = Color(0xFFD9D9D9);  // border.color.medium (hover)
  static const Color borderStrong = Color(0xFF9E9E9E);  // border.color.strong

  // Fonts
  static const Color fontPrimary = Color(0xFF1A1A1A);   // font.color.primary
  static const Color fontSecondary = Color(0xFF4A4A4A); // font.color.secondary
  static const Color fontTertiary = Color(0xFF9E9E9E);  // font.color.tertiary
  static const Color fontLight = Color(0xFFBDBDBD);     // font.color.light

  // Focus ring (blue accent Twenty)
  static const Color focusRing = Color(0xFF1C68F5);     // color.blue
  static const Color focusRingLight = Color(0x1A1C68F5); // blue 10%

  // Status colors (inspirés du Figma)
  static const Color successBg = Color(0xFFEDF7EE);
  static const Color successFg = Color(0xFF1F7A32);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color warningFg = Color(0xFF8B5E00);
  static const Color dangerBg = Color(0xFFFEECEB);
  static const Color dangerFg = Color(0xFFB71C1C);
  static const Color infoBg = Color(0xFFEBF2FE);
  static const Color infoFg = Color(0xFF1C68F5);
  static const Color neutralBg = Color(0xFFF3F3F3);
  static const Color neutralFg = Color(0xFF4A4A4A);
}

/// Navigation Drawer
abstract class ScaNavDrawer {
  static const double collapsedWidth = 56.0;
  static const double expandedWidth = 240.0;
  static const double itemHeight = ScaSpacing.s7; // 28px
  static const double itemHeightMobile = ScaSpacing.s8; // 32px
}
