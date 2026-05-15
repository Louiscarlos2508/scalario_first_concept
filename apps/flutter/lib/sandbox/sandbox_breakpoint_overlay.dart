// STORY-009 — Sandbox dev-only.
//
// Wrap d'un widget enfant dans une `MediaQuery` overlay de taille fixe afin
// de simuler un breakpoint (mobile / tablet / desktop) sans changer de device
// (AC-04, AC-05).

import 'package:flutter/material.dart';

/// Breakpoints simulables dans le sandbox.
enum SandboxBreakpoint {
  mobile(360, 740, 'Mobile · 360×740'),
  tablet(768, 1024, 'Tablet · 768×1024'),
  desktop(1440, 900, 'Desktop · 1440×900');

  const SandboxBreakpoint(this.width, this.height, this.label);
  final double width;
  final double height;
  final String label;
}

/// Encapsule `child` dans un viewport contraint de largeur/hauteur fixées au
/// breakpoint sélectionné. Le `MediaQueryData` est overridé pour que les
/// composants qui interrogent `MediaQuery.of(context).size` voient les
/// dimensions simulées (et non celles du device).
class SandboxBreakpointOverlay extends StatelessWidget {
  const SandboxBreakpointOverlay({
    super.key,
    required this.breakpoint,
    required this.child,
  });

  final SandboxBreakpoint breakpoint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData parent = MediaQuery.of(context);
    final Size simulated = Size(breakpoint.width, breakpoint.height);
    return Center(
      child: ClipRect(
        child: SizedBox(
          width: breakpoint.width,
          height: breakpoint.height,
          child: MediaQuery(
            data: parent.copyWith(size: simulated),
            child: Material(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
