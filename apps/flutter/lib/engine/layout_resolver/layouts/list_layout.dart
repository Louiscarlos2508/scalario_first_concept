import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/spacing.dart';
import '../../component_registry/component_config.dart';
import '../../component_registry/component_registry.dart';
import '../breakpoints.dart';
import '../screen_config.dart';

/// Layout `list` — 3 variantes responsives.
///
/// Zone mapping :
/// - main  : liste principale (plein écran mobile, flex tablet/desktop)
/// - aside : filtres — BottomSheet mobile (trigger dans AppBar, hors scope),
///           panneau fixe 240dp gauche tablet/desktop
/// - kpis  : ignoré Phase 1
/// - actions : ignoré (navigation gérée au niveau screen)
///
/// Detail panel (master-detail desktop) : Phase 1 = absent (zones.detail n'existe
/// pas encore dans ScreenConfig) → desktop reste 2 colonnes (aside + main).
class ListLayout extends StatelessWidget {
  const ListLayout({
    super.key,
    required this.config,
    required this.registry,
  });

  final ScreenConfig config;
  final ComponentRegistry registry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        return switch (BreakpointResolver.fromConstraints(constraints)) {
          Breakpoint.mobile => _mobile(ctx),
          Breakpoint.tablet => _tablet(ctx),
          Breakpoint.desktop => _desktop(ctx),
        };
      },
    );
  }

  // ── Mobile (< 600) ─────────────────────────────────────────────────────────
  // aside (filtres) → BottomSheet déclenché depuis l'AppBar du screen (hors scope).
  // detail → navigation vers screen séparé (hors scope).
  Widget _mobile(BuildContext ctx) {
    if (!_hasZone(config.zones.main)) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioLayout.mobilePagePaddingH,
        vertical: ScalarioSpacing.space4,
      ),
      children: _buildZone(config.zones.main!, ctx),
    );
  }

  // ── Tablet (600–1024) ───────────────────────────────────────────────────────
  // aside à gauche (240dp fixe), main à droite (flex). detail ignoré.
  Widget _tablet(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_hasZone(config.zones.aside)) ...<Widget>[
          SizedBox(
            width: ScalarioLayout.sidebarWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildZone(config.zones.aside!, ctx),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        Expanded(
          child: _hasZone(config.zones.main)
              ? ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ScalarioLayout.mobilePagePaddingH,
                    vertical: ScalarioSpacing.space4,
                  ),
                  children: _buildZone(config.zones.main!, ctx),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Desktop (> 1024) ────────────────────────────────────────────────────────
  // aside (240dp) + main (flex). Detail panel Phase 2 (zones.detail absent → 2 cols).
  Widget _desktop(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_hasZone(config.zones.aside)) ...<Widget>[
          SizedBox(
            width: ScalarioLayout.sidebarWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildZone(config.zones.aside!, ctx),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        Expanded(
          child: _hasZone(config.zones.main)
              ? ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ScalarioLayout.webPagePaddingH,
                    vertical: ScalarioSpacing.space4,
                  ),
                  children: _buildZone(config.zones.main!, ctx),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasZone(List<ComponentConfig>? zone) =>
      zone != null && zone.isNotEmpty;

  List<Widget> _buildZone(List<ComponentConfig> configs, BuildContext ctx) =>
      configs.map((ComponentConfig c) => registry.build(c, ctx)).toList();
}
