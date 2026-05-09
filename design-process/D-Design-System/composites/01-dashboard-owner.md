---
type: composite
slug: dashboard-owner
components: [AlertBanner, KPICard, ChartWidget, RankingList, ActionButton, SyncStatusBar]
scenarios: [01, 20]
---

# Composite — Dashboard OWNER

> Assemblage des composants atomiques pour le dashboard Blandine.
> Règle : AlertBanner si active, KPIs above fold, actions accessibles sans scroll.

---

## Mobile Android — État Nominal (pas d'alerte)

```
┌──────────────────────────────────────────────┐
│ 📶 🔋                              09:45     │  StatusBar Android
├──────────────────────────────────────────────┤
│ ≡  MON MAGASIN                     [🔔] [⚙] │  AppBar h=56px
├──────────────────────────────────────────────┤
│                                              │  ← AlertBanner absente
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ CA du jour   ║  ║ Marge brute  ║           │
│ ║  47 500      ║  ║  18 200      ║           │
│ ║  FCFA        ║  ║  FCFA        ║           │
│ ║  _+12%_ ↑   ║  ║  _38%_ ↑    ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│                                              │
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Transactions ║  ║ Stock crit.  ║           │
│ ║     23       ║  ║      0       ║           │
│ ║  _ventes_    ║  ║  _articles_  ║           │
│ ║  _+3 vs hier_║  ║  _[● OK]_    ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│  CA — 7 derniers jours                       │
│  ┌──────────────────────────────────────┐    │  ↕ scroll
│  │  60k ┤                          ●    │    │
│  │  50k ┤         ●    ●      ●       ●│    │
│  │  40k ┤    ●                          │    │
│  │      └──L03──L04──L05──L06──L07──L08─┤    │
│  └──────────────────────────────────────┘    │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│  Top 3 articles — Aujourd'hui                │
│  ┌──────────────────────────────────────┐    │
│  │  1  Tomates       23 500 FCFA     ›  │    │
│  │  2  Igname        18 200 FCFA     ›  │    │
│  │  3  Poivrons       8 800 FCFA     ›  │    │
│  └──────────────────────────────────────┘    │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │📊 Rapports│ │📦 Stock  │ │👥 Équipe │     │
│  └──────────┘ └──────────┘ └──────────┘     │
│  ┌───────────────────────────────────────┐   │
│  │           Commander →                 │   │
│  └───────────────────────────────────────┘   │
├──────────────────────────────────────────────┤
│  [●] Synchronisé — il y a 2 min              │  SyncStatusBar
├──────────────────────────────────────────────┤
│ 🏠 Dashboard  📊 Rapports  📦 Stock  ⚙ Params│  Bottom nav
└──────────────────────────────────────────────┘
```

---

## Mobile Android — État Alerte Critique

```
┌──────────────────────────────────────────────┐
│ ≡  MON MAGASIN                     [🔔] [⚙] │
├──────────────────────────────────────────────┤
│ [!] Stock critique : Tomates — 2,3 kg        │  AlertBanner rouge
│                                  [Voir stock]│
├──────────────────────────────────────────────┤
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ CA du jour   ║  ║ Marge brute  ║           │
│ ║  47 500      ║  ║  18 200      ║           │
│ ║  FCFA +12%   ║  ║  FCFA 38%    ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Transactions ║  ║ Stock crit.  ║           │
│ ║     23       ║  ║      3       ║  ← rouge  │
│ ║  _+3 vs hier_║  ║  _[!] alerte_║           │
│ ╚══════════════╝  ╚══════════════╝           │
│  ... (suite identique)                       │
└──────────────────────────────────────────────┘
```

---

## Flutter Web PWA — Layout 3 colonnes

```
┌────────────────────────────────────────────────────────────────┐
│ [Sc] MON MAGASIN                          [Blandine ▾] [⚙]   │  TopBar
├──────────┬─────────────────────────────────────────────────────┤
│          │ [!] Stock critique : Tomates — 2,3 kg  [Voir stock] │  AlertBanner
│ Dashboard│─────────────────────────────────────────────────────│
│ Rapports │ ╔══════════╗ ╔══════════╗ ╔══════════╗ ╔══════════╗│
│ Stock    │ ║ CA        ║ ║ Marge    ║ ║ Transact.║ ║ Stk crit.║│
│ Équipe   │ ║ 47 500F   ║ ║ 18 200F  ║ ║   23     ║ ║    3  [!]║│
│ Fourniss.│ ║ +12%↑     ║ ║ 38% ↑    ║ ║ +3 vs.h. ║ ║  articles║│
│ Paramèt. │ ╚══════════╝ ╚══════════╝ ╚══════════╝ ╚══════════╝│
│          │─────────────────────────────────────────────────────│
│ ─────    │ CA — 7 derniers jours    │ Top 3 articles           │
│ Blandine │ ┌─────────────────────┐  │ 1. Tomates  23 500F  ›  │
│ [Déconn] │ │     line chart      │  │ 2. Igname   18 200F  ›  │
│          │ └─────────────────────┘  │ 3. Poivrons  8 800F  ›  │
│          │─────────────────────────────────────────────────────│
│          │ [📊 Rapports] [📦 Stock] [👥 Équipe] [Commander →] │
└──────────┴─────────────────────────────────────────────────────┘
```
