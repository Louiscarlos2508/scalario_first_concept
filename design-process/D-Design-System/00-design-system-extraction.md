# Design System — Scalario Retail Phase 1

> Extraction des tokens et composants depuis le code Flutter existant pour servir de base au Design System Figma.

**Document:** Design System Extraction
**Created:** 2026-04-06
**Status:** READY FOR FIGMA
**Source:** `apps/frontend/lib/core/theme/` + audit composants

---

## Contexte

L'app Scalario Phase 1 a été codée sans maquettes. Ce document extrait toutes les fondations visuelles déjà présentes dans le code Flutter pour les répliquer fidèlement en Figma. Ensuite, les maquettes Figma serviront de référence pour la ré-implémentation des écrans.

**Source de vérité actuelle :** `apps/frontend/lib/core/theme/app_theme.dart` + `app_breakpoints.dart` + `sheet_style.dart`.

---

## 1. Couleurs (9 tokens)

Règle 60-30-10 : background dominant, surface secondaire, primary accent.

| Token | HEX | Usage |
|---|---|---|
| `color/primary` | `#1565C0` | CTA, liens, états actifs — bleu confiance |
| `color/success` | `#2E7D32` | Validé, sync OK, écart positif |
| `color/error` | `#C62828` | Erreurs, pertes, écart négatif, destructif |
| `color/warning` | `#F9A825` | En attente, alertes, sync pending |
| `color/background` | `#F5F5F5` | Fond app (60% dominant) |
| `color/surface` | `#FFFFFF` | Cards, modales, inputs |
| `color/text-primary` | `#212121` | Texte principal |
| `color/text-secondary` | `#757575` | Labels, secondaire (WCAG AA sur blanc) |
| `color/border` | `#E0E0E0` | Séparations subtiles |

### Palette sheet (modales / bottom sheets)

Distincte du thème principal pour les dialogues, basée sur Slate :

| Token | HEX | Usage |
|---|---|---|
| `sheet/bg-input` | `#F8FAFC` | Fond input dans sheet |
| `sheet/border` | `#E2E8F0` | Bordure input/divider sheet |
| `sheet/focus` | `#1A73E8` | Focus input sheet |

**Mode sombre :** non implémenté Phase 1 (light only). Logo wordmark a une variante adaptée au fond foncé de l'AppBar (`#0F172A`).

**ColorScheme Material 3** généré depuis seed `#1565C0`.

---

## 2. Typographie (8 styles)

Famille **Roboto** (system Flutter) + **Roboto Mono** pour les nombres/prix/quantités.

| Style | Taille | Weight | Line height | Usage |
|---|---|---|---|---|
| `display/medium` | 22 | Bold | 1.2 | Titres principaux page |
| `headline/large` | 20 | Bold (mono) | 1.2 | Prix gros format |
| `headline/medium` | 18 | Bold (mono) | 1.2 | Quantités gros format |
| `title/large` | 18 | SemiBold (w600) | 1.2 | Titres de section |
| `title/medium` | 16 | SemiBold (w600) | 1.2 | Titres de carte |
| `body/medium` | 14 | Regular | 1.4 | Corps de texte |
| `body/small` | 12 | Regular | 1.4 | Texte secondaire (color-secondary) |
| `label/small` | 11 | Medium (w500) | 1.4 | Labels MAJUSCULES, spacing 0.5 |

---

## 3. Spacing (6 tokens)

Échelle observée dans les widgets :

| Token | px | Usage typique |
|---|---|---|
| `space/4` | 4 | Micro-spacing (icônes adjacentes) |
| `space/8` | 8 | Items menu, gaps serrés |
| `space/12` | 12 | Cards, rows |
| `space/16` | 16 | **Padding standard sections** (DOMINANT) |
| `space/24` | 24 | Séparation sections non liées |
| `space/32` | 32 | Espacements principaux |

---

## 4. Border radius (4 tokens)

| Token | px | Usage |
|---|---|---|
| `radius/8` | 8 | Inputs, small containers, icon backgrounds |
| `radius/10` | 10 | Boutons sheet, dialogs |
| `radius/12` | 12 | **Cards, containers standard** (DOMINANT) |
| `radius/16` | 16 | Sheet titles |

---

## 5. Breakpoints responsive

Source : `lib/core/theme/app_breakpoints.dart`

| Breakpoint | Range | Layout |
|---|---|---|
| `compact` | < 600px | Mobile : colonne simple, bottom nav, modales plein écran |
| `medium` | 600 – 1024px | Tablette : split view, navigation rail |
| `expanded` | > 1024px | Desktop : layout 3 panneaux, breadcrumb actif |

---

## 6. Élévation

Design **flat** — Material 3 avec elevation 0 sur la majorité des composants. Pas d'ombres marquées.

---

## 7. Boutons (Material 3)

- **ElevatedButton** : min 48×48dp
- **FilledButton (CTA primaires)** : min 56×88dp (règle Fitts pour touch retail)
- **Radius** : 10px (sheet) / Material default (app)
- **Elevation** : 0

---

## 8. Composants atomiques codés (à répliquer en Figma)

### Composants core

| Composant | Chemin | Description |
|---|---|---|
| **ScalarioAppBar** | `lib/core/widgets/scalario_app_bar.dart` | Fond `#0F172A`, leadingWidth 56, hauteur 56, monogramme + titre + bell (owner/manager) + actions |
| **ProductAutocomplete** | `lib/core/widgets/product_autocomplete.dart` | Recherche produit + dropdown suggestions inline |

### Composants métier

| Composant | Chemin | Description |
|---|---|---|
| **KpiCard** (`_KpiCard`) | `lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart` | Icon + valeur monospace + label (CA, Ventes, Bénéfice...) |
| **StockStatCard** | `lib/features/shared/inventory/presentation/widgets/stock_summary_row.dart` | Icône + nombre + label, animée au tap |
| **FreshnessChip** | `lib/features/shared/catalog/presentation/widgets/freshness_chip.dart` | Badge color-coded vert/orange/rouge fraîcheur |
| **AlertBanner** (`_AlertBanner`) | `lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart` | Bannière tapable, fond couleur thème alpha 0.08 |
| **ClientOrderCard** | `lib/features/shared/client_orders/presentation/widgets/client_order_card.dart` | Status badge + montant + actions (Valider/Préparer/Livrer/Annuler) |
| **PlanInfoCard** | `lib/features/shared/billing/presentation/widgets/plan_info_card.dart` | Badge couleur + prix/mois + nb users + chips modules |
| **StockActionChipsRow** | `lib/features/shared/inventory/presentation/widgets/action_chips_row.dart` | Row d'ActionChip horizontales (Réception, Envoi, Perte, Comptage, Fraîcheur, Ajustement, Réappro) |

### Composants sheet (modales / dialogs)

Source : `lib/core/theme/sheet_style.dart`

| Composant | Description |
|---|---|
| **SheetDialogHeader** | Header dialog : icône carré 36×36 + titre + subtitle |
| **SheetTitleRow** | Titre row pour bottom sheets : icône + titre + trailing widget |
| **SheetActionRow** | Paire boutons : Annuler (outline) + Confirmer (filled) full-width |
| **SheetDivider** | Divider 1px couleur `#E2E8F0` |
| **SheetSectionLabel** | Label MAJUSCULE 11sp w600 spacing 0.5 |

---

## 9. Composants à CRÉER (manquants dans le code)

À designer from scratch en Figma :

- **Breadcrumb** (desktop nav) — pattern de navigation principal Scalario, surtout desktop ⚠️ priorité
- **Empty state** générique (icône + message + action) — docstring existe pas codé
- **Skeleton loader** (shimmer 300ms, pas spinner)
- **Modal/Dialog** générique
- **DataTable** (rapports desktop dense)
- **Pagination**
- **Toast/Snackbar** custom

---

## 10. Patterns de layout

| Pattern | Source | Description |
|---|---|---|
| AppBar Scalaire | `scalario_app_bar.dart` | Fond `#0F172A`, monogramme, bell auto pour roles owner/manager |
| Bottom Sheet modal | Utilisé POS, inventory | `isScrollControlled: true`, `heightFactor: 0.90–0.95`, drag handle, SafeArea |
| LayoutBuilder responsive | `kpi_card_grid.dart` | KPI : 1×4 row tablet / 2×2 grid mobile |
| Alert Banners (Zone B) | `KpiCardGrid` | Alertes conditionnelles (count > 0), couleur thème alpha 0.08 |

**Patterns manquants :** breadcrumb desktop, navigation rail, drawer mobile.

---

## 11. Iconographie

**Pack :** Material Icons (Flutter standard `Icons.*`).

Pas d'icônes custom SVG. Material Icons suffisant pour Phase 1.

**Icônes clés observées :**
- Commerce : `shopping_cart`, `receipt_long`, `attach_money`, `money_off`
- Stock : `inventory_2_outlined`, `warning_amber_rounded`, `eco_outlined`
- Tendances : `trending_up`, `trending_down`
- Navigation : `chevron_right`, `close`, `more_vert`, `search`
- Logo : `AppLogos.monogram()` (SVG custom)

**Pour Figma :** importer le pack **Material Symbols** (Google).

---

## 12. Assets

Dossier : `apps/frontend/assets/images/`

| Asset | Type | Fichier |
|---|---|---|
| Wordmark Dark | SVG | `scalario-wordmark-dark.svg` |
| Wordmark Light | SVG | `scalario-wordmark-light.svg` |
| Monogram Dark | SVG | `scalario-monogram-dark.svg` |
| Monogram Light | SVG | `scalario-monogram-light.svg` |

**Helpers Flutter :** `AppLogos.wordmark(context, maxWidth: 140)` et `AppLogos.monogram(context, size: 24)` adaptatifs au thème.

**Règles d'usage logo** (mémoire) :
- Monogramme = `Sc` (S arcs + c arc), jamais S seul
- Wordmark = `S arcs + CALARIO`
- Jamais les deux ensemble

---

## 13. Plan de construction Figma

### Étape 1 — Fondations (1-2h)
1. Créer fichier Figma "Scalario Design System"
2. Créer les **9 color styles** (Variables Figma)
3. Créer les **8 text styles** (Roboto + Roboto Mono)
4. Créer les **spacing/radius/breakpoints** comme variables
5. Importer les **4 SVG logos** comme components

### Étape 2 — Composants atomiques (3-4h)
6. Button (Filled / Outlined / Text — 3 tailles + states)
7. TextField (2 palettes : app + sheet)
8. Chip / ActionChip / Badge
9. Avatar (XS/S/M/L)
10. Card / Divider
11. AppBar Scalario (variante mobile + desktop)

### Étape 3 — Composants métier (3-4h)
12. KpiCard
13. StockStatCard
14. FreshnessChip
15. AlertBanner
16. ClientOrderCard
17. PlanInfoCard
18. SheetHeader / SheetActionRow / SheetSectionLabel
19. BottomSheet template

### Étape 4 — Patterns navigation (2h)
20. **Breadcrumb desktop** (à designer from scratch)
21. Bottom nav (mobile)
22. Navigation rail (tablet)
23. Page templates : mobile / tablet / desktop avec breakpoints

### Étape 5 — Maquettes (gros morceau)
24. Maquetter les **14 page specs delta** depuis `design-process/C-UX-Scenarios/`
25. Audit visuel des **32 écrans "garder"** : vérifier qu'ils respectent le DS

---

## 14. Lacunes identifiées

À combler dans la phase Figma ou à compléter dans le code après :

- ❌ Pas de système de spacing en code (valeurs hardcodées dans les widgets)
- ❌ Pas de breadcrumb component
- ❌ Pas d'empty state codé (juste docstring)
- ❌ Pas de skeleton loader codé
- ❌ Pas de mode sombre
- ❌ Pas de pagination component
- ⚠️ Deux palettes en parallèle (app + sheet) — à harmoniser ou maintenir explicitement

---

## Documents liés

- **[Trigger Map](../B-Trigger-Map/00-trigger-map.md)** — Personas et drivers
- **[UX Scenarios](../C-UX-Scenarios/00-ux-scenarios.md)** — 10 scénarios + page specs delta
- **[PRD](../../docs/prd-scalario-retail-2026-04-06.md)** — Specs fonctionnelles
- **[Architecture](../../docs/architecture-scalario-retail-2026-04-06.md)** — Stack technique
- **Source code DS :** `apps/frontend/lib/core/theme/`

---

_Extraction réalisée le 2026-04-06 — base prête pour création Figma Design System_
