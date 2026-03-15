---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish']
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
version: '5.0'
date: '2026-03-11'
classification:
  projectType: saas_b2b
  domain: erp_multi_vertical_commerce
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

**Version 5.0** | **Auteur :** Carlos-simpore | **Date :** 2026-03-11

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

---

## Table des Matières

| # | Section | Contenu |
|:---|:---|:---|
| 1 | Executive Summary | Vision, principes fondateurs, ce qui rend Scalario unique |
| 2 | Classification du projet | Type, domaine, complexité, stack, état actuel |
| 3 | Critères de Succès | Métriques utilisateur, business et technique |
| 4 | Périmètre du Produit & Phases | Phase 1 (MVP), 2a, 2b (Croissance), 3 (Expansion) |
| 5 | UI-Driven Architecture | Server-Driven UI, modules par métier, roadmap verticaux |
| 6 | Scalario Connect | Interconnexion inter-entreprises, flux B2B, structure DB |
| 7 | Scalario Enterprise | Multi-départements, modes Intégré / Fédéré, flux inter-dép. |
| 8 | Programme Ambassadeurs | Modèle économique, profils, fonctionnalités, kit |
| 9 | Exigences Domain-Spécifiques | Conformité FEC/DGI, devise FCFA, anti-fraude, résilience |
| 10 | User Journeys (1–8) | Retail (Fatou, Blandine, Moussa, Carlos) + Enterprise (Awa, Ibrahim, Serge) + Offline |
| 11 | Exigences SaaS B2B | Multi-tenancy, RBAC Retail & Enterprise, modules, intégrations |
| 12 | Onboarding & Support Client | Processus par offre, SLAs, kit Ambassadeur |
| 13 | Protection des Données & Conformité | Cadre légal BF/OHADA/RGPD, données sensibles, droits utilisateurs |
| 14 | Import & Migration Enterprise | Formats CSV, règles migration Retail → Enterprise, gestion erreurs |
| 15 | Politique Notifications & Alertes | Matrice événements/canaux/destinataires, règles anti-spam |
| 16 | Gestion des Échecs de Sync | Cycle de vie outbox, conflits financiers, monitoring admin |
| 17 | Stratégie QA & Tests | Niveaux de tests, DoD, environnements (Local / Staging / Prod) |
| 18 | Positionnement Concurrentiel | Retail vs Odoo/Wave/Colibris, Enterprise vs SAP/Sage, matrice |
| 19 | Exigences Fonctionnelles (FR1–FR75) | Toutes les exigences numérotées par module |
| 20 | Exigences Non-Fonctionnelles | Performance, sécurité, fiabilité, scalabilité, réseau |
| 21 | Croissance & Projections | Projections sur 10 ans, tarification complète, infrastructure |
| 22 | Gestion des Risques | Risques techniques, marché, ressources avec mitigations |
| A | Annexe A — Tests de Validation | 9 tests clés avec critères de réussite |
| B | Annexe B — Résumé des Innovations | 9 innovations différenciantes |
| C | Annexe C — Glossaire | 24 termes définis |

---

## Executive Summary

Scalario est une plateforme ERP modulaire et multi-tenant conçue pour les entreprises d'Afrique et des marchés émergents. Contrairement aux ERP occidentaux (SAP, Odoo Enterprise) qui imposent des workflows rigides et supposent une connectivité permanente, Scalario adopte une approche « business-first » : le système s'adapte au métier et à la réalité terrain, pas l'inverse.

La plateforme repose sur une architecture trois niveaux — Kernel (identité, multi-tenancy, moteur de sync), Shared Modules (catalog, contacts, transactions, paiements, inventaire, reporting), et Vertical Modules (logique métier par secteur). Cette structure permet à tout nouveau vertical (retail, restaurant, pharmacie, services) de s'intégrer à l'infrastructure partagée existante sans toucher au kernel. Le même Kernel sert une boutique de quartier et une PME avec plusieurs départements.

Le principe fondateur est l'offline-first : le client écrit toujours localement et synchronise dès que la connectivité revient. Ce n'est pas un mode dégradé — c'est le mode d'opération primaire, conçu pour les environnements où internet est l'exception et les coupures de courant sont fréquentes.

Le premier vertical commercial est le Retail POS, actuellement en production chez 3 clients (épiceries, cosmétiques, boissons). La feuille de route étend Scalario vers la pharmacie, les services, la restauration, la logistique, et les PME multi-départements (RH, comptabilité OHADA, secrétariat, achats). À terme, Scalario Connect permet à toute entreprise sur la plateforme d'échanger des bons de commande et factures avec ses partenaires commerciaux directement depuis l'interface métier.

### Ce qui rend Scalario unique

- **Transparence réseau :** quand la connexion tombe, le commerçant ou l'employé ne le remarque pas. Les opérations continuent, la sync se fait silencieusement à la reconnexion.
- **Contrôle passif du business :** résumés WhatsApp automatiques chaque soir pour les propriétaires absents. Tableaux de bord temps réel pour les dirigeants de PME.
- **Business-first, pas configuration-first :** la logique métier (arrondi FCFA, poids, péremptions, paie CNSS, plan comptable OHADA) est une fonctionnalité native, pas un paramétrage caché.
- **Couche partagée polymorphe :** base-entity + extension verticale, 60–80 % de réutilisation entre chaque nouveau métier ou département.
- **UI-Driven Architecture :** une seule app Flutter, N métiers et départements. L'interface s'adapte dynamiquement au type de métier ou de département sans mise à jour Play Store.
- **Scalario Connect (Phase 3) :** tout tenant peut passer des bons de commande à un autre tenant. Boutique → grossiste, pharmacie → distributeur, entreprise → fournisseur. Un seul réseau.
- **Scalario Enterprise (Phase 3) :** un seul Kernel pour gérer une boutique et une PME avec RH, comptabilité, secrétariat et logistique. Mode Intégré (un tenant, N départements) ou Mode Fédéré (N entités liées) selon la taille.
- **Programme Ambassadeurs (Phase 2b) :** les clients satisfaits deviennent une force de vente terrain rémunérée via Mobile Money, sans coût fixe pour Scalario.

---

## Classification du projet

| Dimension | Valeur |
|:---|:---|
| Type de projet | SaaS B2B — Plateforme ERP multi-tenant modulaire |
| Domaine | ERP / Commerce multi-vertical + PME multi-départements / Marchés émergents Afrique de l'Ouest |
| Complexité | Haute — Architecture trois niveaux, entités partagées polymorphes, sync offline-first, UI-Driven Engine, modèle départemental, contraintes marchés émergents |
| Contexte | Brownfield — Restructuration du POS monolithique en architecture modulaire extensible |
| Stack | Flutter + NestJS + Supabase + Prisma + Isar |
| État actuel | 3 clients retail actifs (Phase 1). Roadmap : Pharmacie, Services, Logistique, PME Enterprise multi-départements, Scalario Connect inter-entreprises |
| Slogan | À définir (axe stratégique validé : Scalario s'adapte à votre métier) |

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
| 12 mois | 20–30 clients retail actifs + 1 nouveau vertical lancé (Pharmacie ou Services) | Premier revenu récurrent stable |
| Phase 3 (18–24 mois) | Scalario Connect + Scalario Enterprise lancés. Premiers clients PME multi-départements | Panier moyen clients Enterprise : 25–50k FCFA/mois |
| Signal de succès | 5 clients satisfaits qui recommandent activement | Croissance par parrainage Ambassadeurs |
| Modèle de revenu | Abonnement mensuel par tenant (Retail 15k, Enterprise 25–50k) + commissions Ambassadeurs (Phase 2b) + Scalario Connect (Phase 3) | Tarification finalisée post-stabilisation produit |

### Succès Technique

| Métrique | Cible | Validation |
|:---|:---|:---|
| Sécurité migration | Zéro perte de données pour 3 clients existants | Fenêtre de maintenance 1–2 jours acceptable |
| Vélocité nouveau vertical | 2–4 semaines pour 1 développeur | Utilise modules partagés sans toucher le kernel |
| Intégrité architecture | Ajouter un vertical ou un département Enterprise ne nécessite jamais de changement kernel | Si Pharmacie ou module RH touche le kernel = échec |
| Fiabilité offline | Shift 8h, zéro perte de données, sync silencieuse | Délai sync < 30s pour journée complète |
| Réutilisation modules partagés | 60–80 % de la couche data d'un vertical ou département | Mesuré par ratio réutilisation entités |
| UI-Driven Engine | Ajout d'un nouveau métier ou département via config JSON sans deploy Flutter | Le layout RH diffère du layout Retail sans branching applicatif |
| Scalario Enterprise | Un tenant PME avec 4 départements actifs sans dégradation de performance | Isolation des vues de données par département validée par les RLS |

---

## Périmètre du Produit & Phases

### Phase 1 — MVP : Restructuration incrémentale

Même fonctionnalité, nouvelle architecture. Décomposer le monolithe en kernel/shared/vertical. Zéro nouvelle fonctionnalité sauf l'arrondi FCFA à 5 francs dans le module Payments. 3 clients migrés sans perte de données.

### Phase 2a — Post-restructuration immédiate

- Ventes au poids (valide le pattern d'extension Catalog)
- Workflow demande de réapprovisionnement (valide événements cross-module)
- Intégration fiscale FEC/DGI (valide file de sync dédiée)
- Résumé WhatsApp soir (premier hook de rétention)

### Phase 2b — Croissance

- Suivi des pertes (taux de frotte), dépôts de bouteilles (consignes)
- Dashboard distant propriétaire (mobile)
- Import CSV catalogue
- API Mobile Money (Orange Money / Moov Money)
- Export OHADA Retail (Phase 2b) : export des écritures de ventes au format OHADA pour remise à un expert-comptable externe. Distinct de la comptabilité intégrée Enterprise (Phase 3).
- Programme Ambassadeurs (voir section dédiée ci-dessous)

### Phase 3 — Expansion

- Deuxième vertical (Pharmacie ou Services)
- Scalario Connect — Interconnexion inter-entreprises (voir section dédiée)
- Scalario Enterprise — Modèle multi-départements PME : RH & Paie, Comptabilité OHADA, Secrétariat, Logistique (voir section dédiée)
- Facturation et abonnement intégrés
- Reporting avancé, prédictions IA
- Open API, multi-devises, expansion internationale

---

## UI-Driven Architecture (Dynamic Vertical UI)

Scalario ne gère pas ses verticaux avec des branches de code distinctes. L'application Flutter embarque un moteur d'interface piloté par le serveur (Server-Driven UI) : le backend envoie une définition JSON du layout, et Flutter le rend dynamiquement selon le `business_type` du tenant.

### Principe fondamental

- Un seul binaire Flutter livré — zéro branching applicatif par métier
- Le Kernel envoie les composants UI actifs via la configuration de module
- Modifier l'interface d'un métier ne nécessite pas de mise à jour Play Store
- Chaque widget est contextuel : Date de péremption (Pharma), Unité poids/mètres (Quincaillerie), Table (Resto)

### Modules UI Contextuels par Métier

| business_type | Widgets activés | Champs spécifiques |
|:---|:---|:---|
| retail | Scanner code-barres, Remise rapide, Grille produits | weightUnit, stockQuantity, sessionId |
| pharmacy | Alerte péremption, Filtre DCI, Contrôle ordonnance | expiryDate, dci, ordonnanceRequired, lotNumber |
| services | Facturation horaire, Gestion devis | hourlyRate, quoteId, serviceDate |
| wholesale | Picking list, Gestion lots, Tarifs volume | batchId, volumeDiscount, pickingStatus |
| restaurant | Gestion tables, Bons de commande cuisine | tableNumber, courseOrder, kitchenStatus |
| enterprise_hr | Fiches employés, Bulletin de paie, CNSS | employeeId, contractType, salaryBase, cnssRef |
| enterprise_accounting | Grand livre, Balance, États OHADA | accountCode, journalType, fiscalPeriod |
| enterprise_secretariat | Courrier, Agenda, Archivage | documentType, dueDate, recipientDeptId |
| enterprise_logistics | Bons commande, Parc matériel, Fournisseurs | assetId, purchaseOrderRef, deliveryStatus |

### Roadmap des Verticaux (Publique)

> *La roadmap des métiers est communicable publiquement. Elle permet aux prospects de se projeter et crée un effet de réservation (un pharmacien qui voit « Module Pharma Q3 2026 » n'ira pas chercher un autre logiciel).*

| Phase | Métier | Statut |
|:---|:---|:---|
| Phase 1 (actuel) | Retail / Boutiques / Commerce de détail | En production |
| Phase 2a | Retail Pro (poids, consignes, pertes) | À venir |
| Phase 2b | Pharmacies & Santé | Roadmap publique Q3 2026 |
| Phase 3 | Services (garages, agences, nettoyage) | Roadmap publique Q4 2026 |
| Phase 3 | Logistique / Grossistes | Vision |
| Phase 3 | Restauration | Vision |
| Phase 3 | Enterprise PME — Multi-départements (RH, Compta, Secrétariat, Achats) | Vision |

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

Scalario Enterprise étend la plateforme aux entreprises structurées qui ont plusieurs départements internes (RH, Comptabilité, Secrétariat, Logistique/Achats). C'est le passage du marché « Boutique » au marché « PME », avec un panier moyen significativement plus élevé et une fidélité structurellement plus forte.

### Modèle de structure selon la taille

Deux modes coexistent selon la maturité de l'organisation :

| Mode | Pour qui | Fonctionnement | Exemple |
|:---|:---|:---|:---|
| Mode Intégré (Un tenant, N départements) | PME de taille moyenne (5–50 employés) | Un seul tenant Scalario. Les départements sont des sous-unités (department_id) partageant le même tenant. Chaque département a ses propres rôles, modules actifs et vues de données. | Une entreprise de transport : la direction voit tout, le RH voit uniquement la paie, le comptable voit uniquement les finances. |
| Mode Fédéré (N tenants liés) | Groupes / Holdings (50+ employés, multi-sites) | Chaque entité (filiale, agence) est un tenant indépendant. Un tenant « Groupe » consolide les rapports via Scalario Connect. Isolation totale des données entre filiales. | Un groupe avec une pharmacie, une clinique et une boutique d'optique : trois tenants, un dashboard de consolidation pour le DG. |

> *La décision Mode Intégré vs Mode Fédéré est configurée par l'admin à la création du tenant. Elle peut évoluer — une PME qui grandit peut migrer d'Intégré vers Fédéré sans perte de données.*

### Départements ciblés (Phase 3)

| Département | Modules Scalario activés | Fonctionnalités clés | Persona principal |
|:---|:---|:---|:---|
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
| PME Essentiel | 25 000 FCFA / mois | Mode Intégré, 2 départements, 10 utilisateurs, modules RH + Compta de base |
| PME Pro | 50 000 FCFA / mois | Mode Intégré, 4 départements, 25 utilisateurs, tous les modules départementaux |
| Groupe / Holding | Sur devis | Mode Fédéré, N tenants liés, dashboard consolidation, Scalario Connect inclus |

> *La tarification Enterprise est significativement plus élevée que le Retail (15 000 FCFA) car la valeur livrée est proportionnellement plus grande : une PME qui évite un comptable externe (économie de 100 000–300 000 FCFA/mois) justifie aisément 50 000 FCFA d'abonnement.*

### Structure DB à anticiper (Phase 1)

| Table | Champ à ajouter | Utilité |
|:---|:---|:---|
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

## Exigences Domain-Spécifiques

### Conformité Fiscale & Réglementaire

Scalario est conçu pour être déployé dans plusieurs pays de la zone UEMOA et CEMAC. La conformité fiscale n'est pas codée en dur — elle est pilotée par un moteur configurable par pays/juridiction. Chaque tenant est associé à une juridiction dès sa création, et les règles s'appliquent automatiquement.

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

Carlos crée un nouveau tenant Pharmacie, active les modules partagés, active le vertical Pharmacy qui ajoute ses extensions spécifiques via l'UI-Driven Engine. Le pharmacien est opérationnel en 2 heures. Zéro modification du kernel.

**Fonctionnalités révélées :** provisioning multi-tenant, configuration RBAC par vertical, système d'activation de module, import CSV catalogue, extensions CatalogItem vertical-spécifiques, isolation du kernel.

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

---

## Exigences SaaS B2B

### Multi-Tenancy

| Aspect | Implémentation |
|:---|:---|
| Modèle d'isolation | Isolation logique via tenant_id sur toutes les entités + Supabase RLS en filet de sécurité |
| Provisioning tenant | Manuel par admin (MVP). Self-service post-MVP |
| Configuration tenant | Devise, timezone, juridiction fiscale, modules actifs, vertical actif, type métier (UI-Driven) |
| Cycle de vie tenant | Créer, activer, suspendre, archiver. Pas de suppression (audit trail) |

### Matrice de Permissions RBAC — Retail

| Permission | Propriétaire | Gestionnaire | Commercial |
|:---|:---|:---|:---|
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

### Matrice de Permissions RBAC — Enterprise

En mode Enterprise, les permissions s'appliquent à l'intersection (tenant, département, rôle). Le DG voit tous les départements en lecture. Chaque responsable de département écrit uniquement dans son périmètre.

| Permission | DG | DRH | Comptable | Secrétaire | Resp. Achats |
|:---|:---|:---|:---|:---|:---|
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

### Registre & Activation des Modules

| Aspect | Implémentation |
|:---|:---|
| Registre modules | Kernel maintient le registre des modules disponibles (shared + vertical) |
| Activation par tenant | TenantModule(tenantId, moduleId, activatedAt, status) |
| Dépendances | Les modules verticaux déclarent leurs dépendances sur les modules partagés |
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

### Processus d'Onboarding par Offre

| Offre | Étape 1 | Étape 2 | Étape 3 | Durée totale |
|:---|:---|:---|:---|:---|
| Retail Standard | Carlos crée le tenant (15 min) | Import CSV catalogue ou saisie manuelle (1–2h) | Formation caissier via vidéo (45 min) — première vente < 15 min | 1 journée |
| Retail Premium | Idem Standard + activation multi-sites | Migration données existantes (1–2 jours) | Formation gestionnaire + propriétaire (3h) | 2–3 jours |
| Enterprise Essentiel | Audit préalable : liste employés + plan comptable existant (1h) | Configuration 2 départements + import CSV employés et plan comptable (demi-journée) | Formation DRH + Comptable en session dédiée (4h) | 3–5 jours |
| Enterprise Pro | Idem Essentiel + cartographie des 4 départements | Import complet + configuration flux inter-départements + validation DG | Formation par département (2h chacun) + test de clôture à blanc | 1–2 semaines |

### SLAs de Support par Offre

| Offre | Canal | Première réponse | Résolution estimée | Horaires |
|:---|:---|:---|:---|:---|
| Retail Standard | WhatsApp | < 4h ouvrables | < 24h pour bugs bloquants | Lun–Sam 8h–18h |
| Retail Premium | WhatsApp prioritaire | < 2h ouvrables | < 12h pour bugs bloquants | Lun–Sam 8h–18h |
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

### Matrice Urgence / Canal

| Événement déclencheur | Urgence | Canal | Destinataire | Phase |
|:---|:---|:---|:---|:---|
| Stock critique (< seuil configurable) | Haute | Push in-app + WhatsApp | Propriétaire / Gestionnaire | Phase 2a |
| Sync échouée après 3 retries (voir section dédiée) | Haute | Push in-app + badge rouge | Utilisateur concerné + Admin | Phase 1 |
| Transfert de stock en attente de confirmation (> 2h) | Moyenne | Push in-app | Récepteur du transfert | Phase 1 |
| Résumé soir (CA, pertes, stock critique, top 3) | Info | WhatsApp automatique | Propriétaire | Phase 2a |
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

Scalario opère dans un espace où les concurrents sont soit trop généralistes (SAP, Odoo), soit trop limités (POS simples locaux), soit inadaptés au contexte Afrique de l'Ouest (connectivité, devise, réglementation). L'analyse ci-dessous couvre les deux segments : Retail et Enterprise.

### Segment Retail

| Concurrent | Forces | Faiblesses face à Scalario | Menace |
|:---|:---|:---|:---|
| Odoo Community (POS) | Marque connue, open-source, multi-métier | Pas offline-first. Configuration complexe. Pas adapté FCFA/FEC. Technicien requis pour installer. | Moyenne |
| Wave POS (Sénégal) | Simple, mobile money natif, croissance rapide | POS uniquement, pas d'ERP, pas offline robuste, pas de verticaux | Faible sur Retail Pro |
| POS locaux (solutions custom) | Adaptés au marché local, prix bas | Monolithiques, pas de sync cloud, pas d'évolutivité, pas de support | Faible long terme |
| Colibris ERP (Afrique) | Présent sur le marché, adapté OHADA | Pas offline-first. Interface complexe. Pas de vertical dédié. Peu d'innovation produit. | Moyenne |
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
| Adapté FCFA / FEC Burkina | ✓ | ~ Manuel | ✓ Partiel | ~ | ✗ |
| Retail POS intégré | ✓ | ✓ | ✓ | ✗ | ✓ |
| RH & Paie CNSS natif | ✓ Phase 3 | ~ Plugin | ✗ | ~ | ✓ |
| Comptabilité OHADA native | ✓ Phase 3 | ~ Module | ✗ | ✓ | ✓ |
| Multi-départements PME | ✓ Phase 3 | ✓ | ✗ | ~ | ✓ |
| Interconnexion B2B (Connect) | ✓ Phase 3 | ✗ | ✗ | ✗ | ✗ |
| Prix accessible PME BF | ✓ 25–50k FCFA | ~ Variable | ✓ | ✗ > 200k | ✗ > 500k |
| Onboarding < 1 semaine | ✓ | ✗ | ✓ | ✗ | ✗ |

> *Légende : ✓ = oui natif, ~ = partiel ou avec effort, ✗ = non ou hors portée.*

---

## Exigences Fonctionnelles

### Identité & Accès (FR1–FR6)

- **FR1 :** L'admin peut créer et configurer un nouveau tenant (devise, timezone, juridiction fiscale, type de métier, org_mode)
- **FR2 :** Le propriétaire peut créer des comptes utilisateurs, assigner des rôles et, en mode Enterprise, assigner des départements
- **FR3 :** Le système applique les permissions RBAC à l'intersection (tenant, département, rôle). En mode Retail : frontières par vertical. En mode Enterprise : frontières par département.
- **FR4 :** Authentification JWT scopée au tenant
- **FR5 :** Isolation tenant automatique — aucun utilisateur ne peut accéder aux données d'un autre tenant
- **FR6 :** Sessions expirées après timeout configurable

### Modules & Verticaux (FR7–FR10)

- **FR7 :** L'admin peut activer ou désactiver modules partagés et verticaux par tenant
- **FR8 :** Les modules verticaux valident leurs dépendances à l'activation
- **FR9 :** Désactiver un module pour un tenant n'impacte aucun autre tenant
- **FR10 :** En mode Retail (standalone), chaque tenant a un vertical actif. En mode Enterprise (integrated), un tenant peut avoir plusieurs `business_type` actifs simultanément selon les départements configurés.

### Catalogue (FR11–FR15)

- **FR11 :** Le propriétaire peut créer, modifier et désactiver des articles (nom, prix, catégorie, code-barres)
- **FR12 :** Les articles supportent un discriminateur de type (physical, bookable, service)
- **FR13 :** Les modules verticaux peuvent étendre les articles avec des champs spécifiques via l'UI-Driven Engine
- **FR14 :** Le propriétaire peut gérer les catégories de produits
- **FR15 :** Les données catalogue sont disponibles offline sur le device

### Transactions (FR16–FR22)

- **FR16 :** Le commercial peut créer une transaction de vente en sélectionnant articles et quantités
- **FR17 :** Le commercial peut appliquer un mode de paiement (espèces, mobile money, crédit client)
- **FR18 :** Le système calcule les totaux avec arrondi selon la devise (XOF : 5 FCFA)
- **FR19 :** Le système enregistre la monnaie rendue pour les paiements en espèces
- **FR20 :** Les transactions supportent des états de cycle de vie (instant, accumulating, scheduled)
- **FR21 :** Les modules verticaux peuvent étendre les transactions (ex: sessionId, receiptNumber pour Retail)
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
- **FR45 :** Indicateur de connectivité discret et non-bloquant
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

### RH & Paie Enterprise (FR63–FR68)

- **FR63 :** Le DRH peut créer et gérer des fiches employés (nom, prénom, date naissance, poste, type contrat CDI/CDD, date entrée, numéro CNSS, salaire brut)
- **FR64 :** Le système calcule automatiquement le salaire net à partir du salaire brut en appliquant les règles SMIG, cotisations CNSS, CARFO et retenues configurables. Les taux sont mis à jour par l'admin sans déploiement.
- **FR65 :** Le DRH peut enregistrer les absences (justifiées, non justifiées, congés payés) et les saisies sont prises en compte dans le calcul de paie du mois
- **FR66 :** Le système génère les bulletins de salaire de tous les employés actifs en une seule opération. Un bulletin validé est immuable (audit trail légal).
- **FR67 :** Le système génère le fichier de déclaration sociale (cotisations employés + employeur) au format attendu par l'organisme local du pays (CNSS BF, IPRES SN, CNPS CI…), exportable en CSV ou PDF. Le dépôt se fait manuellement ou via le portail de l'organisme — aucune intégration API directe n'est prévue.
- **FR68 :** La validation des bulletins émet un événement inter-départements vers le module Comptabilité : une écriture de charge salariale est créée automatiquement sans saisie manuelle

### Comptabilité & Finance Enterprise (FR69–FR72)

- **FR69 :** Le système fournit un plan comptable pré-chargé conformément au Système Comptable OHADA révisé 2017. Le comptable peut personnaliser les sous-comptes sans modifier la structure principale.
- **FR70 :** Le comptable peut saisir des écritures manuelles au journal. Les écritures auto-générées (ventes, paie, achats) sont pré-remplies et éditables avant validation.
- **FR71 :** Le système supporte le rapprochement bancaire : import d'un relevé (CSV ou PDF), suggestion automatique des appariements, validation manuelle des écarts
- **FR72 :** Le comptable peut clôturer un mois. Après clôture, les écritures de la période sont gelées. Le système génère le bilan et le compte de résultat au format OHADA, exportables en PDF et Excel.

### Import Enterprise & Gestion des Erreurs (FR73–FR74)

- **FR73 :** Le système accepte l'import CSV pour : employés (module RH), plan comptable et soldes d'ouverture (module Comptabilité), parc matériel (module Logistique). Chaque import génère un rapport d'erreur ligne par ligne. L'import partiel est autorisé (lignes valides importées, lignes invalides rejetées et listées).
- **FR74 :** Un tenant Retail (org_mode: standalone) peut être migré en mode Enterprise (org_mode: integrated) sans perte de données et sans fenêtre de maintenance. Les transactions Retail existantes restent accessibles et peuvent être importées rétroactivement dans le module Comptabilité via un script de migration dédié.

### Gestion des Échecs de Sync (FR75)

- **FR75 :** Le système implémente le cycle de vie complet des mutations en échec : stockage outbox → retry automatique (3 tentatives, exponential backoff) → marquage FAILED si échec définitif → notification admin et utilisateur → interface de résolution manuelle dans le backoffice. Les mutations financières (transactions de vente, écritures comptables, bulletins validés) ne sont jamais soumises au last-write-wins : elles entrent en file de résolution manuelle obligatoire en cas de conflit.

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
| NFR15 : Reprise après crash | Zéro perte de données sur terminaison inattendue (WAL) |
| NFR16 : Résilience sync | Retry automatique avec exponential backoff. Zéro intervention manuelle |
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
| Retail Standard | Boutiques, commerces de détail | 15 000 FCFA / mois | 4 utilisateurs, sync Cloud, offline-first, rapports journaliers, 1 vertical actif |
| Retail Premium | Boutiques multi-sites, réseaux | 30 000 FCFA / mois (Phase 2b) | Multi-agences, modules avancés (poids, consignes), Scalario Connect |
| Enterprise Essentiel | PME 5–20 employés | 25 000 FCFA / mois (Phase 3) | Mode Intégré, 2 départements, 10 utilisateurs, RH de base + Compta OHADA |
| Enterprise Pro | PME 20–50 employés | 50 000 FCFA / mois (Phase 3) | 4 départements, 25 utilisateurs, tous modules, Scalario Connect inclus |
| Groupe / Holding | Multi-entités, filiales | Sur devis (Phase 3) | Mode Fédéré, N tenants liés, dashboard consolidation, SLA dédié |
| Ambassadeur | Partenaires apporteurs d'affaires | Commission 20 % (Phase 2b) | 3 000 FCFA / client Retail actif / mois. Proportionnel pour Enterprise |

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
- **Test 2 — Nouveau vertical :** 1 développeur crée le vertical Pharmacie (catalog + ventes + stock) en < 4 semaines. Zéro modification kernel.
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
| Architecture modulaire polymorphe | Duplication de code à chaque nouveau métier ou département | 60–80 % de réutilisation entre verticaux ET entre départements Enterprise |
| Conformité fiscale offline | FEC offline = numérotation séquentielle impossible | Plages pré-allouées + file DGI dédiée |
| UI-Driven Engine | App différente par métier = maintenance exponentielle | Un seul binaire Flutter, N métiers et N départements, via config JSON serveur |
| Scalario Connect | Commandes inter-entreprises manuelles (WhatsApp, téléphone, papier) | Graphe universel Acheteur/Vendeur. Migration concurrent = convaincre tous les partenaires simultanément. |
| Scalario Enterprise | ERP PME inaccessibles (trop chers, trop complexes) pour le marché africain | Multi-départements intégrés ou fédérés sur le même Kernel, tarif 25–50k FCFA vs 200k+ pour Sage |
| Gestion conflits financiers offline | Last-write-wins inapplicable sur les données financières (paie, transactions) | File de résolution manuelle dédiée pour transactions et écritures comptables. Zéro perte, zéro écrasement silencieux. |
| Onboarding Enterprise < 1 semaine | SAP/Sage : 2–6 mois de mise en œuvre avec consultants | Import CSV + configuration guidée + formation par département. Première paie en 3–5 jours. |

### C. Glossaire

| Terme | Définition |
|:---|:---|
| Kernel | Couche fondamentale : auth, multi-tenancy, RBAC, event bus, moteur sync. Ne doit jamais être modifié par un vertical ou un département. |
| Shared Module | Module réutilisable entre tous les verticaux : Catalog, Contacts, Transactions, Payments, Inventory, Reporting |
| Vertical Module | Logique métier spécifique à un secteur : Retail POS, Pharmacy, Services, Restaurant |
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
