---
stepsCompleted: ['step-19-inspiration-workshop']
project: scalario
lastUpdated: 2026-05-09
status: complete
---

# Inspiration Analysis: Scalario

> Reference Site Analysis & Design Principles

**Created:** 2026-05-09
**Author:** Carlos Simporé
**Related:** [Product Brief](./project-brief.md) | [Content & Language](./content-language.md)

---

## Core Insight

> "La simplicité de l'UX — pour une personne du domaine, tu n'as pas besoin de formation pour comprendre quelque chose dans leur app. Tout est clair, les actions primaires sont visibles, pas besoin de les chercher."
> — Carlos Simporé

**Principe directeur : Zero Learning Curve for Domain Experts.**
L'interface parle le langage de l'utilisateur, pas celui du logiciel.

---

## Sites Analyzed

### Airbnb

**URL:** https://www.airbnb.com

#### Ce qui attire

- **Actions primaires immédiatement visibles** — la recherche est là, sans chercher. L'utilisateur sait exactement quoi faire dès l'ouverture.
- **Hiérarchie claire** — ce qui compte maintenant est au-dessus. Le reste suit.
- **Langage du domaine** — "Séjours", "Expériences", pas "Module réservation v2"
- **Cards lisibles** — prix, photo, étoiles. L'information nécessaire sans surcharge.

#### Adaptations pour Scalario

- **Cards → Widgets métier** — pas des photos, mais des KPIs (CA du jour, stock critique, alertes)
- **Search-first → Role-first** — pas de recherche universelle, l'action primaire dépend du rôle JSON
- **Palette claire → Dark-first** — Airbnb est light, Scalario est dark (usage terrain Burkina)

#### Principes extraits

- L'action #1 est toujours au-dessus du fold
- La hiérarchie visuelle remplace les instructions texte
- Le vocabulaire est celui de l'utilisateur, jamais du logiciel

---

### Uber

**URL:** https://www.uber.com

#### Ce qui attire

- **Un seul CTA dominant** — pas d'ambiguïté sur quoi faire. Carte + bouton. Point.
- **Minimalisme extrême** — zéro friction entre l'utilisateur et son objectif
- **État toujours visible** — en recherche, en route, arrivé. On sait toujours où on en est.
- **Mobile-first radical** — conçu pour le téléphone d'abord, jamais adapté après

#### Adaptations pour Scalario

- **Single CTA → Role-based primary action** — Blandine voit son dashboard. Commercial voit "Nouvelle vente". Manager voit "Validations en attente". Uber pour chaque rôle.
- **Minimalisme → Data-dense dark** — Uber est très vide, Scalario a plus de données à afficher (KPIs, mouvements)

#### Principes extraits

- Un rôle = une action primaire = visible sans chercher
- Le système communique son état en permanence (sync, offline, en cours)
- Zéro étape inutile entre l'utilisateur et son objectif

---

### Binance

**URL:** https://www.binance.com

#### Ce qui attire

- **Dark-first assumé** — chiffres sur fond sombre, lisible en plein air, batterie préservée
- **Data-dense sans chaos** — beaucoup d'information, mais la hiérarchie typographique fait le tri
- **Couleur comme signal de statut** — vert = hausse / rouge = baisse. Universel, instantané.
- **Chiffres grands, contexte petit** — ce qui compte (le prix) est gros. Le label est petit.

#### Adaptations pour Scalario

- **Crypto vocabulary → Commerce vocabulary** — "Portfolio" devient "Caisse", "Trade" devient "Vente"
- **Dense mais pas anxiogène** — Binance peut être stressant (rouge/vert partout). Scalario = confiance, pas tension.
- **Green/Red → Green/Amber/Red** — 3 états : ok / attention / alerte. Pas de sur-alarme.

#### Principes extraits

- Dark-first : fond sombre + texte clair = lisibilité terrain
- Typographie comme hiérarchie : chiffre clé = grand, contexte = petit
- Couleur = signal immédiat, pas décoration

---

## Design Principles (Synthesized)

### Layout

**DO:**
- Action primaire du rôle au-dessus du fold, toujours
- Un écran = un objectif principal
- Cards pour grouper l'information liée (widget KPI, ligne de vente, article stock)
- Navigation role-based : chaque rôle a son point d'entrée naturel

**DON'T:**
- Menus cachés pour les actions fréquentes
- Écrans multi-objectifs qui forcent le scroll avant d'agir
- Hiérarchie plate où tout a la même importance visuelle

---

### Content Hierarchy

**DO:**
- Chiffre clé : grande taille, poids fort (Roboto Mono pour les données)
- Label contextuel : petite taille, couleur secondaire
- Statut visible en permanence (sync, offline, alertes)
- Termes du commerce UEMOA — "Caisse", "Livraison", "Stock" — jamais le jargon ERP

**DON'T:**
- Labels ERP dans l'UI Blandine ("module", "transaction", "entité")
- Informations de même poids visuel
- État du système caché ou ambigu

---

### Visual Style

**DO:**
- Dark-first : fond sombre (#121212 ou proche), texte blanc/clair
- Couleur = signal : vert (ok/positif), ambre (attention), rouge (alerte critique)
- Palette logo 4 couleurs (#FFCC00, #1A73E8, #34A853, #EA4335) pour accents et identité
- Typographie : Inter pour les labels, Roboto Mono pour les données/chiffres, Bebas Neue pour les headers/wordmark

**DON'T:**
- Light mode comme défaut (usage terrain Ouagadougou : plein air, batterie)
- Couleur décorative sans signification sémantique
- Gradients complexes ou effets visuels qui ralentissent le rendu

---

### User Experience

**DO:**
- Zero learning curve pour l'utilisateur du domaine (Blandine comprend en 3 secondes)
- L'interface parle le langage du commerce, pas du logiciel
- État offline affiché clairement mais sans panique — "Mode hors ligne — tes données sont sauvegardées"
- Feedback immédiat sur chaque action (loading, succès, erreur — en langage humain)
- Chaque rôle a une action primaire évidente, sans chercher

**DON'T:**
- Bloquer l'utilisateur quand la connexion est faible
- Codes d'erreur techniques visibles par Blandine
- Formulaires longs sans progression visible
- Onboarding tutorial si l'interface est déjà auto-explicite

---

## Application par Rôle (Scalario)

| Rôle | Action Primaire Visible | Analogie Inspiration |
|---|---|---|
| **OWNER (Blandine)** | CA du jour + alertes critiques | Binance portfolio view |
| **MANAGER** | Validations en attente + livraisons | Uber driver — file de jobs |
| **COMMERCIAL** | Bouton "Nouvelle vente" | Uber rider — une seule action |

---

## How to Use This Document

**Pour Visual Direction (step-20+) :**
Ces principes sont les rails de la direction visuelle. Chaque composant doit passer le test : "L'action primaire est-elle visible ? Le chiffre clé est-il lisible en 3 secondes ?"

**Pour UX Scenarios (Phase 3) :**
Chaque flow doit respecter "zero learning curve pour l'expert domaine". Si Blandine doit chercher quelque chose, le flow est raté.

**Pour Design Review :**
4 questions de contrôle : (1) Action primaire visible ? (2) Vocabulaire commerce ou logiciel ? (3) État système clair ? (4) Lisible dark-first ?

---

_Inspiration Analysis v1.0 — Carlos Simporé — 2026-05-09_
