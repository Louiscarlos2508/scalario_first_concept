---
type: components
group: data-display
components: [KPICard, TransactionList, RankingList, ChartWidget]
---

# Composants — Data Display

> Ces composants affichent des données calculées. Lecture seule.
> Le contenu vient toujours du backend ou de Drift — jamais hardcodé.

---

## KPICard

**Rôle :** Affiche une métrique clé avec sa valeur, son label et sa variation.
**Position :** Grille 2×2 sur mobile, 3–4 colonnes sur web.
**Règle :** Tappable si drill-down disponible — chevron discret en bas à droite.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `label` | string | Nom de la métrique |
| `value` | string | Valeur formatée (ex: "47 500") |
| `unit` | string? | Unité séparée (ex: "FCFA", "kg", "articles") |
| `delta` | string? | Variation (ex: "+12%", "−3 kg") |
| `delta_positive` | bool? | true = vert, false = rouge |
| `status` | enum? | `nominal` / `warning` / `critical` |
| `drilldown_route` | string? | Route si tappable |

### États & Sketches ASCII

```
NOMINAL (2×2 mobile) :
╔══════════════════╗  ╔══════════════════╗
║ CA du jour       ║  ║ Marge brute      ║
║                  ║  ║                  ║
║  47 500          ║  ║  18 200          ║
║  FCFA            ║  ║  FCFA            ║
║  _+12% vs hier_  ║  ║  _38% ↑_         ║
╚══════════════════╝  ╚══════════════════╝
╔══════════════════╗  ╔══════════════════╗
║ Transactions     ║  ║ Stock critique   ║
║                  ║  ║                  ║
║     23           ║  ║      3           ║
║  _ventes_        ║  ║  _articles_      ║
║  _+3 vs hier_    ║  ║  _[!] alerte_    ║
╚══════════════════╝  ╚══════════════════╝

CRITIQUE (valeur rouge) :
╔══════════════════╗
║ Stock critique   ║
║                  ║
║      3           ║  ← color-danger-500
║  _articles_      ║
║  _[!] alerte_    ║  ← color-danger-500
╚══════════════════╝
fond: color-danger-50 | bordure gauche: color-danger-500

TAPPABLE (chevron discret) :
╔══════════════════╗
║ CA du jour       ║
║                  ║
║  47 500          ║
║  FCFA  +12%      ║
║              _›_ ║  ← chevron bas droite
╚══════════════════╝
```

---

## TransactionList / TransactionLine

**Rôle :** Affiche une liste de transactions ou mouvements — chronologique décroissant.
**Position :** Section dédiée du dashboard ou vue détail.

### Props (TransactionLine)

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | `sale` / `delivery` / `loss` / `inventory` / `order` / `cancellation` |
| `timestamp` | datetime | Heure/date |
| `amount` | string? | Montant formaté |
| `description` | string | Résumé (articles, motif…) |
| `actor` | string? | Responsable |
| `status` | StatusBadge | Statut actuel |
| `tappable` | bool | Si tap → détail |

### Sketches ASCII

```
VENTE (active) :
┌────────────────────────────────────────────┐
│ Vente · 09:34                 12 500 FCFA  │
│ _Tomates 2kg · Igname 5kg_        [● Actif]│
└────────────────────────────────────────────┘

VENTE (annulée) :
┌────────────────────────────────────────────┐
│ ~~Vente · 09:34~~         ~~8 000 FCFA~~   │
│ _Erreur saisie_                  [✕ Annulé]│
└────────────────────────────────────────────┘

VENTE (crédit) :
┌────────────────────────────────────────────┐
│ Vente crédit · 11:20          15 000 FCFA  │
│ _Mamadou · Solde dû: 10 000 FCFA_ [! Crédit]│
└────────────────────────────────────────────┘

LIVRAISON :
┌────────────────────────────────────────────┐
│ Livraison · FrutPro · 08:15    +45 kg tot. │
│ _Tomates 20kg · Igname 25kg_  [● Reçu]    │
└────────────────────────────────────────────┘

PERTE :
┌────────────────────────────────────────────┐
│ Perte déclarée · Ibrahim · 14:30           │
│ _Tomates 3kg — Avariées_        [! Perdu]  │
└────────────────────────────────────────────┘

MOUVEMENT STOCK (inventaire écart) :
┌────────────────────────────────────────────┐
│ Inventaire · 18:00         Écart: −2,5 kg  │
│ _Stock théo: 12kg · Réel: 9,5kg_ [! Écart] │
└────────────────────────────────────────────┘

Liste complète :
┌────────────────────────────────────────────┐
│ [✓ Ventes]  [✓ Livraisons]  [○ Pertes]    │  ← FilterChips
├────────────────────────────────────────────┤
│ Vente · 14:30                 8 500 FCFA  │
│ _Poivrons 1kg · Tomates 2kg_  [● Actif]  │
├────────────────────────────────────────────┤
│ Livraison · FrutPro · 12:00   +38 kg tot.  │
│ _Tomates 20kg · Igname 18kg_  [● Reçu]   │
├────────────────────────────────────────────┤
│ Vente · 09:34                12 500 FCFA  │
│ _Tomates 2kg · Igname 5kg_   [● Actif]   │
└────────────────────────────────────────────┘
```

---

## RankingList

**Rôle :** Classement des meilleurs articles par une métrique (CA, quantité, etc.).
**Position :** Section scroll du dashboard OWNER ou vue rapport.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Titre du classement |
| `items` | list | `{rank, label, value, unit, tappable}` |
| `period` | string | Période (affiché en caption) |

### Sketch ASCII

```
Top 5 articles — Aujourd'hui
┌────────────────────────────────────────────┐
│  1  Tomates           23 500 FCFA      ›   │
│     _42 kg vendus_                         │
├────────────────────────────────────────────┤
│  2  Igname            18 200 FCFA      ›   │
│     _91 kg vendus_                         │
├────────────────────────────────────────────┤
│  3  Poivrons           8 800 FCFA      ›   │
│     _8,8 kg vendus_                        │
├────────────────────────────────────────────┤
│  4  Oignons            6 500 FCFA      ›   │
├────────────────────────────────────────────┤
│  5  Bananes            4 200 FCFA      ›   │
└────────────────────────────────────────────┘
_Tap sur un article pour voir l'historique_
```

---

## ChartWidget

**Rôle :** Graphique de tendance — line chart (CA) ou bar chart (comparaisons).
**Position :** Section scroll dashboard OWNER, vue rapport période.
**Règle :** Toujours tappable (point ou barre) → drill-down.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | `line` / `bar` |
| `title` | string | Titre du graphique |
| `data` | list | `{label, value}` — depuis backend/Drift |
| `unit` | string | Unité des valeurs (FCFA, kg…) |
| `period` | string | Période affichée |

### Sketch ASCII

```
CA — 7 derniers jours
┌────────────────────────────────────────────┐
│  60k ┤                         ●           │
│  50k ┤              ●     ●         ●      │
│  40k ┤         ●                          │
│  30k ┤    ●                               │
│  20k ┤●                                   │
│      └─────┬─────┬─────┬─────┬─────┬─────┤
│           L03   L04   L05   L06   L07   L08 │
│                              _Aujourd'hui_ │
└────────────────────────────────────────────┘
_Tap sur un point pour voir le détail_

Bar chart — CA par jour (semaine) :
┌────────────────────────────────────────────┐
│  60k ┤                         ██          │
│  50k ┤         ██    ██   ██   ██  ██      │
│  40k ┤   ██   ██    ██   ██   ██  ██      │
│      └─────┬──────┬──────┬──────┬──────┬──┤
│           Lun   Mar   Mer   Jeu   Ven  Sam  │
└────────────────────────────────────────────┘
```
