# Innovation Strategy: Scalario

**Date:** 2026-05-09
**Strategist:** Carlos Simpore
**Strategic Focus:** Créer la catégorie "Instant Business OS" en UEMOA — et verrouiller le marché via un réseau d'intégrateurs certifiés avant que les acteurs globaux ne s'y intéressent.

---

## 🎯 Strategic Context

### Current Situation

Scalario est un Business Operating System universel basé sur un BDUI Engine + catalogue de templates JSON. Le principe fondamental : zéro code métier dans le produit — tout est déclaré en JSON. Un nouveau secteur = un nouveau fichier JSON, zéro ligne de code.

Fondateur solo (Carlos Simpore — dev + CEO + sales). Premier client : Blandine (épicerie fine, Burkina Faso). Beachhead : UEMOA → Côte d'Ivoire → Sénégal.

Target J+60 : Blandine live sur 4 fonctions critiques (validation croisée, pertes segmentées, clôture caisse, dashboard proprio).

### Strategic Challenge

Comment créer une nouvelle catégorie ("Instant Business OS") et la scaler sans croissance linéaire de l'équipe — via un canal d'intégrateurs certifiés et un catalogue de templates sectoriels qui s'auto-alimente.

---

## 📊 MARKET ANALYSIS

### Market Landscape

**TAM — Marché Total Adressable**
Les ERPs SMB en Afrique Sub-Saharienne. ~3-5 millions de PME formelles en UEMOA. Marché ERP africain estimé à $2-3B, croissance 15-20%/an. Le vrai TAM de Scalario : les PME qui n'ont *aucun* ERP aujourd'hui — soit 90%+ des entreprises. Marché vierge, pas marché à prendre.

**SAM — Marché Adressable Serviceable**
UEMOA, secteurs cibles Phase 1-2 : retail, épicerie, pharmacie, boissons, cosmétiques, BTP léger.
Estimation : 150-300K entreprises × 40-80K FCFA/mois = **$100-250M/an de potentiel MRR**.

**SOM — Marché Obtenable (5 ans)**
Réaliste avec canal intégrateur : 0.5-1% du SAM = **500-1500 clients actifs → $3-6M ARR à M36**.

### Competitive Dynamics

Axes clés : vitesse de déploiement × adéquation UEMOA.

- **SAP Business One** : 6-18 mois, $50K+, hors scope PME UEMOA
- **Odoo** : 1-6 mois, présence Afrique mais nécessite des devs, pas offline-first
- **Sage** : 1-3 mois, distribution West Africa, UI vieillissante, zéro offline
- **QuickBooks/Wave** : rapide mais comptabilité seulement
- **Excel/Papier** : le vrai concurrent Phase 1 — gratuit, familier, zéro onboarding

Le white space : rapide + UEMOA-natif + offline-first + SMB-pricé. Personne n'y est.

### Market Opportunities

1. 90%+ des PME UEMOA sans ERP = marché non-consommateur à créer
2. Infrastructure mobile + Wave/Orange Money maintenant mature
3. Aucun dominant UEMOA SMB ERP — Odoo présent mais pas dominant
4. Secteurs à forte demande non servie : épicerie fine, pharmacie, BTP, boissons

### Critical Insights

**La fenêtre est ouverte maintenant.** Dans 3-5 ans, soit un global player investit massivement en UEMOA, soit un local champion a déjà construit le réseau d'intégrateurs. Le premier qui verrouille ce réseau gagne.

Signaux positifs : smartphone urbain 75-85%, Wave/Orange Money opérationnel, LLMs matures depuis 2023, Flutter production-ready, pression OHADA + digitalisation post-COVID.

Risque principal : Odoo pourrait lancer une offensive Africa-first dans 12-18 mois.

---

## 💼 BUSINESS MODEL ANALYSIS

### Current Business Model

Scalario opère un modèle hybride Franchise + Razor/Blades + Platform (horizon M18+).

Phase 1 : Carlos est le seul intégrateur. Revenue direct client (40-80K FCFA/mois).
Phase 2 : Intégrateurs certifiés (60/40 revenue split). Certification 75K FCFA one-time.
Phase 3 : Marketplace templates (20% commission) + BDAPI usage-based.

### Value Proposition Assessment

**Pour l'intégrateur :** Configurer un ERP client en 45 min sans dev, gagner 40% MRR récurrent, avoir une marque crédible à revendre localement.

**Pour le client final (Blandine) :** Arrêter les pertes inexpliquées, monitorer à distance, responsabilité segmentée par employé, clôture caisse automatisée.

### Revenue and Cost Structure

| Phase | Source | Montant | Qui paie |
|---|---|---|---|
| Phase 1 | Abonnement Standard | 40K FCFA/mois | Client final |
| Phase 1 | Abonnement Premium | 80K FCFA/mois | Clients multi-sites |
| Phase 2 | Certification intégrateur | 75K FCFA one-time | Intégrateur |
| Phase 2 | Revenue share MRR | 60% Scalario / 40% Intégrateur | Automatique |
| Phase 2 | Renouvellement annuel | 40K FCFA/an | Intégrateur |
| Phase 3 | Commission marketplace | 20% du prix | Acheteur template |
| Phase 3 | BDAPI usage-based | TBD | Enterprises |

Coûts principaux : infrastructure VPS (faible), temps Carlos (élevé Phase 1), support (réduit par intégrateurs Phase 2).

### Business Model Weaknesses

1. Carlos = point de défaillance unique jusqu'à M8
2. Claim "45 minutes" faux jusqu'à Phase 2 (Config IA) — Phase 1 = 2h manuel
3. Revenue par client faible — 25 clients pour atteindre 1M FCFA MRR — volume existentiel
4. Risque de désintermédiation intégrateur si pas de relation directe Scalario→client final

---

## ⚡ DISRUPTION OPPORTUNITIES

### Disruption Vectors

1. Non-consommation — servir les 90% sans ERP, pas prendre des clients à Odoo
2. Configuration — 45 min vs 6 mois, change la règle du jeu
3. Distribution — intégrateurs locaux vs force de vente directe
4. Prix — 40-80K FCFA/mois vs $50K+ pour un ERP classique
5. Connectivité — offline-first natif là où les concurrents échouent

### Unmet Customer Jobs

Blandine : "Savoir ce qui se passe dans mon business depuis mon téléphone — et que mon équipe soit responsable sans que je sois présente." Job = confiance + contrôle à distance, pas "avoir un ERP."

Intégrateur : "Construire un business tech récurrent et stable en UEMOA sans être développeur." Job = transformation de carrière, pas revente de logiciel.

### Technology Enablers

- LLMs (2023+) → Config Agent : extraction de règles métier depuis une conversation
- Flutter → codebase unique mobile + web + offline
- BDUI → interface générée depuis JSON, zéro dev par client
- Wave/Orange Money → infrastructure paiement existante
- pgvector → RAG hybride pour queries IA métier

### Strategic White Space

Position non-occupée et verrouillable : "Business OS déployé en 45 min, offline-first, Africa-native, pour PMEs 3-20 employés, distribué par réseau d'intégrateurs locaux certifiés."

SAP ne peut pas descendre là. Odoo ne veut pas. Les solutions locales n'ont pas le moteur. C'est le terrain de Scalario.

---

## 🚀 INNOVATION OPPORTUNITIES

### Innovation Initiatives

10 opportunités identifiées sur 3 horizons temporels.

**Horizon 1 (M1-M12) :** OI-1 Templates Premium, OI-2 WhatsApp Reporting, OI-3 Formation intégrateur packagée
**Horizon 2 (M6-M24) :** OI-4 Partenariat Telco, OI-5 Partenariat Banque, OI-6 Experts-comptables intégrateurs, OI-7 Marketplace Templates
**Horizon 3 (M18-H3) :** OI-8 BDAPI, OI-9 B2B Inter-tenants, OI-10 Config IA Self-Service

### Business Model Innovation

- Templates Premium Business (multi-département) à 150-200K FCFA/mois — 3x le ticket Standard
- Marketplace templates à 20% commission — revenus passifs sur catalogue tiers
- Config IA self-service Phase 3 — ouvre le marché sans intégrateur

### Value Chain Opportunities

- Expert-comptables comme intégrateurs — confiance existante + base clients PME prête
- BDAPI usage-based — ouvre aux développeurs africains sans modifier le core
- B2B inter-tenants — network effect pur dès 20+ clients par ville

### Partnership Opportunities

- Orange/MTN : distribution à l'échelle via réseau telco (10% MRR)
- Ecobank/Coris Bank : bundle compte pro + Scalario 3 mois offerts
- Cabinets comptables UEMOA : certification intégrateur via canal confiance existant

### Horizon 3 — Infrastructure d'Écosystème (OI-11)

**Scalario = couche de données commune du commerce UEMOA.**

Une app de livraison de médicaments n'a pas besoin de construire son propre système de gestion pharmacie. Elle se branche via BDAPI sur les pharmacies déjà sur Scalario. Scalario gère stock, permissions, données — l'app reçoit exactement ce qu'elle est autorisée à voir.

Verticales applicables : Santé (hôpital→pharmacie→livreur), Agri-food (ferme→distributeur→détaillant), Commerce général (importateur→grossiste→détaillant), BTP.

Chaque connexion inter-tenants = transaction monétisable. Double network effect : plus de tenants → plus d'apps tierces veulent se connecter → plus d'apps tierces → plus de tenants veulent rejoindre. Coût de churn quasi-nul une fois connecté à l'écosystème.

**Prérequis : 20+ tenants actifs dans une même ville. Priorité inchangée — Horizon 3.**

---

## 🎲 STRATEGIC OPTIONS

*(À compléter — Step 6)*

---

## 🏆 RECOMMENDED STRATEGY

### Strategic Direction

**Option A — Champion Vertical Profond, avec expansion géographique via intégrateurs.**

Carlos ne s'étend pas géographiquement. Les intégrateurs s'étendent à sa place. Playbook prouvé au Burkina → intégrateur certifié Abidjan → intégrateur certifié Dakar. Profondeur de template avant largeur de marché.

Option B rejetée : un template médiocre dans 3 pays vaut moins qu'un template irréprochable dans 1 pays. La réputation UEMOA se construit par bouche-à-oreille — un client mal servi à Abidjan détruit la réputation à Ouagadougou.

Option C rejetée : le double network effect n'existe que si les tenants existent. Destination confirmée — pas le chemin.

### Key Hypotheses to Validate

1. H1 : Blandine reste et réfère à J+90 → valide la proposition de valeur
2. H2 : Un intégrateur onboarde sans Carlos en 2 jours → valide la scalabilité du canal
3. H3 : Le template fresh produce marche pour la 2ème épicerie sans modification → valide la généralisation
4. H4 : 40K FCFA/mois soutenable 12 mois → valide le pricing

### Critical Success Factors

1. Template quality — retail_fresh_produce.json si bon que Blandine dit "ça a changé mon business"
2. Premier intégrateur choisi comme co-fondateur, pas revendeur — standard pour tous les suivants
3. Config IA Phase 2 livrée sans régression — le claim "45 minutes" doit devenir réel

---

## 📋 EXECUTION ROADMAP

### Phase 1: Immediate Impact

**Objectif :** Blandine live. Template validé. Hypothèses prouvées.

Initiatives : BDUI Engine + ModuleEngine + Auth + RBAC dynamique · `retail_fresh_produce.json` (4 fonctions critiques, 3 rôles) · Blandine live Android · Push notification soir · 2ème client même secteur · Prospect pharmacie identifié.

Ressources : Carlos seul · VPS + Docker Compose (nestjs, postgresql, redis).

Gate 1 : Blandine utilise quotidiennement sans aide + 2ème client onboardé depuis le même template sans modification JSON.

### Phase 2: Foundation Building

**Objectif :** Canal intégrateur opérationnel. Config IA live. 5 clients payants. MRR 200K FCFA.

Initiatives : `pharmacie.json` (2ème template, secteur différent) · Config Conversationnelle IA en production · Formation intégrateur packagée (2 jours + certification + kit) · 3 premiers intégrateurs certifiés · WhatsApp reporting · Contrat intégrateur formalisé (60/40 MRR split).

Gate 2 : 1 intégrateur autonome + Config IA live → expansion géographique autorisée.

### Phase 3: Scale & Optimization

**Objectif :** 15+ clients dans 2 pays. Marketplace ouverte. MRR 750K FCFA.

Initiatives : Premier intégrateur Côte d'Ivoire · `distribution_multi_depot.json` (Business tier 150-200K FCFA) · Partenariat expert-comptable pilote · B2B inter-tenants si 20+ clients Ouagadougou · Marketplace templates · Exploration partenariat telco/banque.

Gate 3 : 15 clients + 1 intégrateur géographique autonome → modèle plateforme validé.

---

## 📈 SUCCESS METRICS

### Leading Indicators

- Fréquence d'ouverture app par Blandine (quotidien)
- Nombre de validations croisées Phase 3 exécutées (hebdo)
- Modifications JSON demandées par clients (moins = mieux)
- Candidatures intégrateurs spontanées (mensuel)
- Temps d'onboarding client N vs N-1 (décroissant)
- Support requests par client par semaine (décroissant)

### Lagging Indicators

| Métrique | Gate 1 (M3) | Gate 2 (M6) | Gate 3 (M12) |
|---|---|---|---|
| Clients payants | 2 | 5 | 15+ |
| MRR | 80K FCFA | 200K FCFA | 750K FCFA |
| Templates catalogue | 1 | 2 | 5+ |
| Intégrateurs actifs | 0 | 3 | 6+ |
| Churn mensuel | <0% | <3% | <5% |
| Pays actifs | 1 | 1 | 2 |

### Decision Gates

- Gate 0 (J+60) : Blandine utilise quotidiennement → Go Phase 1 complète. Sinon → Stop diagnostic.
- Gate 1 (M3) : 2 clients + template non modifié → Go programme intégrateur. Sinon → Stop retravail template.
- Gate 2 (M6) : 5 clients + 1 intégrateur autonome + Config IA live → Go expansion géo. Sinon → Stop.
- Gate 3 (M12) : 15 clients + 1 intégrateur Côte d'Ivoire → Go fundraising + marketplace.

---

## ⚠️ RISKS AND MITIGATION

### Key Risks

1. R1 : Carlos sur-ingénierise avant validation (Prob : Haute)
2. R2 : Blandine churne à M3 — template ne résout pas la vraie douleur (Prob : Moyenne)
3. R3 : Premier intégrateur mal sélectionné — déforme la réputation (Prob : Haute sans critères)
4. R4 : Config IA glisse au-delà de M9 — claim "45 min" reste théorique (Prob : Moyenne)
5. R5 : Odoo offensive Africa-native (Prob : Faible dans 12 mois)
6. R6 : Intégrateur fork le concept (Prob : Faible mais existentielle)

### Mitigation Strategies

- R1 : Règle absolue — aucune feature ne sert avant Blandine live à J+60
- R2 : Check-in hebdomadaire Blandine 90 premiers jours — réagir à J+30 si usage faible
- R3 : Critères stricts (3+ ans PME consulting, références, certification payante). Max 3 intégrateurs Phase 2.
- R4 : Config IA = priorité #1 Phase 2. MVP partiel (3 secteurs) vaut mieux que version parfaite tardive.
- R5 : Réseau intégrateurs locaux = 18-24 mois à construire même avec budget. Avantage terrain non achetable.
- R6 : Clause non-concurrence moteur BDUI dans contrat certification. La valeur = catalogue + réseau, pas le moteur.

---

_Generated using BMAD Creative Intelligence Suite - Innovation Strategy Workflow_
