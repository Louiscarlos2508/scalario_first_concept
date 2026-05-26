# Scalario BDUI — Architecture & Specification

**Version**: 14.0 | **Date**: 2026-05-26
**Moteur**: Flutter BDUI Canvas Engine

---

## Principe

Scalario Canvas rend n'importe quel layout ERP depuis du JSON.
Zéro logique metier dans le code Flutter. Tout passe par le `ScalarioCanvasRegistry`.

```
JSON → ComponentConfig → Registry → Widget Flutter
     ↑ schema Zod/NestJS validant le contrat
```

---

## 1. Composants — 3 categories

### 1.1 Layout Containers (structure)

| Type | Role | Proprietes |
|---|---|---|
| `Scaffold` | Ecran complet | `appBar`, `body`, `bottomNav`, `fab`, `children[]` |
| `AppBar` | Barre de titre | `variant: default | large | search | transparent | minimal`, `title`, `actions[]`, `collapse_on_scroll` |
| `BottomNav` | Navigation | `items[]: { icon, label, badge }`, `currentIndex` |
| `Grid` | Grille responsive | `columns`, `gap: xs|sm|md|lg`, `responsive: { compact, medium, expanded }` |
| `Row` | Flex horizontal | `gap`, `children[]` |
| `Column` | Flex vertical | `gap`, `children[]` |
| `Slots` | Layout semantique | `slots: { banner, main, aside, bottom, fab }`, `scroll: fixed|sliver|page` |
| `Stack` | Superposition | `position: top|bottom|bottom_right|fill`, `margin`, `padding` |

### 1.2 Components (metier, codés une fois)

| Type | Role | Variantes |
|---|---|---|
| `KPICard` | Indicateur | `default`, `compact`, `hero`, `with-icon`, `with-chart` |
| `DataTable` | Tableau | `default`, `compact`, `card-list`, `timeline` |
| `ChartBar` | Graphique barres | `default`, `stacked`, `horizontal`, `mini` |
| `ChartPie` | Graphique camembert | `default`, `donut`, `mini-legend` |
| `AlertBanner` | Bandeau d'alerte | `info`, `success`, `warning`, `critical` |
| `StatsCard` | Statistique | `default`, `trend-up`, `trend-down`, `flat` |
| `Button` / `ActionButton` | Bouton | `primary` (#FFCC00), `secondary`, `ghost`, `danger`, `icon-only` |
| `FAB` | Bouton flottant | `default`, `extended`, `mini` |
| `ListTile` | Element de liste | `default`, `with-avatar`, `with-badge`, `dense` |
| `FormSection` | Formulaire | `text`, `number`, `date`, `select`, `search`, `scan` |
| `SyncStatusBar` | Statut sync | `synced`, `syncing`, `conflict`, `offline` |
| `DocumentPreview` | Apercu doc | `inline`, `card`, `fullscreen`, `thumbnail` |

### 1.3 Behaviour Wrappers

| Type | Role |
|---|---|
| `StateWrapper` | Gere les etats: `loading`, `empty`, `error`, `success` |
| `PullToRefresh` | Rafraichissement au scroll down |

---

## 2. Spacing System — Tokens semantiques

```
AUCUN pixel en dur dans le JSON.

Token  → px
───────┼─────
none   → 0
xs     → 4
sm     → 8
md     → 16
lg     → 24
xl     → 32
xxl    → 48
```

Usage: `"gap": "sm"`, `"padding": "lg"`, `"margin": "none"`

---

## 3. Typography System

```
Token       → Style
─────────────┼──────────────────────────
h1          → 28sp bold, -0.5 letter
h2          → 22sp w700
h3          → 18sp w600
body        → 14sp normal
body_bold   → 14sp bold
caption     → 12sp grey
overline    → 10sp uppercase, grey
label       → 11sp w500
kpi_value   → 28sp monospace w700
kpi_label   → 12sp w500
```

---

## 4. Responsive — 3 breakpoints

```
Breakpoint  Largeur     Config JSON
──────────  ──────────  ──────────────────
compact     < 600px     responsive.compact
medium      600-1200px  responsive.medium
expanded    > 1200px    responsive.expanded
```

Exemple:
```json
{ "layout": {
    "responsive": {
      "compact":  { "type": "slots", "aside": false },
      "medium":   { "type": "slots", "aside": { "width": 280 } },
      "expanded": { "type": "slots", "aside": { "width": 360 } }
    }
  }
}
```

---

## 5. States — Loading / Empty / Error / Success

```json
{
  "type": "DataTable",
  "source": "commandes",
  "states": {
    "loading": "skeleton",
    "empty": {
      "illustration": "empty_cart",
      "message_key": "commandes.empty",
      "action": "creer_commande"
    },
    "error": { "retry": true }
  }
}
```

---

## 6. Scroll Behavior

```
fixed  → SingleChildScrollView (dashboard)
sliver → CustomScrollView + SliverAppBar (collapse)
page   → PageView (swipe entre sections)
```

---

## 7. Theme / Colours

```json
{
  "theme": {
    "mode": "system",   // system|light|dark
    "colors": {
      "primary": "#FFCC00",     // Scalario brand yellow
      "danger": "#E74C3C",
      "success": "#27AE60",
      "warning": "#E67E22",
      "bg_page": "#F8F8FC",
      "bg_card": "#FFFFFF",
      "text_primary": "#1A1A2E"
    }
  }
}
```

---

## 8. Transitions & Navigation

```json
{
  "navigation": {
    "transition": "slide",   // slide|fade|scale|hero
    "hero_tag": "commande_$id"
  }
}
```

---

## 9. Forms — Wizard multi-step

```json
{
  "form": {
    "type": "wizard",
    "steps": [
      { "title": "Etape 1", "fields": [...] },
      { "title": "Etape 2", "fields": [...] },
      { "title": "Confirmation", "type": "summary" }
    ],
    "progress": "stepper"  // stepper|dots|progress_bar
  }
}
```

---

## 10. Sheets / Dialogs / Drawers

```json
// Declenche depuis un pipeline Scalario Flow:
{ "id": "confirmer", "registry": "canvas", "fn": "show_dialog",
  "props": { "variant": "confirm", "title": "Valider ?", "actions": ["annuler", "confirmer"] },
  "output": "user_choice" }

// BottomSheet avec snap points:
{ "registry": "canvas", "fn": "show_sheet",
  "props": { "snap_points": ["40%", "80%"], "component": "FiltresForm" } }
```

---

## 11. Gestures

```json
{
  "component": "ListTile",
  "gestures": {
    "swipe_left":  { "action": "archiver", "color": "warning" },
    "swipe_right": { "action": "valider",  "color": "success" },
    "long_press":  { "action": "selection_multiple" }
  }
}
```

---

## 12. Pagination

```json
{
  "component": "DataTable",
  "pagination": { "type": "infinite", "page_size": 20 }
}
```

---

## 13. Offline Behaviour

```json
{
  "component": "DataTable",
  "offline_behavior": {
    "show_stale_badge": true,
    "disable_actions": ["create", "delete"]
  }
}
```

---

## 14. Keyboard (Desktop)

```json
{
  "form": {
    "keyboard": {
      "submit_on_enter": true,
      "tab_order": ["ref", "client", "montant"],
      "shortcuts": { "ctrl+s": "submit", "escape": "cancel" }
    }
  }
}
```

---

## 15. Accessibility (a11y)

```json
{
  "type": "FAB",
  "icon": "add",
  "semantics_label_key": "a11y.creer_commande"
}
```

---

## 16. Print Layout

```json
{
  "print_layout": {
    "page_size": "A4",
    "orientation": "portrait",
    "hide_components": ["fab", "bottom_nav"],
    "show_components": ["print_header", "print_footer"]
  }
}
```

---

## 17. API Contract — ComponentConfig JSON Schema

```json
{
  "type": "KPICard",
  "variant": "auto",
  "id": "ca_jour",
  "props": {
    "label_key": "kpiCaJour",
    "value": 47500,
    "text_style": "kpi_value",
    "span": 1
  },
  "source": { "engine": "vault", "entity": "Sale", "aggregate": "sum", "period": "today" },
  "calc": { "fn": "format_currency", "args": ["$value", "$tenant.currency"] },
  "visible_if": { "operator": "role", "value": ["OWNER", "MANAGER"] },
  "states": {
    "loading": "skeleton",
    "empty": { "illustration": "empty_cart", "action": "creer" }
  },
  "on_tap": { "engine": "canvas", "fn": "navigate", "to": "/screens/detail" },
  "gestures": {
    "swipe_left": { "action": "archiver" }
  },
  "children": [
    { "type": "Text", "props": { "text_key": "detail.description" } }
  ]
}
```

---

## 18. Registry — Types enregistres (26)

```
Layout (8):  Scaffold, AppBar, BottomNav, Grid, Row, Column, Slots, Stack
Data (6):    KPICard, DataTable, ChartBar, ChartPie, StatsCard, DocumentPreview
Feedback (2): AlertBanner, SyncStatusBar
Actions (4): Button, FAB, ScalarioButton, ActionButton
Inputs (2):  FormSection, FormWidget
Lists (2):   MouvementItem, TicketPreview
State (1):   StateWrapper
```

---

## 19. Ce qui est HORS scope (jamais dans le JSON)

```
❌ Pixels arbitraires          → tokens semantiques
❌ Couleurs hors tokens        → theme.json uniquement
❌ Animations custom           → transitions predefinies
❌ Composants hors catalogue   → extension manuelle du registry
❌ Fonts hors Design System    → typography tokens
❌ CustomPainter / Shader      → trop bas niveau
❌ Platform channels directs   → Scalario Sense abstrait
```

---

## 20. Implementation Status

```
✅ Composants + variantes (12)
✅ Layout containers (Scaffold, AppBar, BottomNav, Grid, Row, Column, Slots, Stack)
✅ Spacing tokens
✅ Typography tokens
✅ Responsive 3 breakpoints
✅ States (loading, empty, error)
✅ Scroll behavior
✅ Theme switching (dark/light mode)
✅ Transitions + Hero
✅ Forms multi-step wizard
✅ Sheets / Dialogs / Drawers / SnackBars
✅ Gestures (swipe, long press)
✅ Pagination infinite scroll
✅ Offline UI feedback
✅ Keyboard desktop
✅ Accessibility (Semantics)
✅ Print layout
```
