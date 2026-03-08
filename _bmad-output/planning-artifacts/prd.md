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

# Product Requirements Document - Scalario

**Author:** Carlos-simpore
**Date:** 2026-03-08

## Executive Summary

Scalario is a modular, multi-tenant ERP platform purpose-built for businesses in Africa and emerging markets. Unlike Western-designed ERPs (SAP, Odoo Enterprise) that force businesses into rigid, configuration-heavy workflows, Scalario adopts a "business-first" approach: the system adapts to the trade, not the other way around.

The platform operates on a three-tier architecture — Kernel (identity, tenancy, sync engine), Shared Modules (catalog, contacts, transactions, payments, inventory, reporting), and Vertical Modules (industry-specific logic). This structure allows any new business vertical (retail, restaurant, pharmacy, services) to plug into existing shared infrastructure without touching the kernel or duplicating core logic.

Scalario's foundational principle is offline-first: the client always writes locally and syncs when connectivity returns. This is not a degraded fallback mode — it is the primary operating mode, designed for environments where internet is the exception and power cuts are routine. The first commercial vertical is Retail POS, currently serving 3 clients across grocery, cosmetics, and beverage shops, with prospects emerging in pharmacy and services.

The platform handles African market realities that global ERPs ignore: FCFA currency with 5-franc rounding, bulk sales by weight (grams), spoilage rates on perishable goods, bottle deposit tracking, and WhatsApp-based business reporting for owners who manage remotely. Target users are non-technical — the system must be learnable in under one hour.

This PRD defines the restructuring of the current monolithic POS codebase into the modular kernel/shared/vertical architecture, preserving all existing functionality while enabling multi-vertical expansion.

### What Makes This Special

1. **Network transparency** — When connectivity drops, the merchant doesn't notice. Sales, payments, and stock updates continue uninterrupted. Sync happens silently on reconnection. Competitors stop working; Scalario keeps selling.

2. **Passive business control** — Owners receive automated evening summaries via WhatsApp: daily revenue, losses, critical stock alerts. No manual checking, no next-day ledger review. The shift from "enduring your business" to "controlling it from home" is the retention inflection point.

3. **Business-first, not configuration-first** — The modular architecture allows each vertical to embed domain-specific trade logic (bulk pricing by weight, spoilage tracking, deposit systems) as first-class features, not afterthought configurations buried in settings menus.

4. **Polymorphic shared layer** — Shared modules (Catalog, Transactions, Inventory) use a base-entity + vertical-extension pattern with type discriminators (`physical | bookable | service`), enabling new verticals to reuse 60-80% of existing infrastructure.

## Project Classification

| Dimension | Value |
|:---|:---|
| **Project Type** | SaaS B2B — Multi-tenant modular ERP platform |
| **Domain** | ERP / Multi-vertical commerce |
| **Complexity** | High — Three-tier modular architecture, polymorphic shared entities, offline-first sync with per-module adapters, emerging market constraints |
| **Project Context** | Brownfield — Restructuring existing monolithic POS into modular architecture |
| **Stack** | Flutter (mobile/desktop/web) + NestJS (backend) + Supabase (auth/DB/realtime) + Prisma (ORM) + Isar (local DB) |
| **Current State** | 3 active retail clients, working POS with offline-first, sync, sessions, customers, orders, stock movements |

## Success Criteria

### User Success

| Persona | Success Metric | Target |
|:---|:---|:---|
| **Cashier** | Autonomous after training | < 1 hour: open session, search product, sell, cash payment, close session |
| **Shop Owner** | Autonomous on configuration & reports | < 3 hours: products, categories, pricing, read reports |
| **Store Manager** | Autonomous on stock operations | < 2 hours: reception, transfers, adjustments |
| **Cashier (offline)** | Full-shift operation without connectivity | 8+ hours, zero data loss, zero workflow interruption |
| **Owner (remote)** | Evening WhatsApp summary received automatically | Daily: revenue, sale count, losses, cash variance, critical stock, top 3 products. Readable in < 10 seconds |
| **All users** | Sync after reconnection | < 30 seconds for a full day of transactions |

### Business Success

| Timeframe | Target | Priority |
|:---|:---|:---|
| **6 months** | 3 existing clients migrated + 5-10 new retail clients on new architecture | Quality & reliability over quantity |
| **12 months** | 20-30 active retail clients + 1 new vertical launched (pharmacy or services) | First stable recurring revenue |
| **Success signal** | 5 satisfied clients who actively recommend > 20 clients who struggle | Referral-driven growth |
| **Revenue model** | Hybrid: monthly subscription per tenant, tiered by users/modules | Free/low entry for small shops, value scales with module activation. Pricing finalized post-product stabilization |

### Technical Success

| Metric | Target | Validation |
|:---|:---|:---|
| **Migration safety** | Zero data loss for 3 existing clients | 1-2 day maintenance window acceptable with advance notice |
| **New vertical velocity** | 2-4 weeks for 1 developer to ship a basic vertical | Uses shared modules (catalog, transactions, inventory, payments) without touching kernel or duplicating shared code |
| **Architecture integrity** | Adding a vertical never requires kernel changes | If pharmacy vertical touches kernel = restructuring failure |
| **Offline reliability** | 8-hour shift, zero data loss, automatic silent sync | Sync delay < 30s for full day of transactions |
| **Shared module reuse** | 60-80% of a new vertical's data layer comes from shared modules | Measured by LOC or entity reuse ratio |

### Measurable Outcomes

1. **The Offline Test** — A cashier works a full 8-hour shift without internet. At end of day, connectivity returns, and all transactions sync within 30 seconds. Zero data loss. Zero manual intervention.
2. **The Vertical Test** — A single developer creates a basic "pharmacy" vertical (catalog + sales + stock) in under 4 weeks, reusing shared modules, with zero changes to kernel code.
3. **The Migration Test** — All 3 existing clients are migrated to the new architecture with zero data loss and identical functionality within the 1-2 day maintenance window.
4. **The Onboarding Test** — A new cashier with no prior ERP experience processes their first sale unassisted within 15 minutes of starting training.

## Product Scope

> Detailed phased development plan, MVP boundaries, and risk mitigation strategies are defined in the **Project Scoping & Phased Development** section below.

**MVP (Phase 1): Incremental Platform Restructuring**
Same functionality, new architecture. Decompose monolith into kernel/shared/vertical. Zero new features except FCFA 5-franc rounding in Payments module. 3 clients migrated with zero data loss.

**Phase 2a: Immediate Post-Restructuring**
1. Weight-based sales (validates Catalog extension pattern)
2. Restock request workflow (validates cross-module events)
3. FEC/DGI fiscal integration (validates dedicated sync queue)
4. WhatsApp evening summary (primary retention hook)

**Phase 2b: Growth**
Spoilage tracking, bottle deposits, remote dashboard, CSV import, mobile money API, OHADA export, multi-branch

**Phase 3: Expansion**
Second vertical (pharmacy/services), subscription billing, advanced reporting, AI predictions, open API, multi-currency, international expansion

## User Journeys

### Journey 1: Fatou, Commercial — Une journée complète

**Persona:** Fatou, 24 ans, commerciale au rayon fruits & legumes. Pas de formation informatique, a appris le systeme en 45 minutes. Utilise une tablette Android posee sur le comptoir.

**Opening Scene:** 7h30, Fatou arrive et ouvre sa session de caisse. Elle saisit son code, declare le fond de caisse (15 000 FCFA en especes). Le systeme affiche son rayon et les produits disponibles.

**Rising Action:**
- Moussa le gestionnaire a prepare 3 caisses de tomates (8 kg) et 2 caisses de mangues pour son rayon. Fatou ouvre la notification de transfert sur sa tablette, verifie physiquement : les tomates sont bien la mais elle ne compte que 7 kg. Elle confirme la reception en saisissant 7 kg au lieu de 8. L'ecart de 1 kg est automatiquement trace — le systeme sait que le produit a ete sorti par Moussa (8 kg) mais recu par Fatou (7 kg). Blandine verra cet ecart ce soir.
- 9h, les premiers clients arrivent. Fatou vend des tomates au poids — 500g a 1200 FCFA/kg = 600 FCFA, arrondi a 600 FCFA. Le client paie avec un billet de 1000 FCFA, rendu : 400 FCFA. Tout s'enregistre localement — le wifi est tombe a 8h45 et personne ne s'en est rendu compte.
- 11h, pic de clients. Un client veut des mangues mais le rayon est presque vide. Fatou lance une demande de reapprovisionnement a Moussa depuis sa tablette tout en encaissant le client suivant.
- 14h, les tomates restantes ont tourne. Fatou declare 1.2 kg en perte (taux de frotte) dans le systeme avec motif "produit trop mur". Le stock est ajuste immediatement. Si elle ne le fait pas, l'ecart apparaitra comme un vol potentiel a l'arret de caisse.

**Climax:** 18h, fin de journee. Fatou lance l'arret de caisse. Elle compte ses especes : 127 500 FCFA. Le systeme affiche un chiffre d'affaires theorique de 128 000 FCFA. Ecart : -500 FCFA. Fatou saisit l'explication : "rendu monnaie approximatif sur plusieurs ventes en petite monnaie." Le rapport est cloture et transmis automatiquement a Moussa pour consolidation.

**Resolution:** Le wifi est revenu a 16h. En arriere-plan, les 127 transactions de la journee se sont synchronisees en 18 secondes. Fatou n'a rien eu a faire. Le rapport de caisse, les pertes declarees, l'ecart de reception — tout est remonte au cloud. Blandine pourra tout voir ce soir depuis son telephone.

**Requirements revealed:** Offline-first transaction engine, weight-based sales with FCFA rounding, stock transfer reception with quantity variance tracking, loss declaration with motif, cash session open/close with variance reporting, automatic background sync, restock request workflow.

### Journey 2: Blandine, Proprietaire a distance — Controler sans etre la

**Persona:** Blandine, 41 ans, entrepreneuse. Vit dans un autre pays, gere son epicerie fine a distance. N'a jamais mis les pieds dans un ERP avant Scalario. Utilise son smartphone Android pour tout suivre.

**Opening Scene:** Lundi matin, Blandine est chez elle. Elle sait que le stock de tomates sera bas d'ici mercredi d'apres les ventes de la semaine derniere. Elle ouvre Scalario sur son telephone et saisit une commande fournisseur : 20 cartons de tomates (160 kg), 10 cartons de mangues, 5 sacs d'oignons. Le fournisseur sera prevenu, et Moussa saura qu'une livraison est attendue.

**Rising Action:**
- Mardi, le fournisseur livre. Moussa receptionne au magasin. Blandine recoit une notification : "Reception partielle — 18 cartons de tomates recus sur 20 commandes. Observation de Moussa : 2 cartons non livres par le fournisseur." Blandine note l'info pour relancer le fournisseur.
- Mercredi soir, Blandine recoit son resume WhatsApp. Elle scanne les chiffres en 10 secondes : CA du jour 340 000 FCFA, 89 ventes, pertes declarees 4 200 FCFA (tomates et mangues), ecart de caisse Fatou -500 FCFA, ecart de caisse Amadou +200 FCFA. Stock critique : oignons (reste 2 jours). Top 3 : tomates, mangues, piments.
- Jeudi, elle voit dans le tableau de bord un ecart de stock suspect sur les mangues — Moussa a sorti 15 kg vers le rayon de Fatou, mais Fatou n'a confirme que 13 kg. 2 kg de mangues ont disparu entre le magasin et le rayon. Elle appelle Moussa pour comprendre.

**Climax:** La tracabilite maillon par maillon lui montre exactement ou l'ecart s'est produit. Elle n'a pas besoin de prendre un avion pour verifier. Le systeme a fait le travail de surveillance a sa place.

**Resolution:** En un mois, Blandine a identifie un pattern : les ecarts se produisent systematiquement le matin entre 7h et 8h, avant l'arrivee de Fatou. Elle ajuste le process : Moussa ne sort plus les produits avant que le commercial ne soit present pour confirmer immediatement. Les pertes inexpliquees chutent de 40%.

**Requirements revealed:** Remote supplier order management, reception tracking with variance, WhatsApp summary engine, real-time dashboard accessible on mobile, stock transfer traceability chain (who sent, who received, quantity delta), historical pattern analysis for loss detection.

### Journey 3: Moussa, Gestionnaire de magasin — Le pivot operationnel

**Persona:** Moussa, 35 ans, gestionnaire du magasin central de Blandine. Responsable du stock, des receptions fournisseur, et de l'approvisionnement des rayons. Utilise une tablette au magasin.

**Opening Scene:** 6h, Moussa arrive au magasin avant les commerciaux. Il verifie les commandes en attente : une livraison de tomates et mangues est prevue ce matin. Il prepare l'espace de reception.

**Rising Action:**
- 7h, le fournisseur arrive. Moussa ouvre la commande correspondante dans le systeme (saisie par Blandine) et coche chaque ligne recue. 18 cartons de tomates sur 20 — il note l'ecart et ajoute une observation. Les mangues sont completes mais il note "qualite moyenne, certaines trop mures". Il valide la reception — le stock magasin est mis a jour.
- 7h30, il prepare les sorties vers les rayons. Il selectionne les produits, pese les quantites a envoyer a chaque commercial, et cree les transferts dans le systeme. 8 kg de tomates pour Fatou, 6 kg pour Amadou. Le statut passe en "sorti du magasin, en attente de confirmation rayon".
- 11h, Fatou lance une demande de reapprovisionnement en mangues. Moussa recoit l'alerte, verifie le stock magasin, prepare 5 kg et cree un nouveau transfert.
- 15h, Moussa fait un inventaire partiel — il scanne les produits restants au magasin et compare avec le stock theorique. Le systeme signale un ecart de 3 kg d'oignons. Il le declare et documente : "sac perce, perte au sol".

**Climax:** 18h30, les commerciaux ont cloture leurs caisses. Moussa consolide les rapports du jour : ventes par rayon, pertes declarees, ecarts de reception, ecarts de transfert. Le rapport consolide est automatiquement disponible pour Blandine.

**Resolution:** Moussa n'a jamais touche la caisse. Les commerciaux n'ont jamais accede au magasin. Chaque maillon de la chaine est responsable de son perimetre. Blandine voit tout sans etre la.

**Requirements revealed:** Supplier delivery reception with order matching, stock transfer creation with weight tracking, multi-location inventory (warehouse vs shelf), restock request workflow, partial inventory count with variance declaration, daily consolidation report generation, role-based access (manager cannot sell, commercial cannot receive at warehouse).

### Journey 4: Carlos, Admin systeme — Onboarding d'un nouveau client

**Persona:** Carlos, developpeur et admin de la plateforme Scalario. Doit onboarder un nouveau client (pharmacie) sur le systeme.

**Opening Scene:** Un pharmacien a Bobo-Dioulasso veut utiliser Scalario. Carlos cree un nouveau tenant dans le systeme admin.

**Rising Action:**
- Carlos cree le tenant, configure les roles (pharmacien-proprietaire, preparateur, caissier), et active les modules partages : Catalog, Contacts, Transactions, Payments, Inventory.
- Il active le vertical "Pharmacy" (post-restructuring). Le vertical ajoute automatiquement les extensions specifiques : champs `ordonnanceRequise`, `DCI`, `datePeremption` sur le CatalogItem de base, et les regles metier (controle de peremption a la vente, alertes stock sur medicaments essentiels).
- Le pharmacien se connecte, importe son catalogue de medicaments via CSV, configure ses categories (antibiotiques, antidouleurs, hygiene...). Il est operationnel en 2 heures.

**Climax:** Le vertical Pharmacy a ete cree en 3 semaines par Carlos, en branchant sur les modules partages existants. Zero modification du kernel. Le CatalogItem de base (nom, prix, categorie) fonctionne identiquement au retail — seules les extensions pharmacie ont ete ajoutees.

**Resolution:** Scalario sert maintenant retail + pharmacie avec le meme kernel, les memes modules partages, et deux verticaux independants. Le pharmacien utilise le meme sync engine, le meme offline-first, la meme gestion des paiements que Blandine — sans que ni l'un ni l'autre ne soit impacte.

**Requirements revealed:** Multi-tenant provisioning, role configuration per vertical, vertical module activation system, CSV import for catalog, vertical-specific CatalogItem extensions without base model changes, kernel isolation validation.

### Journey 5: Fatou, Offline Crisis — Journee sans internet

**Persona:** Fatou (same as Journey 1), day where internet goes down completely.

**Opening Scene:** 7h30, Fatou ouvre sa session normalement. Elle ne sait pas que l'antenne du quartier est en panne — le wifi de la boutique est mort depuis 5h du matin.

**Rising Action:**
- Toutes les donnees sont deja en local (catalogue, prix, stock, clients reguliers). Fatou ne voit aucune difference — la grille de produits s'affiche, les prix sont la, le stock est a jour (derniere sync la veille a 19h).
- Elle vend normalement toute la journee. 127 transactions. Chaque vente est ecrite dans la base locale (Isar) et ajoutee a la file d'attente de synchronisation (outbox). Un petit indicateur discret dans un coin de l'ecran montre "hors ligne" — Fatou l'a remarque mais ne s'en preoccupe pas.
- Un client regulier, Mamadou, achete a credit. Fatou selectionne son profil client (disponible en local), enregistre la vente avec "paiement : credit client". Le solde debiteur de Mamadou est mis a jour localement.
- 14h, Fatou declare des pertes sur les tomates — tout fonctionne, c'est local.
- 16h, Moussa envoie un transfert de stock depuis sa tablette. Le transfert est aussi en local chez lui. Fatou ne recoit PAS la notification car ils ne sont pas synchronises. Elle le recevra a la reconnexion.

**Climax:** 17h30, l'antenne est reparee. Le wifi revient. En arriere-plan, le sync engine detecte la connectivite et commence a pousser la file d'attente : 127 transactions, 3 declarations de perte, 1 vente a credit, l'arret de caisse. Tout part en 22 secondes. En retour, le transfert de Moussa arrive et le stock local est mis a jour.

**Resolution:** Fatou cloture sa session. Le rapport est identique — qu'il y ait eu du wifi ou non. Blandine, depuis son telephone, voit le rapport du jour sans savoir qu'il y a eu une coupure internet de 12 heures. La journee de vente n'a pas ete impactee d'une seconde.

**Requirements revealed:** Full offline operation (all CRUD local), outbox queue with automatic push on reconnect, local customer profiles with offline credit tracking, graceful notification delivery post-sync, sync status indicator (subtle, non-blocking), conflict resolution for concurrent offline edits (Moussa's transfer vs Fatou's stock view).

### Journey Requirements Summary

| Capability Area | Revealed By Journeys | Priority |
|:---|:---|:---|
| **Offline-first engine** | J1, J5 | MVP - Core |
| **Weight-based sales + FCFA rounding** | J1 | MVP |
| **Cash session management** (open/close/variance) | J1, J3 | MVP |
| **Stock transfer chain** (send/receive/variance tracking) | J1, J2, J3 | MVP |
| **Loss declaration** with motif | J1, J3 | MVP |
| **Role-based access** (sell vs manage vs own) | J1, J2, J3 | MVP |
| **Multi-location inventory** (warehouse vs shelf) | J3 | MVP |
| **Supplier order + reception matching** | J2, J3 | MVP |
| **Restock request workflow** | J1, J3 | MVP |
| **Vertical module activation** | J4 | MVP (architecture) |
| **Tenant provisioning + role config** | J4 | MVP (admin) |
| **Offline credit tracking** | J5 | MVP |
| **Conflict resolution** (concurrent offline edits) | J5 | MVP |
| **Sync status indicator** | J5 | MVP |
| **WhatsApp evening summary** | J2 | Growth (Priority #1) |
| **Remote dashboard** (owner mobile) | J2 | Growth |
| **CSV catalog import** | J4 | Growth |
| **Historical pattern analysis** (loss detection) | J2 | Vision |

## Domain-Specific Requirements

### Fiscal & Regulatory Compliance

**Facturation Electronique Certifiee (FEC) — Burkina Faso (obligatoire 2026)**
- Logiciel de caisse certifie avec connexion API vers le systeme DGI pour tracabilite temps reel des transactions
- Recus electroniques avec numerotation sequentielle, inalterable et garantie d'unicite
- En mode offline : generation locale des factures avec numerotation sequentielle pre-allouee, transmission au DGI a la synchronisation
- TVA multi-taux : 18% (normal), 10% (reduit), exonerations. Taux configurable par produit/categorie
- Architecture du moteur fiscal : configurable par pays/juridiction, pas code en dur pour un pays specifique
- Anticipation : chaque pays UEMOA/CEMAC aura ses propres regles fiscales — le moteur doit supporter des plugins fiscaux par juridiction

**Implication architecturale critique :** Le moteur fiscal doit etre un module **Shared** (pas vertical) car toute transaction dans tout vertical est soumise a la fiscalite. Il doit supporter :
- Pre-allocation de plages de numeros de facture pour le mode offline
- File d'attente specifique DGI dans le sync engine (separee de la sync generale)
- Signature/hashage des factures pour garantir l'inalteration

### Currency & Pricing Engine

| Constraint | Implementation |
|:---|:---|
| **Multi-currency support** | Chaque tenant configure sa devise. MVP : XOF. Architecture prete pour XAF, EUR, USD |
| **Rounding rules per currency** | XOF : arrondi a 5 FCFA. EUR : arrondi a 0.01. Configurable par devise, pas par code |
| **Price authority** | Seul le proprietaire peut modifier les prix — contrainte anti-fraude metier |
| **Weight-based pricing** | Prix/kg avec calcul au gramme, arrondi final selon devise |

### Infrastructure Resilience

**Power Failure Recovery (Crash Recovery)**
- Write-ahead logging (WAL) sur la base locale pour garantir zero corruption en cas d'arret brutal
- Transaction en cours sauvegardee incrementalement — redemarrage reprend la transaction ou la marque comme abandonnee
- Critique sur PC Windows (pas de batterie tampon). Moins critique sur tablette Android (batterie)
- Le systeme doit demarrer en etat coherent apres un kill -9 ou une coupure secteur

**Low-Bandwidth Sync (2G/3G)**
- Compression des payloads de synchronisation
- Sync incrementale (delta only) — jamais de full sync apres initialisation
- Retry intelligent avec exponential backoff sur connexions instables
- Pas de sync d'images/fichiers lourds — uniquement donnees transactionnelles
- Objectif : une journee complete de 127 transactions doit syncer en < 30s meme sur 3G

**Device Constraints (Low-End Tablets)**
- Specification minimum : 1-2 Go RAM, stockage limite
- Base locale legere : catalogue, stock actuel, clients, transactions des 30 derniers jours
- Historique complet cote serveur uniquement, accessible via dashboard en ligne
- Politique de purge locale configurable (30-90 jours)

### Data Sovereignty

| Constraint | Current State | Target |
|:---|:---|:---|
| **Hosting** | Supabase self-hosted (local) | Maintenu pour MVP. Option region (Afrique Ouest / Europe) pour Cloud futur |
| **Data residency** | Donnees sur le territoire | Garanti par self-hosting. Documenter pour conformite client |
| **Local DB** | Isar sur device | Donnees operationnelles uniquement, pas d'export non autorise |

### Trust & Anti-Fraud Patterns

**Chain of Custody (pattern metier africain)**
- Double validation a chaque transfert : emetteur declare la quantite sortie, recepteur confirme la quantite recue. L'ecart est automatiquement trace et attribue
- Separation stricte des roles : qui vend ne recoit pas, qui recoit ne vend pas, qui possede ne touche pas la caisse
- Prix verrouilles par le proprietaire — commerciaux ne peuvent pas modifier les prix

**Cash Session Accountability**
- Arret de caisse quotidien obligatoire avec confrontation (theorique vs reel)
- Ecarts > seuil configurable declenchent une alerte au gestionnaire/proprietaire
- Explication obligatoire pour tout ecart avant cloture

**Audit Trail**
- Chaque action tracee : acteur, action, timestamp, donnees avant/apres
- Conservation illimitee cote serveur (pas de suppression automatique)
- Conservation locale : 30-90 jours (configurable) pour performance device
- Historique complet accessible via dashboard en ligne

### Domain Risk Mitigations

| Risk | Impact | Mitigation |
|:---|:---|:---|
| **Facture offline non transmise au DGI** | Non-conformite fiscale, amende | File DGI dediee avec retry agressif, alerte admin si factures en attente > 24h |
| **Numerotation sequentielle cassee offline** | Facture invalide | Pre-allocation de plages de numeros par terminal, avec reserve suffisante pour une semaine offline |
| **Corruption base locale (coupure courant)** | Perte de transactions | WAL + checksum verification au demarrage + transaction recovery |
| **Ecarts de stock non declares** | Pertes financieres non tracees | Ecarts automatiquement calcules a chaque transfert, rapport obligatoire avant cloture |
| **Commercial qui modifie les prix** | Fraude | Prix en lecture seule pour role commercial, modification reservee au proprietaire |
| **Donnees sensibles sur device perdu/vole** | Fuite de donnees client | Chiffrement de la base locale, wipe a distance possible, session timeout automatique |

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. Offline-First ERP Architecture**
Existing ERPs treat offline as a degraded mode. Scalario inverts this: offline is the primary operating mode, online is the bonus. This is not a feature flag — it's a fundamental architectural decision that shapes every module. The sync engine, conflict resolution, and local-first data model are core infrastructure, not bolt-on capabilities. No major ERP competitor (SAP, Odoo, Zoho) has achieved true offline-first at the architectural level.

**2. Chain-of-Custody Trust Pattern**
The double-validation stock transfer system (emitter declares quantity out, receiver confirms quantity in, delta automatically attributed) is a domain innovation born from African commercial reality. In markets where surveillance cameras and automated warehouse systems don't exist, trust is engineered through process segmentation. Each actor is accountable for their link in the chain. This pattern is transferable to any supply chain context where physical verification matters more than digital tracking.

**3. Business-First Modular Architecture**
The three-tier kernel/shared/vertical architecture with polymorphic shared entities is architecturally novel for the ERP space. The `itemType` discriminator pattern (physical | bookable | service) on shared entities allows radically different verticals to share 60-80% of infrastructure without compromise. This contrasts with Odoo's monolithic module system where modules are tightly coupled through a shared ORM.

**4. Fiscal Compliance in Offline Context**
The pre-allocated invoice number ranges for offline FEC compliance is a novel solution to a real regulatory problem. No existing solution addresses how to maintain fiscal sequential numbering across multiple terminals operating offline simultaneously. The dedicated DGI sync queue (separate from general sync) ensures regulatory compliance even in degraded network conditions.

### Market Context & Competitive Landscape

| Competitor | Offline Support | Multi-Vertical | African Market Focus | Trust Patterns |
|:---|:---|:---|:---|:---|
| **SAP Business One** | None | Yes (heavy config) | Minimal | None |
| **Odoo** | Partial (POS only, limited) | Yes (monolithic modules) | Some partners | None |
| **Zoho** | Partial (mobile only) | Yes | Minimal | None |
| **Wave (local)** | None | Accounting only | Yes | None |
| **Scalario** | Full (architecture-level) | Yes (polymorphic shared) | Core design principle | Chain-of-custody built-in |

Scalario's competitive moat is the combination of all four innovations — no competitor addresses even two of them simultaneously.

### Validation Approach

| Innovation | Validation Method | Timeline |
|:---|:---|:---|
| **Offline-first** | The Offline Test: 8-hour shift, 127 transactions, < 30s sync | MVP |
| **Chain-of-custody** | Deploy at Blandine's: measure loss reduction over 30 days | MVP + 30 days |
| **Polymorphic shared** | The Vertical Test: pharmacy vertical in < 4 weeks, zero kernel changes | Post-MVP |
| **Offline fiscal compliance** | Pre-allocated number ranges, DGI sync queue, audit by regulator | MVP (Burkina compliance) |

### Risk Mitigation

| Innovation Risk | Fallback |
|:---|:---|
| **Offline conflict resolution too complex** | Last-write-wins for non-critical data, manual resolution queue for financial data |
| **Polymorphic entities create performance issues** | Denormalize hot paths (product grid) while keeping normalized shared base |
| **FEC offline numbering creates gaps** | Pre-allocate generous ranges, document gap policy for DGI audit |
| **Chain-of-custody too rigid for small shops** | Make double-validation optional per tenant config — small shops can skip it |

## SaaS B2B Specific Requirements

### Multi-Tenancy Model

| Aspect | Implementation |
|:---|:---|
| **Isolation model** | Logical isolation via `tenant_id` on all entities + Supabase RLS as safety net |
| **Tenant provisioning** | Manual by admin (MVP). Self-service registration post-MVP |
| **Tenant configuration** | Currency, timezone, fiscal jurisdiction, active modules, active vertical |
| **Data isolation guarantee** | Every query scoped by `tenant_id`. RLS policies enforce at DB level. No cross-tenant data leakage possible |
| **Tenant lifecycle** | Create, activate, suspend, archive. No hard delete (audit trail preservation) |

### RBAC Permission Matrix

**MVP: Fixed roles with predefined permissions per vertical**

| Permission | Owner | Manager | Commercial |
|:---|:---|:---|:---|
| **View dashboard & reports** | Full | Own location | Own session |
| **Modify prices** | Yes | No | No |
| **Add/edit products** | Yes | No | No |
| **Create supplier orders** | Yes | No | No |
| **Receive supplier deliveries** | No | Yes | No |
| **Create stock transfers** | No | Yes | No |
| **Confirm transfer reception** | No | No | Yes |
| **Open/close cash session** | No | No | Yes |
| **Process sales** | No | No | Yes |
| **Declare losses** | No | Yes | Yes |
| **Restock request** | No | No | Yes |
| **Partial inventory count** | No | Yes | No |
| **Consolidate daily reports** | No | Yes | No |
| **Manage users & roles** | Yes | No | No |
| **Configure modules** | Yes (via admin) | No | No |

**Architecture: Granular RBAC ready for future delegation**
- Permission table: `Permission(id, code, module, description)`
- Role-permission mapping: `RolePermission(roleId, permissionId)`
- MVP: Roles are seeded per vertical with fixed permissions, no UI for customization
- Future: Owner can delegate specific permissions to manager via UI

### Module Registry & Activation

| Aspect | Implementation |
|:---|:---|
| **Module registry** | Kernel maintains a registry of available modules (shared + vertical) |
| **Per-tenant activation** | `TenantModule(tenantId, moduleId, activatedAt, status)` |
| **Module dependencies** | Vertical modules declare dependencies on shared modules (e.g., Retail POS requires Catalog, Transactions, Inventory, Payments) |
| **Activation flow (MVP)** | Admin activates modules manually per tenant |
| **Activation flow (Future)** | Self-service: tenant selects modules, billing adjusts automatically |
| **Module isolation** | Activating/deactivating a module for one tenant has zero impact on other tenants |

### Integration Architecture

**MVP: Single integration — DGI Fiscal API**
- FEC-compliant invoice transmission to DGI
- Dedicated sync queue separate from general data sync
- Retry with alerting for failed transmissions

**Roadmap integrations (prioritized):**

| Priority | Integration | Purpose | Timeline |
|:---|:---|:---|:---|
| 1 | **DGI Fiscal API** | FEC compliance — mandatory | MVP |
| 2 | **WhatsApp Business API** | Evening summary to owners | Growth (#1) |
| 3 | **Orange Money / Moov Money API** | Automatic payment verification | Growth |
| 4 | **OHADA accounting export** | Standard accounting format for West Africa | Growth |
| 5 | **Accounting software bridge** | SAGE, QuickBooks integration | Vision |
| 6 | **Open API** | Third-party integrations | Vision |

**Current mobile money handling (MVP):**
- Commercial records "mobile money" as payment method manually
- No API verification — trust-based (client shows confirmation screen)
- Future: API integration verifies payment automatically before recording sale

### Subscription & Billing

| Aspect | MVP | Post-MVP |
|:---|:---|:---|
| **Tenant creation** | Manual by admin | Self-service registration |
| **Module activation** | Manual by admin | Self-service with billing |
| **Billing** | Manual (invoicing outside Scalario) | Integrated billing per tenant |
| **Pricing model** | Not enforced in system | Tiered: base + per-user + per-module |
| **Free tier** | Admin discretion | Configured in system |

### Implementation Considerations

**Cross-cutting concerns for SaaS B2B:**
- All API endpoints must validate `tenant_id` scope — no endpoint should return data without tenant context
- Supabase RLS acts as defense-in-depth — even if application logic has a bug, RLS prevents cross-tenant leakage
- Module activation must be checked at the API level — disabled modules should return 403, not just hide UI elements
- Audit trail must capture tenant context for every mutation
- The sync engine must scope all sync operations to the authenticated tenant

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**Approach: Incremental Platform Restructuring**

Single developer, 3 active clients who must never be blocked. Each extraction step must be independently deployable and backward-compatible.

**Core principle: Same functionality, new architecture.** No new features during restructuring — if a bug appears, the cause is unambiguous (refactoring, not new logic). Single exception: FCFA 5-franc rounding is integrated into the Payments module at creation time (trivial, foundational).

**Extraction sequence:**
1. **Kernel** — Auth, tenancy, RBAC, event bus, sync engine
2. **Shared modules** (one by one) — Catalog, Transactions, Inventory, Payments
3. **Vertical wrapper** — Existing POS becomes the Retail vertical consuming shared modules

Each step validates before the next begins. Clients stay operational throughout.

**Resource requirements:** 1 full-stack developer (Carlos), self-hosted Supabase infrastructure already in place.

### MVP Feature Set (Phase 1: Restructuring)

**Core User Journeys Supported:**
- Journey 1 (Fatou — daily POS operations): Fully preserved, identical UX
- Journey 3 (Moussa — warehouse operations): Fully preserved
- Journey 5 (Fatou — offline crisis): Fully preserved, sync engine re-architected but same behavior

**Must-Have Capabilities (restructuring only):**

| Capability | Source | Restructuring Scope |
|:---|:---|:---|
| **Kernel: Auth + tenancy** | Existing | Extract from monolith, add `tenant_id` scoping + RLS |
| **Kernel: RBAC** | Existing (partial) | Extract, formalize fixed roles (Owner/Manager/Commercial) |
| **Kernel: Sync engine** | Existing | Extract, make module-agnostic with per-module sync adapters |
| **Kernel: Event bus** | New (architecture) | Internal event system for cross-module communication |
| **Kernel: Module registry** | New (architecture) | `TenantModule` activation table, dependency declarations |
| **Shared: Catalog** | Existing Product/Category | Decompose into base CatalogItem + `itemType` discriminator, extract RetailProduct extension |
| **Shared: Transactions** | Existing Order | Decompose into base Transaction + lifecycle states, extract RetailSale extension |
| **Shared: Inventory** | Existing StockMovement | Extract as shared module, preserve chain-of-custody logic |
| **Shared: Payments** | Existing (partial) | Extract payment processing, integrate FCFA 5-franc rounding |
| **Shared: Contacts** | Existing Customer | Extract as shared base entity |
| **Vertical: Retail POS** | Existing POS | Wrap as vertical consuming shared modules, preserve all UX |
| **Prisma multi-schema** | Existing (public) | Decompose into `kernel`, `shared`, `retail` schemas |
| **Data migration** | N/A | Migrate 3 clients with zero data loss, 1-2 day maintenance window |

**Explicitly NOT in restructuring MVP:**
- Restock request workflow (new feature)
- Weight-based sales (new feature)
- WhatsApp evening summary
- FEC/DGI integration (post-restructuring)
- Supplier order management
- Multi-branch support
- Any new UI screens

### Post-MVP Features

**Phase 2a: Immediate post-restructuring features (new architecture validates)**

| Feature | Priority | Rationale |
|:---|:---|:---|
| **FCFA weight-based sales** | #1 | Daily need for Blandine's grocery, validates Catalog extension pattern |
| **Restock request workflow** | #2 | Daily operational need for commercials, validates cross-module events |
| **FEC/DGI fiscal integration** | #3 | Regulatory compliance, validates dedicated sync queue architecture |
| **WhatsApp evening summary** | #4 | Primary retention hook for owners, first external API integration |

**Phase 2b: Growth features**

| Feature | Priority | Rationale |
|:---|:---|:---|
| **Spoilage rate tracking** (taux de frotte) | Medium | Loss pattern analysis for perishable goods |
| **Bottle deposit system** (consignes) | Medium | Common in beverage retail |
| **Remote dashboard** (owner mobile) | High | Blandine's primary interface |
| **CSV catalog import** | Medium | Onboarding acceleration |
| **Orange Money / Moov Money API** | Medium | Payment verification automation |
| **OHADA accounting export** | Low | Accounting compliance |
| **Multi-branch support** | Low | Cross-branch transfers, consolidated reporting |

**Phase 3: Expansion**

| Feature | Rationale |
|:---|:---|
| **Second vertical** (Pharmacy or Services) | Architecture validation — must ship in 2-4 weeks |
| **Subscription & billing integration** | Self-service tenant management |
| **Advanced reporting dashboards** | Configurable widgets, trend analysis |
| **AI inventory predictions** | Reorder suggestions based on sales patterns |
| **Open API** | Third-party integrations |
| **Multi-currency beyond FCFA** | International expansion |

### Risk Mitigation Strategy

**Technical Risks:**

| Risk | Mitigation |
|:---|:---|
| **Incremental extraction breaks existing functionality** | Each extraction step has full regression testing against current behavior before deployment. Clients never see broken features |
| **Prisma multi-schema migration corrupts data** | Dry-run migration on cloned database first. Rollback script prepared for each step |
| **Sync engine refactoring causes data loss** | Keep existing sync running in parallel during transition. Shadow-mode validation before cutover |
| **Polymorphic entity decomposition creates performance regressions** | Benchmark product grid and transaction queries before/after. Denormalize hot paths if needed |
| **Module boundaries wrong — discovered during pharmacy vertical** | Accept and refactor. Incremental approach means boundaries are validated step by step, not all at once |

**Market Risks:**

| Risk | Mitigation |
|:---|:---|
| **3 existing clients frustrated during restructuring** | Zero downtime for daily operations. 1-2 day maintenance window with advance notice only for final migration |
| **New client acquisition paused during restructuring** | Acceptable — quality over quantity. Focus on architecture stability |
| **Restructuring takes longer than expected** | Each step is independently valuable — even partial restructuring improves codebase. No all-or-nothing dependency |

**Resource Risks:**

| Risk | Mitigation |
|:---|:---|
| **Solo developer — bus factor = 1** | Clean architecture + comprehensive PRD + architecture docs = onboarding material for future developers |
| **Scope creep during restructuring** | Strict "same functionality, new architecture" rule. New features queue in Phase 2a, never mixed with restructuring |
| **Burnout / timeline pressure** | Incremental approach allows pauses. Each step is deployable — no pressure to finish everything before shipping |

## Functional Requirements

### Identity & Access Management

- FR1: System administrator can create and configure a new tenant with currency, timezone, and fiscal jurisdiction
- FR2: Tenant owner can create user accounts and assign roles (Owner, Manager, Commercial)
- FR3: System enforces role-based permissions — each role has predefined access boundaries per vertical
- FR4: Users can authenticate via credentials and receive a session scoped to their tenant
- FR5: System automatically enforces tenant isolation — no user can access data outside their tenant context
- FR6: System terminates idle sessions after a configurable timeout period

### Module & Vertical Management

- FR7: System administrator can activate or deactivate shared modules and vertical modules per tenant
- FR8: Vertical modules declare dependencies on shared modules — activation validates all dependencies are met
- FR9: Deactivating a module for one tenant has zero impact on other tenants
- FR10: Each tenant can have exactly one active vertical module at a time (MVP)

### Catalog Management

- FR11: Owner can create, edit, and deactivate catalog items with name, price, category, and barcode
- FR12: Catalog items support a type discriminator (physical, bookable, service) at the shared level
- FR13: Vertical modules can extend base catalog items with vertical-specific fields (e.g., RetailProduct adds stockQuantity, weightUnit)
- FR14: Owner can create and manage product categories
- FR15: Catalog data is available offline on the local device for all assigned users

### Transaction Processing

- FR16: Commercial can create a sales transaction by selecting catalog items and quantities
- FR17: Commercial can apply a payment method to a transaction (cash, mobile money)
- FR18: System calculates transaction totals with currency-specific rounding rules (FCFA: 5-franc rounding)
- FR19: System records change due for cash payments
- FR20: Transactions support lifecycle states at the shared level (instant, accumulating, scheduled)
- FR21: Vertical modules can extend base transactions with vertical-specific fields (e.g., RetailSale adds sessionId, receiptNumber)
- FR22: All transactions are written locally first and queued for synchronization

### Cash Session Management

- FR23: Commercial can open a cash session by declaring the starting cash float
- FR24: All sales during an active session are associated with that session
- FR25: Commercial can close a cash session by declaring the counted cash amount
- FR26: System calculates and displays the variance between theoretical and declared cash amounts
- FR27: Commercial must provide an explanation for any cash variance before session closure
- FR28: Manager can view session closure reports for all commercials in their location

### Inventory & Stock Management

- FR29: Manager can receive supplier deliveries and record received quantities against expected quantities
- FR30: System tracks reception variances (received vs expected) with observer notes
- FR31: Manager can create stock transfers from warehouse to shelf locations with declared quantities
- FR32: Commercial can confirm transfer reception and declare actually received quantity
- FR33: System automatically tracks and attributes transfer variances (sent vs received)
- FR34: Commercial can declare stock losses with a mandatory motif (spoilage, damage, etc.)
- FR35: Manager can perform partial inventory counts and the system signals variances against theoretical stock
- FR36: Inventory data is maintained locally for offline operation

### Contact Management

- FR37: Users can create and manage customer profiles (name, phone, type)
- FR38: Commercial can associate a transaction with a customer profile
- FR39: Commercial can record a credit sale against a customer profile, updating their outstanding balance
- FR40: Customer profiles and balances are available offline

### Synchronization & Offline Operations

- FR41: All create, read, update operations function identically whether online or offline
- FR42: System queues all local mutations in an outbox for automatic synchronization when connectivity returns
- FR43: Sync engine transmits only delta changes (incremental sync), never full dataset after initialization
- FR44: System resolves conflicts for concurrent offline edits (last-write-wins for non-critical data, manual resolution queue for financial data)
- FR45: System displays a subtle, non-blocking connectivity status indicator
- FR46: System recovers to a consistent state after unexpected termination (power failure, crash) with zero data loss
- FR47: Local database retains operational data for a configurable retention period (30-90 days)

### Reporting & Accountability

- FR48: Manager can generate a daily consolidation report covering sales, losses, variances, and transfers across all sessions
- FR49: Owner can view dashboard reports on revenue, sale count, losses, cash variances, and critical stock levels
- FR50: System maintains an immutable audit trail of all mutations (actor, action, timestamp, before/after data)
- FR51: Audit trail is retained indefinitely server-side and for the configured retention period locally

### Data Migration & Architecture

- FR52: System supports migration of existing client data from monolithic schema to multi-schema architecture with zero data loss
- FR53: Prisma schema operates across kernel, shared, and retail schemas with referential integrity
- FR54: Sync engine operates module-agnostically with per-module sync adapters

## Non-Functional Requirements

### Performance

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR1: Product grid rendering** | < 500ms for up to 2,000 catalog items | Commercial needs instant product search during sales rush |
| **NFR2: Transaction recording** | < 200ms local write | Must feel instantaneous even on low-end devices |
| **NFR3: Full-day sync** | < 30 seconds for 150+ transactions | Sync must not block operations on reconnection |
| **NFR4: App cold start** | < 3 seconds to usable state | Power failure recovery — cashier needs to resume fast |
| **NFR5: Session closure report** | < 2 seconds generation | End-of-day report must not delay commercial departure |
| **NFR6: Device memory footprint** | < 150MB RAM steady state | Low-end Android tablets with 1-2GB RAM |
| **NFR7: Local database size** | < 500MB for 90 days of operational data | Limited storage on low-end devices |

### Security

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR8: Tenant data isolation** | Zero cross-tenant data leakage | Application-level `tenant_id` scoping + Supabase RLS defense-in-depth |
| **NFR9: Authentication** | JWT-based with configurable session timeout | Supabase Auth, session auto-expire on idle |
| **NFR10: Local data encryption** | Encrypted local database | Device loss/theft protection — no readable data without authentication |
| **NFR11: Transport encryption** | TLS 1.2+ for all server communication | Data in transit protection |
| **NFR12: Price modification audit** | Every price change traced with actor, timestamp, before/after values | Anti-fraud: only Owner can modify, full trail |
| **NFR13: Financial data integrity** | All financial mutations are atomic and logged | No partial transaction states, no silent failures |

### Reliability & Availability

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR14: Offline autonomy** | 8+ hours continuous operation without connectivity | Full work shift without internet |
| **NFR15: Crash recovery** | Zero data loss on unexpected termination | WAL on local DB, in-progress transaction saved incrementally |
| **NFR16: Sync resilience** | Automatic retry with exponential backoff on failures | Unstable 2G/3G connections, no manual intervention |
| **NFR17: Server uptime** | 99% (allows ~7h downtime/month) | Self-hosted Supabase, solo admin — realistic target |
| **NFR18: Data durability** | Zero transaction loss, ever | Financial data: no acceptable loss threshold |

### Scalability

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR19: Tenant capacity** | Support 30+ concurrent tenants | 12-month growth target |
| **NFR20: Users per tenant** | Up to 10 concurrent users per tenant | Typical shop: 1 owner + 1 manager + 3-5 commercials |
| **NFR21: Transaction volume** | Up to 500 transactions/day per tenant | High-traffic retail shops |
| **NFR22: Catalog size** | Up to 5,000 items per tenant | Grocery/pharmacy typical range |
| **NFR23: Horizontal growth** | Adding tenants requires zero code changes | New tenant = configuration only |

### Network & Bandwidth

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR24: Sync payload compression** | Compressed delta-only payloads | 2G/3G bandwidth optimization |
| **NFR25: Minimum bandwidth** | Functional sync on 2G (50 kbps) | Rural Africa connectivity reality |
| **NFR26: No heavy asset sync** | Images and files excluded from sync — data only | Bandwidth preservation |
| **NFR27: Initial provisioning** | Full catalog + config download < 5MB | First-time device setup on limited connectivity |

### Usability

| Requirement | Target | Context |
|:---|:---|:---|
| **NFR28: Cashier onboarding** | Autonomous after < 1 hour training | Non-technical users with no prior ERP experience |
| **NFR29: Error recovery** | Clear, actionable error messages in user's language | No technical jargon, no stack traces |
| **NFR30: Offline transparency** | User unaware of connectivity state during normal operations | Offline is the default, not the exception |
