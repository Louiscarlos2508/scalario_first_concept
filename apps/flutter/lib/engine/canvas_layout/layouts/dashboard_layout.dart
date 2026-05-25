import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/spacing.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../breakpoints.dart';
import '../screen_config.dart';

/// Layout `dashboard` — 3 variantes responsives.
///
/// Zones consommées : kpis (sub-grille), main, actions (FAB + inline desktop).
/// Zone `aside` ignorée Phase 1 — placeholder Phase 2 (panneau latéral persistant).
///
/// Convention FAB : actions[0].type == 'ActionButton' && props['variant'] == 'floating'
/// → rendu en Stack Align bottomRight. Les autres actions sont inline (header desktop /
/// BottomBar mobile-tablet).
class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
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
  Widget _mobile(BuildContext ctx) {
    final Widget? fab = _extractFab(config.zones.actions, ctx);
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ScalarioLayout.mobilePagePaddingH,
            vertical: ScalarioSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_hasZone(config.zones.kpis)) ...<Widget>[
                _buildKpiGrid(config.zones.kpis!, 2, ctx),
                const SizedBox(height: ScalarioSpacing.space4),
              ],
              if (_hasZone(config.zones.main))
                ..._buildZone(config.zones.main!, ctx),
              if (fab != null) const SizedBox(height: ScalarioSpacing.space16),
            ],
          ),
        ),
        if (fab != null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: fab,
            ),
          ),
      ],
    );
  }

  // ── Tablet (600–1024) ───────────────────────────────────────────────────────
  Widget _tablet(BuildContext ctx) {
    final Widget? fab = _extractFab(config.zones.actions, ctx);
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ScalarioLayout.mobilePagePaddingH,
            vertical: ScalarioSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_hasZone(config.zones.kpis)) ...<Widget>[
                _buildKpiGrid(config.zones.kpis!, 2, ctx),
                const SizedBox(height: ScalarioSpacing.space4),
              ],
              if (_hasZone(config.zones.main))
                ..._buildZone(config.zones.main!, ctx),
              if (fab != null) const SizedBox(height: ScalarioSpacing.space16),
            ],
          ),
        ),
        if (fab != null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: fab,
            ),
          ),
      ],
    );
  }

  // ── Desktop (> 1024) ────────────────────────────────────────────────────────
  Widget _desktop(BuildContext ctx) {
    final Widget? fab = _extractFab(config.zones.actions, ctx);
    final List<ComponentConfig> inline =
        _inlineActions(config.zones.actions);

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ScalarioLayout.webPagePaddingH,
            vertical: ScalarioSpacing.space4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ScalarioLayout.webMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (inline.isNotEmpty) ...<Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildZone(inline, ctx),
                      ),
                    ),
                    const SizedBox(height: ScalarioSpacing.space4),
                  ],
                  if (_hasZone(config.zones.kpis)) ...<Widget>[
                    _buildKpiGrid(config.zones.kpis!, 4, ctx),
                    const SizedBox(height: ScalarioSpacing.space4),
                  ],
                  if (_hasZone(config.zones.main))
                    ..._buildZone(config.zones.main!, ctx),
                  if (fab != null)
                    const SizedBox(height: ScalarioSpacing.space16),
                ],
              ),
            ),
          ),
        ),
        if (fab != null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: fab,
            ),
          ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasZone(List<ComponentConfig>? zone) =>
      zone != null && zone.isNotEmpty;

  List<Widget> _buildZone(List<ComponentConfig> configs, BuildContext ctx) =>
      configs.map((ComponentConfig c) => registry.build(c, ctx)).toList();

  /// Grille KPI en N colonnes avec espacement [ScalarioSpacing.space4].
  ///
  /// Utilise des `Row`s explicites (pas `GridView`) pour respecter les hauteurs
  /// intrinsèques des composants et éviter un `childAspectRatio` hardcodé.
  Widget _buildKpiGrid(
    List<ComponentConfig> kpis,
    int cols,
    BuildContext ctx,
  ) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < kpis.length; i += cols) {
      final List<ComponentConfig> rowItems =
          kpis.sublist(i, min(i + cols, kpis.length));
      final List<Widget> cells = <Widget>[];
      for (int j = 0; j < rowItems.length; j++) {
        if (j > 0) cells.add(const SizedBox(width: ScalarioSpacing.space4));
        cells.add(Expanded(child: registry.build(rowItems[j], ctx)));
      }
      // Remplir les cellules vides de la dernière ligne.
      for (int j = rowItems.length; j < cols; j++) {
        cells.add(const SizedBox(width: ScalarioSpacing.space4));
        cells.add(const Expanded(child: SizedBox()));
      }
      rows.add(IntrinsicHeight(child: Row(children: cells)));
      if (i + cols < kpis.length) {
        rows.add(const SizedBox(height: ScalarioSpacing.space4));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  /// Extrait le FAB depuis la zone `actions` selon la convention :
  /// actions[0].type == 'ActionButton' && props['variant'] == 'floating'.
  Widget? _extractFab(List<ComponentConfig>? actions, BuildContext ctx) {
    if (actions == null || actions.isEmpty) return null;
    final ComponentConfig first = actions[0];
    if (first.type == 'ActionButton' &&
        first.props['variant'] == 'floating') {
      return registry.build(first, ctx);
    }
    return null;
  }

  /// Actions inline (hors FAB) à afficher dans le header desktop.
  List<ComponentConfig> _inlineActions(List<ComponentConfig>? actions) {
    if (actions == null || actions.isEmpty) return <ComponentConfig>[];
    final ComponentConfig first = actions[0];
    if (first.type == 'ActionButton' &&
        first.props['variant'] == 'floating') {
      return actions.sublist(1);
    }
    return actions;
  }
}
