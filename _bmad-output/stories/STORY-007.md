# STORY-007 : LayoutResolver

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 5
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-001 (tokens spacing/layout), STORY-002 (ThemeData) — pour les tokens `mobilePagePaddingH`, `webMaxWidth`, `sidebarWidth`. STORY-005 (ComponentRegistry) en parallèle — le LayoutResolver appelle le registry pour instancier les composants des zones.

---

## User Story

> **En tant que** BDUIEngine Scalario,
> **je veux** un résolveur qui prend un `layout` string + un `viewport` et retourne un widget Flutter qui structure les zones (`kpis`, `main`, `aside`, `actions`),
> **so that** chaque screen s'adapte automatiquement au mobile / tablet / desktop sans qu'aucune décision de layout ne soit codée dans les composants ni dans l'Engine — et qu'un même JSON donne un rendu cohérent partout.

---

## Description

### Background

Scalario doit fonctionner sur Android (Blandine, terrain, Snapdragon 680, écran 5-6"), sur iOS (managers Phase 2), et sur web admin (Carlos / Ibrahim, écran desktop). Un même `ScreenConfig` JSON doit produire un layout adéquat sur chaque plateforme — sans branchement plateforme dans le code métier ni dans le composant lui-même.

L'architecture (`_bmad-output/architecture-scalario-2026-05-09.md` lignes 463-481) définit **4 layouts canoniques** :

| Layout | Mobile (<600) | Tablet (600-1024) | Desktop (>1024) | Zones |
|---|---|---|---|---|
| `dashboard` | Stack vertical | Grid 2 cols | Grid 3 cols | kpis, main, actions |
| `list`      | Liste plein écran | Liste + filtre aside | Liste + filtre + détail | main, filters, detail |
| `form`      | Sections empilées | 2 colonnes | 2 colonnes + aside | sections, actions |
| `detail`    | Scroll vertical | Tabs | Master/detail split | header, body, actions |

C'est volontairement **fixe** : l'IA et les templates ne peuvent **pas créer de nouveaux layouts**. Cette contrainte garantit la cohérence visuelle entre tous les tenants. Tout besoin "un nouveau layout" passe par une story dev qui ajoute un cinquième cas — ce n'est pas data-driven. Cf. PRD §FR-003 ligne 229 : "L'IA choisit lequel utiliser — elle ne crée jamais de nouveaux layouts."

### Scope

**In scope :**

- Package `lib/engine/layout_resolver/` avec :
  - `breakpoints.dart` — `Breakpoint` enum (`mobile`, `tablet`, `desktop`) + `BreakpointResolver.from(BoxConstraints)` ou `MediaQuery`.
  - `layout_resolver.dart` — `LayoutResolver.resolve(String layoutType, ScreenConfig config, BuildContext ctx) → Widget`.
  - `layouts/dashboard_layout.dart` — implémentation des 3 variantes responsives.
  - `layouts/list_layout.dart` — idem.
  - `layouts/form_layout.dart` — idem.
  - `layouts/detail_layout.dart` — idem.
  - `layouts/unknown_layout.dart` — fallback `dashboard` + warning log.
- Chaque layout consomme `ComponentRegistry.build` (injecté via DI) pour instancier les composants des zones.
- Utilisation systématique des tokens `ScalarioSpacing`, `ScalarioRadius`, `ScalarioElevation` (STORY-001).
- Support `LayoutBuilder` interne — les layouts ne lisent pas `MediaQuery.of(ctx)` directement (testabilité).
- Tests : 4 layouts × 3 breakpoints = 12 golden tests + tests unitaires de `BreakpointResolver`.
- Benchmark : un layout résolu sur écran à 20 composants doit rendre en < 80ms (budget LayoutResolver dans le total < 200ms cold de STORY-008).

**Out of scope (autres stories) :**

- Pipeline complet `parse JSON → RuleEvaluator → registry → layout` → STORY-008.
- Composants DS individuels (KPICard, DataTable…) → STORY-003 / EPIC-001.
- Mode sombre / theming → couvert globalement par STORY-002 ; ce story consomme le `Theme.of(ctx)` sans le modifier.
- Animation transitions de breakpoint (rotation device) → out of scope ; le rebuild Flutter standard suffit.
- Layouts custom par tenant → architecturalement interdit. Phase 1 = 4 layouts. Phase 2 reste à 4. Si jamais un 5e arrive, c'est une story dev dédiée.
- Couverture multi-plateforme builds (PWA, iOS spec) → STORY-012.

### Runtime Flow

1. BDUIEngine STORY-008 reçoit `screenConfig.layout = "dashboard"`.
2. Appelle `layoutResolver.resolve("dashboard", screenConfig, ctx)`.
3. `LayoutResolver` regarde le mapping `dashboard → DashboardLayout()`.
4. `DashboardLayout` est un `StatelessWidget` qui utilise `LayoutBuilder` :
   - `constraints.maxWidth < 600` → variante mobile (Column verticale).
   - `600 <= maxWidth <= 1024` → variante tablet (Grid 2 cols).
   - `> 1024` → variante desktop (Grid 3 cols + sidebar éventuel).
5. Pour chaque zone (`kpis`, `main`, `actions`), itère `screenConfig.zones.kpis` et appelle `componentRegistry.build(componentConfig, ctx)` pour chaque composant.
6. Retourne le widget tree complet. **Aucun if métier**, aucune connaissance du domaine.

---

## Acceptance Criteria

### Breakpoints

- [ ] AC-01 — Enum `Breakpoint { mobile, tablet, desktop }`.
- [ ] AC-02 — `BreakpointResolver.fromWidth(double width) → Breakpoint` :
  - `width < 600` → `mobile`.
  - `600 <= width <= 1024` → `tablet`.
  - `width > 1024` → `desktop`.
- [ ] AC-03 — `BreakpointResolver.fromConstraints(BoxConstraints)` lit `constraints.maxWidth`.
- [ ] AC-04 — Tokens layout (`ScalarioLayout.sidebarWidth = 240`, `webMaxWidth = 1200`, `mobilePagePaddingH = 16`, `webPagePaddingH = 32`) — vérifiés exposés par STORY-001 et utilisés ici.

### LayoutResolver — API

- [ ] AC-05 — `LayoutResolver.resolve(String layoutType, ScreenConfig config, BuildContext ctx) → Widget`.
- [ ] AC-06 — Layout supportés : `dashboard`, `list`, `form`, `detail`. Tout autre string → `UnknownLayout` qui rend la variante `dashboard` + log warning `dart:developer level: 900` `Unknown layout type "$layoutType", falling back to dashboard`.
- [ ] AC-07 — `LayoutResolver` est sans état, instance unique injectée via DI (`get_it`).
- [ ] AC-08 — Aucun import `package:scalario/features/...` dans `lib/engine/layout_resolver/` (vérifié par lint CI).

### DashboardLayout

- [ ] AC-09 — **Mobile (<600px) :** `Column` verticale dans cet ordre : zone `kpis` (sub-grille 2 cols), zone `main` (Column scrollable), FAB de la zone `actions` positionné en `Stack` bas-droite via `Align(Alignment.bottomRight)`. Padding horizontal `mobilePagePaddingH`.
- [ ] AC-10 — **Tablet (600-1024) :** `GridView` à 2 colonnes pour `kpis` (4 KPIs sur 2 lignes), zone `main` plein largeur en dessous, FAB idem.
- [ ] AC-11 — **Desktop (>1024) :** `GridView` à 4 colonnes pour `kpis` (4 KPIs sur 1 ligne), zone `main` au centre avec `maxWidth = 1200`, zone `actions` peut contenir des boutons inline (header) en plus du FAB.
- [ ] AC-12 — Espacement entre KPIs : `ScalarioSpacing.space4` (16dp) sur tous breakpoints.

### ListLayout

- [ ] AC-13 — **Mobile :** `main` = ListView plein écran. `filters` = `BottomSheet` accessible via icône filtre dans l'AppBar (rendue par TopBar du screen, pas le LayoutResolver). `detail` ignoré (navigation vers screen séparé).
- [ ] AC-14 — **Tablet :** `Row` 2 colonnes — `filters` à gauche (240dp fixe), `main` à droite (flex). `detail` ignoré.
- [ ] AC-15 — **Desktop :** `Row` 3 colonnes — `filters` (240dp), `main` (flex), `detail` (320dp à droite, master-detail). Si `detail` est vide → 2 colonnes.

### FormLayout

- [ ] AC-16 — **Mobile :** `sections` = `Column` empilé scrollable. `actions` = barre fixe en bas (`SafeArea` + `Container` avec elevation `e2`).
- [ ] AC-17 — **Tablet/Desktop :** `Wrap` ou `Row` à 2 colonnes pour les sections. `actions` reste fixe en bas.
- [ ] AC-18 — Largeur max formulaire : `webMaxWidth = 1200` centrée sur desktop.

### DetailLayout

- [ ] AC-19 — **Mobile :** `Column` scrollable — `header` haut, `body` milieu, `actions` bas (sticky `BottomAppBar`).
- [ ] AC-20 — **Tablet :** `header` plein largeur, `body` en `TabBarView` (tabs déclarées dans le JSON via `body` enfants typés `Tab`). `actions` sticky bas.
- [ ] AC-21 — **Desktop :** master-detail split — colonne gauche 30% (header + nav), colonne droite 70% (body courant). `actions` en haut à droite.

### Fallback & Robustesse

- [ ] AC-22 — Layout type inconnu → `UnknownLayout` rend variante `dashboard` + warning logué + un `AlertBanner` de niveau `info` en haut "Layout `xyz` non reconnu, mode dashboard".
- [ ] AC-23 — Zone vide ou absente (ex: `screenConfig.zones.kpis == null`) → la zone n'est pas rendue, pas d'espace réservé. Aucun crash.
- [ ] AC-24 — Composant individuel qui throw (via `ComponentRegistry.build`) → l'ErrorBoundary l'intercepte (STORY-010) ; le LayoutResolver continue de rendre les autres composants.

### Tests

- [ ] AC-25 — Tests widget (`flutter_test`) : 4 layouts × 3 breakpoints = 12 tests + golden snapshots (`flutter test --update-goldens` au premier run).
- [ ] AC-26 — Test unitaire `BreakpointResolver.fromWidth` couvre boundaries (599 → mobile, 600 → tablet, 1024 → tablet, 1025 → desktop).
- [ ] AC-27 — Test fallback : layout `"foobar"` → renders DashboardLayout + warning capturé via `IOOverrides`.
- [ ] AC-28 — Test zone vide : `ScreenConfig` avec `zones.kpis = null` → DashboardLayout ne rend pas la zone, pas de crash.
- [ ] AC-29 — Couverture ≥ 90% sur `lib/engine/layout_resolver/`.

### Performance

- [ ] AC-30 — Benchmark widget test : `DashboardLayout` avec 20 composants stub renders en < 80ms sur émulateur Snapdragon 680.
- [ ] AC-31 — Pas de `setState` inutile lors d'un changement de breakpoint — `LayoutBuilder` rebuild seulement les enfants concernés.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/layout_resolver/`
- **Tokens consommés :** `ScalarioSpacing`, `ScalarioLayout`, `ScalarioElevation` (STORY-001).
- **DI :** `LayoutResolver` + `BreakpointResolver` enregistrés via `get_it`.
- **Référence DS :** `design-process/D-Design-System/ux-rules/layout.md` (existe ou à créer en parallèle).

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── engine/
│       └── layout_resolver/
│           ├── breakpoints.dart
│           ├── layout_resolver.dart
│           ├── layouts/
│           │   ├── dashboard_layout.dart
│           │   ├── list_layout.dart
│           │   ├── form_layout.dart
│           │   ├── detail_layout.dart
│           │   └── unknown_layout.dart
│           └── layout_resolver.dart   # barrel
├── test/
│   └── engine/
│       └── layout_resolver/
│           ├── breakpoints_test.dart
│           ├── dashboard_layout_test.dart
│           ├── list_layout_test.dart
│           ├── form_layout_test.dart
│           ├── detail_layout_test.dart
│           ├── unknown_layout_test.dart
│           ├── benchmark_test.dart
│           └── goldens/
│               ├── dashboard_mobile.png
│               ├── dashboard_tablet.png
│               ├── dashboard_desktop.png
│               └── ... (12 fichiers)
```

### Pattern Dart recommandé

```dart
enum Breakpoint { mobile, tablet, desktop }

abstract final class BreakpointResolver {
  static Breakpoint fromWidth(double width) {
    if (width < 600) return Breakpoint.mobile;
    if (width <= 1024) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }

  static Breakpoint fromConstraints(BoxConstraints c) =>
      fromWidth(c.maxWidth);
}

@immutable
final class LayoutResolver {
  const LayoutResolver({required this.registry});
  final ComponentRegistry registry;

  Widget resolve(
    String layoutType,
    ScreenConfig config,
    BuildContext ctx,
  ) {
    return switch (layoutType) {
      'dashboard' => DashboardLayout(config: config, registry: registry),
      'list'      => ListLayout(config: config, registry: registry),
      'form'      => FormLayout(config: config, registry: registry),
      'detail'    => DetailLayout(config: config, registry: registry),
      _           => _unknown(layoutType, config),
    };
  }

  Widget _unknown(String layoutType, ScreenConfig config) {
    developer.log(
      'Unknown layout type "$layoutType", falling back to dashboard',
      name: 'BDUI.LayoutResolver',
      level: 900,
    );
    return DashboardLayout(config: config, registry: registry);
  }
}

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
    super.key,
    required this.config,
    required this.registry,
  });
  final ScreenConfig config;
  final ComponentRegistry registry;

  @override
  Widget build(BuildContext ctx) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final bp = BreakpointResolver.fromConstraints(constraints);
        return switch (bp) {
          Breakpoint.mobile  => _mobile(ctx),
          Breakpoint.tablet  => _tablet(ctx),
          Breakpoint.desktop => _desktop(ctx),
        };
      },
    );
  }
  // ...
}
```

### Spec source — résolution du conflit PRD ↔ DS

Le PRD §FR-003 et le sprint plan parlent de zones `kpis, main, actions` pour `dashboard`. **Le DS implique aussi une zone `aside`** (sidebar desktop, filters tablet). L'architecture ligne 977-984 (contrat partagé `ScreenConfig.zones`) liste 4 zones : `kpis, main, aside, actions`.

**Décision :** la zone `aside` est gérée différemment selon le layout :
- `dashboard` : `aside` ignorée (Phase 1) — placeholder pour Phase 2 si on ajoute un panneau latéral persistant.
- `list` : `aside` = `filters` à gauche.
- `form` : `aside` = panneau d'aide à droite (desktop seulement).
- `detail` : `aside` = nav latérale gauche desktop.

**Source de vérité :** contrat partagé `ScreenConfig.zones` (architecture ligne 977). DS gagne. Documenter en commentaire dans chaque layout.

### Edge cases

- **Rotation device** : `LayoutBuilder` rebuild automatiquement quand les constraints changent. Pas de manipulation `OrientationBuilder` requise.
- **Flutter Web zoom** : un utilisateur peut zoomer le navigateur ; `LayoutBuilder` se base sur `maxWidth` logique, donc un zoom déclenche un re-breakpoint correct.
- **Web embarqué iframe** : si Scalario est embarqué (Phase 2 partenaire), la largeur peut être < 600 même sur desktop. Le breakpoint mobile s'applique → comportement attendu.
- **Grand écran 4K (>2560px)** : on reste en `desktop` ; la `webMaxWidth = 1200` centre le contenu. Pas de breakpoint "ultra-wide" Phase 1.
- **Composant "trop large" pour la cellule grid** : c'est la responsabilité du composant DS de respecter sa cellule (Wrap, FittedBox, etc.). Le LayoutResolver ne forcera pas un crop. Documenté dans la convention DS.
- **Zone `actions` avec FAB ET boutons inline** : Phase 1, le FAB est extrait du JSON par convention `actions[0].type == "ActionButton" && variant == "floating"`. Les autres ActionButtons sont rendus inline (en barre header sur desktop, en bottom bar sur mobile).

### Sécurité

N/A — couche présentation, aucun input utilisateur, aucun appel réseau, aucune donnée sensible.

### Performance

- `LayoutBuilder` est gratuit côté Flutter — il rebuild seulement quand les constraints changent.
- `GridView.count` avec `shrinkWrap: false` est performant. `GridView.builder` si plus de 100 KPIs (ne devrait jamais arriver — un dashboard a 4-8 KPIs max par convention DS).
- Budget LayoutResolver dans le total cold render < 200ms (STORY-008) : **80ms max**. Le reste = ComponentRegistry (50ms) + RuleEvaluator (10ms) + parse JSON (60ms).

---

## Dependencies

**Prérequis :**

- STORY-001 (Design Tokens) — `merged` (tokens spacing, layout, elevation).
- STORY-002 (ThemeData) — `merged` (Theme.of(ctx) consommé pour couleurs surfaces).
- STORY-005 (ComponentRegistry) — `merged` ou en parallèle ; les layouts appellent `registry.build`.

**Stories bloquées par celle-ci :**

- STORY-008 (BDUIEngine) — directe.
- STORY-009 (Sandbox) — via STORY-008.
- STORY-012 (Multi-plateforme) — directe (les breakpoints sont la base de la responsivité).

**Externes :**

- Aucun.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-007-layout-resolver`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/layout_resolver/`.
- [ ] `flutter test test/engine/layout_resolver/` vert avec ≥ 90% coverage.
- [ ] 12 golden tests (4 layouts × 3 breakpoints) générés et committés.
- [ ] Aucun nom de domaine métier hardcodé dans le dossier (vérifié par grep).
- [ ] Aucun import `lib/features/...` (vérifié par lint CI).
- [ ] Benchmark layout < 80ms vérifié (test runner sur émulateur Snapdragon 680).
- [ ] Code review passé (auto-review Carlos + `/codex review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-007 status `completed`, completed_points sprint 1 += 5).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `Breakpoint` enum + `BreakpointResolver` + tests boundaries | 0.25 | Trivial. |
| `LayoutResolver.resolve` + fallback `UnknownLayout` | 0.5 | Switch sur 4 cas + log warning. |
| `DashboardLayout` (3 variantes responsives, FAB Stack, KPI grid) | 1 | Le plus utilisé — soigner le polissage. |
| `ListLayout` (filters/main/detail responsive) | 0.75 | Sidebar fixed-width tablet, master-detail desktop. |
| `FormLayout` (sections empilées vs 2 cols + actions sticky) | 0.5 | Plus simple, mais sticky bottom à blinder mobile. |
| `DetailLayout` (scroll vs Tabs vs split) | 0.75 | TabBarView desktop, sticky actions, header sticky. |
| Golden tests (12 fichiers) + harness setup | 0.75 | Le plus long en temps de mise en place — flux golden = run + check + commit. |
| Benchmark < 80ms + tests fallback + zone vide | 0.5 | Filet anti-régression performance. |
| **Total** | **5** | Fibonacci 5 — moderate, présentation pure. |

**Rationale :** Pas de logique conditionnelle métier, mais beaucoup de "cas × breakpoints" → la combinatoire visuelle est ce qui mange les points. Les golden tests sont le filet de non-régression. Sans eux, un dev peut accidentellement casser le layout list desktop en sprint 4 sans s'en rendre compte. On prend 5 points pour blinder la responsivité — c'est ce qui rend Scalario "vrai multi-plateforme" plutôt qu'un mobile retaillé pour le web.

---

## Notes additionnelles

- **Layouts custom = anti-pattern :** quand un PM voudra "juste un nouveau layout" pour un module spécifique, refuser. Soit ça rentre dans `dashboard|list|form|detail`, soit on ouvre une vraie discussion architecture pour ajouter un 5e layout (story dev = 5+ points avec golden tests). Cette contrainte est ce qui garantit la cohérence Scalario.
- **Mode portrait/landscape mobile :** un mobile en mode paysage (~840px) tombe en breakpoint `tablet`. Comportement attendu — on suit la largeur logique, pas l'orientation.
- **`MediaQuery.of(ctx).size.width` vs `LayoutBuilder.constraints.maxWidth` :** on utilise **toujours `LayoutBuilder`**. Raisons : (1) testable sans wrapper `MediaQuery`, (2) supporte les sous-régions (un `ListLayout` à l'intérieur d'un panel desktop peut basculer en mode mobile s'il est étroit), (3) plus rapide (pas de subscription `MediaQuery`).
- **Logo Scalario / branding :** non concerné par cette story.
- **Animation transitions :** Phase 2. Phase 1, le rebuild Flutter standard suffit (≈ 60fps sur Snapdragon 680).

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
