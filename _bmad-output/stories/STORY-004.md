# STORY-004 : Showcase Files + Flutter Widget Preview + Thème Global

**Epic :** EPIC-001 — Design System Scalario
**Priorité :** Must Have
**Story Points :** 4
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-001 (Tokens), STORY-002 (ThemeData), STORY-003 (Composants BDUI)

---

## User Story

> **En tant que** dev Flutter sur Scalario,
> **je veux** un fichier `_<feature>_showcase.dart` par composant BDUI (pattern Santera issu du projet `recherchelivraisonmedicament`), avec annotations `@Preview` Light + Dark consommables par `flutter widget-preview start`, plus un `main()` standalone runnable avec toggle dark/light dans l'AppBar,
> **so that** je peux visualiser et itérer sur n'importe quel composant DS — soit dans l'IDE (preview en temps réel), soit en lançant l'app standalone (`flutter run --target=lib/components/data_display/_kpi_card_showcase.dart`) — sans démarrer toute l'app, sans setup additionnel, et sans dupliquer le wiring de thème.

---

## Description

### Background

STORY-003 livre 7 composants BDUI métier. Sans showcase, la seule façon de les voir = lancer un écran complet de l'app (qui n'existe pas encore au Sprint 1). C'est cassé pour itérer rapidement, et c'est cassé pour la documentation visuelle (un nouveau dev qui rejoint le projet ne peut pas naviguer le DS sans deviner où chaque widget est utilisé).

**Pattern Santera (référence : `/home/carlos-simpore/StudioProjects/elyf_group_app/lib/features/tour/presentation/screens/...` — projet recherchelivraisonmedicament).** Chaque widget a son fichier compagnon `_<feature>_showcase.dart` avec :

- Header de commentaires : commandes de run (`flutter run --target=...` + `flutter widget-preview start`).
- Helpers locaux : `PreviewThemeData scalarioXThemes()` + `Widget scalarioXWrap(child)` pour wrapping uniforme.
- Annotations `@Preview` (Flutter 3.22+ via `package:flutter/widget_previews.dart`) — **un seul preview par variant** (sm/md/lg, loading, disabled), pas de duplication Light/Dark.
- `main()` standalone : `MaterialApp` avec **AppBar contenant un toggle dark/light** — c'est là qu'on switch les modes, pas dans `@Preview`.

**Pourquoi pas Widgetbook en primaire ?** Widgetbook est lourd (UI séparée, knobs, addons), excellent pour la **galerie de référence** mais friction élevée pour itérer. Le pattern `_showcase.dart` est plus léger (1 fichier = 1 widget = 1 preview), s'intègre dans le projet sans app dédiée, et reste compatible avec Widgetbook **en parallèle** (Widgetbook reste le miroir CI + snapshot tests visuels — Sprint 2+).

### Scope

**In scope :**

- 7 fichiers showcase (un par composant BDUI de STORY-003) :
  - `lib/components/data_display/_kpi_card_showcase.dart`
  - `lib/components/data_display/_data_table_showcase.dart`
  - `lib/components/data_display/_chart_bar_showcase.dart`
  - `lib/components/feedback/_alert_banner_showcase.dart`
  - `lib/components/actions/_scalario_fab_showcase.dart`
  - `lib/components/lists/_scalario_list_tile_showcase.dart`
  - `lib/components/inputs/_form_section_showcase.dart`
- 2 compositions showcases (écrans assemblés depuis composants) :
  - `lib/showcases/_dashboard_owner_showcase.dart` — KPICard×4 grid + AlertBanner + ChartBar + ListTile transactions.
  - `lib/showcases/_pos_commercial_showcase.dart` — ScalarioListTile articles + KPICard total panier + FAB encaisser.
- Fichier helper partagé : `lib/showcases/_showcase_app.dart` — classe `ScalarioShowcaseApp` réutilisée par tous les `main()` standalone (AppBar + toggle dark/light + ThemeMode state).
- Header standardisé en haut de chaque fichier showcase (commentaires de commandes).
- Wrapper helper `scalarioXWrap(child)` qui pad/scroll consistant.
- Setup `pubspec.yaml` : ajouter `widget_previews` (intégré Flutter 3.22+) — **pas** de dépendance externe.
- Setup Widgetbook en backup : `widgetbook/lib/main.widgetbook.dart` minimal qui pointe vers les composants — **stub uniquement** pour Sprint 1, populated en Sprint 2.
- Documentation : `apps/flutter/SHOWCASES.md` court qui explique comment lancer une preview.

**Out of scope (autres stories) :**

- Showcases pour les composants restants du DS (StatusBadge, SyncStatusBar, NumberInput, etc.) → créés en cascade au fil des stories qui les implémentent.
- Snapshot tests visuels (golden tests) — Sprint 2 via Widgetbook + `flutter_test golden`.
- Knobs interactifs (changer une prop runtime depuis l'UI showcase) — dans le scope Widgetbook plus tard.
- CI : intégration Widgetbook dans GitHub Actions → STORY-013 ou later.
- Compositions showcases au-delà de Dashboard Owner + POS Commercial → faits avec les écrans réels en Sprint 2+.

### User Flow (Developer Experience)

**Flow A — Preview dans l'IDE :**

1. Dev ouvre `lib/components/data_display/_kpi_card_showcase.dart` dans VSCode/Cursor.
2. Lance `flutter widget-preview start` (ou clique le bouton preview sur l'annotation `@Preview`).
3. L'IDE affiche les variantes (KPICard nominal, warning, critical, loading, empty, tappable) côte à côte.
4. Dev modifie une prop dans le code → preview se recharge automatiquement.

**Flow B — Standalone runnable :**

1. Dev lance `flutter run --target=lib/components/data_display/_kpi_card_showcase.dart -d chrome` (ou `-d <device>`).
2. App démarre avec `MaterialApp` + AppBar `KPICard Showcase` + toggle dark/light dans le coin supérieur droit.
3. Dev clique le toggle → tout le contenu bascule en dark, transition Flutter native.
4. Dev itère sur le widget en hot reload normal.

**Flow C — Composition (dashboard complet) :**

1. Dev veut voir comment les composants s'assemblent dans un dashboard owner.
2. Lance `flutter run --target=lib/showcases/_dashboard_owner_showcase.dart`.
3. Voit grid 2×2 KPICards + bandeau alerte stock + chart CA 7 derniers jours + liste transactions — sans backend, données mockées dans le fichier.

---

## Acceptance Criteria

### Pattern showcase (uniforme)

- [ ] AC-01 — Chaque fichier showcase commence par un header de commentaires standardisé (3 lignes minimum) :
  ```dart
  // Run (standalone):  flutter run --target=lib/components/data_display/_kpi_card_showcase.dart -d <device>
  // Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
  // Spec:              design-process/D-Design-System/components/02-data-display.md (KPICard)
  ```
- [ ] AC-02 — Chaque fichier importe `package:flutter/widget_previews.dart` + tokens + theme + le composant testé. Pas d'import depuis d'autres showcases (chaque fichier est autonome).
- [ ] AC-03 — Chaque fichier expose une fonction top-level `PreviewThemeData scalario<X>Themes()` qui retourne `PreviewThemeData(materialLight: ScalarioTheme.light(), materialDark: ScalarioTheme.dark())`.
- [ ] AC-04 — Chaque fichier expose une fonction top-level `Widget scalario<X>Wrap(Widget child)` qui wrappe `Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(ScalarioSpacing.space4), child: child))` — wrapping uniforme.
- [ ] AC-05 — Annotations `@Preview` : **un seul** par variant fonctionnelle (par ex. KPICard a `@Preview('Nominal')`, `@Preview('Warning')`, `@Preview('Critical')`, `@Preview('Loading')`, `@Preview('Empty')`, `@Preview('Tappable')`). **Pas** de doublon Light/Dark — la bascule mode se fait en standalone (`main()`).
- [ ] AC-06 — Chaque `@Preview` a `name`, `theme: scalario<X>Themes`, `wrapper: scalario<X>Wrap`. Conformité littérale au pattern Santera.

### Showcases composants (7 fichiers)

- [ ] AC-07 — `_kpi_card_showcase.dart` : 6 previews (Nominal, Warning, Critical, Tappable, Loading, Empty). Sketches conformes spec `02-data-display.md:34-69`.
- [ ] AC-08 — `_data_table_showcase.dart` : 5 previews (Normal, Sorted, Hover web, Loading, Empty). Données mockées : 5 lignes Tenants façon `A02` (`Boutique Kouamé`, `Shop Aminata`, etc. — strings illustratifs).
- [ ] AC-09 — `_alert_banner_showcase.dart` : 4 previews (Critical, Warning, Success, Info) + 1 preview `Critical avec action` (action label `Voir stock`). Auto-dismiss désactivé en preview (sinon disparaît au render).
- [ ] AC-10 — `_scalario_fab_showcase.dart` : 4 previews (Normal, Extended avec label, Loading, Disabled).
- [ ] AC-11 — `_scalario_list_tile_showcase.dart` : 6 previews (Simple, Avec leading+trailing, Status success/warning/danger border-left, Loading, Empty).
- [ ] AC-12 — `_form_section_showcase.dart` : 4 previews (Normal avec 3 enfants `Container` placeholder, Avec hint, Avec erreurs inline, Loading wrap). Vu que TextInput n'est pas dans STORY-003, utiliser des `Container` ou `TextField` Material 3 brut comme stand-in.
- [ ] AC-13 — `_chart_bar_showcase.dart` : 4 previews (Normal 7 jours, Loading shimmer, Empty, Erreur).

### Standalone `main()` avec toggle dark/light

- [ ] AC-14 — Chaque fichier showcase termine par un `main()` qui appelle `runApp(const ScalarioShowcaseApp(child: <X>Showcase()))` — pas de duplication de `MaterialApp`.
- [ ] AC-15 — `ScalarioShowcaseApp` (dans `lib/showcases/_showcase_app.dart`) :
  - `StatefulWidget` qui maintient un `ThemeMode _mode = ThemeMode.light`.
  - `MaterialApp` avec `theme: ScalarioTheme.light()`, `darkTheme: ScalarioTheme.dark()`, `themeMode: _mode`.
  - `Scaffold` avec `AppBar` contenant un `IconButton` (icône `ScalarioIcons.theme` ou `Icons.brightness_6`) en `actions` qui toggle entre `light` et `dark`.
  - Titre AppBar : nom du composant (passé en prop `title`).
- [ ] AC-16 — Toggle dark/light : transition fluide ≤ 200ms (par défaut Flutter `AnimatedTheme`), aucun glitch visuel — vérifié manuellement sur les 7 showcases.

### Compositions

- [ ] AC-17 — `_dashboard_owner_showcase.dart` :
  - 1 preview "Dashboard Owner" (ou variantes par taille viewport `mobile`, `web`).
  - Layout : `AlertBanner.warning` en haut + grid 2×2 `KPICard` (`CA jour`, `Marge`, `Transactions`, `Stock critique`) + `ChartBar` 7 jours + `ScalarioListTile` × 4 (transactions).
  - Données mockées en haut du fichier (constants).
  - `main()` runnable avec toggle dark/light.
- [ ] AC-18 — `_pos_commercial_showcase.dart` :
  - 1 preview "POS Commercial".
  - Layout : Liste `ScalarioListTile` articles (5 articles mockés) + bottom card avec `KPICard` total panier + `ScalarioFAB.extended` "Encaisser".
  - `main()` runnable.

### Configuration projet

- [ ] AC-19 — `pubspec.yaml` met à jour les dépendances pour activer `widget_previews` (intégré Flutter 3.22+, vérifier la version minimale dans le `environment` block).
- [ ] AC-20 — `widgetbook/lib/main.widgetbook.dart` créé minimal — stub avec `WidgetbookApp` + 1 case "Hello world" + import des composants. Déclaré dans `pubspec.yaml` du sub-package `widgetbook/`. **Galerie complète = Sprint 2.**
- [ ] AC-21 — `apps/flutter/SHOWCASES.md` (≤ 80 lignes) documente :
  - Comment lancer une preview (`flutter widget-preview start`).
  - Comment lancer un standalone (`flutter run --target=...`).
  - Convention de nommage (`_<feature>_showcase.dart`, fonctions `scalario<X>Themes` / `scalario<X>Wrap`).
  - Reference au pattern Santera + lien projet de référence.

### Hygiène & Tests

- [ ] AC-22 — `flutter analyze` passe sur tous les fichiers showcase + `lib/showcases/`.
- [ ] AC-23 — Aucune valeur hardcodée dans les showcases (tokens via `ScalarioColors`/`ScalarioSpacing`/`ScalarioTypography` ou via `Theme.of`). Vérifié script anti-hardcode (STORY-001).
- [ ] AC-24 — Tests smoke `test/showcases/` :
  - Pour chaque showcase, un test `flutter pumpWidget(ScalarioShowcaseApp(child: <X>Showcase()))` qui vérifie que le widget se monte sans exception.
  - Test toggle dark/light : tap sur l'IconButton → ThemeMode change → finder `Theme.of(context).brightness == Brightness.dark`.
- [ ] AC-25 — Au moins 1 preview par fichier est lancée manuellement et visualisée (commande `flutter widget-preview start` testée — checklist annotée dans la PR).
- [ ] AC-26 — Tous les composants BDUI de STORY-003 ont leur showcase — checklist 7/7 dans la PR.

---

## Technical Notes

### Composants concernés

- **Nouveau layer :** `apps/flutter/lib/showcases/` (compositions + helpers).
- **Showcases unitaires :** colocalisés avec les widgets (`lib/components/<group>/_<name>_showcase.dart`) — pas dans un dossier séparé. Le préfixe `_` les marque comme dev-only et les exclut implicitement des exports `components.dart` barrel.
- **Lit depuis :** STORY-001 (tokens), STORY-002 (`ScalarioTheme`), STORY-003 (composants).
- **Setup secondaire :** `apps/flutter/widgetbook/` — stub Sprint 1.

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   ├── components/
│   │   ├── data_display/
│   │   │   ├── kpi_card.dart
│   │   │   ├── _kpi_card_showcase.dart        ← STORY-004
│   │   │   ├── data_table.dart
│   │   │   ├── _data_table_showcase.dart      ← STORY-004
│   │   │   ├── chart_bar.dart
│   │   │   └── _chart_bar_showcase.dart       ← STORY-004
│   │   ├── feedback/
│   │   │   ├── alert_banner.dart
│   │   │   └── _alert_banner_showcase.dart    ← STORY-004
│   │   ├── actions/
│   │   │   ├── scalario_fab.dart
│   │   │   └── _scalario_fab_showcase.dart    ← STORY-004
│   │   ├── lists/
│   │   │   ├── scalario_list_tile.dart
│   │   │   └── _scalario_list_tile_showcase.dart  ← STORY-004
│   │   └── inputs/
│   │       ├── form_section.dart
│   │       └── _form_section_showcase.dart    ← STORY-004
│   └── showcases/
│       ├── _showcase_app.dart                 # ScalarioShowcaseApp (helper partagé)
│       ├── _dashboard_owner_showcase.dart
│       └── _pos_commercial_showcase.dart
├── widgetbook/
│   ├── lib/
│   │   └── main.widgetbook.dart               # stub
│   └── pubspec.yaml
├── test/
│   └── showcases/
│       ├── kpi_card_showcase_test.dart
│       ├── ... (1 par showcase)
│       └── showcase_app_test.dart
└── SHOWCASES.md
```

### Pattern Dart de référence (KPICard showcase)

```dart
// Run (standalone):  flutter run --target=lib/components/data_display/_kpi_card_showcase.dart
// Preview (IDE):     flutter widget-preview start
// Spec:              design-process/D-Design-System/components/02-data-display.md

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/showcases/_showcase_app.dart';

PreviewThemeData scalarioKPICardThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioKPICardWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

@Preview(name: 'Nominal', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardNominal() => const KPICard(
      label: 'CA du jour',
      value: '47 500',
      unit: 'FCFA',
      delta: '+12% vs hier',
      deltaPositive: true,
    );

@Preview(name: 'Critical', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardCritical() => const KPICard(
      label: 'Stock critique',
      value: '3',
      unit: 'articles',
      delta: '[!] alerte',
      deltaPositive: false,
      status: KpiStatus.critical,
    );

@Preview(name: 'Loading', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardLoading() => KPICard.loading(label: 'CA du jour');

@Preview(name: 'Empty', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardEmpty() => const KPICard.empty('Pas de données');

@Preview(name: 'Tappable', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardTappable() => KPICard(
      label: 'CA du jour',
      value: '47 500',
      unit: 'FCFA',
      delta: '+12%',
      onTap: () {},
    );

class _KPICardShowcase extends StatelessWidget {
  const _KPICardShowcase();
  @override
  Widget build(BuildContext context) => Column(
        children: [
          previewKPICardNominal(),
          const SizedBox(height: ScalarioSpacing.space4),
          previewKPICardCritical(),
          const SizedBox(height: ScalarioSpacing.space4),
          previewKPICardLoading(),
          const SizedBox(height: ScalarioSpacing.space4),
          previewKPICardEmpty(),
          const SizedBox(height: ScalarioSpacing.space4),
          previewKPICardTappable(),
        ],
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'KPICard Showcase',
      child: _KPICardShowcase(),
    ));
```

`ScalarioShowcaseApp` :

```dart
class ScalarioShowcaseApp extends StatefulWidget {
  const ScalarioShowcaseApp({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  State<ScalarioShowcaseApp> createState() => _ScalarioShowcaseAppState();
}

class _ScalarioShowcaseAppState extends State<ScalarioShowcaseApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      debugShowCheckedModeBanner: false,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      themeMode: _mode,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(_mode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined),
              tooltip: 'Toggle theme',
              onPressed: () => setState(() {
                _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
              }),
            ),
          ],
        ),
        body: widget.child,
      ),
    );
  }
}
```

### Spec source — résolution des conflits

**Conflit 1 — sprint plan title vs body : "Widgetbook + Thème Global" vs "Showcase Files".** Le titre Section du sprint plan dit "Widgetbook + Flutter Widget Preview + Thème Global" mais le corps de l'AC parle de showcases. La table récapitulative ligne 917 dit aussi `STORY-004 | Widgetbook + Thème Global`. **Décision (mémoire user `feedback_flutter_widget_preview.md`)** : la convention **primaire** = pattern showcase Santera (`_<feature>_showcase.dart` + `@Preview` + `main()` standalone). Widgetbook reste **secondaire** — gardé en stub Sprint 1, populé Sprint 2 comme galerie CI + snapshot tests visuels. Pas de conflit en pratique : on fait les deux, mais on priorise les showcases (qui livrent de la valeur dev immédiate).

**Conflit 2 — `@Preview` light + dark dupliqués vs un seul.** Sprint plan AC dit explicitement « **un seul** par variant — pas de duplication Light/Dark ». La bascule mode se fait dans le `main()` standalone (toggle AppBar). **Cohérent** — implémenter ainsi. Justification : doubler chaque preview ferait 12 cases pour KPICard (6 variants × 2 modes) — illisible.

**Conflit 3 — toggle theme : où ?** STORY-002 dit que l'app prod respecte `ThemeMode.system` (pas de toggle UX dans l'app prod). Cette story dit que les **showcases** ont un toggle dans leur AppBar. **Cohérent et complémentaire** — le toggle est un outil dev, pas une feature prod. Documenter clairement dans la docstring de `ScalarioShowcaseApp` : *« Dev-only — utilisé uniquement par les showcases. L'app prod (`main.dart`) n'a pas de toggle, elle suit l'OS. »*

**Conflit 4 — `flutter_widget_preview` package name.** L'API officielle Flutter pour previews est `package:flutter/widget_previews.dart` (intégré au SDK depuis 3.22, ne pas confondre avec un plugin externe). Vérifier la version Flutter dans `pubspec.yaml` (`environment.flutter: ">=3.22.0"`). Si la version locale < 3.22, ouvrir un PR séparé pour bumper le SDK avant de merger cette story.

### Edge cases

- **Préfixe `_` et imports.** Les fichiers `_<name>_showcase.dart` ont un underscore = library-private en Dart **uniquement si placés dans la même bibliothèque**. Comme chacun est son propre fichier top-level, l'underscore n'est qu'une **convention** (pas une garantie technique). Pour vraiment exclure les showcases du barrel `components.dart`, ne pas les ré-exporter dans le barrel — ce qui est implicite vu la convention de nommage. Documenter dans `SHOWCASES.md`.
- **Hot reload des `@Preview`.** Le widget preview tool recharge à chaque sauvegarde — vérifier qu'aucun showcase n'a d'état persistant (timer, controller non-disposé). Tous nos widgets sont `StatelessWidget` ou ont un `dispose()` correct.
- **Compositions = pas de logique métier.** `_dashboard_owner_showcase.dart` mocke les données en haut du fichier (`const _mockKpis = [...]`). **Aucun appel réseau, aucune logique.** Si un dev est tenté d'appeler une API ici, c'est qu'il est dans la mauvaise story.
- **Widgetbook stub vide.** `widgetbook/` peut casser la CI si on ne `pub get` pas correctement. Sprint 1 : stub minimal, **pas inclus dans le `pubspec.yaml` workspace**. Sprint 2 ajoute la galerie complète + workspace.
- **Toggle dark/light ne triggers pas hot reload sur tous les widgets.** Dans Flutter, changer `themeMode` rebuild l'arbre depuis `MaterialApp` — tous les `Theme.of(context)` se mettent à jour. Cas pathologique : un widget qui cache `Theme.of(context)` dans une variable static → ne se met pas à jour. Notre code STORY-003 lit `Theme.of` à chaque `build` → ok.
- **`fl_chart` couleur fixe en preview.** Le bar chart utilise `Theme.of(context).colorScheme.primary` — vérifier en preview que dark mode change effectivement la couleur des barres. Si non, `fl_chart` cache le thème — bug à reporter dans STORY-003.

### Sécurité

N/A — outil de développement, jamais build en release. Les fichiers `_*_showcase.dart` peuvent contenir des données mockées (ex: `Mamadou`, `Boutique Kouamé`) — vérifier que ce ne sont pas des vraies données de Blandine ou d'un tenant beta. Convention : noms **ostensiblement fictifs** (`Tenant Démo`, `Acme SARL`) ou prénoms ivoiriens génériques. Documenter dans `SHOWCASES.md`.

---

## Dependencies

**Prérequis :**

- **STORY-001** (Tokens) — strict.
- **STORY-002** (`ScalarioTheme.light()` / `.dark()`) — strict.
- **STORY-003** (les 7 composants BDUI) — strict.

**Stories bloquées par celle-ci :**

- Aucune **strictement** — les showcases n'apparaissent pas dans le code app prod. Mais c'est un **prérequis fort de productivité** pour Sprint 2+ : sans showcases, itérer sur un composant = lancer un écran complet.
- STORY-013 (Docker compose / CI) pourrait référencer `flutter widget-preview` dans la CI Sprint 2.

**Externes :**

- Flutter ≥ 3.22 (pour `package:flutter/widget_previews.dart`).
- Package `widgetbook: ^3.x` (déclaré uniquement dans `widgetbook/pubspec.yaml`, pas dans `apps/flutter/pubspec.yaml`).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-004-showcases-widget-preview`.
- [ ] `flutter analyze` passe sur tous les fichiers showcase + helpers.
- [ ] `flutter test apps/flutter/test/showcases/` vert (smoke tests pour chaque showcase + ScalarioShowcaseApp).
- [ ] 7 showcases composants + 2 compositions + helper créés et fonctionnels.
- [ ] `flutter widget-preview start` lancé manuellement sur les 9 fichiers — vérification visuelle annotée dans la PR (screenshots OK).
- [ ] `flutter run --target=lib/components/data_display/_kpi_card_showcase.dart` lance l'app standalone avec toggle dark/light fonctionnel — testé manuellement sur Web et Android.
- [ ] `apps/flutter/SHOWCASES.md` créé et lu (≤ 80 lignes).
- [ ] Widgetbook stub minimal créé dans `widgetbook/` (pas exigé fonctionnel — juste compile).
- [ ] Aucune valeur hardcodée dans les showcases (script anti-hardcode vert).
- [ ] Code review passé (`/codex review` recommandé).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-004 status `completed`, completed_points sprint 1 += 4.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `ScalarioShowcaseApp` (helper partagé + toggle theme) | 0.5 | Stateful avec setState — petit mais consommé par tous. |
| 7 showcases composants (header + helpers + 4-6 previews + main + composition class) | 1.5 | Mécanique répétitif, mais ~50-80 lignes par fichier × 7. |
| 2 compositions (dashboard owner + pos commercial) avec mocks réalistes | 1.0 | Plus de pensée layout — ressembler aux sketches du DS. |
| `widgetbook/` stub + pubspec config | 0.25 | Minimal Sprint 1. |
| `SHOWCASES.md` documentation | 0.25 | ≤ 80 lignes, lien vers projet Santera de référence. |
| Tests smoke + toggle theme test (8 fichiers) | 0.5 | pumpWidget + finder, répétitif. |
| **Total** | **4** | Fibonacci 4 — entre 3 (mécanique) et 5 (complexe), pile au milieu. |

**Rationale :** Pas de complexité algorithmique mais 9 fichiers × pattern uniforme à respecter exactement = volume non-trivial. Le piège est de copy-paste mal — un nom de fonction `scalarioKPICardThemes` qui devient `scalarioDataTableThemes` fait merger des thèmes inattendus. Le filet est la convention stricte de nommage + le smoke test par showcase.

---

## Notes additionnelles

- **Pattern de référence Santera : projet `recherchelivraisonmedicament`.** Mémoire user (`feedback_flutter_widget_preview.md`) : *« Chaque widget = fichier `_<feature>_showcase.dart` avec @Preview Light+Dark + main() standalone. Référence : projet recherchelivraisonmedicament. »* — Aller voir le projet pour calibrer le ton/structure exacte si besoin (`/home/carlos-simpore/StudioProjects/elyf_group_app/`).
- **Note importante mémoire user vs sprint plan AC.** Mémoire dit "@Preview Light+Dark" (deux previews par variant). Sprint plan AC dit "**un seul** par variant — pas de duplication Light/Dark". **Sprint plan gagne** (plus récent : 2026-05-09 vs entrée mémoire). Le toggle dark/light est dans le `main()` AppBar — c'est plus puissant qu'un preview dupliqué (un seul tap = bascule live, pas deux frames côte à côte).
- **Widgetbook plus tard.** Quand on aura 30+ composants, Widgetbook deviendra utile pour la galerie. Sprint 1 : 7 composants × showcases — pas besoin de Widgetbook full. Stub seulement.
- **i18n** : showcases en français, mocks en français. Pas d'effort i18n ici.
- **Logo Scalario** : pas concerné par cette story.
- **Composition Manager Dashboard** (S22 — Ibrahim) : **pas dans cette story**. Sera créé en Sprint 2 par STORY-019/020/021 directement avec les écrans réels.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-10 : Completed (Carlos / Dev via `/bmad:dev-story`)

**Actual Effort :** 4 points (matched estimate)

**Implementation Notes :**
- Pattern Santera respecté : 7 fichiers `_<feature>_showcase.dart` + 2 compositions + helper `ScalarioShowcaseApp`
- `@Preview` avec thème/wrapper Scalario, un seul preview par variant (pas de duplication Light/Dark — toggle dans le `main()`)
- `flutter analyze` vert sur tous les fichiers showcase
- 11 smoke tests verts (`test/showcases/`)
- Widgetbook stub minimal créé dans `widgetbook/` (Sprint 2 = galerie complète)
- `SHOWCASES.md` créé ≤ 80 lignes

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
