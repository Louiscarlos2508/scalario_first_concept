import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/spacing.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../breakpoints.dart';
import '../screen_config.dart';

/// Layout `detail` — 3 variantes responsives.
///
/// Zone mapping :
/// - kpis    : header (identité de l'entité)
/// - main    : body / contenu détaillé (TabBarView tablet si composants typés Tab)
/// - aside   : nav latérale gauche desktop (liens de section / ancres)
/// - actions : boutons d'action (sticky BottomAppBar mobile-tablet, header desktop)
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    super.key,
    required this.config,
    required this.registry,
  });

  final ScreenConfig config;
  final ScalarioCanvasRegistry registry;

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
  // header haut, body milieu scrollable, actions sticky BottomAppBar.
  Widget _mobile(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_hasZone(config.zones.kpis))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.mobilePagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildZone(config.zones.kpis!, ctx),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.mobilePagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _hasZone(config.zones.main)
                  ? _buildZone(config.zones.main!, ctx)
                  : <Widget>[],
            ),
          ),
        ),
        _buildStickyActions(config.zones.actions, ctx),
      ],
    );
  }

  // ── Tablet (600–1024) ───────────────────────────────────────────────────────
  // header plein largeur, body en Column scrollable (TabBarView Phase 2), actions sticky bas.
  Widget _tablet(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_hasZone(config.zones.kpis))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.mobilePagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildZone(config.zones.kpis!, ctx),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.mobilePagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _hasZone(config.zones.main)
                  ? _buildZone(config.zones.main!, ctx)
                  : <Widget>[],
            ),
          ),
        ),
        _buildStickyActions(config.zones.actions, ctx),
      ],
    );
  }

  // ── Desktop (> 1024) ────────────────────────────────────────────────────────
  // Colonne gauche 30% (kpis header + aside nav), colonne droite 70% (main body).
  // Actions en haut à droite.
  Widget _desktop(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioLayout.webPagePaddingH,
        vertical: ScalarioSpacing.space4,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ScalarioLayout.webMaxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Colonne gauche 30% — header + nav
              Expanded(
                flex: 30,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_hasZone(config.zones.kpis))
                        ..._buildZone(config.zones.kpis!, ctx),
                      if (_hasZone(config.zones.aside)) ...<Widget>[
                        const SizedBox(height: ScalarioSpacing.space4),
                        ..._buildZone(config.zones.aside!, ctx),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: ScalarioSpacing.space6),
              // Colonne droite 70% — body + actions haut-droite
              Expanded(
                flex: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_hasZone(config.zones.actions))
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildZone(config.zones.actions!, ctx),
                        ),
                      ),
                    if (_hasZone(config.zones.actions))
                      const SizedBox(height: ScalarioSpacing.space4),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _hasZone(config.zones.main)
                              ? _buildZone(config.zones.main!, ctx)
                              : <Widget>[],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasZone(List<ComponentConfig>? zone) =>
      zone != null && zone.isNotEmpty;

  List<Widget> _buildZone(List<ComponentConfig> configs, BuildContext ctx) =>
      configs.map((ComponentConfig c) => registry.build(c, ctx)).toList();

  Widget _buildStickyActions(
    List<ComponentConfig>? actions,
    BuildContext ctx,
  ) {
    if (!_hasZone(actions)) return const SizedBox.shrink();
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _buildZone(actions!, ctx),
      ),
    );
  }
}
