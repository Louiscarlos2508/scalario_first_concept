---
type: components
group: selection
components: [ProductGrid, QuantityControl, ChipSelector, FilterChips, PeriodSelector, ProductSelector, CartSummary, ChoiceCard, PaymentMethodSelector, BluetoothDeviceSelector]
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

---

## CartSummary

**Rôle :** Barre sticky fixe en bas d'écran pendant le POS — affiche le total courant du panier et l'accès au paiement. Toujours visible au-dessus du BottomNav (ou à sa place si BottomNav masqué pendant la vente).
**Usage :** S02.2 (Sélection Articles), S15.2 (Vente Crédit) — surface POS.
**Règle :** Caché si panier vide. Apparaît en slide-up (200ms ease-in) au premier ajout. Sticky bottom — ne défile pas.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `item_count` | int | Nombre d'articles dans le panier |
| `total_fcfa` | int | Total calculé en FCFA |
| `is_enabled` | bool | false = disabled (panier vide ou stock bloquant) |
| `on_tap` | callback | → navigation vers 02.3 Confirmation Paiement |

### Tokens

| Élément | Token | Valeur |
|---------|-------|--------|
| Fond barre | `color-neutral-900` | #1A1A1A (sombre, contraste fort) |
| Label articles | `color-neutral-400` | Roboto Mono 12sp |
| Montant total | `color-primary-400` | Roboto Mono 18sp 700 (#FFCC00 atténué) |
| CTA "Procéder" | `color-primary-500` bg | #FFCC00, color-neutral-900 |
| Hauteur | — | 64px + safeAreaBottom |
| Élévation | `elevation-4` | shadow remontant |

### Sketch ASCII

```
PANIER VIDE — caché (aucun rendu)

PANIER ACTIF — 2 articles :
┌──────────────────────────────────────────────┐  ← sticky bottom 64px
│ 🛒 2 articles              9 750 FCFA        │  bg color-neutral-900
│              [ Procéder au paiement → ]       │  btn #FFCC00 h=40px radius-md
└──────────────────────────────────────────────┘

  label      : Inter 12sp 500 color-neutral-400 — "2 articles"
  montant    : Roboto Mono 18sp 700 color-primary-400
  CTA label  : Inter 14sp 500 color-neutral-900

PANIER ACTIF — expanded (web, side panel) :
  → Côté droit de l'écran : liste détaillée + total + bouton pleine largeur
  → Même tokens, layout vertical

STOCK BLOQUANT (qté > stock) :
  bg color-neutral-900 · CTA bg color-neutral-400 (disabled) · texte "Stock insuffisant"
```

---

## ChoiceCard

**Rôle :** Carte de sélection large — permet de choisir une option parmi 2 ou 3 alternatives visuellement distinctes. Différent de ChipSelector : chaque option est une carte full-tap avec description, pas juste un chip.
**Usage :** S24.1 (Setup PIN/biométrie — choix méthode de déverrouillage).
**Règle :** Tap sur toute la surface de la carte = sélection. Indicateur radio ○/● en haut à droite. Une seule carte sélectionnée à la fois.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `options` | list | `{id, icon, title, description, available}` |
| `selected` | string | ID de l'option sélectionnée |
| `on_select` | callback(id) | Mise à jour sélection |

### Sketch ASCII

```
2 OPTIONS — PIN sélectionné :
┌──────────────────────────────────────────────┐
│ ●  🔢 Code PIN                               │  ← sélectionné (radio plein)
│    Déverrouillez avec un code à 6 chiffres   │  bg color-primary-50 · border color-primary-500
│    Fonctionne hors ligne                     │  Inter 13sp 400 neutral-600
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ ○  👆 Biométrie (empreinte / face)           │  ← non sélectionné
│    Déverrouillez sans saisir de code         │  bg color-white · border color-neutral-200
│    Nécessite configuration Android           │
└──────────────────────────────────────────────┘

OPTION NON DISPONIBLE (web — biométrie grisée) :
┌──────────────────────────────────────────────┐
│ ○  👆 Biométrie (empreinte / face)    [Web]  │  bg color-neutral-50 · opacity 0.5
│    _Disponible sur l'application mobile_     │  Inter 13sp 400 neutral-400 (grisé)
└──────────────────────────────────────────────┘
```

---

## PaymentMethodSelector

**Rôle :** Sélecteur de mode de paiement dans le flow POS — similaire à ChipSelector mais avec gestion de l'état partiel (vente crédit = montant versé + solde dû).
**Usage :** S02.3 (Confirmation paiement standard), S15.2 (Paiement partiel / crédit).
**Règle :** Sélection "Crédit" révèle les champs `Montant versé` et `Nom client`. Sélection "Espèces" ou "Mobile Money" = paiement complet, pas de champs additionnels.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `modes` | list | Modes disponibles depuis retail_fresh_produce.json |
| `selected` | enum | `cash` / `mobile_money` / `credit` |
| `on_select` | callback(mode) | Révèle champs conditionnels selon mode |

### Sketch ASCII

```
ESPÈCES SÉLECTIONNÉ :
  [● Espèces]  [○ Mobile Money]  [○ Crédit]

CRÉDIT SÉLECTIONNÉ — champs révélés :
  [○ Espèces]  [○ Mobile Money]  [● Crédit]

  Montant versé maintenant (FCFA)
  ┌──────────────────────────────────────────┐
  │  5 000                                   │  NumberInput
  └──────────────────────────────────────────┘
  _Solde dû : 10 000 FCFA — sera enregistré comme créance_

  Nom client *
  ┌──────────────────────────────────────────┐
  │  Koné Fatou                              │  TextInput
  └──────────────────────────────────────────┘
```

---

## BluetoothDeviceSelector

**Rôle :** Sélecteur d'imprimante Bluetooth thermique — scan des appareils à portée, sélection et mémorisation de l'imprimante préférée.
**Usage :** S27.1 (Ticket caisse — canal "Impression Bluetooth").
**Règle :** Le scan se lance automatiquement quand le canal "Impression" est sélectionné. Durée du scan : 3s. Imprimante mémorisée = auto-sélectionnée au prochain usage.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `scan_status` | enum | `scanning` / `found` / `empty` / `error` |
| `devices` | list | `{name, address, signal_strength, is_preferred}` |
| `selected_device` | string? | Adresse MAC de l'appareil sélectionné |
| `on_select` | callback(device) | Sélection d'un appareil |

### Sketch ASCII

```
SCAN EN COURS (3s) :
  ┌──────────────────────────────────────────┐
  │ [↻] Recherche imprimantes Bluetooth...   │  spinner + ProgressBar 3s
  │ ██████████████░░░░░░░░░░░░░░░░░░░░░░░░  │
  └──────────────────────────────────────────┘

IMPRIMANTE TROUVÉE :
  ┌──────────────────────────────────────────┐
  │ [● ★] Epson TM-T20 · A4:B8:C1:D2 ████  │  ← préférée · signal fort
  │ [○  ] Sunmi T2 Mini · B4:C9:D3:E4 ███░  │  signal moyen
  └──────────────────────────────────────────┘
  ★ = imprimante mémorisée · signal: Roboto Mono barres

AUCUN APPAREIL :
  ┌──────────────────────────────────────────┐
  │ ⚠ Aucune imprimante trouvée             │
  │ _Activez le Bluetooth et l'imprimante_  │
  │ [  Réessayer  ]                         │
  └──────────────────────────────────────────┘

ERREUR BLUETOOTH DÉSACTIVÉ :
  ┌──────────────────────────────────────────┐
  │ ⚠ Bluetooth désactivé                   │
  │ [  Activer le Bluetooth  ]              │  → Intent Android Bluetooth settings
  └──────────────────────────────────────────┘
```
