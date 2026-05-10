# STORY-003 : Composants BDUI Métier

**Epic :** EPIC-001 — Design System Scalario
**Priorité :** Must Have
**Story Points :** 5
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-001 (Design Tokens), STORY-002 (ThemeData)

---

## User Story

> **En tant que** moteur BDUI Scalario,
> **je veux** les 7 composants métier core (`KPICard`, `DataTable`, `AlertBanner`, `FAB`, `ListTile`, `FormSection`, `ChartBar`) implémentés en Dart, chacun avec **tous ses états** (Normal, Warning, Danger, Loading, Vide, Erreur),
> **so that** le `ComponentRegistry` (STORY-005) peut, en lisant un type string depuis JSON, instancier n'importe lequel d'entre eux et le remplir depuis un `ComponentConfig` typé — sans logique métier dans le widget, sans valeur hardcodée, sans `if (tenantSlug == 'X')`.

---

## Description

### Background

Scalario est BDUI : 100% des écrans sont décrits en JSON, instanciés à runtime. Le contrat est : *un type string JSON → un widget Flutter*. STORY-005 (`ComponentRegistry`) est la mécanique de résolution. **STORY-003 est le contenu du registry** — les widgets eux-mêmes.

7 composants suffisent à couvrir 80% des écrans Phase 1 MVP (dashboard owner, dashboard manager, POS commercial, vue stock, vue alertes, formulaires de saisie, exports). Les 66 autres composants du DS (StatusBadge, SyncStatusBar, FilterChip, etc.) sont implémentés en stories ultérieures de l'EPIC ou en cascade quand un écran les exige.

Chaque widget de cette story :

1. Consomme un objet `ComponentConfig` (pour cette story : `Map<String, dynamic>` typé via une `factory.fromJson(map)` — la version Zod-générée arrive en STORY-023). Les props correspondent **exactement** aux specs DS `components/01..10-*.md`.
2. Lit ses couleurs/typo/spacing **uniquement** depuis `Theme.of(context)` + `ScalarioColors` constants — zéro hex, zéro magic number.
3. Implémente **tous les états** : Normal, Warning, Danger, Loading, Vide, Erreur.
4. Est **stateless** par défaut — l'état métier vit dans le data layer (Drift/Riverpod), pas dans le widget.

### Scope

**In scope (7 composants) :**

| # | Composant | Spec DS | États |
|---|-----------|---------|-------|
| 1 | `KPICard` | `components/02-data-display.md` (lignes 14-69) | Nominal, Warning, Critical (Danger), Tappable, Loading, Vide, Erreur |
| 2 | `DataTable` | `components/02-data-display.md` (lignes 529-559) | Normal, Tri actif, Hover, Loading, Vide, Erreur |
| 3 | `AlertBanner` | `components/01-feedback.md` (lignes 14-68) | Critical, Warning, Success (auto-dismiss), Info, Absent |
| 4 | `ScalarioFAB` | `components/05-actions.md` (variante FAB) + Material 3 `FloatingActionButton` | Normal, Disabled, Loading, Extended (avec label) |
| 5 | `ScalarioListTile` | `components/06-lists.md` (pattern liste générique) | Normal, Tappable, Disabled, Loading, Vide, Erreur, Avec leading/trailing |
| 6 | `FormSection` | `components/03-inputs.md` (variante FormWidget — section regroupée) | Normal, Avec hint, Avec erreur de validation, Loading (champs disabled) |
| 7 | `ChartBar` | `components/02-data-display.md` (lignes 182-222) | Normal, Loading (skeleton bars), Vide (pas de données), Erreur |

**Out of scope (autres stories) :**

- `ComponentRegistry.register()` et résolution depuis type string → STORY-005.
- JSON Schema + génération `ComponentConfig` typé (Zod / quicktype) → STORY-023.
- Composants restants du DS (StatusBadge, SyncStatusBar, FilterChip, NumberInput, etc.) → en cascade dans Sprint 2+ par les stories qui en ont besoin.
- ConfirmationDialog (composant Action) → typiquement utilisé par STORY-019/020 (POS), créé avec elle.
- Showcase files `_<feature>_showcase.dart` → STORY-004.
- Tests visuels golden — gardés simples ici, exhaustifs en STORY-004.

### User Flow (Developer Experience + BDUI runtime)

1. Backend renvoie un JSON `screen-config` avec un composant `{"type": "KPICard", "props": {"label": "CA du jour", "value": "47 500", "unit": "FCFA", "delta": "+12% vs hier", "delta_positive": true, "status": "nominal"}}`.
2. `BDUIEngine` (STORY-004 du moteur, hors EPIC-001) résout `type: "KPICard"` via `ComponentRegistry` → builder de cette story.
3. Le builder appelle `KPICard.fromJson(props)` → retourne un widget `KPICard(...)`.
4. Le widget rend la valeur en Roboto Mono (parce que `value` est numérique temps réel), le label en Inter 14sp, le delta vert si `delta_positive: true`, applique le fond `bgCard` lu depuis `Theme.of(context).colorScheme.surface`.
5. Si `status: "critical"` → fond `danger-50`, bordure gauche `danger-500`, valeur en `danger-500` (lu depuis `ScalarioColorsExtension.critical`).
6. Si la donnée n'arrive pas (data source en loading) → BDUIEngine passe `loadingState: true` au composant → skeleton shimmer rendu.
7. Dev qui veut visualiser un KPICard isolé : ouvre `lib/components/data_display/_kpi_card_showcase.dart` (STORY-004) → toutes les variantes affichées avec hot reload.

---

## Acceptance Criteria

### KPICard

- [ ] AC-01 — `KPICard({required String label, required String value, String? unit, String? delta, bool deltaPositive = true, KpiStatus status = KpiStatus.nominal, VoidCallback? onTap})` rend la card avec layout fidèle au sketch ASCII de `components/02-data-display.md` (label haut, value gros, delta bas).
- [ ] AC-02 — `value` rendu en `ScalarioTypography.fontKpiValue` (Roboto Mono, taille `display`/28sp). `label` en `ScalarioTypography.fontKpiLabel`. `delta` en `caption`.
- [ ] AC-03 — Couleurs selon `status` :
  - `nominal` : fond `colorScheme.surface`, valeur `textPrimary`.
  - `warning` : fond `warning-50`, bordure gauche 3px `warning-500`, valeur `warning-700`.
  - `critical` : fond `danger-50`, bordure gauche 3px `danger-500`, valeur `danger-500`.
- [ ] AC-04 — Si `onTap != null` : chevron `›` discret bas-droite (icône `ScalarioIcons.chevronRight` taille `xs` couleur `textDisabled`), wrapping `InkWell` avec ripple tokens.
- [ ] AC-05 — `delta` couleur : `success-500` si `deltaPositive: true`, `danger-500` si `false`. Format inchangé (string passé tel quel — le formatter est ailleurs).
- [ ] AC-06 — `KPICard.loading()` factory : skeleton avec `Shimmer` Flutter natif sur les zones value + delta — label visible mais grisé.
- [ ] AC-07 — `KPICard.empty(String label)` : valeur "—", delta absent, fond `neutral-50`, `textDisabled`.
- [ ] AC-08 — `KPICard.error({required String label, String? message})` : icône `ScalarioIcons.error` + message court (truncated 2 lignes), fond `danger-50`.

### DataTable (Web Admin)

- [ ] AC-09 — `ScalarioDataTable<T>({required List<DataColumnConfig> columns, required List<T> rows, ValueChanged<T>? onRowTap, String? defaultSortKey, bool defaultSortAsc = true, T Function(Map<String,dynamic>)? rowFromJson})` — utilise `DataTable` Material 3 sous le capot, **pas un grid custom**.
- [ ] AC-10 — Tri par colonne : clic en-tête toggle `↑↓`, indicateur visuel via `IconData(ScalarioIcons.arrowUp/Down)`, état tri rendu depuis `WidgetStateProperty`.
- [ ] AC-11 — Hover ligne : bg `colorScheme.surfaceContainerHighest` (= `primary-50` light / `primary-900` dark) — vérifié sur Web seulement (mobile = no-op).
- [ ] AC-12 — En-têtes : `ScalarioTypography.captionMedium` (12sp 500) couleur `textSecondary` ; lignes : `ScalarioTypography.body` (14sp 400) `textPrimary`. Cellules numériques (colonne avec `align: right`) en Roboto Mono.
- [ ] AC-13 — État vide : `ScalarioDataTable.empty(String message)` rend une zone vide avec illustration + message centré (`ScalarioIcons.inbox` + texte `body` `textSecondary`).
- [ ] AC-14 — État loading : 5 lignes shimmer ; état erreur : icône `error` + message + CTA "Réessayer" (callback optionnel).

### AlertBanner

- [ ] AC-15 — `AlertBanner({required AlertType type, required String message, String? actionLabel, VoidCallback? onAction, int? autoDismissMs})` — `type` enum {`critical`, `warning`, `success`, `info`}.
- [ ] AC-16 — Couleurs strictement conformes à `components/01-feedback.md` :
  - `critical` : bg `danger-100`, texte `danger-700`, bordure gauche `danger-500`, icône `ScalarioIcons.alert`.
  - `warning` : bg `warning-100`, texte `warning-700`, bordure gauche `warning-500`, icône `ScalarioIcons.warning`.
  - `success` : bg `success-100`, texte `success-700`, bordure gauche `success-500`, icône `ScalarioIcons.check`.
  - `info` : bg `info-100`, texte `info-500`, bordure gauche `info-500`, icône `ScalarioIcons.info`.
- [ ] AC-17 — `autoDismissMs != null` : animation slide-up après le délai (sauf si `type == critical` — critical jamais auto-dismiss, conforme spec).
- [ ] AC-18 — Swipe horizontal pour dismiss (sauf `critical`) — utilise `Dismissible` Flutter.
- [ ] AC-19 — `actionLabel` rendu comme `TextButton` (variant `ghost`) à droite du message ; `onAction` callback.

### ScalarioFAB

- [ ] AC-20 — `ScalarioFAB({required IconData icon, String? label, VoidCallback? onPressed, bool loading = false})` — wrappe `FloatingActionButton` Material 3 ou `FloatingActionButton.extended` si `label != null`.
- [ ] AC-21 — `loading: true` : remplace l'icône par `CircularProgressIndicator` 20px couleur `onPrimary`, `onPressed` ignoré pendant loading.
- [ ] AC-22 — `onPressed: null` → état disabled, opacité 0.5, pas de ripple.
- [ ] AC-23 — Position : composant **ne se positionne pas lui-même** — c'est au `Scaffold(floatingActionButton: ...)` du parent (LayoutResolver) de le placer. Le widget reste positionnement-agnostique.

### ScalarioListTile

- [ ] AC-24 — `ScalarioListTile({Widget? leading, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap, bool enabled = true, ListTileStatus? status})` — wrappe `ListTile` Material 3.
- [ ] AC-25 — Typo : `title` en `bodyMedium` (14sp 500) `textPrimary` ; `subtitle` en `caption` (12sp 400) `textSecondary`.
- [ ] AC-26 — Bordure gauche colorée si `status` fourni (3px) — utilisé par MouvementItem/StockListItem-like (`success`, `warning`, `danger`, `primary`).
- [ ] AC-27 — `enabled: false` → opacité 0.5, pas de ripple, `textDisabled` couleurs.
- [ ] AC-28 — `ScalarioListTile.loading()` : 3 zones shimmer (avatar leading + 2 lignes title/subtitle).
- [ ] AC-29 — `ScalarioListTile.empty(String message)` : variante centrée avec icône `inbox` + message.

### FormSection

- [ ] AC-30 — `FormSection({required String title, String? hint, List<FormFieldError>? errors, required List<Widget> children, bool loading = false})` — rend un titre de section + hint optionnel + colonne de champs.
- [ ] AC-31 — Titre : `ScalarioTypography.fontSectionTitle` (`overline` 11sp 500 uppercase `textSecondary`).
- [ ] AC-32 — Padding intérieur : `space4` horizontal, `space3` entre champs (gap), `space5` après le titre.
- [ ] AC-33 — `errors` non-null → bandeau d'erreur compact en haut de la section (`AlertBanner` inline `warning`) listant les erreurs de validation des champs enfants.
- [ ] AC-34 — `loading: true` → wrappe les enfants dans `IgnorePointer` + opacité 0.5 (champs disabled visuellement, callbacks ignorés).

### ChartBar

- [ ] AC-35 — `ChartBar({required List<ChartDataPoint> data, required String title, String? unit, String? period, ValueChanged<ChartDataPoint>? onTap})` — bar chart vertical, layout conforme sketch (ligne 215-222 de `02-data-display.md`).
- [ ] AC-36 — Implémentation : `fl_chart` package (`BarChart` widget) avec configuration depuis tokens — couleurs barres `primary-500`, axes `neutral-300`, labels `caption` `textSecondary`.
- [ ] AC-37 — Tap sur barre → `onTap?.call(dataPoint)` ; barres avec hover sur Web (couleur `primary-700`).
- [ ] AC-38 — État vide : `data.isEmpty` → message centré "Pas de données pour cette période" + icône `chart` couleur `textDisabled`.
- [ ] AC-39 — État loading : 5 barres shimmer hauteur aléatoire ; état erreur : message + retry CTA.

### Hygiène & Tests transverses

- [ ] AC-40 — **Aucun** widget de cette story n'a une couleur hardcodée — `flutter analyze` + script anti-hardcode (STORY-001) verts sur `lib/components/`.
- [ ] AC-41 — Aucun `if` métier dans les widgets (le `if status == critical` est OK car c'est un mapping enum→couleur, pas de la logique métier). Vérifié manuellement en code review.
- [ ] AC-42 — Tests widget `test/components/` :
  - 7 fichiers de test, un par composant.
  - Chaque test : pumpe le widget dans `MaterialApp(theme: ScalarioTheme.light())`, vérifie rendu de chaque état (au moins 4 états par composant).
  - Smoke `fromJson` : passer un map valide → widget non-null ; map malformé → fallback (pas de crash).
- [ ] AC-43 — Couverture ≥ 80% sur `lib/components/data_display/`, `lib/components/feedback/`, `lib/components/actions/`, `lib/components/lists/`, `lib/components/inputs/`.
- [ ] AC-44 — Chaque composant a une docstring de classe avec : rôle, spec source (lien `components/0X-*.md` + ligne), liste des états supportés.

---

## Technical Notes

### Composants concernés

- **Nouveau layer :** `apps/flutter/lib/components/` — organisé par groupe DS.
- **Lit depuis :** STORY-001 (tokens), STORY-002 (`Theme.of(context)`).
- **Consommé par :** STORY-005 (`ComponentRegistry`), STORY-004 (showcases), tous les écrans BDUI à partir de Sprint 2.

### Structure de fichiers (cible)

```
apps/flutter/lib/components/
├── data_display/
│   ├── kpi_card.dart                # KPICard + KpiStatus enum + KPICard.loading/.empty/.error
│   ├── data_table.dart              # ScalarioDataTable<T> + DataColumnConfig
│   └── chart_bar.dart               # ChartBar + ChartDataPoint
├── feedback/
│   └── alert_banner.dart            # AlertBanner + AlertType enum
├── actions/
│   └── scalario_fab.dart            # ScalarioFAB
├── lists/
│   └── scalario_list_tile.dart      # ScalarioListTile + ListTileStatus enum
├── inputs/
│   └── form_section.dart            # FormSection + FormFieldError
└── components.dart                  # barrel export

apps/flutter/test/components/
├── data_display/
│   ├── kpi_card_test.dart
│   ├── data_table_test.dart
│   └── chart_bar_test.dart
├── feedback/
│   └── alert_banner_test.dart
├── actions/
│   └── scalario_fab_test.dart
├── lists/
│   └── scalario_list_tile_test.dart
└── inputs/
    └── form_section_test.dart
```

### Pattern Dart recommandé

Stateless, immutable, factory `.fromJson` pour intégration BDUI :

```dart
class KPICard extends StatelessWidget {
  const KPICard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaPositive = true,
    this.status = KpiStatus.nominal,
    this.onTap,
  });

  factory KPICard.fromJson(Map<String, dynamic> json) => KPICard(
        label: json['label'] as String,
        value: json['value'] as String,
        unit: json['unit'] as String?,
        delta: json['delta'] as String?,
        deltaPositive: json['delta_positive'] as bool? ?? true,
        status: KpiStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'nominal'),
          orElse: () => KpiStatus.nominal,
        ),
      );

  factory KPICard.loading({required String label}) =>
      _LoadingKPICard(label: label) as KPICard; // ou widget dédié

  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final bool deltaPositive;
  final KpiStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<ScalarioColorsExtension>()!;
    final palette = _paletteFor(status, ext, theme.colorScheme);

    final card = Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: palette.borderLeft != null
            ? Border(left: BorderSide(color: palette.borderLeft!, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ScalarioTypography.fontKpiLabel),
          const SizedBox(height: ScalarioSpacing.space2),
          Text(value, style: ScalarioTypography.fontKpiValue.copyWith(color: palette.value)),
          if (unit != null) Text(unit!, style: ScalarioTypography.caption),
          if (delta != null) ...[
            const SizedBox(height: ScalarioSpacing.space1),
            Text(
              delta!,
              style: ScalarioTypography.caption.copyWith(
                color: deltaPositive ? ext.synced : ScalarioColors.danger500,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
      child: Stack(
        children: [
          card,
          Positioned(
            right: ScalarioSpacing.space3,
            bottom: ScalarioSpacing.space3,
            child: Icon(ScalarioIcons.chevronRight,
                size: ScalarioIconSize.xs,
                color: ScalarioColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

enum KpiStatus { nominal, warning, critical }
```

`ComponentConfig` placeholder (STORY-023 le typera fortement) :

```dart
typedef ComponentConfig = Map<String, dynamic>;

abstract class BdUiComponent {
  static Widget build(String type, ComponentConfig config) {
    // Stub — STORY-005 implémente le registry réel.
    // Ici on documente juste le contrat : chaque widget de STORY-003
    // expose une factory .fromJson(config['props'] as Map).
    throw UnimplementedError('See STORY-005');
  }
}
```

### Spec source — résolution des conflits

**Conflit 1 — sprint plan dit "FAB" générique, spec DS ne le mentionne pas explicitement.** Le sprint plan AC `FAB (Floating Action Button) : icône + label + position bas-droite configurable`. La spec DS `components/05-actions.md` couvre `ActionButton` + `ConfirmationDialog` mais pas un FAB dédié. **Décision :** créer `ScalarioFAB` qui wrappe `FloatingActionButton` Material 3 + style depuis tokens. La position "bas droite configurable" est **fausse spec** — c'est le `Scaffold` qui place le FAB (Flutter natif), pas le widget. AC-23 reflète ça. PRD à clarifier en post-merge.

**Conflit 2 — DataTable mobile vs web.** La spec DS dit explicitement « exclusivement sur Flutter Web (surfaces Admin). Non utilisé sur mobile. » (`components/02-data-display.md:531`). Cette story implémente le composant sans le verrouiller à une plateforme — c'est le **LayoutResolver** (FR-003) ou le tenant config qui décide quel layout l'utilise. Le widget se rend correctement sur mobile (fallback : scrollable horizontal), mais ce n'est pas son cas d'usage prévu. Documenter dans la docstring.

**Conflit 3 — ListTile : composant Material 3 vs composant DS dédié.** Material 3 a déjà `ListTile`. La spec DS a `EmployeeList`/`SupplierList`/etc. — chacune est une **liste** d'items, pas un item-template. **Décision :** créer `ScalarioListTile` qui wrappe `ListTile` M3 + ajoute la border-left colorée + la factory loading/empty. Les listes spécialisées (EmployeeList, etc.) sont des stories ultérieures qui utilisent `ScalarioListTile` comme item template. C'est cohérent avec le pattern Sprint 1 (composants core, pas écrans).

**Conflit 4 — FormSection : sprint plan dit "champs groupés", spec dit `FormWidget` + `ExpandableSection`.** Le sprint plan parle de "FormSection" qui n'existe pas tel quel dans la spec. **Décision :** implémenter `FormSection` comme un container léger (titre + hint + enfants) — l'`ExpandableSection` (collapsable) est une variante future, hors scope ici. Les champs eux-mêmes (`TextInput`, `NumberInput`, etc. de `components/03-inputs.md`) sont **hors scope** de cette story — créés en cascade par les stories d'écrans qui en ont besoin.

**Conflit 5 — `ChartBar` vs `ChartWidget`.** La spec DS dit `ChartWidget` avec `type: line | bar` (`02-data-display.md:182`). Le sprint plan dit "ChartBar" tout court. **Décision :** implémenter `ChartBar` (bar chart uniquement) maintenant. `ChartLine` viendra dans une story ultérieure quand un écran l'exigera. Documenter que `ChartBar` n'est **pas** la version finale de `ChartWidget` — c'est sa première variante. Le type JSON BDUI sera `"ChartBar"` (pas `"ChartWidget"`).

### Edge cases

- **Composants `null`-safe.** Un JSON BDUI peut arriver avec props manquantes. Chaque `.fromJson` doit avoir des défauts ou jeter une exception **explicite et descriptive** (pas un `NoSuchMethodError`). Pattern : `as String? ?? throw FormatException('Missing required: label')`.
- **Roboto Mono pour les valeurs numériques.** `KPICard.value`, `DataTable` colonnes numériques, `ChartBar` axes Y → Roboto Mono. Identifier par convention dans le code (`ScalarioTypography.fontKpiValue`, `ScalarioTypography.fontMonoSm`). Si une colonne `DataTable` doit être mono, le `DataColumnConfig.align: right` la rend mono automatiquement.
- **Espace insécable FCFA.** Le formatter de nombres (`12 500 FCFA` avec U+202F) **n'est pas** dans cette story — les widgets reçoivent des strings déjà formatés (`value: "47 500"`). Le formatter sera un `lib/core/format/currency_formatter.dart` créé à la première story qui en a besoin.
- **Skeleton shimmer.** Utiliser le package `shimmer: ^3.x` ou implémenter un `Container` animé maison avec `AnimatedContainer` + `LinearGradient`. Décision : `shimmer` ok pour Sprint 1 (1 dep externe légère) — à ré-évaluer si bundle size pose problème.
- **`fl_chart` pour ChartBar.** Package éprouvé (10k+ stars), maintenu, supporte mobile + web. Configuration depuis tokens : `BarChartData(barGroups: ..., titlesData: ...)` avec couleurs lues de `Theme.of`. Risque : `fl_chart` impose son propre style — vérifier qu'on peut tout overrider depuis le thème.
- **AlertBanner critical persistant.** AC-17 dit "critical jamais auto-dismiss". Implémenter par garde : `if (type != AlertType.critical && autoDismissMs != null)` avant de planifier le dismiss. Test dédié pour vérifier qu'un `AlertBanner.critical` avec `autoDismissMs: 2000` reste visible après 3s.
- **DataTable tri stable.** Le tri Material 3 par défaut n'est pas stable. Pour des colonnes égales (ex: deux MRR à 40 000), garder l'ordre d'origine — utiliser `List.sort` avec un index de fallback.
- **FormSection erreurs.** `errors: List<FormFieldError>` est passé depuis le parent. Le widget ne valide rien lui-même — il **affiche** les erreurs reçues. La validation vit ailleurs (STORY-023 JSON Schema field validation).

### Sécurité

- **XSS dans les strings JSON.** Toutes les valeurs string viennent du JSON BDUI (donc du backend authentifié). Flutter `Text(...)` n'interprète pas HTML — pas de risque XSS natif. **Mais** : ne **jamais** utiliser `RichText` avec parsing HTML/markdown sur un input non-trusted. Cette story n'en utilise pas.
- **Callbacks `onTap` / `onAction`.** Les callbacks sont fournis par le parent (BDUIEngine ou un container test). Aucun callback n'est résolu depuis le JSON dans cette story (les `route`/`action` strings sont gérés par STORY-005+). Pas de risque d'injection.
- **`TextEditingController` dans FormSection.** Pas de `TextEditingController` créé ici — les champs (TextInput, NumberInput) sont enfants passés par le parent. Si on en crée plus tard, attention au `dispose()` (memory leak classique Flutter).

---

## Dependencies

**Prérequis :**

- **STORY-001** (Design Tokens) — strict.
- **STORY-002** (ThemeData + ThemeExtensions) — strict (les widgets lisent `Theme.of(context).extension<ScalarioColorsExtension>()`).

**Stories bloquées par celle-ci :**

- STORY-004 (Showcase + Widget Preview) — direct (les showcases instancient ces composants).
- STORY-005 (`ComponentRegistry`) — direct (le registry enregistre ces 7 builders).
- STORY-026 (Workflow Inventaire) — utilise `FormSection`.
- STORY-019/020/021 (POS, Vente, etc.) — utilisent `KPICard`, `AlertBanner`, `FAB`, `ListTile`.
- Plus généralement, **tous** les écrans Phase 1 MVP (S01–S30, A01–A05).

**Externes :**

- Package `fl_chart: ^0.68.x` (bar chart).
- Package `shimmer: ^3.0.x` (skeleton loading).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-003-bdui-components`.
- [ ] `flutter analyze` passe sans warning sur `lib/components/`.
- [ ] `flutter test apps/flutter/test/components/` vert avec ≥ 80% couverture.
- [ ] Aucun `Color(0xFF…)` ni magic spacing dans `lib/components/` (script anti-hardcode vert).
- [ ] Chaque composant a sa docstring + lien spec DS + liste des états.
- [ ] Chaque composant a une `factory.fromJson(Map<String,dynamic>)` testée.
- [ ] Tous les états (Normal/Warning/Danger/Loading/Vide/Erreur) implémentés ET testés pour les 7 composants — checklist annotée dans la PR.
- [ ] Code review passé (`/codex review` recommandé — challenge sur les edge cases).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-003 status `completed`, completed_points sprint 1 += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `KPICard` (7 états + factory + onTap + chevron) | 0.75 | Le plus utilisé — soigner. |
| `ScalarioDataTable<T>` (tri + hover web + 6 états + génériques) | 1.0 | Le plus complexe — `WidgetStateProperty`, `DataColumn`, tri stable. |
| `AlertBanner` (4 types + auto-dismiss + swipe + action) | 0.75 | `Dismissible` + `Timer` + `AnimatedContainer`. |
| `ScalarioFAB` (extended + loading + disabled) | 0.25 | Wrapper léger M3. |
| `ScalarioListTile` (status border-left + 6 états) | 0.5 | Wrapper M3 + variantes. |
| `FormSection` (titre + erreurs inline + loading wrap) | 0.5 | Container simple + AlertBanner intégré. |
| `ChartBar` avec `fl_chart` (4 états + tap + theme override) | 1.0 | `fl_chart` n'aime pas être themé — patience requise. |
| Tests widget (7 fichiers, 4-6 tests chacun) + couverture 80% | 0.25 | Fondamentalement répétitif — pumpWidget + finder. |
| **Total** | **5** | Fibonacci 5 — le plus gros de Sprint 1. |

**Rationale :** 7 composants × tous leurs états × tests = volume mécanique. Pas de difficulté algorithmique, mais **pas de raccourci possible** : l'`AlertBanner.critical` qui s'auto-dismiss accidentellement à cause d'un test cassé = bug critique en prod (l'utilisateur rate l'alerte stock). Chaque AC est un bug évité.

---

## Notes additionnelles

- **Convention `Scalario` prefix.** `ScalarioDataTable`, `ScalarioFAB`, `ScalarioListTile` ont le préfixe parce qu'ils **shadow** des classes Material 3 du même nom. `KPICard`, `AlertBanner`, `FormSection`, `ChartBar` n'ont pas le préfixe parce qu'ils n'entrent pas en collision. Cohérent avec les conventions Flutter idiomatiques (préfixe = wrapper, pas de préfixe = nouveau widget).
- **Composant `ConfirmationDialog`** (spec DS `components/05-actions.md:90`) **pas dans cette story** — il sera créé par la première story qui l'utilise (probablement STORY-019 POS — annulation vente). Argument : l'inclure ici sans cas d'usage = sur-engineering.
- **Showcases** (`_<feature>_showcase.dart`) — STORY-004. Cette story **ne crée pas** les showcases mais structure les composants pour qu'ils soient *facilement* showcasables : factories `.loading()`/`.empty()`/`.error()` séparées, props nommées, pas d'état caché.
- **Logo Scalario** : pas concerné. Si un composant futur a besoin du logo (ex: SplashScreen), respecter monogramme `Sc` vs wordmark `S + CALARIO`.
- **i18n** : tous les strings affichés dans cette story (placeholders empty/error) sont **hardcodés en français** pour Sprint 1. STORY-042 wrappera tout dans `AppLocalizations.of(context)`. Documenter en TODO dans chaque widget.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-10 : Completed (Carlos / Developer via `/bmad:dev-story`)

**Actual Effort :** 5 points (matched estimate)

**Implementation Notes :**
- 7 widgets implémentés conformément aux ACs : `KPICard`, `ScalarioDataTable<T>`, `AlertBanner`, `ScalarioFAB`, `ScalarioListTile`, `FormSection`, `ChartBar`.
- Chaque widget expose `.fromJson(Map<String,dynamic>)` + factories `loading()/empty()/error()` selon les états applicables.
- Shimmer maison (`lib/components/_internal/shimmer.dart`) — 0 dépendance externe ajoutée. À ré-évaluer si volume widget loading explose.
- ChartBar implémenté en `CustomPaint` direct — `fl_chart` non ajouté pour Sprint 1 (pas de tooltips/animations exigés). Le passage à `fl_chart` reste possible si on a besoin de stacks/lines plus tard.
- AlertBanner action : `GestureDetector + Padding + Text` au lieu de `TextButton` — `TextButton` dans un Row déclenche l'assertion "BoxConstraints forces an infinite width" pendant la mesure intrinsèque du Flex (incompatibilité connue Flutter 3.41 entre `_RenderInputPadding` et le passe Flex initial). Visuel "ghost button" préservé. Documenté inline.
- AlertBanner swipe : `GestureDetector.onHorizontalDragEnd` au lieu de `Dismissible` — même raison de contraintes. Behavior fonctionnel équivalent (swipe vélocité > 200 → dismiss).
- Bug du checker `scripts/check_no_hardcoded_tokens.dart` corrigé en cours de route : la regex EdgeInsets matchait les digits de `ScalarioSpacing.space4`. Ajout d'un negative lookbehind `(?<!\w)` pour ne flag que les littéraux nus.
- 10 nouveaux alias dans `tokens/icons.dart` (`chevronRight`, `arrowUp`, `arrowDown`, `inbox`, `chart`, `error`, `alert`, `warning`, `check`, `info`).
- Coverage `lib/components/` = **93.4%** (cible AC-43 ≥ 80%) — 568/608 lignes couvertes.
- 55 tests widget verts ; suite globale 209/209.
- `flutter analyze` propre, anti-hardcode propre.

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
