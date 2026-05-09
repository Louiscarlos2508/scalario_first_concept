---
stepsCompleted: ['step-20-visual-init', 'step-21-existing-brand', 'step-22-references', 'step-23-design-style', 'step-24-layout-effects', 'step-25-imagery', 'step-26-create-visual-document']
project: scalario
lastUpdated: 2026-05-09
status: complete
---

# Visual Direction: Scalario

> Brand Aesthetics & Design Guidelines

**Created:** 2026-05-09
**Author:** Carlos Simporé
**Related:** [Product Brief](./project-brief.md) | [Content & Language](./content-language.md) | [Inspiration Analysis](./inspiration-analysis.md)

---

## Summary: Visual DNA

```
Style:       Material Design 3 flat · Service Center aesthetic
Colors:      Dark-first #121212 + 4 accents logo · Dual dark/light mode
Typography:  Bebas Neue (display) · Inter (UI) · Roboto Mono (données)
Mood:        Confiant · Direct · Dense · Terrain · Lisible
Key Element: Action primaire du rôle toujours visible — zero learning curve
```

---

## Existing Brand Assets

Scalario dispose d'une identité visuelle définie — not a blank canvas.

| Asset | Status | Location | Décision |
|-------|--------|----------|----------|
| Logo monogramme (dark) | Existant — SVG | `assets/images/scalario-monogram-dark.svg` | Keep |
| Logo wordmark (dark) | Existant — SVG | `assets/images/scalario-wordmark-dark.svg` | Keep |
| Palette couleurs | Documentée — hex | Product Brief | Keep |
| Typographie | Documentée | Product Brief | Keep |
| Versions light | Non existant | — | Create (phase design) |
| PNG exports | Non existant | — | Create (phase design) |
| Imagery / photos | Non existant | — | Create (phase design) |

### Contraintes de marque

- Monogramme = **Sc** toujours — jamais S seul
- Jamais monogramme + wordmark ensemble sur le même support
- Dark-first — versions light à créer, non prioritaires Phase 1
- Aucune contrainte partenaire / franchise / affiliation

---

## Visual References

### Sites d'inspiration

**[Airbnb](https://www.airbnb.com)**
- Ce qu'on retient : hiérarchie visuelle immédiate, cards lisibles, action primaire toujours visible
- Pertinence : modèle de clarté — l'utilisateur sait quoi faire en 3 secondes

**[Uber](https://www.uber.com)**
- Ce qu'on retient : minimalisme radical, un seul CTA dominant, mobile-first absolu, état système toujours visible
- Pertinence : un rôle = une action primaire évidente — le commercial voit "Nouvelle vente" comme le rider voit "Commander"

**[Binance](https://www.binance.com)**
- Ce qu'on retient : dark-first assumé, data-dense sans chaos, couleur comme signal (vert/rouge), chiffres grands / contexte petit
- Pertinence : modèle pour le dashboard Blandine — beaucoup de données, zéro confusion

### Références négatives (à éviter)

- **ERP classiques** (SAP, Sage, Odoo) — denses pour de mauvaises raisons, hiérarchie absente, jargon partout
- **Designs feature-first** — sacrifient l'UX pour la completeness fonctionnelle
- **Inconsistance inter-modules** — chaque module avec son propre style
- **Silicon Valley startup aesthetic** — trop light, trop coloré, déconnecté du terrain UEMOA

### Visual Mood

> Le BDUI Engine est le garant de la qualité : peu importe le template (`retail.json`, `pharmacie.json`), les règles UX/UI sont celles du Design System niveau 1. Le contenu change, la qualité ne change jamais.

**Mots-clés :** Confiant · Direct · Dense · Terrain · Lisible

---

## Design Style

### UI Style

**Primary Style :** Material Design 3 (Flutter natif) + Flat aesthetic

Surfaces propres, pas de chrome inutile, contenu en avant. Aligné avec l'OS Android (cible MVP) et le système de composants Flutter. Les trois références (Airbnb, Uber, Binance) convergent vers ce registre flat — aucune n'utilise de glassmorphism, neobrutalism, ou effets visuels lourds.

**Caractéristiques :**
- Surfaces élevées via ombre subtile (Material elevation), pas via couleur de fond
- Pas de borders décoratives — séparation par whitespace et ombre
- Composants natifs Material 3 étendus, jamais remplacés
- Pas de chrome inutile autour des éléments de données

### Design Aesthetic

**Aesthetic :** Service Center — pratique et orienté confiance

Pas corporate (trop froid), pas artisanal (trop chaleureux). L'interface fait le travail sans se mettre en avant. Chaque élément présent a une raison d'être — rien de décoratif sans fonction.

---

## Color Direction

### Color Strategy

Dark-first avec support dual mode. Les tokens de couleur sont sémantiques (`surface`, `onSurface`, `primary`, `error`, `warning`) — Flutter `ThemeData` switche dark/light sans duplication de code. La couleur est toujours un signal, jamais de la décoration.

### Palette Direction

| Rôle | Direction | Hex | Notes |
|------|-----------|-----|-------|
| **Background** | Dark surface | `#121212` | Dark mode primaire |
| **Background Light** | Surface claire | `#FFFFFF` / `#F5F5F5` | Light mode |
| **Text primaire** | Blanc / Noir | `#F5F5F5` / `#1A1A1A` | Contraste WCAG AA minimum |
| **Accent jaune** | Brand / CTA principal | `#FFCC00` | Actions primaires, logo |
| **Accent bleu** | Info / Navigation | `#1A73E8` | Liens, navigation active |
| **Accent vert** | Succès / Positif | `#34A853` | Gains, validé, ok |
| **Accent rouge** | Alerte / Critique | `#EA4335` | Pertes, erreurs, alertes |
| **Ambre** | Attention | `#F59E0B` | Warnings, seuils |

### Schéma de couleurs

**Type :** Dark monochromatic base + multi-color semantic accents

Couleur = signal sémantique universel :
- Vert → positif (vente validée, stock ok, sync réussi)
- Ambre → attention (stock bas, validation en attente)
- Rouge → critique (perte, erreur, alerte propriétaire)
- Jaune → brand / action primaire

---

## Typography Direction

### Approche

Trois polices avec rôles distincts — aucune ambiguïté sur ce qui est un titre, un label, ou une donnée. La typographie fait la hiérarchie, pas la couleur seule.

### Font Direction

| Rôle | Police | Style | Usage |
|------|--------|-------|-------|
| **Display / Wordmark** | Bebas Neue | Géométrique condensé bold | Titres d'écran, wordmark, headers marketing |
| **UI / Labels / Corps** | Inter | Neo-grotesque humaniste | Tous les labels, descriptions, body text |
| **Données / Chiffres** | Roboto Mono | Monospace | KPIs, montants, quantités, timestamps |

**Principe :** Chiffre clé = grand + Roboto Mono. Label contextuel = petit + Inter couleur secondaire. Jamais de chiffre important en Inter — la monospace force l'alignement et la lisibilité numérique.

---

## Layout Direction

### Approche

App mobile Flutter. Pas de site web — les concepts "hero section" et "mega menu" ne s'appliquent pas. La structure est déclarée en JSON (BDUI Engine) et rendue par Flutter.

### Éléments clés

| Élément | Approche | Notes |
|---------|----------|-------|
| **Écran d'accueil** | Data-focused, role-based | Blandine → CA + alertes. Manager → validations. Commercial → CTA vente |
| **Content layout** | Bento box / Card-based | Widgets modulaires configurés par JSON, pas de structure fixe codée |
| **Navigation** | Bottom Navigation Bar (3-5 tabs) | Role-based — chaque rôle voit ses propres onglets. Sticky, toujours visible |
| **Navigation secondaire** | Drawer ou icon menu | Settings, profil, déconnexion |
| **Cards / Widgets** | Elevation subtile, données structurées | KPI card, transaction line, stock item |

**Principe fondateur :** Action primaire du rôle au-dessus du fold, toujours visible sans scroll. Un écran = un objectif principal.

---

## Visual Effects

### Approche

Performance non-négociable : cible Android mid-range (Snapdragon 680, 4GB RAM). 60fps constant. Effets lourds exclus.

### Effets spécifiques

| Effet | Niveau | Raison |
|-------|--------|--------|
| Shadows / Elevation | Subtil | Material 3 natif — différenciation cards |
| Transitions page | Subtil (fade/slide léger) | Orientation spatiale — pas de physique complexe |
| Animations données | Subtil (CountUp sur KPIs) | Attention sans surcharge GPU |
| Parallax | Aucun | Coût GPU injustifié sur mid-range |
| BackdropFilter / Blur | Minimal ou aucun | Lourd sur GPU Snapdragon 680 |
| Hover effects | N/A | Mobile tactile uniquement |

---

## Photography & Imagery

### Dans l'app → Aucune photographie

L'UI est data-first. Pas de photos dans les écrans métier.

| Type | Approche | Source |
|------|----------|--------|
| Icônes | Material Icons + custom pour métier UEMOA | Flutter / custom SVG |
| Avatars | Photos uploadées par l'utilisateur | User-generated |
| Empty states | Illustrations ligne, style flat cohérent | Custom, phase design |
| Onboarding | Illustrations légères | Custom, phase design |

### Pour le marketing → Authentique / Documentaire

- Vraies commerçantes, vrai commerce Ouagadougou — pas de stock générique
- Pas de photos studio staged — terrain, mains, produits réels
- Femmes commerçantes au premier plan (Blandine = archétype)
- Traitement couleur : naturel, zéro filtres Instagram

**Stock si nécessaire :** Unsplash / Pexels — collection cohérente, même style photographique. Éviter les banques avec stéréotypes africains.

### Guidelines images

- Compression agressive pour web/mobile
- Alt text systématique (accessibilité + SEO)
- Ratio cohérent par type de placement

---

## Design Constraints

- **Flutter Material 3** comme système de base — composants natifs étendus, pas remplacés
- **Android mid-range** (Snapdragon 680, 4GB RAM) → 60fps, zéro shader lourd, zéro BackdropFilter intensif
- **Offline-first** → zéro blocking skeleton screens — données depuis DB locale immédiatement
- **Dual theme** (dark-first + light mode) → tokens sémantiques uniquement, pas de couleurs hardcodées
- **BDUI Engine** → composants design doivent être composables / modulaires — le JSON décrit la structure
- **Multilingue FR/EN** → labels UI doivent absorber la variabilité de longueur de texte (EN souvent plus court)
- **Touch targets** → minimum 48×48dp (Material accessibility guidelines)
- **i18n RTL** → readiness pour marchés futurs (Phase 3+)
- **WCAG AA** → contraste minimum 4.5:1 pour text, 3:1 pour composants UI

---

## Next Steps

- [ ] **Phase 2 : Trigger Mapping** — Connecter visuels à la psychologie utilisateur
- [ ] **Phase 3 : UX Scenarios** — Appliquer la direction visuelle aux flows
- [ ] **Phase 4 : Design System** — Construire les design tokens depuis cette direction

---

_Visual Direction v1.0 — Carlos Simporé — 2026-05-09_
