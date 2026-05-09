# Product Brief: Scalario

**Version:** 1.0
**Date:** 2026-05-09
**Fondateur:** Carlos Simporé
**Status:** Complete
**Next Phase:** Trigger Mapping (Phase 2)

---

## Strategic Summary

Scalario n'est pas un ERP de plus. C'est un moteur qui génère des ERPs sur mesure depuis du JSON — le premier **Instant Business OS** pour les PME d'Afrique subsaharienne.

90%+ des PME en UEMOA n'ont aucun système de gestion. Pas un ERP médiocre — rien. Elles gèrent avec Excel, des cahiers, et leur mémoire. Le concurrent réel n'est pas Odoo — c'est le cahier et la confiance aveugle envers l'équipe. Blandine, propriétaire d'une épicerie fine à Ouagadougou, ne sait pas pourquoi ses marges baissent. Les pertes sont inexpliquées. Elle délègue parce qu'elle n'a pas le choix — pas parce qu'elle a des données.

Scalario répond à ce job en 45 minutes : un intégrateur local certifié charge un template JSON sectoriel, ajuste les overrides, et le client est live — offline-first, multilingue, multidevise, sécurisé en 5 couches. La fenêtre est ouverte maintenant. Dans 18 mois, soit un acteur global investit massivement en UEMOA, soit Scalario a déjà verrouillé le réseau d'intégrateurs. Le premier qui construit ce réseau gagne — il ne peut pas être acheté.

---

## Vision

> **Scalario est le premier Instant Business OS pour les PME d'Afrique subsaharienne.** Un système de gestion complet qu'un intégrateur local peut déployer en 45 minutes depuis une conversation, sans une ligne de code. Pas un ERP de plus — un moteur qui génère des ERPs sur mesure depuis du JSON.

**Vision 5 ans :** Devenir la couche de données commune du commerce UEMOA — l'infrastructure sur laquelle tournent les apps de livraison, de credit scoring, de supply chain de toute l'Afrique de l'Ouest. Double network effect : plus de tenants → plus d'apps tierces → plus de tenants.

---

## Positioning

**Pour** les PME d'Afrique subsaharienne (3–20 employés) qui gèrent encore avec Excel ou un cahier et ont besoin de confiance + contrôle à distance sur leur business,

**Scalario** est le premier **Instant Business OS**

qui permet à n'importe quel intégrateur local de déployer un ERP complet en **45 minutes depuis une conversation**, offline-first, zéro code.

**Contrairement à** Odoo (3–6 mois, nécessite des devs) ou Excel (aveugle sur les responsabilités),

**Scalario est le seul ERP nativement conçu pour l'UEMOA** — distribué par un réseau d'intégrateurs certifiés locaux, avec un moat non-achetable : 18–24 mois à construire même avec budget illimité.

### Composants du positionnement

| Composant | Valeur |
|---|---|
| Cible | PME UEMOA, 3–20 employés, 90%+ sans ERP |
| Besoin | Confiance + contrôle à distance, pas "un ERP" |
| Catégorie | Instant Business OS (nouvelle catégorie) |
| Bénéfice clé | 45 min de déploiement, offline-first, zéro dev |
| Concurrent principal | Excel/Papier (do-nothing) |
| Différenciateur | Réseau intégrateurs locaux non-achetable |

---

## Target Users

### Utilisateur Primaire — Britta la Business Owner *(Blandine archétype)*

| Attribut | Détail |
|---|---|
| Profil | Propriétaire PME (épicerie, pharmacie, BTP...), Ouagadougou |
| Taille équipe | 4–8 employés |
| Device | Android (smartphone mid-range) |
| Présence | Souvent absente physiquement — délègue |
| Technique | Non-technique, zéro jargon ERP |
| **Job réel** | *"Savoir ce qui se passe dans mon business depuis mon téléphone — et que mon équipe soit responsable sans que je sois présente"* |
| Frustrations | Marges inexpliquées, pertes non attribuées, perte de contrôle quand elle délègue |
| Solution actuelle | Confiance aveugle + Excel/cahier |
| Goal | Confiance + contrôle à distance, 24/7 |

### Utilisateurs Secondaires

- **Manager** — supervise terrain, valide livraisons, accès modules opérationnels
- **Staff/Commercial** — vend, encaisse, interface simplifiée limitée à son rôle JSON

### Business Customer (B2B) — L'Intégrateur Certifié

| Attribut | Profil |
|---|---|
| Qui | Consultant local PME, 3+ ans d'expérience terrain |
| Structure | Freelance ou micro-cabinet (1–3 personnes) |
| Localisation Phase 1 | Ouagadougou |
| Décision | Solo — budget certification 75K FCFA one-time |
| Motivation | Transformer expertise PME en MRR récurrent prévisible |
| Ce qu'il NE veut PAS | Coder, gérer un serveur, dépendre d'un éditeur étranger |
| Revenue | 40% du MRR client à vie |
| **Job réel** | *"Construire un business tech récurrent et stable en UEMOA sans être développeur"* |

---

## Business Model

**Modèle B2B2B** — Franchise + Razor/Blades + Platform

| Phase | Produit | Prix | Payeur |
|---|---|---|---|
| Phase 1 | Standard | 40K FCFA/mois | Client final |
| Phase 1 | Premium | 80K FCFA/mois | Clients multi-sites |
| Phase 2 | Certification intégrateur | 75K FCFA one-time | Intégrateur |
| Phase 2 | Revenue share MRR | 60% Scalario / 40% Intégrateur | Auto |
| Phase 2 | Renouvellement annuel | 40K FCFA/an | Intégrateur |
| Phase 3 | Commission marketplace | 20% | Acheteur template |
| Phase 3 | BDAPI usage-based | TBD | Enterprises |

**Distinction buyer / end-user :**
- Buyer Scalario → Intégrateur (paie la certification, configure, supporte)
- End-user → Blandine + employés (utilisent l'app quotidiennement)

**Phase 1 (maintenant) :** Carlos = seul intégrateur. Revenue direct Blandine (40K FCFA/mois).
**Phase 2 (M6) :** Intégrateurs certifiés, canal scalable sans Carlos.

---

## Product Concept

**L'idée structurante : "Everything is JSON"**

> Le backend décide quoi afficher. Flutter ne contient aucun `if` métier — c'est un moteur de rendu pur qui lit des règles JSON. Ajouter un nouveau secteur = créer un nouveau fichier JSON. Zéro ligne de code.

**Les 3 niveaux immuables :**

```
Niveau 1 — Design System (FIXE, code)
           Composants, tokens, BDUI Engine — codé une fois, jamais touché

Niveau 2 — Templates sectoriels (JSON catalogue)
           retail.json, pharmacie.json — nouveau secteur = nouveau fichier

Niveau 3 — Config client (JSON override)
           Modules activés, rôles, règles spécifiques — zéro code
```

**Règle d'or absolue :** Jamais de logique métier dans Flutter. Jamais d'endpoint NestJS spécifique à un domaine. Tout ce qui est métier = fichier JSON dans le catalogue.

**Exemple concret :** `retail_fresh_produce.json` → Blandine a son dashboard, ses 3 rôles, ses 6 modules, ses workflows — sans une ligne de code Flutter ni NestJS spécifique au retail.

---

## Success Criteria

**Métrique primaire :** Blandine ouvre l'app quotidiennement — sans aide, sans Carlos.

| Gate | Date | Critères | Décision |
|---|---|---|---|
| **Gate 0** | **8 juillet 2026** | Blandine utilise quotidiennement sans aide | Go Phase 1 complète |
| Gate 1 | Août 2026 (M3) | 2 clients + template non modifié pour le 2ème | Go programme intégrateur |
| Gate 2 | Nov. 2026 (M6) | 5 clients + 1 intégrateur autonome + Config IA live + MRR 200K FCFA | Go expansion géographique |
| Gate 3 | Mai 2027 (M12) | 15 clients + 1 intégrateur Côte d'Ivoire + MRR 750K FCFA | Go fundraising + marketplace |

**Leading indicators :**
- Fréquence ouverture app Blandine (quotidien = succès)
- Validations croisées exécutées chaque semaine
- Modifications JSON demandées par clients (moins = mieux)
- Candidatures intégrateurs spontanées (mensuel)

---

## Competitive Landscape

**Le vrai concurrent Phase 1 : Excel + cahier** (gratuit, familier, zéro onboarding)

| Alternative | Pourquoi ils restent | Où ça échoue | Scalario gagne |
|---|---|---|---|
| Excel/Papier | Gratuit, connu, zéro friction | Aveugle sur responsabilités, inutilisable à distance | Control + accountability depuis un smartphone |
| Odoo | Présent en Afrique, complet | 1–6 mois, nécessite devs, pas offline-first | 45 min, zéro dev, offline natif |
| SAP/Sage | Marque reconnue | $10K–50K+, hors portée PME | Prix SMB, déploiement immédiat |
| Apps génériques | Simples | Ne couvrent pas les workflows métier spécifiques | Templates sectoriels précis |
| Do-nothing | Ça "marche" | Pertes inexpliquées, délégation aveugle | Confiance + données sans être présente |

**Avantage non-achetable :**
Réseau d'intégrateurs locaux certifiés — 18–24 mois à construire même avec budget illimité. Odoo peut venir avec des millions. Il ne peut pas acheter la confiance terrain et les relations commerçants.

**Reality check :** Si Odoo lance une offensive Africa-native dans 12–18 mois, le réseau d'intégrateurs déjà verrouillé + le catalogue de templates = barrière infranchissable à court terme.

---

## Constraints & Context

| Catégorie | Paramètre | Flexible ? |
|---|---|---|
| Timeline | Gate 0 = 8 juillet 2026 (Blandine live J+60) | Non — date fixe |
| Équipe | Carlos seul jusqu'à M8 minimum | Non — solo dev intentionnel |
| Budget | Infrastructure légère : VPS + Docker Compose 5 services | Flexible si traction prouvée |
| Tech | Flutter + NestJS + FastAPI + PostgreSQL + Redis | Non — stack décidée |
| Scope Phase 1 | Aucune feature non-critique avant Blandine live | Non — principe fondateur |
| Marché | Ouagadougou Phase 1 uniquement | Non — profondeur avant largeur |
| Connectivité | Offline-first natif — contrainte terrain UEMOA | Non — non-négociable |
| i18n | Zéro string hardcodée dès le jour 1 | Non — prévu pour scale global |

**Ce qui est flexible :** ordre des features post-Gate 0, timing Phase 2 (peut glisser de 1–2 mois si Gate 1 non atteint), choix LLM (Claude API → Ollama selon client).

---

## Platform Strategy

**Approche : Cross-Platform Flutter (codebase unique) + Mobile-first**

| Couche | Plateforme | Priorité |
|---|---|---|
| App client | Flutter Android | MVP Phase 1 |
| App client | Flutter iOS | Phase 2 |
| App client | Flutter Web (PWA) | Phase 2 |
| Admin intégrateur | Flutter Web | Phase 2 |

- **Offline-first natif** — Drift/Isar = première source de vérité, backend = service de sync
- **Mobile-first** — design pour Android mid-range (Snapdragon 680), scale up desktop
- **Un seul BDUIEngine** — même JSON, même composants, même comportement sur toutes les plateformes
- **PWA installable** — Flutter Web avec Service Worker, accessible sans App Store

---

## Tone of Voice

**4 attributs :**
1. **Direct & concret** — pas de jargon ERP, pas d'abstraction
2. **Confiant sans être arrogant** — la preuve vient des données, pas des slides
3. **Associé terrain** — parle comme quelqu'un qui connaît le commerce africain
4. **Respectueux** — jamais condescendant envers des entrepreneurs qui réussissent avec peu

**Microcopy en action :**

| Contexte | ❌ Éviter | ✅ Scalario |
|---|---|---|
| Bouton principal | "Submit" | "Valider" |
| Chargement | "Loading..." | "Chargement en cours..." |
| Sync offline | "Synchronization pending" | "Données en attente de sync" |
| Erreur champ | "Invalid input" | "Vérifie ce champ" |
| État vide stock | "No items found" | "Aucun produit pour l'instant" |
| Succès clôture | "Operation completed" | "Caisse clôturée ✓" |
| Mode offline | "You are offline" | "Mode hors ligne — tes données sont sauvegardées" |

**Langues :** Français (primaire) + Anglais. Langues locales (Dioula, Mooré, Wolof) = Phase 3.

**Marque personnelle Carlos Simporé :**
- Identité : "Carlos Simporé | Builder" — build in public, coulisses, transparence
- Canaux : TikTok/Facebook Carlos (fondateur authentique) + TikTok/Facebook Scalario (brand produit)
- Stratégie : build in public → liste WhatsApp → mini-apps par métier → conversion Scalario

---

**Status:** Product Brief Complete
**Next Phase:** Trigger Mapping (Phase 2)
**Last Updated:** 2026-05-09
