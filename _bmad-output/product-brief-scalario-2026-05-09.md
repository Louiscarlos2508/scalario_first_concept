# Product Brief: Scalario

**Version:** 1.0  
**Date:** 2026-05-09  
**Fondateur:** Carlos Simporé

---

## Executive Summary

Scalario est le premier **Instant Business OS** pour les PME d'Afrique subsaharienne — un système de gestion d'entreprise complet que n'importe quel intégrateur local peut déployer en 45 minutes depuis une conversation, sans une seule ligne de code.

Le principe est radical dans sa simplicité : zéro logique métier dans le produit. Tout est déclaré en JSON. Un nouveau secteur d'activité = un nouveau fichier de configuration. Un nouveau client = charger un template. La plateforme génère automatiquement l'interface, les permissions, les rapports, le tout offline-first, multilingue, multidevise.

Nous ne construisons pas un ERP de plus. Nous créons une nouvelle catégorie et verrouillons un marché de 150 000–300 000 entreprises en UEMOA via un réseau d'intégrateurs certifiés locaux — avant que les acteurs globaux ne s'y intéressent. La fenêtre est ouverte. Elle ne le sera plus dans 18 mois.

---

## The Problem

**90%+ des PME en UEMOA n'ont aucun système de gestion.** Pas un ERP médiocre — rien. Elles gèrent avec Excel, des cahiers, ou leurs souvenirs.

Le résultat concret pour Blandine (épicerie fine, Ouagadougou) : elle ne sait pas pourquoi ses marges baissent. Les pertes sont inexpliquées. Elle ne peut pas monitorer son magasin depuis son téléphone. Quand elle délègue, elle perd le contrôle. Elle fait confiance à son équipe parce qu'elle n'a pas le choix — pas parce qu'elle a des données.

Les solutions ERP existantes ne sont pas la réponse :
- **SAP/Odoo/Sage** : 3 à 18 mois de déploiement, $10K–$50K+, nécessitent des développeurs locaux — hors portée pour une PME de 5 personnes
- **Excel/papier** : le vrai concurrent — gratuit, familier, mais aveugle sur les responsabilités, inexploitable à distance, inexistant offline
- **Apps mobiles génériques** : ne couvrent pas les workflows métier spécifiques (validation croisée, pertes segmentées, clôture caisse par employé)

Le job réel que les PME cherchent à accomplir : **"Savoir ce qui se passe dans mon business depuis mon téléphone — et que mon équipe soit responsable sans que je sois présente."**

---

## The Solution

Scalario répond à ce job en 45 minutes.

**Pour le propriétaire (Blandine) :**
- Dashboard propriétaire avec KPIs en temps réel, accessible depuis un smartphone
- Validation croisée entre équipes (réception ↔ caisse, pour stopper les pertes inexpliquées)
- Responsabilité segmentée : chaque perte est attribuée à un employé, à un rayon
- Clôture caisse quotidienne automatisée avec réconciliation

**Pour l'intégrateur (le vrai client de Scalario) :**
- Catalogue de templates JSON sectoriels (`retail_fresh_produce.json`, `pharmacie.json`...)
- Déploiement depuis une conversation : l'intégrateur collecte les règles métier, charge le template, ajuste les overrides JSON — client live en 45 minutes
- Revenue récurrent : 40% du MRR mensuel du client, à vie

**Architecture fondamentale :**
- BDUI Engine : Flutter pur renderer JSON, zéro logique métier codée
- ModuleEngine : 2 endpoints génériques servent tous les modules — nouveau module = nouveau JSON
- Offline-first natif : Drift/Isar sync queue, fonctionne sans internet
- Multi-tenant, RBAC + ABAC, multilingue, multidevise

---

## What Makes This Different

**1. Vitesse radicale.** 45 minutes vs 3–18 mois pour un ERP classique. Ce n'est pas une amélioration — c'est un changement de catégorie.

**2. Zero-code-per-client by design.** La plupart des solutions "no-code" restent complexes pour l'intégrateur. Scalario, c'est un fichier JSON + une conversation. L'intégrateur n'a pas besoin d'être développeur.

**3. Offline-first natif.** Pas un bolt-on. La connectivité intermittente est une contrainte africaine réelle. Scalario est conçu pour ça depuis le début — les concurrents ne peuvent pas rattraper sans réécrire leur core.

**4. Réseau d'intégrateurs locaux.** Odoo peut venir avec un budget. Il ne peut pas reconstruire en 18 mois un réseau de consultants certifiés qui connaissent le tissu économique local, parlent Dioula et Mooré, et ont la confiance des commerçants. C'est l'avantage non-achetable.

**5. Catalogue templates = moat cumulatif.** Chaque nouveau template sectoriel enrichit le catalogue. Chaque intégrateur qui contribue accélère l'expansion secteur par secteur. Les premiers entrants dans le réseau ont accès à tous les templates — incitation à rejoindre tôt.

**Moat principal :** Le réseau d'intégrateurs certifiés. 18–24 mois à construire, même avec budget illimité.

---

## Who This Serves

### Propriétaires de PME (utilisateurs finaux)
**Archétype : Blandine.** Propriétaire d'une épicerie fine à Ouagadougou, 4–8 employés, délègue mais perd le contrôle. Smartphone Android. Souvent absente physiquement. Son job = confiance + contrôle à distance. Elle ne veut pas "un ERP" — elle veut dormir sans se demander si son manager siphonne la caisse.

Secteurs Phase 1 : épicerie/fresh produce, pharmacie. Phase 2 : boissons, cosmétiques, BTP léger.

### Intégrateurs certifiés (canal de distribution)
Consultants locaux avec 3+ ans d'expérience PME, cherchant à construire un business tech récurrent. Ils ne sont pas développeurs — et c'est la contrainte. Scalario leur donne un produit qu'ils peuvent vendre, configurer et supporter sans coder. En échange : certification 75K FCFA + renouvellement 40K FCFA/an, 40% du MRR client à vie.

**Job de l'intégrateur :** "Transformer mon expertise PME en revenu mensuel récurrent prévisible."

### Non-clients actuels (marché à créer)
90%+ des PME UEMOA sans ERP. Pas un marché à prendre à Odoo — un marché non-consommateur à créer. La compétition réelle est Excel et le cahier.

---

## Tone of Voice & Identité de Marque

**Positionnement verbal :** Partenaire de confiance, pas fournisseur de logiciel. Chaleureux, direct, humain — jamais condescendant envers des entrepreneurs qui réussissent avec peu.

**Voix Scalario :**
- Parle comme un associé qui connaît le terrain africain
- Clair et concret — pas de jargon ERP
- Confiant sans être arrogant — la preuve vient des résultats, pas des slides
- Respecte l'intelligence des propriétaires de PME

**Langues :** Français (primaire) + Anglais. Dioula/Mooré/Wolof = Phase 3 (vocale).

**Direction visuelle :**
- Dark-first (mobile africain, usage en plein air, batterie)
- Palette 4 couleurs du logo : jaune #FFCC00, bleu #1A73E8, vert #34A853, rouge #EA4335
- Typographie : Inter (UI), Roboto Mono (données/chiffres), Bebas Neue (wordmark/headers)
- Monogramme : Sc (arcs S + arc c) — jamais S seul
- Wordmark : arcs S + "CALARIO" en Bebas Neue — jamais monogramme + wordmark ensemble

**Marque personnelle Carlos Simporé :**
- Identité : "Carlos Simporé | Builder" — couvre projets, apprentissages, tech
- Canal : TikTok/Facebook Carlos (fondateur authentique, build in public) + TikTok/Facebook Scalario (marque produit)
- Stratégie : build in public → liste WhatsApp → mini-apps par métier comme canal d'acquisition → conversion Scalario quand MVO prêt

---

## Success Criteria

| Gate | Critère | Décision |
|------|---------|----------|
| J+60 | Blandine utilise quotidiennement sans aide | Go Phase 1 complète |
| M3 | 2ème client onboardé depuis `retail_fresh_produce.json` sans modification | Go programme intégrateur |
| M6 | Config IA live + 1 intégrateur autonome + 5 clients + MRR 200K FCFA | Go expansion géographique |
| M12 | 15 clients + 1 intégrateur Côte d'Ivoire actif + MRR 750K FCFA | Go fundraising + marketplace |
| H3 | 20+ tenants par ville → BDAPI + B2B inter-tenants | Go écosystème plateforme |

**Leading indicators :** Fréquence ouverture app Blandine · Validations croisées exécutées · Candidatures intégrateurs spontanées · Modifications JSON demandées par clients (moins = mieux)

---

## Scope — Phase 1 MVP

**In :** BDUI Engine + ModuleEngine + Auth RBAC/ABAC · `retail_fresh_produce.json` (4 fonctions : validation croisée, pertes segmentées, clôture caisse, dashboard proprio) · 3 rôles (OWNER, MANAGER, COMMERCIAL) · Offline-first · Push notifications · Multi-tenant shared schema · Android MVP

**Out (Phase 2+) :** Config IA conversationnelle · Programme intégrateur certifié · `pharmacie.json` · iOS · Web backoffice admin · Marketplace templates · WhatsApp reporting · Config IA self-service (Tier Solo)

**Règle absolue Phase 1 :** Aucune feature non-critique avant que Blandine soit live.

---

## Vision

Dans 3 ans, Scalario est l'infrastructure de gestion des PME UEMOA — 500–1500 clients actifs, réseau de 50+ intégrateurs certifiés dans 4+ pays, catalogue de 20+ templates sectoriels, MRR $3–6M.

Dans 5 ans : la couche de données commune du commerce UEMOA. Les apps de livraison, de credit scoring, de supply chain se branchent via BDAPI sur les données Scalario de leurs partenaires commerçants. Double network effect verrouillé.

Scalario ne construit pas un ERP africain de plus. Scalario construit l'OS sur lequel tourne le commerce informel formalisé de l'Afrique de l'Ouest.

---

_Product Brief v1.0 — Carlos Simporé — 2026-05-09_
