# Scalario Design System

## Design Philosophy

Scalario serves merchants in West Africa. The UI must handle:
- Users with varying tech literacy (some use smartphones daily, some barely)
- Bright outdoor environments (markets, shop fronts)
- Touch-first devices (Android tablets for POS)
- Intermittent connectivity
- French as primary language

### Core Principles

1. **Gros et clair** — Big buttons, big text, high contrast
2. **2 taps maximum** — Any frequent action reachable in 2 taps (Rule of 3 Clicks)
3. **Pas de surprise** — Confirm destructive actions, show clear feedback
4. **Ça marche sans internet** — Offline indicators, never block on network
5. **Français d'abord** — All labels and messages in French by default
6. **Feedback systématique** — Every action has a visible reaction (loading, vibration, color change)

---

## UX Laws — Applied to Every Screen

These laws are mandatory design constraints. Every screen, widget, and interaction
must respect them. When reviewing UI code, check against these laws.

### Loi de Jakob (Familiarity)

Users spend most of their time on OTHER apps. Don't reinvent standard patterns:
- Search icon = magnifying glass (always)
- Cart/basket = top right or side panel (always)
- Back = arrow top left (always)
- Swipe to delete, pull to refresh — standard gestures
- Bottom sheet for options on mobile
- If Fatou uses WhatsApp and Facebook daily, Scalario must feel that familiar

**Rule:** Before designing any interaction, ask: "How does WhatsApp/Facebook do this?"
If there's a standard pattern, use it. Originality in interaction design = confusion.

### Loi de Hick (Fewer Choices = Faster Decisions)

More options = longer decision time = frustrated user. Apply everywhere:
- POS product grid: show categories first, products second (two-step drill-down)
- Payment screen: max 3 payment methods visible (Cash, Mobile Money, Credit)
- Navigation rail: max 5-7 items visible, overflow in "Plus"
- Forms: only show fields relevant to the current step
- Menus: max 7 items per level, group with separators

**Rule:** If a screen shows more than 7 actionable items at once, it needs restructuring.

### Loi de Fitts (Big Targets, Close to Thumb)

Important targets must be large AND close to where the finger naturally rests:
- Primary action buttons: minimum 48x48px (Material standard), prefer 56px+
- POS "Encaisser" button: largest element on screen, bottom-right of cart panel
- Delete/destructive actions: smaller and further from primary action (prevent accidents)
- On tablet (landscape): primary actions on the right side (right-hand dominant)
- On phone (portrait): primary actions at bottom center (thumb zone)

**Thumb Zone Map (phone portrait):**
```
┌─────────────────┐
│   Hard to reach  │  ← Menu, settings, non-critical info
│                  │
│  OK to reach     │  ← Content, lists, secondary actions
│                  │
│  Easy to reach   │  ← PRIMARY ACTIONS HERE
│  (thumb zone)    │  ← Navigation, confirm, main CTA
└─────────────────┘
```

**Thumb Zone Map (tablet landscape — right hand holds):**
```
┌──────────────────────────────────────┐
│                        │  Easy zone  │
│  Content / browsing    │  (right     │
│                        │  thumb)     │
│                        │  PRIMARY    │
│                        │  ACTIONS    │
└──────────────────────────────────────┘
```

### Loi de Proximité (Grouping)

Elements close together are perceived as belonging to the same group:
- Group related fields in forms (personal info together, address together)
- Group action buttons together (Save + Cancel side by side)
- Separate unrelated sections with whitespace (min 16px) or dividers
- In POS cart: item + quantity + price on the same line, total separated below
- In reports: KPIs grouped by theme (revenue together, stock together)

**Rule:** If two elements are related, they must be within 8px of each other.
If they are unrelated, they must be at least 24px apart.

### Loi de Miller (7 ± 2 Items)

Working memory holds 7 ± 2 items. Don't overwhelm:
- Dashboard KPIs: max 6 cards visible without scrolling
- Category tabs: max 7 visible, scroll for more
- Report tables: max 7 columns visible (scroll or collapse for more)
- Dropdown lists: if > 10 items, add a search/filter

---

## Color System

### Palette Principale — Rule 60-30-10

Apply the 60-30-10 rule for visual harmony:
- **60% Dominant** (neutral): `#F5F5F5` background + `#FFFFFF` surfaces
- **30% Secondary** (structure): `#212121` text + `#757575` secondary text + `#E0E0E0` borders
- **10% Accent** (action): `#1565C0` primary blue for CTAs, links, active states

```
Primaire:     #1565C0 (Bleu confiance — actions principales, CTA, links)
Succès:       #2E7D32 (Vert — confirmations, synchronisé, validated)
Erreur:       #C62828 (Rouge — erreurs, alertes, pertes, destructive)
Attention:    #F9A825 (Jaune — en attente, sync pending, warnings)
Surface:      #FFFFFF (Cartes, modales, input fields)
Fond:         #F5F5F5 (Fond app — 60% dominant)
Texte:        #212121 (Texte principal — high contrast)
Texte léger:  #757575 (Texte secondaire — WCAG AA compliant on white)
Bordures:     #E0E0E0 (Séparations subtiles)
```

**Contrast Requirements (WCAG AA minimum):**
- Text on white: minimum contrast ratio 4.5:1
- Text on colored backgrounds: always use white text on dark colors
- Large text (18sp+): minimum ratio 3:1
- Bright outdoor use: prefer darker text colors, avoid light gray on white

### Couleurs Verticales

Each vertical has a subtle accent in the navigation rail:

```
Retail (Boutique):  #1565C0 (Bleu)
Pharmacy (futur):   #2E7D32 (Vert)
School (futur):     #6A1B9A (Violet)
Enterprise (futur): #E65100 (Orange)
```

### Code Couleur Fraîcheur (Vertical Grocery)

```
🟢 Vert:   Frais — date OK, stock normal
🟠 Orange: Attention — proche expiration, vendre en priorité
🔴 Rouge:  Urgent — dernière chance, promo flash ou déclasser
⚫ Gris:   Expiré — à déclarer en perte
```

---

## Typography

### Hierarchy Rules

Use size, weight, and color to create clear visual hierarchy.
The most important information must catch the eye first.

```
Titre principal:  22sp / Bold / #212121
Titre section:    18sp / SemiBold / #212121
Titre carte:      16sp / SemiBold / #212121
Corps:            14sp / Regular / #212121
Corps petit:      12sp / Regular / #757575
Étiquette:        11sp / Medium / #757575 / MAJUSCULES
Prix:             20sp / Bold / Monospace / #212121
Quantité:         18sp / Bold / Monospace / #212121
```

**Rules:**
- Maximum 2 font families (system font + monospace for numbers)
- System fonts only: Roboto (Android), Segoe UI (Windows), sans-serif (Web)
- Line height: 1.4x font size for body, 1.2x for headings
- Consistent spacing between all text elements

---

## Components

### Interaction Feedback Rules (Apply to ALL Components)

Every user action MUST produce visible feedback. No silent interactions.

| Action | Feedback | Timing |
|--------|----------|--------|
| Tap a button | Ripple effect + slight scale | Immediate (<50ms) |
| Add item to cart | Item animation to cart + haptic | <100ms |
| Complete a sale | Green checkmark + haptic | <200ms |
| Delete/remove | Item slides out + subtle vibration | <200ms |
| Loading data | Skeleton shimmer (not spinner) | Show after 300ms |
| Form error | Red border + error text below | Immediate |
| Successful save | Green toast "Enregistré ✓" | 2 seconds visible |
| Error | Red dialog with simple explanation | Until dismissed |
| Offline change | Subtle indicator color change | Immediate |

### POS — Écran de Vente

Layout tablette (10" paysage):

```
┌──────────────────────────────────────────────────┐
│ [Barre supérieure: Nom boutique | Caissier | ●🟢] │
├────────────────────────────┬─────────────────────┤
│                            │                     │
│   GRILLE PRODUITS          │   PANIER            │
│   (3-4 colonnes)           │                     │
│                            │   Produit 1  2x 500 │
│   [🍅 Tomate]  [🧅 Oignon] │   Produit 2  1x 300 │
│   [🌶 Piment]  [🧄 Ail]    │   Produit 3  3x 150 │
│   [🥬 Laitue]  [🥕 Carotte]│                     │
│                            │   ─────────────     │
│   [Catégories en haut]     │   TOTAL: 1 750 F    │
│                            │                     │
│                            │  [  ENCAISSER  ]    │
│                            │  (gros bouton vert) │
├────────────────────────────┴─────────────────────┤
│ [🔍 Recherche produit]  [📊 Historique] [⚙️ Plus] │
└──────────────────────────────────────────────────┘
```

- Product card: min 90x90px, image/initial + name + price
- "Encaisser": LARGEST element (Fitts), bottom-right (thumb zone)
- Cart always visible on right (Jakob)
- Total always visible, large, bold
- Categories as horizontal tabs (Hick: filter before browse)
- Max 12 products visible (Miller)

### Pavé Numérique

```
┌─────────────────────┐
│     [ 1.500 F ]     │  ← 24sp, monospace, centered
├─────┬─────┬─────────┤
│  7  │  8  │    9    │
├─────┼─────┼─────────┤
│  4  │  5  │    6    │
├─────┼─────┼─────────┤
│  1  │  2  │    3    │
├─────┼─────┼─────────┤
│  .  │  0  │   ←     │
├─────┴─────┴─────────┤
│    [ VALIDER ✓ ]    │  ← Green, full width, 64px (Fitts)
└─────────────────────┘
```

Buttons: min 56px, haptic on every press.

### Empty States

Never show blank screens. Always: icon + message + action button.

### Loading States

Skeleton shimmer screens (not spinners). Show after 300ms delay.

### Dialogues de Confirmation

For critical actions: always show summary of what happens, destructive button on RIGHT, cancel on LEFT.

---

## Navigation

### Rail (tablet/desktop) — max 7 items (Miller)

Show only activated modules. Icons + short labels. Active = colored background.

### Bottom Nav (phone) — max 5 items (Hick)

Icons + labels always visible (Jakob). Overflow "Plus ⋯".

### Consistency Rule

Same button style, same icon meaning, same color coding, same placement on EVERY screen.

---

## Multi-Platform Adaptive Behavior

Scalario is a single Flutter codebase targeting 4 platforms. Each platform has different
constraints. The rule: **one codebase, adaptive layouts** — not separate UIs per platform.

### Platform Matrix

| Platform | Device | Primary User | Input | Offline | Priority |
|----------|--------|-------------|-------|---------|----------|
| Android Tablet | 10" POS | Fatou (caissière), Moussa (gestionnaire) | Touch | Obligatoire | Phase 1 — PRIMARY |
| Android Phone | 5-6.5" | Blandine (propriétaire), Serge (DG) | Touch | Obligatoire | Phase 1 |
| Windows Desktop | 13"+ | Moussa (inventaire), Ibrahim (comptable) | Souris + clavier | Souhaité | Phase 2 |
| iOS (iPhone/iPad) | Variable | Serge (DG), propriétaires premium | Touch | Obligatoire | Phase 2+ |
| Web (navigateur) | Variable | Carlos (admin), propriétaires | Souris + clavier | Non | Phase 3 |

### Responsive Layout Strategy

Flutter uses `LayoutBuilder` + breakpoints to adapt. The SAME screen code
renders differently based on available width:

```
┌─────────────────────────────────────────────────────────┐
│  compact (< 600px) — Phone                              │
│  → Single column, bottom nav, full-screen modals        │
│  → Cart = separate screen (not side panel)              │
│  → Forms = full width, one field per row                │
│  → Dashboard = vertical scroll of cards                 │
├─────────────────────────────────────────────────────────┤
│  medium (600-1024px) — Tablet                           │
│  → Split view (product grid | cart side panel)          │
│  → Navigation rail on left                              │
│  → Forms = 2 columns for related fields                 │
│  → Dashboard = 2x3 grid of KPI cards                   │
├─────────────────────────────────────────────────────────┤
│  expanded (> 1024px) — Desktop / Large tablet           │
│  → Three-panel layout (nav | content | detail)          │
│  → Navigation rail expanded with labels                 │
│  → Forms = multi-column with inline validation          │
│  → Dashboard = full grid with charts                    │
└─────────────────────────────────────────────────────────┘
```

**Implementation pattern in Flutter:**
```dart
Widget build(BuildContext context) {
  return LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth < 600) return CompactLayout();
    if (constraints.maxWidth < 1024) return MediumLayout();
    return ExpandedLayout();
  });
}
```

### POS Screen Adaptation (Critical)

The POS is the most-used screen. It MUST work well on all sizes:

**Tablet (medium — primary POS device):**
```
┌────────────────────────────┬─────────────────────┐
│   GRILLE PRODUITS          │   PANIER             │
│   (3-4 colonnes)           │   (always visible)   │
│                            │   TOTAL + ENCAISSER  │
└────────────────────────────┴─────────────────────┘
```

**Phone (compact — Blandine checking sales remotely):**
```
┌─────────────────────┐    ┌─────────────────────┐
│   GRILLE PRODUITS    │    │   PANIER             │
│   (2 colonnes)       │ ←→ │   (separate screen)  │
│                      │    │   TOTAL + ENCAISSER  │
│   [🛒 Panier (3)]   │    │   [← Retour]         │
└─────────────────────┘    └─────────────────────┘
         Tab 1                      Tab 2
```

**Desktop (expanded — back-office view with extra info):**
```
┌──────┬─────────────────────────┬─────────────────────┐
│ NAV  │   GRILLE PRODUITS       │   PANIER             │
│ RAIL │   (5-6 colonnes)        │   + client sélectionné│
│      │                         │   + historique récent  │
│      │                         │   TOTAL + ENCAISSER   │
└──────┴─────────────────────────┴─────────────────────┘
```

### Phone-Specific Adaptations

When the app detects compact width (< 600px):

- **Bottom navigation** replaces left rail (5 items max)
- **Full-screen modals** replace side sheets and dialogs
- **Cart becomes a separate screen** with a floating badge on the product grid showing item count
- **Forms go single-column** — one field per row, large touch targets
- **Tables become cards** — data tables unstack into scrollable card lists
- **Swipe gestures enabled** — swipe left to delete, swipe between tabs
- **Pull-to-refresh** on all list screens
- **Floating Action Button (FAB)** for primary create action (bottom-right, 56px)

**Phone navigation pattern:**
```
┌─────────────────────┐
│  [←] Titre page     │  ← AppBar with back button
│                      │
│  Content area        │
│  (scrollable)        │
│                      │
│                [+]   │  ← FAB for primary action
├─────────────────────┤
│ 🏪  📦  💰  📊  ⋯  │  ← Bottom nav (max 5)
└─────────────────────┘
```

### Desktop-Specific Adaptations (Windows / Web)

When mouse + keyboard input is detected:

- **Hover states** on all interactive elements (buttons, cards, table rows)
- **Right-click context menus** on table rows (Modifier, Supprimer, Détails)
- **Keyboard shortcuts** for power users (see table below)
- **Tooltip on hover** for icon buttons (shows the label after 500ms)
- **Mouse cursor changes** — pointer on clickable, text on editable, grab on draggable
- **Scrollbars visible** (not hidden like on touch) — standard platform scrollbars
- **Multi-select in tables** — Ctrl+click for individual, Shift+click for range
- **Focus ring visible** — 2px blue outline on focused element (keyboard navigation)
- **Tab order** follows logical flow (left-to-right, top-to-bottom)

**Keyboard Shortcuts (Desktop / Web):**

| Shortcut | Action | Context |
|----------|--------|---------|
| `Ctrl+N` | Nouvelle vente | POS screen |
| `Ctrl+F` | Rechercher produit | POS, Catalogue, Stock |
| `Ctrl+Enter` | Encaisser / Valider | POS cart, Forms |
| `Ctrl+S` | Enregistrer | Any form |
| `Escape` | Annuler / Fermer modal | Everywhere |
| `Ctrl+P` | Imprimer reçu | POS after sale |
| `F5` | Rafraîchir données | Dashboard, Reports |
| `Ctrl+Z` | Annuler dernière action | Where applicable |
| `Tab` | Champ suivant | Forms |
| `Shift+Tab` | Champ précédent | Forms |
| `↑ / ↓` | Naviguer dans la liste | Tables, dropdowns |
| `Enter` | Sélectionner item | Tables, dropdowns |

**Implementation in Flutter:**
```dart
// Global shortcuts via Shortcuts + Actions widgets
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
      NewSaleIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
      SearchProductIntent(),
  },
  child: Actions(
    actions: { NewSaleIntent: CallbackAction(...) },
    child: child,
  ),
)
```

### iOS Considerations (Phase 2+)

Flutter renders Material Design by default on all platforms. For iOS:

**DO use Material Design (not Cupertino):**
- Scalario is a business tool, not a consumer app — consistency across platforms > native feel
- Training cost: users who learn on Android tablet must recognize the same UI on iPhone
- Maintenance cost: one widget set instead of two
- Exception: date pickers and time pickers → use `showDatePicker()` which adapts natively

**iOS-specific adjustments (within Material):**
- **Safe area insets** — always wrap with `SafeArea` (notch, Dynamic Island, home indicator)
- **Bottom padding** — add 34px bottom padding on iPhone X+ for home indicator area
- **Scroll physics** — use `BouncingScrollPhysics` on iOS (default ClampingScrollPhysics on Android)
- **Status bar** — light text on dark header backgrounds (set `SystemUiOverlayStyle`)
- **Haptic feedback** — use `HapticFeedback.lightImpact()` on iOS (matches Taptic Engine)
- **Text selection** — iOS handles show selection handles natively, don't override
- **Pull-to-refresh** — `CupertinoSliverRefreshControl` feels more native on iOS than Material's

**iOS App Store requirements to remember:**
- App must work fully offline (already by design)
- No references to "Android" or "Google Play" in the UI
- Privacy labels must match data collected (audit logs = "Usage Data")

### Platform Detection in Flutter

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum ScalarioPlatform { androidTablet, androidPhone, ios, desktop, web }

ScalarioPlatform detectPlatform(BuildContext context) {
  if (kIsWeb) return ScalarioPlatform.web;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    return ScalarioPlatform.desktop;
  if (Platform.isIOS) return ScalarioPlatform.ios;

  // Android: distinguish phone vs tablet by screen width
  final width = MediaQuery.of(context).size.shortestSide;
  return width >= 600
    ? ScalarioPlatform.androidTablet
    : ScalarioPlatform.androidPhone;
}
```

Use this to conditionally enable:
- Haptic feedback type (Android vibration vs iOS Taptic Engine)
- Scroll physics (Clamping vs Bouncing)
- Keyboard shortcut registration (desktop/web only)
- Context menus (right-click on desktop, long-press on mobile)

### Input Adaptation Rules

| Feature | Touch (Mobile/Tablet) | Mouse + Keyboard (Desktop/Web) |
|---------|----------------------|-------------------------------|
| Primary action | Large button in thumb zone | Button + keyboard shortcut |
| Secondary actions | Bottom sheet / Action sheet | Context menu (right-click) |
| Selection | Tap to select, long-press for multi | Click, Ctrl+click, Shift+click |
| Search | Tap magnifier → full-screen input | Ctrl+F → inline search bar |
| Scroll | Touch scroll, pull-to-refresh | Mouse wheel, scrollbar, PgUp/PgDn |
| Numeric input | Custom numpad (Scalario pavé) | Native keyboard input |
| Drag & drop | Long-press + drag | Click + drag (with grab cursor) |
| Hover | N/A | Highlight row, show tooltip |
| Form navigation | Tap next field | Tab / Shift+Tab |

---

## Accessibility (A11y)

- Contrast: WCAG AA (4.5:1 body, 3:1 large text)
- Touch targets: min 48x48px
- Semantic labels on all icon buttons
- Font scaling handles 1.5x without breaking
- Color never sole indicator — always pair with icon or text

---

## Design Review Checklist

Before any screen is done, verify:

- [ ] **Fitts:** Primary action is largest and in thumb zone
- [ ] **Hick:** Max 7 actionable items visible
- [ ] **Jakob:** Patterns match standard apps
- [ ] **Proximity:** Related grouped, unrelated spaced
- [ ] **Miller:** Lists/grids don't overwhelm
- [ ] **60-30-10:** Color balance correct
- [ ] **Feedback:** Every tap produces visible reaction
- [ ] **Contrast:** Readable in bright outdoor light
- [ ] **Touch targets:** All interactive elements ≥ 48px
- [ ] **Consistency:** Matches rest of app
- [ ] **Empty state:** Icon + message + action
- [ ] **Loading:** Skeleton screens
- [ ] **Offline:** Works without internet
- [ ] **French:** All text in French
- [ ] **Confirmation:** Destructive actions require dialog
- [ ] **Responsive:** Layout adapts to compact / medium / expanded breakpoints
- [ ] **Phone:** Cart on separate screen, bottom nav, single-column forms
- [ ] **Desktop:** Hover states, keyboard shortcuts, right-click menus
- [ ] **iOS safe area:** SafeArea wrapper, bottom padding for home indicator
- [ ] **Input mode:** Touch targets on mobile, hover/focus on desktop
