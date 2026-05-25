import 'package:flutter/rendering.dart';

/// Breakpoints canoniques Scalario — Phase 1, 3 variantes fixes.
///
/// Basés sur `constraints.maxWidth` (LayoutBuilder), pas MediaQuery :
/// testable sans wrapper, supporte les sous-régions, évite les subscriptions.
enum Breakpoint { mobile, tablet, desktop }

/// Résout le [Breakpoint] depuis une largeur logique ou des [BoxConstraints].
///
/// Limites : < 600 → mobile | 600–1024 → tablet | > 1024 → desktop.
abstract final class BreakpointResolver {
  static Breakpoint fromWidth(double width) {
    if (width < 600) return Breakpoint.mobile;
    if (width <= 1024) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }

  static Breakpoint fromConstraints(BoxConstraints c) =>
      fromWidth(c.maxWidth);
}
