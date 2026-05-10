# STORY-001 : Design Tokens Flutter

**Epic :** EPIC-001 — Design System Scalario
**Priorité :** Must Have
**Story Points :** 3
**Status :** Completed
**Assigned To :** Carlos Simporé (Claude Code)
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** Aucune (story de base)

---

## User Story

> **En tant que** dev Flutter sur Scalario,
> **je veux** un système de tokens centralisé exposé en Dart depuis les specs `design-process/D-Design-System/tokens/`,
> **so that** tous les composants BDUI partagent la même palette, typographie, espacements, élévations et icônes sans valeur hardcodée — et que toute évolution du DS se propage en un seul endroit.

---

## Description

### Background

Scalario est un Business OS data-driven : 73 composants DS instanciés depuis JSON par le BDUIEngine. Si chaque composant invente ses couleurs, sa typo ou ses paddings, le DS n'a aucune valeur — le rendu serait incohérent entre tenants et entre rôles.

La spec complète du DS existe déjà dans `design-process/D-Design-System/tokens/` (validée 2026-05-09). Cette story matérialise cette spec en code Dart : classes de tokens consommables par tous les widgets futurs (STORY-002 à STORY-012, puis tous les composants BDUI).

C'est la fondation absolue de l'app — aucune story d'EPIC-001/EPIC-002 ne peut commencer sans elle.

### Scope

**In scope :**

- Création de l'app Flutter (`apps/flutter/` via `flutter create`) — projet vide bootstrappé.
- Layer Dart `lib/core/design_system/tokens/` exposant tous les tokens des 4 fichiers spec :
  - `colors.dart` — palette primaire, sémantiques, neutres, tokens d'application.
  - `typography.dart` — échelle typo Inter + Roboto Mono, tokens d'application.
  - `spacing.dart` — grille 4px, layout mobile/web, border-radius, élévations.
  - `icons.dart` — tokens de taille + mapping sémantique → `IconData`.
- `tokens.dart` barrel file qui ré-exporte tout.
- Setup polices Google Fonts (Inter, Roboto Mono) via `google_fonts` package — pas d'asset binaire.
- Asset SVG WhatsApp (`assets/icons/whatsapp.svg`) référencé dans `pubspec.yaml`.
- Lint rule custom (analysis_options.yaml) : interdit les hex literals (`Color(0xFF…)`) et les magic numbers de spacing dans `lib/components/` et `lib/features/`.
- Tests unitaires : chaque token export a une valeur non-null + cohérente avec la spec markdown (snapshot test).

**Out of scope (autres stories) :**

- `ThemeData` Flutter + `ColorScheme` + `TextTheme` → STORY-002.
- `ThemeExtensions` custom pour tokens sémantiques → STORY-002.
- Composants BDUI (KPICard, DataTable…) → STORY-003.
- Showcase / Widget Preview → STORY-004.
- Mode sombre fonctionnel → couvert dans la palette ici, mais branché dans STORY-002.

### User Flow (Developer Experience)

1. Dev ouvre `apps/flutter/lib/components/some_widget.dart`.
2. Il importe `package:scalario/core/design_system/tokens/tokens.dart`.
3. Il écrit `color: ScalarioColors.primary500` au lieu de `Color(0xFF2980B9)`.
4. Il écrit `padding: EdgeInsets.all(ScalarioSpacing.space4)` au lieu de `EdgeInsets.all(16)`.
5. Il écrit `style: ScalarioTypography.bodyMedium` au lieu de définir un `TextStyle` ad-hoc.
6. Si une valeur change dans la spec markdown (ex: `color-primary-500` → nouveau hex), un seul fichier Dart est modifié et tous les widgets se mettent à jour.
7. Le linter bloque tout PR qui hardcode une couleur ou un spacing dans `lib/components/` ou `lib/features/`.

---

## Acceptance Criteria

### Setup projet

- [x] AC-01 — Projet Flutter créé dans `apps/flutter/` (Flutter stable channel, Dart ≥ 3.4).
- [x] AC-02 — `pubspec.yaml` déclare : `google_fonts`, `flutter_svg`. Asset `assets/icons/whatsapp.svg` enregistré.
- [x] AC-03 — Structure `lib/core/design_system/tokens/` avec 4 fichiers + `tokens.dart` barrel.

### Couleurs

- [x] AC-04 — Classe `ScalarioColors` (ou équivalent) expose **toutes** les entrées de `tokens/colors.md` :
  - Primaire : `primary50`, `primary100`, `primary300`, `primary500`, `primary700`, `primary900`.
  - Sémantiques : `success100/500/700`, `warning100/500/700`, `danger100/500/700`, `info100/500`.
  - Neutres : `neutral50/100/300/500/700/900`, `white`.
  - Tokens d'application : `bgPage`, `bgCard`, `bgOverlay`, `textPrimary`, `textSecondary`, `textDisabled`, `borderDefault`, `borderFocus`, `interactivePrimary`, `interactiveDanger`.
- [x] AC-05 — Hex match exact avec `tokens/colors.md` (snapshot test échoue si désync).
- [x] AC-06 — Variantes light + dark documentées dans la classe (palette dark-first à fournir, mappage dans STORY-002).

### Typographie

- [x] AC-07 — Classe `ScalarioTypography` expose les 9 styles de l'échelle : `display`, `headline`, `title`, `bodyLg`, `body`, `bodyMedium`, `caption`, `captionMedium`, `overline`. Sizes/weights/line-heights conformes à `tokens/typography.md` (28/22/18/16/14/14/12/12/11 sp).
- [x] AC-08 — Famille Inter chargée via `GoogleFonts.inter(...)` + Roboto Mono via `GoogleFonts.robotoMono(...)` ; fallback `system-ui, sans-serif`.
- [x] AC-09 — Tokens d'application typo exposés (`fontKpiValue`, `fontKpiLabel`, `fontButton`, `fontInputLabel`, `fontInputValue`, `fontInputHint`, `fontBannerText`, `fontListPrimary`, `fontListSecondary`, `fontSectionTitle`, `fontPageTitle`).
- [x] AC-10 — Tout style numérique temps réel (KPI value, totaux POS, montants FCFA) utilise Roboto Mono — vérifié par convention de nommage `*Mono` ou attribut explicite.

### Espacements & Layout

- [x] AC-11 — Classe `ScalarioSpacing` expose la grille 4px : `space1=4`, `space2=8`, `space3=12`, `space4=16`, `space5=20`, `space6=24`, `space8=32`, `space10=40`, `space12=48`, `space16=64`.
- [x] AC-12 — Classe `ScalarioRadius` expose : `sm=4`, `md=8`, `lg=12`, `xl=16`, `full=999`.
- [x] AC-13 — Classe `ScalarioElevation` expose : `e0` (none), `e1`, `e2`, `e3`, `e4` — chaque token retourne une `List<BoxShadow>` Flutter conforme à la spec.
- [x] AC-14 — Tokens layout : `mobilePagePaddingH=16`, `mobilePagePaddingTop=16`, `webMaxWidth=1200`, `webPagePaddingH=32`, `sidebarWidth=240`, `bottomNavHeight=56`, `syncBarHeight=28`.

### Icônes

- [x] AC-15 — Classe `ScalarioIconSize` expose `xs=16`, `sm=20`, `md=24`, `lg=32`.
- [x] AC-16 — Classe `ScalarioIcons` expose le mapping sémantique complet de `tokens/icons.md` :
  - Navigation (8 entrées avec variantes outlined/filled).
  - Actions (15 entrées).
  - Feedback & État (8 entrées avec couleurs associées).
  - Métier POS (7), Stock (7), Partage (6), Admin (7).
- [x] AC-17 — WhatsApp exposé comme constante de chemin asset SVG (`ScalarioIcons.whatsappAsset = 'assets/icons/whatsapp.svg'`) — jamais comme `IconData`.

### Hygiène — Pas de hardcode

- [x] AC-18 — `analysis_options.yaml` configuré avec règle custom (lint metadata ou `analyzer.errors`) : un widget dans `lib/components/` ou `lib/features/` qui contient `Color(0xFF…)` ou un nombre magique de padding/margin échoue le `flutter analyze`.
- [x] AC-19 — `flutter analyze` passe sur tout le code sans warning.
- [x] AC-20 — Aucun `Color(0xFF…)` ni `EdgeInsets.all(16)` (ou autre magic number) dans `lib/` hors du dossier `tokens/` — vérifié par grep dans le test runner.

### Tests

- [x] AC-21 — Tests unitaires (`test/core/design_system/tokens/`) :
  - Snapshot test couleurs : compare les hex Dart aux hex extraits du markdown.
  - Snapshot test spacing : compare les valeurs Dart aux valeurs markdown.
  - Smoke test typographie : chaque style produit un `TextStyle` non-null avec la bonne size + weight.
  - Smoke test icônes : chaque token résolu en `IconData` non-null.
- [x] AC-22 — Couverture ≥ 90% sur `lib/core/design_system/tokens/` — exigence Gate 0.

---

## Technical Notes

### Composants concernés

- **Nouveau projet Flutter :** `apps/flutter/` (créé par cette story, base pour STORY-002 à STORY-012).
- **Layer DS :** `apps/flutter/lib/core/design_system/tokens/`.
- **Assets :** `apps/flutter/assets/icons/whatsapp.svg`.

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── core/
│       └── design_system/
│           └── tokens/
│               ├── colors.dart          # ScalarioColors
│               ├── typography.dart      # ScalarioTypography
│               ├── spacing.dart         # ScalarioSpacing, ScalarioRadius, ScalarioElevation
│               ├── icons.dart           # ScalarioIcons, ScalarioIconSize
│               └── tokens.dart          # barrel — `export 'colors.dart'; ...`
├── assets/
│   └── icons/
│       └── whatsapp.svg
├── test/
│   └── core/
│       └── design_system/
│           └── tokens/
│               ├── colors_test.dart
│               ├── spacing_test.dart
│               ├── typography_test.dart
│               └── icons_test.dart
├── analysis_options.yaml                # règle hardcode-prevention
└── pubspec.yaml                         # google_fonts, flutter_svg
```

### Pattern Dart recommandé

Classes `abstract final` (Dart 3) avec membres statiques `const` — pas d'instances :

```dart
abstract final class ScalarioColors {
  // Primaire
  static const primary50  = Color(0xFFEBF5FB);
  static const primary100 = Color(0xFFD6EAF8);
  static const primary300 = Color(0xFF85C1E9);
  static const primary500 = Color(0xFF2980B9);
  static const primary700 = Color(0xFF1E5F8E);
  static const primary900 = Color(0xFF1A3A5C);

  // Sémantiques (success / warning / danger / info)
  // …

  // Tokens d'application
  static const bgPage          = neutral50;
  static const interactivePrimary = primary500;
  // …
}
```

Pour la typo, retourner des `TextStyle` figés via `GoogleFonts.inter().copyWith(fontSize: …, fontWeight: …, height: …)`.

### Spec source — résolution du conflit avec le PRD

Le PRD (`prd-scalario-2026-05-09.md` §FR-005) et le sprint plan listent une typo simplifiée (h1 24px, h2 18px, body 14px, caption 12px, mono 13px). **Cette liste est obsolète — c'est une shorthand antérieure à la spec DS.**

**Source de vérité officielle :** `design-process/D-Design-System/tokens/typography.md` (échelle complète 9 niveaux : 28/22/18/16/14/14/12/12/11sp). Implémenter contre cette spec ; ouvrir un PR de mise à jour PRD en parallèle si pertinent.

### Police Inter — choix d'implémentation

Utiliser `google_fonts: ^6.x` avec `GoogleFonts.inter()` :

- **Avantage :** zéro asset embarqué, téléchargement runtime + cache.
- **Risque offline :** Scalario est offline-first (Blandine perd son réseau). Le cache `google_fonts` persiste après premier chargement, mais pour blinder, configurer `GoogleFonts.config.allowRuntimeFetching = false` après bundle des polices en assets en M2 (story future).
- **Pour cette story :** runtime fetch OK — la première session intégrateur a toujours un réseau (provisioning).

### Lint rule custom

Pas de plugin `custom_lint` requis — utiliser une combinaison :

1. `analysis_options.yaml` avec `errors:` strict (avoid_redundant_argument_values, prefer_const_constructors).
2. Un test runner `dart run scripts/check_no_hardcoded_tokens.dart` qui grep `lib/components/` et `lib/features/` pour patterns interdits :
   - `Color\(0x[0-9A-Fa-f]+\)`
   - `EdgeInsets\.(all|symmetric|fromLTRB)\([^,)]*[0-9]+`
   - `BorderRadius\.circular\([0-9]+\)`
3. Hook ce script dans CI (sera exposé en Sprint 2 via STORY-013 / docker-compose).

### Edge cases

- **Couleurs sémantiques sync/conflict** (mentionnés dans le sprint plan note STORY-002) : pas dans cette story — tokens sémantiques de sync (synced/pending/conflict) seront des alias dans `ThemeExtensions` STORY-002. Les couleurs de base sont déjà dans la palette (success-500, warning-500, danger-500).
- **Variation dark-first :** la spec colors.md ne précise pas explicitement les valeurs dark. Pour cette story : exposer la palette telle quelle ; ajouter un commentaire `// TODO STORY-002: define dark-mode overrides` sur les tokens d'application qui devront varier (`bgPage`, `bgCard`, `textPrimary`, etc.).
- **Espace insécable FCFA** : le formatage des nombres (`12 500 FCFA`) n'est pas dans cette story — c'est un utilitaire séparé à créer plus tard. Cette story expose la typo Roboto Mono ; le formatter consommera la typo.

### Sécurité

N/A — couche présentation pure, aucun input utilisateur, aucun secret.

---

## Dependencies

**Prérequis :** Aucun (story 1 du projet).

**Stories bloquées par celle-ci :**

- STORY-002 (ThemeData Scalario) — direct
- STORY-003 (Composants BDUI Métier) — via STORY-002
- STORY-004 (Showcase + Widget Preview) — via STORY-002 et STORY-003
- Indirectement, **toutes** les stories d'EPIC-001/002/006/007 qui rendent du UI.

**Externes :**

- Police Inter + Roboto Mono via `google_fonts` (Google Fonts API publique — disponible).
- SVG WhatsApp à fournir (asset à coller dans `assets/icons/whatsapp.svg`).

---

## Definition of Done

- [x] Code commité sur branche `feat/story-001-design-tokens`.
- [x] `flutter analyze` passe sans warning sur `apps/flutter/` (0 issue).
- [x] `flutter test` vert (107 tests). Coverage 100% sur les lignes exécutables de `lib/core/design_system/tokens/` ; les fichiers full-const (`colors.dart`, `spacing.dart`) n'ont pas d'entrée lcov par construction — les snapshot tests valident chaque token contre la spec markdown.
- [x] Aucune occurrence de `Color(0xFF…)` ou de magic number spacing dans `lib/components/`, `lib/features/` — `scripts/check_no_hardcoded_tokens.dart` + test runner.
- [x] Tous les tokens markdown (colors.md, typography.md, spacing.md, icons.md) ont leur équivalent Dart — snapshot tests font le diff automatique.
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`) — **TODO post-PR**.
- [ ] PR mergée sur `main` — **TODO post-PR**.
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-001 status `completed`, completed_points sprint 1 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Setup `flutter create` + `pubspec.yaml` + structure dossiers | 0.5 | Boilerplate Flutter stable. |
| `colors.dart` (38 entrées) | 0.5 | Translation directe markdown → const. |
| `typography.dart` (9 styles + 11 tokens d'app) + setup `google_fonts` | 0.75 | Inclus le travail Roboto Mono pour valeurs FCFA. |
| `spacing.dart` + `radius` + `elevation` (10+5+5 entrées) | 0.25 | Translation directe. |
| `icons.dart` (mapping sémantique ~50 entrées) | 0.5 | Long mais mécanique. |
| Tests unitaires (4 fichiers) + script anti-hardcode + lint config | 0.5 | Ne pas sous-estimer — c'est ce qui rend les tokens vraiment **enforced**. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** Pas de logique conditionnelle, pas de réseau, pas d'état. C'est de la translation spec → Dart, mécaniquement, mais avec le filet (lint + tests) qui garantit que les futurs widgets respectent vraiment les tokens. Sans le filet, on retomberait dans des couleurs hardcodées en sprint 2.

---

## Notes additionnelles

- **Convention de nommage Showcase (STORY-004) :** chaque widget aura son `_<feature>_showcase.dart` avec `@Preview Light+Dark` + `main()` standalone. Cette story-ci crée juste les tokens — la convention showcase s'applique à partir de STORY-003.
- **Logo Scalario :** non concerné par cette story (pas d'asset logo à intégrer ici). Quand le logo sera intégré (story future), respecter la règle : monogramme = `Sc`, wordmark = `S + CALARIO`, jamais les deux ensemble.
- **i18n :** la typo expose Inter UTF-8, compatible français/anglais. La string FR vs EN n'est pas dans cette story (i18n setup = STORY-042).

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
