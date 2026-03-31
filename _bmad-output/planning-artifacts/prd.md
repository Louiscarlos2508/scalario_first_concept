---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-e-01-discovery', 'step-e-02-review', 'step-e-03-edit']
inputDocuments:
  - docs/product_brief.md
  - docs/ARCHITECTURE.md
  - docs/modules.md
  - docs/implementation_plan.md
  - docs/product_discovery.md
  - docs/task.md
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 5
workflowType: 'prd'
projectType: 'brownfield'
version: '8.2'
date: '2026-03-11'
lastEdited: '2026-03-30'
editHistory:
  - date: '2026-03-19'
    changes: 'FR76–FR88 ajoutés (Inventaire Avancé & Vente Configurable). Phases 2a/2b mises à jour. Table des matières, Politique Notifications, UI-Driven retail mis à jour. Source: gaps proposition client Blandine.'
  - date: '2026-03-19'
    changes: 'FR89–FR91 ajoutés (Variantes, Multi-tarifs & Promotions). Phase 2b et Phase 3 mises à jour. Table des matières FR1–FR91.'
  - date: '2026-03-19'
    changes: 'Post-validation fixes: version header 5.0→6.1, FR45 measurability rewrite, NFR15/NFR16 implementation-name removal.'
  - date: '2026-03-19'
    changes: 'FR92–FR97 ajoutés (Traçabilité Articles & Configurations Métier). Phase 2b mise à jour. Table des matières FR1–FR97. Version 6.1→6.2.'
  - date: '2026-03-19'
    changes: 'FR98–FR99 ajoutés (Retours & Réservations). Phase 2a (FR98) et Phase 2b (FR99) mises à jour. Table des matières FR1–FR99. Version 6.2→6.3.'
  - date: '2026-03-20'
    changes: 'FR100–FR103 ajoutés (Plans Tarifaires & Facturation). PlanDefinition par tenant (FR100, Phase 2a) ; frais installation + statuts facturation trial/active/overdue/suspended (FR101, Phase 2a) ; consultation plan + demande upgrade propriétaire (FR102, Phase 2a préparé Phase 3) ; paiement en ligne Mobile Money/carte + auto-provisioning tenant (FR103, Phase 3). Table des matières FR1–FR103. Version 6.3→6.4.'
  - date: '2026-03-20'
    changes: 'FR104–FR106 ajoutés (Configuration Business Type). BusinessTypeDefinition configurable sans déploiement avec flags produit par défaut, sections visibles et catégories suggérées (FR104, Phase 2a) ; formulaire produit adaptatif au businessType — priorité et pré-remplissage des champs pertinents, masquage des champs non-pertinents, override par produit toujours possible (FR105, Phase 2a) ; pré-création automatique des catégories suggérées à la création du tenant (FR106, Phase 2a). Phase 2a mise à jour. Table des matières FR1–FR106. Version 6.4→6.5.'
  - date: '2026-03-22'
    changes: 'Vision stratégique documentée : 3 nouvelles sections ajoutées après Verticaux Futurs — Limites d''Usage par Plan (Phase 2a), Intelligence Artificielle Roadmap (Phase 2b→Phase 4), Scalario Platform Écosystème Inter-Entreprises (Phase 3+). Documentation uniquement — aucun epic, aucune implémentation. Version 6.6→6.7.'
  - date: '2026-03-30'
    changes: 'Version 8.3 — (1) Parcours Commercial H1 ajouté en section Onboarding : modèle validé Blandine (présentation → signature → Orange Money → config on-site → formation → go-live en une visite). (2) Naming tiers unifié Starter/Business/Pro/Enterprise (aligné Innovation Strategy) — remplacement "Retail Standard/Retail Premium" dans onboarding table et SLAs. (3) Blandine positionnée Pro tier client fondateur 40K FCFA/mois (vs 55K normal).'
  - date: '2026-03-30'
    changes: 'Version 8.2 — Ajout section Infrastructure & Déploiement : stack Railway + Supabase Pro par horizon (H1→H3+), distribution Flutter APK direct H1 → Play Store H2 → Web H3, environnements dev/staging/prod, CI/CD GitHub Actions + Fastlane, sécurité secrets + backups. 5 nouveaux NFR (NFR-INFRA-01–05) : deploy < 5 min, zero data loss, rollback < 2 min, backup quotidien, staging avant canal intégrateur. ToC mis à jour (entrée 12c).'
  - date: '2026-03-30'
    changes: 'Version 8.1 — Ajout section Super Admin Scalario (Backoffice Opérationnel) : interface interne équipe Scalario distincte du backoffice tenant et du dashboard intégrateur. Périmètre H1→Phase 3. 6 nouveaux FRs (FR-SUPERADMIN-01–06) : création tenant, suspension/réactivation, billing dashboard, onboarding intégrateur, feature flags par tenant, review marketplace templates. ToC mis à jour (entrée 12b). Journeys 9–12 ajoutés (multi-POS, intégrateur, cabinet comptable, AI config). NFR39 : latence alertes anomalies précisée (< 60s). Validation rapport : status IN_PROGRESS → COMPLETE.'
  - date: '2026-03-30'
    changes: 'Version 8.0 — (0) FR-RBAC-01 ajouté : RBAC Dynamique par Tenant avec dette technique Story 1.2 documentée (kernel.roles sans tenant_id, guard hardcodé). Migration schema H1 + API Phase 2b + AI RBAC Phase 2c. (1) REQUALIFICATION DES VERTICALS : section "Verticaux Futurs" → "Secteurs Cibles & Modules Core". Chaque secteur cible = Template Sectoriel (config) + Modules Core requis (nouveau code). 7 nouveaux FRs Phase 3+ : FR-DEVIS-01, FR-WORKORDER-01, FR-BOM-01, FR-ATELIERPLANNING-01, FR-TABLE-01, FR-KDS-01, FR-APPOINTMENT-01. Toutes les références "vertical marché" → "secteur" dans le document (Succès Business/Technique, journeys, FRs, glossaire, concurrents, tarification, registre modules, RBAC, UI-Driven section). (2) FONDATIONS ARCHITECTURALES H1 : nouvelle subsection dans Phase 1 avec tableau non-négociables (i18n NFR31, /api/v1/ NFR35, payment adapters NFR33, compliance pluggable NFR32). Règle explicite : ne pas bloquer H1 pour implémenter H2. (3) MODÈLE DE REVENU 3 HORIZONS : nouvelle section "Évolution du Modèle de Revenu" avec tableau H1/H2/H3 (abonnement → distribution → réseau). Modèle de revenu dans Critères de Succès mis à jour avec les 3 horizons. (4) ROADMAP PAR MODULES : "Roadmap des Verticaux" → "Roadmap des Modules (Publique)" — table remplacée par phases de modules Core (Phase 1–4) avec secteurs déverrouillés via template. (5) MODÈLE DE RESPONSABILITÉ : nouvelle section — qui construit quoi : Scalario team / Intégrateurs / Intégrateurs avancés / Clients finaux.'
  - date: '2026-03-30'
    changes: 'Version 7.0 — Décisions stratégiques session Innovation Strategy 2026-03-29 intégrées. (1) Vision universelle : Scalario n''est plus "ERP commerce UEMOA" mais plateforme universelle pour toute organisation — UEMOA = beachhead, pas plafond. Classification domain mis à jour. (2) 10 nouveaux NFR architecturaux (NFR31–NFR40) : i18n complet, compliance pluggable, payment adapter pattern, unités configurables, API versionnée /api/v1/, certificate pinning Flutter, rate limiting, subscription enforcement server-side, anomaly detection H2, trajectoire microservices. (3) 5 nouveaux FR AI (FR-AI-01 à FR-AI-05) : section LLM dédiée, actions AI-invocables par module, Excel/CSV import, NL config, Config Wizard universel. (4) 2 FR Template Builder (FR-TEMPLATE-01/02). (5) FR-MULTISTORE-01 : multi-points de vente 3 modèles. (6) FR-MULTISERVICE-01 : dashboard multi-clients professionnels. (7) FR-SESSION-01 : gestion sessions utilisateurs. (8) Nouvelles sections : Écosystème Commercial Channels, Flywheel Architecture. (9) Corrections conflits : notes plugin ajoutées sur FR64 (CNSS BF), FR69 (OHADA), FR103 (payment adapter), FR86 (i18n). (10) Positionnement et framing stratégique mis à jour pour scope universel.'
classification:
  projectType: saas_b2b
  domain: universal_platform_any_organization
  complexity: high
  projectContext: brownfield
  elicitationInsights:
    firstPrinciples:
      - Current entities (Product, Order, Customer) must be decomposed into shared base + vertical extensions
      - Three-tier architecture: Kernel (auth, tenants, sync) / Shared (catalog, contacts, transactions, payments, inventory, reporting) / Vertical (POS sessions, retail UI, barcode)
      - Sync engine is kernel but sync schemas are per module
    whatIfScenarios:
      - Catalog must support itemType discriminator: physical | bookable | service
      - Transaction must support lifecycle states: instant | accumulating | scheduled
      - Shared modules use base entity + vertical extension tables pattern
      - Tested against Restaurant, Hotel, Services verticals - kernel untouched in all cases
      - Contacts, Payments, Inventory, Reporting hold perfectly across all verticals
---

# SCALARIO — Product Requirements Document

**Version 8.3** | **Auteur :** Carlos-simpore | **Date :** 2026-03-30

Confidentiel — Carlos-simpore

---

## Historique des Versions

| Version | Date | Auteur | Modifications principales |
|:---|:---|:---|:---|
| 1.0 | 2026-03-08 | Carlos-simpore | Document initial. Architecture kernel/shared/vertical, Retail POS, offline-first, sync engine, user journeys Retail, exigences fonctionnelles et non-fonctionnelles. |
| 2.0 | 2026-03-08 | Carlos-simpore | Ajout UI-Driven Architecture (Server-Driven UI). Ajout Scalario Connect inter-entreprises (Phase 3). Ajout Programme Ambassadeurs (Phase 2b). Mise à jour projections et tarification. |
| 3.0 | 2026-03-08 | Carlos-simpore | Ajout Scalario Enterprise multi-départements (RH, Comptabilité OHADA, Secrétariat, Logistique). Modèle Intégré / Fédéré. Flux inter-départements. Mise à jour cohérence Executive Summary, Classification, Succès, NFR, Tarification, Risques. |
| 4.0 | 2026-03-11 | Carlos-simpore | Ajout journeys Enterprise (DRH/Awa, Comptable/Ibrahim, DG/Serge). RBAC Enterprise complet (5 rôles). Onboarding & Support avec SLAs par offre. Protection des Données & Conformité (loi BF, RGPD, OHADA). Import & Migration Enterprise. Politique Notifications & Alertes. Gestion échecs de sync. Stratégie QA & Tests (DoD, environnements). Positionnement Concurrentiel complet (Retail + Enterprise, matrice comparative). |
| 5.0 | 2026-03-11 | Carlos-simpore | Corrections post-audit : saut de page FR manquant corrigé, FR3/FR10 mis à jour, réglementations étendues à la zone UEMOA/CEMAC (multi-pays), CNSS sans API corrigé (export fichier uniquement), NFR20 restructuré, FR63–FR75 Enterprise ajoutés, Annexes A et B complétées, OHADA Phase 2b clarifié, Table des matières ajoutée. |
| 6.0 | 2026-03-19 | Carlos-simpore | Ajout FR76–FR88 (Inventaire Avancé & Vente Configurable) : unitType configurable, vente au poids, commandes fournisseurs + réception liée, alertes stock bas par produit, résumé quotidien automatique, pertes avec emplacement, circuit de réapprovisionnement interne (Phase 2a) ; conversion vrac→détail et dates de fraîcheur + code couleur (Phase 2b). Mise à jour phases 2a/2b, Table des matières, Politique Notifications, UI-Driven retail. Issu des gaps identifiés dans la proposition client Blandine. |
| 6.1 | 2026-03-19 | Carlos-simpore | Ajout FR89–FR91 (Variantes, Multi-tarifs & Promotions) : variantes article avec attributs tenant-configurables (Phase 2b), niveaux de prix multiples avec sélection automatique par customerType ou quantité (Phase 2b), règles de promotion configurables remise/%/X+Y/prix barré (Phase 3). Mise à jour phases 2b et 3, Table des matières FR1–FR91. |
| 6.2 | 2026-03-19 | Carlos-simpore | Ajout FR92–FR97 (Traçabilité Articles & Configurations Métier) : numéros de série traçables par unité (FR92), certificats de garantie (FR93), prescription ordonnance (FR94), date de garde optimale sur lot (FR95), prix dynamique avec historique (FR96), article unique dépôt-vente (FR97). Mise à jour Phase 2b, Table des matières FR1–FR97. |
| 6.3 | 2026-03-19 | Carlos-simpore | Ajout FR98–FR99 (Retours & Réservations) : retour article au POS avec politique tenant configurable — remboursement/avoir/échange, réintégration stock RETURN (FR98, Phase 2a) ; réservation avec acompte partiel configurable, suivi solde client, KPI dashboard (FR99, Phase 2b). Mise à jour phases 2a/2b, Table des matières FR1–FR99. |
| 6.4 | 2026-03-20 | Carlos-simpore | Ajout FR100–FR103 (Plans Tarifaires & Facturation) : plan tarifaire par tenant avec PlanDefinition — free/standard/premium/enterprise, changement plan auto-applique modules et maxUsers, downgrade avec confirmation (FR100, Phase 2a) ; frais d'installation/formation + statuts facturation trial/active/overdue/suspended + suspension auto configurable (FR101, Phase 2a) ; consultation plan et demande upgrade par propriétaire tenant (FR102, Phase 2a — self-service préparé Phase 3) ; paiement en ligne Mobile Money/carte + onboarding self-service + auto-provisioning tenant (FR103, Phase 3). Architecture anticipée dès Phase 2a (champs Tenant + PlanDefinition). Mise à jour phases 2a et 3, Table des matières FR1–FR103. |
| 6.5 | 2026-03-20 | Carlos-simpore | Ajout FR104–FR106 (Configuration Business Type) : BusinessTypeDefinition configurable sans déploiement — code unique, nom, flags produit par défaut (trackSerialNumbers, hasVariants, warrantyMonths, expiryDays, requiresPrescription, isUnique, dynamicPricing, unitType), sections visibles dans le formulaire produit, catégories suggérées, icône admin (FR104, Phase 2a) ; formulaire produit adaptatif au businessType — champs pertinents prioritaires et pré-remplis, champs non-pertinents masqués avec toggle "Afficher plus d'options", override par produit toujours possible (FR105, Phase 2a) ; pré-création automatique des catégories suggérées à la création du tenant (FR106, Phase 2a). 13 types seedés (généraliste, épicerie, téléphonie, textile, pharmacie, quincaillerie, électroménager, cave à vin, bijouterie, dépôt-vente, boulangerie, station service, grossiste). Mise à jour Phase 2a, Table des matières FR1–FR106. |
| 6.6 | 2026-03-20 | Carlos-simpore | Ajout FR107–FR111 : Commandes clients avec lifecycle complet draft→paid, lignes produit avec variantes et quantités réelles livrées, document de livraison configurable par business type (FR107–FR109, Phase 2a) ; dashboard commandes en cours + paiements partiels + solde client (FR110, Phase 2a) ; labels de rôle par business type (commercial → "Chauffeur-livreur", etc.) via BusinessTypeDefinition.roleLabels (FR111, Phase 2a). Ajout business type "distribution" (14e type). Mise à jour Phase 2a, Table des matières FR1–FR111. |
| 7.0 | 2026-03-30 | Carlos-simpore | Vision universelle : Scalario = plateforme universelle pour toute organisation, UEMOA = beachhead. 10 NFR architecturaux (NFR31–NFR40) : i18n, compliance pluggable, payment adapter, unités configurables, API /api/v1/, certificate pinning, rate limiting, subscription enforcement server-side, anomaly detection, trajectoire microservices. FR-AI-01 à FR-AI-05 (AI Assistant dédié, actions AI-invocables, Excel import, NL config, Config Wizard). FR-TEMPLATE-01/02 (Template Builder). FR-MULTISTORE-01 (Multi-POS). FR-MULTISERVICE-01 (Dashboard Multi-Clients Pro). FR-SESSION-01 (Sessions). Sections Écosystème Commercial Channels + Flywheel Architecture. Corrections conflits : FR64/FR69/FR103/FR86 enrichis de notes plugin/adapter. Positionnement et framing mis à jour scope global. |

---

## Table des Matières

| # | Section | Contenu |
|:---|:---|:---|
| 1 | Executive Summary | Vision, principes fondateurs, ce qui rend Scalario unique |
| 2 | Classification du projet | Type, domaine, complexité, stack, état actuel |
| 3 | Critères de Succès | Métriques utilisateur, business et technique |
| 4 | Périmètre du Produit & Phases | Phase 1 (MVP) + Fondations Architecturales H1, 2a, 2b (Croissance), 3 (Expansion) |
| 4a | Fondations Architecturales H1 | i18n, /api/v1/, payment adapters, compliance pluggable — non-négociables H1 |
| 5 | UI-Driven Architecture | Server-Driven UI, modules par métier, roadmap secteurs |
| 6 | Scalario Connect | Interconnexion inter-entreprises, flux B2B, structure DB |
| 7 | Scalario Enterprise | Multi-départements, modes Intégré / Fédéré, flux inter-dép. |
| 8 | Programme Ambassadeurs | Modèle économique, profils, fonctionnalités, kit |
| 9 | Exigences Domain-Spécifiques | Conformité FEC/DGI, devise FCFA, anti-fraude, résilience |
| 10 | User Journeys (1–8) | Retail (Fatou, Blandine, Moussa, Carlos) + Enterprise (Awa, Ibrahim, Serge) + Offline |
| 11 | Exigences SaaS B2B | Multi-tenancy, RBAC Retail & Enterprise, modules, intégrations |
| 12 | Onboarding & Support Client | Processus par offre, SLAs, kit Ambassadeur |
| 12b | Super Admin Scalario (Backoffice Opérationnel) | Interface interne équipe Scalario — création tenants, billing, feature flags, marketplace templates |
| 12c | Infrastructure & Déploiement | Railway + Supabase Pro, APK direct H1, CI/CD GitHub Actions, NFR-INFRA-01–05 |
| 13 | Protection des Données & Conformité | Cadre légal BF/OHADA/RGPD, données sensibles, droits utilisateurs |
| 14 | Import & Migration Enterprise | Formats CSV, règles migration Retail → Enterprise, gestion erreurs |
| 15 | Politique Notifications & Alertes | Matrice événements/canaux/destinataires, règles anti-spam |
| 16 | Gestion des Échecs de Sync | Cycle de vie outbox, conflits financiers, monitoring admin |
| 17 | Stratégie QA & Tests | Niveaux de tests, DoD, environnements (Local / Staging / Prod) |
| 18 | Positionnement Concurrentiel | vs Odoo/Wave/Colibris/SAP/Sage, matrice universelle |
| 19 | Écosystème Commercial Channels | Cabinets comptables, franchiseurs, groupements, professionnels |
| 19b | Modèle Intégrateur Mini-Opérateur SaaS | Canaux directs/indirects, bundles, prix plancher/plafond, fee dégressif |
| 20 | Flywheel Architecture | Module Core → secteurs déverrouillés via templates |
| 20b | Modèle de Responsabilité | Scalario team / Intégrateurs / Clients — qui construit quoi |
| 21 | Exigences Fonctionnelles (FR1–FR111) | Toutes les exigences numérotées par module |
| 21a | FR-AI-01 à FR-AI-05 | AI Assistant dédié, actions invocables, Excel import, NL config, Config Wizard |
| 21b | FR-TEMPLATE-01 à FR-TEMPLATE-02 | Template Builder AI-driven pour intégrateurs |
| 21c | FR-MULTISTORE-01 | Gestion Multi-Points de Vente (3 modèles) |
| 21d | FR-MULTISERVICE-01 | Dashboard Multi-Clients Professionnels |
| 21e | FR-SESSION-01 | Gestion des Sessions Utilisateurs |
| 21f | FR-INTEGRATOR-01 à FR-INTEGRATOR-04 | Prix plancher/plafond intégrateur, fee dégressif, commission récurrente |
| 21g | FR-DEVIS-01 à FR-APPOINTMENT-01 | Modules Core Sectoriels Phase 3+ : Artisan/Atelier, Restaurant, Services |
| 21h | FR-RBAC-01 | RBAC Dynamique par Tenant — rôles data-driven, dette technique Story 1.2 documentée |
| 22 | Exigences Non-Fonctionnelles | Performance, sécurité, fiabilité, scalabilité, réseau, architecture (NFR1–NFR40) |
| 23 | Croissance & Projections | Projections sur 10 ans, tarification complète, évolution revenus 3 horizons, infrastructure |
| 24 | Gestion des Risques | Risques techniques, marché, ressources avec mitigations |
| A | Annexe A — Tests de Validation | 9 tests clés avec critères de réussite |
| B | Annexe B — Résumé des Innovations | 9 innovations différenciantes |
| C | Annexe C — Glossaire | 24 termes définis |

---

## Executive Summary

Scalario est une plateforme de gestion universelle, modulaire et multi-tenant, conçue pour toute organisation dans le monde — commerce, industrie, éducation, santé, hôtellerie, mines, agriculture, ONG, coopératives, services juridiques et toute structure qui a besoin de gérer des opérations, des équipes et des flux financiers. Contrairement aux ERP occidentaux (SAP, Odoo Enterprise) qui imposent des workflows rigides, supposent une connectivité permanente et nécessitent des consultants à 500 €/jour, Scalario adopte une approche « business-first » : le système s'adapte au métier et à la réalité terrain, configurable sans code, déployable via AI en heures, pas en semaines.

La plateforme repose sur une architecture quatre niveaux — Kernel (identité, multi-tenancy, moteur de sync), Shared Modules (catalog, contacts, transactions, paiements, inventaire, reporting), Modules Fonctionnels (logique métier générique, réutilisable par tous les secteurs) et Templates Sectoriels (bundles de configuration pré-définis par secteur, activables sans développement). Cette structure permet à tout nouveau secteur (éducation, hospitalité, agriculture) de s'intégrer via un template sans toucher au kernel ni au code Flutter. Le même Kernel sert une boutique de quartier, un cabinet comptable et une coopérative agricole de 500 membres.

Le principe fondateur est l'offline-first : le client écrit toujours localement et synchronise dès que la connectivité revient. Ce n'est pas un mode dégradé — c'est le mode d'opération primaire, conçu pour tous les environnements où internet est l'exception, des marchés émergents aux zones rurales mondiales.

Le beachhead de validation est le Retail UEMOA — le marché le plus exigeant en termes de contraintes (offline, mobile money, unités locales, conformité OHADA) — actuellement en production chez 3 clients. Valider ici = valider pour n'importe quel marché. La feuille de route étend Scalario vers tout secteur via le mécanisme Templates Sectoriels, sans développement sectoriel dédié. À terme, Scalario Connect permet à toute organisation sur la plateforme d'échanger des documents transactionnels avec ses partenaires directement depuis l'interface métier.

### Ce qui rend Scalario unique

- **Transparence réseau :** quand la connexion tombe, l'utilisateur ne le remarque pas. Les opérations continuent, la sync se fait silencieusement à la reconnexion. Valable partout dans le monde — pas seulement en Afrique.
- **Contrôle passif du business :** résumés automatiques chaque soir pour les propriétaires absents. Tableaux de bord temps réel pour les dirigeants. Délégation d'accès pour les professionnels de service (comptables, consultants).
- **Universal-first, pas configuration-first :** aucune string hardcodée, aucune devise hardcodée, aucune réglementation en dur. FCFA/OHADA/CNSS sont les plugins du beachhead UEMOA — KES/IFRS/NHIF Kenya sont le prochain plugin. La conformité locale s'adapte, le kernel ne change pas.
- **Couche partagée polymorphe :** base-entity + extension sectorielle via Template, 60–80 % de réutilisation entre chaque nouveau secteur ou département.
- **Templates Sectoriels AI-driven :** un intégrateur décrit le secteur en langage naturel, l'AI configure les modules, rôles, workflows et vocabulaire. Tout secteur = configurable sans développement Flutter. Aucune exclusion par taille ou secteur.
- **UI-Driven Architecture :** une seule app Flutter, N métiers et départements. L'interface s'adapte dynamiquement au type de métier ou de département sans mise à jour Play Store.
- **AI comme couche d'interface universelle :** tout ce qui est configurable via UI est configurable via AI — dans une section dédiée, pas injecté sur les écrans modules. L'AI génère des action chips contextuels qui déclenchent des fonctions pré-définies dans les modules.
- **Scalario Connect (Phase 3) :** tout tenant peut passer des bons de commande à un autre tenant. Boutique → grossiste, cabinet → client, coopérative → distributeur. Un seul réseau.
- **Scalario Enterprise (Phase 3) :** un seul Kernel pour gérer une boutique et une PME avec RH, comptabilité, secrétariat et logistique. Mode Intégré (un tenant, N départements) ou Mode Fédéré (N entités liées) selon la taille.
- **Programme Ambassadeurs (Phase 2b) :** les clients satisfaits deviennent une force de vente terrain rémunérée via Mobile Money, sans coût fixe pour Scalario.
- **Slogan :** À définir — direction : universel, inclusif, aucune exclusion par taille ou secteur.

---

## Classification du projet

| Dimension | Valeur |
|:---|:---|
| Type de projet | SaaS B2B — Plateforme universelle de gestion multi-tenant modulaire |
| Domaine | Plateforme universelle — toute organisation (commerce, industrie, éducation, santé, hôtellerie, mines, agriculture, ONG, coopératives, services, juridique et tout secteur). Beachhead : UEMOA Retail. Vision : global-first. |
| Complexité | Haute — Architecture quatre niveaux (Kernel/Modules Fonctionnels/Templates Sectoriels/AI Config), entités partagées polymorphes, sync offline-first, UI-Driven Engine, modèle départemental, compliance pluggable, payment adapters, i18n natif |
| Contexte | Brownfield — Restructuration du POS monolithique en architecture modulaire universelle extensible |
| Stack | Flutter + NestJS + Supabase + Prisma + Isar |
| État actuel | 3 clients retail actifs (Phase 1). Roadmap : tout secteur via Templates Sectoriels AI-driven, sans développement Flutter dédié |
| Slogan | À définir — direction : universel, inclusif, aucune exclusion par taille ou secteur |

---

## Critères de Succès

### Succès Utilisateur

| Persona | Métrique de succès | Cible |
|:---|:---|:---|
| Caissier | Autonome après formation | < 1h : ouvrir session, chercher produit, vendre, encaisser, fermer session |
| Propriétaire boutique | Autonome sur config et rapports | < 3h : produits, catégories, prix, lecture des rapports |
| Gestionnaire stock | Autonome sur opérations stock | < 2h : réception, transferts, ajustements |
| Caissier (offline) | Travail en shift complet sans connectivité | 8h+, zéro perte de données, zéro interruption |
| Propriétaire (distant) | Résumé WhatsApp reçu automatiquement | Quotidien : CA, pertes, écarts, stock critique, top 3. Lisible en < 10s |
| DRH / Responsable RH | Autonome sur gestion employés et paie | < 3h : fiche employé, calcul paie, bulletin, déclaration CNSS |
| Comptable / DAF | Autonome sur comptabilité OHADA | < 4h : saisie écriture, grand livre, bilan, export expert-comptable |
| DG / Directeur | Dashboard consolidé multi-départements | Vision en temps réel : CA boutique + masse salariale + engagements achats sur un écran |
| Tous | Sync après reconnexion | < 30s pour une journée entière de transactions |

### Succès Business

| Horizon | Cible | Priorité |
|:---|:---|:---|
| 6 mois | 3 clients migrés + 5–10 nouveaux clients retail | Qualité et fiabilité avant quantité |
| 12 mois | 20–30 clients retail actifs + 1 nouveau secteur servi (Pharmacie ou Services) via Template Sectoriel + Modules Core requis | Premier revenu récurrent stable |
| Phase 3 (18–24 mois) | Scalario Connect + Scalario Enterprise lancés. Premiers clients PME multi-départements | Panier moyen clients Enterprise : 25–50k FCFA/mois |
| Signal de succès | 5 clients satisfaits qui recommandent activement | Croissance par parrainage Ambassadeurs |
| Modèle de revenu | **H1** : abonnement direct mensuel (Retail 15k, Enterprise 25–50k). **H2** : + canal intégrateur wholesale (fee dégressif, marge intégrateur — voir FR-INTEGRATOR-01–04) + commissions Ambassadeurs + pricing modulaire par composant. **H3** : + frais réseau Scalario Connect (take-rate B2B) + self-service onboarding automatisé (FR103). | 3 horizons de revenus : abonnement → distribution → réseau |

### Succès Technique

| Métrique | Cible | Validation |
|:---|:---|:---|
| Sécurité migration | Zéro perte de données pour 3 clients existants | Fenêtre de maintenance 1–2 jours acceptable |
| Vélocité nouveau secteur | 2–4 semaines par Module Core requis. Template Sectoriel configuré en heures | Secteur servi via Template + Modules Core sans toucher le kernel |
| Intégrité architecture | Ajouter un Template Sectoriel ou un département Enterprise ne nécessite jamais de changement kernel | Si template Pharmacie ou module RH touche le kernel = échec |
| Fiabilité offline | Shift 8h, zéro perte de données, sync silencieuse | Délai sync < 30s pour journée complète |
| Réutilisation modules partagés | 60–80 % de la couche data d'un secteur ou département | Mesuré par ratio réutilisation entités |
| UI-Driven Engine | Ajout d'un nouveau métier ou département via config JSON sans deploy Flutter | Le layout RH diffère du layout Retail sans branching applicatif |
| Scalario Enterprise | Un tenant PME avec 4 départements actifs sans dégradation de performance | Isolation des vues de données par département validée par les RLS |

---

## Périmètre du Produit & Phases

### Phase 1 — MVP : Restructuration incrémentale

Même fonctionnalité, nouvelle architecture. Décomposer le monolithe en kernel/shared/vertical. Zéro nouvelle fonctionnalité sauf l'arrondi FCFA à 5 francs dans le module Payments. 3 clients migrés sans perte de données.

#### Fondations Architecturales H1 (Non-Négociables)

> **Règle :** H1 = livrer FR1–FR111 sans tout refactorer. Mais les quatre fondations suivantes **doivent** être en place dès H1 pour éviter une dette technique bloquante en H2. Ce ne sont pas des features — ce sont des contraintes d'implémentation.

| Fondation | NFR | Règle d'implémentation |
| :--- | :--- | :--- |
| **i18n complet** | NFR31 | Aucune string UI hardcodée en français (ou toute autre langue). Toutes les labels, messages et libellés passent par le système de traduction dès le premier écran. |
| **REST API versionnée /api/v1/** | NFR35 | Toutes les routes backend exposées sous `/api/v1/`. Aucune route sans préfixe de version. Obligatoire avant tout appel client externe. |
| **Payment adapter pattern** | NFR33 | Wave, Orange Money, Mobile Money = adaptateurs pluggables. Aucun provider hardcodé dans la logique métier. Chaque provider est un module isolé. |
| **Compliance pluggable** | NFR32 | OHADA, CNSS, CARFO, TVA = plugins de conformité, pas du code core. Aucune règle fiscale ou sociale hardcodée dans le kernel. |

> **Ne pas bloquer H1 pour implémenter H2.** Template Builder (FR-TEMPLATE-01/02), AI Config (FR-AI-01 à FR-AI-05), Extension Module, secteurs → Templates Sectoriels : tout cela est H2+. H1 implémente ces fondations comme des patterns d'architecture (interfaces, adaptateurs, registres) sans les features H2 qui s'y branchent.

### Phase 2a — Post-restructuration immédiate

- Ventes au poids + unitType configurable par produit (FR76–FR78)
- Commandes fournisseurs + réception liée avec variance et notes qualité (FR79–FR80)
- Alertes stock bas configurables par produit (FR81–FR82)
- Déclaration de perte avec emplacement configurable (FR87)
- Résumé quotidien automatique WhatsApp / push (FR86)
- Circuit de demande de réapprovisionnement interne (FR88)
- Intégration fiscale FEC/DGI (valide file de sync dédiée)
- Retours articles et remboursements (FR98)
- Plans tarifaires et facturation admin (FR100–FR101)
- Consultation plan par le propriétaire (FR102)
- Types de business configurables (FR104–FR106)
- Commandes clients (FR107–FR110)
- Labels de rôle par business type (FR111)

### Phase 2b — Croissance

- Conversion vrac → unité détail avec règles de reconditionnement (FR83)
- Dates de fraîcheur + coefficient de tolérance déshydratation + code couleur POS (FR84–FR85)
- Variantes produit (FR89), multi-tarifs configurables (FR90)
- Traçabilité articles : séries, garantie, ordonnance, garde, prix dynamique, articles uniques (FR92–FR97)
- Dashboard distant propriétaire (mobile)
- **AI Excel/CSV Import catalogue** (FR-AI-03) : upload fichier existant → AI configure automatiquement produits, variantes, unités, prix. Onboarding catalogue 3h → 10 minutes. *(H2 early, Mois 3–6)*
- **AI Natural Language Config produits** (FR-AI-04) : configuration produit, unités, variantes, prix par langage naturel. Résout nativement vrac→sachet, multi-unités. *(H2 early)*
- API Mobile Money (Orange Money / Moov Money) — via payment adapter pattern (NFR33)
- Export OHADA Retail (Phase 2b) : export des écritures de ventes au format OHADA (plugin compliance) pour remise à un expert-comptable externe. Distinct de la comptabilité intégrée Enterprise (Phase 3).
- Réservations avec acompte (FR99)
- Programme Ambassadeurs (voir section dédiée ci-dessous)
- Gestion Multi-Points de Vente — 3 modèles stock (FR-MULTISTORE-01)

### Phase 3 — Expansion

- Promotions configurables (remise %, X+Y gratuit, prix barré temporaire) (FR91)
- Scalario Connect — Interconnexion inter-entreprises (voir section dédiée)
- Scalario Enterprise — Modèle multi-départements PME : RH & Paie, Comptabilité OHADA, Secrétariat, Logistique (voir section dédiée)
- Paiement en ligne + onboarding self-service (FR103) via payment adapter pattern
- Facturation et abonnement intégrés
- **AI Config Wizard Universel** (FR-AI-05) : configuration complète de l'entreprise via conversation — rôles, modules, workflows, permissions, multi-entités, comptabilité, RH, alertes, dashboards. *(H2 mid, Mois 6–12)*
- **Template Builder AI-driven** (FR-TEMPLATE-01/02) : outil pour intégrateurs, configuration secteur complet via langage naturel, sans génération de code Flutter
- **Dashboard Multi-Clients Professionnels** (FR-MULTISERVICE-01) : pour cabinets comptables, consultants, franchiseurs
- **Section LLM Dédiée** (FR-AI-01) : AI assistant dans section dédiée (chat panel / command bar), non injecté sur les écrans modules
- **AI-invocable actions par module** (FR-AI-02) : tout module expose ses actions pour l'AI
- Reporting avancé, prédictions IA (voir Intelligence Artificielle — Phase 3)
- Tout secteur via Templates Sectoriels — éducation, santé, agriculture, ONG, etc. (aucun développement Flutter dédié)
- REST API versionnée /api/v1/ ouverte pour intégrations tierces (NFR35)

### Secteurs Cibles & Modules Core (Phase 3+)

Le principe est : **un secteur = un Template Sectoriel + les Modules Core qu'il requiert**. Les Templates Sectoriels sont de la configuration pure (business types, rôles, vocabulaire, workflows, données par défaut) — aucun développement Flutter dédié. Les Modules Core requis sont du nouveau code métier — chacun a son propre FR et sert plusieurs secteurs simultanément.

Le champ `vertical` est déjà présent dans le schéma (Phase 2a anticipation) et vaut `"retail"` pour tous les types actuels. La priorisation est guidée par le Flywheel : quel Module Core déverrouille le plus de secteurs ?

---

**Secteur Artisan / Atelier** — Fabrication sur commande

Business types : `tailleur`, `menuisier`, `forgeron`, `cordonnier`, `imprimeur`, `artisan_general`

**Template Sectoriel** (configuration existante — aucun dev Flutter dédié) :

- Types business configurés dans `BusinessTypeDefinition` avec flags métier (`hasVariants`, `dynamicPricing`, `unitType`, etc.)
- Catalogue modèles/designs : module Catalog existant avec images (`itemType = design`)
- Gestion matières premières : module Inventory existant (stock, alertes, réapprovisionnement)

**Modules Core requis** (nouveau code — FR Phase 3+) :

- `devis_fabrication` **(FR-DEVIS-01)** : devis matériaux + main d'œuvre + marge, accepté/refusé par client, lié à la commande de fabrication
- `work_order` **(FR-WORKORDER-01)** : commande fabrication avec étapes kanban, statuts, dates estimées, lié au devis
- `bill_of_materials` **(FR-BOM-01)** : nomenclature (BOM) — matériaux requis par produit, consommation automatique du stock à validation de l'ordre
- `atelier_planning` **(FR-ATELIERPLANNING-01)** : planning atelier, file d'attente, capacité, dates de livraison

---

**Secteur Restaurant** — Service en salle

Business types : `restaurant`, `fast_food`, `bar`, `traiteur`

**Template Sectoriel** (configuration existante — aucun dev Flutter dédié) :

- Types business dans `BusinessTypeDefinition`
- Gestion stock alimentation : module Inventory (pertes, dates fraîcheur — FR84/FR85 déjà développés)
- Menu du jour : catalog + catégories + prix temporaires via BusinessTypeDefinition
- Pourboires : type de paiement configurable dans le module Payments

**Modules Core requis** (nouveau code — FR Phase 3+) :

- `table_management` **(FR-TABLE-01)** : plan de salle configurable, attribution table → commande, statuts (libre/occupée/réservée/nettoyage)
- `kitchen_display` **(FR-KDS-01)** : tickets cuisine en temps réel, statuts préparation (reçu/en cours/prêt), notification salle

---

**Secteur Services** — Prestations pures

Business types : `salon_coiffure`, `lavage_auto`, `cyber_cafe`, `photographe`, `services_general`

**Template Sectoriel** (configuration existante — aucun dev Flutter dédié) :

- Catalogue prestations : module Catalog avec `itemType = service`, durée et tarif par prestation
- Historique client : module Contacts (transactions par client déjà disponibles dans le dashboard contacts)
- Encaissement : POS existant avec types paiement Mobile Money

**Module Core requis** (nouveau code — FR Phase 3+) :

- `appointment` **(FR-APPOINTMENT-01)** : prise de rendez-vous, planning créneaux, rappels automatiques client, vue agenda opérateur

---

> **Approche :** On ne "build pas un vertical restaurant". On build le Module Core `table_management`, le Module Core `kitchen_display`, et on crée le Template Sectoriel "Restaurant" qui les configure. Ces mêmes modules servent hôtels (table = chambre), traiteurs (table = livraison), cafétérias. La granularité est le Module Core, pas le secteur. Les secteurs (restaurant, distribution, atelier, services) restent des **marchés cibles valides** — seul le mode d'implémentation change.

---

### Limites d'Usage par Plan (Phase 2a)

Chaque plan a des limites d'usage au-delà des modules activés :

| Limite | Standard | Premium | Enterprise |
|--------|----------|---------|------------|
| Utilisateurs max | 5 | 15 | Illimité |
| Transactions/mois | 500 | Illimité | Illimité |
| Produits catalogue | 200 | Illimité | Illimité |
| Stockage données | 500 Mo | 5 Go | Illimité |
| Historique accessible | 6 mois | 2 ans | Illimité |

Quand un tenant atteint une limite, le système :
- Affiche un banner non-bloquant "Vous avez atteint X% de votre limite"
- À 100% : dialog d'upgrade "Passez au Premium pour continuer"
- NE bloque PAS les opérations critiques (ventes, encaissements)
- Bloque les opérations non-critiques (création produit, nouvel user)
- Le owner voit ses limites dans Paramètres → Mon abonnement

> **Note :** Les limites sont configurées dans `PlanDefinition.limits` (Json), pas hardcodées. Carlos peut ajuster par tenant si nécessaire. Champ d'anticipation prévu dans le schéma — implémentation middleware en Phase 2a.
>
> **Note évolution H2+ (pricing modulaire) :** Ces limites s'appliquent aux plans fixes H1 (Standard/Premium/Enterprise). À partir de H2, la grille évolue vers un pricing par composant actif — les limites seront recalculées dynamiquement selon les modules activés (voir FR-INTEGRATOR-01 et Modèle de Tarification).

---

### Intelligence Artificielle — Roadmap (Phase 2b → Phase 4)

**Principe architectural AI (s'applique à tous les horizons — voir FR-AI-01 à FR-AI-05) :**
L'AI est la couche d'interface universelle sur tout l'ERP — pas une feature parmi d'autres. Tout ce qui est configurable via UI doit être configurable via AI (FR-AI-02). L'AI vit dans une **section dédiée** (chat panel / command bar), jamais injectée sur les écrans modules (FR-AI-01). Dans cette section, l'AI génère des action chips contextuels (listes, boutons, cards) qui déclenchent des fonctions pré-définies dans les modules. Les écrans modules restent pré-construits, propres, prévisibles. L'assistant est indisponible offline — acceptable car les screens fonctionnent normalement sans lui.

L'IA est une couche transversale qui exploite les données accumulées par chaque tenant pour créer de la valeur.

**Phase 2b — IA individuelle (données du tenant seul) — voir aussi FR-AI-03/04 :**

| Fonctionnalité | Description | Module |
|----------------|-------------|--------|
| Prévision de stock | "Vous allez manquer de farine dans 4 jours selon vos ventes" | inventory |
| Détection d'anomalies caisse | "Cette caisse a 3 écarts suspects cette semaine" | reports |
| Suggestions réapprovisionnement | "Commandez 50kg de riz — votre consommation moyenne est 7kg/jour" | purchase_orders |
| Assistant métier | Le commerçant pose une question en français, l'IA répond avec SES données | kernel |
| Scoring crédit client | Historique paiement du client → risque crédit automatique | clients |

Architecture : service IA backend (Python ou API externe) qui consomme les données du tenant via des endpoints internes. L'IA ne voit JAMAIS les données d'un autre tenant (isolation stricte).

**Phase 3 — IA réseau (données agrégées anonymisées) :**

| Fonctionnalité | Description |
|----------------|-------------|
| Recommandation fournisseur | "3 retailers similaires s'approvisionnent chez ce distributeur — satisfaction 94%" |
| Opportunité produit manquant | "12 clients ont cherché ce produit que vous ne proposez pas" |
| Alerte rupture anticipée | "Votre fournisseur a une baisse de 40% de ses sorties — risque de rupture" |
| Benchmark anonyme | "Votre panier moyen est 12% sous la moyenne de votre zone" |
| Matching B2B | "Un grossiste à Bobo cherche un distributeur dans votre zone" |

Architecture : service IA séparé qui opère sur des données AGRÉGÉES et ANONYMISÉES. Aucune donnée individuelle n'est partagée sans consentement explicite du tenant.

**Phase 4-5 — Scalario Intelligence (vision long terme) :**

Scalario devient le "système nerveux commercial" des marchés émergents :
- Cartographie des flux commerciaux B2B en temps réel
- Optimisation des chaînes d'approvisionnement locales
- Indicateurs économiques locaux basés sur les données réelles
- API ouverte pour les institutions financières (scoring PME)

> **Note :** Cette vision est documentée pour orienter les décisions architecturales dès Phase 1 (isolation données, events, audit trail). Aucune implémentation avant Phase 3.

---

### Scalario Platform — Écosystème Inter-Entreprises (Phase 3+)

Extension de Scalario Connect (FR52-FR55) vers un écosystème complet :

```text
Fournisseur ──► Distributeur ──► Retailer ──► Client final
     │               │               │
     └───────────────┴───────────────┘
              SCALARIO NETWORK
         (commandes, paiements, factures,
          stocks en temps réel)
```

**Effets de réseau :**

| Utilisateurs | Valeur |
|-------------|--------|
| 100 clients | Outil utile individuellement |
| 1 000 clients | Connexions inter-entreprises possibles |
| 10 000 clients | L'écosystème = la valeur principale |
| 100 000 clients | Plateforme universelle de référence pour les marchés émergents mondiaux |

**Fonctionnalités Platform :**
- Commandes inter-entreprises (acheteur → vendeur, tout dans Scalario)
- Factures inter-entreprises avec réconciliation automatique
- Paiement Mobile Money B2B intégré
- Catalogue fournisseur partagé (le vendeur publie, l'acheteur commande)
- Marketplace B2B locale (découverte de fournisseurs par zone)

> **Note architecture :** Les champs d'anticipation existent déjà dans le schéma (FR52-FR55 : `referred_by`, `linked_tenant_id`, `supplier_reference`, `transfer_inter_tenant`). La logique métier s'activera en Phase 3.

**Positionnement stratégique :**

Scalario ne bat pas Odoo sur les marchés occidentaux. Scalario rend Odoo non pertinent sur les marchés où 4 milliards de personnes vont s'équiper pour la première fois.

Avantages défensifs :
- Mobile Money natif (pas un plugin)
- FCFA + fiscalité OHADA + TVA locale intégrés
- Interface et support en français
- Pricing PME-friendly (15 000 FCFA vs 50€+ Odoo)
- Onboarding terrain (opérationnel en 48h vs semaines pour Odoo)
- Effet réseau local impossible à reproduire depuis l'extérieur

**Projections utilisateurs :**

| Phase | Horizon | Clients | Utilisateurs |
|-------|---------|---------|--------------|
| Phase 1 | 0–3 ans | 1 000–3 000 | 5K–24K (UEMOA) |
| Phase 2 | 3–7 ans | 20 000–60 000 | 160K–720K (Pan-Afrique) |
| Phase 3 | 7–15 ans | 300 000–1M | 3,6M–15M (Marchés émergents) |

---

## UI-Driven Architecture (Dynamic Vertical UI)

Scalario ne gère pas ses secteurs avec des branches de code distinctes. L'application Flutter embarque un moteur d'interface piloté par le serveur (Server-Driven UI) : le backend envoie une définition JSON du layout, et Flutter le rend dynamiquement selon le `business_type` du tenant.

### Principe fondamental

- Un seul binaire Flutter livré — zéro branching applicatif par métier
- Le Kernel envoie les composants UI actifs via la configuration de module
- Modifier l'interface d'un métier ne nécessite pas de mise à jour Play Store
- Chaque widget est contextuel : Date de péremption (Pharma), Unité poids/mètres (Quincaillerie), Table (Resto)

### Modules UI Contextuels par Métier

| business_type | Widgets activés | Champs spécifiques |
|:---|:---|:---|
| retail | Scanner code-barres, Remise rapide, Grille produits, Indicateur fraîcheur couleur | unitType, weightUnit, stockQuantity, sessionId, freshnessDate, colorCode, lowStockThreshold |
| pharmacy | Alerte péremption, Filtre DCI, Contrôle ordonnance | expiryDate, dci, ordonnanceRequired, lotNumber |
| services | Facturation horaire, Gestion devis | hourlyRate, quoteId, serviceDate |
| wholesale | Picking list, Gestion lots, Tarifs volume | batchId, volumeDiscount, pickingStatus |
| restaurant | Gestion tables, Bons de commande cuisine | tableNumber, courseOrder, kitchenStatus |
| enterprise_hr | Fiches employés, Bulletin de paie, CNSS | employeeId, contractType, salaryBase, cnssRef |
| enterprise_accounting | Grand livre, Balance, États OHADA | accountCode, journalType, fiscalPeriod |
| enterprise_secretariat | Courrier, Agenda, Archivage | documentType, dueDate, recipientDeptId |
| enterprise_logistics | Bons commande, Parc matériel, Fournisseurs | assetId, purchaseOrderRef, deliveryStatus |

### Roadmap des Modules (Publique)

> *La roadmap est communicable publiquement par modules — pas par secteurs. Chaque nouveau module déverrouille automatiquement des secteurs entiers via Templates Sectoriels, sans développement dédié. Les secteurs (pharmacie, restauration, etc.) deviennent ainsi accessibles dès qu'un module requis est livré.*

| Phase | Modules Core livrés | Secteurs déverrouillés via Template |
| :--- | :--- | :--- |
| Phase 1 (actuel) | POS + Stock + Workflows + Multi-rôles + Multi-entités + Sync offline | Commerce de détail, grossistes simples |
| Phase 2a | Module Plans & Facturation modulaire + Module Client Orders + BusinessType Config | Tout commerce configuré (distribution, épicerie, quincaillerie, etc.) |
| Phase 2b | Module RH & Paie + AI Excel/CSV Import + AI Natural Language Config | Toute PME avec employés. Onboarding catalogue accéléré. |
| Phase 2c | AI Config Wizard Universel + Template Builder AI-driven | Tout intégrateur peut configurer n'importe quel secteur sans dev |
| Phase 3 | Module Projets/Chantiers + CRM Avancé + Module Comptabilité OHADA + Dashboard Multi-clients | BTP, ONG, consultants, cabinets comptables, franchiseurs |
| Phase 4 | Module Gestion Documentaire + Module Dossier Patient + SDK tiers | Cabinets juridiques, cliniques, pharmacies avancées, administrations |

---

## Scalario Connect — Interconnexion Inter-Entreprises (Phase 3)

Scalario Connect est le module permettant à deux entités distinctes sur la plateforme d'échanger des documents transactionnels (bons de commande, factures, confirmations de livraison) directement dans leur interface métier respective.

> *Ce module est placé en Phase 3. Cependant, la structure de données doit anticiper ces relations dès la Phase 1 (champs référentiels, pas de logique applicative).*

### Concept Node-to-Node (Acheteur / Vendeur)

La relation n'est pas linéaire (Grossiste → Détaillant). C'est un graphe universel :
- Tout tenant Scalario peut être Acheteur, Vendeur, ou les deux simultanément
- Une pharmacie commande à un distributeur médical
- Une boutique commande à un grossiste alimentaire
- Une entreprise commande des fournitures à une papeterie
- Un restaurant commande à ses fournisseurs de produits frais

### Flux transactionnel inter-tenant

| Étape | Acheteur (Tenant A) | Vendeur (Tenant B) |
|:---|:---|:---|
| 1. Alerte stock | Reçoit notification « Stock bas » | — |
| 2. Bon de commande | Crée un Shared_Order depuis son catalogue fournisseurs | — |
| 3. Réception commande | — | Reçoit le bon de commande en temps réel |
| 4. Validation | — | Valide / modifie / rejette la commande |
| 5. Expédition | — | Marque « Expédié » — stock déduit chez B |
| 6. Réception | Confirme la réception physique | Stock crédité chez A automatiquement |
| 7. Rapprochement | Facture auto-générée et rapprochée | Facture marquée payée |

### Structure de données à anticiper (Phase 1)

| Table | Champ à ajouter | Utilité |
|:---|:---|:---|
| shops / tenants | network_visible (bool) | Le tenant accepte d'être découvert par d'autres tenants |
| catalog_items | supplier_reference (uuid nullable) | Lien vers l'article du fournisseur sur Scalario |
| contacts | linked_tenant_id (uuid nullable) | Un fournisseur = aussi un tenant Scalario |
| transactions | type: transfer_inter_tenant | Distinguer les transactions internes des inter-tenants |

### Confidentialité et isolation

- L'Acheteur ne voit jamais les marges ni le stock total du Vendeur
- Le Vendeur ne voit jamais le prix de revente de l'Acheteur
- Les RLS Supabase garantissent l'isolation au niveau base de données
- Seuls les documents partagés (Shared_Order) sont mutuellement visibles

### Effet de réseau (Network Effect)

> *Chaque grossiste qui adopte Scalario Connect incite ses détaillants à adopter la plateforme pour simplifier les commandes. La migration d'un client vers un concurrent exige de convaincre simultanément tous ses partenaires commerciaux. C'est le verrou stratégique long terme de Scalario.*

---

## Scalario Enterprise — Modèle Multi-Départements (Phase 3)

Scalario Enterprise étend la plateforme aux entreprises structurées qui ont plusieurs départements internes. **Les départements sont des données configurables par tenant, définies par le Template — pas des valeurs hardcodées dans le système.** Chaque Template sectoriel livre une structure organisationnelle préconfigurée comme point de départ. Un tenant peut ensuite créer, renommer et structurer ses unités librement via AI Config. Exemples : Template Retail → Direction, Ventes, Stock, Caisse ; Template Enterprise PME → RH, Comptabilité, Secrétariat, Logistique ; Template Juridique → Direction, Contentieux, Conseil, Secrétariat ; Template Hôpital → Direction, Médical, Infirmier, Pharmacie. C'est le passage du marché « Boutique » au marché « PME », avec un panier moyen significativement plus élevé et une fidélité structurellement plus forte.

### Modèle de structure selon la taille

Deux modes coexistent selon la maturité de l'organisation :

| Mode | Pour qui | Fonctionnement | Exemple |
|:---|:---|:---|:---|
| Mode Intégré (Un tenant, N départements) | PME de taille moyenne (5–50 employés) | Un seul tenant Scalario. Les départements sont des sous-unités (department_id) partageant le même tenant. Chaque département a ses propres rôles, modules actifs et vues de données. | Une entreprise de transport : la direction voit tout, le RH voit uniquement la paie, le comptable voit uniquement les finances. |
| Mode Fédéré (N tenants liés) | Groupes / Holdings (50+ employés, multi-sites) | Chaque entité (filiale, agence) est un tenant indépendant. Un tenant « Groupe » consolide les rapports via Scalario Connect. Isolation totale des données entre filiales. | Un groupe avec une pharmacie, une clinique et une boutique d'optique : trois tenants, un dashboard de consolidation pour le DG. |

> *La décision Mode Intégré vs Mode Fédéré est configurée par l'admin à la création du tenant. Elle peut évoluer — une PME qui grandit peut migrer d'Intégré vers Fédéré sans perte de données.*

### Structures Organisationnelles par Template (valeurs par défaut)

> **Principe :** La structure organisationnelle est définie par le Template — jamais hardcodée dans le système. La table `departments(id, tenantId, name, type)` est tenant-driven. H1 livre chaque Template avec une structure préconfigurée comme point de départ. Phase 2c active la personnalisation libre via AI Config (renommage, ajout, suppression d'unités).

| Template Sectoriel | Départements par défaut | Secteur cible |
| :--- | :--- | :--- |
| Template Retail | Direction, Ventes, Stock, Caisse | Commerce de détail, épicerie, boutique |
| Template Enterprise PME | RH, Comptabilité, Secrétariat, Logistique | PME structurée, agence, cabinet |
| Template Juridique *(Phase 3+)* | Direction, Contentieux, Conseil, Secrétariat | Cabinet d'avocats, étude notariale |
| Template Hôpital *(Phase 3+)* | Direction, Médical, Infirmier, Pharmacie | Clinique, hôpital, centre de santé |

### Détail — Template Enterprise PME (départements par défaut)

> **Ces départements sont des valeurs par défaut préconfigurées pour le Template Enterprise PME.** Ils sont modifiables par chaque tenant via AI Config : renommage libre, ajout de nouveaux départements (ex: "Direction Commerciale", "Support Client", "R&D"), suppression des départements non utilisés, configuration des modules actifs par département. Le système ne hardcode aucun nom de département — la table `departments(id, tenantId, name, type)` est entièrement tenant-driven.

| Département | Modules Scalario activés | Fonctionnalités clés | Persona principal |
| :--- | :--- | :--- | :--- |
| RH & Paie | Contacts (employés), Reporting, Payments | Fiches employés, contrats, congés, calcul de paie (SMIG Burkina), bulletins de salaire, historique disciplinaire, déclarations CNSS/CARFO | Responsable RH |
| Comptabilité & Finance | Transactions, Payments, Reporting | Plan comptable OHADA, grand livre, balance, journaux, rapprochement bancaire, états financiers (bilan, compte de résultat), export pour expert-comptable | Comptable / DAF |
| Secrétariat & Gestion documentaire | Contacts, module Documents (nouveau) | Gestion du courrier entrant/sortant, agenda partagé, archivage numérique des documents (contrats, attestations, factures), alertes échéances | Secrétaire / Assistant de direction |
| Logistique & Achats | Inventory, Catalog, Contacts (fournisseurs) | Bons de commande internes, gestion des fournisseurs, suivi des livraisons, état du parc matériel, gestion des immobilisations | Responsable Achats / Logisticien |

### Architecture : Départements comme sous-unités (Mode Intégré)

- Nouvelle table `departments(id, tenantId, name, type, parentDepartmentId)` pour la hiérarchie
- Chaque utilisateur est assigné à un ou plusieurs départements via `DepartmentUser(userId, departmentId, roleId)`
- Les modules activés sont configurés par département, pas uniquement par tenant
- Les permissions RBAC s'appliquent à l'intersection (tenant, département, rôle)
- La Direction voit les données de tous les départements en lecture. Chaque département ne voit que les siennes en écriture
- L'UI-Driven Engine charge le layout spécifique au département actif de l'utilisateur connecté

### Flux inter-départements

> **Ces flux sont des exemples pour le Template Enterprise PME par défaut.** L'event bus du Kernel est générique — n'importe quel département peut émettre vers n'importe quel autre. Les flux effectifs dépendent des modules activés par le tenant dans chaque département.

Les départements communiquent entre eux via des événements internes au tenant, sans exposer leurs données brutes :

| Émetteur | Destinataire | Événement | Résultat |
|:---|:---|:---|:---|
| Logistique | Comptabilité | Bon de commande validé | Engagement budgétaire créé automatiquement |
| RH | Comptabilité | Bulletins de paie validés | Écriture comptable de paie générée |
| Secrétariat | Tous | Contrat signé uploadé | Notification aux départements concernés |
| Comptabilité | Direction | Clôture mensuelle effectuée | Rapport consolidé disponible sur dashboard DG |
| Retail/Caisse | Comptabilité | Session de caisse clôturée | Écriture comptable ventes générée |

### Tarification Enterprise

| Offre | Prix estimé (Phase 3) | Inclus |
|:---|:---|:---|
| PME Essentiel | 25 000 FCFA / mois | Mode Intégré, jusqu'à 2 départements configurables, 10 utilisateurs, 2 modules métier actifs |
| PME Pro | 50 000 FCFA / mois | Mode Intégré, jusqu'à 4 départements configurables, 25 utilisateurs, tous les modules actifs |
| Groupe / Holding | Sur devis | Mode Fédéré, N tenants liés, dashboard consolidation, Scalario Connect inclus |

> *La tarification Enterprise est significativement plus élevée que le Retail (15 000 FCFA) car la valeur livrée est proportionnellement plus grande : une PME qui évite un comptable externe (économie de 100 000–300 000 FCFA/mois) justifie aisément 50 000 FCFA d'abonnement.*

### Structure DB à anticiper (Phase 1)

| Table | Champ / Action | Utilité |
| :--- | :--- | :--- |
| **departments** *(nouvelle table)* | `id, tenantId, name, type, parentDepartmentId` | Unités organisationnelles tenant-driven — noms libres, définis par le Template par défaut |
| tenants | org_mode (enum: standalone \| integrated \| federated) | Définit si le tenant supporte les départements |
| tenants | parent_tenant_id (uuid nullable) | Pour le Mode Fédéré : lien vers le tenant Groupe |
| users | department_ids (array uuid) | Un utilisateur peut appartenir à plusieurs départements |
| TenantModule | department_id (uuid nullable) | Activation d'un module pour un département spécifique |

### Validation : Le Test Enterprise

- Un DRH configure son département RH, importe 15 employés, génère les bulletins du mois et exporte la déclaration CNSS en moins de 2 heures, sans formation préalable.
- Un comptable clôture le mois, génère le bilan OHADA et l'exporte vers son expert-comptable sans ressaisie manuelle.
- Le DG voit sur un seul écran le CA de la boutique, la masse salariale du RH et les engagements d'achats de la logistique, en temps réel.

---

## Programme Ambassadeurs (Phase 2b)

> **Ambassadeur ≠ Intégrateur — deux canaux distincts et complémentaires :**
>
> **Ambassadeur** = client Scalario satisfait qui recommande Scalario à ses pairs. Canal informel. Commission 20% de l'abonnement mensuel tant que le client référé est actif. Aucune responsabilité de déploiement ou de support.
>
> **Intégrateur** = professionnel (agence, développeur, revendeur sectoriel) qui déploie Scalario pour ses propres clients. Canal formel. Wholesale fee dégressif selon volume. Assure le L1 support de ses clients. Voir FR-INTEGRATOR-01–04.

Le Programme Ambassadeurs est le système de parrainage natif de Scalario. Il transforme les clients satisfaits en force de vente terrain sans coût fixe.

### Modèle économique

| Acteur | Bénéfice | Condition |
|:---|:---|:---|
| Ambassadeur (Parrain) | 20 % de l'abonnement mensuel tant que le client est actif (3 000 FCFA/mois pour 15k) | Paiement via Mobile Money, seuil min. 10 000 FCFA |
| Nouveau client (Filleul) | 50 % de remise sur le premier mois | Via code de parrainage unique |
| Scalario | Acquisition sans coût pub + ambassadeur aligné sur la rétention | Commission versée uniquement si paiement confirmé |

### Profils d'Ambassadeurs cibles

- Clients Scalario existants (boutiquiers satisfaits)
- Comptables indépendants gérant plusieurs commerces
- Vendeurs de matériel (smartphones, tablettes, imprimantes thermiques)
- Agents commerciaux terrain recrutables ultérieurement

### Fonctionnalités techniques

- Génération d'un code de parrainage unique par boutique
- Champ `referred_by` (UUID) sur chaque tenant dès la Phase 1 (structure DB uniquement)
- Calcul automatique des commissions à chaque transaction de paiement réussie
- Mini-tableau de bord Ambassadeur : clients actifs, commissions cumulées, statut de paiement
- Paiement automatisé mensuel via Orange Money / Moov Money API

> *Phase 1 : ajouter `referred_by` sur la table tenants. Phase 2b : activer le calcul, le tableau de bord et le paiement automatisé.*

### Protection de l'image de marque

- Les Ambassadeurs reçoivent un « Kit de Communication » (3 vidéos de démonstration + FAQ)
- Ils ne peuvent pas modifier le discours commercial ou promettre des fonctionnalités inexistantes
- Commissions suspendues en cas de pratique abusive signalée

---

## Écosystème Commercial Channels (Phase 2–3)

Scalario se distribue via des canaux à effet de réseau multiplicateur — chaque canal apporte plusieurs clients simultanément plutôt qu'un seul.

### Cabinets Comptables & Experts-Comptables — Canal stratégique (H2 mid)

Les experts-comptables en UEMOA gèrent 15–30 clients PME chacun et sont obligatoires pour les entreprises formelles (OHADA). Modèle : le cabinet gère sa propre activité dans Scalario (facturation honoraires, suivi missions, gestion équipe) + accède aux données de ses clients via délégation d'accès (FR-MULTISERVICE-01). Parallèle exact du modèle Xero (NZ) — licorne via les experts-comptables comme premier canal.

Prérequis : module Comptabilité OHADA opérationnel. Cible H2 mid : 3–5 cabinets Ouaga pilotes.

### Franchiseurs & Réseaux de Distribution — Adoption imposée (H2–H3)

Un franchiseur ou tête de réseau adopte Scalario → toutes ses unités (franchises, agents, points de vente) l'utilisent par obligation contractuelle ou par standard réseau. Mécanisme : le franchiseur impose, 1 deal B2B = 10–50 clients instantanément. Cibles UEMOA : chaînes de pharmacies, réseaux de stations-service, distributeurs avec agents terrain, franchises restauration rapide, réseaux de collecte agricole.

Features requises : dashboard tête de réseau (vue consolidée toutes unités), benchmarking inter-unités, standards de config imposés par le franchiseur, reporting consolidé groupe (couvert par FR-MULTISTORE-01 + Scalario Connect).

### Groupements, Coopératives & Associations de Commerçants — Adoption collective (H2–H3)

En UEMOA les commerçants s'organisent en groupements d'achat, coopératives, associations sectorielles. Scalario signe avec le groupement → tous les membres adoptent collectivement. 1 négociation = 20–100 clients. Bonus : les groupements ont souvent accès à des financements institutionnels (BOAD, AFD, USAID, Proparco) pour digitaliser leurs membres.

Cibles : coopératives agricoles, associations de femmes entrepreneures (tarif groupe + microfinance), groupements d'achat marchands (stock mutualisé + commandes groupées fournisseurs).

### Professionnels de Service (Avocats, Consultants, Agences) — Multi-Client (H3)

Gérables via FR-MULTISERVICE-01 dès que les modules Core couvrent leur besoin métier. Templates sectoriels activent chaque profession sans développement dédié. Le professionnel est lui-même client Scalario pour sa propre gestion + dashboard multi-clients pour ses dossiers.

---

## Modèle Intégrateur Mini-Opérateur SaaS (Phase 2b–3)

Les intégrateurs évoluent de revendeurs ponctuels vers un modèle de **mini-opérateur SaaS** : ils créent des bundles sectoriels configurés via AI, vendent l'abonnement directement à leurs clients à leur propre prix, et gèrent la relation client de proximité. Scalario prélève un fee wholesale; l'intégrateur conserve sa marge.

### Canaux de Distribution

| Canal | Description | Phase |
|:---|:---|:---|
| **Direct** — Scalario → Client | Le client souscrit via la page d'onboarding Scalario (FR103). Scalario gère la relation, le support de niveau 2 et la facturation. | Phase 1+ |
| **Indirect** — Scalario → Intégrateur → Client | L'intégrateur souscrit en wholesale, configure les bundles pour ses clients, assure le support de proximité. Scalario facture l'intégrateur au fee wholesale. | Phase 2b |

Les deux canaux coexistent. Un client acquis en direct reste en direct; un client acquis via intégrateur reste attaché à cet intégrateur pour le calcul des commissions.

### Bundles Sectoriels

L'intégrateur compose des offres packagées via le Template Builder (FR-TEMPLATE-01), aidé par l'AI (FR-AI-05) pour sélectionner les modules selon le budget et le secteur du marchand. Exemples :

- **"Petit Commerce Starter"** — Core POS + catalogue + stock de base
- **"Boucher Bundle"** — Core POS + gestion poids + variantes par découpe
- **"Cabinet Médical Starter"** — Core + template Dossier Patient + agenda

Chaque bundle est un template sectoriel configuré, pas un développement dédié.

### Règles de Protection de la Valeur (FR-INTEGRATOR-01 à FR-INTEGRATOR-02)

- **Prix plancher :** L'intégrateur ne peut pas vendre en dessous du seuil minimum fixé par Scalario par offre. Protège la valeur perçue du produit sur le marché.
- **Prix plafond :** L'intégrateur ne peut pas vendre au-dessus du prix maximum fixé par Scalario. Protège les clients finaux contre les marges abusives et préserve l'image de marque.

Les planchers et plafonds sont configurables par Scalario sans déploiement (via PlanDefinition, FR100).

### Fee Dégressif par Volume (FR-INTEGRATOR-03)

| Volume clients actifs de l'intégrateur | Fee wholesale |
|:---|:---|
| 1–5 clients | Fee standard (taux de base) |
| 6–20 clients | -10 % sur le fee standard |
| 21–50 clients | -20 % sur le fee standard |
| 50+ clients | Accord négocié (contrat cadre) |

Le volume est recalculé automatiquement à chaque fin de cycle de facturation. Le palier s'ajuste à la hausse immédiatement, à la baisse avec un délai d'1 cycle (protection contre les churns temporaires).

### Commission Récurrente (FR-INTEGRATOR-04)

L'intégrateur perçoit sa marge tant que son client est actif : marge = prix de revente – fee wholesale. Aucune commission à l'acquisition uniquement — l'intégrateur est naturellement incité à assurer la rétention et la satisfaction client. Commission suspendue si le client passe au canal direct ou si l'intégrateur est suspendu pour pratique abusive.

---

## Flywheel Architecture

Chaque nouveau module Core déverrouille plusieurs secteurs servables via Templates Sectoriels sans développement Flutter dédié. La priorisation des modules Core doit être guidée par le nombre de secteurs qu'ils déverrouillent.

### Modules Core → Secteurs Déverrouillés

| Module Core | Secteurs déverrouillés via Template | Priorité |
|:---|:---|:---|
| Gestion Documentaire | Avocats, notaires, RH avancé, hôpitaux, administration publique | Haute |
| Projets / Chantiers | BTP, agences créatives, consultants, ONG, gestion de missions | Haute |
| Dossier Patient | Cliniques, pharmacies, laboratoires, médecins indépendants | Haute |
| Production / Fabrication | Ateliers, manufactures, agroalimentaire, brasseries | Moyenne |
| Gestion Scolaire | Écoles primaires, lycées, centres de formation, universités privées | Moyenne |
| Gestion Hôtelière | Hôtels, auberges, campings, résidences | Moyenne |
| Gestion Agricole | Coopératives agricoles, exploitations, collecteurs | Moyenne |

### Principe Flywheel

```text
Module Core stable
        ↓
Template Sectoriel AI-driven configuré en heures
        ↓
Nouveau secteur servi sans dev Flutter
        ↓
Revenu + données + réseau d'intégrateurs formés
        ↓
Financement prochain Module Core
        ↓
(Boucle)
```

> **Note :** Les Templates Sectoriels sont de la configuration pure (rôles, workflows, permissions, vocabulaire, données par défaut). Aucune génération d'écran Flutter. L'UI-Driven Engine + BusinessTypeDefinition + roleLabels couvrent la totalité de la customisation UX nécessaire.

---

## Modèle de Responsabilité

### Qui construit quoi

| Acteur | Responsabilité | Outillage |
| :--- | :--- | :--- |
| **Scalario (équipe)** | Core Platform (Kernel, Shared Modules, moteur sync, UI-Driven Engine). Modules Fonctionnels (FR1–FR111+). Templates Officiels pour les secteurs communs (Retail, Distribution, PME). | Code Flutter + NestJS. Infrastructure Supabase. |
| **Intégrateurs** | Créent des Templates Sectoriels pour leurs clients via Template Builder AI-driven (Phase 2c). Configuration en langage naturel — aucun code requis. Bundlent et revendent des offres Scalario à leur propre marque. | Template Builder (FR-TEMPLATE-01/02). Canal intégrateur wholesale (FR-INTEGRATOR-01–04). |
| **Intégrateurs avancés (Phase 4+)** | Développent des Modules Custom via SDK tiers pour des besoins non couverts par les modules officiels. Contribuent au marketplace de modules. | SDK Scalario (Phase 4). API /api/v1/ ouverte (NFR35). |
| **Clients finaux** | Personnalisent leur espace via AI Natural Language (FR-AI-04). Configurent produits, rôles, alertes, workflows en conversation. Activent les modules adaptés à leur métier. | AI Config (FR-AI-04/05). UI admin. Template Sectoriel appliqué par leur intégrateur ou en self-service. |

> **Principe clé :** Template Builder = outil de configuration AI-driven, **pas de génération d'écrans Flutter**. Les écrans sont pré-construits dans le Kernel. Un intégrateur configure le *contenu et le comportement* — jamais la structure de l'application.

---

## Exigences Domain-Spécifiques

### Conformité Fiscale & Réglementaire

Scalario est conçu pour être déployé dans n'importe quelle juridiction mondiale. La conformité fiscale, la comptabilité et les règles sociales ne sont jamais codées en dur — elles sont pilotées par un moteur de plugins par pays/juridiction (NFR32). Chaque tenant est associé à une juridiction dès sa création, et les règles s'appliquent automatiquement. UEMOA/CEMAC est le beachhead de validation — les plugins Burkina Faso, Côte d'Ivoire, Sénégal sont les premiers livrés. Les plugins Kenya (KES/NSSF), Nigeria (NGN/PENCOM), Indonésie (IDR/BPJS) suivent sans modification du Kernel.

#### Architecture fiscale multi-pays

- Moteur fiscal configurable par juridiction (plugins pays) : taux TVA, règles d'arrondi, formats de reçus, obligations de transmission
- MVP : Burkina Faso (XOF, FEC/DGI, TVA 18 %/10 %). Architecture prête pour Côte d'Ivoire, Sénégal, Mali, Cameroun, Togo, Bénin sans modification du Kernel
- Chaque plugin pays déclare : devise, arrondi, taux TVA, format reçu, obligation de transmission fiscale, identifiants légaux requis
- Un tenant peut être migré de juridiction (exemple : agence BF → agence CI) sans perte de données historiques

#### Facturation électronique certifiée (FEC) — Burkina Faso (MVP, obligatoire 2026)

- Logiciel de caisse certifié avec transmission des données de facturation vers le système DGI
- Reçus électroniques avec numérotation séquentielle, inaltérable et garantie d'unicité
- Mode offline : génération locale avec plages de numéros pré-allouées, transmission à la synchronisation
- TVA multi-taux : 18 % (normal), 10 % (réduit), exonérations. Configurable par produit/catégorie

#### Paie & Sécurité Sociale — Architecture multi-pays

- Les règles de paie (SMIG, cotisations sociales, retenues) sont définies dans le plugin pays, pas dans le code métier
- MVP Burkina Faso : SMIG en vigueur, cotisations CNSS (employé + employeur), CARFO pour fonctionnaires, retenue ITS progressive
- Extension future : IPRES Sénégal, CNPS Côte d'Ivoire, CNPS Cameroun — ajout d'un plugin sans modifier le moteur de paie
- Les taux et barèmes sont mis à jour par l'admin sans déploiement (configuration JSON par pays)
- La déclaration sociale génère un fichier export (CSV ou PDF) au format attendu par l'organisme local. Aucune API directe n'est prévue — la déclaration est envoyée manuellement ou via le portail de l'organisme.

> *Règle d'architecture : toute contrainte réglementaire spécifique à un pays (taux, format, obligation) est un paramètre de configuration du plugin pays, jamais une ligne de code dans le Kernel ou un Shared Module.*

### Moteur de Devise & Prix

| Contrainte | Implémentation |
|:---|:---|
| Multi-devises | Chaque tenant configure sa devise. MVP : XOF. Architecture prête pour XAF, EUR, USD |
| Règles d'arrondi par devise | XOF : arrondi à 5 FCFA. EUR : arrondi à 0.01. Configurable par devise |
| Autorité prix | Seul le propriétaire peut modifier les prix — contrainte anti-fraude |
| Prix au poids | Prix/kg avec calcul au gramme, arrondi final selon devise |

### Résilience Infrastructure

- WAL (Write-Ahead Logging) sur la base locale : zéro corruption en cas d'arrêt brutal
- Transaction en cours sauvegardée incrémentalement — redémarrage reprend ou abandonne proprement
- Compression des payloads de sync, delta-only, retry avec exponential backoff
- Spécification minimum supportée : tablette 1–2 Go RAM, stockage limité

### Confiance & Anti-Fraude

- Double validation à chaque transfert de stock : émetteur déclare la sortie, récepteur confirme la réception, écart automatiquement attribué
- Séparation stricte des rôles : qui vend ne reçoit pas, qui reçoit ne vend pas
- Arrêt de caisse quotidien obligatoire avec confrontation théorique/réel
- Audit trail immuable : acteur, action, timestamp, données avant/après

---

## User Journeys

### Journey 1 : Fatou, Commerciale — Journée complète

Fatou, 24 ans, commerciale fruits & légumes, tablette Android. Apprend le système en 45 minutes. Travaille une journée complète avec ventes au poids, pertes, transferts et coupure wifi totale — sans s'en apercevoir.

**Fonctionnalités révélées :** moteur transactions offline-first, ventes au poids + arrondi FCFA, gestion de session de caisse, transferts de stock avec variance, déclaration de pertes, sync automatique en arrière-plan.

### Journey 2 : Blandine, Propriétaire à distance

Blandine, 41 ans, gère son épicerie fine depuis l'étranger via smartphone. Reçoit résumé WhatsApp chaque soir. Détecte un pattern de pertes en 30 jours grâce à la traçabilité chaînon par chaînon.

**Fonctionnalités révélées :** gestion commandes fournisseurs à distance, suivi des réceptions avec variance, moteur résumé WhatsApp, dashboard mobile temps réel, traçabilité des transferts de stock.

### Journey 3 : Moussa, Gestionnaire de magasin

Moussa, 35 ans, pivot opérationnel. Gère les réceptions fournisseurs, les transferts vers les rayons, les inventaires partiels et la consolidation des rapports journaliers.

**Fonctionnalités révélées :** réception livraison avec appariement commande, création de transferts stock avec poids, inventaire partiel avec variance, rapport consolidé journalier, RBAC strict.

### Journey 4 : Carlos, Admin système — Onboarding Pharmacie

Carlos crée un nouveau tenant Pharmacie, active les modules partagés, applique le Template Sectoriel Pharmacie qui configure les extensions spécifiques via l'UI-Driven Engine. Le pharmacien est opérationnel en 2 heures. Zéro modification du kernel.

> *Ce journey illustre le flow H1 (provisioning manuel par admin). Phase 2c : ce flow devient self-service via AI Config Wizard (FR-AI-05) — le client sélectionne le Template Sectoriel Pharmacie, décrit son activité, le tenant est configuré automatiquement sans Carlos.*

**Fonctionnalités révélées :** provisioning multi-tenant, configuration RBAC par secteur, système d'activation de module, import CSV catalogue, extensions CatalogItem secteur-spécifiques via Template, isolation du kernel.

### Journey 5 : Fatou — Crise offline (journée sans internet)

L'antenne est en panne depuis 5h. Fatou ne le remarque pas. 127 transactions en local. Sync complète en 22 secondes à la reconnexion. Blandine voit le rapport du jour sans savoir qu'il y a eu 12h de coupure.

**Fonctionnalités révélées :** opération offline totale (CRUD local), file outbox + push automatique, profils clients locaux, suivi crédits offline, indicateur de connectivité discret, résolution de conflits.

### Journey 6 : Awa, DRH — Clôture de paie du mois

**Persona :** Awa, 38 ans, Directrice des Ressources Humaines d'une PME de distribution (22 employés). Utilise Scalario Enterprise en Mode Intégré. Smartphone et PC de bureau.

**Scène d'ouverture :** le 28 du mois, Awa ouvre le module RH depuis son PC. Elle voit la liste des 22 employés avec leur statut de pointage du mois. 2 employés ont des jours d'absence non justifiée signalés en rouge.

**Déroulement :** elle règle les absences (1 maladie justifiée, 1 absence non payée), lance le calcul de paie. Le système applique le SMIG en vigueur au Burkina, calcule les cotisations CNSS/CARFO, les retenues, et génère les 22 bulletins en 40 secondes. Awa les vérifie, valide. Le système émet automatiquement un événement vers le module Comptabilité : une écriture de charge salariale est créée sans saisie manuelle. Elle génère le fichier de déclaration CNSS (CSV) en un clic — prêt pour dépôt manuel ou via le portail CNSS. Elle reçoit une alerte : le contrat CDD de Mamadou expire dans 12 jours.

**Fonctionnalités révélées :** gestion employés avec pointage, calcul paie SMIG/cotisations sociales automatisé, génération bulletins, export fichier déclaration sociale (format local), événement inter-départements RH → Comptabilité, alertes échéance contrat.

### Journey 7 : Ibrahim, Comptable — Clôture mensuelle OHADA

**Persona :** Ibrahim, 32 ans, comptable de la même PME. Utilise le module Comptabilité de Scalario Enterprise. Il gère le journal, le grand livre et envoie les états à l'expert-comptable externe chaque trimestre.

**Scène d'ouverture :** le 1er du mois suivant, Ibrahim ouvre le tableau de bord Comptabilité. Il voit les écritures du mois écoulé déjà pré-remplies : les ventes Retail (issues de la clôture des sessions de caisse), les charges salariales (issues de la validation paie Awa), et les achats logistique (issus des bons de commande validés).

**Déroulement :** Ibrahim saisit manuellement les écritures restantes (loyer, électricité, téléphone). Il effectue le rapprochement bancaire en important le relevé PDF de la banque. Le système suggère les appariements automatiquement. Ibrahim valide, corrige 2 écarts, clôture le mois. Il génère le bilan et le compte de résultat au format OHADA. Il les exporte en PDF et Excel pour l'expert-comptable — sans ressaisie, sans recopie de chiffres.

**Fonctionnalités révélées :** écritures pré-remplies depuis événements inter-départements, rapprochement bancaire semi-automatique, plan comptable OHADA natif, clôture mensuelle, génération états financiers (bilan + compte de résultat), export PDF/Excel.

### Journey 8 : Serge, DG — Vision consolidée en 2 minutes

**Persona :** Serge, 47 ans, Directeur Général de la PME. Il ne touche pas aux détails opérationnels. Il veut la vision d'ensemble, quand il veut, où il veut, sur son smartphone.

**Scène :** Serge est en réunion externe. Entre deux rendez-vous, il ouvre Scalario sur son téléphone. Son dashboard DG affiche en temps réel : CA journalier de la boutique (340 000 FCFA, +12 % vs hier), masse salariale du mois (écritures RH validées : 2 850 000 FCFA), engagements achats en cours (4 bons de commande ouverts, valeur totale 780 000 FCFA), trésorerie estimée (solde bancaire - engagements = 1 240 000 FCFA). Une alerte rouge : le stock d'oignons tombe à 2 jours de couverture. Il forward l'alerte à Moussa via la notification intégrée.

**Fonctionnalités révélées :** dashboard DG consolidé multi-départements, indicateurs temps réel (CA, masse salariale, engagements, trésorerie estimée), alertes critiques cross-départements, notification vers employé depuis le dashboard.

### Journey 9 : Aminata, Propriétaire multi-sites — Supervision centralisée (Phase 2b)

**Persona :** Aminata, 34 ans, propriétaire de 3 boutiques textile à Ouagadougou (centre-ville, Gounghin, Pissy). Elle dirige depuis la boutique principale et délègue les opérations locales à chaque caissière.

**Scène :** Aminata ouvre son dashboard multi-sites depuis son téléphone le lundi matin. Elle voit en un seul écran le CA weekend de ses 3 points de vente : Centre-Ville 485 000 FCFA, Gounghin 312 000 FCFA, Pissy 198 000 FCFA. Le stock de pagnes wax est en alerte à Gounghin (3 unités) mais abondant à Centre-Ville (47 unités). Elle initie un transfert inter-sites depuis l'app. La caissière de Gounghin reçoit la confirmation du transfert entrant.

**Fonctionnalités révélées :** dashboard agrégé multi-POS (FR-MULTISTORE-01), transfert inter-sites, RBAC par point de vente, consolidation reporting, alertes stock cross-sites.

### Journey 10 : Moussa, Intégrateur — Déploiement d'une chaîne de boulangeries (Phase 2c)

**Persona :** Moussa, 29 ans, développeur indépendant basé à Abidjan. Il a signé un contrat avec une chaîne de 5 boulangeries pour déployer Scalario.

**Scène :** Moussa accède à son espace intégrateur. Il ouvre le Template Builder et décrit : "Boulangerie artisanale — vente au comptoir de pains, viennoiseries, gâteaux. Stock farine/sucre/levure. Caissière unique. Rapport journalier propriétaire." L'AI génère un draft Template : rôles Propriétaire/Caissière/Production, catégories Pains/Viennoiseries/Gâteaux pré-créées, modules POS + Inventory actifs. Moussa ajuste le vocabulaire ("Fournée" pour les transferts de production), valide et publie le template dans son espace. Il provisionne les 5 tenants de la chaîne en wholesale et applique le template à chacun en 3 clics. Les 5 boutiques sont opérationnelles. Aucune ligne de code Flutter écrite.

**Fonctionnalités révélées :** espace intégrateur wholesale (FR-INTEGRATOR-01/02), Template Builder (FR-TEMPLATE-01/02), AI génération de config (FR-AI-01/02), provisioning multi-tenants, marge intégrateur, vocabulaire sectoriel configurable.

### Journey 11 : Ibrahim, Expert-comptable — Clôture mensuelle multi-clients (Phase 3)

**Persona :** Ibrahim, 42 ans, expert-comptable indépendant à Dakar. Il gère la comptabilité de 12 clients PME, tous sur Scalario Enterprise.

**Scène :** Ibrahim ouvre son dashboard professionnel depuis son PC. Il voit ses 12 clients avec leur statut de clôture : 9 validées, 2 en attente, 1 avec anomalie (écart de 47 000 FCFA sur le compte 411). Il clique sur le client concerné — son accès délégué lui ouvre la comptabilité du tenant en lecture+écriture sur le module Finance uniquement. Il identifie l'écart : une facture client non lettrée. Il crée l'écriture de lettrage depuis le grand livre. Le propriétaire du tenant reçoit une notification "Votre comptable a finalisé la clôture de mars." Ibrahim revient à son dashboard et passe au client suivant.

**Fonctionnalités révélées :** accès délégué multi-tenants (FR-MULTISERVICE-01), isolation par module (Finance uniquement), dashboard professionnel agrégé, audit trail délégation, notification cross-acteurs.

### Journey 12 : Fatou, Propriétaire — Configuration métier via chat AI (Phase 2c)

**Persona :** Fatou, propriétaire de l'épicerie (Journey 1). 3 mois après le démarrage, elle veut ajouter une règle de prix pour les achats en gros.

**Scène :** Fatou ouvre la section AI depuis son écran principal et tape : "Je veux que les clients qui achètent 5 fois le même produit aient une remise de 8%." L'AI répond : "Je vais créer une règle de promotion : à partir de 5 unités du même article dans la même transaction, remise automatique 8%. C'est bien ce que vous voulez ?" Fatou confirme. L'AI invoque l'action `createPromotion` (FR-AI-02) avec les paramètres générés : type=QUANTITY_DISCOUNT, threshold=5, discount=8%, scope=SAME_ITEM. La règle est active immédiatement — la vente suivante applique la remise automatiquement. Aucun menu de configuration visité, aucune formation requise.

**Fonctionnalités révélées :** section AI dédiée non-injectée (FR-AI-01), function calling vers module Promotions (FR-AI-02), confirmation avant action destructive, paramètres auto-générés, activation instantanée.

---

## Exigences SaaS B2B

### Multi-Tenancy

| Aspect | Implémentation |
|:---|:---|
| Modèle d'isolation | Isolation logique via tenant_id sur toutes les entités + Supabase RLS en filet de sécurité |
| Provisioning tenant | Manuel par admin (MVP). Self-service post-MVP |
| Configuration tenant | Devise, timezone, juridiction fiscale, modules actifs, secteur actif, type métier (UI-Driven) |
| Cycle de vie tenant | Créer, activer, suspendre, archiver. Pas de suppression (audit trail) |

### Exemple de Configuration RBAC — Template Retail (valeurs par défaut)

> **Ces rôles et permissions sont des valeurs par défaut préconfigurées pour le Template Retail.** Ils sont modifiables par chaque tenant via AI Config (FR-AI-02/FR-RBAC-01). Le système ne hardcode aucun rôle — tous les noms de rôles, permissions et règles d'accès sont des données configurables en base. "Propriétaire", "Gestionnaire" et "Commercial" sont les labels du Template Retail par défaut. Un tenant peut les renommer ("Patron", "Responsable de rayon", "Vendeur"), modifier leurs permissions, ou créer de nouveaux rôles (ex: "Superviseur", "Auditeur") sans déploiement.

| Permission | Propriétaire | Gestionnaire | Commercial |
| :--- | :--- | :--- | :--- |
| Dashboard & rapports | Complet | Son emplacement | Sa session |
| Modifier les prix | Oui | Non | Non |
| Ajouter/modifier produits | Oui | Non | Non |
| Créer commandes fournisseurs | Oui | Non | Non |
| Réceptionner livraisons | Non | Oui | Non |
| Créer transferts stock | Non | Oui | Non |
| Confirmer réception transfert | Non | Non | Oui |
| Ouvrir/fermer caisse | Non | Non | Oui |
| Traiter ventes | Non | Non | Oui |
| Déclarer pertes | Non | Oui | Oui |
| Gérer utilisateurs et rôles | Oui | Non | Non |

> **Note architecture :** L'implémentation actuelle (Phase 1) accepte ces rôles comme point de départ préconfigurés dans le Template Retail. La refactorisation vers RBAC dynamique complet (FR-RBAC-01) est obligatoire avant Phase 2c (AI Config Wizard) — sans quoi le wizard ne peut pas créer de rôles custom pour les clients. Voir dette technique documentée dans `_bmad-output/implementation-artifacts/1-2-role-based-access-control.md`.

### Exemple de Configuration RBAC — Template Enterprise PME (valeurs par défaut)

> **Ces rôles sont des valeurs par défaut préconfigurées pour le Template Enterprise PME (mode multi-départements).** Un tenant Enterprise peut renommer "DRH" en "Responsable Humain", "Comptable" en "DAF", ajouter un rôle "Responsable Juridique" avec accès au module Secrétariat, ou supprimer un rôle non utilisé — sans déploiement.

En mode Enterprise, les permissions s'appliquent à l'intersection (tenant, département, rôle). Le DG voit tous les départements en lecture. Chaque responsable de département écrit uniquement dans son périmètre.

| Permission | DG | DRH | Comptable | Secrétaire | Resp. Achats |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Dashboard consolidé multi-dép. | Lecture | Non | Non | Non | Non |
| Fiches employés & contrats | Lecture | Écriture | Lecture | Lecture | Non |
| Calcul paie & bulletins | Lecture | Écriture | Lecture | Non | Non |
| Export CNSS / CARFO | Non | Oui | Non | Non | Non |
| Saisie écritures comptables | Non | Non | Écriture | Non | Non |
| Rapprochement bancaire | Non | Non | Écriture | Non | Non |
| Clôture mensuelle & bilan OHADA | Lecture | Non | Écriture | Non | Non |
| Courrier entrant / sortant | Lecture | Non | Non | Écriture | Non |
| Agenda partagé & échéances | Lecture | Lecture | Lecture | Écriture | Lecture |
| Bons de commande internes | Lecture | Non | Lecture | Non | Écriture |
| Réception livraisons internes | Non | Non | Non | Non | Écriture |
| Parc matériel & immobilisations | Lecture | Non | Lecture | Non | Écriture |
| Configurer départements & rôles | Oui | Non | Non | Non | Non |

> *Règle d'or Enterprise : un utilisateur peut appartenir à plusieurs départements (department_ids). Ses permissions sont l'union de ses rôles dans chaque département. Le DG est le seul rôle avec lecture transversale sur tous les départements.*
>
> **Note architecture :** Même règle que pour le Template Retail — ces rôles sont des données configurables, pas des enums hardcodés. La refactorisation RBAC dynamique (FR-RBAC-01) s'applique à tous les templates, Retail et Enterprise.

### Registre & Activation des Modules

| Aspect | Implémentation |
|:---|:---|
| Registre modules | Kernel maintient le registre des modules disponibles (shared + sectoriels) |
| Activation par tenant | TenantModule(tenantId, moduleId, activatedAt, status) |
| Dépendances | Les modules sectoriels déclarent leurs dépendances sur les modules partagés |
| UI-Driven config | TenantModule inclut un JSON de configuration UI spécifique au métier |

### Architecture d'Intégration

| Priorité | Intégration | Objet | Phase |
|:---|:---|:---|:---|
| 1 | API Fiscale DGI | Conformité FEC — obligatoire | MVP |
| 2 | WhatsApp Business API | Résumé soir propriétaires + alertes critiques | Phase 2a |
| 3 | Orange Money / Moov Money API | Paiement Ambassadeurs automatisé + encaissement clients | Phase 2b |
| 4 | Export OHADA Retail | Format export fiscal standard pour comptable externe (ventes Retail uniquement) | Phase 2b |
| 5 | Export Déclaration Sociale (RH Enterprise) | Génération fichier déclaration cotisations (CSV/PDF) au format attendu par l'organisme local (CNSS BF, IPRES SN, CNPS CI…). Dépôt manuel ou via portail organisme. | Phase 3 Enterprise |
| 6 | Comptabilité OHADA intégrée | Plan comptable natif, grand livre, bilan — distinct de l'export OHADA Retail | Phase 3 Enterprise |
| 7 | Scalario Connect B2B API | Interconnexion inter-tenants (bons de commande, factures) | Phase 3 |
| 8 | Open API | Intégrations tierces partenaires | Vision |

---

## Onboarding & Support Client

### Parcours Commercial H1 — Vente Directe Carlos (Pré-Intégrateur)

Modèle validé sur Blandine (premier client Pro, mars-avril 2026) :

1. Présentation à distance (~30 min) — appel vidéo, démonstration des 5 flows critiques depuis le dashboard propriétaire mobile
2. Signature accord commercial à distance (WhatsApp ou email)
3. Paiement setup fee via Orange Money — par le gestionnaire on-site ou par Blandine depuis l'étranger
4. Go-live on-site : Carlos chez les employés — configuration tenant (catalogue, comptes, rôles), formation par rôle (~30 min chacun)
5. Blandine suit le go-live à distance via l'app en temps réel

> **Note :** Blandine gère sa boutique depuis l'étranger — c'est l'archétype exact du use case "contrôle à distance" que Scalario résout. La démo vidéo montre en live ce qu'elle peut faire depuis là où elle est. Ce modèle (propriétaire absent, go-live via gestionnaire on-site) devient le template du Playbook Commercial intégrateur (Phase 2).

---

### Processus d'Onboarding — Évolution par Horizon

> **H1 (actuel) :** Manuel — Carlos ou un intégrateur crée et configure le tenant. Valide pour l'acquisition initiale terrain. **Phase 2a :** AI Excel/CSV Import (FR-AI-03) réduit l'import catalogue de 1–2h à 10 min. **Phase 2c :** AI Config Wizard (FR-AI-05) rend le flow entièrement self-service — l'étape "Carlos/intégrateur crée le tenant" disparaît. Durée Retail : < 30 min autonome.

#### H1 — Processus actuel (Manuel)

| Offre | Étape 1 — Création tenant | Étape 2 — Import données | Étape 3 — Formation | Durée totale |
| :--- | :--- | :--- | :--- | :--- |
| Starter / Business | Carlos ou intégrateur crée le tenant (15 min) | Import CSV catalogue ou saisie manuelle (1–2h) | Formation caissier via vidéo (45 min) — première vente < 15 min | 1 journée |
| Pro | Parcours Commercial H1 (voir ci-dessus) — présentation + signature + config on-site | Catalogue produits on-site ou pré-chargé si liste envoyée en avance | Formation par rôle ~30 min (propriétaire + gestionnaire + commerciaux) | 1 visite (demi-journée) |
| Enterprise | Audit préalable (1h) + Carlos ou intégrateur configure tenant | Configuration départements + import CSV employés et plan comptable | Formation par département (2–4h chacun) + test clôture à blanc | 3–5 jours |

> **H1 :** Processus manuel Carlos/intégrateur (ci-dessus, valide). **Phase 2a :** AI Excel Import (FR-AI-03) → catalogue 10 min. **Phase 2c :** self-service complet — l'intégrateur ou le client crée le tenant via AI Config Wizard sans Carlos (FR-AI-05).

#### Phase 2a — AI Import (Mois 3–6)

> AI Excel/CSV Import (FR-AI-03) : upload fichier catalogue existant → AI configure automatiquement produits, variantes, unités, prix. **Étape 2 Retail : 1–2h → 10 min.** Étape 2 Enterprise : demi-journée → < 1h pour l'import employés et plan comptable.

#### Phase 2c — Self-service Complet (FR-AI-05)

> Config Wizard universel : le client souscrit via FR103 (Mobile Money → provisioning instant), sélectionne son Template Sectoriel, décrit son activité en langage naturel. Le Wizard configure automatiquement rôles, modules, vocabulaire, structure organisationnelle. **Étape 1 ("Carlos/intégrateur crée le tenant") disparaît du flow.** Durée Retail : < 30 min autonome. Durée Enterprise : < 2h guidée par le Wizard.
>
> **Noms d'offres H1 :** Starter (15K/mois) / Business (30K/mois) / Pro (55K/mois, client fondateur Blandine à 40K) / Enterprise (sur devis). À partir de H2 (pricing modulaire par composant actif), la grille tarifaire évolue — voir Modèle de Tarification et Évolution du Modèle de Revenu (3 Horizons).

### SLAs de Support par Offre

> **Niveaux de support :** Canal Direct (Scalario → Client) : Scalario assure L1 et L2. Canal Indirect (via Intégrateur) : l'intégrateur assure le **L1** (premier contact, résolution courante), Scalario assure le **L2** (bugs produit, incidents infra). Les SLAs ci-dessous s'appliquent au canal direct. Les SLAs canal indirect sont contractualisés entre Scalario et chaque intégrateur (voir FR-INTEGRATOR-02).

| Offre | Canal | Première réponse | Résolution estimée | Horaires |
| :--- | :--- | :--- | :--- | :--- |
| Starter / Business | WhatsApp | < 4h ouvrables | < 24h pour bugs bloquants | Lun–Sam 8h–18h |
| Pro | WhatsApp prioritaire | < 2h ouvrables | < 12h pour bugs bloquants | Lun–Sam 8h–18h |
| Enterprise Essentiel | WhatsApp + appel téléphonique | < 2h ouvrables | < 8h pour bugs bloquants | Lun–Sam 8h–19h |
| Enterprise Pro | WhatsApp + appel + session TeamViewer | < 1h ouvrables | < 4h pour bugs bloquants | Lun–Sam 7h–20h |
| Groupe / Holding | Account manager dédié | < 30 min | SLA contractuel sur devis | Sur devis |

### Kit Ambassadeur

- Vidéo 1 (2 min) : démonstration première vente Retail
- Vidéo 2 (3 min) : démonstration rapport soir + WhatsApp propriétaire
- Vidéo 3 (2 min) : démonstration onboarding Scalario Enterprise (DRH + Comptable)
- FAQ PDF : 10 objections courantes + réponses standardisées
- Fiche tarifaire Ambassadeur (prix publics uniquement, sans marges)

> *Les Ambassadeurs n'ont pas accès au backoffice admin. Ils reçoivent uniquement leur tableau de bord de commissions et le kit de communication.*

---

## Super Admin Scalario (Backoffice Opérationnel)

> Interface interne réservée à l'équipe Scalario. Distincte du backoffice tenant (admin boutique) et du dashboard intégrateur.

### Périmètre par Horizon

#### H1 (actuel — manuel)

- Création et configuration manuelle d'un tenant (business_type, plan, modules actifs)
- Activation / suspension d'un tenant
- Réinitialisation de mot de passe utilisateur
- Consultation des logs de sync et erreurs critiques

#### Phase 2b — Canal Intégrateur & Billing

- Onboarding intégrateur : création compte, affectation tier fee, limites prix plancher/plafond
- Dashboard billing : abonnements actifs, paiements reçus/en attente, suspensions automatiques
- Calcul et déclenchement des commissions Ambassadeurs (Mobile Money)
- Suivi des commissions intégrateurs (marge, volume, tier actif)
- Feature flags par tenant : activer/désactiver un module sans déploiement

#### Phase 3 — Marketplace & Monitoring avancé

- Review et approbation des templates sectoriels soumis par les intégrateurs
- Dashboard santé plateforme : uptime, volume sync, erreurs critiques, anomalies
- Gestion des plugins pays (activation conformité fiscale/sociale par tenant)

### FR Super Admin (FR-SUPERADMIN-01–06)

- **FR-SUPERADMIN-01 :** Création de tenant via formulaire Super Admin — sélection du plan, des modules actifs, du template sectoriel initial, de l'intégrateur attaché (optionnel). Provisioning immédiat. *(H1)*

- **FR-SUPERADMIN-02 :** Suspension / réactivation d'un tenant avec motif tracé. Suspension entraîne l'expiration des sessions actives côté client dans < 5s. *(H1)*

- **FR-SUPERADMIN-03 :** Dashboard billing — vue des abonnements actifs, paiements confirmés vs en attente, alertes retard de paiement. Suspension automatique après X jours de retard configurable. *(Phase 2b)*

- **FR-SUPERADMIN-04 :** Onboarding intégrateur — création compte intégrateur, configuration tier fee initial, activation des droits wholesale. Modification du tier fee rétroactive au prochain cycle. *(Phase 2b)*

- **FR-SUPERADMIN-05 :** Feature flags par tenant — activer ou désactiver un module ou une fonctionnalité expérimentale sur un tenant précis sans déploiement applicatif. Stocké en base (tenant_features). *(Phase 2b)*

- **FR-SUPERADMIN-06 :** Review marketplace templates — file d'attente des templates soumis par intégrateurs, interface de validation (approve / reject + commentaire), versioning des templates approuvés. *(Phase 3)*

---

## Infrastructure & Déploiement

> Décisions d'infrastructure par horizon. Le détail opérationnel (pipeline CI/CD, commandes, rollback) est dans les implementation artifacts.

### Stack d'hébergement

| Composant | H1 | H2 | H3+ |
| :--- | :--- | :--- | :--- |
| Backend NestJS | Railway Starter (~20$/mo) | Railway scale | Hetzner VPS (optimisation coût) |
| Base de données | Supabase Cloud Pro (25$/mo) | idem | Évaluer self-hosted Supabase |
| Stockage fichiers | Supabase Storage | idem | S3-compatible si volumétrie |
| CDN / Assets | Supabase CDN inclus | idem | CloudFront H3 |

**Rationale Railway :** DX maximal pour fondateur solo-augmenté — deploy sur git push, env vars par environnement, rollback en 1 clic, pas d'ops serveur.

**Rationale Supabase Pro obligatoire dès H1 :** backups daily automatiques inclus (rétention 7j H1 → 30j H2), point-in-time recovery, RLS natif — requis dès le premier client payant.

### Distribution Flutter

| Canal | Horizon | Usage |
| :--- | :--- | :--- |
| APK direct (WhatsApp / email) | H1 | Testers + premiers clients (Blandine). Pas de délai Play Store review. Sideloading courant en UEMOA. |
| Google Play Store | H2 | Lancement marché large. Crédibilité + mises à jour automatiques. |
| Flutter Web | H3 (backoffice uniquement) | Interface Super Admin Scalario. POS reste mobile-only (offline-first). |

### Environnements par Horizon

| Env | Horizon | Stack |
| :--- | :--- | :--- |
| dev | H1 | Local (machine Carlos) + Supabase projet dev |
| prod | H1 | Railway prod + Supabase projet prod |
| staging | H2 | Railway staging + Supabase projet staging — activé à l'ouverture du canal intégrateur |

### CI/CD

- **Backend :** GitHub Actions → Railway auto-deploy sur push `main`. Pre-deploy command : `npx prisma migrate deploy`. Rollback : Railway one-click previous deployment.
- **Flutter :** GitHub Actions build APK signé sur tag `v*.*.*`. Distribution H1 : artefact GitHub Actions → WhatsApp. Distribution H2 : Fastlane → Play Store.
- **Migrations breaking :** fenêtre de maintenance < 2h acceptable H1 (notifier clients via WhatsApp avant). Cible zero-downtime H2 (migrations additives uniquement, blue-green à évaluer H3).

### Sécurité Infrastructure

- Secrets : Railway environment variables (chiffrés au repos) — H1/H2. Doppler si équipe > 3 personnes (H3).
- Backups prod : Supabase daily auto (Pro) + export manuel S3 mensuel (H2) + test restauration trimestriel (H3).
- Isolation tenant : tenant_id applicatif + RLS Supabase (double défense — NFR8).

### NFR Infrastructure (NFR-INFRA-01–05)

- **NFR-INFRA-01 :** Deploy backend < 5 min de bout en bout (git push → live). *(H1)*
- **NFR-INFRA-02 :** Zéro perte de données lors d'un deploy (migrations additives only sur prod sans fenêtre maintenance). *(H1)*
- **NFR-INFRA-03 :** Rollback backend < 2 min en cas d'incident post-deploy. *(H1)*
- **NFR-INFRA-04 :** Backup quotidien automatique prod avec rétention 7j minimum. Test restauration effectué avant chaque nouveau client actif. *(H1)*
- **NFR-INFRA-05 :** Staging environment isolé activé avant ouverture canal intégrateur — aucun intégrateur ne teste sur prod. *(H2)*

---

## Protection des Données & Conformité

### Cadre Légal Applicable

Scalario cible la zone UEMOA et CEMAC. La conformité légale est traitée à deux niveaux : les obligations communes à la zone (OHADA, UEMOA), et les obligations spécifiques au pays du tenant (droit du travail local, fiscalité, protection des données). Toute contrainte réglementaire est un paramètre de configuration du plugin pays — jamais une ligne de code dans le Kernel.

| Réglementation | Zone / Pays | Impact Scalario | Phase |
|:---|:---|:---|:---|
| Plan Comptable Général OHADA révisé 2017 | Zone OHADA (17 pays : BF, CI, SN, CM, ML, TG, BJ…) | États financiers (bilan, compte de résultat) conformes OHADA. Plan comptable natif pré-chargé. | Phase 3 Enterprise |
| Directive UEMOA sur la fiscalité intérieure | Zone UEMOA (8 pays) | Moteur fiscal multi-juridictions : taux TVA, formats reçus, arrondi par devise, configurés par plugin pays. MVP : BF. Extension : CI, SN, ML, TG, BJ… | Phase 1 (architecture) |
| Droit du travail + sécurité sociale | Par pays — plugin configurable | Moteur de paie paramétrable : SMIG, cotisations sociales (CNSS/CARFO BF • IPRES/CSS SN • CNPS CI • CNPS CM…). Export fichier déclaration au format local. Aucune intégration API directe avec les caisses — dépôt manuel ou via portail organisme. Validation expert-comptable local obligatoire avant mise en prod. | Phase 3 Enterprise |
| Loi protection données personnelles (par pays) | BF : Loi n°010-2004 • CI : Loi n°2013-450 • SN : Loi n°2008-12 • autres pays UEMOA | Consentement collecté, finalité déclarée, droits d'accès et rectification. Conformité activée par le plugin pays. | Phase 1 (BF). Par pays à l'expansion. |
| Loi FEC / transmission fiscale — Burkina Faso (MVP) | Burkina Faso, obligatoire 2026 | Numérotation séquentielle, immuabilité des reçus, transmission DGI. Plages pré-allouées pour le mode offline. | Phase 1 MVP |
| Obligations fiscales équivalentes autres pays | CI, SN, CM, ML… | Activées par le plugin fiscal du pays à l'expansion. Jamais codées en dur dans le Kernel. | Phase 3+ |
| RGPD (extra-territorial) | UE (si clients ou employés européens concernés) | DPA à signer si pertinent. Clauses de transfert de données hors UE. | Phase 3 (expansion internationale) |

> *Principe fondateur : Scalario ne suppose jamais qu'un tenant est au Burkina Faso. La juridiction est une configuration du tenant. Les obligations légales (paie, fiscalité, protection des données) découlent du plugin pays actif, pas du code métier.*

---

## Stratégie d'Import & Migration Enterprise

Contrairement au Retail où l'import se limite au catalogue produits, l'onboarding Enterprise implique des données structurées historiques : employés, plan comptable, soldes d'ouverture. Cette section définit les formats acceptés, les règles de validation et la stratégie de migration.

### Imports par Module

| Module | Données importées | Format accepté | Validation requise | Phase |
|:---|:---|:---|:---|:---|
| Catalog (Retail) | Produits, catégories, prix, unités | CSV standardisé Scalario | Dédoublonnage par référence. Alerte prix à 0. | Phase 1 |
| RH (Enterprise) | Employés : nom, prénom, date naissance, poste, salaire brut, date entrée, type contrat (CDI/CDD), numéro CNSS | CSV RH Scalario (template fourni) | Numéro CNSS unique. Salaire ≥ SMIG. Date valide. | Phase 3 |
| Comptabilité (Enterprise) | Plan comptable OHADA personnalisé, soldes d'ouverture par compte | CSV Comptabilité Scalario (template fourni) | Numéros de compte conformes OHADA. Solde d'ouverture total actif = total passif. | Phase 3 |
| Contacts / Fournisseurs | Nom, téléphone, adresse, catégorie (client / fournisseur / les deux) | CSV Contacts Scalario | Téléphone unique par tenant. Format numéro BF validé. | Phase 2a |
| Logistique (Enterprise) | Parc matériel existant, immobilisations | CSV Logistique Scalario (template fourni) | Valeur acquisition > 0. Date mise en service valide. | Phase 3 |

### Règles de migration Retail → Enterprise

- Un tenant Retail existant peut passer en Mode Intégré Enterprise sans perte de données. Le champ `org_mode` passe de standalone à integrated.
- Les transactions Retail existantes restent intactes. Le module Comptabilité peut les importer rétroactivement comme écritures de ventes via un script de migration dédié.
- La migration est irréversible (standalone → integrated) mais sans fenêtre de maintenance : le tenant reste opérationnel pendant la transition.
- Migration integrated → federated : possible uniquement via intervention admin (création du tenant Groupe + rattachement). Prévu Phase 3.

### Gestion des erreurs d'import

- Chaque import génère un rapport d'erreur CSV : ligne concernée, champ en erreur, raison.
- Import partiel autorisé : les lignes valides sont importées, les lignes invalides sont rejetées et listées.
- Un import ne peut pas être annulé après exécution. Si correction nécessaire, archiver les enregistrements erronés et réimporter.

---

## Politique de Notifications & Alertes

Toute notification Scalario est catégorisée selon son urgence et son canal. Le propriétaire peut configurer ses préférences par catégorie depuis son profil.

> **Note :** Les noms de rôles dans la colonne "Destinataire" (Propriétaire, Gestionnaire, DRH, etc.) désignent les rôles par défaut des Templates correspondants. En RBAC dynamique (FR-RBAC-01), le destinataire est résolu par code de permission (`notifications.receive_stock_alert`, etc.) — le rôle associé à cette permission reçoit la notification, quel que soit son nom.

### Matrice Urgence / Canal

| Événement déclencheur | Urgence | Canal | Destinataire | Phase |
|:---|:---|:---|:---|:---|
| Stock ≤ seuil configuré par article (FR81–FR82) | Haute | Push in-app + WhatsApp | Propriétaire / Gestionnaire | Phase 2a |
| Sync échouée après 3 retries (voir section dédiée) | Haute | Push in-app + badge rouge | Utilisateur concerné + Admin | Phase 1 |
| Transfert de stock en attente de confirmation (> 2h) | Moyenne | Push in-app | Récepteur du transfert | Phase 1 |
| Résumé quotidien automatique (CA, pertes, articles ≤ seuil, top 3 ventes) — heure configurable, défaut 20h00 (FR86) | Info | WhatsApp (opt-in) + Push | Propriétaire | Phase 2a |
| Paiement ambassadeur envoyé | Info | WhatsApp + in-app | Ambassadeur | Phase 2b |
| Contrat employé expiré dans 30 / 15 / 7 jours | Haute | Push in-app + WhatsApp | DRH | Phase 3 Enterprise |
| Échéance fiscale dans 7 jours (TVA, CNSS, clôture DGI) | Haute | Push in-app + WhatsApp | Comptable + DG | Phase 3 Enterprise |
| Clôture mensuelle disponible (dernier jour du mois) | Moyenne | Push in-app | Comptable | Phase 3 Enterprise |
| Bon de commande validé par DG (logistique) | Moyenne | Push in-app | Resp. Achats | Phase 3 Enterprise |
| Dashboard DG : alerte stock critique cross-dép. | Haute | Push in-app | DG | Phase 3 Enterprise |

### Règles générales

- Aucune notification n'est envoyée entre 22h et 7h (heure locale du tenant), sauf urgence critique (sync échouée, données non sync depuis > 4h).
- Chaque catégorie de notification est désactivable individuellement par le propriétaire (sauf alertes système critiques).
- Les notifications WhatsApp nécessitent l'opt-in explicite du destinataire lors de l'onboarding.
- Limite anti-spam : max 5 notifications push par heure par utilisateur, sauf alertes critiques.

---

## Gestion des Échecs de Synchronisation

La sync offline-first de Scalario est conçue pour être transparente. Mais quand elle échoue définitivement, le comportement produit doit être défini précisément pour éviter la perte de données et maintenir la confiance des clients.

### Cycle de vie d'une mutation en échec

| État | Condition | Action système | Visible utilisateur |
|:---|:---|:---|:---|
| En attente | Connectivité absente | Stockage outbox local. Opérations continuent normalement. | Indicateur wifi discret en orange |
| Retry en cours | Connectivité revenue. Tentatives 1–3 (exponential backoff : 5s, 30s, 2min) | Envoi silencieux en arrière-plan. | Indicateur sync en cours (discret) |
| Conflit détecté | Deux mutations conflictuelles sur la même entité | Last-write-wins pour données non-financières. File de résolution manuelle pour données financières. | Alerte « Conflit à résoudre » avec diff avant/après |
| Échec définitif | 3 retries échoués OU erreur serveur non récupérable (400, 409) | Mutation marquée FAILED dans l'outbox. Log serveur créé. Notification admin. | Alerte rouge in-app : « X opération(s) non synchronisée(s). Contactez le support. » |
| Résolution manuelle | Intervention admin ou utilisateur | Admin peut forcer le re-push ou rejeter la mutation. | Interface dédiée dans le tableau de bord admin |

### Règles spécifiques Données Financières

- Les transactions de vente (argent encaissé) ne sont JAMAIS soumises au last-write-wins. En cas de conflit, la transaction est mise en file de résolution manuelle et le propriétaire est alerté.
- Les écritures comptables Enterprise en conflit sont gelées avec statut `PENDING_RESOLUTION`. Le comptable doit les arbitrer manuellement avant la clôture du mois.
- Les bulletins de paie validés sont immuables : une fois validés et syncés, ils ne peuvent plus être modifiés (audit trail légal).

### Monitoring & Observabilité

- Dashboard admin : liste des tenants avec mutations en échec, nombre de conflits non résolus, taux de sync des 24 dernières heures.
- Alerte automatique vers Carlos (admin) si un tenant accumule > 10 mutations FAILED en attente.
- Retention des logs d'échec : 90 jours. Export CSV disponible pour investigation.

---

## Stratégie QA & Tests

Scalario est développé en solo. La stratégie de tests est conçue pour maximiser la couverture des chemins critiques sans bloquer la vélocité. La règle : tester ce qui coûte cher à casser.

### Niveaux de tests & priorités

| Type | Quoi tester | Outil | Quand | Priorité |
|:---|:---|:---|:---|:---|
| Tests unitaires | Moteur de calcul (arrondi FCFA, paie SMIG, TVA multi-taux, règles CNSS) | Jest (NestJS) | À chaque commit sur fonctions de calcul | Critique |
| Tests d'intégration | Flux sync outbox → serveur, résolution de conflits, écritures inter-départements, activation de modules | Jest + Supertest (API NestJS) | Avant chaque déploiement | Haute |
| Tests de régression Retail | Les 5 journeys Retail (vente, session, offline, stock, migration) | Tests manuels + scripts Postman | Après toute modification kernel ou shared module | Critique |
| Tests de régression Enterprise | Journeys 6, 7, 8 (DRH, Comptable, DG). Flux inter-départements. | Tests manuels sur tenant de staging | Avant tout release Enterprise | Haute |
| Tests de performance | Grille produits < 500ms (2000 articles), sync < 30s (150 tx), cold start < 3s | Flutter DevTools + script de charge NestJS | Avant chaque release majeure | Moyenne |
| Tests de sécurité | Isolation tenant (cross-tenant data leak), RBAC (accès non autorisé) | Tests manuels + Postman avec tokens multi-tenant | Avant tout release | Critique |
| Tests de migration | 3 clients existants : zéro perte après migration Prisma | Script de comparaison avant/après sur clone DB | Avant toute migration de schéma | Critique |

### Definition of Done (DoD)

Une fonctionnalité est considérée terminée uniquement si :
- Les tests unitaires des fonctions de calcul associées passent à 100 %
- Le flux complet a été testé manuellement sur un tenant de staging
- La journey utilisateur associée (si applicable) a été exécutée de bout en bout sans erreur
- Le comportement offline (si applicable) a été testé en mode avion
- Le cas d'erreur principal (import invalide, conflit de sync, perm refusée) est géré et affiché proprement à l'utilisateur
- Aucune modification du kernel non documentée

### Environnements

| Environnement | Usage | Données | Accès |
|:---|:---|:---|:---|
| Local (dev) | Développement et tests unitaires | Données synthétiques générées | Carlos uniquement |
| Staging | Tests d'intégration, tests journeys, démos clients | Clone anonymisé de la production | Carlos + testeurs sélectionnés |
| Production | Clients réels | Données réelles chiffrées | Carlos (admin) + tenants isolés |

---

## Positionnement Concurrentiel

Scalario opère dans un espace où les concurrents sont soit trop généralistes (SAP, Odoo), soit trop limités (POS simples locaux), soit trop géo-spécifiques pour s'adapter à des marchés variés. L'avantage structurel de Scalario est son architecture universelle : offline-first natif, conformité pluggable, paiements par adaptateurs, i18n complet — conçu pour fonctionner dans n'importe quelle juridiction sans modifications core. L'UEMOA est le marché d'entrée; le positionnement vise les marchés émergents mondiaux. L'analyse ci-dessous couvre les deux segments : Retail et Enterprise.

### Segment Retail

| Concurrent | Forces | Faiblesses face à Scalario | Menace |
|:---|:---|:---|:---|
| Odoo Community (POS) | Marque connue, open-source, multi-métier | Pas offline-first. Configuration complexe. Pas adapté FCFA/FEC. Technicien requis pour installer. | Moyenne |
| Wave POS (Sénégal) | Simple, mobile money natif, croissance rapide | POS uniquement, pas d'ERP, pas offline robuste, pas de Templates Sectoriels | Faible sur Retail Pro |
| POS locaux (solutions custom) | Adaptés au marché local, prix bas | Monolithiques, pas de sync cloud, pas d'évolutivité, pas de support | Faible long terme |
| Colibris ERP (Afrique) | Présent sur le marché, adapté OHADA | Pas offline-first. Interface complexe. Pas de Templates Sectoriels. Peu d'innovation produit. | Moyenne |
| Tableur Excel / Cahier | Zéro coût, familier | Zéro contrôle, zéro rapport, zéro sécurité, zéro temps réel | Faible (c'est notre marché cible) |

### Segment Enterprise PME

| Concurrent | Forces | Faiblesses face à Scalario | Menace |
|:---|:---|:---|:---|
| SAP Business One | Référence mondiale, très complet | Prix prohibitif (> 5M FCFA/an). Complexité de mise en œuvre. Pas offline. Consultant requis. | Très faible (marché différent) |
| Sage 50 / Sage Comptabilité | Comptabilité OHADA native, présence Afrique | Pas de module RH intégré natif. Pas offline. Pas de retail intégré. Prix élevé pour PME. | Moyenne sur segment Comptabilité |
| Dext / PayFit (RH cloud) | Simple, SaaS moderne, RH avancé | Non disponible Burkina Faso. Pas de CNSS/CARFO local. Pas d'intégration Retail. | Faible actuellement |
| ERP sur mesure (développeurs locaux) | Sur mesure, relation directe | Coût élevé d'évolution, pas de product roadmap, maintenance dépendante d'un individu | Faible long terme |
| Solutions hybrides (Sage + Excel + logiciel paie) | Connu, utilisé actuellement | Données fragmentées, ressaisies, zéro flux automatisé inter-départements. C'est notre cible principale. | Faible (c'est notre marché) |

### Matrice de positionnement

| Critère | Scalario | Odoo | Wave POS | Sage | SAP B1 |
|:---|:---|:---|:---|:---|:---|
| Offline-first robuste | ✓ Natif | ✗ | ~ Partiel | ✗ | ✗ |
| Multi-devise / multi-juridiction | ✓ Natif (i18n + plugins) | ~ Manuel | ✗ Limité | ~ | ✓ coûteux |
| Retail POS intégré | ✓ | ✓ | ✓ | ✗ | ✓ |
| RH & Paie (plugin conformité locale) | ✓ Phase 3 (NFR32) | ~ Plugin | ✗ | ~ | ✓ |
| Comptabilité (plugin référentiel actif) | ✓ Phase 3 (NFR32) | ~ Module | ✗ | ✓ | ✓ |
| Multi-départements PME | ✓ Phase 3 | ✓ | ✗ | ~ | ✓ |
| Interconnexion B2B (Connect) | ✓ Phase 3 | ✗ | ✗ | ✗ | ✗ |
| Prix accessible marchés émergents | ✓ | ~ Variable | ✓ | ✗ | ✗ |
| Onboarding < 1 semaine | ✓ | ✗ | ✓ | ✗ | ✗ |
| Templates sectoriels (N secteurs) | ✓ Phase 3 | ✗ | ✗ | ✗ | ✗ |

> *Légende : ✓ = oui natif, ~ = partiel ou avec effort, ✗ = non ou hors portée.*

---

## Exigences Fonctionnelles

> **Note sur les noms de rôles dans les FRs :** Les termes "propriétaire", "gestionnaire", "commercial", "DRH", "comptable", "DG" utilisés comme sujets dans les FRs ci-dessous désignent les **rôles par défaut du Template correspondant** (Retail ou Enterprise PME), pas des valeurs hardcodées dans le système. Conformément à FR-RBAC-01, tous ces noms sont configurables par tenant — un tenant peut utiliser d'autres noms pour les mêmes niveaux d'accès. Les codes de permission sous-jacents (`catalog.edit`, `session.open`, etc.) restent stables.

### Identité & Accès (FR1–FR6)

- **FR1 :** L'admin peut créer et configurer un nouveau tenant (devise, timezone, juridiction fiscale, type de métier, org_mode)
- **FR2 :** Le propriétaire peut créer des comptes utilisateurs, assigner des rôles et, en mode Enterprise, assigner des départements
- **FR3 :** Le système applique les permissions RBAC à l'intersection (tenant, département, rôle). En mode Retail : frontières par secteur actif. En mode Enterprise : frontières par département.
- **FR4 :** Authentification JWT scopée au tenant
- **FR5 :** Isolation tenant automatique — aucun utilisateur ne peut accéder aux données d'un autre tenant
- **FR6 :** Sessions expirées après timeout configurable

### Modules & Secteurs (FR7–FR10)

- **FR7 :** L'admin peut activer ou désactiver modules partagés et modules sectoriels par tenant
- **FR8 :** Les modules sectoriels valident leurs dépendances à l'activation
- **FR9 :** Désactiver un module pour un tenant n'impacte aucun autre tenant
- **FR10 :** En mode Retail (standalone), chaque tenant a un secteur actif. En mode Enterprise (integrated), un tenant peut avoir plusieurs `business_type` actifs simultanément selon les départements configurés.

### Catalogue (FR11–FR15)

- **FR11 :** Le propriétaire peut créer, modifier et désactiver des articles (nom, prix, catégorie, code-barres)
- **FR12 :** Les articles supportent un discriminateur de type (physical, bookable, service)
- **FR13 :** Les modules sectoriels peuvent étendre les articles avec des champs spécifiques via l'UI-Driven Engine
- **FR14 :** Le propriétaire peut gérer les catégories de produits
- **FR15 :** Les données catalogue sont disponibles offline sur le device

### Transactions (FR16–FR22)

- **FR16 :** Le commercial peut créer une transaction de vente en sélectionnant articles et quantités
- **FR17 :** Le commercial peut appliquer un mode de paiement (espèces, mobile money, crédit client)
- **FR18 :** Le système calcule les totaux avec arrondi selon la devise (XOF : 5 FCFA)
- **FR19 :** Le système enregistre la monnaie rendue pour les paiements en espèces
- **FR20 :** Les transactions supportent des états de cycle de vie (instant, accumulating, scheduled)
- **FR21 :** Les modules sectoriels peuvent étendre les transactions (ex: sessionId, receiptNumber pour Retail)
- **FR22 :** Toutes les transactions sont écrites localement d'abord et mises en file de sync

### Session de Caisse (FR23–FR28)

- **FR23 :** Le commercial peut ouvrir une session en déclarant le fond de caisse initial
- **FR24 :** Toutes les ventes durant une session active sont associées à cette session
- **FR25 :** Le commercial peut clôturer une session en déclarant le montant compté
- **FR26 :** Le système calcule et affiche l'écart théorique/réel
- **FR27 :** Le commercial doit fournir une explication pour tout écart avant clôture
- **FR28 :** Le gestionnaire peut consulter les rapports de clôture de tous les commerciaux de son emplacement

### Inventaire & Stock (FR29–FR36)

- **FR29 :** Le gestionnaire peut réceptionner des livraisons fournisseurs et enregistrer les quantités reçues vs attendues
- **FR30 :** Le système trace les variances de réception avec notes observateur
- **FR31 :** Le gestionnaire peut créer des transferts magasin → rayon avec quantités déclarées
- **FR32 :** Le commercial peut confirmer la réception d'un transfert et déclarer la quantité effectivement reçue
- **FR33 :** Le système trace et attribue automatiquement les variances de transfert
- **FR34 :** Le commercial peut déclarer des pertes de stock avec motif obligatoire
- **FR35 :** Le gestionnaire peut réaliser des inventaires partiels avec signal des écarts
- **FR36 :** Les données inventaire sont maintenues localement pour le mode offline

### Contacts (FR37–FR40)

- **FR37 :** Les utilisateurs peuvent créer et gérer des profils clients (nom, téléphone, type)
- **FR38 :** Le commercial peut associer une transaction à un profil client
- **FR39 :** Le commercial peut enregistrer une vente à crédit contre un profil client, mettant à jour le solde
- **FR40 :** Les profils clients et soldes sont disponibles offline

### Synchronisation & Offline (FR41–FR47)

- **FR41 :** Toutes les opérations CRUD fonctionnent identiquement online ou offline
- **FR42 :** Le système met en file (outbox) toutes les mutations locales pour sync automatique à la reconnexion
- **FR43 :** Le moteur de sync transmet uniquement les delta (sync incrémentale)
- **FR44 :** Le système résout les conflits (last-write-wins pour données non critiques, file de résolution manuelle pour données financières)
- **FR45 :** Un indicateur de connectivité visible uniquement dans la barre de statut (< 5 % de la surface écran) s'affiche sans interrompre ni bloquer l'opération en cours. Toutes les actions locales (vente, perte, transfert) restent accessibles sans délai quelle que soit la valeur de l'indicateur. L'indicateur ne génère aucune modale, aucun toast bloquant, ni aucune demande de confirmation liée à la connectivité.
- **FR46 :** Le système reprend un état cohérent après terminaison inattendue (coupure courant, crash), zéro perte de données
- **FR47 :** La base locale retient les données opérationnelles pour une période configurable (30–90 jours)

### Reporting & Responsabilité (FR48–FR51)

- **FR48 :** Le gestionnaire peut générer un rapport de consolidation journalier (ventes, pertes, variances, transferts)
- **FR49 :** Le propriétaire peut consulter le dashboard (CA, nb ventes, pertes, écarts caisse, stock critique)
- **FR50 :** Le système maintient un audit trail immuable de toutes les mutations
- **FR51 :** Audit trail conservé indéfiniment côté serveur, période configurable en local

### Scalario Connect — Structure DB anticipée (FR52–FR55)

- **FR52 :** La table tenants inclut un champ `referred_by` (UUID nullable) et `network_visible` (bool)
- **FR53 :** La table contacts inclut un champ `linked_tenant_id` (UUID nullable) pour lier un fournisseur à un tenant Scalario
- **FR54 :** La table catalog_items inclut un champ `supplier_reference` (UUID nullable)
- **FR55 :** Les types de transactions supportent `transfer_inter_tenant` pour les futures opérations inter-tenants

### Migration & Architecture (FR56–FR58)

- **FR56 :** Migration des données clients existants vers la multi-schema architecture sans perte
- **FR57 :** Prisma opère sur les schémas kernel, shared et retail avec intégrité référentielle
- **FR58 :** Le moteur de sync opère de façon module-agnostique avec des adaptateurs par module

### Scalario Enterprise — Structure DB anticipée (FR59–FR62)

- **FR59 :** La table tenants inclut un champ `org_mode` (enum: standalone | integrated | federated) et `parent_tenant_id` (UUID nullable)
- **FR60 :** La table users inclut `department_ids` (array UUID) pour l'appartenance multi-départements
- **FR61 :** La table TenantModule inclut `department_id` (UUID nullable) pour l'activation par département
- **FR62 :** Le système supporte les événements inter-départements internes (ex: clôture paie → écriture comptable) via l'event bus du Kernel

> **Note sur les noms de départements dans les FRs Enterprise :** Les noms "RH", "Comptabilité", "Secrétariat", "Logistique" utilisés comme sujets dans les FRs ci-dessous sont les **départements par défaut du Template Enterprise PME**. Conformément au principe de départements dynamiques, chaque tenant peut nommer ses départements librement. Les fonctionnalités décrites restent identiques quel que soit le nom du département — elles sont liées aux modules activés (Contacts-employés, Transactions, Inventory, etc.), pas aux noms.

### RH & Paie Enterprise (FR63–FR68)

- **FR63 :** Le DRH peut créer et gérer des fiches employés (nom, prénom, date naissance, poste, type contrat CDI/CDD, date entrée, numéro CNSS, salaire brut)
- **FR64 :** Le système calcule automatiquement le salaire net à partir du salaire brut en appliquant les règles du plugin paie actif du tenant (SMIG, cotisations sociales, retenues). Les taux sont mis à jour par l'admin sans déploiement. *Note plugin : SMIG/CNSS/CARFO sont les défauts du plugin Burkina Faso (NFR32). Un plugin pays différent (IPRES Sénégal, CNPS CI, NSSF Kenya) active ses propres règles sans modifier ce FR ni le code métier.*
- **FR65 :** Le DRH peut enregistrer les absences (justifiées, non justifiées, congés payés) et les saisies sont prises en compte dans le calcul de paie du mois
- **FR66 :** Le système génère les bulletins de salaire de tous les employés actifs en une seule opération. Un bulletin validé est immuable (audit trail légal).
- **FR67 :** Le système génère le fichier de déclaration sociale (cotisations employés + employeur) au format attendu par l'organisme local du pays (CNSS BF, IPRES SN, CNPS CI…), exportable en CSV ou PDF. Le dépôt se fait manuellement ou via le portail de l'organisme — aucune intégration API directe n'est prévue.
- **FR68 :** La validation des bulletins émet un événement inter-départements vers le module Comptabilité : une écriture de charge salariale est créée automatiquement sans saisie manuelle

### Comptabilité & Finance Enterprise (FR69–FR72)

- **FR69 :** Le système fournit un plan comptable pré-chargé conformément au référentiel comptable actif du tenant. Le comptable peut personnaliser les sous-comptes sans modifier la structure principale. *Note plugin : OHADA révisé 2017 est le plugin comptable par défaut pour les tenants UEMOA/CEMAC (NFR32). L'architecture supporte tout référentiel comptable national via un plugin équivalent (IFRS, UK GAAP, PCG France, etc.) sans modifier ce FR ni le Kernel.*
- **FR70 :** Le comptable peut saisir des écritures manuelles au journal. Les écritures auto-générées (ventes, paie, achats) sont pré-remplies et éditables avant validation.
- **FR71 :** Le système supporte le rapprochement bancaire : import d'un relevé (CSV ou PDF), suggestion automatique des appariements, validation manuelle des écarts
- **FR72 :** Le comptable peut clôturer un mois. Après clôture, les écritures de la période sont gelées. Le système génère le bilan et le compte de résultat au format du référentiel comptable actif du tenant (OHADA par défaut pour UEMOA), exportables en PDF et Excel.

### Import Enterprise & Gestion des Erreurs (FR73–FR74)

- **FR73 :** Le système accepte l'import CSV pour : employés (module RH), plan comptable et soldes d'ouverture (module Comptabilité), parc matériel (module Logistique). Chaque import génère un rapport d'erreur ligne par ligne. L'import partiel est autorisé (lignes valides importées, lignes invalides rejetées et listées).
- **FR74 :** Un tenant Retail (org_mode: standalone) peut être migré en mode Enterprise (org_mode: integrated) sans perte de données et sans fenêtre de maintenance. Les transactions Retail existantes restent accessibles et peuvent être importées rétroactivement dans le module Comptabilité via un script de migration dédié.

### Gestion des Échecs de Sync (FR75)

- **FR75 :** Le système implémente le cycle de vie complet des mutations en échec : stockage outbox → retry automatique (3 tentatives, exponential backoff) → marquage FAILED si échec définitif → notification admin et utilisateur → interface de résolution manuelle dans le backoffice. Les mutations financières (transactions de vente, écritures comptables, bulletins validés) ne sont jamais soumises au last-write-wins : elles entrent en file de résolution manuelle obligatoire en cas de conflit.

### Inventaire Avancé & Vente Configurable (FR76–FR88)

> *Toutes les fonctionnalités de cette section sont configurables par tenant via l'interface admin (UI-Driven). Aucune valeur n'est codée en dur pour un type de commerce spécifique. Chaque paramètre est optionnel — un tenant qui ne configure pas un champ ne voit pas la fonctionnalité associée.*

- **FR76 :** Le propriétaire peut configurer pour chaque article un `unitType` parmi : `unit` (pièce), `weight` (poids), `volume` (volume), `length` (longueur). Le tenant définit l'unité native de chaque type (ex: kg, g, L, m). La configuration est modifiable depuis la fiche article sans déploiement. Par défaut, `unitType = unit`.

- **FR77 :** Pour les articles dont `unitType = weight` (ou `volume` ou `length`), le terminal POS affiche un champ de saisie de quantité en virgule flottante avec l'unité native de l'article. Le total est calculé automatiquement : `prix_unitaire × quantité_saisie`, arrondi selon la règle devise du tenant (XOF : 5 FCFA). La transaction enregistre la quantité exacte et l'unité native.

- **FR78 :** Le propriétaire peut définir par article : l'unité de vente (label libre, ex: "kg", "sachet 500g", "pièce"), le prix unitaire dans cette unité, et un facteur de conversion optionnel vers l'unité de stock (ex: 1 sachet 500g = 0.5 unité stock). Ces trois champs sont configurables depuis l'UI admin. Le facteur de conversion décrémente le stock dans l'unité de stock à chaque vente.

- **FR79 :** Le propriétaire ou le gestionnaire autorisé peut créer une commande fournisseur en sélectionnant un contact de type fournisseur, en ajoutant les articles commandés avec quantité attendue et unité, la date de livraison prévue, et des notes optionnelles. Chaque commande reçoit un identifiant unique et un statut parmi : `draft`, `confirmed`, `partially_received`, `received`, `cancelled`. Les commandes sont consultables et filtrables par statut, fournisseur et période.

- **FR80 :** Lors de la réception d'une livraison, le gestionnaire peut lier la réception à une commande fournisseur existante (FR79). Pour chaque article, il saisit la quantité effectivement reçue. Le système calcule et enregistre automatiquement la variance (reçu − commandé). Le gestionnaire peut ajouter une observation qualité libre par article (ex: "produits trop mûrs"). Variances et observations sont tracées dans l'audit trail et visibles dans les rapports de réception. La réception sans commande associée reste possible.

- **FR81 :** Le propriétaire peut définir un seuil d'alerte stock (`lowStockThreshold`) par article, exprimé dans l'unité de stock native de l'article. Le seuil est éditable depuis la fiche article sans code. La valeur `null` signifie "pas d'alerte configurée pour cet article".

- **FR82 :** Après chaque mouvement de stock (vente, perte, transfert, ajustement, reconditionnement), le système évalue le stock courant de l'article contre son `lowStockThreshold`. Si stock ≤ seuil et que l'alerte n'a pas déjà été déclenchée depuis le dernier passage au-dessus du seuil, une notification push est envoyée au propriétaire et au gestionnaire, et l'article est signalé dans le prochain résumé quotidien (FR86). L'alerte ne se redéclenche qu'après que le stock soit repassé au-dessus du seuil.

- **FR83 :** Le propriétaire peut définir des règles de reconditionnement par couple (article source, article cible) : unité source (ex: sac 5 kg), unité cible (ex: sachet 100 g), facteur de conversion (ex: 50 sachets par sac). Lorsqu'un reconditionnement est enregistré, le système décrémente le stock de l'article source et incrémente le stock de l'article cible selon le facteur. Un reconditionnement partiel est autorisé. L'opération génère un mouvement de stock de type `REPACKAGING` traçable dans l'audit trail. *(Phase 2b)*

- **FR84 :** Le propriétaire peut configurer par article : (a) une fenêtre de fraîcheur en jours (durée avant péremption depuis la date de réception) ; (b) un coefficient de tolérance en % sur le poids, représentant la perte naturelle acceptable par déshydratation ou évaporation. La date d'expiration est calculée automatiquement à chaque réception. Les écarts de poids inférieurs au coefficient de tolérance configuré ne sont pas signalés comme pertes mais comme variance naturelle. La valeur `null` sur l'un ou l'autre de ces champs signifie "non applicable pour cet article". *(Phase 2b)*

- **FR85 :** Les articles ayant une fenêtre de fraîcheur configurée (FR84) affichent un indicateur couleur dans la grille POS et dans les vues stock : Vert (> 50 % de la fenêtre restante), Orange (20–50 % restante), Rouge (< 20 % restante ou date dépassée). Les seuils de couleur (50 % et 20 %) sont configurables par tenant. Les articles en Orange ou Rouge sont présentés en priorité dans la grille POS. Un filtre "Articles urgents" permet d'afficher uniquement les articles en Orange/Rouge. *(Phase 2b)*

- **FR86 :** Chaque jour à l'heure configurable par le tenant (défaut : 20h00 heure locale du tenant), le système génère et envoie automatiquement un résumé au propriétaire via WhatsApp (si opt-in explicite) et/ou notification push contenant : (1) chiffre d'affaires total du jour, (2) montant total des pertes déclarées du jour, (3) liste des articles dont le stock est ≤ `lowStockThreshold`, (4) top 3 articles les plus vendus en quantité. L'envoi est conditionné à l'opt-in du propriétaire. Si aucune activité dans la journée, le résumé indique le message i18n correspondant à la langue du tenant ("Aucune vente enregistrée" en FR). L'heure d'envoi, les canaux et la langue des messages sont configurables par tenant depuis le profil propriétaire. *Note i18n (NFR31) : les templates de messages ne contiennent aucune string hardcodée en français — toutes les chaînes passent par le système i18n du tenant.*

- **FR87 :** Lors de la déclaration d'une perte (FR34), l'utilisateur doit sélectionner l'emplacement de la perte dans une liste configurable par tenant (ex: "Magasin", "Rayon"). Le champ emplacement est obligatoire si au moins un emplacement est configuré pour le tenant ; optionnel si aucun n'est configuré. L'emplacement est enregistré sur le `InventoryMovement` de type `LOSS`. Les rapports de pertes peuvent être filtrés et agrégés par emplacement pour attribution de responsabilité. La liste des emplacements est gérée depuis l'interface admin sans code.

- **FR88 :** Un commercial peut créer une demande de réapprovisionnement interne en spécifiant l'article, la quantité souhaitée, l'unité, et un niveau d'urgence (Normal, Urgent). La demande suit un circuit configurable par tenant : Commercial (Demande) → Gestionnaire (Préparation / validation intermédiaire) → Propriétaire (Validation finale). Chaque transition génère une notification push au prochain acteur du circuit. Le propriétaire peut approuver, modifier la quantité, ou rejeter avec un motif. Une demande approuvée génère automatiquement un transfert magasin → rayon (FR31). Les étapes du circuit sont configurables par tenant — un tenant peut activer ou désactiver l'étape intermédiaire gestionnaire.

### Variantes, Multi-tarifs & Promotions (FR89–FR91)

- **FR89 :** Un article du catalogue peut avoir des variantes configurables par le propriétaire. Chaque variante est définie par des attributs tenant-configurables (ex: taille, couleur, matière — labels libres). Chaque variante possède son propre SKU, code-barres optionnel, prix et stock indépendant. L'article parent agrège le stock total de ses variantes pour le reporting. Au POS, le commercial sélectionne d'abord le produit puis la variante avant d'ajouter au panier. Les variantes sont optionnelles — un article sans variante fonctionne exactement comme aujourd'hui. *(Phase 2b)*

- **FR90 :** Un article peut avoir plusieurs niveaux de prix configurables par le propriétaire : détail (défaut), gros, fidélité, promotionnel. Le prix applicable est déterminé automatiquement soit par le `customerType` du contact associé à la transaction, soit par la quantité commandée (seuil tenant-configurable). Le commercial peut forcer un niveau de prix manuellement si son rôle inclut la permission `price_override`. Les niveaux de prix et leurs labels sont entièrement tenant-configurables — un tenant peut en définir entre 1 et N. Le reçu affiche le niveau de prix appliqué. *(Phase 2b)*

- **FR91 :** Le propriétaire peut créer des règles de promotion configurables : (a) remise en pourcentage sur un article ou une catégorie entière, (b) offre quantitative (ex: 3 acheté = 1 offert — seuil et article offert configurables), (c) prix barré temporaire (prix original affiché barré, nouveau prix actif). Chaque promotion a une date de début, une date de fin, et un statut (active/inactive) modifiable manuellement. Les promotions actives s'appliquent automatiquement au POS dès qu'un article éligible est ajouté au panier — sans intervention du commercial. Le reçu affiche le prix original barré et le prix après remise pour chaque article remisé. Plusieurs promotions peuvent coexister ; en cas de cumul sur un même article, la promotion la plus avantageuse pour le client s'applique (configurable : plus avantageuse ou première définie). *(Phase 3)*

---

### Traçabilité Articles & Configurations Métier (FR92–FR97)

> **Note :** Tous ces champs sont optionnels et désactivés par défaut. Chaque tenant active uniquement les fonctionnalités pertinentes pour son métier via le panel admin.

- **FR92 :** Un article du catalogue peut avoir un numéro de série (IMEI, numéro de châssis, etc.) traçable par unité vendue. Le champ `serialNumber` est saisi à la vente (pas au catalogue). Le système enregistre le lien article–série–client–date de vente. L'historique des séries vendues est consultable par le propriétaire. Configurable : le propriétaire active/désactive le suivi par série par catégorie de produit. *(Phase 2b)*

- **FR93 :** Un article peut avoir une durée de garantie configurable (`warrantyMonths` sur CatalogItem). À la vente d'un article avec garantie, le système génère un certificat de garantie (numéro unique, date d'achat, date d'expiration garantie, client). Le client peut être recherché par numéro de garantie. *(Phase 2b)*

- **FR94 :** Un article peut être marqué `requiresPrescription: true` (pharmacie). À la vente, le système exige la saisie d'un numéro d'ordonnance et du nom du prescripteur avant validation. Le numéro d'ordonnance est enregistré sur la transaction. Configurable par tenant — désactivé par défaut. *(Phase 2b)*

- **FR95 :** Un lot de produit (ProductBatch) peut avoir une date de consommation optimale (`bestBeforeDate`) en plus de la date d'expiration (`expiresAt`). Le code couleur fraîcheur utilise `bestBeforeDate` si renseigné, sinon `expiresAt`. Utile pour les produits avec fenêtre de garde (vin, fromage). *(Phase 2b)*

- **FR96 :** Un article peut être marqué `dynamicPricing: true`. Le prix unitaire est mis à jour quotidiennement par le propriétaire (ou via une source externe configurable). L'historique des prix est conservé. Le POS utilise toujours le dernier prix en vigueur. Utile pour : or, carburant, matières premières. *(Phase 2b)*

- **FR97 :** Un article peut être marqué `isUnique: true` (dépôt-vente, antiquités, occasion). Le stock maximum est 1. L'article n'est pas réapprovisable — une fois vendu, il disparaît du catalogue actif. Le propriétaire peut dupliquer un article unique pour en créer un similaire. *(Phase 2b)*

---

### Retours & Réservations (FR98–FR99)

- **FR98 :** Le commercial peut enregistrer un retour article au POS.
  Le retour est lié à la transaction de vente originale (recherche par
  numéro de reçu ou scan code-barres). Le système propose :
  remboursement cash, avoir client (crédit sur le compte Contact),
  ou échange article. Le stock est automatiquement réintégré
  (StockMovement type RETURN). Le Z-report distingue les ventes
  brutes et les retours. Le propriétaire peut configurer une
  politique de retour par tenant : délai maximum (jours),
  nécessité d'un motif obligatoire, approbation manager requise
  ou non. *(Phase 2a — bloquant pour tout retail)*

- **FR99 :** Le commercial peut créer une réservation avec acompte.
  Le client paie un montant partiel (configurable : minimum 10% à 50%
  du total). La réservation crée une transaction de type "reservation"
  avec statut "pending". Le solde restant est visible sur la fiche client.
  Quand le client récupère l'article, le commercial complète le paiement
  et la transaction passe en "completed". Le propriétaire peut annuler
  une réservation — l'acompte est converti en avoir client ou remboursé.
  Le dashboard affiche un KPI "Réservations en cours" avec le montant
  total des acomptes. *(Phase 2b)*

### Plans Tarifaires & Facturation (FR100–FR103)

- **FR100 :** Le superadmin peut assigner un plan tarifaire par tenant
  (free, standard, premium, enterprise). Chaque plan est défini dans
  une table PlanDefinition : code, nom, prix mensuel, maxUsers,
  liste des modules inclus. Le changement de plan met à jour
  automatiquement les modules activés et le maxUsers. Le downgrade
  désactive les modules hors-plan (avec confirmation). Le plan
  "free" est le défaut à la création. Les plans sont configurables
  par le superadmin sans déploiement. *(Phase 2a)*

- **FR101 :** Le superadmin peut enregistrer des frais d'installation
  et de formation par tenant. Les montants sont libres (négociés
  avec le client), pré-remplis par le plan mais modifiables.
  Le panel admin affiche le statut facturation de chaque tenant :
  trial (30j gratuit), active, overdue, suspended. Un tenant
  "overdue" depuis plus de 30 jours peut être suspendu
  automatiquement (configurable). Le tenant suspendu voit un
  message "Abonnement expiré — contactez votre administrateur"
  au lieu de l'app. *(Phase 2a)*

- **FR102 :** Le propriétaire du tenant peut consulter son plan
  actuel, les modules inclus, le statut de facturation et
  l'historique des paiements depuis l'écran Paramètres de son
  backoffice. Il peut demander un upgrade de plan (notification
  envoyée au superadmin pour validation manuelle en Phase 2a).
  *(Phase 2a — self-service préparé pour Phase 3)*

- **FR103 :** Le système supporte le paiement en ligne de
  l'abonnement via une page d'onboarding dédiée. Le client
  peut : choisir son plan, payer via les méthodes disponibles
  dans sa région (Mobile Money, carte bancaire, virement),
  et son tenant est créé et activé automatiquement à la
  confirmation du paiement. L'upgrade de plan est possible
  depuis le backoffice avec paiement intégré. *(Phase 3 —
  auto-provisioning complet)* *Note adapter (NFR33) : Orange Money
  et Moov Money sont les implémentations initiales du payment
  adapter UEMOA. Le pattern adapter permet d'ajouter M-Pesa Kenya,
  Flutterwave Nigeria, Stripe global sans modifier ce FR ni la
  logique métier de facturation.*

> **Note d'encadrement :**
> Phase 2a = gestion manuelle par Carlos (panel admin).
> Phase 3 = self-service client (paiement en ligne + auto-provisioning).
> L'architecture est conçue dès Phase 2a pour supporter Phase 3
> sans migration (champs anticipation sur Tenant + PlanDefinition).

> **Direction évolution modèle tarifaire (H2+) :**
> Le modèle tarifaire cible est le **pricing modulaire** : le client paie uniquement pour ce qui est activé (modules + extensions). La facturation s'ajuste automatiquement à chaque activation via AI Config (FR-AI-04/FR-AI-05). À partir de H2, le modèle évolue vers : **prix de base Core + chaque module/extension activé = ligne de facturation additionnelle**. Les tiers fixes actuels (Starter/Standard/Premium/Enterprise) sont une simplification valide pour H1 avant que l'AI Config soit opérationnelle. FR100–FR103 restent valides pour H1 sans modification. L'architecture PlanDefinition doit anticiper une structure tarifaire par composant (modules, extensions, limites usage) dès sa conception en Phase 2a.

---

### Configuration Business Type (FR104–FR106)

- **FR104 :** Le superadmin peut assigner un type de business à chaque
  tenant lors de la création. Les types de business sont définis dans
  une table BusinessTypeDefinition configurable sans déploiement.
  Chaque type définit : un code unique, un nom affiché, des flags
  produit par défaut (trackSerialNumbers, hasVariants, warrantyMonths,
  expiryDays, requiresPrescription, isUnique, dynamicPricing, unitType),
  les sections visibles dans le formulaire produit, et une liste de
  catégories suggérées. Le type "generaliste" est le défaut — tout
  désactivé, le propriétaire configure manuellement. *(Phase 2a)*

- **FR105 :** Le formulaire de création/édition de produit dans le
  backoffice s'adapte au businessType du tenant. Les champs pertinents
  pour le type de business sont affichés en priorité et pré-remplis
  avec les défauts du type. Les champs non-pertinents sont masqués
  par défaut mais accessibles via un toggle "Afficher plus d'options".
  Le propriétaire peut toujours override chaque flag par produit —
  rien n'est verrouillé. *(Phase 2a)*

- **FR106 :** À la création d'un tenant avec un businessType, le
  système pré-crée les catégories suggérées du type (ex: "Smartphones",
  "Accessoires", "Cartes SIM" pour téléphonie). Le propriétaire peut
  renommer, supprimer ou ajouter des catégories librement. *(Phase 2a)*

> **Note d'encadrement :**
> Le businessType est un facilitateur, pas un verrou. Il pré-configure
> les défauts et masque les champs non-pertinents pour simplifier l'UX.
> Le propriétaire garde le contrôle total sur chaque produit.
> Un tenant "téléphonie" peut vendre des fruits — il suffit d'activer
> expiryDays sur ce produit spécifique.

---

### Commandes Clients (FR107–FR110)

- **FR107 :** Le commercial peut créer une commande client depuis
  le backoffice ou le POS. La commande contient : client (Contact),
  liste de produits avec quantités et prix, date de livraison souhaitée,
  mode de paiement prévu (comptant, crédit, partiel), et notes.
  Chaque commande a un numéro unique auto-généré. Si le produit a
  hasVariants: true, la variante est obligatoire. Si unitType != "piece",
  la quantité est en unité du produit (kg, litre, etc.).
  Statuts : draft → confirmed → preparing → ready → delivered → invoiced → paid.
  *(Phase 2a — bloquant pour grossiste/distribution)*

- **FR108 :** Le gestionnaire/propriétaire peut valider une commande
  (draft → confirmed). La validation vérifie la disponibilité du stock
  et alerte si stock insuffisant (sans bloquer — le propriétaire décide).
  Le gestionnaire prépare la commande (confirmed → preparing → ready)
  en cochant chaque ligne préparée. Le système réserve le stock
  des lignes préparées (StockMovement type RESERVED). *(Phase 2a)*

- **FR109 :** Le commercial enregistre la livraison (ready → delivered).
  Il saisit les quantités réellement livrées (variance possible).
  La livraison génère automatiquement une transaction de vente liée
  à la commande. Le document généré est configurable par business type :
  "Ticket de caisse" (défaut), "Bon de livraison", ou "Facture".
  Le type de document est défini dans BusinessTypeDefinition.documentType.
  Le stock réservé est converti en stock sorti (RESERVED → SALE). *(Phase 2a)*

- **FR110 :** Le propriétaire peut consulter les commandes en cours
  dans le backoffice : liste filtrable par statut, client, date.
  KPI dashboard : "Commandes en cours" (count), "CA en attente" (somme).
  Le client peut payer en plusieurs fois (paiements partiels enregistrés
  sur la commande). Le solde restant est visible sur la fiche client.
  *(Phase 2a)*

---

### Labels de Rôle par Business Type (FR111)

- **FR111 :** Chaque BusinessTypeDefinition inclut un champ roleLabels
  (Json) qui mappe les codes de rôle du Template (owner, manager,
  commercial, cashier pour le Template Retail H1) à des labels métier
  affichés dans l'UI. Exemples : "commercial" → "Chauffeur-livreur"
  (distribution), "manager" → "Pharmacien adjoint" (pharmacie).
  Les rôles sous-jacents (permissions, routing) ne changent pas —
  seul le label affiché change. Le panel admin utilise ces labels
  dans le dropdown de création d'utilisateur. Le backoffice utilise
  ces labels dans les rapports et l'historique. *(Phase 2a)*
  *Note évolution (FR-RBAC-01) : En Phase 2c, roleLabels mappe les
  IDs de rôles dynamiques du tenant (pas des codes fixes) vers des
  labels d'affichage. Le champ Json est rétro-compatible — la structure
  clé→valeur reste, les clés deviennent des role_id au lieu de noms
  fixes.*

---

### AI Assistant (FR-AI-01 à FR-AI-05)

> **Principe architectural :** L'IA est une couche d'interface universelle, jamais une fonctionnalité injectée dans un écran de module. Chaque FR ci-dessous respecte ce principe.

- **FR-AI-01 :** Section AI dédiée — panneau latéral sur demande, raccourci clavier global, mode plein écran optionnel. Jamais injecté sur les écrans de module. Présent dans toutes les offres Standard/Premium/Pro. *(Phase 1 — architecture, Phase 2b — activation)*

- **FR-AI-02 :** Actions AI invocables par module — chaque module expose un catalogue d'actions que l'IA peut invoquer via function calling (ex : créer un produit, lancer un rapport, ajuster un stock, générer une facture). L'IA ne peut invoquer que des actions déclarées — pas d'accès direct à la base de données. *(Phase 2b)*

- **FR-AI-03 :** Import Excel/CSV guidé par l'IA — import de catalogues produits, listes clients, historiques de transactions depuis fichiers externes. Mapping des colonnes piloté par l'IA (suggestion automatique des correspondances). *(Phase 2b)*

- **FR-AI-04 :** Configuration en langage naturel — l'utilisateur configure des paramètres métier via le chat AI (ex : "change le taux de TVA à 18%", "active le module RH pour ce tenant"). L'IA traduit en mutations JSON validées côté serveur avant application. *(Phase 2b)*

- **FR-AI-05 :** Config Wizard universel — assistant guidé pour l'onboarding de tout nouveau type d'organisation. Dialogue conversationnel pour générer la configuration initiale du tenant. Sélectionne et adapte le template sectoriel approprié. *(Phase 3)*

---

### Template Builder (FR-TEMPLATE-01 à FR-TEMPLATE-02)

- **FR-TEMPLATE-01 :** Template Builder AI-driven — outil destiné aux intégrateurs (pas aux utilisateurs finaux). Permet de créer et publier des templates sectoriels via configuration JSON/YAML. L'IA suggère les modules, workflows et paramètres par défaut selon la description du secteur fournie. **Pas de génération d'écrans Flutter** — les templates sont de la configuration pure. *(Phase 3)*

- **FR-TEMPLATE-02 :** Configuration de modules en langage naturel — dans le Template Builder, l'intégrateur décrit un besoin en langage naturel, l'IA génère la configuration du module (champs, règles, workflows). Sortie : JSON/YAML validé contre le schéma Scalario avant publication. *(Phase 3)*

---

### Gestion Multi-Points de Vente (FR-MULTISTORE-01)

- **FR-MULTISTORE-01 :** Dashboard propriétaire centralisé pour superviser N points de vente d'un même tenant. Trois modèles de stock supportés :
  - **Modèle A — Stock central partagé** : entrepôt central → POS consommateurs (transferts sortants).
  - **Modèle B — Stocks indépendants par POS** : chaque site gère son propre stock (pas de partage).
  - **Modèle C — Mix** : certains articles centraux, d'autres locaux, défini par article ou catégorie.
  Transferts inter-sites avec traçabilité, consolidation des rapports de vente, alertes de rupture par site. Le modèle de stock est configurable par tenant. *(Phase 2b)*

---

### Dashboard Multi-Clients Professionnels (FR-MULTISERVICE-01)

- **FR-MULTISERVICE-01 :** Interface pour les professionnels de service gérant plusieurs clients (cabinets comptables, consultants, franchiseurs). Accès délégué à N tenants clients depuis un compte professionnel unique. Vue agrégée des indicateurs clés cross-tenant. Notifications cross-tenant configurables. **Modèle Xero pour cabinets** : le client-tenant invite son comptable via email → le comptable voit tous ses clients dans un dashboard dédié sans partage de mot de passe. *(Phase 3)*

---

### Gestion des Sessions Utilisateurs (FR-SESSION-01)

- **FR-SESSION-01 :** Tableau de bord des sessions actives par utilisateur : appareil, localisation approximative, heure de connexion. Révocation instantanée d'une session individuelle depuis le backoffice admin (déconnexion forcée < 5s). Alertes connexion inhabituelle (nouveau device non reconnu, géolocalisation anormale par rapport à l'historique). Délai d'expiration de session configurable par tenant (défaut : 8h). *(Phase 2b)*

---

### Modèle Intégrateur (FR-INTEGRATOR-01 à FR-INTEGRATOR-04)

- **FR-INTEGRATOR-01 :** Prix plancher intégrateur — Le système refuse la souscription ou la modification d'un abonnement intégrateur dont le prix de revente est inférieur au prix plancher configuré par Scalario pour cette offre. Le plancher est défini dans PlanDefinition et modifiable sans déploiement. *(Phase 2b)*

- **FR-INTEGRATOR-02 :** Prix plafond intégrateur — Le système refuse la souscription ou la modification d'un abonnement intégrateur dont le prix de revente est supérieur au prix plafond configuré par Scalario pour cette offre. Le plafond est défini dans PlanDefinition et modifiable sans déploiement. *(Phase 2b)*

- **FR-INTEGRATOR-03 :** Fee dégressif par volume — Le fee wholesale appliqué à l'intégrateur est recalculé automatiquement à chaque fin de cycle de facturation selon le nombre de clients actifs : fee standard (1–5 clients), fee standard −10 % (6–20 clients), fee standard −20 % (21–50 clients), accord contractuel (50+ clients). La progression vers un palier supérieur est immédiate; la régression vers un palier inférieur est retardée d'1 cycle complet. *(Phase 2b)*

- **FR-INTEGRATOR-04 :** Commission récurrente intégrateur — L'intégrateur perçoit sa marge (prix de revente – fee wholesale) chaque mois tant que son client est actif et attaché à son compte intégrateur. La commission est suspendue si le client résilie, si le client migre vers le canal direct, ou si le compte intégrateur est suspendu. Aucune commission versée sur simple acquisition sans rétention (délai de grâce : 30 jours pour éviter les résiliations immédiates). *(Phase 2b)*

---

### Modules Core Sectoriels (FR-DEVIS-01 à FR-APPOINTMENT-01)

> Ces Modules Core sont les briques nécessaires pour servir les secteurs cibles Phase 3+. Chaque module sert plusieurs secteurs simultanément via des Templates Sectoriels distincts. Aucun dev Flutter dédié par secteur — seul le template de configuration varie.

- **FR-DEVIS-01 :** Module Devis / Fabrication — création de devis avec lignes matériaux, main d'œuvre et marge configurable. Lifecycle : brouillon → soumis → accepté/refusé → converti en work_order. Lié aux contacts clients et au catalogue. *(Phase 3+)*

- **FR-WORKORDER-01 :** Module Ordre de Fabrication — commande de fabrication avec étapes configurables (kanban). Chaque étape a un statut (à faire/en cours/terminé), un responsable assigné et une date estimée. Lié au devis (FR-DEVIS-01) et consomme le stock via FR-BOM-01. *(Phase 3+)*

- **FR-BOM-01 :** Module Nomenclature (Bill of Materials) — définition des matériaux requis par produit fabriqué (quantité, unité, article du catalog). À la validation d'un work_order, le stock des matériaux est automatiquement consommé via le module Inventory. Alerte si stock insuffisant avant lancement. *(Phase 3+)*

- **FR-ATELIERPLANNING-01 :** Module Planning Atelier — vue calendrier des ordres de fabrication par atelier ou opérateur. Gestion de la file d'attente, capacité journalière configurable, dates de livraison promises vs réelles. *(Phase 3+)*

- **FR-TABLE-01 :** Module Gestion de Salle — plan de salle configurable (tables, zones, capacité). Attribution table → commande active. Statuts temps réel : libre / occupée / réservée / nettoyage. Fusionne ou scinde des tables. Sert restaurants, hôtels (chambre), traiteurs (livraison), cafétérias. *(Phase 3+)*

- **FR-KDS-01 :** Module Kitchen Display System — tickets de préparation en temps réel depuis le POS vers la cuisine. Statuts : reçu / en cours / prêt. Notification salle à la validation. Vue par station (entrées/plats/boissons). Sert restaurants, bars, cantines. *(Phase 3+)*

- **FR-APPOINTMENT-01 :** Module Rendez-vous — prise de rendez-vous sur créneaux configurables par service et opérateur. Vue agenda opérateur (jour/semaine). Rappels automatiques client (push/SMS). Annulation et report. Lié au catalog (prestation) et aux contacts (client). Sert salons, garages, cabinets, photographes. *(Phase 3+)*

---

### RBAC Dynamique (FR-RBAC-01)

> **Contexte :** Le RBAC actuel (implémenté Story 1.2) utilise des rôles globaux partagés entre tenants (`kernel.roles` sans `tenant_id`), avec des noms de rôles hardcodés dans les décorateurs TypeScript (`@Roles('owner')`). Cette architecture est bloquante pour la vision universelle — un template "Cabinet Juridique" ne peut pas définir des rôles "Associé / Collaborateur / Secrétaire" différents d'un template "Restaurant" avec "Gérant / Serveur / Caissier". FR-RBAC-01 spécifie la cible. La dette technique est documentée dans `_bmad-output/implementation-artifacts/1-2-role-based-access-control.md`.

- **FR-RBAC-01 :** RBAC Dynamique par Tenant — les rôles sont des données stockées en base **par tenant**, pas des enums ou valeurs globales partagées. Chaque tenant définit ses propres noms de rôles (texte libre) et ses propres jeux de permissions par module via l'interface admin. Les rôles préconfigurés du Template Sectoriel appliqué sont le point de départ — le tenant peut les renommer, modifier leurs permissions, ou créer de nouveaux rôles sans déploiement. L'AI (FR-AI-02) peut créer et modifier des rôles via langage naturel ("j'ai un responsable stock qui peut voir les entrées mais pas valider les commandes" → rôle créé avec permissions exactes). Aucun nom de rôle hardcodé dans le code backend — le guard vérifie des codes de permission (`catalog.edit`, `session.open`) et non des noms de rôle. *(Architecture H1 — API de gestion Phase 2b — AI RBAC Phase 2c)*

> **Dette technique identifiée (Story 1.2) :**
>
> | Point | État actuel | Refactorisation requise | Priorité |
> | :--- | :--- | :--- | :--- |
> | `kernel.roles` sans `tenant_id` | Rôles globaux partagés, `@@unique([name, vertical])` | Ajouter `tenant_id UUID FK`, changer unique en `@@unique([name, tenantId])`. Migration + backfill des tenants existants. | **H1 (fondation)** |
> | Guard basé sur nom de rôle (`@Roles('owner')`) | `getUserRoleName()` + comparaison string | Migrer vers `@Permissions('catalog.edit')` + `hasPermission()` — déjà implémenté dans PermissionService, pas encore utilisé par le guard. | **H1 (fondation)** |
> | Aucun CRUD API rôles | Rôles créés uniquement via seed script | Endpoints `POST/GET/PATCH/DELETE /tenants/:id/roles` + `POST /tenants/:id/roles/:roleId/permissions` | **Phase 2b** |
> | AI config rôles | Non implémenté | Exposer les actions rôles dans FR-AI-02 function calling | **Phase 2c** |
>
> **Note :** La migration schema (`tenant_id` sur roles) est une fondation H1 car un Template Sectoriel ne peut pas définir des rôles sectoriels distincts tant que les rôles sont globaux. Cela bloque également la vision multi-secteur d'un seul Kernel. L'effort est limité : `hasPermission()` existe déjà dans PermissionService — la migration est principalement un changement de schema + switch du guard.

---

## Exigences Non-Fonctionnelles

### Performance

| Exigence | Cible | Contexte |
|:---|:---|:---|
| NFR1 : Rendu grille produits | < 500ms pour 2 000 articles | Recherche produit pendant rush |
| NFR2 : Enregistrement transaction | < 200ms écriture locale | Ressenti instantané sur appareils bas de gamme |
| NFR3 : Sync journée complète | < 30s pour 150+ transactions | Ne bloque pas les opérations à la reconnexion |
| NFR4 : Démarrage à froid | < 3s jusqu'à état utilisable | Reprise après coupure courant |
| NFR5 : Rapport clôture session | < 2s de génération | Fin de journée ne doit pas retarder le commercial |
| NFR6 : Empreinte RAM | < 150 Mo état stable | Tablettes Android bas de gamme 1–2 Go |
| NFR7 : Taille base locale | < 500 Mo pour 90 jours | Stockage limité appareils bas de gamme |

### Sécurité

| Exigence | Cible |
|:---|:---|
| NFR8 : Isolation tenant | Zéro fuite inter-tenant. tenant_id applicatif + RLS Supabase en défense en profondeur |
| NFR9 : Authentification | JWT avec timeout de session configurable |
| NFR10 : Chiffrement local | Base de données locale chiffrée. Protection perte/vol device |
| NFR11 : Chiffrement transport | TLS 1.2+ pour toutes les communications serveur |
| NFR12 : Audit modification prix | Chaque changement de prix tracé : acteur, timestamp, avant/après |
| NFR13 : Intégrité données financières | Toutes les mutations financières sont atomiques et logées |

### Fiabilité & Disponibilité

| Exigence | Cible |
|:---|:---|
| NFR14 : Autonomie offline | 8h+ d'opération continue sans connectivité |
| NFR15 : Reprise après crash | Zéro perte de données sur terminaison inattendue — validé par test de crash-recovery (coupure courant simulée) |
| NFR16 : Résilience sync | Retry automatique sur échec sync (délais croissants : 5s, 30s, 2min). Zéro intervention manuelle pour les cas récupérables |
| NFR17 : Uptime serveur | 99 % (Supabase self-hosted, admin solo — cible réaliste) |
| NFR18 : Durabilité données | Zéro perte de transaction, jamais |

### Scalabilité

| Exigence | Cible |
|:---|:---|
| NFR19 : Capacité tenants | 30+ tenants concurrents (objectif 12 mois) |
| NFR20 : Utilisateurs par tenant — Retail | 10 utilisateurs concurrents maximum (Standard). 20 maximum (Premium multi-sites). |
| NFR20 : Utilisateurs par tenant — Enterprise | 50 utilisateurs concurrents maximum (Pro). Distribution sur 4 départements, pics non simultanés. |
| NFR21 : Volume transactions — Retail | 500 transactions de vente / jour par tenant |
| NFR21 : Volume événements — Enterprise | 2 000 événements / jour par tenant (ventes + écritures comptables + bulletins + documents) |
| NFR22 : Taille catalogue — Retail | 5 000 articles par tenant |
| NFR22 : Volume données — Enterprise | 10 000 enregistrements par tenant (employés + fournisseurs + comptes OHADA + documents) |
| NFR23 : Croissance horizontale | Ajouter des tenants ou des départements ne nécessite aucun changement de code |

### Réseau & Bande passante

| Exigence | Cible |
|:---|:---|
| NFR24 : Compression sync | Payloads delta compressés uniquement |
| NFR25 : Bande passante minimum | Sync fonctionnelle sur 2G (50 kbps) |
| NFR26 : Pas de sync d'assets lourds | Images et fichiers exclus de la sync — données uniquement |
| NFR27 : Provisioning initial | Catalogue + config complets < 5 Mo |

### Utilisabilité

| Exigence | Cible |
|:---|:---|
| NFR28 : Onboarding caissier | Autonome après < 1h de formation |
| NFR29 : Gestion d'erreurs | Messages clairs et actionnables dans la langue de l'utilisateur. Zéro jargon technique |
| NFR30 : Transparence offline | L'utilisateur ne perçoit pas l'état de connectivité lors des opérations normales |

### Internationalisation & Localisation

| Exigence | Cible |
|:---|:---|
| NFR31 : i18n complet | Zéro chaîne de caractères française hardcodée dans le code Flutter ou NestJS. Toutes les chaînes UI passent par le système i18n. Support multi-devise natif (FCFA par défaut, extensible). |

### Conformité Pluggable

| Exigence | Cible |
|:---|:---|
| NFR32 : Framework de conformité pluggable | OHADA, CNSS, CARFO, régimes fiscaux locaux implémentés comme plugins de pays — pas de logique de conformité codée dans le core. Chaque tenant active le plugin correspondant à sa juridiction. L'ajout d'une nouvelle juridiction ne nécessite aucune modification du core. |

### Adaptateurs de Paiement

| Exigence | Cible |
|:---|:---|
| NFR33 : Pattern adaptateur paiement | Wave, Orange Money, Moov Money, et tout futur moyen de paiement implémentés comme adaptateurs interchangeables. Le core ne contient aucune intégration directe à un prestataire de paiement. Ajout d'un nouveau prestataire = nouvel adaptateur sans toucher le core. |

### Configuration Universelle

| Exigence | Cible |
|:---|:---|
| NFR34 : Unités configurables | Unités de mesure, devises, formats de date/heure configurables par tenant. Aucune valeur par défaut non surchargeable. |

### API Versionnée

| Exigence | Cible |
|:---|:---|
| NFR35 : REST API versionnée | Toutes les routes API exposées sous `/api/v1/`. Versionning sémantique. Rétrocompatibilité garantie 12 mois sur les routes v1 avant dépréciation. |

### Sécurité Mobile

| Exigence | Cible |
|:---|:---|
| NFR36 : Certificate pinning Flutter | L'application Flutter implémente le certificate pinning pour toutes les communications vers le backend Scalario. Validation du certificat côté client à chaque requête HTTPS. |

### Rate Limiting

| Exigence | Cible |
|:---|:---|
| NFR37 : Limitation de débit | Rate limiting appliqué sur toutes les routes API publiques et authentifiées. Limites par tenant, par IP, et par endpoint. Réponses HTTP 429 avec en-tête Retry-After. |

### Application des Abonnements

| Exigence | Cible |
|:---|:---|
| NFR38 : Enforcement abonnement côté serveur uniquement | Les restrictions liées au niveau d'abonnement (features, limites utilisateurs, modules actifs) sont appliquées exclusivement côté serveur via le Kernel. Aucune logique d'enforcement dans le client Flutter — l'application cliente se contente d'afficher l'état retourné par l'API. |

### Détection d'Anomalies

| Exigence | Cible |
|:---|:---|
| NFR39 : Détection d'anomalies financières | H2 — Monitoring automatique des patterns de transactions anormaux (volumes inhabituels, modifications de prix hors plage, remises atypiques). Alertes < 60s après détection vers l'owner du tenant. Seuils configurables par tenant. |

### Architecture Évolutive

| Exigence | Cible |
|:---|:---|
| NFR40 : Trajectoire microservices | H1 : monolithe modulaire NestJS (architecture actuelle). H2 : service Python/FastAPI dédié pour les fonctionnalités AI (découplé, communicant via API interne). H3 : extraction en microservices indépendants sur les bottlenecks prouvés par les métriques de production uniquement — pas de découpage prématuré. |

---

## Croissance & Projections

### Projections par An

| Horizon | Clients | Panier moyen | CA Mensuel | Statut |
|:---|:---|:---|:---|:---|
| 1 an | 100 | 15 000 FCFA | 1,5 M FCFA | Solopreneur — Validation |
| 2 ans | 600 | 20 000 FCFA | 12 M FCFA | Start-up — Croissance |
| 5 ans | 5 000 | 30 000 FCFA | 150 M FCFA | PME Leader SaaS |
| 10 ans | 40 000 | 25 000 FCFA | 1 Milliard FCFA | Institution Régionale |

> *Note : 40 000 clients sur 10 ans représente moins de 0,5 % du marché total des MPME en Afrique de l'Ouest (estimation > 5–10 millions d'unités commerciales). Ce chiffre n'inclut pas les PME multi-départements (Scalario Enterprise) dont le panier est 2 à 3x plus élevé. Le potentiel réel est considérablement plus grand.*

### Modèle de Tarification

| Offre | Cible | Prix | Inclus |
|:---|:---|:---|:---|
| Retail Standard | Boutiques, commerces de détail | 15 000 FCFA / mois | 4 utilisateurs, sync Cloud, offline-first, rapports journaliers, 1 secteur actif |
| Retail Premium | Boutiques multi-sites, réseaux | 30 000 FCFA / mois (Phase 2b) | Multi-agences, modules avancés (poids, consignes), Scalario Connect |
| Enterprise Essentiel | PME 5–20 employés | 25 000 FCFA / mois (Phase 3) | Mode Intégré, 2 départements, 10 utilisateurs, RH de base + Compta OHADA |
| Enterprise Pro | PME 20–50 employés | 50 000 FCFA / mois (Phase 3) | 4 départements, 25 utilisateurs, tous modules, Scalario Connect inclus |
| Groupe / Holding | Multi-entités, filiales | Sur devis (Phase 3) | Mode Fédéré, N tenants liés, dashboard consolidation, SLA dédié |
| Ambassadeur | Partenaires apporteurs d'affaires | Commission 20 % (Phase 2b) | 3 000 FCFA / client Retail actif / mois. Proportionnel pour Enterprise |
| Intégrateur wholesale | Agences, développeurs, revendeurs sectoriels | Fee wholesale (Phase 2b) | Prix plancher/plafond Scalario. Fee dégressif selon volume. Marge intégrateur = revente − wholesale. Voir FR-INTEGRATOR-01–04. |

> **Deux canaux de distribution :** (1) **Direct** — client souscrit via onboarding Scalario, relation et support Scalario. (2) **Indirect** — client acquis et suivi par un intégrateur mini-opérateur SaaS, Scalario facture en wholesale. Les deux coexistent sans conflit de canal.

> **Direction H2+ — Pricing modulaire :** Les tiers ci-dessus sont valides pour H1. À partir de H2 (AI Config opérationnel — FR-AI-04/FR-AI-05), le modèle évolue vers un pricing par composant : prix de base Core + chaque module/extension activé = ligne de facturation additionnelle ajustée automatiquement. Aucune modification des FRs ou de l'infrastructure H1 requise pour cette transition.

### Évolution du Modèle de Revenu (3 Horizons)

| Horizon | Streams actifs | Moteur de croissance |
| :--- | :--- | :--- |
| **H1** (Phase 1–2a) | Abonnement direct mensuel uniquement (tiers fixes Retail/Enterprise). Onboarding manuel. | Acquisition terrain + bouche-à-oreille. Valider product-market fit. |
| **H2** (Phase 2b) | + Canal intégrateur wholesale (fee dégressif par volume, voir FR-INTEGRATOR-01–04). + Commissions Ambassadeurs (3 000 FCFA / client Retail / mois). + Pricing modulaire par composant (activer un module = ligne de facturation additionnelle). | Distribution démultipliée via réseau d'intégrateurs. Panier moyen augmenté par modules additionnels. |
| **H3** (Phase 3) | + Frais réseau Scalario Connect (take-rate sur transactions B2B inter-tenants). + Self-service onboarding automatisé (FR103 : paiement Mobile Money → provisioning instant). + AI upsell (modules AI comme add-on facturable). | Effets de réseau platform. Croissance non-linéaire. Revenus transaction récurrents sans coût d'acquisition. |

> **Note :** Les trois horizons sont séquentiels, pas parallèles. H1 = maîtriser le revenu abonnement et l'économie unitaire. H2 = scale sans coût fixe (intégrateurs = force de vente variable). H3 = monétiser le réseau (valeur inter-tenants, non-linéaire).

### Infrastructure & Coûts

- Phase 1 : Supabase Cloud (Free Tier → Pro) — zéro investissement infrastructure initial
- Dès 10 clients payants : migration vers VPS Hostinger (~10 000 FCFA/mois) + Supabase self-hosted Docker
- Coût infrastructure estimé par tenant Retail : ~500 FCFA/mois (sync delta-only, pas d'assets lourds)
- Coût infrastructure estimé par tenant Enterprise : ~2 000–3 000 FCFA/mois (volume événements plus élevé, stockage documents)
- Marge brute cible : > 90 % sur Retail Standard. > 85 % sur Enterprise Pro.

---

## Gestion des Risques

### Risques Techniques

| Risque | Mitigation |
|:---|:---|
| Extraction incrémentale casse la fonctionnalité existante | Tests de régression complets à chaque étape avant déploiement |
| Migration Prisma multi-schéma corrompt les données | Dry-run sur clone DB. Script de rollback préparé par étape |
| Refactoring moteur sync cause perte de données | Sync existante maintenue en parallèle. Validation shadow-mode avant bascule |
| Régressions de performance sur entités polymorphes | Benchmark grille produits et requêtes transactions avant/après |
| UI-Driven JSON mal formé perçu par le client | Schéma JSON de layout validé côté serveur avant envoi. Fallback sur layout par défaut |
| Résolution de conflits offline trop complexe | Last-write-wins pour données non critiques. File de résolution manuelle pour données financières |

### Risques Marché

| Risque | Mitigation |
|:---|:---|
| 3 clients existants frustrés pendant la restructuration | Zéro downtime opérationnel. Fenêtre maintenance 1–2 jours avec préavis uniquement pour migration finale |
| Acquisition nouveaux clients mise en pause | Acceptable — qualité avant quantité. Focus sur stabilité architecture |
| Restructuration plus longue que prévu | Chaque étape est déployable indépendamment. Pas de dépendance tout-ou-rien |
| Copie par un concurrent après communication publique | L'exécution prime sur l'idée. Avance technique + réseau clients = barrière à l'entrée |
| Ambassadeurs qui survendent des fonctionnalités inexistantes | Kit de communication standardisé. Commissions suspendues en cas d'abus signalé |
| Complexité Enterprise sous-estimée (OHADA, CNSS, paie) | Démarrer par 1 client PME bêta avant le lancement commercial. La réglementation locale (CNSS, CARFO) doit être validée par un expert-comptable local avant la mise en production |
| Positionnement ambigu : boutique vs PME | Communication segmentée : TikTok/Facebook pour Retail, LinkedIn/WhatsApp professionnel pour Enterprise. Deux tunnels de vente distincts |

### Risques Ressources

| Risque | Mitigation |
|:---|:---|
| Développeur solo — bus factor = 1 | Architecture propre + PRD complet + docs architecture = matériel d'onboarding futur développeur |
| Dérive de périmètre durant la restructuration | Règle stricte : même fonctionnalité, nouvelle architecture. Nouvelles features en Phase 2a uniquement |
| Burnout / pression de calendrier | Approche incrémentale, pauses possibles. Chaque étape est déployable |

---

## Annexes

### A. Tests de Validation Clés

- **Test 1 — Offline complet :** Shift 8h sans internet, 127 transactions, sync < 30s à la reconnexion. Zéro perte. Zéro intervention manuelle.
- **Test 2 — Nouveau secteur via Template :** 1 développeur crée le Template Sectoriel Pharmacie (catalog + ventes + stock, Modules Core existants) en < 4 semaines. Zéro modification kernel.
- **Test 3 — Migration Retail :** 3 clients existants migrés vers la nouvelle architecture sans perte de données, fonctionnalité identique, fenêtre 1–2 jours.
- **Test 4 — Onboarding caissier :** Un caissier sans expérience ERP réalise sa première vente sans assistance en < 15 minutes de formation.
- **Test 5 — UI-Driven :** Activer le type « Pharmacie » sur un tenant affiche les champs date de péremption et DCI sans mise à jour de l'app Flutter.
- **Test 6 — Ambassadeur :** Un code de parrainage généré déclenche automatiquement le calcul de commission et le paiement Mobile Money mensuel sans intervention manuelle.
- **Test 7 — Enterprise RH+Compta+DG :** Awa (DRH) importe 15 employés et génère les bulletins en < 2h. Ibrahim (Comptable) clôture le mois et génère le bilan OHADA sans ressaisie. Serge (DG) voit CA + masse salariale + engagements achats sur un seul écran en temps réel.
- **Test 8 — Sync Failure & Résolution :** Simuler une erreur serveur non récupérable (400) après 3 retries. Vérifier : mutation marquée FAILED, notification envoyée à l'utilisateur et à l'admin, enregistrement visible dans l'interface de résolution, relance manuelle fonctionnelle.
- **Test 9 — Import Enterprise avec erreurs :** Import CSV de 20 employés dont 3 avec numéro CNSS invalide et 1 avec salaire < SMIG. Vérifier : 16 lignes importées, rapport d'erreur généré avec ligne + champ + raison pour les 4 rejets. Import répétable sans doublon.

### B. Résumé des Innovations

| Innovation | Problème résolu | Différenciation concurrentielle |
|:---|:---|:---|
| Architecture offline-first | Internet non fiable en Afrique de l'Ouest | Aucun ERP concurrent (SAP, Odoo, Sage) n'offre l'offline comme mode primaire — c'est toujours un mode dégradé chez eux |
| Chaîne de garde (Chain of Custody) | Vol de stock non détectable sans système formel | Double validation émetteur/récepteur native, écart attribué automatiquement |
| Architecture modulaire polymorphe | Duplication de code à chaque nouveau métier ou département | 60–80 % de réutilisation entre secteurs ET entre départements Enterprise |
| Conformité fiscale offline | FEC offline = numérotation séquentielle impossible | Plages pré-allouées + file DGI dédiée |
| UI-Driven Engine | App différente par métier = maintenance exponentielle | Un seul binaire Flutter, N métiers et N départements, via config JSON serveur |
| Scalario Connect | Commandes inter-entreprises manuelles (WhatsApp, téléphone, papier) | Graphe universel Acheteur/Vendeur. Migration concurrent = convaincre tous les partenaires simultanément. |
| Scalario Enterprise | ERP PME inaccessibles (trop chers, trop complexes) pour le marché africain | Multi-départements intégrés ou fédérés sur le même Kernel, tarif 25–50k FCFA vs 200k+ pour Sage |
| Gestion conflits financiers offline | Last-write-wins inapplicable sur les données financières (paie, transactions) | File de résolution manuelle dédiée pour transactions et écritures comptables. Zéro perte, zéro écrasement silencieux. |
| Onboarding Enterprise < 1 semaine | SAP/Sage : 2–6 mois de mise en œuvre avec consultants | Import CSV + configuration guidée + formation par département. Première paie en 3–5 jours. |

### C. Glossaire

| Terme | Définition |
|:---|:---|
| Kernel | Couche fondamentale : auth, multi-tenancy, RBAC, event bus, moteur sync. Ne doit jamais être modifié par un module sectoriel ou un département. |
| Shared Module | Module réutilisable entre tous les secteurs : Catalog, Contacts, Transactions, Payments, Inventory, Reporting |
| Vertical Module | Couche architecturale (dans Kernel/Shared/Vertical/Templates) : logique métier spécifique à un secteur. Exemples : Retail POS, Modules Core sectoriels (table_management, appointment, etc.). Distinct du concept de "vertical marché" — un secteur cible est servi par un Template Sectoriel + les Modules Core qu'il requiert. |
| Offline-first | Mode d'opération primaire : écriture locale d'abord, sync quand connectivité disponible. Ce n'est pas un mode dégradé. |
| Outbox | File de mutations locales en attente de synchronisation vers le serveur. Persistée sur disque (WAL). |
| UI-Driven Engine | Système qui définit le layout Flutter via configuration JSON serveur selon le `business_type` du tenant ou le département actif. |
| Scalario Connect | Système d'interconnexion inter-tenants (Phase 3). Tout tenant peut être Acheteur, Vendeur, ou les deux. Graphe universel B2B. |
| Scalario Enterprise | Mode multi-départements pour PME. Supporte le Mode Intégré (un tenant, N départements) et le Mode Fédéré (N tenants liés sous un tenant Groupe). |
| Département | Sous-unité organisationnelle d'un tenant Enterprise. Possède ses propres modules, rôles et vues de données. |
| Mode Intégré | Un seul tenant Scalario, plusieurs départements internes. Pour PME de 5–50 employés. |
| Mode Fédéré | Plusieurs tenants liés sous un tenant Groupe. Pour holdings et organisations multi-sites. |
| Ambassadeur | Client Scalario ou partenaire qui génère de nouveaux clients via code de parrainage contre commission Mobile Money. |
| Chain of Custody | Pattern de double validation des transferts de stock : émetteur déclare, récepteur confirme, écart attribué automatiquement. |
| Tenant | Entreprise cliente isolée sur la plateforme Scalario. Peut être standalone, integrated (Enterprise) ou federated (Groupe). |
| FCFA | Franc CFA (XOF). Devise principale. Arrondi natif à 5 FCFA. |
| OHADA | Organisation pour l'Harmonisation en Afrique du Droit des Affaires. Définit le plan comptable utilisé dans 17 pays africains dont le Burkina Faso. |
| SMIG | Salaire Minimum Interprofessionnel Garanti. Référence légale pour le calcul de la paie au Burkina Faso. Scalario le met à jour automatiquement. |
| CNSS | Caisse Nationale de Sécurité Sociale (Burkina Faso). Cotisations calculées par le module RH et exportées en fichier déclaration (CSV/PDF) pour dépôt manuel. Pas d'API directe disponible. |
| CARFO | Caisse Autonome de Retraite des Fonctionnaires (Burkina Faso). Applicable aux agents de la fonction publique. |
| FEC | Fichier des Écritures Comptables. Format d'export fiscal obligatoire (DGI Burkina Faso). Généré par Scalario, compatible offline via plages pré-allouées. |
| DoD | Definition of Done. Liste de critères qu'une fonctionnalité doit respecter pour être considérée terminée (tests, journey, offline, erreurs gérées). |
| WAL | Write-Ahead Logging. Mécanisme de persistance locale qui garantit zéro perte de données en cas d'arrêt brutal de l'application. |
| Last-write-wins | Politique de résolution de conflits de sync pour les données non financières : la dernière écriture l'emporte. Interdit pour les transactions et écritures comptables. |
| SLA | Service Level Agreement. Engagement de niveau de service (temps de réponse support, disponibilité). Défini par offre dans la section Onboarding & Support. |
