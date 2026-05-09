---
type: components
group: selection
components: [ProductGrid, QuantityControl, ChipSelector, FilterChips, PeriodSelector, ProductSelector]
---

# Composants — Selection

> Ces composants permettent à l'utilisateur de choisir parmi des options définies.

---

## ProductGrid (POS Mode)

**Rôle :** Affichage des produits en grille de cartes pour le POS — tap pour ajouter au panier.
**Usage :** S02 (Quick Sale), S15 (Credit Sale) — surface de vente principale.
**Note :** Ce composant remplace le `ProductSelector` en mode liste pour le POS. Le mode liste reste pour la gestion catalogue (S09, S19).

### Comportement par pos_type

| pos_type | Tap carte | Saisie quantité |
|----------|-----------|----------------|
| `unit` | Ajoute 1 au panier directement | Compteur +/− sur la carte |
| `vrac` | Ouvre une bottom sheet de saisie kg | QuantityControl décimal |
| `service` | Ajoute 1 au panier directement (prix fixe, pas de quantité) | — |
| `mixed` | Ouvre choix : unité ou vrac | Selon choix |

### Props

| Prop | Type | Description |
|------|------|-------------|
| `items` | list | Articles depuis Drift — `{name, price, unit, pos_type, stock, image?}` |
| `columns` | int | 2 (mobile) / 3-4 (web) |
| `filter` | string? | Catégorie active |
| `cart` | CartState | État panier actuel (pour afficher qté sur carte) |

### Sketch ASCII — Mobile (2 colonnes)

```
┌──────────────────────────────────────────────┐
│ 🔍 Rechercher...   [● Légumes] [○ Fruits] → │  SearchBar + FilterChips
├──────────────────────────────────────────────┤
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ 🍅           ║  ║ 🥬           ║           │
│ ║ Tomates      ║  ║ Igname       ║           │
│ ║ 1 500 F/kg   ║  ║ 800 F/kg     ║           │
│ ║ _Stock: 15kg_║  ║ _Stock: 42kg_║           │
│ ║   [+ Ajouter]║  ║   [+ Ajouter]║           │
│ ╚══════════════╝  ╚══════════════╝           │
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ 🌶           ║  ║ 🧅           ║           │
│ ║ Poivrons     ║  ║ Oignons      ║           │
│ ║ 2 000 F/kg   ║  ║ 600 F/kg     ║           │
│ ║ _Stock: 5kg_ ║  ║ _Stock: 28kg_║           │
│ ║ [!] [+ Ajout]║  ║   [+ Ajouter]║           │  ← [!] stock faible
│ ╚══════════════╝  ╚══════════════╝           │
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ 🍌           ║  ║ 🥕           ║           │
│ ║ Bananes      ║  ║ Carottes     ║           │
│ ║ 500 F/kg     ║  ║ 1 200 F/kg   ║           │
│ ║ _Rupture_ [✕]║  ║ _Stock: 18kg_║           │
│ ║ [░ Indispon.]║  ║   [+ Ajouter]║           │  ← grisé si rupture
│ ╚══════════════╝  ╚══════════════╝           │
├──────────────────────────────────────────────┤
│ 🛒 Panier — 2 articles          9 750 FCFA   │  ← barre panier fixe
│                 [ Procéder au paiement → ]   │
└──────────────────────────────────────────────┘
```

### Sketch ASCII — Article ajouté (unit)

```
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ 🍅           ║  ║              ║           │
│ ║ Tomates      ║  ║              ║           │
│ ║ 1 500 F/kg   ║  ║              ║           │
│ ║ _2,5kg = 3750F║  ║             ║           │
│ ║ ┌──┐   ┌──┐  ║  ║             ║           │
│ ║ │− │2,5│+ │  ║  ║             ║           │  ← QuantityControl inline
│ ║ └──┘   └──┘  ║  ║             ║           │
│ ╚══════════════╝  ╚══════════════╝           │
```

### Sketch ASCII — Bottom Sheet vrac (après tap Tomates)

```
┌──────────────────────────────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓ ╔══════════════════════════════════════╗ ▓│
│▓▓ ║  Tomates — Quelle quantité ?         ║ ▓│
│▓▓ ║  Prix : 1 500 FCFA / kg             ║ ▓│
│▓▓ ║  Stock : 15 kg disponibles          ║ ▓│
│▓▓ ║  ──────────────────────────────     ║ ▓│
│▓▓ ║  ┌──────┐ ┌─────────────┐ ┌──────┐ ║ ▓│
│▓▓ ║  │  −   │ │   2,5 kg    │ │  +   │ ║ ▓│
│▓▓ ║  └──────┘ └─────────────┘ └──────┘ ║ ▓│
│▓▓ ║                                     ║ ▓│
│▓▓ ║  = 3 750 FCFA                       ║ ▓│
│▓▓ ║                                     ║ ▓│
│▓▓ ║  ┌──────────────────────────────┐   ║ ▓│
│▓▓ ║  │ ████ Ajouter au panier ██████│   ║ ▓│
│▓▓ ║  └──────────────────────────────┘   ║ ▓│
│▓▓ ╚══════════════════════════════════════╝ ▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└──────────────────────────────────────────────┘
```

### Sketch ASCII — Flutter Web (3 colonnes)

```
┌──────────────────────────────────────────────────────────────┐
│ 🔍 Rechercher...    [● Légumes] [○ Fruits] [○ Secs] [○ Tous] │
├──────────────────────────────────────────────────────────────┤
│ ╔═══════════╗  ╔═══════════╗  ╔═══════════╗                  │
│ ║ 🍅 Tomates║  ║ 🥬 Igname ║  ║ 🌶 Poivron║                  │
│ ║ 1 500F/kg ║  ║ 800 F/kg  ║  ║ 2 000F/kg ║                  │
│ ║ Stock:15kg║  ║ Stock:42kg║  ║ Stock:5kg ║                  │
│ ║[+ Ajouter]║  ║[+ Ajouter]║  ║[!][+ Ajout║                  │
│ ╚═══════════╝  ╚═══════════╝  ╚═══════════╝                  │
│ ╔═══════════╗  ╔═══════════╗  ╔═══════════╗                  │
│ ║ 🧅 Oignons║  ║ 🍌 Bananes║  ║ 🥕 Carottes║                 │
│ ║ 600 F/kg  ║  ║ 500 F/kg  ║  ║ 1 200F/kg ║                  │
│ ║ Stock:28kg║  ║ Rupture[✕]║  ║ Stock:18kg║                  │
│ ║[+ Ajouter]║  ║[░ Indispon]║  ║[+ Ajouter]║                 │
│ ╚═══════════╝  ╚═══════════╝  ╚═══════════╝                  │
├──────────────────────────────────────────────────────────────┤
│ 🛒 Panier — 2 articles : Tomates 2,5kg + Igname 5kg          │
│ Total : 9 750 FCFA          [ Procéder au paiement → ]       │
└──────────────────────────────────────────────────────────────┘
```

---

## ProductSelector (Catalogue Mode)

**Rôle :** Navigation dans le catalogue complet pour la gestion (stock, historique, config).
**Usage :** S09 (Product Setup), S19 (Stock History) — mode liste, pas grille POS.
**Note :** Ce composant N'est PAS le POS. C'est la vue de gestion du catalogue.

### Sketch ASCII

```
┌──────────────────────────────────────────────┐
│ 🔍 Rechercher...                             │
├──────────────────────────────────────────────┤
│ [✓ Légumes] [○ Fruits] [○ Secs] [○ Boissons] │
├──────────────────────────────────────────────┤
│ Tomates              Stock: 15 kg  [● OK]  › │
│ Igname               Stock: 42 kg  [● OK]  › │
│ Poivrons             Stock: 5 kg   [! Alerte]›│
│ Oignons              Stock: 28 kg  [● OK]  › │
│ Bananes              Stock: 0 kg   [✕ Rupture]│
└──────────────────────────────────────────────┘
```

---

## ChipSelector

**Rôle :** Sélection unique parmi des options mutuellement exclusives.
**Usage :** Mode paiement, pos_type (config produit), motif, canal alerte, secteur.

### Sketches ASCII

```
3 OPTIONS :
  [● Espèces]  [○ Mobile Money]  [○ Crédit]

AVEC ICÔNES (pos_type en config produit) :
  [● 📦 Vrac (kg)]  [○ 🔢 Unité]  [○ 🛠 Service]  [○ … Autre]

RÉVÈLE CHAMPS CONDITIONNELS (mode Crédit sélectionné) :
  [○ Espèces]  [○ Mobile Money]  [● Crédit]
  ↓
  Nom client *
  ┌─────────────────────────────────────────┐
  │                                         │
  └─────────────────────────────────────────┘
```

---

## FilterChips

**Rôle :** Filtres multi-sélection pour listes et catalogue.
**Usage :** S12, S14, S18, S19 — et barre de catégories du POS.

### Sketch ASCII

```
  [✓ Légumes]  [✓ Fruits]  [○ Secs]  [○ Boissons]
```

---

## PeriodSelector

**Rôle :** Sélection de période pour rapports et historique.
**Usage :** S12, S19.

### Sketch ASCII

```
  [● Aujourd'hui]  [○ Semaine]  [○ Mois]  [○ Perso...]
```

---

## QuantityControl

**Rôle :** Saisie de quantité avec boutons +/−.
**Usage :** Bottom sheet POS (vrac), saisie livraison, saisie inventaire.

### Sketches ASCII

```
VRAC (décimal) :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │     2,5 kg       │  │  +   │
  └──────┘  └──────────────────┘  └──────┘

UNIT (entier) :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │    12 pièces     │  │  +   │
  └──────┘  └──────────────────┘  └──────┘

MAX ATTEINT :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │  15 kg (max)     │  │  ░   │  ← + grisé
  └──────┘  └──────────────────┘  └──────┘
```
