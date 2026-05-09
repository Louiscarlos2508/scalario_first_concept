---
type: components
group: data-display
components: [KPICard, TransactionList, RankingList, ChartWidget, InfoCard, DateSeparator, MouvementItem, StockListItem, OperationItem, ContextCard, ContentPreview, DataTable, StatusTable, LogItem]
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

---

## InfoCard

**Rôle :** Carte d'information contextuelle — affiche un groupe de champs label/valeur en lecture seule. Composant générique utilisé partout où un bloc d'infos structurées est nécessaire.
**Usage :** S17.3, S19.1, S20, S22, S25.1, S26.2, A02, A03, A04, A05 — le plus utilisé après KPICard.
**Règle :** Pas d'action inline dans l'InfoCard. Si une action est possible, elle est séparée (ActionButton sous la card).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string? | Titre de la section (optionnel) |
| `items` | list | `{label: string, value: string, value_style?: "mono" / "normal"}` |
| `style` | enum? | `default` / `success` / `warning` / `danger` |

### Sketch ASCII

```
INFOS ENTREPRISE (S17.3) :
╔══════════════════════════════════════════╗
║  INFORMATIONS BOUTIQUE                   ║  titre — Inter 13sp 600 neutral-600
║  ───────────────────────────────────     ║
║  Nom       Boutique Kouamé               ║  label: Inter 12sp 400 neutral-500
║  Adresse   Cocody, Abidjan               ║  valeur: Inter 13sp 500 neutral-800
║  Template  retail_fresh_produce          ║  valeur mono: Roboto Mono 13sp
║  RCCM      CI-ABJ-2025-B-1234           ║  ← Roboto Mono (identifiant)
║  Intégrat. Kofi Mensah                   ║
╚══════════════════════════════════════════╝
  bg: color-neutral-50 · radius-md · padding 16px

SÉCURITÉ (S25.1) — style success :
╔══════════════════════════════════════════╗
║  SÉCURITÉ                                ║
║  ───────────────────────────────────     ║
║  Déverrouillage  PIN 6 chiffres          ║
║  Dernière conn.  09/05/2026  08h15       ║  Roboto Mono pour timestamp
╚══════════════════════════════════════════╝
  bg: color-success-50 · si statut sécurité OK

PLAN FACTURATION (A04) — style danger :
╔══════════════════════════════════════════╗
║  PLAN ACTUEL                             ║
║  ───────────────────────────────────     ║
║  Plan      Standard                      ║
║  Montant   40 000 FCFA/mois              ║  Roboto Mono
║  Prochain  01/06/2026                    ║  Roboto Mono
║  Statut    ⛔ Impayé 35 jours           ║
╚══════════════════════════════════════════╝
  bg: color-danger-50 · si statut danger
```

---

## DateSeparator

**Rôle :** Séparateur de date dans une liste chronologique — groupe les items par journée.
**Usage :** S14.1 (Historique ventes), S19.2 (Historique article), S22 (Opérations manager).
**Règle :** Sticky pendant le scroll si la liste est longue. Ne dépasse jamais la hauteur 32px.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `date` | date | Date du groupe |
| `sticky` | bool | Reste visible pendant le scroll (défaut: true) |

### Sketch ASCII

```
AUJOURD'HUI :
  ────────── Aujourd'hui · 09/05/2026 ──────────
  h=32px · Inter 11sp 500 color-neutral-400 · centré · bg color-neutral-50

HIER :
  ─────────────── Hier · 08/05/2026 ───────────

DATE PASSÉE :
  ──────────────── 05/05/2026 ─────────────────
```

---

## MouvementItem

**Rôle :** Item de liste dans l'historique des mouvements d'un article — encode le type (TypeBadge), le delta, le contexte (qui / quand).
**Usage :** S19.2 (Historique article — MouvementList).
**Règle :** Tappable → ÉTAT détail (S19.3). Border-l colorée selon le `TypeBadge` du mouvement.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | Même enum que `TypeBadge` |
| `timestamp` | datetime | Date et heure |
| `delta_qty` | string | Ex: "−3 kg" ou "+20 kg" |
| `delta_positive` | bool | true = vert, false = rouge |
| `description` | string | Résumé humain |
| `actor` | string? | Commercial / Manager / Système |
| `tappable` | bool | true → S19.3 |

### Sketch ASCII

```
VENTE (border-l primary) :
┌─────────────────────────────────────────────┐
║ [Vente]   09h34 · Ibrahim         −2,5 kg   ║  TypeBadge primary + delta Roboto Mono rouge
║  Tomates 2,5kg — Vente espèces              ║  Inter 12sp neutral-500
└─────────────────────────────────────────────┘
bg: color-white · border-l 3px color-primary-300

LIVRAISON (border-l success) :
┌─────────────────────────────────────────────┐
║ [Livraison]  08h15 · FrutPro       +20 kg   ║  delta Roboto Mono vert
║  Réception confirmée par Ibrahim            ║
└─────────────────────────────────────────────┘
bg: color-success-50 · border-l 3px color-success-500

INVENTAIRE ÉCART (border-l danger) :
┌─────────────────────────────────────────────┐
║ [Inventaire]  18h00 · Ibrahim      −3 kg    ║  delta Roboto Mono rouge
║  Écart signif. · Théo:15kg · Réel:12kg      ║
└─────────────────────────────────────────────┘
bg: color-danger-50 · border-l 3px color-danger-400
```

---

## StockListItem

**Rôle :** Item dans la vue liste du stock — affiche le niveau actuel, le seuil critique, le statut et le delta depuis le dernier inventaire.
**Usage :** S19.1 (Vue stock — liste articles).
**Règle :** Tappable → S19.2 (historique article). Couleur border-l selon le statut stock.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `name` | string | Nom de l'article |
| `category` | string | Catégorie (depuis template JSON) |
| `stock_qty` | number | Stock actuel |
| `unit` | string | Unité (kg, pièces…) |
| `threshold_qty` | number | Seuil d'alerte critique |
| `status` | enum | `ok` / `critical` / `surplus` / `rupture` |
| `delta_since_inventory` | string? | Ex: "↓ −3 depuis inv." |
| `last_updated` | datetime | Timestamp dernière MAJ |

### Sketch ASCII

```
STOCK OK :
┌──────────────────────────────────────────────┐
│ Igname                   Stock: 42 kg  [● OK]›│
│ _Légumes · Seuil: 5 kg_                       │
└──────────────────────────────────────────────┘
bg: color-white · border: color-neutral-100

STOCK CRITIQUE :
┌──────────────────────────────────────────────┐
│ Tomates            Stock: 2,3 kg  [! Critique]›│
│ _Légumes · Seuil: 5 kg_ ↓ −3 depuis inv.     │  ← delta Roboto Mono 11sp danger-600
└──────────────────────────────────────────────┘
bg: color-danger-50 · border-l 3px color-danger-400

SURPLUS :
┌──────────────────────────────────────────────┐
│ Oignons              Stock: 28 kg  [↑ Surplus]›│
│ _Légumes · Seuil: 3 kg_ ↑ +2 depuis inv.     │  ← delta Roboto Mono 11sp primary-500
└──────────────────────────────────────────────┘
bg: color-white · border-l 3px color-primary-300

RUPTURE :
┌──────────────────────────────────────────────┐
│ Bananes               Stock: 0 kg  [✕ Rupture]›│
│ _Fruits · Rupture totale_                     │
└──────────────────────────────────────────────┘
bg: color-danger-50 · border-l 3px color-danger-600
```

---

## OperationItem

**Rôle :** Item dans la liste des opérations récentes du Dashboard MANAGER — encode le type d'opération terrain (réception, inventaire, perte, commande).
**Usage :** S22.1 (Dashboard Manager — OperationList).
**Règle :** Tappable → vue détail de l'opération concernée. Icône et couleur selon le type.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | `reception` / `inventory` / `loss` / `order` |
| `timestamp` | datetime | Date et heure |
| `summary` | string | Résumé de l'opération |
| `actor` | string | Responsable |
| `status` | enum | `done` / `pending` / `partial` |

### Sketch ASCII

```
RÉCEPTION (✓ confirmée) :
┌──────────────────────────────────────────────┐
│ 📦 Réception · FrutPro · 08h15   [✓ Confirmé]│
│ _Tomates 20kg · Igname 25kg · Ibrahim_       │
└──────────────────────────────────────────────┘
icône success · border-l color-success-400

RÉCEPTION EN ATTENTE :
┌──────────────────────────────────────────────┐
│ 📦 Réception · FrutPro · Aujourd'hui  [↻ Att]│
│ _Commande attendue — à réceptionner_         │
└──────────────────────────────────────────────┘
icône warning · border-l color-warning-400

INVENTAIRE :
┌──────────────────────────────────────────────┐
│ 📋 Inventaire partiel · 18h00       [✓ Fait] │
│ _Légumes · 2 déficits · Ibrahim_             │
└──────────────────────────────────────────────┘
icône primary · border-l color-primary-300

PERTE :
┌──────────────────────────────────────────────┐
│ ⚠ Perte déclarée · 14h30          [! Perte]  │
│ _Tomates 3kg avariées · Ibrahim_             │
└──────────────────────────────────────────────┘
icône warning · border-l color-warning-500
```

---

## ContextCard

**Rôle :** Carte de contexte métier liée à un mouvement ou une opération — affiche qui a fait quoi, quand, avec quelles données associées. Apparaît dans les vues détail.
**Usage :** S19.3 (Détail mouvement — contexte de la transaction / livraison / inventaire).
**Règle :** Toujours en bas de la vue détail, sous les KPICards. Jamais tappable lui-même — ses CTAs sont séparés.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Titre ("Contexte vente", "Détail livraison"…) |
| `items` | list | `{label, value, value_style?}` — même structure qu'InfoCard |
| `type` | enum | `sale` / `delivery` / `loss` / `inventory` — détermine les champs affichés |

### Sketch ASCII

```
CONTEXTE VENTE :
╔══════════════════════════════════════════╗
║  Contexte vente                          ║
║  ─────────────────────────────────────   ║
║  Réf.        TXN-2026-0847               ║  Roboto Mono 12sp (identifiant)
║  Commercial  Ibrahim Coulibaly           ║
║  Heure       09h34 · 09/05/2026          ║  Roboto Mono
║  Panier      Tomates 2,5kg · Igname 3kg  ║
║  Total       9 250 FCFA                  ║  Roboto Mono 700
║  Mode        Espèces                     ║
╚══════════════════════════════════════════╝

CONTEXTE LIVRAISON :
╔══════════════════════════════════════════╗
║  Détail livraison                        ║
║  ─────────────────────────────────────   ║
║  Fournisseur  FrutPro SARL               ║
║  Commandé     20 kg                      ║  Roboto Mono
║  Reçu         18 kg  [⚠ écart]          ║  Roboto Mono · warning si écart
║  Prix unitaire 750 FCFA/kg               ║  Roboto Mono
║  Validé par   Ibrahim · 08h15            ║
╚══════════════════════════════════════════╝
```

---

## ContentPreview

**Rôle :** Résumé des données qui seront incluses dans un export (rapport PDF ou CSV). Affiché avant la génération pour que l'utilisateur confirme le contenu.
**Usage :** S28.1 (Export rapport — BottomSheet format/canal).
**Règle :** Lecture seule. Se met à jour si la période ou le filtre change (debounce 300ms).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `period` | string | Période de l'export (ex: "09/05/2026") |
| `items` | list | `{label, value}` — métriques clés incluses |

### Sketch ASCII

```
EXPORT RAPPORT — CONTENU INCLUS :
╔══════════════════════════════════════════╗
║  Période        09/05/2026               ║  Roboto Mono 13sp pour valeurs
║  CA             47 500 FCFA              ║
║  Transactions   23                       ║
║  Top articles   5 inclus                 ║
║  Pertes         2 déclarées              ║
╚══════════════════════════════════════════╝
  bg: color-neutral-50 · radius-md · padding 14px
  label: Inter 13sp 400 color-neutral-500
  valeur: Roboto Mono 13sp 400 color-neutral-900
```

---

## DataTable

**Rôle :** Tableau de données structuré avec colonnes, tri par colonne et hover sur ligne — exclusivement sur Flutter Web (surfaces Admin). Non utilisé sur mobile.
**Usage :** A01 (tenants en erreur), A02 (liste tenants), A03 (liste intégrateurs), A04 (liste facturation), A05 (liste tenants santé).
**Règle :** Tri par colonne au clic de l'en-tête (↑↓ toggle). Hover ligne : bg color-primary-50. Clic ligne → détail.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `columns` | list | `{key, label, sortable, width?, align?}` |
| `rows` | list | Tableau de données — chaque ligne est un objet |
| `on_row_tap` | callback(row) | Navigation vers le détail |
| `default_sort` | string? | Colonne de tri par défaut |
| `default_sort_asc` | bool | true = croissant |

### Sketch ASCII

```
DATATABLE TENANTS (A02) :
╔═══════════════════════════════════════════════════════╗
║ Nom Tenant       Intégrateur  Template  Statut  MRR  ›║  en-tête Inter 12sp 600 neutral-600
║ ─────────────────────────────────────────────────────║
║ Boutique Kouamé  Kofi Mensah  retail_fp ✓ Actif 40k ›║  hover → bg primary-50
║ Shop Aminata     Kofi Mensah  retail_fp ✓ Actif 40k ›║  MRR: Roboto Mono 13sp 700
║ [... lignes ...]                                      ║
╚═══════════════════════════════════════════════════════╝

EN-TÊTE CLIQUABLE (tri actif) :
║ Nom Tenant ↑     Intégrateur  ...                     ║  ↑ = tri croissant actif
```

---

## StatusTable

**Rôle :** Variante de DataTable spécifique au monitoring — les lignes ont une couleur de fond réactive au statut santé (OK / warning / erreur). Tri automatique : erreurs en premier.
**Usage :** A01 (alertes actives), A05 (santé des tenants).
**Règle :** Lignes erreur = bg color-danger-50. Lignes warning = bg color-warning-50. Lignes OK = bg color-white. Séparateur visuel entre groupes.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `columns` | list | Idem DataTable |
| `rows` | list | Chaque ligne a un champ `health_status: "ok" / "warning" / "error"` |
| `on_row_tap` | callback(row) | → détail tenant monitoring |

### Sketch ASCII

```
STATUSTABLE MONITORING (A05) :
╔═════════════════════════════════════════════════════╗
║ Tenant         Dernière sync   FCM 7j  Erreurs Stat ║  en-tête
║ ───────────────────────────────────────────────────  ║
║ Shop Aminata   14h32 (53min)  84,1%   3   ⛔ Err  ›║  bg danger-50
║ Boutique Kouamé 14h45 (35min) 81,3%   3   ⛔ Err  ›║  bg danger-50
║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ║  séparateur groupes
║ Marché Plateau 15h16 (4min)   98,2%   0   ✓ OK   ›║  bg white
║ Super Yidaba   15h15 (5min)   96,5%   0   ✓ OK   ›║  bg white
╚═════════════════════════════════════════════════════╝

Timestamps : Roboto Mono 12sp color-neutral-600
FCM % : Roboto Mono 12sp — > 95%: success-700 · 85-95%: neutral-900 · < 85%: danger-700
```

---

## LogItem

**Rôle :** Entrée de log système dans la vue Monitoring admin — affiche timestamp, sévérité, tenant, type, message résumé. Expandable pour voir le stack trace.
**Usage :** A05 (Vue Logs — LogList temps réel).
**Règle :** Tap sur l'item → expand/collapse stack trace. Border-l colorée selon sévérité. Auto-refresh de la liste toutes les 30s.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `timestamp` | datetime | Format HH:mm:ss.ms |
| `severity` | enum | `critical` / `warning` / `info` |
| `tenant_name` | string | Nom du tenant concerné (ou "Tous") |
| `log_type` | enum | `sync` / `fcm` / `auth` / `api` / `webhook` |
| `message` | string | Message résumé |
| `detail` | string? | Détail technique (2e ligne) |
| `stack_trace` | string? | Stack trace complet (affiché à l'expand) |
| `actions` | list? | CTAs contextuels (ex: "Forcer resync") |

### Sketch ASCII

```
LOG CRITIQUE (collapsed) :
┌───────────────────────────────────────────────────┐
│ 15:20:14  ⛔ CRITIQUE  Shop Aminata     SYNC       │  bg danger-50 · border-l 3px danger-500
│  Drift sync échec — tentative 4/5 — conn refused   │  Inter 12sp neutral-700
│  [Voir détail]  [Forcer resync]                    │  CTAs Inter 12sp primary-600
└───────────────────────────────────────────────────┘

LOG CRITIQUE (expanded — stack trace visible) :
┌───────────────────────────────────────────────────┐
│ 15:20:14  ⛔ CRITIQUE  Shop Aminata     SYNC       │
│  Drift sync échec — tentative 4/5                  │
│  ┌─────────────────────────────────────────────┐  │
│  │ DriftException: ConnectionRefused            │  │  bg neutral-900 · Roboto Mono 11sp
│  │   at SyncService.push (sync_service.dart:142)│  │  color-neutral-100
│  │   at BackendAdapter.flush (adapter.dart:88)  │  │
│  └─────────────────────────────────────────────┘  │
│  [Voir détail]  [Forcer resync]                    │
└───────────────────────────────────────────────────┘

LOG WARNING (collapsed) :
┌───────────────────────────────────────────────────┐
│ 14:55:03  ⚠️ WARNING   Tous tenants    FCM         │  bg warning-50 · border-l 3px warning-500
│  FCM delivery rate 84% — seuil 85%                 │
└───────────────────────────────────────────────────┘

LOG INFO (collapsed) :
┌───────────────────────────────────────────────────┐
│ 14:32:01  ℹ️ INFO    Boutique Kouamé   SYNC        │  bg white · border-l 3px neutral-200
│  Sync OK — 143 enregistrements                     │
└───────────────────────────────────────────────────┘

Timestamp : Roboto Mono 12sp color-neutral-500
Tenant : Inter 12sp 600 color-neutral-800
Message résumé : Inter 13sp 500 color-neutral-800
Stack trace panel : bg color-neutral-900 · Roboto Mono 11sp color-neutral-100
```
