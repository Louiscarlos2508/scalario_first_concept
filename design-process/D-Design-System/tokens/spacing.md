---
type: tokens
token-category: spacing
---

# Tokens — Espacements & Layout

## Grille de Base : 4px

| Token | Valeur | Usage |
|-------|--------|-------|
| `space-1` | 4px | Micro — gap interne badge, icon padding |
| `space-2` | 8px | Petit — gap entre label et valeur |
| `space-3` | 12px | Moyen-petit — padding interne chip |
| `space-4` | 16px | Standard — padding card, gap entre composants |
| `space-5` | 20px | Moyen — gap section |
| `space-6` | 24px | Grand — padding page horizontal |
| `space-8` | 32px | X-large — espacement entre sections |
| `space-10` | 40px | XX-large — hauteur ActionButton |
| `space-12` | 48px | Hauteur barre navigation |
| `space-16` | 64px | Hauteur AlertBanner |

## Layout Mobile Android

| Zone | Valeur | Token |
|------|--------|-------|
| Padding horizontal page | 16px | `space-4` |
| Padding vertical page top | 16px | `space-4` |
| Gap entre cards | 12px | `space-3` |
| Gap entre sections | 24px | `space-6` |
| Hauteur ActionButton primaire | 48px | `space-12` |
| Hauteur ActionButton secondaire | 40px | `space-10` |
| Hauteur input | 48px | `space-12` |
| Hauteur chip | 32px | `space-8` |
| Hauteur ligne liste | 56px | 56px |
| Hauteur AlertBanner | 48–64px | flexible |
| Hauteur SyncStatusBar | 28px | 28px |
| Hauteur barre navigation bottom | 56px | 56px |
| Safe area bottom (Android) | 16px | `space-4` |

## Layout Flutter Web PWA (Desktop)

| Zone | Valeur |
|------|--------|
| Max width contenu | 1200px |
| Padding horizontal page | 32px |
| Grille colonnes | 12 colonnes — gap 16px |
| Sidebar navigation | 240px fixe |
| Contenu principal | fluid |
| Dashboard OWNER grille | 3 colonnes |
| Dashboard admin grille | 2–4 colonnes |

## Border Radius

| Token | Valeur | Usage |
|-------|--------|-------|
| `radius-sm` | 4px | Chips, badges, inputs |
| `radius-md` | 8px | Cards, boutons |
| `radius-lg` | 12px | Modals, bottom sheets |
| `radius-xl` | 16px | AlertBanner |
| `radius-full` | 999px | Pills, avatars ronds |

## Élévations / Shadows

| Token | Shadow | Usage |
|-------|--------|-------|
| `elevation-0` | none | Fond plat |
| `elevation-1` | `0 1px 3px rgba(0,0,0,0.08)` | Cards |
| `elevation-2` | `0 2px 8px rgba(0,0,0,0.12)` | ActionButton |
| `elevation-3` | `0 4px 16px rgba(0,0,0,0.16)` | ConfirmationDialog |
| `elevation-4` | `0 8px 24px rgba(0,0,0,0.20)` | Bottom sheets |

## ASCII — Représentation Layout dans les Sketches

```
Mobile (360px) — largeur ASCII : ~44 chars entre bordures
┌──────────────────────────────────────────┐  ← 360px
│ padding 16px                             │
│  ┌──────────────────────────────────┐    │  ← card elevation-1
│  │                                  │    │
│  └──────────────────────────────────┘    │
│ gap 12px                                 │
│  ┌──────────────────────────────────┐    │
└──────────────────────────────────────────┘

Flutter Web (1200px) — grille 3 colonnes :
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Col 1/3    │  │  Col 2/3    │  │  Col 3/3    │
└─────────────┘  └─────────────┘  └─────────────┘
```
