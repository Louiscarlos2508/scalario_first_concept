---
type: tokens
token-category: typography
---

# Tokens — Typographie

## Famille

**Font principale :** Inter (Google Fonts)
**Fallback :** system-ui, -apple-system, sans-serif
**Langue :** Français — UTF-8 — chiffres FCFA avec séparateur espace insécable

## Échelle Typographique

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `text-display` | 28sp | 700 Bold | 1.2 | KPICard valeur principale |
| `text-headline` | 22sp | 600 SemiBold | 1.3 | Titres de page / section |
| `text-title` | 18sp | 600 SemiBold | 1.3 | Titres composants |
| `text-body-lg` | 16sp | 400 Regular | 1.5 | Corps de texte principal |
| `text-body` | 14sp | 400 Regular | 1.5 | Corps standard / labels |
| `text-body-medium` | 14sp | 500 Medium | 1.5 | Labels actifs / valeurs |
| `text-caption` | 12sp | 400 Regular | 1.4 | Métadonnées / timestamps |
| `text-caption-medium` | 12sp | 500 Medium | 1.4 | Labels chips / badges |
| `text-overline` | 11sp | 500 Medium | 1.2 | Catégories / sections (uppercase) |

## Tokens d'Application

| Token | Valeur | Contexte |
|-------|--------|----------|
| `font-kpi-value` | `text-display` | Valeur numérique KPICard |
| `font-kpi-label` | `text-caption` | Label sous la valeur KPICard |
| `font-kpi-delta` | `text-caption-medium` | Variation vs hier (+12%) |
| `font-button` | `text-body-medium` | Label ActionButton |
| `font-input-label` | `text-caption-medium` | Label champ au-dessus |
| `font-input-value` | `text-body` | Valeur saisie |
| `font-input-hint` | `text-caption` | Placeholder / hint |
| `font-banner-text` | `text-body-medium` | Texte AlertBanner |
| `font-list-primary` | `text-body-medium` | Ligne principale liste |
| `font-list-secondary` | `text-caption` | Ligne secondaire liste |
| `font-section-title` | `text-title` | Titre de section |
| `font-page-title` | `text-headline` | Titre de page |

## Formatage Nombres

| Contexte | Format | Exemple |
|----------|--------|---------|
| Montants FCFA | `xxx xxx FCFA` | `12 500 FCFA` |
| KPICard valeur | `xxx xxx` (unité séparée) | `12 500` + label `FCFA` |
| Variations | `+X%` / `−X%` | `+12%` / `−3%` |
| Poids vrac | `X,X kg` | `4,5 kg` |
| Dates | `JJ/MM` ou `JJ MMM` | `09/05` ou `9 mai` |
| Heures | `HH:MM` | `19:30` |

## ASCII — Représentation Typo dans les Sketches

```
Conventions typographiques ASCII :
  TITRE          = text-headline (majuscules dans ASCII)
  Titre section  = text-title (casse normale, gras symbolisé)
  Corps texte    = text-body (casse normale)
  note / hint    = text-caption (italique symbolisé avec _underscores_)
  12 500 FCFA    = montant formaté avec espace insécable simulé
```
