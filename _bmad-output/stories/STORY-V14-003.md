# STORY-V14-003 : ComponentRegistry dispatch par variante (KPICard.fromConfig + resolveVariant)

**Epic :** EPIC-V14-002 — Scalario Canvas (BDUI v14)
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-2 (2026-06-09 → 2026-06-22)
**Dépendances :** V14-002 (schéma variant) ; STORY-005 v13 (ComponentRegistry de base)

---

## User Story

> **En tant que** Flutter renderer du BDUI,
> **je veux** que chaque composant DS (KPICard, DataTable, ChartBar, etc.) dispatche en interne vers son implémentation selon `variant`, et que `variant: 'auto'` soit résolu au runtime selon le contexte (screen size, rôle user, nb d'éléments),
> **so that** le JSON config reste propre (`type: KPICard, variant: auto`) et le rendu s'adapte automatiquement sans hardcoder N types dans le registre.

---

## Description

### Background

PRD v14 §8.4 montre le pattern :
```dart
class KPICard extends StatelessWidget {
  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    final variant = resolveVariant(config.variant, ctx);
    return switch (variant) {
      'compact'    => KPICardCompact(config.props),
      'with-icon'  => KPICardWithIcon(config.props),
      'with-chart' => KPICardWithChart(config.props),
      'hero'       => KPICardHero(config.props),
      _            => KPICardDefault(config.props),
    };
  }

  static String resolveVariant(String variant, BuildContext ctx) {
    if (variant != 'auto') return variant;
    final screen = MediaQuery.of(ctx).size;
    final user = ctx.read<UserContext>();
    final kpiCount = ctx.read<ScreenState>().kpiCount;
    if (screen.width < 600)  return 'compact';
    if (user.role == 'DG')   return 'with-chart';
    if (kpiCount == 1)       return 'hero';
    return 'default';
  }
}
```

Cette story livre :
1. Helper `ScalarioCanvasResolver.resolveVariant(variant, ctx)` — règle globale auto
2. Refactor des 12 composants DS existants pour exposer `<Type>.fromConfig(config, ctx)` → dispatch interne par variante
3. `ScalarioCanvasRegistry.build(config, ctx)` → switch sur `config.type` → délègue à `<Type>.fromConfig`

### Scope

**In scope :**
- 12 composants DS refactorés avec `.fromConfig` + dispatch par variante :
  - KPICard, DataTable, ListTile, AlertBanner, ChartBar, ChartPie, Button, FAB, FormField, StatCard, SyncStatusBar, DocumentPreview
- Helper `ScalarioCanvasResolver` avec `resolveVariant` global + hook par composant
- `UnknownComponent` fallback si `type` inconnu (avec error boundary)
- Tests widget pour chaque composant × variantes principales

**Out of scope :**
- Catalogue des variantes autorisées par métier — V14-004
- Widgetbook setup — V14-010 (juste les composants ici, pas la doc visuelle)

---

## Acceptance Criteria

### Helper `ScalarioCanvasResolver`

- [ ] **AC-01** — `resolveVariant(variant: String, ctx: BuildContext)` retourne `variant` si ≠ `'auto'`.
- [ ] **AC-02** — Si `variant == 'auto'` : applique règles globales (mobile <600px → `compact`, role `DG` → `with-chart`, kpiCount==1 → `hero`, default → `default`).
- [ ] **AC-03** — Composants peuvent override `resolveVariant` avec leur propre logique (méthode statique optionnelle).

### Dispatch par composant (12 composants)

- [ ] **AC-04** — `KPICard.fromConfig(config, ctx)` dispatche vers KPICardDefault/Compact/WithIcon/Hero/WithChart selon variante.
- [ ] **AC-05** — `DataTable.fromConfig` → DataTableDefault/Compact/CardList/Timeline.
- [ ] **AC-06** — `ListTile.fromConfig` → ListTileDefault/WithAvatar/WithBadge/Dense.
- [ ] **AC-07** — `AlertBanner.fromConfig` → AlertBannerInfo/Success/Warning/Danger/Dismissible.
- [ ] **AC-08** — `ChartBar.fromConfig` → ChartBarDefault/Stacked/Horizontal/Mini.
- [ ] **AC-09** — `ChartPie.fromConfig` → ChartPieDefault/Donut/MiniLegend.
- [ ] **AC-10** — `Button.fromConfig` → ButtonPrimary/Secondary/Ghost/Danger/IconOnly.
- [ ] **AC-11** — `FAB.fromConfig` → FABDefault/Extended/Mini.
- [ ] **AC-12** — `FormField.fromConfig` → Text/Number/Date/Select/Search/Scan (le `variant` ici = type de champ).
- [ ] **AC-13** — `StatCard.fromConfig` → StatCardDefault/TrendUp/TrendDown/Flat.
- [ ] **AC-14** — `SyncStatusBar.fromConfig` → variantes Syncing/Synced/Conflict/Offline (auto-bind à `ScalarioSync` state via Riverpod).
- [ ] **AC-15** — `DocumentPreview.fromConfig` → DocumentPreviewInline/Card/Fullscreen/Thumbnail.

### Registry + fallback

- [ ] **AC-16** — `ScalarioCanvasRegistry.build(config, ctx)` switch sur `config.type` → `<Type>.fromConfig`.
- [ ] **AC-17** — Type inconnu → renders `UnknownComponent(type: config.type)` avec icône warning + log.

### Tests

- [ ] **AC-18** — Widget test pour chaque composant : `default` rendu correctement.
- [ ] **AC-19** — Widget test `variant: 'auto'` sur KPICard : 3 scénarios (mobile→compact, DG→with-chart, single→hero).
- [ ] **AC-20** — Test `UnknownComponent` : type fictif `'XyzWidget'` → fallback affiché, pas de crash.

---

## Technical Notes

### Composants concernés

- `apps/flutter/lib/core/canvas/` — nouveau dossier (V14-001 a renommé `bdui/` en `canvas/`)
- `apps/flutter/lib/core/canvas/scalario_canvas_resolver.dart` — nouveau helper
- `apps/flutter/lib/core/canvas/scalario_canvas_registry.dart` — refactor de l'ancien ComponentRegistry
- `apps/flutter/lib/components/feedback/`, `lib/components/data_display/`, etc. — refactor des 12 composants

### Structure attendue

```dart
// lib/core/canvas/scalario_canvas_resolver.dart
class ScalarioCanvasResolver {
  static String resolveVariant(String variant, BuildContext ctx, {String? component}) {
    if (variant != 'auto') return variant;
    // Hook par composant si défini
    final hook = _componentHooks[component];
    if (hook != null) return hook(ctx);
    // Règle globale
    final screen = MediaQuery.of(ctx).size;
    if (screen.width < 600) return 'compact';
    return 'default';
  }

  static final Map<String, String Function(BuildContext)> _componentHooks = {
    'KPICard': (ctx) {
      final screen = MediaQuery.of(ctx).size;
      final user = ctx.read<UserContext>();
      final kpiCount = ctx.read<ScreenState>().kpiCount;
      if (screen.width < 600) return 'compact';
      if (user.role == 'DG') return 'with-chart';
      if (kpiCount == 1) return 'hero';
      return 'default';
    },
    // ... 11 autres composants
  };
}
```

### Edge cases

- `BuildContext` sans `UserContext` provider → fallback `'default'` (jamais throw)
- Resize d'écran pendant runtime → re-build automatique via MediaQuery
- `variant` inconnu (ex: `'super-hero'` sur KPICard) → fallback `'default'` + log warning

---

## Dependencies

- **Prérequis :** V14-001 (migration nomenclature), V14-002 (schéma variant)
- **Stories bloquées :** V14-004 (Catalogue variantes), V14-010 (Widgetbook), V14-007 (6 moteurs)

---

## Definition of Done

- [ ] 12 composants refactorés + tests verts
- [ ] Helper resolveVariant testé sur 3 scénarios KPICard
- [ ] `UnknownComponent` fallback testé
- [ ] flutter analyze = 0 issue
- [ ] sprint-status.yaml V14-003 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| ScalarioCanvasResolver + 12 hooks par composant | 1.0 |
| Refactor 12 composants (.fromConfig + dispatch) | 2.0 |
| ScalarioCanvasRegistry.build + UnknownComponent fallback | 0.5 |
| Tests widget (20 cas) | 1.0 |
| Docs + memory feedback_scalario_canvas_dispatch.md | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

**Status History :**
- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
