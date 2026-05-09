---
type: tokens
token-category: colors
---

# Tokens — Couleurs

## Palette Primaire

| Token | Hex | Usage |
|-------|-----|-------|
| `color-primary-900` | `#1A3A5C` | Texte sur fond clair — titres forts |
| `color-primary-700` | `#1E5F8E` | Éléments interactifs — liens |
| `color-primary-500` | `#2980B9` | ActionButton primaire — fond |
| `color-primary-300` | `#85C1E9` | États hover / focus |
| `color-primary-100` | `#D6EAF8` | Fonds cards légères |
| `color-primary-50`  | `#EBF5FB` | Fonds sections |

## Couleurs Sémantiques

### Succès (vert)
| Token | Hex | Usage |
|-------|-----|-------|
| `color-success-700` | `#1D6A35` | Texte success |
| `color-success-500` | `#27AE60` | AlertBanner succès / SyncStatusBar synced |
| `color-success-100` | `#D5F5E3` | Fond AlertBanner succès |

### Warning (ambre)
| Token | Hex | Usage |
|-------|-----|-------|
| `color-warning-700` | `#935116` | Texte warning |
| `color-warning-500` | `#E67E22` | AlertBanner warning / StatusBadge ambre |
| `color-warning-100` | `#FDEBD0` | Fond AlertBanner warning |

### Critique (rouge)
| Token | Hex | Usage |
|-------|-----|-------|
| `color-danger-700`  | `#922B21` | Texte danger |
| `color-danger-500`  | `#E74C3C` | AlertBanner critique / stock rouge |
| `color-danger-100`  | `#FADBD8` | Fond AlertBanner critique |

### Info (bleu)
| Token | Hex | Usage |
|-------|-----|-------|
| `color-info-500`    | `#2471A3` | Info neutre |
| `color-info-100`    | `#D6EAF8` | Fond info |

## Neutres

| Token | Hex | Usage |
|-------|-----|-------|
| `color-neutral-900` | `#1A1A2E` | Texte principal |
| `color-neutral-700` | `#4A4A6A` | Texte secondaire |
| `color-neutral-500` | `#7A7A9A` | Placeholder / disabled |
| `color-neutral-300` | `#C8C8E0` | Bordures / séparateurs |
| `color-neutral-100` | `#F0F0F8` | Fonds cards |
| `color-neutral-50`  | `#F8F8FC` | Fond page |
| `color-white`       | `#FFFFFF` | Fond surface |

## Tokens d'Application

| Token | Valeur | Contexte |
|-------|--------|----------|
| `bg-page` | `color-neutral-50` | Fond global app |
| `bg-card` | `color-white` | Fond cards / composants |
| `bg-overlay` | `rgba(0,0,0,0.5)` | Fond ConfirmationDialog |
| `text-primary` | `color-neutral-900` | Corps de texte |
| `text-secondary` | `color-neutral-700` | Labels, sous-titres |
| `text-disabled` | `color-neutral-500` | États inactifs |
| `border-default` | `color-neutral-300` | Bordures inputs / cards |
| `border-focus` | `color-primary-500` | Focus ring inputs |
| `interactive-primary` | `color-primary-500` | ActionButton primaire |
| `interactive-danger` | `color-danger-500` | ActionButton destructif |

## ASCII — Représentation Couleurs dans les Sketches

```
Conventions couleur dans les ASCII sketches :
  [●] = actif / sélectionné / succès
  [○] = inactif / désélectionné
  [!] = warning / alerte ambre
  [✕] = erreur / danger rouge
  [✓] = succès / validé vert
  ███ = fond plein (bouton primaire, fond badge)
  ▓▓▓ = fond semi (hover, selected)
  ░░░ = fond léger (bg card, zone désactivée)
```
