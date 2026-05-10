# STORY-002 : Material 3 + ThemeData Scalario

**Epic :** EPIC-001 — Design System Scalario
**Priorité :** Must Have
**Story Points :** 3
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-001 (Design Tokens Flutter)

---

## User Story

> **En tant que** dev Flutter sur Scalario,
> **je veux** un `ThemeData` Scalario complet branché sur les tokens (STORY-001) et étendu via `ThemeExtensions` pour les sémantiques métier (sync, conflict, surfaces application),
> **so that** chaque composant Material 3 (`FilledButton`, `Card`, `TextField`, `Dialog`, `DataTable`…) consomme automatiquement la palette/typo/spacing Scalario sans valeur hardcodée — light + dark — et que les widgets métier de STORY-003 lisent leurs couleurs sémantiques (`syncedColor`, `conflictColor`…) via `Theme.of(context).extension<ScalarioColors>()` plutôt que d'importer les classes de tokens directement.

---

## Description

### Background

STORY-001 expose les tokens en classes statiques Dart. Mais Flutter natif raisonne en `ThemeData` / `ColorScheme` / `TextTheme` : sans wiring, chaque `FilledButton` du SDK reste bleu Material par défaut, chaque `TextField` ignore la palette Scalario, et le `DataTable` Material ne sait rien des couleurs neutrales du DS.

Cette story est le **pont** entre tokens Dart (statiques) et le runtime Flutter (réactif). Elle fait deux choses :

1. **ThemeData light + dark** construits depuis `ScalarioColors` / `ScalarioTypography` / `ScalarioSpacing` — toutes les primitives Material 3 héritent.
2. **`ThemeExtension`** custom pour les tokens **qui n'ont pas d'équivalent dans `ColorScheme`** : statuts sync (synced/syncing/offline/error), couleurs sémantiques sync/conflict, élévations Scalario, espacements layout — accessibles via `Theme.of(context).extension<ScalarioThemeExtension>()`.

C'est explicitement **Material 3 natif** — déjà flat, accessible, à jour, zéro dépendance UI externe à maintenir.

### Scope

**In scope :**

- `lib/core/theme/` :
  - `scalario_theme.dart` — point d'entrée : `ScalarioTheme.light()`, `ScalarioTheme.dark()` retournent `ThemeData`.
  - `color_scheme_builder.dart` — construit `ColorScheme.light` et `ColorScheme.dark` depuis `ScalarioColors`.
  - `text_theme_builder.dart` — construit `TextTheme` depuis `ScalarioTypography`.
  - `theme_extensions.dart` — `ScalarioColorsExtension`, `ScalarioSpacingExtension`, `ScalarioElevationExtension`.
- Component themes Material 3 explicitement configurés depuis tokens : `ElevatedButtonTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `TextButtonTheme`, `CardTheme`, `InputDecorationTheme`, `DialogTheme`, `BadgeTheme`, `DataTableThemeData`, `AppBarTheme`, `BottomNavigationBarTheme`, `FloatingActionButtonTheme`, `IconTheme`, `DividerTheme`.
- Variants Scalario nommées (`primary`, `secondary`, `ghost`, `danger`) exposées via une `ButtonStyleResolver` qui mappe vers les variantes Material 3 — pas de nouveau widget, juste des `ButtonStyle` réutilisables.
- Mode sombre fonctionnel (light + dark) avec valeurs dark-first documentées dans `ScalarioColorsExtension`.
- Dans `main.dart` : `MaterialApp` consomme `ScalarioTheme.light()` / `ScalarioTheme.dark()` + `ThemeMode.system`.
- Tests de thème : smoke (build sans erreur), snapshot couleurs (`ColorScheme.primary == ScalarioColors.primary500`), parité light/dark (mêmes clés exposées).

**Out of scope (autres stories) :**

- Composants BDUI métier (KPICard, AlertBanner, etc.) → STORY-003.
- Showcase / `@Preview` annotations → STORY-004.
- Toggle dark/light dans une AppBar runtime (UX util) → STORY-004 (le toggle vit dans les `main()` standalone des showcases, pas dans l'app prod).
- Theming par tenant (overrides via JSON) → Phase 2 du DS, hors EPIC-001.
- Animations de transition `AnimatedTheme` cross-fade → laissé au comportement par défaut Flutter.

### User Flow (Developer Experience)

1. Dev démarre l'app : `MaterialApp(theme: ScalarioTheme.light(), darkTheme: ScalarioTheme.dark(), themeMode: ThemeMode.system)`.
2. Dev écrit `FilledButton(onPressed: ..., child: Text('Vendre'))` → bouton Scalario primary (bleu primary-500, 48px h, radius-md, typo `fontButton`) sans paramètre supplémentaire.
3. Dev veut un bouton danger : `FilledButton(style: ScalarioButtonStyles.danger, ...)` — pas un nouveau widget.
4. Dev veut la couleur "synced" pour la `SyncStatusBar` : `Theme.of(context).extension<ScalarioColorsExtension>()!.synced`.
5. L'OS bascule en dark : tous les composants se retournent automatiquement (couleurs sombres, contrastes corrects, hot reload ok).
6. Dev ajoute un `Card(child: ...)` : padding, élévation, radius hérités du `CardTheme` Scalario — aucun override local.

---

## Acceptance Criteria

### ColorScheme

- [ ] AC-01 — `ScalarioTheme.light()` retourne un `ThemeData` avec `useMaterial3: true` et `colorScheme` construit explicitement (pas via `ColorScheme.fromSeed`) :
  - `primary = ScalarioColors.primary500`, `onPrimary = ScalarioColors.white`.
  - `secondary = ScalarioColors.primary300`, `onSecondary = ScalarioColors.textPrimary`.
  - `error = ScalarioColors.danger500`, `onError = ScalarioColors.white`.
  - `surface = ScalarioColors.bgCard`, `onSurface = ScalarioColors.textPrimary`.
  - `surfaceContainerHighest = ScalarioColors.neutral100`.
  - `outline = ScalarioColors.borderDefault`.
- [ ] AC-02 — `ScalarioTheme.dark()` retourne le `ThemeData` dark équivalent avec inversions documentées dans `ScalarioColorsExtension` (commentaires `// dark-first`).
- [ ] AC-03 — Tous les hex de `ColorScheme` proviennent de `ScalarioColors` — aucun `Color(0xFF…)` dans `lib/core/theme/`.

### TextTheme

- [ ] AC-04 — `TextTheme` mappe les 9 styles `ScalarioTypography` sur les slots Material 3 :
  - `displayLarge` → `ScalarioTypography.display`.
  - `headlineLarge` → `ScalarioTypography.headline`.
  - `titleLarge` → `ScalarioTypography.title`.
  - `bodyLarge` → `ScalarioTypography.bodyLg`.
  - `bodyMedium` → `ScalarioTypography.body`.
  - `labelLarge` → `ScalarioTypography.bodyMedium`.
  - `bodySmall` → `ScalarioTypography.caption`.
  - `labelSmall` → `ScalarioTypography.captionMedium`.
  - `labelMedium` → `ScalarioTypography.overline`.
- [ ] AC-05 — `Text('xyz')` sans `style:` rend `bodyMedium` Inter 14sp 400 conforme spec.

### Component Themes

- [ ] AC-06 — `FilledButtonTheme` configuré : hauteur 48px, padding horizontal `space4`, radius `md`, fond `primary500`, typo `fontButton`.
- [ ] AC-07 — `OutlinedButtonTheme` : bordure `borderDefault` 1.5px, fond transparent, texte `primary500`, hauteur 48px.
- [ ] AC-08 — `TextButtonTheme` (= ghost) : pas de fond/bordure, texte `primary500`, hauteur 40px.
- [ ] AC-09 — `CardTheme` : `surfaceTintColor: Colors.transparent` (pas de teinte M3), `elevation: 1`, radius `md`, padding 0 (le contenu gère son padding).
- [ ] AC-10 — `InputDecorationTheme` : bordures `OutlineInputBorder` radius `sm`, focus `borderFocus`, error `danger500`, hint `textDisabled`, fond `bgCard`.
- [ ] AC-11 — `DialogTheme` : radius `lg`, fond `bgCard`, élévation `e3`, padding `space5`.
- [ ] AC-12 — `AppBarTheme` : fond `bgPage`, élévation 0, titre typo `fontPageTitle`, foreground `textPrimary`.
- [ ] AC-13 — `FloatingActionButtonTheme` : couleur `primary500`, `extendedTextStyle = ScalarioTypography.bodyMedium`, radius `lg`.
- [ ] AC-14 — `BadgeTheme`, `BottomNavigationBarTheme`, `DataTableThemeData`, `IconTheme`, `DividerTheme` configurés depuis tokens — listés explicitement dans `scalario_theme.dart`.

### Variants Scalario (boutons nommés)

- [ ] AC-15 — Classe `ScalarioButtonStyles` expose 4 `ButtonStyle` const :
  - `primary` (= défaut FilledButton).
  - `secondary` (= OutlinedButton primary300).
  - `ghost` (= TextButton).
  - `danger` (= FilledButton fond `danger500`).
- [ ] AC-16 — Tous accessibles via `style:` sur `FilledButton`/`OutlinedButton`/`TextButton` Material 3 — **aucun nouveau widget créé**, on reste sur les primitives M3.

### ThemeExtensions

- [ ] AC-17 — `ScalarioColorsExtension extends ThemeExtension<ScalarioColorsExtension>` expose les couleurs sémantiques métier non couvertes par `ColorScheme` :
  - `synced`, `syncing`, `offline`, `syncError` (4 statuts SyncStatusBar).
  - `conflict` (couleur conflits Drift, alias warning-700 en light).
  - `surplus`, `critical`, `rupture` (statuts stock).
  - `pendingCredit` (warning-700, vente crédit).
  - Implémente `copyWith` et `lerp` (exigence `ThemeExtension`).
- [ ] AC-18 — `ScalarioSpacingExtension` expose les tokens spacing pour qu'un widget puisse lire `Theme.of(context).extension<ScalarioSpacingExtension>()!.space4` plutôt que d'importer `ScalarioSpacing` directement (préférence runtime).
- [ ] AC-19 — `ScalarioElevationExtension` expose `e0..e4` comme `List<BoxShadow>` (déjà construits dans STORY-001 — ici on les wrappe pour exposition runtime).
- [ ] AC-20 — Light et dark fournissent **les mêmes clés** d'extensions avec valeurs adaptées — vérifié par test (`light.extensions.keys == dark.extensions.keys`).

### Mode sombre

- [ ] AC-21 — `MaterialApp(themeMode: ThemeMode.system)` switche light↔dark sans glitch, transition Flutter native ≤ 200ms.
- [ ] AC-22 — Bascule manuelle (`ThemeMode.dark`) en hot reload : tous les composants Material 3 (boutons, cards, inputs, dialogs) se retournent — vérifié par test widget.
- [ ] AC-23 — Aucun composant n'a une couleur "qui reste light" en dark — vérifié par snapshot (`flutter test --update-goldens` sur un screen témoin).

### Hygiène & Tests

- [ ] AC-24 — `flutter analyze` passe sans warning sur `lib/core/theme/`.
- [ ] AC-25 — Tests unitaires `test/core/theme/` :
  - Smoke `light()` et `dark()` build un `ThemeData` non-null.
  - Snapshot `ColorScheme` light : 6 clés clés (primary, onPrimary, error, surface, onSurface, outline) match `ScalarioColors`.
  - Smoke `TextTheme` : `bodyMedium.fontSize == 14` et `fontFamily contient 'Inter'`.
  - `ScalarioColorsExtension.lerp(0.5, ...)` retourne instance non-null (pas de NPE).
  - Parité light/dark : extensions exposent les mêmes types.
- [ ] AC-26 — Tests widget `test/core/theme/component_themes_test.dart` : `pumpWidget(MaterialApp(theme: ScalarioTheme.light(), home: FilledButton(...)))` rend un bouton avec `material.color == primary500` et `borderRadius == md`.
- [ ] AC-27 — Couverture ≥ 85% sur `lib/core/theme/`.

---

## Technical Notes

### Composants concernés

- **Nouveau layer :** `apps/flutter/lib/core/theme/`.
- **Consommé par :** STORY-003 (composants BDUI), STORY-004 (showcases — qui utilisent `scalarioXThemes()` pointant ici), `main.dart`.
- **Lit depuis :** STORY-001 (`lib/core/design_system/tokens/`).

### Structure de fichiers (cible)

```
apps/flutter/lib/core/theme/
├── scalario_theme.dart            # ScalarioTheme.light() / .dark() — point d'entrée public
├── color_scheme_builder.dart      # _buildLightColorScheme(), _buildDarkColorScheme()
├── text_theme_builder.dart        # _buildTextTheme()
├── component_themes/
│   ├── button_themes.dart         # FilledButton/Outlined/TextButton themes
│   ├── input_themes.dart          # InputDecorationTheme
│   ├── surface_themes.dart        # CardTheme, DialogTheme, AppBarTheme
│   ├── feedback_themes.dart       # BadgeTheme, DividerTheme, IconTheme
│   └── data_themes.dart           # DataTableThemeData, BottomNavigationBarTheme, FAB
├── theme_extensions.dart          # ScalarioColorsExtension, SpacingExtension, ElevationExtension
└── button_styles.dart             # ScalarioButtonStyles.{primary,secondary,ghost,danger}

apps/flutter/test/core/theme/
├── scalario_theme_test.dart
├── color_scheme_test.dart
├── text_theme_test.dart
├── component_themes_test.dart
└── theme_extensions_test.dart
```

### Pattern Dart recommandé

`ThemeData` construit en pure fonction, immuable, mémoizable :

```dart
abstract final class ScalarioTheme {
  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark()  => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? _buildDarkColorScheme() : _buildLightColorScheme();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      textTheme: _buildTextTheme(colors),
      filledButtonTheme: buildFilledButtonTheme(colors),
      outlinedButtonTheme: buildOutlinedButtonTheme(colors),
      textButtonTheme: buildTextButtonTheme(colors),
      cardTheme: buildCardTheme(colors),
      inputDecorationTheme: buildInputDecorationTheme(colors),
      dialogTheme: buildDialogTheme(colors),
      appBarTheme: buildAppBarTheme(colors),
      floatingActionButtonTheme: buildFabTheme(colors),
      badgeTheme: buildBadgeTheme(colors),
      dataTableTheme: buildDataTableTheme(colors),
      bottomNavigationBarTheme: buildBottomNavTheme(colors),
      iconTheme: IconThemeData(color: colors.onSurface, size: ScalarioIconSize.md),
      dividerTheme: DividerThemeData(color: colors.outline, thickness: 1),
      extensions: <ThemeExtension<dynamic>>[
        ScalarioColorsExtension.fromBrightness(brightness),
        ScalarioSpacingExtension.standard(),
        ScalarioElevationExtension.fromBrightness(brightness),
      ],
    );
  }
}
```

`ScalarioColorsExtension` exemple :

```dart
@immutable
class ScalarioColorsExtension extends ThemeExtension<ScalarioColorsExtension> {
  const ScalarioColorsExtension({
    required this.synced,
    required this.syncing,
    required this.offline,
    required this.syncError,
    required this.conflict,
    required this.surplus,
    required this.critical,
    required this.rupture,
    required this.pendingCredit,
  });

  final Color synced;
  final Color syncing;
  final Color offline;
  final Color syncError;
  final Color conflict;
  final Color surplus;
  final Color critical;
  final Color rupture;
  final Color pendingCredit;

  factory ScalarioColorsExtension.fromBrightness(Brightness b) {
    if (b == Brightness.dark) {
      return ScalarioColorsExtension(
        synced:        ScalarioColors.success500,
        syncing:       ScalarioColors.primary300,
        offline:       ScalarioColors.neutral500,   // jamais rouge — P3
        syncError:     ScalarioColors.warning500,
        conflict:      ScalarioColors.warning700,
        surplus:       ScalarioColors.primary300,
        critical:      ScalarioColors.danger500,
        rupture:       ScalarioColors.danger700,
        pendingCredit: ScalarioColors.warning700,
      );
    }
    return ScalarioColorsExtension(
      synced:        ScalarioColors.success500,
      syncing:       ScalarioColors.primary500,
      offline:       ScalarioColors.neutral500,
      syncError:     ScalarioColors.warning500,
      conflict:      ScalarioColors.warning700,
      surplus:       ScalarioColors.primary500,
      critical:      ScalarioColors.danger500,
      rupture:       ScalarioColors.danger700,
      pendingCredit: ScalarioColors.warning700,
    );
  }

  @override
  ScalarioColorsExtension copyWith({Color? synced, /* ... */}) => /* ... */;

  @override
  ScalarioColorsExtension lerp(ThemeExtension<ScalarioColorsExtension>? other, double t) {
    if (other is! ScalarioColorsExtension) return this;
    return ScalarioColorsExtension(
      synced: Color.lerp(synced, other.synced, t)!,
      // ... toutes les couleurs
    );
  }
}
```

`ScalarioButtonStyles` :

```dart
abstract final class ScalarioButtonStyles {
  static final ButtonStyle primary = FilledButton.styleFrom(
    backgroundColor: ScalarioColors.primary500,
    foregroundColor: ScalarioColors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  static final ButtonStyle danger = FilledButton.styleFrom(
    backgroundColor: ScalarioColors.danger500,
    foregroundColor: ScalarioColors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  // secondary, ghost — idem.
}
```

### Spec source — résolutions de conflits

**Conflit 1 — Base UI.** PRD et architecture alignés sur Material 3 Flutter natif + tokens Scalario via `ThemeData` + `ThemeExtensions`. Aucune dépendance UI externe. Cette story implémente Material 3 pur.

**Conflit 2 — variants nommées.** Le sprint plan parle de variants `primary` / `secondary` / `ghost` / `danger`. La spec DS (`components/05-actions.md`) nomme `primary` / `secondary` / `destructive` / `ghost`. **Source de vérité : la spec DS** — on aligne sur `destructive` côté ASCII / docs, mais on expose **deux noms équivalents** côté Dart : `ScalarioButtonStyles.danger` (terme sprint plan, plus court) avec alias `ScalarioButtonStyles.destructive`. Préférence dans la PR : utiliser `danger` partout dans le code, garder `destructive` exporté pour cohérence avec la spec ASCII.

**Conflit 3 — toggle dark/light dans l'AppBar.** Le sprint plan mentionne un toggle dans l'AppBar de l'app. **Décision** : ce toggle est dans les `main()` standalone des **showcases (STORY-004)** — pas dans l'app prod. L'app prod respecte `ThemeMode.system` (l'OS décide). Note STORY-004 : l'AppBar des showcases force l'override pour preview Light vs Dark sans changer l'OS.

### Edge cases

- **Surface tint Material 3.** M3 applique par défaut une teinte primary translucide sur les surfaces élévées (`surfaceTintColor`). Cela contredit la palette neutre Scalario. **Fix :** `surfaceTintColor: Colors.transparent` sur `CardTheme`, `AppBarTheme`, `DialogTheme`, `BottomSheetTheme`. À documenter dans `scalario_theme.dart`.
- **`ColorScheme.fromSeed` ne match pas la palette exacte.** `fromSeed` génère une palette algorithmique qui dévie de nos hex. **Fix :** construire `ColorScheme` à la main (ctor explicite avec tous les champs), pas via `fromSeed`. Vérifié par snapshot AC-03.
- **Dark scheme manquant dans `tokens/colors.md`.** La spec ne précise pas explicitement les hex dark. **Fix temporaire :** dériver mécaniquement (`bgPage = neutral900`, `bgCard = neutral700`, `textPrimary = neutral50`, `textSecondary = neutral300`) — documenter dans `color_scheme_builder.dart` avec commentaire `// TODO: validate dark palette with designer Sprint 2`.
- **`google_fonts` runtime fetch en dark.** Inter ne change pas selon le mode — pas d'impact, mais s'assurer que `GoogleFonts.config.allowRuntimeFetching` reste cohérent entre light/dark builds (pas de re-fetch au switch).
- **`ThemeExtension.lerp` lors d'`AnimatedTheme`.** Flutter interpole les extensions via `lerp` durant les transitions. Implémentation correcte de `lerp` obligatoire (sinon couleurs sémantiques "sautent" au lieu de fade). Test dédié AC-25.
- **DataTable Material 3 sur Web.** `DataTableThemeData` doit configurer `headingTextStyle = ScalarioTypography.captionMedium`, `dataTextStyle = ScalarioTypography.body`, `headingRowColor: WidgetStateProperty.all(neutral50)`. Pas de `dividerThickness > 1` — flat design.

### Sécurité

N/A — couche présentation pure. Pas d'input utilisateur, pas de secret. Le seul risque est un mismatch hex qui passerait inaperçu — couvert par les snapshot tests AC-25.

---

## Dependencies

**Prérequis :**

- **STORY-001** (Design Tokens Flutter) — strict. Sans `ScalarioColors`/`ScalarioTypography`/`ScalarioSpacing`, rien à wirer.

**Stories bloquées par celle-ci :**

- STORY-003 (Composants BDUI Métier) — direct (les composants lisent leur thème via `Theme.of(context)`).
- STORY-004 (Showcase + Widget Preview) — direct (`scalarioXThemes()` retourne `ScalarioTheme.light/dark`).
- Indirectement, **toutes** les stories qui rendent du UI à partir de Sprint 1 (EPIC-002+).

**Externes :**

- Flutter SDK ≥ 3.22 (pour `useMaterial3` stable et `WidgetStateProperty` non-deprecated).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-002-themedata-scalario`.
- [ ] `flutter analyze` passe sans warning sur `lib/core/theme/`.
- [ ] `flutter test apps/flutter/test/core/theme/` vert avec ≥ 85% couverture sur `lib/core/theme/`.
- [ ] Aucune valeur hex (`Color(0xFF…)`) ni magic spacing dans `lib/core/theme/` — vérifié par script anti-hardcode (script de STORY-001).
- [ ] `ColorScheme` light + dark snapshots verts.
- [ ] `MaterialApp(theme: ScalarioTheme.light(), darkTheme: ScalarioTheme.dark())` testé manuellement avec basculement OS — pas de glitch.
- [ ] Code review passé (`/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-002 status `completed`, completed_points sprint 1 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `color_scheme_builder.dart` (light + dark, 16 slots × 2) | 0.5 | Mécanique mais doit matcher hex exact. |
| `text_theme_builder.dart` (mapping 9 styles → slots M3) | 0.25 | Direct. |
| Component themes (12 fichiers : button×3, input, card, dialog, appbar, fab, badge, data, bottomnav, divider, icon) | 1.0 | Le gros — chaque thème lit `colors`/`textTheme` et configure ~5-10 props. |
| `ScalarioButtonStyles` (4 variants) | 0.25 | Quatre `styleFrom` + alias `destructive`. |
| `ThemeExtension`s (Colors + Spacing + Elevation) avec `copyWith`+`lerp` | 0.5 | `lerp` correct = pas trivial sur 9 couleurs. |
| Tests (smoke + snapshots + parité + lerp) | 0.5 | Couverture ≥ 85% exigée. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** Mécanique mais détaillé. Pas de logique métier, pas d'IO, pas d'état. Le risque est l'oubli d'un component theme (ex : `BottomSheetTheme`) → le composant correspondant aura des couleurs M3 par défaut en STORY-003. Le filet est la liste exhaustive AC-06 à AC-14 + le test snapshot.

---

## Notes additionnelles

- **Base Material 3 :** documenter dans `apps/flutter/lib/core/theme/scalario_theme.dart` en docstring de classe : *« Base : Material 3 natif Flutter (2026-05-10). Material 3 est déjà flat, accessible, à jour, et évite toute dépendance UI externe. Le DS Scalario s'applique via ThemeData + ThemeExtensions. »*
- **Hot reload du thème en dev :** garantie automatique par Flutter dès que `ScalarioTheme.light()` est une fonction pure — aucune config supplémentaire.
- **Couleur `info-700` manquante dans tokens.** STORY-001 expose `info100/500` mais pas `info700`. Si `DialogTheme` ou un component theme en a besoin, **ne pas l'inventer ici** — ajouter une issue séparée pour étendre la palette en STORY-001 (post-merge).
- **Roboto Mono dans les TextTheme slots.** `bodyMedium`/`labelLarge` restent en Inter ; les widgets numériques (KPICard value, totaux POS) utiliseront `style: ScalarioTypography.fontKpiValue` explicitement (passé via la classe tokens, pas via `Theme.of`). Cohérent avec la règle "mono pour temps réel".
- **Convention STORY-004 :** chaque widget `_X_showcase.dart` consomme `ScalarioTheme.light()` / `ScalarioTheme.dark()` depuis cette story — pas de thème dupliqué.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-10 : Implemented + tested + completed (Carlos / Dev via `/bmad:dev-story STORY-002`)

**Actual Effort :** 3 points (matched estimate)

**Implementation Notes :**
- Architecture conforme à la story : `lib/core/theme/` avec `scalario_theme.dart` comme point d'entrée + 5 component-theme files + 3 ThemeExtensions.
- `ColorScheme` construit explicitement (pas via `fromSeed`) — palette Scalario exacte. Seuls `Colors.transparent` (surface tinting M3) et `Colors.black` (shadow/scrim M3) sont utilisés en dehors de `ScalarioColors`, conforme à AC-03.
- 4 variants `ScalarioButtonStyles` (primary/secondary/ghost/danger) + alias `destructive` pour cohérence avec la spec ASCII.
- `ThemeExtension.lerp` correct sur les 9 couleurs sémantiques + 10 spacings (élévations snap au target à t≥0.5 — Flutter ne sait pas mélanger des `BoxShadow` proprement).
- `surfaceTintColor: Colors.transparent` appliqué à Card/AppBar/Dialog/BottomSheet/Button/FAB/DataTable pour conserver la palette neutre Scalario.
- Tests : 154 tests passent (47 dans `test/core/theme/` + 107 hérités), couverture **97.1 %** sur `lib/core/theme/` (≥ 85 % requis).
- `flutter analyze` clean. Anti-hardcode scanner clean (`lib/core/theme/` exempt mais aucun `Color(0xFF…)` non plus).
- Workflow : commit direct sur `main` (trunk-based per règle Scalario pré-Gate 0).

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
