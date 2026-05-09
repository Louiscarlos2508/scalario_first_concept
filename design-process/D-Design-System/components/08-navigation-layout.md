---
type: components
group: navigation-layout
components: [AppBar, TopBar, BottomNav, SearchBar, BottomSheet, MiniTopBar, Breadcrumb]
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

**Rôle :** Barre de navigation principale sur Flutter Web — contient à la fois le branding et les items de navigation.
**Position :** Fixe en haut — couvre toute la largeur.
**Hauteur :** 64px.
**Pattern desktop :** TopBar + nav horizontale uniquement. **Pas de sidebar** — max 6 items de navigation OWNER ; la horizontale tient à 1280px. La sidebar n'est pas utilisée dans Scalario PWA.

### Structure TopBar

```
FLUTTER WEB PWA — OWNER (Blandine) :
┌────────────────────────────────────────────────────────────────────────────────┐  64px
│ [Sc] MON MAGASIN — Blandine   Dashboard  Catalogue  Historique  Équipe  ⚙️   │
│  Logo + tenant                ←───── navigation horizontale ─────→    User/Notif│
└────────────────────────────────────────────────────────────────────────────────┘

  Zone 1 (gauche)  : Monogramme [Sc] + nom magasin + nom utilisateur
  Zone 2 (centre)  : Tabs de navigation (depuis JSON rôle) — inter 14sp 500
  Zone 3 (droite)  : 🔔 NotificationBadge + user profile (avatar ou initiales)

FLUTTER WEB PWA — INTÉGRATEUR (Kofi — config tenant) :
┌────────────────────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO                 Tenants    Déploiements    Templates    ⚙️       │
└────────────────────────────────────────────────────────────────────────────────┘

ADMIN SCALARIO (Carlos) :
┌────────────────────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN           Tenants    Configs    Billings    Support    ⚙️  │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `tenant_name` | string | Nom du magasin (depuis JSON) |
| `user_name` | string | Prénom de l'utilisateur |
| `nav_items` | list | Items de navigation depuis JSON rôle (max 6) |
| `active_route` | string | Route active — tab surlignée |
| `notification_count` | int | Badge 🔔 (0 = pas de badge) |

### Tokens

```
topbar-bg          : color-white
topbar-border-b    : 1px color-neutral-100
topbar-height      : 64px
topbar-shadow      : elevation-1

logo-monogram      : "Sc" Inter 18sp 700 color-neutral-900
logo-tenant        : Inter 14sp 500 color-neutral-700
logo-user          : "— Blandine" Inter 14sp 400 color-neutral-500

nav-tab            : Inter 14sp 500 color-neutral-500
nav-tab-active     : Inter 14sp 600 color-neutral-900
nav-tab-indicator  : 2px color-primary-500 en bas du tab actif
nav-tab-hover      : bg color-neutral-50 radius-md

user-zone          : 🔔 [count] + initiales avatar 32px bg color-primary-100
```

### Règles navigation par rôle (web)

| Rôle | Items nav web |
|------|--------------|
| OWNER | Dashboard · Catalogue · Historique · Équipe · Paramètres |
| OWNER + rapports | Dashboard · Catalogue · Rapports · Historique · Équipe · Paramètres |
| INTÉGRATEUR | Tenants · Déploiements · Templates · Paramètres |
| ADMIN | Tenants · Configs · Billings · Support · Paramètres |

---

## Breadcrumb (Flutter Web uniquement)

**Rôle :** Indique la position dans la hiérarchie — permet de revenir à n'importe quel niveau par tap.
**Position :** Sous le TopBar, dans la zone de contenu — première ligne de la page.
**Usage :** Pages secondaires uniquement — pas affiché sur les vues racines (Dashboard, Catalogue, etc.)
**Mobile :** Pas de breadcrumb — le retour se fait via la flèche ← dans l'AppBar.

### Règle d'affichage

```
Page racine (Dashboard, Catalogue, Équipe...) :
  → Pas de breadcrumb — le titre de page suffit

Page secondaire (Nouveau produit, Modifier employé, Rapport semaine...) :
  → Breadcrumb : PARENT › PAGE COURANTE

Page tertiaire (Drill-down dans rapport...) :
  → Breadcrumb : PARENT › SOUS-PAGE › DÉTAIL
  Maximum 3 niveaux — au-delà, tronquer le début
```

### Sketches ASCII

```
PAGE SECONDAIRE (formulaire, création) :
┌────────────────────────────────────────────────────────────────────────────────┐
│  [Sc] MON MAGASIN — Blandine   Dashboard  Catalogue  Historique  Équipe  ⚙️  │  TopBar
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  CATALOGUE  ›  NOUVEAU PRODUIT                                                 │  Breadcrumb
│                                                                                │
│  [contenu de la page]                                                          │
└────────────────────────────────────────────────────────────────────────────────┘

PAGE TERTIAIRE (drill-down) :
│  HISTORIQUE  ›  RAPPORT SEMAINE  ›  VENTES                                     │  3 niveaux max

PAS DE BREADCRUMB (vue racine) :
│  CATALOGUE PRODUITS · 11 produits actifs           [+ Ajouter un produit]      │  titre seul
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `items` | list\<string\> | Segments du chemin (ex: ["Catalogue", "Nouveau produit"]) |
| `on_tap` | callback(index) | Navigation vers le niveau tappé |

### Tokens

```
breadcrumb-item       : Inter 13sp 500 color-neutral-500
breadcrumb-item-tap   : hover underline color-primary-600 (tappable)
breadcrumb-active     : Inter 13sp 600 color-neutral-900 (dernière page — non tappable)
breadcrumb-separator  : "›" Inter 13sp 400 color-neutral-300 · margin H-6
breadcrumb-height     : 32px · margin-bottom 12px
```

### Règle flèche ← sur web

**La flèche ← n'est PAS utilisée sur web.** Le breadcrumb remplace la navigation retour.
- Mobile : AppBar avec ← (tap = back)
- Web : Breadcrumb avec lien tappable (tap PARENT = back)

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
│  🛒 Vente    🏠 Dashboard    📋 Historique   │
│              [●]                             │
└──────────────────────────────────────────────┘
Note : 🛒 Vente = raccourci direct vers le POS (S02) — 1 tap depuis n'importe où.

MANAGER (Ibrahim) :
┌──────────────────────────────────────────────┐
│  🏠 Dashboard    📦 Stock    📋 Opérations   │
│  [●]                                         │
└──────────────────────────────────────────────┘

INTÉGRATEUR (Kofi) — Flutter Web uniquement, pas de bottom nav mobile
```

---

## MiniTopBar

**Rôle :** Barre d'en-tête compacte mobile — version réduite du TopBar pour les écrans où le contexte tenant + utilisateur doit être visible sans occuper toute la hauteur d'une AppBar standard.
**Usage :** S20.1 (Dashboard Owner mobile), S21.1 (Dashboard Commercial mobile), S22.1 (Dashboard Manager mobile).
**Règle :** Hauteur 48px (vs 56px AppBar). Pas de flèche retour — toujours sur une vue racine. Pas d'actions icônes (celles-ci vont dans le BottomNav ou les ActionButtons). Monogramme [Sc] + nom tenant à gauche, salutation + prénom à droite.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `tenant_name` | string | Nom du magasin (depuis config JSON) |
| `user_greeting` | string | Salutation dynamique ("Bonjour", "Bon après-midi"…) |
| `user_name` | string | Prénom de l'utilisateur |

### Tokens

| Élément | Token | Valeur |
|---------|-------|--------|
| Fond | `color-white` | + border-b 1px color-neutral-100 |
| Hauteur | — | 48px |
| Monogramme [Sc] | `font-logo` | Inter 14sp 700 color-neutral-900 |
| Nom tenant | `text-body-sm` | Inter 13sp 500 color-neutral-700 |
| Salutation | `text-caption` | Inter 12sp 400 color-neutral-500 |
| Prénom | `text-caption` | Inter 12sp 600 color-neutral-800 |

### Sketch ASCII

```
MOBILE (48px) :
┌──────────────────────────────────────────────┐  48px
│ [Sc] Boutique Kouamé      Bonjour, Blandine  │
└──────────────────────────────────────────────┘
  ← gauche : monogramme + tenant               → droite : salutation + prénom

COMMERCIAL (matin) :
┌──────────────────────────────────────────────┐
│ [Sc] Boutique Kouamé    Bonjour, Ibrahim     │
└──────────────────────────────────────────────┘

MANAGER (après-midi) :
┌──────────────────────────────────────────────┐
│ [Sc] Boutique Kouamé    Bon après-midi, Kofi │
└──────────────────────────────────────────────┘

Salutation dynamique :
  Avant 12h00  → "Bonjour,"
  12h00–17h30  → "Bon après-midi,"
  Après 17h30  → "Bonne soirée,"
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
