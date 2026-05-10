import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/spacing.dart';
import '../../component_registry/component_config.dart';
import '../../component_registry/component_registry.dart';
import '../breakpoints.dart';
import '../screen_config.dart';

/// Layout `form` — 3 variantes responsives.
///
/// Zone mapping :
/// - main    : sections du formulaire
/// - actions : barre sticky bas (SafeArea + elevation e2)
/// - aside   : panneau d'aide contextuelle (desktop seulement, droite)
/// - kpis    : ignoré Phase 1
class FormLayout extends StatelessWidget {
  const FormLayout({
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
  // sections empilées scrollables + barre actions sticky bas.
  Widget _mobile(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
  // Sections en 2 colonnes (Wrap), actions sticky bas.
  Widget _tablet(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.mobilePagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: _hasZone(config.zones.main)
                ? _buildTwoColumnSections(config.zones.main!, ctx)
                : const SizedBox.shrink(),
          ),
        ),
        _buildStickyActions(config.zones.actions, ctx),
      ],
    );
  }

  // ── Desktop (> 1024) ────────────────────────────────────────────────────────
  // 2 colonnes sections + aside aide droite, centré webMaxWidth, actions sticky bas.
  Widget _desktop(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ScalarioLayout.webPagePaddingH,
              vertical: ScalarioSpacing.space4,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ScalarioLayout.webMaxWidth,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _hasZone(config.zones.main)
                          ? _buildTwoColumnSections(config.zones.main!, ctx)
                          : const SizedBox.shrink(),
                    ),
                    if (_hasZone(config.zones.aside)) ...<Widget>[
                      const SizedBox(width: ScalarioSpacing.space8),
                      SizedBox(
                        width: ScalarioLayout.sidebarWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children:
                              _buildZone(config.zones.aside!, ctx),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildStickyActions(config.zones.actions, ctx),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasZone(List<ComponentConfig>? zone) =>
      zone != null && zone.isNotEmpty;

  List<Widget> _buildZone(List<ComponentConfig> configs, BuildContext ctx) =>
      configs.map((ComponentConfig c) => registry.build(c, ctx)).toList();

  Widget _buildTwoColumnSections(
    List<ComponentConfig> sections,
    BuildContext ctx,
  ) {
    return Wrap(
      spacing: ScalarioSpacing.space4,
      runSpacing: ScalarioSpacing.space4,
      children: sections
          .map(
            (ComponentConfig c) => FractionallySizedBox(
              widthFactor: 0.5,
              child: Padding(
                padding: const EdgeInsets.only(right: ScalarioSpacing.space4),
                child: registry.build(c, ctx),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStickyActions(
    List<ComponentConfig>? actions,
    BuildContext ctx,
  ) {
    if (!_hasZone(actions)) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScalarioLayout.mobilePagePaddingH,
            vertical: ScalarioSpacing.space3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildZone(actions!, ctx),
          ),
        ),
      ),
    );
  }
}
