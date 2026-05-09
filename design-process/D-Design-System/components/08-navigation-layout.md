---
type: components
group: navigation-layout
components: [AppBar, TopBar, BottomNav, SearchBar, BottomSheet]
---

# Composants — Navigation & Layout

> Composants structurels présents sur toutes les surfaces.
> Ils encadrent le contenu — ne contiennent pas de logique métier.

---

## AppBar (Mobile Android)

**Rôle :** Barre de navigation en haut de chaque vue mobile.
**Position :** Fixe en haut, sous la StatusBar Android.
**Hauteur :** 56px.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Titre de la vue (depuis JSON ou route) |
| `show_back` | bool | Affiche ← si true |
| `actions` | list | Icônes actions droite (max 2) |
| `elevation` | bool | Ombre sous l'AppBar (true par défaut) |

### Sketches ASCII

```
VUE RACINE (pas de retour) :
┌──────────────────────────────────────────────┐
│ ≡  MON MAGASIN                     [🔔] [⚙] │
└──────────────────────────────────────────────┘
  Menu burger     Titre                Actions

VUE SECONDAIRE (avec retour) :
┌──────────────────────────────────────────────┐
│ ←  NOUVELLE VENTE                      [✕]  │
└──────────────────────────────────────────────┘
  Retour          Titre                Fermer

VUE MODALE / FORMULAIRE :
┌──────────────────────────────────────────────┐
│ ←  AJOUTER UN PRODUIT                        │
└──────────────────────────────────────────────┘
```

---

## TopBar (Flutter Web PWA + Admin)

**Rôle :** Barre de navigation horizontale en haut sur Flutter Web.
**Position :** Fixe en haut — au-dessus de la sidebar et du contenu.
**Hauteur :** 64px.

### Sketches ASCII

```
FLUTTER WEB PWA :
┌────────────────────────────────────────────────────────────┐
│ [Sc] MON MAGASIN — Épicerie Aminata    [🔔 2]  Blandine ▾ │
└────────────────────────────────────────────────────────────┘
  Logo+tenant                            Notif   User menu

ADMIN SCALARIO :
┌────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                    [🔔 2]  Carlos ▾   │
└────────────────────────────────────────────────────────────┘
```

---

## BottomNav (Mobile Android)

**Rôle :** Navigation principale en bas sur mobile. Toujours visible (sauf dans les formulaires plein écran).
**Hauteur :** 56px + safe area bottom.

### Sketches ASCII par Rôle

```
OWNER (Blandine) :
┌──────────────────────────────────────────────┐
│ 🏠 Dashboard  📊 Rapports  📦 Stock  ⚙ Params│
│ [●]                                          │  ← tab active
└──────────────────────────────────────────────┘

COMMERCIAL :
┌──────────────────────────────────────────────┐
│       🏠 Dashboard           📋 Historique   │
│       [●]                                    │
└──────────────────────────────────────────────┘

MANAGER (Ibrahim) :
┌──────────────────────────────────────────────┐
│  🏠 Dashboard    📦 Stock    📋 Opérations   │
│  [●]                                         │
└──────────────────────────────────────────────┘

INTÉGRATEUR (Kofi) — Flutter Web uniquement, pas de bottom nav mobile
```

---

## SearchBar

**Rôle :** Champ de recherche textuelle — filtrage en temps réel d'une liste ou grille.
**Usage :** POS (ProductGrid), listes employés/fournisseurs, admin tenants.
**Comportement :** Focus auto à l'ouverture si la vue est dédiée à la recherche.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `placeholder` | string | Texte placeholder |
| `value` | string | Valeur courante |
| `on_change` | callback | Filtrage en temps réel (debounce 200ms) |
| `autofocus` | bool | Focus auto à l'ouverture |

### Sketches ASCII

```
REPOS :
┌──────────────────────────────────────────────┐
│ 🔍 Rechercher un article...                  │
└──────────────────────────────────────────────┘

FOCUS (avec texte) :
┌──────────────────────────────────────────────┐
│ 🔍 Tomat|                              [✕]  │  ← clear button
└──────────────────────────────────────────────┘

RÉSULTATS FILTRÉS :
┌──────────────────────────────────────────────┐
│ 🔍 Tomat                               [✕]  │
└──────────────────────────────────────────────┘
  → ProductGrid ou liste filtrée en dessous
  "2 résultats pour 'Tomat'"
```

---

## BottomSheet

**Rôle :** Panneau glissant du bas — contexte supplémentaire ou saisie sans quitter la vue.
**Usage :** Saisie quantité vrac (POS), menu contextuel, détails rapides.
**Comportement :** Swipe down ou tap overlay → dismiss. Pas de bouton retour.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Titre du panneau |
| `height` | enum | `compact` (40vh) / `medium` (60vh) / `full` (90vh) |
| `dismissible` | bool | Tap overlay ferme (true par défaut) |

### Sketches ASCII

```
COMPACT (saisie quantité vrac) :
┌──────────────────────────────────────────────┐
│ [contenu page en arrière-plan]               │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓ ┌──────────────────────────────────────┐ ▓│  ← handle bar en haut
│▓▓ │  ━━━━━━━━━━━                         │ ▓│
│▓▓ │  🍅 Tomates — Quelle quantité ?      │ ▓│
│▓▓ │                                      │ ▓│
│▓▓ │  [QuantityControl]                   │ ▓│
│▓▓ │                                      │ ▓│
│▓▓ │  = 3 750 FCFA                        │ ▓│
│▓▓ │                                      │ ▓│
│▓▓ │  [████ Ajouter au panier ████████]   │ ▓│
│▓▓ └──────────────────────────────────────┘ ▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└──────────────────────────────────────────────┘

MEDIUM (menu contextuel employé) :
│▓▓ │  ━━━━━                               │ ▓│
│▓▓ │  Kofi Mensah — COMMERCIAL            │ ▓│
│▓▓ │  ────────────────────────────────    │ ▓│
│▓▓ │  Modifier les informations           │ ▓│
│▓▓ │  Réinitialiser le mot de passe       │ ▓│
│▓▓ │  ────────────────────────────────    │ ▓│
│▓▓ │  Désactiver le compte         [rouge]│ ▓│
│▓▓ └──────────────────────────────────────┘ ▓│
```
