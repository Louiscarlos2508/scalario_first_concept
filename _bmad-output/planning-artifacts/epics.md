---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - docs/architecture-scalario-2026-03-08.md
---

# Scalario - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Scalario, decomposing the requirements from the PRD and Architecture into implementable stories for the incremental restructuring of the existing monolithic POS into a modular kernel/shared/vertical architecture.

## Requirements Inventory

### Functional Requirements

FR1: System administrator can create and configure a new tenant with currency, timezone, and fiscal jurisdiction
FR2: Tenant owner can create user accounts and assign roles (Owner, Manager, Commercial)
FR3: System enforces role-based permissions — each role has predefined access boundaries per vertical
FR4: Users can authenticate via credentials and receive a session scoped to their tenant
FR5: System automatically enforces tenant isolation — no user can access data outside their tenant context
FR6: System terminates idle sessions after a configurable timeout period
FR7: System administrator can activate or deactivate shared modules and vertical modules per tenant
FR8: Vertical modules declare dependencies on shared modules — activation validates all dependencies are met
FR9: Deactivating a module for one tenant has zero impact on other tenants
FR10: Each tenant can have exactly one active vertical module at a time (MVP)
FR11: Owner can create, edit, and deactivate catalog items with name, price, category, and barcode
FR12: Catalog items support a type discriminator (physical, bookable, service) at the shared level
FR13: Vertical modules can extend base catalog items with vertical-specific fields (e.g., RetailProduct adds stockQuantity, weightUnit)
FR14: Owner can create and manage product categories
FR15: Catalog data is available offline on the local device for all assigned users
FR16: Commercial can create a sales transaction by selecting catalog items and quantities
FR17: Commercial can apply a payment method to a transaction (cash, mobile money)
FR18: System calculates transaction totals with currency-specific rounding rules (FCFA: 5-franc rounding)
FR19: System records change due for cash payments
FR20: Transactions support lifecycle states at the shared level (instant, accumulating, scheduled)
FR21: Vertical modules can extend base transactions with vertical-specific fields (e.g., RetailSale adds sessionId, receiptNumber)
FR22: All transactions are written locally first and queued for synchronization
FR23: Commercial can open a cash session by declaring the starting cash float
FR24: All sales during an active session are associated with that session
FR25: Commercial can close a cash session by declaring the counted cash amount
FR26: System calculates and displays the variance between theoretical and declared cash amounts
FR27: Commercial must provide an explanation for any cash variance before session closure
FR28: Manager can view session closure reports for all commercials in their location
FR29: Manager can receive supplier deliveries and record received quantities against expected quantities
FR30: System tracks reception variances (received vs expected) with observer notes
FR31: Manager can create stock transfers from warehouse to shelf locations with declared quantities
FR32: Commercial can confirm transfer reception and declare actually received quantity
FR33: System automatically tracks and attributes transfer variances (sent vs received)
FR34: Commercial can declare stock losses with a mandatory motif (spoilage, damage, etc.)
FR35: Manager can perform partial inventory counts and the system signals variances against theoretical stock
FR36: Inventory data is maintained locally for offline operation
FR37: Users can create and manage customer profiles (name, phone, type)
FR38: Commercial can associate a transaction with a customer profile
FR39: Commercial can record a credit sale against a customer profile, updating their outstanding balance
FR40: Customer profiles and balances are available offline
FR41: All create, read, update operations function identically whether online or offline
FR42: System queues all local mutations in an outbox for automatic synchronization when connectivity returns
FR43: Sync engine transmits only delta changes (incremental sync), never full dataset after initialization
FR44: System resolves conflicts for concurrent offline edits (last-write-wins for non-critical data, manual resolution queue for financial data)
FR45: System displays a subtle, non-blocking connectivity status indicator
FR46: System recovers to a consistent state after unexpected termination (power failure, crash) with zero data loss
FR47: Local database retains operational data for a configurable retention period (30-90 days)
FR48: Manager can generate a daily consolidation report covering sales, losses, variances, and transfers across all sessions
FR49: Owner can view dashboard reports on revenue, sale count, losses, cash variances, and critical stock levels
FR50: System maintains an immutable audit trail of all mutations (actor, action, timestamp, before/after data)
FR51: Audit trail is retained indefinitely server-side and for the configured retention period locally
FR52: System supports migration of existing client data from monolithic schema to multi-schema architecture with zero data loss
FR53: Prisma schema operates across kernel, shared, and retail schemas with referential integrity
FR54: Sync engine operates module-agnostically with per-module sync adapters
FR76: Owner configures a unitType per article (unit/weight/volume/length); tenant defines native unit label per type (e.g. kg, L, m). Default = unit. Configurable from product form without deployment.
FR77: For articles with unitType ≠ unit, POS shows a floating-point quantity input with native unit label. Total = pricePerUnit × quantity, rounded per tenant currency rule (XOF: nearest 5 FCFA). Transaction records exact quantity and native unit.
FR78: Owner can define per article: sale unit label (free text), price per unit, and optional conversionRate to stock unit (e.g. 1 sachet 500g = 0.5 stock unit). conversionRate is applied to stock decrement on each sale.
FR79: Owner or authorized manager can create a purchase order: select supplier contact, add items with expected quantities, set expected delivery date and optional notes. Status lifecycle: draft → confirmed → partially_received → received → cancelled. POs are listable and filterable by status, supplier, and period.
FR80: On delivery reception, manager links reception to existing PO (optional). System records received quantity per line, calculates variance (received − expected), and accepts free-text quality notes per line. Variances and notes are traced in audit trail and visible in reception reports. Reception without linked PO remains possible.
FR83: Owner can define repackaging rules per (source article, target article) pair: source unit (e.g. 5 kg bag), target unit (e.g. 100 g sachet), conversion factor (e.g. 50 sachets per bag). At POS, selling a child article automatically decrements the parent article's stock by quantity × conversionRate. Partial operations are allowed. The operation generates a traceable REPACKAGING stock movement in the audit trail.
FR84: Owner configures per article: (a) a freshness window in days (expiryDays) — expiry date calculated automatically as reception date + window; (b) a natural shrinkage tolerance % (shrinkageTolerance) representing acceptable weight loss from dehydration or evaporation. Weight losses within tolerance are classified as natural variance, not losses. Either field can be null (feature inactive for that article).
FR85: Articles with a configured freshness window display a color indicator in POS grid and stock views: Green (> 50% of window remaining), Orange (20–50% remaining), Red (< 20% remaining or expired). Both color thresholds are configurable per tenant. Orange/Red articles are sorted first in the POS grid. A filter "Articles urgents" shows only Orange/Red articles.
FR89: Catalog articles support tenant-configurable variant attributes (size, color, material — free labels). Each variant has its own SKU, optional barcode, independent price and stock. Parent article aggregates total variant stock for reporting. At POS, cashier selects article then variant before adding to cart. Articles without variants work exactly as today. (Phase 2b)
FR90: Articles support multiple tenant-configurable price levels (e.g. retail, wholesale, loyalty, promotional — labels free). Applied price determined automatically by contactType of associated customer OR by ordered quantity threshold (both tenant-configurable). A cashier with price_override permission can force a level manually. Receipt shows applied price level. (Phase 2b)
FR91: Owner creates promotion rules: (a) % discount on article or full category, (b) quantity offer (buy N get M — threshold + free article configurable), (c) temporary crossed-out price. Each promotion has start/end dates and active/inactive status. Active promotions apply automatically at POS when eligible article added to cart. Receipt shows original crossed-out price + discounted price. Multiple promotions: most-advantageous wins (configurable). (Phase 3)
FR81: Owner or manager can configure a minimum stock level (minStockLevel) per article from the product form. The field is optional; if unset, no alert is generated for that article.
FR82: After any stock movement that decrements stock (sale, loss, transfer_out, adjustment), the system evaluates whether stockQuantity ≤ minStockLevel for each affected article. If so, a low-stock alert is recorded and surfaced in the backoffice (badge on catalog, dedicated alerts screen, KPI on dashboard).
FR86: Owner can enable a daily summary notification per tenant: configure channel (in-app push v1; WhatsApp Phase 2b), delivery time, and on/off switch. When enabled, the system sends a summary each day at the configured time covering: total sales, total revenue, new low-stock alerts count, and pending purchase orders count.

### NonFunctional Requirements

NFR1: Product grid rendering < 500ms for up to 2,000 catalog items
NFR2: Transaction recording < 200ms local write
NFR3: Full-day sync < 30 seconds for 150+ transactions
NFR4: App cold start < 3 seconds to usable state
NFR5: Session closure report < 2 seconds generation
NFR6: Device memory footprint < 150MB RAM steady state
NFR7: Local database size < 500MB for 90 days of operational data
NFR8: Tenant data isolation — zero cross-tenant data leakage (tenant_id + RLS)
NFR9: JWT-based authentication with configurable session timeout
NFR10: Encrypted local database (AES-256)
NFR11: TLS 1.2+ for all server communication
NFR12: Price modification audit — every price change traced with actor, timestamp, before/after values
NFR13: Financial data integrity — all financial mutations atomic and logged
NFR14: Offline autonomy — 8+ hours continuous operation without connectivity
NFR15: Crash recovery — zero data loss on unexpected termination (WAL)
NFR16: Sync resilience — automatic retry with exponential backoff
NFR17: Server uptime — 99%
NFR18: Data durability — zero transaction loss, ever
NFR19: Tenant capacity — support 30+ concurrent tenants
NFR20: Users per tenant — up to 10 concurrent users
NFR21: Transaction volume — up to 500 transactions/day per tenant
NFR22: Catalog size — up to 5,000 items per tenant
NFR23: Horizontal growth — adding tenants requires zero code changes
NFR24: Sync payload compression — compressed delta-only payloads
NFR25: Minimum bandwidth — functional sync on 2G (50 kbps)
NFR26: No heavy asset sync — images/files excluded, data only
NFR27: Initial provisioning — full catalog + config download < 5MB
NFR28: Cashier onboarding — autonomous after < 1 hour training
NFR29: Error recovery — clear, actionable error messages in user's language
NFR30: Offline transparency — user unaware of connectivity state during normal operations

### Additional Requirements

From Architecture:
- Brownfield restructuring — no starter template, incremental extraction from existing monolith
- 9-step incremental migration sequence: Kernel → Catalog → Contacts → Transactions+Payments → Inventory → Retail Vertical → Reporting → Frontend Sync → Cleanup
- Guard chain on every request: AuthGuard → TenantGuard → ModuleGuard → RolesGuard
- Event Bus: NestJS EventEmitter2 for cross-module communication (TransactionCreated, StockAdjusted, SessionClosed)
- Module registration pattern: NestJS DynamicModule per shared/vertical module
- RLS defense-in-depth: Prisma middleware sets SET LOCAL app.current_tenant_id per request
- Base + Extension Table pattern: CatalogItem → RetailProduct, Transaction → RetailSale (not STI)
- Isar local models remain denormalized — API joins across schemas, returns flat objects
- Sync protocol: UUID-based idempotent push, ?since= delta pull, Supabase Realtime push
- Backward-compatible migration: old endpoints proxy to new services during transition
- CI/CD: GitHub Actions (lint → test → migrate → build → deploy staging → manual prod promotion)
- Testing priorities: tenant isolation, sync idempotency, FCFA rounding, session variance, offline→online transition
- Target project structure: kernel/, shared/, retail/ directories in backend src/
- Prisma multi-schema with previewFeatures: ["driverAdapters", "multiSchema"]
- Entity mapping: Product→CatalogItem+RetailProduct, Order→Transaction+RetailSale, Customer→Contact, Category stays, PosSession→retail schema, StockMovement→shared schema

### FR Coverage Map

| FR | Epic | Description |
|:---|:---|:---|
| FR1 | Epic 1 | Create/configure tenant |
| FR2 | Epic 1 | Create users, assign roles |
| FR3 | Epic 1 | Enforce role-based permissions |
| FR4 | Epic 1 | Authenticate, scoped session |
| FR5 | Epic 1 | Tenant isolation |
| FR6 | Epic 1 | Session timeout |
| FR7 | Epic 1 | Activate/deactivate modules |
| FR8 | Epic 1 | Module dependency validation |
| FR9 | Epic 1 | Module isolation per tenant |
| FR10 | Epic 1 | One vertical per tenant — Retail (standalone). Multi-vertical allowed in Enterprise mode (FR10 v5) |
| FR11 | Epic 2 | CRUD catalog items |
| FR12 | Epic 2 | itemType discriminator |
| FR13 | Epic 6 + Epic 10 | Vertical extension fields: RetailProduct (Epic 6 static) + UI-Driven Engine dynamic layer (Epic 10) |
| FR14 | Epic 2 | Category management |
| FR15 | Epic 2 | Offline catalog availability |
| FR16 | Epic 4 | Create sales transactions |
| FR17 | Epic 4 | Payment method selection |
| FR18 | Epic 4 | FCFA 5-franc rounding |
| FR19 | Epic 4 | Change due calculation |
| FR20 | Epic 4 | Transaction lifecycle types |
| FR21 | Epic 6 | Vertical transaction extension (RetailSale) |
| FR22 | Epic 4 | Local-first write + sync queue |
| FR23 | Epic 6 | Open cash session |
| FR24 | Epic 6 | Session-scoped transactions |
| FR25 | Epic 6 | Close session with balance |
| FR26 | Epic 6 | Variance display |
| FR27 | Epic 6 | Mandatory variance explanation |
| FR28 | Epic 6 | Manager views session reports |
| FR29 | Epic 5 | Receive supplier deliveries |
| FR30 | Epic 5 | Reception variance tracking |
| FR31 | Epic 5 | Stock transfers |
| FR32 | Epic 5 | Confirm transfer reception |
| FR33 | Epic 5 | Transfer variance auto-tracking |
| FR34 | Epic 5 | Loss declaration with motif |
| FR35 | Epic 5 | Partial inventory counts |
| FR36 | Epic 5 | Offline inventory data |
| FR37 | Epic 3 | Customer CRUD |
| FR38 | Epic 3 | Associate transactions with customers |
| FR39 | Epic 3 | Credit sales, balance tracking |
| FR40 | Epic 3 | Offline customer profiles |
| FR41 | Epic 8 | Identical online/offline operations |
| FR42 | Epic 8 | Outbox queue, auto-sync |
| FR43 | Epic 8 | Delta-only sync |
| FR44 | Epic 8 | Conflict resolution |
| FR45 | Epic 8 | Connectivity status indicator |
| FR46 | Epic 8 | Crash recovery (WAL) |
| FR47 | Epic 8 | Configurable data retention |
| FR48 | Epic 7 | Daily consolidation report |
| FR49 | Epic 7 | Owner dashboard |
| FR50 | Epic 1 | Immutable audit trail |
| FR51 | Epic 1 | Audit retention policy |
| FR52 (DB) | Story 1.6 | tenants: referred_by + network_visible (Connect/Ambassadeurs — DB only) |
| FR53 (DB) | Story 1.6 | contacts: linked_tenant_id (Connect — DB only) |
| FR54 (DB) | Story 1.6 | catalog_items: supplier_reference (Connect — DB only) |
| FR55 (DB) | Story 1.6 | transaction type: transfer_inter_tenant enum value (Connect — DB only) |
| FR56 | Epic 9 | Zero-loss data migration (renumbered from FR52 v1) |
| FR57 | Epic 9 | Multi-schema Prisma (renumbered from FR53 v1) |
| FR58 | Epic 8 | Module-agnostic sync adapters (renumbered from FR54 v1) |
| FR59 (DB) | Story 1.6 | tenants: org_mode + parent_tenant_id (Enterprise — DB only) |
| FR60 (DB) | Story 1.6 | organization_members: department_ids (Enterprise — DB only) |
| FR61 (DB) | Story 1.6 | tenant_modules: department_id (Enterprise — DB only) |
| FR62 | Epic 13 | Inter-department events via event bus (Enterprise Phase 3) |
| FR63–FR68 | Epic 13 | RH & Paie Enterprise: employés, salaires CNSS/CARFO, bulletins (Phase 3) |
| FR69–FR72 | Epic 13 | Comptabilité OHADA: plan comptable, clôture, bilan, FEC (Phase 3) |
| FR73–FR74 | Epic 13 | Import Enterprise CSV + migration Retail → Enterprise (Phase 3) |
| FR75 | Epic 8 | Gestion des Échecs de Sync: cycle de vie outbox complet (Phase 1) |
| FR76 | Epic 20 | unitType configurable par article (unit/weight/volume/length) |
| FR77 | Epic 20 | POS vente au poids — saisie quantité flottante, calcul automatique FCFA |
| FR78 | Epic 20 | Label unité libre + facteur de conversion stock par article |
| FR79 | Epic 21 | Création et gestion des commandes fournisseurs (lifecycle statuts) |
| FR80 | Epic 21 | Réception liée à une commande + variance + notes qualité par article |
| FR81 | Epic 22 | Seuil stock bas configurable par article (minStockLevel) |
| FR82 | Epic 22 | Alerte stock bas déclenchée après mouvement de stock si stock ≤ seuil |
| FR83 | Epic 23 | Reconditionnement vrac → détail : parentItemId + conversionRate, décrémentation stock parent à la vente |
| FR84 | Epic 24 | Fraîcheur configurable par article (expiryDays, shrinkageTolerance) ; date expiration calculée à la réception |
| FR85 | Epic 24 | Indicateur couleur vert/orange/rouge dans grille POS et stock ; seuils tenant-configurables ; tri priorité |
| FR89 | Epic 25 | Variantes configurables par article (attributs libres, SKU, prix et stock indépendants) ; sélection au POS |
| FR90 | Epic 25 | Multi-niveaux de prix tenant-configurables ; résolution automatique par contactType ou quantité |
| FR91 | Epic 25 | Promotions configurables (%, quantitatif, prix barré) ; application auto au POS ; reçu avec prix barré |
| FR86 | Epic 22 | Résumé quotidien automatique — canal et heure configurables par tenant |

## Epic List

### Epic 1: Kernel — Identity, Tenancy & Access Control
After this epic, users authenticate with tenant-scoped sessions, roles are enforced system-wide, modules can be activated per tenant, and every mutation is audit-logged. This is the foundation all other modules depend on.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR10, FR50, FR51

### Epic 2: Shared Catalog Module
Owners can manage products through the new polymorphic catalog (with itemType discriminator), organize by categories, and all catalog data is available offline. Old product endpoints remain backward-compatible.
**FRs covered:** FR11, FR12, FR14, FR15

### Epic 3: Shared Contacts Module
Users can manage customer profiles, track outstanding balances for credit sales, and access contact data offline. Customer → Contact entity migration with contactType support.
**FRs covered:** FR37, FR38, FR39, FR40

### Epic 4: Shared Transactions & Payments Module
Commercials can process sales with proper payment methods (cash, mobile money, credit, split), FCFA 5-franc rounding, change due calculation, and local-first transaction recording. Order → Transaction entity migration with lifecycle types.
**FRs covered:** FR16, FR17, FR18, FR19, FR20, FR22

### Epic 5: Shared Inventory Module
Managers can receive deliveries, create stock transfers, and perform partial inventory counts. Commercials can confirm transfers and declare losses. The chain-of-custody pattern with double-validation and variance tracking is fully operational. All inventory data works offline.
**FRs covered:** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36

### Epic 6: Retail Vertical — POS Sessions & Extensions
The retail POS is wrapped as a vertical module with cash sessions (open/close/variance), session-scoped transactions, RetailProduct extensions (stockQuantity, weightUnit), RetailSale extensions (sessionId, receiptNumber), and parked cart support. Cash accountability with mandatory variance explanation.
**FRs covered:** FR13, FR21, FR23, FR24, FR25, FR26, FR27, FR28

### Epic 7: Reporting & Business Intelligence
Managers can generate daily consolidation reports. Owners can view dashboards with revenue, sale count, losses, cash variances, and critical stock levels. Reports aggregate across sessions and modules.
**FRs covered:** FR48, FR49

### Epic 8: Frontend Sync & Offline Resilience
Frontend repositories updated to new API endpoints, Isar models aligned with new response shapes, full offline-first experience preserved: delta sync, crash recovery (WAL), conflict resolution, outbox queue, connectivity indicator, configurable data retention. Module-agnostic sync adapters. Full sync failure lifecycle: outbox → retry (3x exponential backoff) → FAILED state → admin notification → manual resolution interface.
**FRs covered:** FR41, FR42, FR43, FR44, FR45, FR46, FR47, FR58, FR75

### Epic 9: Data Migration & Client Cutover
All 3 existing clients migrated from monolithic public schema to kernel/shared/retail multi-schema architecture with zero data loss. Old endpoint proxies removed, cleanup completed, full regression validated.
**FRs covered:** FR56, FR57

### Epic 10: Server-Driven UI Infrastructure
The Flutter app gains a JSON-driven layout engine. A single Flutter binary renders any vertical or department UI by reading layout definitions from the server DB. All Retail screens (Epics 2–6) are refactored to use the layout engine — adding a new business type requires only a new JSON layout config, zero Flutter code change. Infrastructure is in place for future verticals (Pharmacy, Restaurant) and Enterprise departments.
**Phase:** 1 (after Epic 6, before Epic 7)
**FRs covered:** FR13 (dynamic UI-Driven Engine layer)
**Prerequisite:** Epics 1–6 complete (all shared modules + Retail vertical operational)

### Epic 15: SDUI Dashboard & UI Polish
The dashboard is wired to the SDUI engine (retail.dashboard.json), real KPI/chart/terminal widgets replace stubs, all POS and backoffice labels are translated to French with FCFA currency, hardcoded colors are replaced by AppTheme tokens, and navigation adapts to screen size (BottomNavigationBar on phone, NavigationRail on tablet) with SafeArea and Fitts-compliant touch targets throughout.
**Phase:** 1b (after Epic 10 done)
**FRs covered:** FR13 (SDUI dashboard), NFR28 (cashier onboarding ≤ 1h — French UI), NFR29 (French error messages)
**Prerequisite:** Epic 10 complete (SduiRenderer + SduiWidgetRegistry operational)

---

### Epic 16: Retail Operations — Gestion Stock Terrain
Les 4 opérations stock terrain de Moussa (gestionnaire) sont désormais accessibles depuis le frontend Flutter : réception livraison fournisseur, transfert magasin → rayon avec double validation chain-of-custody, déclaration de pertes avec motif obligatoire, et inventaire partiel avec signal des écarts. Les 4 écrans sont intégrés dans un hub Inventaire tabbed. Toutes les opérations fonctionnent offline (Isar + outbox).
**Phase:** 1 (après Epic 15 — UI polish complète)
**FRs covered:** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36
**Prerequisite:** Epics 1–9 (backend inventory opérationnel — 288 tests NestJS verts), Epic 15 (DashboardShell + navigation tabbed)

### Epic 11: Programme Ambassadeurs
Existing tenants generate referral codes and refer new businesses to Scalario. The system tracks referrals via referred_by (seeded in Story 1.6), calculates monthly commissions (20% of referred tenant subscription), and triggers Mobile Money payouts automatically. Ambassadeur dashboard shows referred tenants, commission history, and next payout date.
**Phase:** 2b
**FRs covered:** FR52 business logic (DB fields already seeded in Story 1.6), PRD Section 8 — Programme Ambassadeurs
**Prerequisite:** Epics 1–9 complete

### Epic 12: Scalario Connect
Any Scalario tenant can act as Buyer, Seller, or both in a B2B graph. Tenants discover network-visible suppliers (network_visible flag), link supplier contacts (linked_tenant_id), reference supplier catalog items (supplier_reference), and execute inter-tenant transfers (transfer_inter_tenant type). B2B documents (orders, delivery notes, invoices) flow between tenants digitally — replacing WhatsApp/phone/paper coordination.
**Phase:** 3
**FRs covered:** FR52–FR55 Phase 3 business logic (DB structure already seeded in Story 1.6)
**Prerequisite:** Epic 11 (Ambassadeurs network established)

### Epic 21: Commandes fournisseurs + réception liée
Le gestionnaire peut créer des commandes fournisseurs (sélection fournisseur, articles, quantités, date prévue), suivre leur statut (draft → confirmed → partially_received → received → cancelled), et enregistrer la réception liée avec variance automatique et notes qualité par article. Un KPI "Commandes en attente" apparaît sur le dashboard.
**Phase:** 2a
**FRs covered:** FR79, FR80
**Prerequisite:** Epics 1–9, Epic 3 (contacts fournisseurs), Epic 16 (hub inventaire)

---

### Epic 25: Variantes, multi-tarifs & promotions
Les articles du catalogue supportent des variantes tenant-configurables (taille, couleur, matière) avec stock et prix indépendants. Les prix multi-niveaux (détail, gros, fidélité) s'appliquent automatiquement selon le type de client ou la quantité. Des promotions configurables (%, quantitatives, prix barré) s'appliquent automatiquement au POS dès qu'un article éligible est ajouté au panier.
**Phase:** 2b (FR89, FR90) + Phase 3 (FR91)
**FRs covered:** FR89, FR90, FR91
**Prerequisite:** Epics 1–9, Epic 2 (catalog), Epic 4 (transactions + paiements), Epic 3 (contacts + contactType)

---

### Epic 26: Traçabilité Articles & Configurations Métier

Chaque article du catalogue peut être enrichi de configurations métier avancées selon le secteur du tenant : suivi de numéros de série par unité vendue (électronique, hi-fi), durée de garantie avec génération automatique de certificat, exigence d'ordonnance pour la vente (pharmacie), date de garde optimale sur lot (agroalimentaire, cave), prix dynamique avec historique complet (or, carburant), article unique non-réapprovisable avec archivage automatique après vente (dépôt-vente, antiquités). Toutes ces fonctionnalités sont optionnelles et désactivées par défaut.
**Phase:** 2b
**FRs covered:** FR92, FR93, FR94, FR95, FR96, FR97
**Prerequisite:** Epic 2 (catalog), Epic 5 (inventory/stock movements), Epic 16 (réception fournisseur), Epic 24 (fraîcheur/batches), Epic 25 (variants/pricing)

---

### Epic 24: Fraîcheur + code couleur priorité vente
Chaque article peut avoir une fenêtre de fraîcheur en jours et un coefficient de tolérance au rétrécissement. À la réception, une date d'expiration est calculée automatiquement par lot (`ProductBatch`). La grille POS et les vues stock affichent un indicateur couleur vert/orange/rouge selon le pourcentage de fenêtre restant. Les articles orange/rouge sont triés en priorité. Un onglet "Fraîcheur" dans l'`InventoryScreen` permet de déclasser les lots.
**Phase:** 2b
**FRs covered:** FR84, FR85
**Prerequisite:** Epic 21 (réception fournisseur), Epic 5 (mouvements de stock), Epic 22 (alertes stock)

---

### Epic 23: Conversion unités vrac → détail
Un article enfant (ex: sachet 100 g) peut être lié à un article parent vrac (ex: sac 5 kg) via `parentItemId` et un `conversionRate`. À la vente de l'article enfant au POS, le stock du parent est décrémenté automatiquement selon le facteur. L'opération est tracée comme mouvement `REPACKAGING` dans l'audit trail.
**Phase:** 2a
**FRs covered:** FR83
**Prerequisite:** Epic 20 (unitType + conversionRate sur CatalogItem), Epic 5 (mouvements de stock)

---

### Epic 22: Alertes stock bas + notifications
Chaque article peut avoir un seuil de stock bas configurable. Après tout mouvement décrémentant le stock, le système évalue automatiquement les articles sous seuil et publie les alertes. Le backoffice affiche un badge catalogue, un écran alertes dédié, et un KPI dashboard "Stock critique". Un service de notification envoie un résumé quotidien configurable par tenant (canal, heure, on/off).
**Phase:** 2a
**FRs covered:** FR81, FR82, FR86
**Prerequisite:** Epics 1–9, Epic 2 (catalog + minStockLevel field), Epic 5 (mouvements de stock)

---

### Epic 20: Vente au poids + unités configurables
Les articles peuvent être configurés avec un `unitType` (pièce, poids, volume, longueur) et un label d'unité libre. Au POS, les articles au poids affichent un champ de saisie de quantité en virgule flottante ; le total est calculé automatiquement avec arrondi FCFA. Le reçu affiche la quantité et l'unité native. La décrémentation stock applique le facteur de conversion configuré.
**Phase:** 2a
**FRs covered:** FR76, FR77, FR78
**Prerequisite:** Epics 1–9 (backend catalog opérationnel)

---

### Epic 13: Scalario Enterprise
A Retail tenant (org_mode: standalone) upgrades to Enterprise (org_mode: integrated or federated) with zero downtime. Enterprise adds: multi-department org structure (FR59–FR61, DB seeded in Story 1.6), HR & Payroll with CNSS/CARFO/SMIG compliance (FR63–FR68), OHADA accounting with month-end close and FEC export (FR69–FR72), CSV import for employees and chart of accounts (FR73–FR74), and inter-department event flows connecting payroll validation to automatic accounting entries (FR62). User journeys: Awa (DRH), Ibrahim (Comptable), Serge (DG).
**Phase:** 3
**FRs covered:** FR59–FR74 Phase 3 business logic (DB structure for FR59–FR61 already seeded in Story 1.6)
**Prerequisite:** Epic 1 (Kernel + Story 1.6 DB fields in place)

---

## Epic 1: Kernel — Identity, Tenancy & Access Control

After this epic, users authenticate with tenant-scoped sessions, roles are enforced system-wide, modules can be activated per tenant, and every mutation is audit-logged. This is the foundation all other modules depend on.

### Story 1.1: Kernel Schema, Tenant Management & Authentication

As a system administrator,
I want to create and configure tenants, and have users authenticate with tenant-scoped sessions,
So that each business operates in complete isolation with proper authentication.

**Acceptance Criteria:**

**Given** the database has no kernel schema
**When** the Prisma migration runs
**Then** the `kernel` schema is created with `tenants` and `organization_members` tables, and `Tenant` includes fields: `id`, `name`, `currency` (default XOF), `timezone` (default Africa/Abidjan), `fiscal_jurisdiction`, `status` (active/suspended/archived), `created_at`

**Given** an existing Tenant in the old public schema
**When** the migration completes
**Then** tenant data is preserved in the new kernel schema with new fields populated with defaults

**Given** a valid JWT token from Supabase Auth
**When** a request hits any protected endpoint
**Then** `AuthGuard` validates the token and attaches user context to the request via `@CurrentUser()` decorator

**Given** a request with `x-tenant-id` header
**When** the request passes AuthGuard
**Then** `TenantGuard` validates the user is a member of that tenant, attaches tenant context via `@CurrentTenant()` decorator, and Prisma middleware executes `SET LOCAL app.current_tenant_id` for RLS enforcement

**Given** a request without a valid JWT or with an invalid `x-tenant-id`
**When** the request hits a protected endpoint
**Then** the system returns 401 (no JWT) or 403 (wrong tenant) with clear error messages

**Given** a user session that has been idle longer than the configured timeout
**When** the next request is made
**Then** the session is rejected and the user must re-authenticate

**Given** a route decorated with `@Public()`
**When** an unauthenticated request hits that route
**Then** the request is allowed through without JWT validation

### Story 1.2: Role-Based Access Control (RBAC)

As a tenant owner,
I want to create user accounts with assigned roles and have the system enforce role-based permissions,
So that each team member can only access features appropriate to their role (Owner, Manager, Commercial).

**Acceptance Criteria:**

**Given** the kernel schema exists
**When** the RBAC migration runs
**Then** `roles`, `permissions`, and `role_permissions` tables are created in the kernel schema, and `organization_members.role` is converted from String to FK referencing `roles`

**Given** the system initializes
**When** the seed script runs
**Then** MVP Retail roles are seeded: Owner (full access), Manager (stock/reports), Commercial (POS/sales), each with predefined permissions matching the PRD v5 RBAC Retail matrix
**And** two Phase-3-reserved roles are seeded with zero active permissions:
  - DepartmentAdmin (Enterprise: department-level management)
  - Employee (Enterprise: basic access within department)
  Each marked with a `phase` metadata field ('phase3') — non-activatable in Phase 1 but require no schema migration to enable in Phase 3

**Given** an Owner user is authenticated
**When** they call `POST /api/v1/organizations/:id/members` with a role assignment
**Then** a new OrganizationMember is created with the specified role FK

**Given** a Commercial user is authenticated
**When** they attempt to access an Owner-only endpoint (e.g., price modification)
**Then** `RolesGuard` returns 403 Forbidden

**Given** an endpoint decorated with `@Roles('owner', 'manager')`
**When** a Commercial user calls it
**Then** the request is rejected; when an Owner or Manager calls it, the request proceeds

**Given** the RBAC system is deployed
**When** existing OrganizationMember records are migrated
**Then** each member's string role is mapped to the corresponding Role FK with zero data loss

### Story 1.3: Module Registry & Activation

As a system administrator,
I want to register available modules and activate/deactivate them per tenant,
So that each tenant only pays for and accesses the modules they need, with dependency validation.

**Acceptance Criteria:**

**Given** the kernel schema exists
**When** the module registry migration runs
**Then** `modules` and `tenant_modules` tables are created with fields matching the Architecture spec (code, name, type, dependencies, status)

**Given** the system initializes
**When** the seed script runs
**Then** shared modules (catalog, transactions, inventory, payments, contacts, reporting) and the retail vertical are registered with correct dependency declarations
**And** two Phase-3 modules are pre-registered with status='available_phase3' and activatable=false:
  - connect: type='vertical', depends_on=[]
  - enterprise: type='vertical', depends_on=[catalog, contacts, transactions, reporting]
So that Phase 3 launch requires only a status flag update, never a new seed migration on a live multi-tenant system

**Given** an admin activates a vertical module for a tenant
**When** the vertical declares dependencies on shared modules
**Then** the system validates all dependencies are active before allowing activation; if a dependency is missing, activation fails with a clear error

**Given** a tenant has the catalog module active
**When** a request hits a Catalog endpoint with `@RequiresModule('catalog')`
**Then** `ModuleGuard` allows the request through

**Given** a tenant does NOT have the catalog module active
**When** a request hits a Catalog endpoint
**Then** `ModuleGuard` returns 403 with message "Module not activated for this tenant"

**Given** a tenant with active modules
**When** admin deactivates a module for that tenant
**Then** the deactivation has zero impact on other tenants' module activations

**Given** a tenant with org_mode='standalone' already has one active vertical
**When** admin attempts to activate a second vertical
**Then** the system rejects the activation (Retail mode: one vertical per tenant)

**Given** a tenant with org_mode='integrated' (Enterprise Phase 3)
**When** admin activates a vertical scoped to a specific department
**Then** the system allows it — multi-vertical is valid in Enterprise mode
**Note:** ModuleGuard must check org_mode before enforcing the constraint — write the guard to be mode-aware from day one

### Story 1.4: Event Bus & Audit Trail

As a platform operator,
I want every data mutation to be logged in an immutable audit trail and cross-module events to be published,
So that we have complete accountability and modules can react to events from other modules.

**Acceptance Criteria:**

**Given** the kernel schema exists
**When** the audit trail migration runs
**Then** the `audit_log` table is created with fields: `id`, `tenant_id`, `user_id`, `action` (CREATE/UPDATE/DELETE), `entity`, `entity_id`, `before` (JSON), `after` (JSON), `created_at`, with indexes on `(tenant_id, created_at)` and `(entity_id)`

**Given** the NestJS application starts
**When** the EventBus module initializes
**Then** `EventEmitter2` is configured and available for injection, with typed domain event definitions (TransactionCreated, StockAdjusted, SessionClosed, BalanceUpdated, etc.)

**Given** any service creates, updates, or deletes an entity
**When** the mutation is committed
**Then** an AuditLog entry is created capturing: the authenticated user, the tenant context, the action type, the entity type and ID, the before state (null for CREATE), and the after state (null for DELETE)

**Given** the audit_log table contains entries
**When** any attempt is made to UPDATE or DELETE audit records
**Then** the operation is rejected — audit log is append-only and immutable

**Given** the audit log contains data older than the client-side retention period
**When** the local retention policy runs
**Then** old audit entries are purged locally but remain indefinitely on the server

**Given** a domain event (e.g., TransactionCreated) is published
**When** a handler in another module is registered with `@OnEvent('transaction.created')`
**Then** the handler executes with the event payload

### Story 1.5: Guard Chain Integration & Backward Compatibility

As a developer deploying the kernel extraction,
I want the complete guard chain wired and all existing endpoints still functional,
So that the 3 existing clients experience zero disruption during the kernel deployment.

**Acceptance Criteria:**

**Given** all kernel guards are implemented (Auth, Tenant, Module, Roles)
**When** a request hits any protected endpoint
**Then** guards execute in order: AuthGuard → TenantGuard → ModuleGuard → RolesGuard, and failure at any stage returns the appropriate error code

**Given** the existing POS endpoints (`/pos/*`)
**When** the kernel is deployed
**Then** all existing endpoints continue to function identically for the 3 current clients — same request/response shapes, same behavior

**Given** two tenants (A and B) exist in the system
**When** tenant A's user attempts to query data
**Then** RLS policies ensure zero cross-tenant data leakage, validated by integration tests that create data in tenant A and verify it's invisible to tenant B

**Given** the kernel module is registered as a NestJS module
**When** `AppModule` imports `KernelModule`
**Then** it exports: AuthGuard, TenantGuard, RolesGuard, ModuleGuard, EventBus, and all decorators (@CurrentUser, @CurrentTenant, @Roles, @RequiresModule, @Public)

**Given** a new tenant needs to be created
**When** admin calls the tenant creation endpoint
**Then** the tenant is created with default configuration (XOF currency, Africa/Abidjan timezone), MVP roles are seeded, and shared + retail modules are activated — requiring zero code changes

### Story 1.6: Phase 3 DB Anticipation Fields

As a system architect,
I want to add all Phase 2b/3 anticipation fields in a single dedicated Prisma migration,
So that Scalario Connect, Enterprise, and Programme Ambassadeurs can be activated in future phases without a breaking migration on a live multi-tenant system.

**Note:** This story contains zero business logic. It is a schema-only migration. All new fields are nullable or have safe defaults. No endpoint, service, or guard is modified.

**Acceptance Criteria:**

**Given** all Epic 1 stories (1.1–1.5) are complete
**When** the Phase 3 anticipation migration runs
**Then** the following fields are added with zero data loss and zero downtime for existing tenants:

kernel.tenants:
- referred_by UUID nullable FK → tenants.id (FR52 — Programme Ambassadeurs Phase 2b)
- network_visible Boolean default false (FR52 — Scalario Connect Phase 3)
- org_mode Enum(standalone|integrated|federated) default standalone (FR59 — Enterprise Phase 3)
- parent_tenant_id UUID nullable FK → tenants.id (FR59 — Enterprise Fédéré Phase 3)

kernel.organization_members:
- department_ids UUID[] default [] (FR60 — Enterprise Phase 3)

kernel.tenant_modules:
- department_id UUID nullable (FR61 — Enterprise Phase 3)

shared.contacts:
- linked_tenant_id UUID nullable (FR53 — Scalario Connect Phase 3)

shared.catalog_items:
- supplier_reference UUID nullable (FR54 — Scalario Connect Phase 3)

shared.transactions (transaction_type enum):
- Add 'transfer_inter_tenant' to transaction_type enum (FR55 — Scalario Connect Phase 3)

**Given** each new column is created
**When** existing rows are read
**Then** all nullable fields return null, boolean fields return false, enum fields return 'standalone' — zero breaking change for the 3 existing clients

**Given** RLS is active on kernel.tenants
**When** the new fields are queried
**Then** existing RLS policies cover them automatically — same tenant_id filter applies, no new policy needed

**Given** the migration completes
**Then** each field has a Prisma schema comment explaining its phase and purpose, e.g.:
  /// Phase 2b — Programme Ambassadeurs. Populated when tenant is created via referral. FK to tenants.id.
  referred_by String? @db.Uuid

---

## Epic 2: Shared Catalog Module

Owners can manage products through the new polymorphic catalog (with itemType discriminator), organize by categories, and all catalog data is available offline. Old product endpoints remain backward-compatible.

### Story 2.1: Shared Schema & CatalogItem Entity

As a system architect,
I want the Product entity decomposed into a shared CatalogItem with a polymorphic type discriminator,
So that any vertical can extend the base catalog without touching shared code.

**Acceptance Criteria:**

**Given** the kernel schema exists from Epic 1
**When** the shared catalog migration runs
**Then** the `shared` schema is created with `catalog_items` table containing: `id`, `name`, `price` (Decimal 10,2), `barcode`, `item_type` (default 'physical', enum: physical/bookable/service), `category_id`, `tenant_id`, `is_deleted` (default false), `created_at`, `updated_at`

**Given** existing Product records in the public schema
**When** the data migration runs
**Then** all products are migrated to `shared.catalog_items` with `item_type` set to 'physical', and zero data loss is verified by row count comparison

**Given** the `catalog_items` table exists
**When** indexes are created
**Then** indexes exist on `(tenant_id, updated_at)` for delta sync, `(tenant_id, category_id)` for grid filtering, and `(barcode)` for scan lookup

**Given** RLS is enabled on `shared.catalog_items`
**When** a query executes
**Then** the tenant_isolation policy enforces `tenant_id = current_setting('app.current_tenant_id')::uuid`

### Story 2.2: Category Management & Catalog API

As a shop owner,
I want to create and manage product categories and catalog items through the new shared API,
So that my products are organized and manageable from any vertical.

**Acceptance Criteria:**

**Given** the shared schema with catalog_items exists
**When** the categories migration runs
**Then** the `shared.categories` table is created with `id`, `name`, `tenant_id`, `created_at`, with index on `(tenant_id)` and FK from `catalog_items.category_id`

**Given** existing Category records in the public schema
**When** the data migration runs
**Then** all categories are migrated to `shared.categories` with zero data loss

**Given** an authenticated Owner user
**When** they call `POST /api/v1/catalog/items` with item data (name, price, category, barcode)
**Then** a CatalogItem is created in the shared schema with `item_type` defaulting to 'physical'
**And** an AuditLog entry is recorded

**Given** an authenticated Owner user
**When** they call `DELETE /api/v1/catalog/items/:id`
**Then** the item is soft-deleted (`is_deleted = true`), not physically removed, and delta sync clients will receive the deletion flag

**Given** an authenticated Owner user
**When** they call `GET /api/v1/catalog/categories`
**Then** all categories for the tenant are returned

**Given** an authenticated Owner user
**When** they call `POST /api/v1/catalog/categories` with a category name
**Then** a new Category is created for the tenant

**Given** a Commercial user is authenticated
**When** they attempt to create or edit a catalog item
**Then** RolesGuard returns 403 (only Owner can modify catalog)

**Given** the old `/pos/products` endpoints still exist
**When** a client calls the old endpoints
**Then** they are proxied to the new CatalogService and return identical response shapes

### Story 2.3: Catalog Sync Adapter & Delta Pull

As a cashier using the POS offline,
I want catalog data to sync to my device automatically using delta pulls,
So that I always have the latest products and prices without downloading the entire catalog.

**Acceptance Criteria:**

**Given** a client device with a last sync timestamp
**When** the client calls `GET /api/v1/catalog/items?since=<ISO8601>`
**Then** only items with `updated_at > since` are returned, including soft-deleted items (so the client can remove them locally)

**Given** a client calls the catalog sync endpoint
**When** the response is returned
**Then** it includes `meta.serverTime` so the client can store it as the next `since` value
**And** pagination is supported with `?page=1&limit=100` and `meta.hasMore`

**Given** the CatalogModule is implemented
**When** it is registered in AppModule
**Then** it is registered as a `DynamicModule` via `CatalogModule.register()`, imports KernelModule and PrismaModule, and exports CatalogService for use by other modules

**Given** a bulk sync request from the frontend
**When** the client calls `POST /api/v1/catalog/items/sync` with an array of items
**Then** each item is upserted by UUID (idempotent) — existing items are updated, new items are created

**Given** 2,000 catalog items for a tenant
**When** the client queries the catalog
**Then** the response is returned within acceptable performance bounds for the delta sync protocol

---

## Epic 3: Shared Contacts Module

Users can manage customer profiles, track outstanding balances for credit sales, and access contact data offline. Customer → Contact entity migration with contactType support.

### Story 3.1: Contact Entity & Migration

As a system architect,
I want the Customer entity migrated to a shared Contact with contactType support,
So that the contact system supports customers, suppliers, and future contact types across verticals.

**Acceptance Criteria:**

**Given** the shared schema exists from Epic 2
**When** the contacts migration runs
**Then** the `shared.contacts` table is created with: `id`, `name`, `phone`, `email`, `address`, `contact_type` (default 'customer', future: 'supplier'), `balance` (Decimal 10,2, default 0), `tenant_id`, `created_at`, `updated_at`, with indexes on `(tenant_id)` and `(tenant_id, phone)`

**Given** existing Customer records in the public schema
**When** the data migration runs
**Then** all customers are migrated to `shared.contacts` with `contact_type = 'customer'`, balances preserved, and zero data loss verified

**Given** RLS is enabled on `shared.contacts`
**When** a query executes for a tenant
**Then** only contacts belonging to that tenant are returned

### Story 3.2: Contacts API & Credit Management

As a commercial,
I want to manage customer profiles and record credit sales that update their outstanding balance,
So that I can track which customers owe money and settle debts.

**Acceptance Criteria:**

**Given** an authenticated user
**When** they call `POST /api/v1/contacts` with name and phone
**Then** a Contact is created for the tenant with `contact_type = 'customer'` and `balance = 0`
**And** an AuditLog entry is recorded

**Given** an authenticated user
**When** they call `GET /api/v1/contacts?since=<ISO8601>`
**Then** only contacts with `updated_at > since` are returned (delta sync support)

**Given** an authenticated user
**When** they call `GET /api/v1/contacts/search?q=<name_or_phone>`
**Then** contacts matching the search query for the tenant are returned

**Given** a credit sale is recorded against a customer
**When** `ContactsService.updateBalance(customerId, amount)` is called
**Then** the customer's balance is incremented by the sale amount
**And** a `BalanceUpdated` event is emitted

**Given** a customer has an outstanding balance of 5000 FCFA
**When** a user calls `POST /api/v1/contacts/:id/settle` with amount 3000
**Then** the balance is reduced to 2000 FCFA
**And** an AuditLog entry records the settlement

**Given** the ContactsModule is implemented
**When** it is registered in AppModule
**Then** it is registered as a DynamicModule, imports KernelModule, and exports ContactsService for use by Transactions/Payments

**Given** the old `/pos/customers` endpoints exist
**When** a client calls the old endpoints
**Then** they are proxied to the new ContactsService with identical response shapes

---

## Epic 4: Shared Transactions & Payments Module

Commercials can process sales with proper payment methods (cash, mobile money, credit, split), FCFA 5-franc rounding, change due calculation, and local-first transaction recording. Order → Transaction entity migration with lifecycle types.

### Story 4.1: Transaction Entity & Payments Service

As a system architect,
I want the Order entity decomposed into a shared Transaction with lifecycle types and a dedicated Payments service with FCFA rounding,
So that transaction processing is shared infrastructure usable by any vertical.

**Acceptance Criteria:**

**Given** the shared schema exists
**When** the transactions migration runs
**Then** the `shared.transactions` table is created with: `id`, `total_amount` (Decimal 10,2), `items_json` (JSON), `payment_method`, `payment_splits` (JSON), `lifecycle_type` (default 'instant', enum: instant/accumulating/scheduled), `customer_id` (FK → contacts), `tenant_id`, `created_at`, with indexes on `(tenant_id, created_at)` and `(customer_id)`

**Given** existing Order records in the public schema
**When** the data migration runs
**Then** all orders are migrated to `shared.transactions` with `lifecycle_type = 'instant'`, and zero data loss verified

**Given** the PaymentsService receives a list of items and currency XOF
**When** it calculates the total
**Then** the total is rounded to the nearest 5 FCFA (e.g., 1247 → 1245, 1248 → 1250)

**Given** a cash payment of 1000 FCFA for a 600 FCFA transaction
**When** the change is calculated
**Then** the system returns 400 FCFA as change due

**Given** a split payment (e.g., 500 cash + 100 mobile money)
**When** the payment is processed
**Then** `payment_splits` JSON records each split with method and amount, and the total matches the transaction amount

### Story 4.2: Transaction API & Local-First Recording

As a commercial,
I want to create sales transactions that are written locally first and synced when connectivity returns,
So that I can process sales without interruption regardless of network status.

**Acceptance Criteria:**

**Given** an authenticated Commercial user
**When** they call `POST /api/v1/transactions` with a client-generated UUID and transaction data
**Then** the transaction is created with the provided UUID (idempotent — if UUID exists, return existing record without error)
**And** stock is automatically decremented via `StockAdjusted` event (when Inventory module is active)
**And** an AuditLog entry is recorded

**Given** a transaction with `payment_method = 'credit'` and a `customer_id`
**When** the transaction is recorded
**Then** `ContactsService.updateBalance()` is called to increment the customer's outstanding balance

**Given** the client pushes multiple pending transactions in a batch
**When** they call `POST /api/v1/transactions` for each
**Then** each is processed idempotently — duplicates are ignored, new ones are created

**Given** the TransactionsModule is implemented
**When** it is registered in AppModule
**Then** it is registered as a DynamicModule, imports KernelModule, CatalogModule, ContactsModule, and PaymentsModule
**And** emits `TransactionCreated` event on every new transaction

**Given** the old `/pos/orders` endpoints exist
**When** a client calls the old endpoints
**Then** they are proxied to the new TransactionsService with identical response shapes

**Given** RLS is enabled on `shared.transactions`
**When** a query executes
**Then** only transactions belonging to the authenticated tenant are returned

---

## Epic 5: Shared Inventory Module

Managers can receive deliveries, create stock transfers, and perform partial inventory counts. Commercials can confirm transfers and declare losses. The chain-of-custody pattern with double-validation and variance tracking is fully operational.

### Story 5.1: Inventory Schema & Stock Movement Types

As a system architect,
I want stock movements extracted to a shared module with typed movement categories,
So that inventory tracking is shared infrastructure with clear movement semantics.

**Acceptance Criteria:**

**Given** the shared schema exists
**When** the inventory migration runs
**Then** the `shared.stock_movements` table is created with: `id`, `catalog_item_id` (FK → catalog_items), `quantity` (Decimal 10,2), `type` (enum: SALE/DELIVERY/TRANSFER_OUT/TRANSFER_IN/LOSS/ADJUSTMENT), `reason`, `tenant_id`, `user_id`, `created_at`, with indexes on `(tenant_id, created_at)` and `(catalog_item_id)`

**Given** existing StockMovement records in the public schema
**When** the data migration runs
**Then** all movements are migrated to `shared.stock_movements` with `productId` renamed to `catalog_item_id` and zero data loss verified

**Given** a `TransactionCreated` event is published
**When** the Inventory event handler receives it
**Then** a SALE-type stock movement is automatically created for each item in the transaction, decrementing stock

**Given** the InventoryModule is implemented
**When** it is registered in AppModule
**Then** it is registered as a DynamicModule, imports KernelModule and CatalogModule, exports InventoryService, and listens to TransactionCreated events

### Story 5.2: Supplier Delivery Reception

As a store manager,
I want to receive supplier deliveries and record received quantities against expected quantities,
So that delivery variances are tracked and attributed automatically.

**Acceptance Criteria:**

**Given** an authenticated Manager user
**When** they call `POST /api/v1/inventory/movements` with type DELIVERY, catalogItemId, and received quantity
**Then** a DELIVERY stock movement is created, increasing the stock level for that item
**And** an AuditLog entry is recorded

**Given** a delivery with expected quantity 20 and received quantity 18
**When** the manager records the reception with an observer note "2 cartons not delivered"
**Then** the movement records quantity 18 with the reason field containing the variance note
**And** a `StockAdjusted` event is emitted

**Given** the old `/pos/stock-movements` endpoints exist
**When** a client calls the old endpoints
**Then** they are proxied to the new InventoryService with identical response shapes

### Story 5.3: Stock Transfers & Chain-of-Custody

As a store manager and commercial,
I want to create stock transfers with double-validation (sender declares, receiver confirms),
So that transfer variances are automatically tracked and attributed to the correct link in the chain.

**Acceptance Criteria:**

**Given** an authenticated Manager user
**When** they call `POST /api/v1/inventory/movements` with type TRANSFER_OUT, catalogItemId, quantity, and destination info
**Then** a TRANSFER_OUT movement is created, reducing stock at the sender's location
**And** a `TransferCreated` event is emitted with status "pending confirmation"

**Given** a pending transfer exists
**When** an authenticated Commercial calls the confirmation endpoint with type TRANSFER_IN, the transfer reference, and their actually received quantity
**Then** a TRANSFER_IN movement is created with the declared received quantity
**And** if sent quantity (8 kg) != received quantity (7 kg), the variance (1 kg) is automatically calculated and attributed
**And** a `TransferConfirmed` event is emitted with the variance data

**Given** transfer variance data exists
**When** the owner or manager views the transfer history
**Then** each transfer shows: who sent, quantity sent, who received, quantity received, variance, and timestamp

### Story 5.4: Loss Declaration & Partial Inventory

As a commercial or manager,
I want to declare stock losses with a mandatory reason and perform partial inventory counts,
So that all stock discrepancies are documented and shrinkage is traceable.

**Acceptance Criteria:**

**Given** an authenticated Commercial or Manager user
**When** they call `POST /api/v1/inventory/movements` with type LOSS, catalogItemId, quantity, and reason
**Then** a LOSS movement is created, reducing stock
**And** the `reason` field is mandatory and must be non-empty (e.g., "produit trop mur", "sac perce")
**And** an AuditLog entry is recorded

**Given** an authenticated Manager user
**When** they perform a partial inventory count via `POST /api/v1/inventory/adjust` with catalogItemId and counted quantity
**Then** the system compares counted vs theoretical stock and creates an ADJUSTMENT movement for the variance
**And** if variance exists, the reason is required

**Given** the inventory module processes movements
**When** `GET /api/v1/inventory/stock?catalogItemId=<id>` is called
**Then** the current stock level is calculated by summing all movements for that item (deliveries + transfers_in - sales - transfers_out - losses +/- adjustments)

**Given** the `GET /api/v1/inventory/movements?since=<ISO8601>` endpoint is called
**When** the response is returned
**Then** delta sync is supported, returning only movements after the given timestamp

---

## Epic 6: Retail Vertical — POS Sessions & Extensions

The retail POS is wrapped as a vertical module with cash sessions, session-scoped transactions, RetailProduct and RetailSale extensions, and parked cart support.

### Story 6.1: Retail Schema & Product Extensions

As a system architect,
I want the retail-specific product fields extracted into a RetailProduct extension table,
So that the shared CatalogItem stays clean and other verticals can add their own extensions.

**Acceptance Criteria:**

**Given** the shared catalog_items table exists
**When** the retail schema migration runs
**Then** the `retail` schema is created with `retail_products` table containing: `id`, `catalog_item_id` (unique FK → catalog_items), `stock_quantity` (Decimal 10,2, default 0), `weight_unit` (nullable, for future weight-based sales), `min_stock_level` (nullable, Decimal 10,2)

**Given** existing Product records that had stock-related fields
**When** the data migration runs
**Then** RetailProduct records are created for each CatalogItem with `stock_quantity` and `min_stock_level` values migrated from the old Product model

**Given** a `GET /api/v1/catalog/items` request from a retail tenant
**When** the API response is built
**Then** the response joins CatalogItem + RetailProduct and returns a flat object (name, price, barcode, stockQuantity, weightUnit, minStockLevel) — the client stores this denormalized shape directly in Isar

### Story 6.2: RetailSale Extensions & Session Scoping

As a system architect,
I want retail-specific transaction fields (sessionId, receiptNumber, cashierId) in an extension table,
So that the shared Transaction stays clean and retail-specific POS logic is isolated.

**Acceptance Criteria:**

**Given** the retail schema exists
**When** the retail sales migration runs
**Then** the `retail.retail_sales` table is created with: `id`, `transaction_id` (unique FK → transactions), `session_id` (FK → pos_sessions, nullable), `receipt_number`, `cashier_id`

**Given** existing Order records with sessionId and receiptNumber
**When** the data migration runs
**Then** RetailSale records are created for each Transaction with session and receipt data migrated, zero data loss verified

**Given** a retail transaction is created
**When** the RetailModule processes the sale
**Then** both a shared Transaction AND a RetailSale extension record are created in a single database transaction (atomicity guaranteed)
**And** the RetailSale is linked to the active POS session via `session_id`

### Story 6.3: Cash Session Management

As a commercial,
I want to open and close cash sessions with balance tracking and mandatory variance explanation,
So that cash accountability is enforced and the owner can track cash handling accuracy.

**Acceptance Criteria:**

**Given** the retail schema exists
**When** the sessions migration runs
**Then** the `retail.pos_sessions` table is created (or migrated from public) with: `id`, `opening_balance` (Decimal 10,2), `closing_balance` (nullable), `theoretical_balance` (nullable), `variance` (nullable), `variance_explanation` (nullable), `status` (OPEN/CLOSED), `user_id`, `tenant_id`, `opened_at`, `closed_at`, with index on `(tenant_id, user_id, status)`

**Given** an authenticated Commercial user with no open session
**When** they call `POST /api/v1/retail/sessions/open` with an opening balance (e.g., 15000 FCFA)
**Then** a new PosSession is created with status OPEN and the declared opening balance

**Given** a Commercial has an open session
**When** they attempt to open another session
**Then** the system rejects the request — only one open session per user

**Given** a Commercial has an open session with sales totaling 128000 FCFA in cash
**When** they call `POST /api/v1/retail/sessions/close/:id` with closing_balance = 127500
**Then** the system calculates theoretical_balance = opening_balance + cash_sales = 143000, variance = 127500 - 143000 = -15500
**And** if variance != 0 and no variance_explanation is provided, the closure is rejected with an error

**Given** a Commercial provides a variance explanation
**When** the session is closed
**Then** the session status changes to CLOSED, closed_at is set, and a `SessionClosed` event is emitted

**Given** an authenticated Manager user
**When** they call `GET /api/v1/retail/sessions/summary/:id`
**Then** the session summary is returned with: total sales, breakdown by payment method, opening balance, closing balance, theoretical balance, variance, and explanation

**Given** an authenticated Manager user
**When** they call `GET /api/v1/reports/sessions`
**Then** they can view session closure reports for all commercials in their location

### Story 6.4: Retail Module Registration & POS Orchestration

As a developer,
I want the RetailModule to wrap shared modules into a cohesive POS vertical,
So that activating the retail vertical for a tenant gives them the complete POS experience.

**Acceptance Criteria:**

**Given** the RetailModule is implemented
**When** it is registered in AppModule via `RetailModule.register()`
**Then** it imports CatalogModule, TransactionsModule, InventoryModule, PaymentsModule, ContactsModule, and declares dependency on all of them in the Module registry

**Given** a retail tenant's Commercial creates a sale
**When** the POS orchestration service processes it
**Then** it coordinates: Transaction creation (shared) → RetailSale extension (retail) → Stock decrement (shared, via event) → Customer balance update if credit (shared) — all in a single atomic operation

**Given** the retail vertical endpoints (`/api/v1/retail/*`)
**When** decorated with `@RequiresModule('retail')`
**Then** only tenants with the retail module activated can access them

**Given** all old POS endpoints
**When** the retail module is deployed
**Then** old endpoints proxy to the new retail services with identical behavior for backward compatibility

---

## Epic 7: Reporting & Business Intelligence

Managers can generate daily consolidation reports. Owners can view dashboards with revenue, sale count, losses, cash variances, and critical stock levels.

### Story 7.1: Daily Consolidation Reports

As a store manager,
I want to generate a daily consolidation report covering sales, losses, variances, and transfers,
So that I can review the day's operations and send a summary to the owner.

**Acceptance Criteria:**

**Given** an authenticated Manager user
**When** they call `GET /api/v1/reports/sales?from=<date>&to=<date>&groupBy=day`
**Then** the report returns: total revenue, sale count, breakdown by payment method, total losses declared, total transfer variances, for the requested date range

**Given** an authenticated Manager user
**When** they call `GET /api/v1/reports/sessions?from=<date>&to=<date>`
**Then** the report returns: all sessions with their closure summaries, cash variances per commercial, and variance explanations

**Given** an authenticated Manager user
**When** they call `GET /api/v1/reports/inventory?from=<date>&to=<date>`
**Then** the report returns: deliveries received, transfers completed with variances, losses declared with motifs, adjustments from partial counts

**Given** the ReportingModule is implemented
**When** it is registered in AppModule
**Then** it is a read-only module that queries across shared and retail schemas, imports KernelModule, CatalogModule, TransactionsModule, and InventoryModule

### Story 7.2: Owner Dashboard & Analytics

As a shop owner,
I want to view a dashboard with revenue, sale count, losses, cash variances, and critical stock levels,
So that I can monitor my business remotely without being physically present.

**Acceptance Criteria:**

**Given** an authenticated Owner user
**When** they call `GET /api/v1/reports/sales/stats?from=<date>&to=<date>`
**Then** the response includes: total revenue, total sale count, average transaction value, top 3 products by sales volume, total losses, and total cash variances

**Given** an authenticated Owner user
**When** they call `GET /api/v1/reports/inventory` with no date filter
**Then** the response includes current stock levels for all products with items below `min_stock_level` flagged as critical

**Given** a Commercial user attempts to access reporting endpoints
**When** the RolesGuard evaluates the request
**Then** access is denied — reporting is limited to Manager and Owner roles

**Given** the old stats/reports methods in PosService
**When** the reporting module is deployed
**Then** old report endpoints proxy to the new ReportingService with identical response shapes

---

## Epic 8: Frontend Sync & Offline Resilience

Frontend repositories updated to new API endpoints, Isar models aligned with new response shapes, full offline-first experience preserved with delta sync, crash recovery, conflict resolution, and connectivity indicator.

### Story 8.1: Repository & API URL Migration

As a developer,
I want all frontend repositories updated to call the new modular API endpoints,
So that the frontend communicates with the restructured backend correctly.

**Acceptance Criteria:**

**Given** the existing ProductRepository calls `/pos/products`
**When** the migration is applied
**Then** it calls `/api/v1/catalog/items` with the same request/response handling
**And** delta sync uses `?since=<lastSync>` parameter

**Given** the existing CustomerRepository calls `/pos/customers`
**When** the migration is applied
**Then** it calls `/api/v1/contacts` with updated field mappings (Customer → Contact)

**Given** the existing OrderRepository calls `/pos/orders`
**When** the migration is applied
**Then** it calls `/api/v1/transactions` with updated field mappings (Order → Transaction)

**Given** the existing SessionRepository calls `/pos/sessions`
**When** the migration is applied
**Then** it calls `/api/v1/retail/sessions/*` with updated endpoints (open, close, active, summary)

**Given** all repositories are updated
**When** the frontend makes API calls
**Then** all requests include `x-tenant-id` header and Bearer JWT token as required by the new guard chain

### Story 8.2: Isar Model Alignment & Sync Adapters

As a developer,
I want Isar collections aligned with the new API response shapes and module-agnostic sync adapters,
So that local data matches the restructured backend models.

**Acceptance Criteria:**

**Given** the existing Isar Product collection
**When** the model is updated
**Then** it stores the denormalized CatalogItem + RetailProduct shape (name, price, barcode, itemType, stockQuantity, weightUnit, minStockLevel) as returned by the API

**Given** the existing Isar Customer collection
**When** the model is updated
**Then** it stores the Contact shape (name, phone, email, address, contactType, balance) with the new field names

**Given** the existing Isar Order collection
**When** the model is updated
**Then** it stores the Transaction + RetailSale joined shape (totalAmount, itemsJson, paymentMethod, lifecycleType, sessionId, receiptNumber)

**Given** the SyncService needs module-agnostic adapters
**When** sync adapters are implemented
**Then** each entity type (catalog, contacts, transactions, sessions, movements) has its own sync adapter that handles push/pull independently
**And** the sync engine orchestrates adapters without knowing entity-specific logic

### Story 8.3: Delta Sync, Outbox & Conflict Resolution

As a cashier working offline,
I want all my local mutations queued and synced automatically when connectivity returns,
So that I never lose a transaction and the system handles conflicts gracefully.

**Acceptance Criteria:**

**Given** a mutation (sale, session, customer edit) is performed offline
**When** it is written to Isar
**Then** it is also added to the outbox queue with `syncStatus = pending`

**Given** connectivity returns after an offline period
**When** the sync engine detects the connection
**Then** all pending outbox items are pushed to the server in order: sessions → transactions → customers → stock movements
**And** each push uses UUID-based idempotent upsert (duplicate pushes are safe)

**Given** a delta pull is triggered
**When** the sync engine calls `GET /api/v1/<resource>?since=<lastSync>`
**Then** only records with `updated_at > lastSync` are returned
**And** the client stores `meta.serverTime` as the next `since` value

**Given** two devices edit the same non-critical record offline (e.g., customer address)
**When** both sync
**Then** last-write-wins (LWW) conflict resolution is applied based on `updated_at`

**Given** two devices create conflicting financial records (e.g., overlapping stock adjustments)
**When** both sync
**Then** server-wins resolution is applied and the conflict is logged for review

**Given** a full day of 150+ transactions is pending
**When** sync executes on a 3G connection
**Then** all transactions sync in under 30 seconds with compressed delta payloads

### Story 8.4: Crash Recovery, Retention & Connectivity Indicator

As a cashier on a device that may lose power unexpectedly,
I want the system to recover to a consistent state after a crash with zero data loss,
So that I can resume work immediately without worrying about lost transactions.

**Acceptance Criteria:**

**Given** Isar is configured with WAL (Write-Ahead Log) enabled
**When** the device loses power mid-transaction
**Then** on next app start, Isar replays the WAL and recovers all committed writes — zero data loss

**Given** the app starts after an unexpected termination
**When** the recovery process completes
**Then** in-progress transactions that were fully written are preserved; partially written transactions are rolled back to a consistent state
**And** app cold start remains under 3 seconds

**Given** the sync status UI component
**When** the device is online
**Then** a subtle, non-blocking indicator shows connected status (e.g., small green dot)

**Given** the device goes offline
**When** the connectivity changes
**Then** the indicator updates to show offline status (e.g., small grey dot) without any popup or blocking modal — the user may not even notice

**Given** local data retention is configured (e.g., 60 days)
**When** the retention policy runs
**Then** synced records older than the retention period are purged from Isar
**And** unsynced records are NEVER purged regardless of age
**And** the local database remains under 500MB

**Given** the device has limited memory (1-2 GB RAM)
**When** the app is running with sync in background
**Then** total memory footprint stays under 150MB (Isar mmap, ListView.builder, sync in isolate)

---

## Epic 9: Data Migration & Client Cutover

All 3 existing clients migrated from monolithic public schema to kernel/shared/retail multi-schema architecture with zero data loss. Old endpoint proxies removed, cleanup completed.

### Story 9.1: Migration Scripts & Dry Run Validation

As a platform administrator,
I want migration scripts that move all data from public schema to kernel/shared/retail with rollback capability,
So that we can validate the migration on a cloned database before touching production.

**Acceptance Criteria:**

**Given** the complete multi-schema architecture is deployed (Epics 1-8)
**When** the migration script runs on a cloned production database
**Then** all data is moved: tenants → kernel.tenants, org_members → kernel.organization_members, products → shared.catalog_items + retail.retail_products, orders → shared.transactions + retail.retail_sales, customers → shared.contacts, stock_movements → shared.stock_movements, pos_sessions → retail.pos_sessions

**Given** the migration script completes
**When** row counts are compared (source vs destination)
**Then** every table has identical row counts with zero data loss
**And** referential integrity is verified across all FK relationships

**Given** a migration step fails
**When** the rollback is triggered
**Then** the database returns to its pre-migration state — old tables are intact, new tables are dropped

**Given** the dry run passes on the cloned database
**When** the migration report is generated
**Then** it shows: tables migrated, row counts, FK integrity status, estimated production migration time, and any warnings

### Story 9.2: Production Cutover & Cleanup

As a platform administrator,
I want to execute the production migration for all 3 clients with minimal downtime and then clean up the old schema,
So that the platform is fully on the new architecture with no legacy code remaining.

**Acceptance Criteria:**

**Given** the dry run has been validated and the 1-2 day maintenance window is scheduled
**When** the production migration is executed for all 3 tenants
**Then** all data is migrated to the new schema with zero data loss
**And** the migration completes within the maintenance window

**Given** the production migration is complete
**When** the backend is restarted with the new configuration
**Then** all new endpoints (`/api/v1/*`) are active and functional
**And** old proxy endpoints are still active as a safety net

**Given** all 3 clients are verified working on the new architecture
**When** the cleanup phase executes
**Then** the old PosModule, PosService, and proxy endpoints are removed
**And** the old `public` schema tables that were migrated are dropped
**And** the codebase contains only kernel/, shared/, retail/ module structure

**Given** the cleanup is complete
**When** a full regression test runs
**Then** all existing functionality works identically: POS sales, sessions, stock movements, customers, sync, reports
**And** the Prisma schema only references kernel, shared, and retail schemas

**Given** the new APK is distributed to all 3 clients
**When** the clients update their devices
**Then** the frontend communicates exclusively with new endpoints
**And** sync resumes seamlessly with zero data loss from the transition period

---

## Epic 14: UI Polish — Design System & Conformité UX

Mise en conformité complète de l'interface Flutter avec le design system Scalario : palette 60-30-10, typographie, espacement, boutons tactiles (Fitts), responsive (breakpoints compact/medium/expanded), labels en français, et accessibilité WCAG AA. Epic bloquant pour tout démo client ou lancement commercial.

### Story 14.1: Fix Compile Errors — POS Providers

As a developer,
I want the 3 pre-existing compile errors in pos_providers.dart and related files fixed,
So that the app builds cleanly before any UI work begins.

**Acceptance Criteria:**

**Given** the current state of `pos_providers.dart` and dependent files
**When** `flutter build` or `flutter analyze` is run
**Then** zero compile errors are reported for the POS provider files

**Given** the `RealtimeService`, `RetentionService`, and related imports
**When** the provider wiring is resolved
**Then** all providers instantiate without type mismatches or missing constructors

**Given** the fix is applied
**When** the POS screen and dashboard screens are navigated
**Then** all screens load without runtime provider exceptions

**Notes:**
- Check `RealtimeService(supabase, syncService, ref)` constructor signature
- Check `RetentionService(isarService)` constructor signature
- Run `flutter analyze` to surface all errors before fixing

---

### Story 14.2: ThemeData Centralisé — Design System Setup

As a developer,
I want a centralized `AppTheme` with `ThemeData`, `ColorScheme`, and `TextTheme` matching the Scalario design system,
So that all screens use a single source of truth for colors, typography, and component defaults.

**Acceptance Criteria:**

**Given** the design system palette (60-30-10 rule)
**When** `AppTheme.light()` is applied at the `MaterialApp` level
**Then** all screens inherit:
- Primary: `#1565C0`
- Background: `#F5F5F5`
- Surface: `#FFFFFF`
- Error: `#C62828`
- OnPrimary: `#FFFFFF`
- Text primary: `#212121`
- Text secondary: `#757575`

**Given** the typography scale from the design system
**When** `AppTheme.textTheme` is defined
**Then** it provides:
- `displayMedium`: 22sp / Bold (titre principal)
- `titleLarge`: 18sp / SemiBold (titre section)
- `titleMedium`: 16sp / SemiBold (titre carte)
- `bodyMedium`: 14sp / Regular
- `bodySmall`: 12sp / Regular / `#757575`
- `labelSmall`: 11sp / Medium / `#757575` (uppercase)
- `headlineLarge`: 20sp / Bold / Monospace (prix)

**Given** the component defaults
**When** `ElevatedButton` is used anywhere in the app
**Then** it uses primary blue background, white text, minimum height 48px

**Given** the `FilledButton` (primary CTA — Encaisser)
**When** defined in `AppTheme`
**Then** it uses `#1565C0` background, minimum height 56px

**Given** the app starts
**When** `MaterialApp(theme: AppTheme.light())` is set
**Then** no screen uses hardcoded `Colors.teal`, `Colors.blue`, `Colors.green`, `Colors.purple`, `Colors.grey` — all resolved via `Theme.of(context).colorScheme`

**Files to create/modify:**
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/main.dart` — apply `AppTheme.light()`

---

### Story 14.3: Refactor Écran POS

As a cashier (Fatou),
I want the POS screen and its widgets to look professional and feel easy to use on a tablet,
So that I can serve customers quickly without confusion.

**Acceptance Criteria:**

**Given** the POS screen (`pos_screen.dart`)
**When** it renders
**Then** the AppBar title shows the active shop name (from `userProfile`) instead of "Scalario POS"
**And** all action icons have French tooltips ("Scanner code-barres", "Fermer la session")
**And** the layout uses `LayoutBuilder` with breakpoints:
  - `< 600px` → stacked (product grid full width, cart = FAB badge + separate screen)
  - `≥ 600px` → Row split (product grid 60% | cart panel 40%)

**Given** the cart panel (`cart_panel.dart`)
**When** it renders on tablet (≥ 600px)
**Then** the panel width is `max(320px, 35% of screen width)` — not hardcoded 350px
**And** the header title reads "Vente en cours" (French)
**And** cart items show: product name (bodyMedium), quantity × price in monospace, total in monospace bold
**And** the discount text is at least 13sp (not 12sp)
**And** the "remove" icon is wrapped in a 48×48 touch target (Fitts)
**And** the currency symbol uses FCFA notation (or configured currency — `CurrencyFormatter`)
**And** all hardcoded colors replaced with `Theme.of(context).colorScheme.*`

**Given** the "PAY & PRINT" button (primary CTA)
**When** it renders
**Then** it is labeled "ENCAISSER" (French)
**And** its height is ≥ 56px (Fitts — largest element in the panel)
**And** it uses `colorScheme.primary` background

**Given** the "HOLD" button
**When** it renders
**Then** it is labeled "METTRE EN ATTENTE" or "RETENIR" (French)

**Given** the payment method dropdown
**When** rendered
**Then** method names are translated: CASH→"Espèces", MOBILE_MONEY→"Mobile Money", CARD→"Carte", CREDIT→"Crédit", SPLIT→"Paiement mixte"

**Given** the product grid (`product_grid.dart`)
**When** it renders
**Then** `crossAxisCount` adapts: 2 cols `< 600px`, 3 cols `600–1024px`, 5 cols `> 1024px`
**And** loading state shows a shimmer skeleton (not `CircularProgressIndicator`)
**And** empty state shows: icon + "Aucun produit trouvé" + button "Ajouter un produit"
**And** product card icon uses `colorScheme.primary` (not teal)
**And** category chips use `colorScheme.primaryContainer` when selected

**Given** the close session dialog (`pos_screen.dart` `_showCloseSessionDialog`)
**When** triggered
**Then** all text is in French: "Fermer la session", "Comptez l'argent en caisse", "Montant physique", "Annuler", "Suivant"

**Given** the session report dialog (`session_report_dialog.dart`)
**When** rendered
**Then** all labels are in French: "Résumé de session (Rapport Z)", "Ventes par mode", "Réconciliation caisse", "Solde d'ouverture", "Caisse théorique", "Compte physique", "Écart", "Retour", "Imprimer rapport Z", "Confirmer la fermeture"

**Given** the receipt dialog (`receipt_dialog.dart`)
**When** rendered
**Then** labels are French: "Reçu", "Numéro:", "Date:", "TOTAL:", "Paiement:", "Merci pour votre achat !", "OK", "Imprimer"
**And** date format is `dd/MM/yyyy HH:mm`

**Given** the sync status indicator
**When** rendered
**Then** tooltips are French: "En ligne & synchronisé", "Synchronisation...", "Erreur de synchronisation", "Hors ligne"

**Given** the customer selection dialog
**When** rendered
**Then** labels are French: "Sélectionner un client", "Rechercher par nom ou téléphone", "Aucun client trouvé", "NOUVEAU CLIENT"

**Given** the discount dialog
**When** rendered
**Then** labels are French: "Remise :", "Montant", "Type :", "Annuler", "Appliquer"

---

### Story 14.4: Refactor Dashboard & Écrans Back-Office

As a manager (Moussa) or owner (Blandine),
I want the dashboard and back-office screens to match the design system and be usable on tablet and desktop,
So that I can manage the business without visual clutter or confusion.

**Acceptance Criteria:**

**Given** the dashboard shell (`dashboard_shell.dart`)
**When** it renders on a phone (width < 600px)
**Then** a `BottomNavigationBar` (max 5 items) replaces the `NavigationRail`
**And** the rail is only shown for width ≥ 600px

**Given** the NavigationRail is shown (width ≥ 600px)
**When** it renders
**Then** it is `extended: true` when width ≥ 1024px (not 1200px — matches design system breakpoint)
**And** destination labels are French: "Aperçu", "Inventaire", "Catégories", "Clients", "Historique stock", "Rapports", "Paramètres"
**And** the whole shell is wrapped in `SafeArea`
**And** branch name label is at least 12sp

**Given** the "Open POS" and "Logout" icon buttons in the rail trailing
**When** rendered
**Then** tooltips are French: "Ouvrir la caisse", "Se déconnecter"

**Given** the Overview screen (`dashboard_screen.dart`)
**When** it renders
**Then** the greeting is French: "Bon retour !" or "Bonjour, {prénom} !"
**And** the date picker button label is French: "7 derniers jours" / "dd/MM – dd/MM"
**And** KPI card titles are French: "Chiffre d'affaires", "Nb commandes", "Ticket moyen"
**And** the chart title is French: "Évolution des ventes (7 derniers jours)"
**And** the "Active Terminals" section is French: "Terminaux actifs"
**And** on phone (< 600px), KPI cards stack vertically (not Row)
**And** loading state uses skeleton shimmer (not CircularProgressIndicator)
**And** hardcoded `Colors.green`, `Colors.blue`, `Colors.purple`, `Colors.teal` replaced with `colorScheme` tokens

**Given** the Inventory screen (`inventory_screen.dart`)
**When** it renders
**Then** the AppBar title is "Gestion des stocks"
**And** the search hint is "Rechercher par nom ou code-barres…"
**And** the "Add Product" button is "Ajouter un produit"
**And** DataTable columns are French: "Nom", "Code-barres", "Prix", "Stock", "Actions"
**And** on width < 900px, the DataTable is replaced by a card list (responsive)
**And** action IconButtons in table rows are wrapped in 48×48 touch targets (Fitts)
**And** delete confirmation dialog text is French: "Supprimer ce produit ?", "Êtes-vous sûr…", "Annuler", "Supprimer"

**Given** the Customers screen (`customers_screen.dart`)
**When** it renders
**Then** AppBar title is "Gestion des clients"
**And** search hint is "Rechercher un client…"
**And** "SETTLE DEBT" button is "RÉGLER LA DETTE" and uses `colorScheme.primary` (not teal)
**And** "Balance:" label is "Solde :"
**And** empty state shows icon + "Aucun client trouvé" + "Ajouter un client" button

**Given** the Reports screen (`reports_screen.dart`)
**When** it renders
**Then** AppBar title is "Rapports détaillés"
**And** section titles are French: "Ventes par produit", "Ventes par mode de paiement"
**And** date picker shows "Toute la période"
**And** date format is `dd/MM`
**And** pie chart colors use design system palette (not `Colors.primaries`)
**And** DataTable columns are French: "Produit", "Qté", "Chiffre d'affaires"

**Given** the Categories screen (`categories_screen.dart`)
**When** it renders
**Then** AppBar title is "Gestion des catégories"
**And** empty state shows icon + "Aucune catégorie" + "Créer une catégorie" button
**And** add dialog title is "Ajouter une catégorie", field label "Nom de la catégorie", buttons "Annuler" / "Ajouter"
**And** delete dialog text is "Supprimer cette catégorie ?" with "Annuler" / "Supprimer"

**Given** the Stock History screen (`stock_history_screen.dart`)
**When** it renders
**Then** AppBar title is "Historique des stocks"
**And** date format uses French month names (`dd MMM` with locale `fr`)
**And** empty state shows icon + "Aucun mouvement de stock"
**And** date label text is at least 12sp (not 10sp)

**Given** the Product Form dialog (`product_form_dialog.dart`)
**When** it renders
**Then** title is "Modifier le produit" / "Nouveau produit"
**And** field labels are French: "Nom du produit *", "Prix *", "Stock initial", "Catégorie", "Code-barres"
**And** validation messages are French: "Requis", "Nombre invalide"
**And** buttons are "Annuler" / "Mettre à jour" / "Créer"

**Given** the Settle Debt dialog (`settle_debt_dialog.dart`)
**When** it renders
**Then** title is "Régler la dette — {nom}"
**And** labels are French: "Solde actuel :", "Montant du règlement"
**And** buttons are "ANNULER" / "RÉGLER"
**And** button color uses `colorScheme.primary` (not teal)

---

### Story 14.5: Refactor Écran de Connexion

As a new user opening the app for the first time,
I want a clean, professional login screen with French labels and proper branding,
So that I immediately trust the product.

**Acceptance Criteria:**

**Given** the login screen (`login_screen.dart`)
**When** it renders
**Then** the "Scalario" text is replaced (or complemented) with a proper logo widget (`ScalarioLogo`) using the design system primary color
**And** below the logo, a subtitle reads "Gérez votre boutique, partout." in `bodyMedium` / `#757575`
**And** the email field label is "Adresse email"
**And** the password field label is "Mot de passe"
**And** the password field has a visibility toggle icon (show/hide)
**And** a "Mot de passe oublié ?" `TextButton` appears below the password field (leads to placeholder for now)
**And** the "Sign In" button is labeled "Se connecter" with height ≥ 56px (Fitts)
**And** the background uses `colorScheme.background` (`#F5F5F5`) — not plain white
**And** error snackbars display French messages (pass through Supabase `e.message` — already shows in French if locale is set)
**And** the form container max-width stays at 400px (desktop centering preserved)

---

### Story 14.6: Responsive Breakpoints — Layouts Adaptatifs

As any user (cashier on tablet, owner on phone, manager on desktop),
I want the app to adapt its layout based on screen size,
So that every platform (tablet, phone, desktop) has an optimal experience.

**Acceptance Criteria:**

**Given** the app runs on a phone (width < 600px)
**When** any list screen (Inventory, Customers, Stock History) is displayed
**Then** DataTables are replaced by scrollable card lists (each row = 1 card)
**And** form dialogs use full-screen modals (not AlertDialog)
**And** the bottom navigation bar is visible (not the NavigationRail)

**Given** the POS screen on phone (< 600px)
**When** displayed
**Then** the product grid occupies full width (2 columns)
**And** a floating cart badge button ("🛒 Panier (3)") appears bottom-right showing item count
**And** tapping the cart badge navigates to the full-screen cart view
**And** back from cart returns to the product grid

**Given** the POS screen on tablet (600–1024px)
**When** displayed
**Then** the split layout (product grid | cart panel) is shown as described in the design system
**And** the cart panel is always visible (no FAB needed)

**Given** the POS screen on desktop (> 1024px)
**When** displayed
**Then** the NavigationRail is expanded with labels
**And** the product grid shows 5 columns
**And** the cart panel shows customer history section as per design system

**Given** a `LayoutBuilder` is used in each adaptive screen
**When** the breakpoints are defined
**Then** they follow the design system constants:
- `kCompactBreakpoint = 600.0`
- `kMediumBreakpoint = 1024.0`
**And** a shared `AppBreakpoints` class in `lib/core/theme/` exports these constants

**Given** the dashboard KPI cards on phone
**When** width < 600px
**Then** the 3 stat cards stack vertically (Column) instead of Row

**Given** the Inventory DataTable on medium screens (600–900px)
**When** rendered
**Then** it switches to a card list to avoid horizontal overflow

**Notes:**
- Create `lib/core/theme/app_breakpoints.dart` with `kCompactBreakpoint`, `kMediumBreakpoint`
- Use `LayoutBuilder` in `PosScreen`, `DashboardShell`, `OverviewScreen`, `InventoryScreen`
- Phone cart = separate route, tablet/desktop = side panel


---

## Epic 10: SDUI Foundation & Engine

A Server-Driven UI (SDUI) engine that allows layout definitions to be served from the backend as JSON, enabling dynamic rendering of screens per `business_type` without Flutter code changes. The first SDUI layout converts the existing Retail POS screen to JSON-driven rendering. Story 10.0 is a prerequisite: compile errors must be fixed before any new development.

**Phase:** 1 (after Epics 1–6 done)
**FRs covered:** FR13 (UI-Driven Engine dynamic layer)
**Prerequisite:** Epics 1–6 complete + Epic 14 Story 14.2 (AppTheme tokens in place)

### Story 10.0: Fix Compile Errors — SyncService, categoriesProvider, ReceiptDialog

As a developer,
I want the existing compile errors in `pos_providers.dart`, `product_grid.dart`, and `cart_panel.dart` fixed,
So that the app builds cleanly and all subsequent SDUI work can proceed on a stable base.

**Acceptance Criteria:**

**Given** the `SyncService` constructor call in `pos_providers.dart` (`syncServiceProvider` block)
**When** `flutter analyze` is run
**Then** the 5-argument call `SyncService(orderRepo, productRepo, sessionRepo, customerRepo, categoryRepo)` matches the actual constructor signature in `lib/core/services/sync_service.dart`
**And** if the constructor signature has changed (e.g. parameter added/removed after schema migration), the call is updated accordingly

**Given** `categoriesProvider` referenced in `product_grid.dart` (line 13) via `ref.watch(categoriesProvider)`
**When** the file is analyzed
**Then** the provider is correctly exported and importable from `category_repository.dart`
**And** the import line in `product_grid.dart` resolves without "undefined identifier" error

**Given** `cart_panel.dart` calls `ReceiptDialog(order: order)` and also calls `_showPostCheckoutDialog`
**When** the file is analyzed
**Then** `ReceiptDialog` is imported from `package:frontend/features/pos/presentation/widgets/receipt_dialog.dart`
**And** there is no duplicate receipt dialog trigger (both `showDialog(ReceiptDialog)` and `_showPostCheckoutDialog` firing for the same checkout)

**Given** all errors are resolved
**When** `flutter build windows` or `flutter build apk` is run
**Then** exit code 0, zero compile errors across all three files

**Notes:**
- Run `flutter analyze` first to capture the exact error list — may surface additional issues
- Do NOT refactor beyond fixing errors: no translation, no style changes, no logic changes

---

### Story 10.1: Design System Theme Tokens

As a developer,
I want a centralized `AppTheme` file encoding every design system token from `docs/design-system.md`,
So that all screens adopt correct colors, typography, and component defaults automatically.

**Acceptance Criteria:**

**Given** the 60-30-10 color palette in `docs/design-system.md`
**When** `lib/core/theme/app_theme.dart` is created
**Then** it exports an `AppColors` class with static `const Color` values:
- `primary = Color(0xFF1565C0)` — Bleu confiance (10% accent)
- `success = Color(0xFF2E7D32)` — Vert
- `error = Color(0xFFC62828)` — Rouge
- `warning = Color(0xFFF9A825)` — Jaune
- `surface = Color(0xFFFFFFFF)` — Surfaces
- `background = Color(0xFFF5F5F5)` — Fond app (60%)
- `textPrimary = Color(0xFF212121)` — Texte principal
- `textSecondary = Color(0xFF757575)` — Texte léger
- `border = Color(0xFFE0E0E0)` — Bordures

**Given** the typography hierarchy in `docs/design-system.md`
**When** `AppTheme.textTheme` is built
**Then** it defines 8 text styles mapped to Flutter's `TextTheme` slots:
- `displayMedium` → 22sp Bold `#212121` (titre principal)
- `titleLarge` → 18sp SemiBold `#212121` (titre section)
- `titleMedium` → 16sp SemiBold `#212121` (titre carte)
- `bodyMedium` → 14sp Regular `#212121` (corps)
- `bodySmall` → 12sp Regular `#757575` (corps petit)
- `labelSmall` → 11sp Medium `#757575` (étiquette)
- `headlineLarge` → 20sp Bold monospace `#212121` (prix)
- `headlineMedium` → 18sp Bold monospace `#212121` (quantité)

**Given** component defaults required by the design system (Fitts — min 48dp)
**When** `AppTheme.light()` is constructed
**Then** `ElevatedButtonThemeData` has `minimumSize: Size(64, 48)`
**And** `FilledButtonThemeData` has `minimumSize: Size(88, 56)` (primary CTA)
**And** `InputDecorationTheme` uses `OutlineInputBorder` with `AppColors.border`
**And** `CardTheme` sets `elevation: 0`, `borderRadius: 12`, side `AppColors.border`

**Given** the theme is registered
**When** `lib/main.dart` is modified
**Then** `MaterialApp(theme: AppTheme.light())` is set — single line change

**Files to create:**
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_breakpoints.dart` — exports `kCompact = 600.0`, `kMedium = 1024.0`

**Files to modify:**
- `lib/main.dart` — `theme: AppTheme.light()`

**Scope constraint:** Zero screen/widget files are modified. Theme tokens only.

---

### Story 10.2: SDUI JSON Schema Definition

As a developer,
I want a documented JSON schema for describing screen layouts per `business_type`,
So that backend and frontend have a shared contract before building either side.

**Acceptance Criteria:**

**Given** the need to describe adaptive screen layouts
**When** `docs/sdui-schema.md` is committed
**Then** it documents the following top-level schema:
```json
{
  "version": "1",
  "business_type": "retail",
  "screen": "pos",
  "layout": {
    "type": "split_view",
    "breakpoints": {
      "compact":  { "type": "stacked_with_fab_cart" },
      "medium":   { "type": "horizontal_split", "left_flex": 2, "right_flex": 1 },
      "expanded": { "type": "horizontal_split", "left_flex": 3, "right_flex": 1 }
    },
    "panels": {
      "product_grid": {
        "type": "product_grid",
        "columns": { "compact": 2, "medium": 3, "expanded": 5 },
        "show_categories": true,
        "show_search": true
      },
      "cart": {
        "type": "cart_panel",
        "primary_action": {
          "type": "filled_button",
          "label": "ENCAISSER",
          "action": "checkout",
          "min_height": 56
        },
        "payment_methods": ["CASH", "MOBILE_MONEY", "CARD", "CREDIT", "SPLIT"]
      }
    }
  }
}
```

**Given** the schema must support the dashboard screen
**When** the schema docs describe `retail.dashboard`
**Then** it covers: `kpi_cards` (array with icon, label, value_provider), `line_chart` (data_provider, title), `terminal_status_list`

**Given** parsing unknown widget types
**When** a JSON layout has `"type": "unknown_widget_xyz"`
**Then** the schema documents that this renders a `SduiPlaceholder` — never crashes

**Deliverable:**
- `docs/sdui-schema.md` with field documentation
- `apps/backend/src/sdui/layouts/retail.pos.json` (first real layout)
- `apps/backend/src/sdui/layouts/retail.dashboard.json`

---

### Story 10.3: SDUI Backend Layout Service

As a backend developer,
I want a NestJS `SduiModule` that serves layout JSON based on the tenant's `business_type`,
So that the Flutter app can fetch its screen configuration dynamically at startup.

**Acceptance Criteria:**

**Given** an authenticated tenant with `business_type = 'retail'` calls `GET /api/v1/sdui/layout?screen=pos`
**When** the request hits `SduiController`
**Then** the response is HTTP 200 with `retail.pos.json` content
**And** the response header includes `ETag` (MD5 of layout content) for client-side cache validation

**Given** tenant context is available via the guard chain
**When** `SduiController` processes the request
**Then** it reads `tenant.business_type` from `KernelTenantService` (already available from Epic 1)
**And** delegates to `SduiService.getLayout(businessType, screen)`

**Given** `SduiService` starts up
**When** NestJS bootstraps
**Then** all `.json` files in `apps/backend/src/sdui/layouts/` are loaded into an in-memory `Map<string, object>`
**And** the map key is `{business_type}.{screen}` (e.g., `retail.pos`)

**Given** an unknown combination is requested
**When** `SduiService.getLayout` is called
**Then** it throws `NotFoundException` with message `"Layout introuvable pour ce type de commerce"`

**Files to create:**
- `apps/backend/src/sdui/sdui.module.ts`
- `apps/backend/src/sdui/sdui.controller.ts`
- `apps/backend/src/sdui/sdui.service.ts`
- `apps/backend/src/sdui/layouts/retail.pos.json`
- `apps/backend/src/sdui/layouts/retail.dashboard.json`
- Register `SduiModule` in `apps/backend/src/app.module.ts`

---

### Story 10.4: SDUI Flutter Renderer Engine

As a Flutter developer,
I want a generic widget renderer that converts a parsed `SduiLayout` into a Flutter widget tree,
So that any screen can be driven by server-provided JSON without hardcoded widget hierarchies.

**Acceptance Criteria:**

**Given** a `SduiLayout` object is parsed from JSON
**When** `SduiRenderer(layout: layout).build(context)` is called
**Then** it produces the correct `Widget` hierarchy for the top-level layout type

**Given** the `SduiWidgetRegistry` is initialized at app startup
**When** the renderer encounters `"type": "product_grid"`
**Then** it renders the registered `ProductGrid` widget with props from JSON
**And** for `"type": "cart_panel"` → `CartPanel` widget
**And** for `"type": "split_view"` → `LayoutBuilder` with `kCompact`/`kMedium` breakpoints
**And** for `"type": "stacked_with_fab_cart"` → full-width product grid + floating cart badge

**Given** `sduiLayoutProvider(screen: 'pos')` is defined
**When** a screen watches this provider
**Then** it first returns a cached layout from `SharedPreferences` (key: `sdui_layout_pos`, TTL: 1 hour)
**And** refetches in background after TTL expires (stale-while-revalidate)
**And** if fetch fails (offline), cached layout is used without throwing

**Given** an unknown widget type is encountered
**When** the renderer processes it
**Then** it renders `SizedBox.shrink()` — fails silently, logs in debug mode

**Files to create:**
- `lib/core/sdui/sdui_layout.dart` — models: `SduiLayout`, `SduiPanel`, `SduiAction`
- `lib/core/sdui/sdui_renderer.dart` — `SduiRenderer` StatelessWidget
- `lib/core/sdui/sdui_widget_registry.dart` — type-string to factory function map
- `lib/core/sdui/sdui_providers.dart` — `sduiLayoutProvider(screen)` FutureProvider
- `lib/core/services/sdui_service.dart` — HTTP GET + SharedPreferences cache

---

### Story 10.5: Retail POS Layout — Premier Layout SDUI

As a developer,
I want the Retail POS screen to use the SDUI renderer for its top-level layout,
So that the POS is the first validated proof-of-concept for the full SDUI stack (10.0 → 10.4).

**Acceptance Criteria:**

**Given** the SDUI engine from Story 10.4 is in place
**When** `PosScreen` is updated
**Then** it watches `sduiLayoutProvider(screen: 'pos')`
**And** delegates layout assembly to `SduiRenderer(layout: layout)`
**And** `ProductGrid` and `CartPanel` are rendered by the SDUI engine via the widget registry

**Given** the `retail.pos.json` layout specifies `horizontal_split` for medium/expanded
**When** the POS renders on a tablet (width ≥ 600px)
**Then** it shows product grid (left, flex 2) and cart panel (right, flex 1) — matching current behavior

**Given** the layout specifies `stacked_with_fab_cart` for compact
**When** the POS renders on a phone (width < 600px)
**Then** product grid occupies full width (2 columns)
**And** a floating cart badge button (bottom-right, 56dp) shows item count
**And** tapping navigates to the full-screen cart view

**Given** the device is offline at POS startup
**When** the SDUI layout cannot be fetched
**Then** the POS falls back to the hardcoded default layout (current `Row` split)
**And** the fallback is defined as a constant `SduiLayout.retailPosDefault()` in `sdui_layout.dart`

**Given** the layout JSON changes on the backend (e.g., `left_flex: 3`)
**When** the Flutter app restarts (or cache TTL expires)
**Then** the new layout is applied without a new APK release

**Notes:**
- `ProductGrid` and `CartPanel` widget internals are NOT changed in this story
- Only `PosScreen`'s layout-assembly code is replaced with SDUI rendering
- Validate on tablet emulator AND phone emulator before marking done

---

## Epic 16: Retail Operations — Gestion Stock Terrain

**Objectif :** Câbler les 4 opérations stock terrain de Moussa (gestionnaire) côté frontend Flutter. Le backend (Epic 5) expose déjà tous les endpoints nécessaires (288 tests NestJS verts). Il manque les écrans Flutter, l'intégration dans la navigation, et le support offline.

**Phase :** 1 (après Epic 15)
**FRs couverts :** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36
**Prérequis :** Epics 1–9 (backend inventory opérationnel), Epic 15 (DashboardShell + navigation stable)

### Endpoints backend existants (à consommer)

| Endpoint | Méthode | RBAC | Usage |
|----------|---------|------|-------|
| `/inventory/movements` | POST | owner, manager | DELIVERY / LOSS / TRANSFER_OUT |
| `/inventory/movements/confirm` | POST | owner, manager, commercial | Confirmation TRANSFER_IN |
| `/inventory/adjust` | POST | owner, manager | Inventaire partiel (ADJUSTMENT signé) |
| `/inventory/stock` | GET | tous | Stock actuel par catalogItemId |
| `/inventory/movements` | GET | tous | Historique mouvements (filtres: tenantId, since, referenceId) |

### Types de mouvements (backend)

`DELIVERY` · `TRANSFER_OUT` · `TRANSFER_IN` · `LOSS` · `ADJUSTMENT` · `SALE` (auto)

### Story 16.1: Réception livraison fournisseur

As a manager (Moussa),
I want to record a supplier delivery with received quantities,
So that stock is credited and variances are traced (FR29, FR30).

**Acceptance Criteria:**

**AC1 — Formulaire réception :**
- Sélection du produit (recherche dans le catalogue)
- Champ quantité reçue (obligatoire, entier > 0)
- Champ notes/variance (optionnel)
- Bouton "Valider la réception"

**AC2 — Appel API :**
- Submit → `POST /inventory/movements` body `{type: "DELIVERY", catalogItemId, quantity, reason?, tenantId}`
- En cas de succès → snackbar "Réception enregistrée" + retour à l'écran précédent
- En cas d'erreur → snackbar rouge avec message d'erreur

**AC3 — Feedback visuel :**
- Loading indicator pendant l'appel
- Formulaire désactivé pendant l'envoi (évite double-soumission)

**AC4 — Test :**
- Soumettre une réception → `InventoryMovement.type == 'DELIVERY'` créé avec la bonne quantité
- Widget test vérifie que le formulaire est présent et soumissible

**Notes dev :**
- Rôle requis : owner ou manager (backend enforced — pas de vérification frontend nécessaire sauf cacher le bouton)
- `catalogItemId` = `product.remoteId` (champ existant sur le modèle Product Flutter)
- Réutiliser le pattern ProductFormDialog pour la sélection produit

---

### Story 16.2: Transfert stock magasin → rayon

As a manager (Moussa) and a commercial (Fatou),
I want to declare a stock transfer out and confirm reception,
So that the chain of custody is maintained with automatic variance tracking (FR31, FR32, FR33).

**Acceptance Criteria:**

**AC1 — Formulaire déclaration sortie (gestionnaire) :**
- Sélection produit + quantité déclarée
- Submit → `POST /inventory/movements` body `{type: "TRANSFER_OUT", catalogItemId, quantity, reason?, tenantId}`
- Retourne un `referenceId` (UUID) à conserver pour la confirmation

**AC2 — Affichage en attente de confirmation :**
- Après TRANSFER_OUT créé → écran ou card "Transfert en attente de confirmation"
- Affiche : produit, quantité déclarée, referenceId, date

**AC3 — Formulaire confirmation (récepteur) :**
- Champ quantité effectivement reçue (pré-remplie avec quantité déclarée)
- Submit → `POST /inventory/movements/confirm` body `{referenceId, catalogItemId, quantity, tenantId}`

**AC4 — Variance automatique :**
- Si quantité reçue ≠ quantité déclarée → backend crée `TRANSFER_IN` avec `reason: "Variance: X"`
- Frontend affiche la variance calculée après confirmation

**AC5 — Test :**
- Flux complet (TRANSFER_OUT + confirm) → 2 InventoryMovements créés
- Test variance : déclaré 10, reçu 8 → variance = 2 dans le reason

**Notes dev :**
- RBAC : TRANSFER_OUT = owner/manager ; confirmation = owner/manager/commercial
- `referenceId` transmis via state local (StateProvider) entre les deux écrans

---

### Story 16.3: Déclaration de pertes

As a manager or commercial,
I want to declare a stock loss with a mandatory reason,
So that shrinkage is traced and attributed (FR34).

**Acceptance Criteria:**

**AC1 — Formulaire déclaration :**
- Sélection produit + quantité perdue (entier > 0)
- Motif obligatoire — dropdown : Casse · Péremption · Vol · Frotte · Autre
- Si "Autre" → champ texte libre obligatoire
- Bouton "Déclarer la perte"

**AC2 — Validation frontend :**
- Motif non sélectionné → erreur inline "Motif obligatoire"
- Quantité ≤ 0 → erreur inline "Quantité invalide"

**AC3 — Appel API :**
- Submit → `POST /inventory/movements` body `{type: "LOSS", catalogItemId, quantity, reason, tenantId}`
- Backend valide : `reason` obligatoire pour LOSS (BadRequestException si absent)
- En cas de succès → snackbar "Perte déclarée"

**AC4 — Test :**
- Soumettre sans motif → snackbar erreur (validation frontend) + pas d'appel API
- Soumettre avec motif → `InventoryMovement.type == 'LOSS'` créé
- Widget test vérifie les 4 options du dropdown

**Notes dev :**
- RBAC backend : owner/manager uniquement pour `POST /inventory/movements`
- Discordance PRD vs backend : FR34 dit "commercial peut déclarer", mais le backend n'autorise que owner/manager. À aligner en Epic 17 (ou via endpoint dédié). Pour cette story, implémenter avec les contraintes backend actuelles.
- Motifs labels FR : "Casse", "Péremption", "Vol", "Frotte", "Autre"

---

### Story 16.4: Inventaire partiel

As a manager (Moussa),
I want to perform a partial inventory count with variance signal,
So that discrepancies between physical and system stock are identified and corrected (FR35).

**Acceptance Criteria:**

**AC1 — Sélection produits à compter :**
- Multi-sélection depuis le catalogue (checkbox ou tap)
- Minimum 1 produit requis pour démarrer l'inventaire

**AC2 — Feuille de comptage :**
- Pour chaque produit sélectionné : nom, stock système (issu de `GET /inventory/stock`), champ quantité physique comptée
- Signal visuel : vert si physique == système, rouge si écart

**AC3 — Motif :**
- Si au moins un produit a un écart → champ motif global obligatoire (ex. "Inventaire mensuel janvier")

**AC4 — Soumission :**
- Pour chaque produit avec écart → `POST /inventory/adjust` body `{catalogItemId, countedQuantity, reason, tenantId}`
- Produits sans écart ignorés (backend retourne `{adjusted: false}` — éviter appel inutile)
- Résumé en fin : "X produits ajustés, Y sans écart"

**AC5 — Test :**
- Compter 1 produit avec écart → `InventoryMovement.type == 'ADJUSTMENT'` créé avec quantité signée
- Compter 1 produit sans écart → pas d'appel API (ou appel retourne `adjusted: false`)
- Widget test vérifie le signal couleur (vert/rouge)

**Notes dev :**
- `POST /inventory/adjust` calcule la variance côté backend : `variance = countedQuantity - currentStock`
- La quantité du mouvement ADJUSTMENT est signée (positive = surplus, négative = déficit)
- `GET /inventory/stock?catalogItemId=X&tenantId=Y` pour afficher le stock système en temps réel

---

### Story 16.5: Hub Inventaire — Navigation intégrée

As a manager using the backoffice,
I want a unified inventory hub with tabs for all stock operations,
So that all 4 terrain operations are one tap away from the Inventaire nav item (AC intégration navigation).

**Acceptance Criteria:**

**AC1 — Structure tabbed :**
- L'écran Inventaire (nav item existant) devient un hub avec `TabBar` ou `NavigationBar` :
  - **Produits** — écran existant `InventoryScreen` (catalogue + pagination)
  - **Réceptions** — formulaire 16-1 + liste des réceptions récentes
  - **Transferts** — formulaire 16-2 + liste des transferts en attente
  - **Pertes** — formulaire 16-3 + liste des pertes récentes
  - **Inventaire** — écran 16-4

**AC2 — Labels français, AppTheme :**
- Tous les labels en français, couleurs AppTheme, FCFA où applicable

**AC3 — Liste récente par onglet :**
- Chaque onglet affiche une liste des 20 derniers mouvements du type concerné
- Source : `GET /inventory/movements?tenantId=&limit=20` filtré par type

**AC4 — Raccourci dashboard :**
- La card "Stock faible" du dashboard (KpiCardGrid) navigue vers l'onglet Réceptions

**AC5 — Test :**
- Widget test : TabBar présent avec 5 onglets
- Navigation entre onglets ne déclenche pas d'erreur

**Notes dev :**
- Réutiliser `DefaultTabController` + `TabBar` + `TabBarView`
- Les 4 nouveaux écrans (16-1 à 16-4) sont des widgets intégrés dans les `TabBarView` — pas de screens séparés dans la navigation principale

---

### Story 16.6: Sync offline pour les opérations stock

As a manager or commercial working offline,
I want stock operations to be saved locally and synced when connectivity returns,
So that terrain work is never lost (FR36, NFR30).

**Acceptance Criteria:**

**AC1 — Modèle Isar `InventoryMovementLocal` :**
- Champs : `id` (Isar auto), `remoteId` (String?), `catalogItemId`, `quantity`, `type`, `reason`, `tenantId`, `referenceId` (pour transferts), `status` (pending/synced/failed), `createdAt`
- Fichier : `apps/frontend/lib/features/pos/data/models/inventory_movement.dart` + `.g.dart`

**AC2 — Repository `InventoryRepository` :**
- `saveLocal(movement)` — écriture Isar
- `getPending()` — mouvements avec status == pending
- `markSynced(id)` / `markFailed(id)`
- `getMovements({type?, limit?})` — lecture locale pour les listes onglets

**AC3 — Opérations offline :**
- Les 4 formulaires (16-1 à 16-4) sauvegardent d'abord en local (status: pending)
- Si online → appel API immédiat → markSynced
- Si offline → stocké en pending → sync automatique à la reconnexion via `SyncService`

**AC4 — Indicateur outbox :**
- Badge sur l'icône Inventaire dans la navigation si des mouvements pending existent

**AC5 — Test :**
- Créer un mouvement offline (mock SyncService offline) → status == pending dans Isar
- Réactiver la connexion → mouvement synced, status == synced
- Test Isar en mémoire (pas de DB fichier)

**Notes dev :**
- Suivre le pattern existant : `OrderRepository` (Isar + outbox), `SyncService.startSync()`
- Générer `.g.dart` avec `flutter pub run build_runner build`
- Ne pas modifier `SyncService` — ajouter un `InventorySyncAdapter` si l'architecture le prévoit, sinon étendre `SyncService` avec un batch inventory


---

### Epic 18: Lien Session Caisse ↔ Terminal Physique

Le backoffice "État des caisses" affiche désormais **quel terminal physique** porte quelle session ouverte. Chaque appareil (Android, Windows, Linux) génère et persiste une identité stable (`deviceId`). À l'ouverture d'une session caisse, le `deviceId` est transmis au backend et stocké sur `PosSession`. L'écran "État des caisses" résout et affiche le nom du terminal pour chaque session active.

**Phase:** 1 (correctif backoffice pré-Epic 17)
**FRs covered:** FR23, FR24, FR28 (enrichissement — identification terminal physique)
**Prerequisite:** Epics 1–16 (PosSession opérationnel, TerminalStatusList affiche sessions OPEN)

#### Story 18.1: Backend — `deviceId` sur `PosSession`

**As a** platform developer,
**I want** `PosSession` to store the `deviceId` of the physical terminal that opened it,
**So that** backoffice reports can show which device is running which session.

**Acceptance Criteria:**

**Given** the current `PosSession` schema has no `deviceId`
**When** the Prisma migration runs
**Then** `pos_sessions` gains a nullable column `device_id VARCHAR` (not UUID — device IDs are human-readable strings like `"caisse-android-1"`)

**Given** `POST /retail/sessions/open` receives `{ deviceId?: string, ... }`
**When** a session is opened with a `deviceId`
**Then** the session is saved with that `deviceId`; if omitted, `deviceId` is null

**Given** `POST /pos/sessions` (sync endpoint) receives `{ deviceId?: string, ... }`
**When** the sync adapter pushes a session from the device
**Then** `syncSession()` preserves `deviceId` on upsert

**Given** `GET /retail/sessions/active?tenantId=`
**When** sessions are returned
**Then** each session includes `deviceId` in the response payload

#### Story 18.2: Frontend — Service d'identité device + envoi `deviceId`

**As a** cashier working on a physical POS terminal,
**I want** my device to have a stable, readable identity,
**So that** the backoffice always knows which physical terminal I'm working on.

**Acceptance Criteria:**

**Given** the app launches on a device for the first time
**When** `DeviceIdentityService.getDeviceId()` is called
**Then** a `deviceId` is generated in the format `caisse-{platform}-{6-char-hex}` (ex: `caisse-android-a3f9c2`) and persisted in `SharedPreferences` under key `scalario_device_id`

**Given** the app launches on a device that already has a `deviceId` persisted
**When** `DeviceIdentityService.getDeviceId()` is called
**Then** the existing `deviceId` is returned — never regenerated

**Given** a cashier taps "Ouvrir session" on the POS
**When** the session open request is built
**Then** the `deviceId` from `DeviceIdentityService` is included in the body sent to `POST /retail/sessions/open`

**Given** the sync adapter pushes a pending session
**When** `SessionSyncAdapter.pushPending()` executes
**Then** the `deviceId` stored on the local `PosSession` is included in the sync payload

**Given** the heartbeat fires every 30 seconds
**When** `_sendHeartbeat()` is called
**Then** the same `deviceId` from `DeviceIdentityService` is used (not the hardcoded `"terminal_linux_1"`)

#### Story 18.3: Frontend — "État des caisses" affiche le nom du terminal

**As a** store owner viewing the backoffice dashboard,
**I want** "État des caisses" to show the name of each active terminal,
**So that** I can instantly identify which physical device is working.

**Acceptance Criteria:**

**Given** one or more sessions are OPEN
**When** `TerminalStatusList` renders
**Then** each session card shows `deviceId` (ex: `caisse-android-a3f9c2`) if available, or `"Terminal inconnu"` if `deviceId` is null

**Given** a session has `deviceId: "caisse-android-a3f9c2"`
**When** the card renders
**Then** the title is `caisse-android-a3f9c2`, the subtitle shows `Depuis HH:mm • Fond: XX FCFA`

**Given** `activeSessionsProvider` auto-refresh fires (30 secondes)
**When** a new session is opened on another terminal
**Then** the new card appears within the next refresh cycle — no manual reload required

**Test `test/dashboard_sdui_integration_test.dart` :**
- Mock `activeSessionsProvider` avec une session ayant `deviceId: "caisse-test-001"` → vérifie que le texte `"caisse-test-001"` est rendu
- Mock avec `deviceId: null` → vérifie que `"Terminal inconnu"` est rendu

---

## Epic 17: Dépenses & Bénéfice

**Objectif :** Permettre au gérant de saisir les dépenses du magasin (loyer, électricité, charges diverses) et d'afficher le bénéfice net réel (ventes − dépenses) dans le tableau de bord backoffice.

**Phase :** 1 (après Epic 16)
**Module :** `retail`
**FRs couverts :** FR48, FR49 (extension — bénéfice net)
**Prérequis :** Epics 1–9 (backend retail opérationnel), Epic 10 (SDUI), Epic 16 (navigation stable)

### Contexte métier

Un commerçant a besoin de connaître son **bénéfice net**, pas seulement ses ventes brutes. Les dépenses (loyer, salaires, approvisionnements hors stock) ne transitent pas par le POS — elles sont saisies manuellement par le manager/owner depuis le backoffice.

### Modèle de données cible

```
Expense (retail schema)
  id            UUID PK
  tenantId      UUID FK → tenants.id
  userId        UUID (qui a saisi)
  label         String (ex: "Loyer mars")
  amount        Decimal(10,2)
  category      String (LOYER | SALAIRE | ELECTRICITE | AUTRE)
  date          Date
  notes         String?
  createdAt     Timestamptz
  updatedAt     Timestamptz
```

### KPIs dashboard impactés

| KPI | Calcul |
|-----|--------|
| Dépenses (période) | `SUM(expense.amount)` sur la période |
| Bénéfice net | `totalVentes − totalDépenses` sur la période |

---

### Story 17.1: Backend — Modèle Expense + endpoints CRUD

**ID:** `17-1-expenses-backend`
**Dépend de :** Epics 1–9

**As a** manager/owner,
**I want** to record and retrieve expense entries via the API,
**So that** the frontend can display them and compute net profit.

**Acceptance Criteria:**

**Given** `prisma/schema.prisma`
**When** the story is implemented
**Then** un modèle `Expense` est ajouté dans le schéma `retail` avec les champs : `id`, `tenantId`, `userId`, `label`, `amount`, `category`, `date`, `notes?`, `createdAt`, `updatedAt`

**Given** `POST /retail/expenses` avec body `{ label, amount, category, date, notes?, tenantId }`
**When** le body est valide
**Then** une dépense est créée et retournée (201) ; `tenantId` est isolé par `TenantGuard`

**Given** `GET /retail/expenses?tenantId=&from=&to=`
**When** la requête est valide
**Then** les dépenses du tenant sont retournées filtrées par période (from/to inclusifs)

**Given** `DELETE /retail/expenses/:id`
**When** l'expense appartient au tenant
**Then** la dépense est supprimée (soft delete `isDeleted`) ; sinon 404

**Given** `GET /retail/reporting/summary?tenantId=&from=&to=`
**When** la requête est valide
**Then** la réponse inclut `totalExpenses` et `netProfit` (= `totalSales − totalExpenses`) en plus des champs existants

**RBAC :** `POST` / `DELETE` → `owner`, `manager` ; `GET` → `owner`, `manager`

**Tests :**
- POST valide → expense créé, status 201
- GET avec filtre de date → seules les dépenses dans la période retournées
- DELETE → soft-delete (isDeleted = true)
- Summary endpoint → `netProfit` = `totalSales - totalExpenses`
- POST sans `label` ou `amount` → 400

---

### Story 17.2: Frontend — Écran Dépenses + formulaire de saisie

**ID:** `17-2-expenses-frontend`
**Dépend de :** 17-1

**As a** manager/owner,
**I want** a dedicated "Dépenses" screen in the backoffice with an add form,
**So that** I can log expenses without leaving the app.

**Acceptance Criteria:**

**Given** l'utilisateur navigue vers l'écran Dépenses
**When** l'écran se charge
**Then** la liste des dépenses de la période active est affichée (label, montant, catégorie, date) ou le message "Aucune dépense enregistrée" si vide

**Given** l'utilisateur appuie sur le FAB "+"
**When** le formulaire apparaît
**Then** les champs suivants sont présents : Label (texte, obligatoire), Montant (numérique, obligatoire), Catégorie (dropdown : Loyer / Salaire / Électricité / Autre), Date (date picker, défaut = aujourd'hui), Notes (texte, optionnel)

**Given** l'utilisateur soumet le formulaire avec des données valides
**When** `POST /retail/expenses` répond 201
**Then** la liste se rafraîchit, le formulaire se ferme, snackbar "Dépense enregistrée"

**Given** l'utilisateur appuie sur "Supprimer" sur une dépense
**When** `DELETE /retail/expenses/:id` répond 200
**Then** la dépense disparaît de la liste, snackbar "Dépense supprimée"

**Structure fichiers :**
```
lib/features/retail/expenses/
  data/
    models/expense.dart
    repositories/expense_repository.dart
  presentation/
    providers/expense_providers.dart
    screens/expenses_screen.dart
    widgets/expense_form.dart
    widgets/expense_list_tile.dart
```

**Tests :**
- Widget test : formulaire présent, champs validés
- Provider test : submit → repository.create() appelé avec les bons params
- Cas erreur réseau → snackbar rouge affiché

---

### Story 17.3: Frontend — Navigation + KPIs Bénéfice dans le dashboard

**ID:** `17-3-expenses-navigation`
**Dépend de :** 17-2

**As a** store owner viewing the backoffice dashboard,
**I want** to see "Dépenses" and "Bénéfice net" KPI cards alongside sales,
**So that** I have a real-time view of my shop's financial health.

**Acceptance Criteria:**

**Given** le `DashboardShell` (ou l'écran principal backoffice)
**When** le menu latéral / bottom bar est visible
**Then** un onglet ou entrée "Dépenses" est présent et navigue vers `ExpensesScreen`

**Given** le `KpiCardGrid` du dashboard
**When** les données sont chargées
**Then** deux nouvelles cartes apparaissent : "Dépenses (période)" (montant total en FCFA) et "Bénéfice net" (ventes − dépenses, en vert si positif, rouge si négatif)

**Given** le filtre de période change (ex: 7 jours → 30 jours)
**When** `salesStatsProvider` et `expensesProvider` se rechargent
**Then** les KPIs "Dépenses" et "Bénéfice net" se mettent à jour en cohérence avec la même période

**Given** le bénéfice net est négatif
**When** la carte KPI s'affiche
**Then** la valeur est affichée en rouge avec un icône d'alerte `⚠`

**Tests (`test/dashboard_sdui_integration_test.dart`) :**
- Mock `expensesProvider` → vérifie que "Dépenses (période)" apparaît dans le KpiCardGrid
- Mock avec bénéfice net négatif → vérifie la couleur rouge ou le texte d'alerte
- Navigation : tap sur "Dépenses" dans le menu → `ExpensesScreen` chargé

---

### Story 17.4: Frontend — Ajout produit depuis le backoffice catalogue

**ID:** `17-4-add-product-backoffice`
**Dépend de :** Epic 10 (SDUI), Epic 14 (design system)

**As a** store owner in the backoffice,
**I want** to add a new product to the catalog directly from the backoffice,
**So that** I don't need to use a separate admin interface.

**Acceptance Criteria:**

**Given** l'utilisateur est sur l'écran Catalogue du backoffice
**When** il appuie sur le FAB "+"
**Then** un formulaire d'ajout de produit apparaît avec : Nom (texte, obligatoire), Prix (numérique, obligatoire), Catégorie (dropdown, liste des catégories du tenant), Barcode (optionnel), Quantité initiale en stock (numérique, défaut 0)

**Given** le formulaire est soumis avec des données valides
**When** `POST /catalog/items` répond 201
**Then** le produit est créé, la liste catalogue se rafraîchit, snackbar "Produit ajouté"

**Given** le formulaire est soumis sans Nom ou sans Prix
**When** la validation s'exécute localement
**Then** les champs invalides sont soulignés en rouge, le submit est bloqué

**Given** `POST /retail/products` (création RetailProduct avec stockQuantity initiale)
**When** la quantité initiale > 0
**Then** un `InventoryMovement` de type `DELIVERY` est automatiquement créé côté backend pour tracer l'entrée initiale

**Structure fichiers :**
```
lib/features/retail/catalog/
  presentation/
    screens/catalog_screen.dart     ← déjà existant ou à créer
    widgets/product_form_dialog.dart
```

**Tests :**
- Widget test : formulaire présent, validation Nom + Prix obligatoires
- Submit valide → `CatalogRepository.createItem()` appelé
- Cas erreur réseau → snackbar rouge affiché

---

## Epic 19: Admin Backoffice — Gestion Plateforme

**Objectif :** Permettre à Carlos d'onboarder de nouveaux clients directement depuis l'application Flutter sans toucher à Supabase ou la base SQL manuellement. Le panel admin est intégré dans l'app existante, accessible uniquement au rôle `superadmin`, et couvre la création de tenants, la gestion des modules, des utilisateurs, et un dashboard de monitoring.

**Phase :** 1 (après Epic 18)
**FRs couverts :** FR1, FR2, FR7, FR8, FR9, FR10
**Prérequis :** Epics 1–9 (kernel, tenancy, module registry opérationnels), Epic 15 (DashboardShell + navigation stable)

### Contexte métier

Aujourd'hui, pour onboarder un client, Carlos effectue des `INSERT` SQL manuels dans Supabase :
- Créer le tenant dans `kernel.tenants`
- Créer l'owner dans Supabase Auth
- Créer le membre dans `kernel.organization_members`
- Activer les modules dans `kernel.tenant_modules`
- Insérer les seed data (rôles, permissions)

Ce processus est manuel, error-prone et ne scale pas. Epic 19 remplace tout ça par un panel admin intégré dans l'app Flutter, accessible uniquement si `userProfile.role == 'superadmin'`.

### Architecture admin

- **PAS** une app séparée — c'est un écran dans l'app Flutter existante
- Si `userProfile.role == 'superadmin'` → affiche `AdminDashboard` au lieu du POS/backoffice retail
- Les endpoints admin sont sous `/admin/*` avec un `SuperAdminGuard` (vérifie rôle superadmin dans `OrganizationMember`)
- Le panel admin n'a **pas besoin** de fonctionner offline (toujours connecté)

---

### Story 19.1: Backend — CRUD Tenants sous /admin/tenants

**As a** superadmin,
**I want** REST endpoints to create, list, and update tenants,
**So that** I can onboard new clients without manual SQL.

**Acceptance Criteria:**

**Given** a `SuperAdminGuard` is in place
**When** any `/admin/*` endpoint is called
**Then** only users with `role = 'superadmin'` in `organization_members` can access it; others get 403

**Given** `POST /admin/tenants` with `{ name, ownerEmail, ownerPassword, currency?, timezone?, businessType? }`
**When** the body is valid
**Then** the following is executed in a single Prisma transaction:
- Supabase Auth user created for the owner (email + password)
- `kernel.tenants` record created with provided name, currency (default XOF), timezone, status = active
- `kernel.organization_members` record created linking the new userId to the tenant with `role = 'owner'`
- Default retail modules activated via `ModuleRegistryService.activateDefaultModulesForTenant()` (catalog, inventory, transactions, retail)
- Response: `{ tenantId, userId, name, currency, timezone, status, modulesActivated }`

**Given** `GET /admin/tenants`
**When** called by a superadmin
**Then** returns an array of tenants with: `id`, `name`, `status`, `currency`, `timezone`, `createdAt`, `membersCount` (count of active org members), `activeModules` (array of module codes with status = active)

**Given** `PATCH /admin/tenants/:id` with `{ name?, currency?, timezone?, status? }`
**When** the tenant exists
**Then** the specified fields are updated; `status` accepts only `active | suspended | archived`
**And** if status changes to `suspended`, the change is reflected immediately (tenant guard blocks access)

**Given** a step in the POST transaction fails (e.g., Supabase Auth returns an error)
**When** the error is caught
**Then** the entire transaction is rolled back — no orphaned tenant or org_member records exist

---

### Story 19.2: Backend — Activation/Désactivation Modules par Tenant

**As a** superadmin,
**I want** endpoints to manage which modules are active per tenant,
**So that** I can enable or disable features for a client without touching the database.

**Acceptance Criteria:**

**Given** `GET /admin/modules`
**When** called by a superadmin
**Then** returns the full module catalog from `kernel.modules`: `{ id, code, name, type, dependencies }`

**Given** `GET /admin/tenants/:tenantId/modules`
**When** called by a superadmin
**Then** returns all modules with their activation status for that tenant: `{ moduleCode, name, type, status: 'active'|'inactive', activatedAt? }`

**Given** `POST /admin/tenants/:tenantId/modules/:moduleCode/activate`
**When** the module has dependencies (e.g., `retail` depends on `catalog`, `inventory`, `transactions`)
**Then** all dependency modules are validated as active before activating the requested module
**And** if a dependency is inactive, return 422 with `{ error: 'MISSING_DEPENDENCY', missing: ['catalog'] }`
**And** if all dependencies are met, the module status is set to `active` with `activatedAt = now()`

**Given** `POST /admin/tenants/:tenantId/modules/:moduleCode/deactivate`
**When** another active module depends on the module being deactivated
**Then** return 422 with `{ error: 'HAS_DEPENDENTS', dependents: ['retail'] }`
**And** if no other active module depends on it, set status to `inactive`

**Given** `POST /admin/tenants` creates a retail tenant (Story 19.1)
**When** the seed step runs
**Then** modules `catalog`, `inventory`, `transactions`, `retail` are all activated automatically

---

### Story 19.3: Backend — Gestion Users par Tenant

**As a** superadmin,
**I want** endpoints to create, list, update, and deactivate users within a tenant,
**So that** I can manage client team members without Supabase dashboard access.

**Acceptance Criteria:**

**Given** `POST /admin/tenants/:tenantId/users` with `{ email, password, role }`
**When** the body is valid and `role` is one of `owner | manager | cashier`
**Then** a Supabase Auth user is created with the given email/password
**And** an `organization_members` record is created linking the userId to the tenant with the given role
**And** response: `{ userId, email, role, createdAt }`

**Given** `GET /admin/tenants/:tenantId/users`
**When** called by a superadmin
**Then** returns all `organization_members` for that tenant with: `userId`, `email` (from Supabase Auth), `role`, `createdAt`, `lastSignInAt` (from Supabase Auth metadata)

**Given** `PATCH /admin/tenants/:tenantId/users/:userId` with `{ role }`
**When** the user is a member of that tenant
**Then** the `role_id` in `organization_members` is updated to the new role
**And** return the updated member record

**Given** `DELETE /admin/tenants/:tenantId/users/:userId`
**When** the user is a member of that tenant
**Then** the `organization_members` record is deleted (hard delete — user removed from org)
**And** the Supabase Auth user is disabled (`banned_until = far future`) — not deleted (preserves audit trail)
**And** return 204 No Content

**Given** the target userId is the only owner of the tenant
**When** DELETE is attempted
**Then** return 422 with `{ error: 'CANNOT_REMOVE_LAST_OWNER' }`

---

### Story 19.4: Frontend — Admin Shell avec Navigation

**As a** superadmin,
**I want** a dedicated admin dashboard to appear when I log in,
**So that** I can manage the platform without seeing the retail POS interface.

**Acceptance Criteria:**

**Given** `main.dart` evaluates `userProfile.role`
**When** `profile.role == 'superadmin'`
**Then** `AdminDashboard` is shown instead of `PosScreen` or `DashboardScreen`
**And** the existing cashier/manager routing is unchanged

**Given** `AdminDashboard` is rendered
**When** on a tablet (width ≥ 1024px)
**Then** a `NavigationRail` is shown on the left with 3 destinations: Tenants / Modules / Monitoring
**When** on a phone or medium (width < 1024px)
**Then** a `NavigationBar` (BottomNav) is shown with the same 3 destinations
**And** the same `LayoutBuilder` + `kMedium = 1024.0` breakpoint from `app_breakpoints.dart` is used

**Given** the Tenants tab is selected
**When** `AdminTenantsScreen` renders
**Then** it shows a scrollable list of tenants with: name, status badge (active=green / suspended=orange / archived=grey), member count, active module chips
**And** a FAB "Nouveau client" (bottom-right) navigates to the tenant creation form

**Given** the admin panel has no offline requirement
**When** the device goes offline
**Then** a non-blocking banner "Connexion requise pour l'admin" is shown — no crash, no data corruption

**Files to create:**
- `lib/features/admin/presentation/screens/admin_dashboard.dart`
- `lib/features/admin/presentation/screens/admin_tenants_screen.dart`
- `lib/features/admin/presentation/providers/admin_providers.dart`
- Modify: `lib/main.dart` — add `superadmin` branch in `userProfileAsync.when(data: ...)`

---

### Story 19.5: Frontend — Formulaire Création Tenant + Gestion Modules & Users

**As a** superadmin,
**I want** forms to create a new client and manage their modules and users,
**So that** onboarding is a guided flow with no SQL required.

**Acceptance Criteria:**

**Given** the FAB "Nouveau client" is tapped
**When** `NewTenantForm` renders
**Then** it presents: Nom boutique (required), Email owner (required, validated), Mot de passe owner (required, min 8 chars), Devise (dropdown: XOF default, EUR, USD, MAD), Timezone (dropdown: Africa/Abidjan default), Type métier (radio: Retail — seul choix MVP)

**Given** the form is submitted with valid data
**When** `POST /admin/tenants` returns 201
**Then** success snackbar "Client [nom] créé avec succès", form closes, tenants list refreshes

**Given** the form is submitted with invalid data (missing name, bad email)
**When** local validation runs before submit
**Then** invalid fields are underlined in red; submit is blocked

**Given** a tenant card is tapped in the list
**When** `TenantDetailScreen` renders
**Then** it shows 3 tabs: Infos, Modules, Users

**Given** the Modules tab is selected
**When** `TenantModulesTab` renders
**Then** each module in the catalog is shown as a row with: module name, type badge, a toggle switch
**And** toggling ON calls `POST /admin/tenants/:tenantId/modules/:code/activate`
**And** toggling OFF calls `POST /admin/tenants/:tenantId/modules/:code/deactivate`
**And** if the API returns 422 (dependency error), the toggle reverts and a snackbar shows the error message

**Given** the Users tab is selected
**When** `TenantUsersTab` renders
**Then** it lists users with: email, role chip, last sign-in date
**And** a "+" button opens `AddUserDialog` (email, password, role dropdown)
**And** a long-press on a user row offers "Changer rôle" and "Désactiver"

**Files to create:**
- `lib/features/admin/presentation/screens/new_tenant_form.dart`
- `lib/features/admin/presentation/screens/tenant_detail_screen.dart`
- `lib/features/admin/presentation/widgets/tenant_modules_tab.dart`
- `lib/features/admin/presentation/widgets/tenant_users_tab.dart`

---

### Story 19.6: Frontend — Dashboard Monitoring

**As a** superadmin,
**I want** a monitoring dashboard showing platform health,
**So that** I can proactively identify tenants with sync issues or high error rates.

**Acceptance Criteria:**

**Given** the Monitoring tab is selected
**When** `AdminMonitoringScreen` renders
**Then** it calls `GET /admin/monitoring/health` and displays:
- Total tenants actifs (count where status = 'active')
- Total utilisateurs sur la plateforme
- Liste des tenants avec: nom, statut, dernière activité (dernière mutation créée), nombre de mutations FAILED en attente

**Given** a tenant has > 10 mutations FAILED en attente
**When** its row renders in the monitoring list
**Then** a warning icon (⚠️) and red badge showing the count are displayed
**And** tapping the row shows a detail card with the failed mutation IDs

**Given** `GET /admin/monitoring/health` is called (backend endpoint — à créer dans Story 19.6)
**When** the backend responds
**Then** the response shape is:
```json
{
  "activeTenants": 5,
  "totalUsers": 23,
  "tenants": [
    {
      "id": "uuid",
      "name": "Boutique Koné",
      "status": "active",
      "lastActivityAt": "ISO8601",
      "failedMutationsCount": 0
    }
  ]
}
```

**Given** the monitoring screen is open
**When** the user pulls to refresh
**Then** `GET /admin/monitoring/health` is re-fetched and the data updates

**Backend endpoint à créer :**
- `GET /admin/monitoring/health` — agrège `Tenant`, `OrganizationMember`, et une future table `sync_mutations` (ou `audit_log` comme proxy pour lastActivity)
- Pour MVP : `lastActivityAt` = MAX(`audit_log.created_at`) par tenant, `failedMutationsCount` = 0 (placeholder — réel quand outbox server-side existe)

**Files to create:**
- `lib/features/admin/presentation/screens/admin_monitoring_screen.dart`
- Backend: `apps/backend/src/admin/monitoring/admin-monitoring.controller.ts`

---

## Epic 20: Vente au poids + unités configurables

Les articles peuvent être configurés avec un `unitType` (pièce, poids, volume, longueur) et un label d'unité libre. Au POS, les articles au poids affichent un champ de saisie de quantité en virgule flottante ; le total est calculé automatiquement avec arrondi FCFA. Le reçu affiche la quantité et l'unité native. La décrémentation stock applique le facteur de conversion configuré.

**FRs covered:** FR76, FR77, FR78
**Phase:** 2a
**Prerequisite:** Epics 1–9 (backend catalog opérationnel)

---

### Story 20-1: Backend — Migration Prisma unitType + pricePerUnit + conversionRate

**As an** owner,
**I want** each catalog item to have a configurable unit type, unit price, and stock conversion factor,
**So that** the system can price and track weight/volume/length articles correctly (FR76, FR78).

**Acceptance Criteria:**

**AC1 — Migration Prisma :**

**Given** the current `CatalogItem` table has no `unit_type`, `price_per_unit`, or `conversion_rate` columns
**When** the Prisma migration runs
**Then** the following columns are added to `shared.catalog_items`:
- `unit_type VARCHAR NOT NULL DEFAULT 'piece'` — valeurs acceptées : `piece | weight | volume | length`
- `price_per_unit NUMERIC(10,2) NULL` — prix par unité native (optionnel, null = même valeur que `price`)
- `conversion_rate NUMERIC(10,4) NULL` — facteur de conversion unité de vente → unité de stock
**And** toutes les lignes existantes ont `unit_type = 'piece'`, `price_per_unit = NULL`, `conversion_rate = NULL`
**And** aucune donnée existante n'est perdue

**AC2 — DTO & validation :**

**Given** `POST /api/v1/catalog/items` ou `PATCH /api/v1/catalog/items/:id`
**When** le body inclut `unitType`, `pricePerUnit`, `conversionRate`
**Then** les champs sont validés :
- `unitType` : enum strict `['piece', 'weight', 'volume', 'length']`, défaut `'piece'`
- `pricePerUnit` : Decimal ≥ 0, optionnel
- `conversionRate` : Decimal > 0, optionnel
**And** une valeur `unitType` invalide retourne HTTP 400 avec message d'erreur lisible

**AC3 — Réponse GET catalog :**

**Given** `GET /api/v1/catalog/items`
**When** la réponse est sérialisée
**Then** chaque item inclut `unitType`, `pricePerUnit`, `conversionRate` (null si non définis)
**And** la sync delta (`?since=`) inclut aussi ces champs

**AC4 — Décrémentation stock avec conversionRate :**

**Given** un article avec `conversionRate = 0.5` (ex: 1 sachet 500g = 0.5 unité stock)
**When** une vente de quantité `2.0` est enregistrée
**Then** le `InventoryMovement.quantity` créé est `2.0 × 0.5 = 1.0` (dans l'unité de stock)
**And** si `conversionRate` est null, la décrémentation est `quantity` sans transformation

**AC5 — Tests backend :**

**Given** `catalog.service.spec.ts`
**When** les tests unitaires sont exécutés
**Then** :
- Créer un item avec `unitType: 'weight'` → champ persisté correctement
- Créer avec `unitType: 'invalid'` → erreur de validation
- Décrémentation avec `conversionRate: 0.5`, quantité `3` → stock réduit de `1.5`
- Décrémentation sans `conversionRate` → stock réduit de `3` (comportement inchangé)

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter les 3 champs sur `CatalogItem`
- `apps/backend/prisma/migrations/` — nouvelle migration auto-générée
- `apps/backend/src/shared/catalog/catalog.service.ts` — logique conversionRate
- `apps/backend/src/shared/catalog/catalog.controller.ts` — accepter nouveaux champs
- `apps/backend/src/shared/catalog/dto/` — `CreateCatalogItemDto`, `UpdateCatalogItemDto`
- `apps/backend/src/shared/catalog/catalog.service.spec.ts`

---

### Story 20-2: Frontend — ProductFormDialog supporte unitType

**As an** owner,
**I want** the product form to let me configure unit type, unit label, and unit price,
**So that** I can set up weight/volume articles for accurate POS pricing (FR76, FR78).

**Acceptance Criteria:**

**AC1 — Dropdown unitType :**

**Given** `ProductFormDialog` est ouvert (création ou édition)
**When** l'utilisateur voit le formulaire
**Then** un dropdown "Type d'unité" est présent avec 4 options :
- Pièce (`piece`) — sélectionné par défaut
- Poids (`weight`)
- Volume (`volume`)
- Longueur (`length`)

**AC2 — Champ label unité (conditionnel) :**

**Given** `unitType != 'piece'` est sélectionné
**When** le formulaire se met à jour
**Then** un champ texte "Label unité" apparaît (ex: "kg", "g", "L", "m")
**And** ce champ est obligatoire si `unitType != 'piece'`
**And** si `unitType == 'piece'`, le champ est masqué et sa valeur est ignorée

**AC3 — Affichage prix adapté :**

**Given** `unitType != 'piece'`
**When** le champ prix est affiché
**Then** son label affiche "Prix par [label unité]" (ex: "Prix par kg")
**And** si `unitType == 'piece'`, le label reste "Prix" (comportement actuel)

**AC4 — Champ facteur de conversion (optionnel) :**

**Given** `unitType != 'piece'`
**When** l'utilisateur développe la section "Paramètres avancés"
**Then** un champ "Facteur de conversion (optionnel)" est disponible
**And** son helper text indique "Ex: 0.5 si 1 sachet 500g = 0.5 kg stock"
**And** le champ accepte uniquement des valeurs numériques décimales > 0

**AC5 — Sauvegarde et pré-remplissage :**

**Given** un article avec `unitType = 'weight'` et `pricePerUnit = 1500` est édité
**When** `ProductFormDialog` s'ouvre en mode édition
**Then** le dropdown affiche "Poids", le label unité affiche la valeur persistée, le prix affiche `1500`

**AC6 — Appel API :**

**Given** le formulaire est soumis avec `unitType = 'weight'`, `pricePerUnit = 1500`, `conversionRate = null`
**When** `POST /api/v1/catalog/items` ou `PATCH` est appelé
**Then** le body inclut `{"unitType": "weight", "pricePerUnit": 1500, "conversionRate": null}`

**AC7 — Test widget :**

**Given** le widget test de `ProductFormDialog`
**When** `unitType` est changé à `'weight'`
**Then** le champ "Label unité" devient visible et obligatoire
**And** le label du champ prix change en "Prix par [label]"

**Files to modify:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart`
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `unitType`, `pricePerUnit`, `conversionRate`
- `apps/frontend/lib/features/retail/pos/data/models/product.g.dart` — regénérer
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — sérialisation nouveaux champs

---

### Story 20-3: Frontend — POS vente au poids

**As a** commercial (Fatou),
**I want** the POS to show a quantity input when I add a weight/volume article,
**So that** I can sell 1.5 kg of tomatoes and get the correct total automatically (FR77).

**Acceptance Criteria:**

**AC1 — Déclenchement saisie quantité :**

**Given** la grille POS affiche un article avec `unitType = 'weight'` (ou `volume`, `length`)
**When** l'utilisateur tape sur la carte produit
**Then** un dialog "Saisir la quantité" apparaît immédiatement (avant ajout au panier)
**And** le dialog affiche : nom du produit, champ numérique en virgule flottante, label unité (ex: "kg"), prix unitaire (ex: "1 500 F/kg")
**And** la validation est immédiate : toute valeur > 0 est acceptée

**AC2 — Calcul total automatique :**

**Given** l'utilisateur saisit `1.5` dans le dialog quantité d'un article à `1 500 F/kg`
**When** il confirme
**Then** l'article est ajouté au panier avec quantité `1.5`, total ligne = `2 250 F` (arrondi 5 FCFA)
**And** le total panier est mis à jour immédiatement

**AC3 — Affichage panier :**

**Given** un article au poids est dans le panier
**When** le panneau panier (`CartPanel`) affiche la ligne
**Then** la quantité s'affiche avec l'unité native : "1.5 kg" (pas "1.5 pièce(s)")
**And** le prix ligne affiche "2 250 F"

**AC4 — Article pièce inchangé :**

**Given** un article avec `unitType = 'piece'`
**When** l'utilisateur tape sur la carte produit
**Then** le comportement existant est préservé (ajout direct, quantité entière, pas de dialog)

**AC5 — Reçu adapté :**

**Given** une vente contenant un article au poids est finalisée
**When** `ReceiptDialog` s'affiche
**Then** chaque ligne article au poids affiche : `[nom] — [quantité] [unité] × [prix/unité] = [total ligne]`
**And** les articles pièce affichent le format actuel inchangé

**AC6 — Transaction enregistrée :**

**Given** la vente est soumise au backend
**When** `itemsJson` est sérialisé dans la `Transaction`
**Then** chaque item au poids contient : `{"catalogItemId", "quantity": 1.5, "unitType": "weight", "unitLabel": "kg", "pricePerUnit": 1500, "lineTotal": 2250}`

**AC7 — Test widget :**

**Given** le widget test du `QuantityInputDialog`
**When** l'utilisateur entre `2.3` et confirme
**Then** le `CartNotifier` reçoit l'article avec `quantity = 2.3`
**And** le total calculé = `pricePerUnit × 2.3` arrondi au plus proche multiple de 5

**Files to create/modify:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/quantity_input_dialog.dart` — nouveau widget
- `apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart` — détecter unitType et ouvrir dialog
- `apps/frontend/lib/features/retail/pos/presentation/state/cart_notifier.dart` — gérer quantité flottante
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — affichage unité
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — format ligne poids
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — sérialisation itemsJson

---

### Story 20-4: Tests de bout en bout + sync produits au poids

**As a** developer,
**I want** weight products to sync correctly and receipts to display correct units end-to-end,
**So that** the feature is validated from backend to frontend (FR76, FR77, FR78).

**Acceptance Criteria:**

**AC1 — Sync delta produits au poids :**

**Given** un article avec `unitType = 'weight'` et `pricePerUnit = 1500` existe sur le backend
**When** `CatalogRepository.syncProducts()` exécute un pull delta
**Then** le `Product` local reçu a `unitType = 'weight'`, `pricePerUnit = 1500.0`
**And** l'article est stocké dans Isar avec ces valeurs sans troncation ni perte de précision

**AC2 — Robustesse sync — champs absents :**

**Given** le backend retourne un article sans `unitType` (ancienne donnée avant migration)
**When** `Product.fromJson()` parse la réponse
**Then** `unitType` prend la valeur par défaut `'piece'`
**And** aucune exception n'est levée

**AC3 — Reçu affiché correctement :**

**Given** un reçu contenant une ligne "Tomates — 1.5 kg × 1 500 F/kg = 2 250 F"
**When** `ReceiptDialog` est rendu en test widget
**Then** le texte "1.5 kg" apparaît dans le widget
**And** le texte "2 250" apparaît dans le widget
**And** aucun texte "pièce(s)" ou "1 pcs" n'apparaît pour cette ligne

**AC4 — Calcul arrondi FCFA :**

**Given** un article à `1 333 F/kg`
**When** la quantité `0.75 kg` est saisie → total brut = `999.75 F`
**Then** le total affiché et enregistré = `1 000 F` (arrondi au plus proche multiple de 5)

**AC5 — conversionRate appliqué correctement :**

**Given** un article "Sachet farine" avec `conversionRate = 0.5` (1 sachet = 0.5 kg de stock)
**When** une vente de `3 sachets` est synchronisée avec le backend
**Then** le `InventoryMovement.quantity` créé par le backend est `1.5` (3 × 0.5)
**And** le stock de l'article diminue de `1.5`

**AC6 — Test d'intégration backend (NestJS) :**

**Given** `catalog.service.spec.ts`
**When** les tests d'intégration sont exécutés contre une DB de test
**Then** :
- Migration appliquée → colonnes présentes avec bonnes valeurs par défaut
- Create item `unitType: 'volume'` → GET retourne `unitType: 'volume'`
- Sync delta `?since=T` → articles modifiés incluent `unitType` et `pricePerUnit`

**Notes dev :**
- `Product.fromJson()` doit utiliser `json['unitType'] ?? json['unit_type'] ?? 'piece'` pour la compatibilité snake_case/camelCase
- Isar schema version bump nécessaire si `unitType` est ajouté comme champ indexé

**Files to create/modify:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — fromJson robuste
- `apps/backend/src/shared/catalog/catalog.service.spec.ts` — tests migration + sync
- `apps/frontend/test/features/pos/quantity_input_dialog_test.dart` — nouveau test widget
- `apps/frontend/test/features/pos/receipt_dialog_weight_test.dart` — nouveau test reçu poids

---

## Epic 21: Commandes fournisseurs + réception liée

Le gestionnaire peut créer des commandes fournisseurs (sélection fournisseur, articles, quantités, date prévue), suivre leur statut, et enregistrer la réception liée avec variance automatique et notes qualité par article. La réception sans commande associée reste possible. Un KPI "Commandes en attente" apparaît sur le dashboard.

**FRs covered:** FR79, FR80
**Phase:** 2a
**Prerequisite:** Epics 1–9, Epic 3 (contacts fournisseurs), Epic 16 (hub inventaire)

---

### Story 21-1: Backend — Modèles PurchaseOrder + endpoints CRUD

**As a** manager (Moussa),
**I want** a purchase order API to create, update, and track supplier orders,
**So that** expected deliveries are documented and reception variances are traceable (FR79, FR80).

**Acceptance Criteria:**

**AC1 — Migration Prisma :**

**Given** les tables `purchase_orders` et `purchase_order_lines` sont absentes du schéma `shared`
**When** la migration Prisma s'exécute
**Then** les tables sont créées avec :
- `purchase_orders` : `id, supplier_id (UUID → contacts.id), status, expected_date, notes, tenant_id, created_by, created_at, updated_at`
- `purchase_order_lines` : `id, purchase_order_id, catalog_item_id, expected_quantity, received_quantity (null), quality_notes (null), created_at`
**And** aucune donnée existante n'est affectée

**AC2 — CRUD commandes :**

**Given** un manager authentifié avec rôle owner ou manager
**When** `POST /api/v1/purchase-orders` est appelé avec `{supplierId, lines: [{catalogItemId, expectedQuantity}], expectedDate?, notes?}`
**Then** une `PurchaseOrder` est créée avec `status = 'draft'` et ses lignes associées
**And** la réponse inclut l'objet complet avec lignes

**Given** `GET /api/v1/purchase-orders` est appelé
**When** des filtres sont passés (`?status=confirmed&supplierId=uuid&from=date&to=date`)
**Then** seules les commandes correspondant aux filtres sont retournées, triées par `created_at` DESC
**And** chaque commande inclut : `id, status, expectedDate, supplierName, lineCount, tenantId`

**Given** `GET /api/v1/purchase-orders/:id` est appelé
**When** la commande existe pour le tenant courant
**Then** la réponse inclut l'objet complet avec `lines[]` (chaque ligne : catalogItemId, itemName, expectedQuantity, receivedQuantity, qualityNotes)

**Given** `PATCH /api/v1/purchase-orders/:id` est appelé avec `{status: 'confirmed'}`
**When** la transition de statut est valide (ex: draft → confirmed)
**Then** le statut est mis à jour et la réponse inclut l'objet mis à jour
**And** une transition invalide (ex: received → draft) retourne HTTP 422 avec message d'erreur

**AC3 — Endpoint réception :**

**Given** `POST /api/v1/purchase-orders/:id/receive` est appelé avec `{lines: [{purchaseOrderLineId, receivedQuantity, qualityNotes?}]}`
**When** la commande est en statut `confirmed` ou `partially_received`
**Then** pour chaque ligne : `receivedQuantity` est enregistrée, `qualityNotes` sauvegardée
**And** le système calcule la variance = `receivedQuantity - expectedQuantity` pour chaque ligne
**And** si toutes les lignes sont reçues → statut passe à `received`
**And** si certaines lignes sont partiellement reçues → statut passe à `partially_received`
**And** pour chaque ligne reçue : un `InventoryMovement` de type `DELIVERY` est créé avec `quantity = receivedQuantity`, `referenceId = purchaseOrderId`
**And** l'événement `DeliveryReceived` est émis (payload : lignes reçues, tenantId)

**AC4 — Réception sans commande associée :**

**Given** `POST /api/v1/inventory/movements` est appelé avec `{type: 'DELIVERY', catalogItemId, quantity}`
**When** aucun `purchaseOrderId` n'est fourni
**Then** le mouvement est créé normalement (comportement inchangé — Epic 16 Story 16.1)

**AC5 — Tests backend :**

**Given** `purchase-orders.service.spec.ts`
**When** les tests sont exécutés
**Then** :
- Créer une PO avec 2 lignes → 2 `PurchaseOrderLine` créées avec `receivedQuantity = null`
- Transition valide `draft → confirmed` → OK ; transition invalide `received → draft` → erreur 422
- Réception complète (toutes lignes reçues) → statut = `received`, `InventoryMovement` créés
- Réception partielle → statut = `partially_received`
- Variance = reçu − commandé, calculée correctement pour chaque ligne

**Files to create:**
- `apps/backend/src/shared/purchase-orders/purchase-orders.module.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.controller.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.service.ts`
- `apps/backend/src/shared/purchase-orders/dto/create-purchase-order.dto.ts`
- `apps/backend/src/shared/purchase-orders/dto/receive-purchase-order.dto.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.service.spec.ts`
- `apps/backend/prisma/migrations/` — nouvelle migration auto-générée

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter `PurchaseOrder`, `PurchaseOrderLine`
- `apps/backend/src/app.module.ts` — importer `PurchaseOrdersModule`

---

### Story 21-2: Frontend — Écran liste commandes + formulaire création

**As a** manager (Moussa),
**I want** a screen to list purchase orders and create new ones,
**So that** I can document expected supplier deliveries (FR79).

**Acceptance Criteria:**

**AC1 — Écran liste commandes :**

**Given** l'utilisateur navigue vers l'onglet "Commandes" (hub inventaire)
**When** `PurchaseOrdersScreen` se charge
**Then** il appelle `GET /api/v1/purchase-orders` et affiche une liste de cards
**And** chaque card affiche : nom fournisseur, date prévue, statut (chip coloré), nombre d'articles
**And** un filtre par statut (chips en haut : Tous · Brouillon · Confirmé · Partiel · Reçu · Annulé) est présent
**And** si la liste est vide → message "Aucune commande" + bouton "Créer la première commande"

**AC2 — Chips statut colorés :**

| Statut | Couleur chip |
|:---|:---|
| draft | gris |
| confirmed | bleu |
| partially_received | orange |
| received | vert |
| cancelled | rouge |

**AC3 — Formulaire création commande :**

**Given** le FAB "+" est tapé
**When** `CreatePurchaseOrderSheet` s'ouvre (bottom sheet plein écran)
**Then** le formulaire contient :
- Sélection fournisseur : `ProductAutocomplete` filtré sur `contactType = 'supplier'` (contacts existants)
- Champ date de livraison prévue (optionnel) — `DatePicker`
- Champ notes (optionnel, multiline)
- Section "Articles commandés" : liste de lignes, chaque ligne = produit (autocomplete) + quantité (numérique)
- Bouton "Ajouter un article" pour ajouter une ligne
- Bouton "Supprimer" (icône poubelle) sur chaque ligne
- Bouton "Créer la commande" (disabled si aucun article ou pas de fournisseur)

**AC4 — Soumission création :**

**Given** le formulaire est valide et soumis
**When** `POST /api/v1/purchase-orders` est appelé
**Then** en cas de succès : sheet se ferme, liste se rafraîchit, snackbar "Commande créée"
**And** en cas d'erreur : snackbar rouge avec message d'erreur de l'API

**AC5 — Transition statut depuis la liste :**

**Given** une card de commande en statut `draft` est affichée
**When** l'utilisateur la presse longuement (ou via menu contextuel)
**Then** un menu propose "Confirmer la commande" → appelle `PATCH /api/v1/purchase-orders/:id {status: 'confirmed'}`
**And** la card se met à jour avec le nouveau statut sans rechargement complet

**Files to create:**
- `apps/frontend/lib/features/shared/purchase_orders/data/models/purchase_order_local.dart`
- `apps/frontend/lib/features/shared/purchase_orders/data/repositories/purchase_orders_repository.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/screens/purchase_orders_screen.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart`

---

### Story 21-3: Frontend — Réception liée à une commande

**As a** manager (Moussa),
**I want** to record a delivery against a purchase order with pre-filled quantities,
**So that** variances are calculated automatically and quality issues are documented (FR80).

**Acceptance Criteria:**

**AC1 — Accès depuis liste :**

**Given** une commande en statut `confirmed` ou `partially_received` est affichée
**When** l'utilisateur tape dessus
**Then** `PurchaseOrderDetailScreen` s'ouvre avec : fournisseur, date prévue, notes, liste des lignes (article, qté commandée)
**And** un bouton "Réceptionner" est visible si statut ≠ `received` et ≠ `cancelled`

**AC2 — Formulaire réception pré-rempli :**

**Given** le bouton "Réceptionner" est tapé
**When** `ReceivePurchaseOrderSheet` s'ouvre
**Then** chaque ligne de la commande est affichée avec :
- Nom article
- Quantité commandée (affichée en lecture seule)
- Champ "Quantité reçue" (pré-rempli avec quantité commandée, modifiable)
- Champ "Notes qualité" (optionnel, ex: "produits trop mûrs")

**AC3 — Affichage variance en temps réel :**

**Given** l'utilisateur modifie la quantité reçue d'une ligne
**When** la valeur change
**Then** la variance s'affiche sous le champ : "+2.5" (vert si positif) ou "-1.0" (orange si négatif)
**And** une variance de 0 n'est pas affichée

**AC4 — Soumission réception :**

**Given** le formulaire de réception est soumis
**When** `POST /api/v1/purchase-orders/:id/receive` est appelé
**Then** en cas de succès : sheet se ferme, détail commande se rafraîchit avec nouveau statut
**And** snackbar "Réception enregistrée — [n] mouvements de stock créés"
**And** en cas d'erreur : snackbar rouge avec message d'erreur

**AC5 — Réception sans commande (flux hérité préservé) :**

**Given** l'utilisateur est dans le hub inventaire, onglet "Réceptions"
**When** il crée une réception sans sélectionner de commande fournisseur
**Then** le flux `delivery_form.dart` existant (Epic 16 Story 16.1) fonctionne sans changement
**And** aucune régression sur le flux actuel

**AC6 — Test widget :**

**Given** `ReceivePurchaseOrderSheet` est rendu avec une commande de 2 lignes
**When** la quantité reçue de la ligne 1 est modifiée à une valeur différente de la quantité commandée
**Then** la variance s'affiche correctement sur cette ligne
**And** les autres lignes restent inchangées

**Files to create:**
- `apps/frontend/lib/features/shared/purchase_orders/presentation/screens/purchase_order_detail_screen.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/widgets/receive_purchase_order_sheet.dart`
- `apps/frontend/test/features/purchase_orders/receive_sheet_test.dart`

---

### Story 21-4: Navigation hub inventaire + KPI "Commandes en attente"

**As a** manager or owner,
**I want** purchase orders accessible from the inventory hub and visible as a dashboard KPI,
**So that** pending deliveries are never missed (FR79).

**Acceptance Criteria:**

**AC1 — Onglet "Commandes" dans le hub inventaire :**

**Given** l'utilisateur ouvre le hub inventaire (`InventoryScreen`)
**When** les onglets s'affichent
**Then** un onglet "Commandes" est ajouté aux onglets existants (Réceptions · Transferts · Pertes · Inventaire)
**And** l'onglet "Commandes" charge `PurchaseOrdersScreen`
**And** si des commandes sont en statut `confirmed` ou `partially_received`, un badge numérique rouge apparaît sur l'onglet

**AC2 — KPI dashboard "Commandes en attente" :**

**Given** le dashboard backoffice (`DashboardScreen`) est chargé
**When** la section KPI s'affiche
**Then** une card "Commandes en attente" affiche le nombre de POs avec `status IN ('confirmed', 'partially_received')`
**And** tapper la card navigue vers `InventoryScreen` avec l'onglet "Commandes" sélectionné et filtre "Confirmé" actif
**And** si le count = 0, la card affiche "0" sans masquer la card (visibilité permanente)

**AC3 — Endpoint KPI backend :**

**Given** `GET /api/v1/purchase-orders/stats` est appelé
**When** le backend répond
**Then** la réponse inclut `{ pendingCount: number }` — count des POs `confirmed` + `partially_received` pour le tenant
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

**AC4 — Refresh automatique :**

**Given** le dashboard est visible
**When** une réception est enregistrée (Story 21-3 AC4)
**Then** le provider du KPI est invalidé et le count se met à jour automatiquement

**Notes dev :**
- Le badge sur l'onglet utilise le même provider que le KPI dashboard (source unique de vérité)
- Rôle requis pour accès commandes : owner ou manager — le commercial ne voit pas l'onglet "Commandes"

**Files to modify:**
- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — ajouter onglet Commandes
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — ajouter KPI card

**Files to create:**
- `apps/frontend/lib/features/shared/purchase_orders/presentation/providers/purchase_orders_stats_provider.dart`

---

## Epic 22: Alertes stock bas + notifications

### Story 22-1: Backend — minStockLevel sur CatalogItem + endpoint alertes

**As a** backend developer,
**I want** a low-stock alert evaluation triggered after every stock-decrementing movement, surfaced via a dedicated endpoint,
**So that** the backoffice can display real-time low-stock signals (FR81, FR82).

**Acceptance Criteria:**

**AC1 — Champ minStockLevel déjà en schema :**

**Given** la migration Prisma pour `minStockLevel` sur `CatalogItem` est déjà définie dans l'architecture v1.1
**When** le développeur vérifie `schema.prisma`
**Then** si le champ n'est pas encore appliqué, une migration `add_min_stock_level_to_catalog_items` est générée et appliquée
**And** le champ est `Decimal?` nullable — absence = pas d'alerte pour cet article

**AC2 — Endpoint PATCH minStockLevel :**

**Given** `PATCH /api/v1/catalog/:id` est appelé avec `{ "minStockLevel": 5 }`
**When** la requête est validée
**Then** le champ `minStockLevel` est mis à jour pour l'article du tenant
**And** la réponse renvoie l'article mis à jour avec `minStockLevel`
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

**AC3 — Évaluation post-mouvement de stock :**

**Given** un `InventoryMovement` de type `SALE`, `LOSS`, `TRANSFER_OUT`, ou `ADJUSTMENT` (quantité négative) est créé
**When** l'`InventoryService` traite le mouvement
**Then** pour chaque `catalogItemId` concerné, si `stockQuantity ≤ minStockLevel` et `minStockLevel IS NOT NULL`
**And** une entrée `StockAlert` est upserted (ou un événement `LowStockDetected` est émis sur l'Event Bus)
**And** si `stockQuantity > minStockLevel`, aucune alerte n'est créée / l'alerte existante est résolue automatiquement

**AC4 — Endpoint GET alertes actives :**

**Given** `GET /api/v1/stock-alerts` est appelé
**When** le backend répond
**Then** la réponse renvoie la liste des articles dont `stockQuantity ≤ minStockLevel` pour le tenant courant
**And** chaque entrée inclut : `catalogItemId`, `itemName`, `stockQuantity`, `minStockLevel`, `deficit` (minStockLevel − stockQuantity)
**And** les résultats sont triés par `deficit` décroissant (articles les plus critiques en premier)
**And** l'endpoint supporte `?limit=` et `?offset=` pour la pagination

**AC5 — Endpoint GET count alertes actives :**

**Given** `GET /api/v1/stock-alerts/count` est appelé
**When** le backend répond
**Then** la réponse renvoie `{ criticalCount: number }` — nombre d'articles sous seuil pour le tenant
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

**Notes dev :**
- Créer `StockAlertsModule` dans `apps/backend/src/shared/stock-alerts/`
- L'évaluation post-mouvement peut être synchrone (dans la transaction) ou via Event Bus (`LowStockDetected`) — privilégier Event Bus pour découplage
- Pas de table `StockAlert` dédiée si on préfère une vue calculée — acceptable en MVP (query `WHERE stockQuantity <= minStockLevel`)

**Files to create:**
- `apps/backend/src/shared/stock-alerts/stock-alerts.module.ts`
- `apps/backend/src/shared/stock-alerts/stock-alerts.service.ts`
- `apps/backend/src/shared/stock-alerts/stock-alerts.controller.ts`
- `apps/backend/src/shared/stock-alerts/dto/stock-alert.dto.ts`

**Files to modify:**
- `apps/backend/src/shared/inventory/inventory.service.ts` — émettre `LowStockDetected` après mouvement décrémentant
- `apps/backend/prisma/schema.prisma` — vérifier/appliquer `minStockLevel` sur `CatalogItem`

---

### Story 22-2: Frontend — Configuration seuil dans ProductFormDialog + badge catalogue

**As a** owner or manager,
**I want** to set a minimum stock threshold on each product and see a visual badge when that threshold is breached,
**So that** I can identify at-risk articles at a glance in the catalog (FR81, FR82).

**Acceptance Criteria:**

**AC1 — Champ minStockLevel dans ProductFormDialog :**

**Given** l'utilisateur ouvre `ProductFormDialog` pour créer ou éditer un article
**When** le formulaire s'affiche
**Then** un champ optionnel "Seuil stock bas" (type: nombre décimal, label: "Alerte si stock ≤") est visible
**And** si le champ est vide, aucune alerte ne sera générée pour cet article (placeholder : "Désactivé")
**And** le champ accepte des valeurs décimales (ex. 2.5 pour articles au poids)

**AC2 — Sauvegarde du seuil :**

**Given** l'utilisateur saisit `5` dans le champ "Seuil stock bas" et soumet le formulaire
**When** l'appel `PATCH /api/v1/catalog/:id` est exécuté
**Then** `minStockLevel: 5` est inclus dans le payload
**And** la réponse est reflétée dans le modèle `Product` local (Isar mis à jour)
**And** un message de confirmation "Seuil enregistré" apparaît en snackbar

**AC3 — Badge rouge sur article sous seuil dans la grille catalogue :**

**Given** un article a `stockQuantity ≤ minStockLevel` (et `minStockLevel != null`)
**When** la grille catalogue s'affiche
**Then** une icône d'alerte (triangle orange ou badge rouge) apparaît sur la card de l'article
**And** le tooltip ou sous-label indique "Stock critique : X restants" (X = stockQuantity)
**And** les articles sans seuil configuré n'affichent aucun badge

**AC4 — Offline :**

**Given** l'appareil est hors ligne
**When** l'utilisateur ouvre le catalogue
**Then** les badges de stock bas sont calculés localement depuis le modèle Isar (stockQuantity vs minStockLevel)
**And** aucun appel réseau n'est requis pour afficher les badges

**Notes dev :**
- Ajouter `minStockLevel` au modèle `Product` Dart et au `fromJson`
- La logique de badge est pure (pas de provider supplémentaire) : `product.minStockLevel != null && product.stockQuantity <= product.minStockLevel`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `minStockLevel`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — ajouter champ seuil
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — badge alerte
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — passer `minStockLevel` au PATCH

---

### Story 22-3: Frontend — Écran alertes + KPI dashboard "Stock critique"

**As a** manager or owner,
**I want** a dedicated low-stock alerts screen and a persistent dashboard KPI,
**So that** I can act quickly on replenishment decisions without scanning the full catalog (FR82).

**Acceptance Criteria:**

**AC1 — KPI "Stock critique" sur le dashboard :**

**Given** le dashboard backoffice (`DashboardScreen`) est chargé
**When** la section KPI s'affiche
**Then** une card "Stock critique" affiche le nombre d'articles sous seuil (`criticalCount` de `GET /api/v1/stock-alerts/count`)
**And** si criticalCount > 0, la card est colorée en orange/rouge (couleur d'alerte)
**And** si criticalCount = 0, la card affiche "0 — Tout va bien" en vert
**And** tapper la card navigue vers `StockAlertsScreen`

**AC2 — Écran StockAlertsScreen :**

**Given** l'utilisateur navigue vers `StockAlertsScreen`
**When** l'écran se charge
**Then** une liste d'articles sous seuil est affichée, triée par déficit décroissant
**And** chaque item affiche : nom de l'article, stock actuel, seuil configuré, et déficit en rouge
**And** un bouton "Réapprovisionner" sur chaque item navigue vers `CreatePurchaseOrderSheet` pré-rempli avec l'article
**And** si aucune alerte, l'écran affiche un état vide "Aucun stock critique"

**AC3 — Refresh automatique :**

**Given** l'écran alertes est visible
**When** un mouvement de stock est synchronisé (post-vente, post-perte)
**Then** le provider est invalidé et la liste se rafraîchit automatiquement
**And** si un article repasse au-dessus de son seuil, il disparaît de la liste

**AC4 — Accès rôle :**

**Given** un utilisateur avec le rôle `commercial` accède au dashboard
**When** le dashboard s'affiche
**Then** la card KPI "Stock critique" est masquée (visible uniquement pour `owner` et `manager`)

**Notes dev :**
- `StockAlertsScreen` dans `apps/frontend/lib/features/shared/stock_alerts/presentation/screens/`
- Provider : `stockAlertsProvider` (Riverpod AutoDisposeFutureProvider)
- Le bouton "Réapprovisionner" nécessite Epic 21 complété (navigation vers CreatePurchaseOrderSheet)

**Files to create:**
- `apps/frontend/lib/features/shared/stock_alerts/presentation/screens/stock_alerts_screen.dart`
- `apps/frontend/lib/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart`
- `apps/frontend/lib/features/shared/stock_alerts/data/repositories/stock_alerts_repository.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — ajouter KPI "Stock critique"

---

### Story 22-4: Backend — Service notification (cron/event, push in-app v1)

**As a** backend developer,
**I want** a notification service that listens for low-stock events and sends in-app push notifications to authorized users,
**So that** managers and owners are alerted in real-time when stock drops below threshold (FR82).

**Acceptance Criteria:**

**AC1 — Listener LowStockDetected :**

**Given** l'Event Bus reçoit un événement `LowStockDetected { tenantId, catalogItemId, itemName, stockQuantity, minStockLevel }`
**When** le `NotificationService` traite l'événement
**Then** une notification in-app est persistée pour tous les utilisateurs du tenant ayant le rôle `owner` ou `manager`
**And** la notification contient : titre "Stock critique", corps "X — il reste Y unité(s) (seuil : Z)", et `catalogItemId` comme deep-link cible
**And** la notification est marquée `unread` à la création

**AC2 — Endpoint GET notifications non lues :**

**Given** `GET /api/v1/notifications?unread=true` est appelé
**When** le backend répond
**Then** la réponse renvoie la liste des notifications non lues de l'utilisateur courant
**And** chaque notification inclut : `id`, `title`, `body`, `type`, `targetId`, `createdAt`, `isRead`
**And** l'endpoint est paginé (`?limit=`, `?offset=`)

**AC3 — Endpoint POST marquer comme lue :**

**Given** `POST /api/v1/notifications/:id/read` est appelé
**When** le backend répond
**Then** la notification est marquée `isRead: true`
**And** la réponse renvoie `{ success: true }`

**AC4 — Endpoint GET count non lues :**

**Given** `GET /api/v1/notifications/unread-count` est appelé
**When** le backend répond
**Then** la réponse renvoie `{ unreadCount: number }`
**And** ce count est utilisé par le frontend pour afficher le badge de notification dans l'AppBar

**AC5 — Isolation tenant :**

**Given** deux tenants ont des alertes stock bas
**When** l'endpoint notifications est appelé pour un utilisateur du tenant A
**Then** seules les notifications du tenant A sont retournées — aucune fuite cross-tenant

**Notes dev :**
- Créer `NotificationsModule` dans `apps/backend/src/shared/notifications/`
- Table `notifications` dans le schema `shared` : `id`, `tenantId`, `userId`, `type`, `title`, `body`, `targetId`, `isRead`, `createdAt`
- Phase 2b : intégration WhatsApp Business API (hors scope de cette story)
- Phase 2b : FCM/APNs push mobile (hors scope — in-app only pour v1)

**Files to create:**
- `apps/backend/src/shared/notifications/notifications.module.ts`
- `apps/backend/src/shared/notifications/notifications.service.ts`
- `apps/backend/src/shared/notifications/notifications.controller.ts`
- `apps/backend/src/shared/notifications/dto/notification.dto.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_notifications_table/migration.sql`

**Files to modify:**
- `apps/backend/src/shared/stock-alerts/stock-alerts.service.ts` — émettre `LowStockDetected`
- `apps/backend/src/app.module.ts` — enregistrer `NotificationsModule`

---

### Story 22-5: Backend — Résumé quotidien (FR86) + config canal par tenant dans panel admin

**As a** owner,
**I want** to receive a daily summary notification at a configured time, and to control this setting from the admin panel,
**So that** I stay informed of daily performance without opening the app every day (FR86).

**Acceptance Criteria:**

**AC1 — Config tenant pour résumé quotidien :**

**Given** `PATCH /api/v1/tenants/notification-settings` est appelé avec `{ dailySummaryEnabled: true, dailySummaryTime: "18:00", notificationChannel: "in_app" }`
**When** la requête est validée
**Then** les champs `dailySummaryEnabled`, `dailySummaryTime`, `notificationChannel` sont mis à jour sur le `Tenant`
**And** seul un utilisateur avec le rôle `owner` peut appeler cet endpoint
**And** la réponse renvoie les settings mis à jour

**AC2 — Cron job résumé quotidien :**

**Given** le cron job `DailySummaryJob` est planifié et `dailySummaryEnabled = true` pour un tenant
**When** l'heure locale du tenant (timezone) atteint `dailySummaryTime`
**Then** le système calcule pour la journée : total ventes (`transactionCount`), chiffre d'affaires (`totalRevenue`), nouvelles alertes stock bas (`newAlerts`), commandes en attente (`pendingPOs`)
**And** une notification in-app est persistée pour tous les `owner` du tenant
**And** le corps de la notification inclut ces 4 métriques formatées

**AC3 — Canal WhatsApp (stub Phase 2b) :**

**Given** `notificationChannel = "whatsapp"` est configuré
**When** le résumé quotidien est envoyé
**Then** le système log "WhatsApp channel not yet implemented — fallback to in_app" et envoie la notification in-app
**And** aucune erreur n'est levée (graceful degradation)

**AC4 — Frontend — Section "Notifications" dans le panel admin tenant :**

**Given** l'administrateur ouvre le panel de configuration tenant (`TenantSettingsScreen`)
**When** la section "Notifications" s'affiche
**Then** un toggle "Résumé quotidien activé" est visible
**And** si le toggle est ON, un champ "Heure d'envoi" (time picker, format HH:mm) est visible
**And** un sélecteur "Canal" propose "Application (in-app)" et "WhatsApp (bientôt disponible)" (WhatsApp grisé)
**And** les modifications sont sauvegardées via `PATCH /api/v1/tenants/notification-settings`

**AC5 — Timezone awareness :**

**Given** le cron job évalue quels tenants envoyer
**When** le job s'exécute toutes les minutes
**Then** seuls les tenants dont `dailySummaryTime` correspond à l'heure courante dans leur `timezone` sont traités
**And** chaque tenant n'est traité qu'une fois par jour (idempotence via un flag `lastSummarySentDate`)

**Notes dev :**
- Utiliser `@nestjs/schedule` (`@Cron('* * * * *')`) pour le job minute-by-minute
- `lastSummarySentDate` peut être un champ `DateTime?` sur `Tenant` ou une entrée dans un cache Redis (MVP : champ Tenant)
- Le calcul des métriques réutilise les services existants : `TransactionsService`, `StockAlertsService`, `PurchaseOrdersService`

**Files to create:**
- `apps/backend/src/shared/notifications/jobs/daily-summary.job.ts`

**Files to modify:**
- `apps/backend/src/kernel/tenants/tenants.controller.ts` — ajouter `PATCH notification-settings`
- `apps/backend/src/kernel/tenants/tenants.service.ts` — méthode `updateNotificationSettings`
- `apps/backend/prisma/schema.prisma` — vérifier/appliquer champs notification sur `Tenant`
- `apps/frontend/lib/features/admin/presentation/screens/tenant_settings_screen.dart` — section Notifications
- Backend: `GET /api/v1/purchase-orders/stats` dans `purchase-orders.controller.ts`

---

## Epic 23: Conversion unités vrac → détail

### Story 23-1: Backend — parentItemId + conversionRate sur CatalogItem + logique REPACKAGING

**As a** backend developer,
**I want** parent-child article relationships persisted and the POS sale endpoint to automatically decrement parent stock when a child article is sold,
**So that** bulk → retail unit stock tracking is automated and fully traced (FR83).

**Acceptance Criteria:**

**AC1 — Migration parentItemId + conversionRate :**

**Given** les champs `parentItemId` et `conversionRate` sont définis dans l'architecture v1.1 pour `CatalogItem`
**When** le développeur applique la migration Prisma
**Then** `parentItemId String? @map("parent_item_id") @db.Uuid` est présent sur `catalog_items`
**And** `conversionRate Decimal? @map("conversion_rate") @db.Decimal(10, 4)` est présent
**And** les deux champs sont nullable — absence = article autonome sans relation parent

**AC2 — Validation relation parent-enfant :**

**Given** `PATCH /api/v1/catalog/:id` est appelé avec `{ "parentItemId": "uuid", "conversionRate": 0.02 }`
**When** le service valide la relation
**Then** le parent référencé doit appartenir au même tenant (`tenantId` identique) — sinon erreur 400
**And** pas de référence circulaire tolérée (A → B → A) — le service vérifie 1 niveau
**And** profondeur max = 1 : un article enfant ne peut pas lui-même avoir des enfants
**And** `conversionRate` doit être > 0 et ≤ 1 pour les sous-unités (ex: sachet = 0.02 sac)

**AC3 — Décrémentation stock parent à la vente :**

**Given** un article enfant avec `parentItemId` et `conversionRate` est vendu au POS
**When** `POST /api/v1/transactions` traite la vente
**Then** le stock de l'article enfant n'est PAS décrémenté (l'enfant n'a pas de stock propre)
**And** le stock du parent est décrémenté de `quantity × conversionRate` (ex: 3 sachets × 0.02 = 0.06 sac)
**And** un `InventoryMovement` de type `REPACKAGING` est créé avec `catalogItemId` = parent, `quantity` = -(quantity × conversionRate), `referenceId` = transactionId

**AC4 — Endpoint GET articles enfants d'un parent :**

**Given** `GET /api/v1/catalog/:id/children` est appelé
**When** le backend répond
**Then** la réponse liste tous les articles dont `parentItemId` = `:id` pour le tenant courant
**And** chaque entrée inclut `id`, `name`, `unitType`, `pricePerUnit`, `conversionRate`

**AC5 — Vérification stock parent insuffisant :**

**Given** la vente d'un article enfant décrémenterait le stock parent en dessous de 0
**When** la transaction est traitée
**Then** le backend renvoie un avertissement `{ warning: "PARENT_STOCK_LOW", parentItemName: string, parentStockAfter: number }` dans la réponse (non bloquant — la vente passe quand même)
**And** le stock parent peut devenir négatif (comportement identique aux articles ordinaires)

**Notes dev :**
- Si l'article enfant a aussi son propre `conversionRate` (FR78 sans `parentItemId`), les deux logiques coexistent : `parentItemId` déclenche la décrémentation parent, le `conversionRate` autonome décrémente self
- Le type `REPACKAGING` est ajouté à l'enum commentaire de `InventoryMovement`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter `parentItemId`, `conversionRate` à `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — validation parent-enfant + endpoint children
- `apps/backend/src/shared/catalog/catalog.controller.ts` — `GET /:id/children`
- `apps/backend/src/shared/transactions/transactions.service.ts` — décrémentation parent lors d'une vente

---

### Story 23-2: Frontend — Formulaire conversion dans ProductFormDialog

**As a** owner or manager,
**I want** to link a child article to a parent bulk article and configure the conversion factor from the product form,
**So that** I can set up bulk → retail splits without leaving the admin UI (FR83).

**Acceptance Criteria:**

**AC1 — Section "Lié à un article parent" dans ProductFormDialog :**

**Given** l'utilisateur ouvre `ProductFormDialog` pour créer ou éditer un article
**When** le formulaire s'affiche
**Then** une section optionnelle "Reconditionnement" est visible, avec un toggle "Cet article est un détail d'un article vrac"
**And** si le toggle est OFF, les champs de relation sont masqués
**And** si le toggle est ON, deux champs apparaissent : "Article parent" (autocomplete) et "Facteur de conversion" (nombre décimal > 0)

**AC2 — Autocomplete article parent :**

**Given** l'utilisateur saisit du texte dans le champ "Article parent"
**When** l'autocomplete se déclenche (≥ 2 caractères)
**Then** la liste propose les articles du tenant qui ne sont pas eux-mêmes des articles enfants (pas de `parentItemId` défini)
**And** l'article en cours d'édition est exclu de la liste (pas d'auto-référence)
**And** chaque résultat affiche : nom, unitType, stock actuel

**AC3 — Affichage du facteur de conversion :**

**Given** l'utilisateur a sélectionné un article parent et saisi un facteur de conversion (ex: 0.02)
**When** le facteur est confirmé
**Then** un texte d'aide s'affiche sous le champ : "Vendre 1 [label enfant] décrémente [1/facteur] → [facteur] [unitLabel parent]" (ex: "Vendre 1 sachet décrémente 0.02 sac")
**And** si le facteur est invalide (≤ 0 ou > 1), une erreur de validation s'affiche

**AC4 — Sauvegarde :**

**Given** l'utilisateur soumet le formulaire avec parentItemId + conversionRate
**When** `PATCH /api/v1/catalog/:id` est appelé
**Then** `parentItemId` et `conversionRate` sont inclus dans le payload
**And** le modèle `Product` Dart est mis à jour avec ces champs

**AC5 — Fiche parent — liste des articles enfants :**

**Given** l'utilisateur ouvre la fiche d'un article parent (via le catalogue)
**When** la fiche s'affiche
**Then** une section "Articles détail liés" liste les articles enfants avec leur facteur de conversion
**And** chaque enfant est cliquable pour ouvrir son `ProductFormDialog`

**Notes dev :**
- Ajouter `parentItemId` et `conversionRate` au modèle `Product` Dart et `fromJson`
- L'autocomplete peut réutiliser le `catalogSearchProvider` existant avec un filtre `hasNoParent=true`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `parentItemId`, `conversionRate`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section Reconditionnement
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — PATCH avec nouveaux champs

---

### Story 23-3: Frontend — POS vente du produit enfant (décrémente stock parent)

**As a** cashier,
**I want** to sell child articles (sachets, portions) at the POS with automatic parent stock tracking and a clear warning when parent stock is low,
**So that** bulk consumption is tracked without manual intervention (FR83).

**Acceptance Criteria:**

**AC1 — Vente article enfant au POS — flux normal :**

**Given** un article enfant (avec `parentItemId`) est ajouté au panier
**When** la transaction est validée
**Then** la vente se complète normalement — aucune différence visible pour le caissier
**And** le backend décrémente le stock du parent (Story 23-1 AC3)
**And** le reçu affiche l'article enfant vendu (nom, quantité, prix) sans mention du parent

**AC2 — Alerte stock parent faible :**

**Given** la transaction renvoie `warning: "PARENT_STOCK_LOW"` dans la réponse
**When** la transaction est confirmée
**Then** une snackbar orange apparaît après validation : "Stock faible : [nomParent] — [stockAfter] [unitLabel] restant(s)"
**And** la snackbar est non bloquante (ne nécessite pas d'action) et disparaît après 4 secondes
**And** la vente n'est PAS annulée — la snackbar est informationnelle uniquement

**AC3 — Grille POS — badge "vrac" sur article parent :**

**Given** un article a des enfants liés (`hasChildren = true`)
**When** la grille POS s'affiche
**Then** un badge discret "VRAC" apparaît sur la card de l'article parent pour signaler qu'il ne se vend pas à l'unité directement
**And** les articles enfants n'ont pas ce badge

**AC4 — Stock parent local mis à jour après vente :**

**Given** une vente d'article enfant est synchronisée
**When** la sync retour met à jour les stocks locaux
**Then** le stock local du parent (dans Isar) est décrémenté de `quantity × conversionRate`
**And** si le stock parent passe sous `minStockLevel`, l'alerte stock bas (Epic 22) se déclenche

**Notes dev :**
- Le `cartNotifier` doit lire `parentItemId` pour informer l'UI post-validation
- La logique de décrémentation parent est entièrement backend — le frontend ne calcule pas, il affiche le warning du backend
- Le badge "VRAC" sur la card parent est optionnel MVP — peut être un simple chip texte

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — lire `warning` de la réponse transaction
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — afficher snackbar alerte parent
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — badge VRAC sur article parent

---

## Epic 24: Fraîcheur + code couleur priorité vente

### Story 24-1: Backend — ProductBatch + expiryDays + endpoints expiring

**As a** backend developer,
**I want** a `ProductBatch` model tracking freshness per reception lot, and endpoints to query expiring articles,
**So that** the system can drive color-coded freshness indicators and the "Fraîcheur" tab (FR84, FR85).

**Acceptance Criteria:**

**AC1 — Migration expiryDays + shrinkageTolerance sur CatalogItem :**

**Given** les champs sont définis dans l'architecture v1.1
**When** la migration est appliquée
**Then** `expiryDays Int? @map("expiry_days")` est présent sur `catalog_items`
**And** `shrinkageTolerance Decimal? @map("shrinkage_tolerance") @db.Decimal(5, 2)` est présent
**And** les deux sont nullable — absence = fraîcheur non trackée pour cet article

**AC2 — Migration ProductBatch :**

**Given** le modèle `ProductBatch` est défini dans l'architecture v1.1 (§4.2.12)
**When** la migration est appliquée
**Then** la table `prod_batches` existe dans le schema `shared` avec les colonnes : `id`, `catalog_item_id`, `tenant_id`, `received_at`, `expires_at`, `initial_qty`, `remaining_qty`, `batch_ref`, `is_depleted`, `created_at`
**And** un index existe sur `(tenant_id, expires_at)` pour les requêtes de tri par expiration

**AC3 — Création automatique ProductBatch à la réception :**

**Given** une réception fournisseur est enregistrée (`POST /api/v1/inventory/receive` ou via Epic 21 `POST /api/v1/purchase-orders/:id/receive`)
**When** l'article reçu a `expiryDays != null`
**Then** un `ProductBatch` est créé avec : `receivedAt = now()`, `expiresAt = now() + expiryDays days`, `initialQty = receivedQuantity`, `remainingQty = receivedQuantity`
**And** si `expiryDays = null`, aucun batch n'est créé (article non tracé)

**AC4 — Dépletion FIFO des batches à la vente :**

**Given** un article avec des batches actifs est vendu au POS
**When** la transaction est traitée
**Then** le batch avec la date `expiresAt` la plus ancienne est consommé en premier (FIFO)
**And** `remainingQty` est décrémenté de la quantité vendue
**And** si `remainingQty ≤ 0`, le batch est marqué `isDepleted = true`
**And** si la vente dépasse le `remainingQty` d'un batch, le surplus est prélevé sur le batch suivant (cascade)

**AC5 — Endpoint GET articles expirant :**

**Given** `GET /api/v1/batches/expiring?days=7` est appelé
**When** le backend répond
**Then** la réponse liste les batches dont `expiresAt ≤ now() + 7 days` et `isDepleted = false` pour le tenant
**And** chaque entrée inclut : `batchId`, `catalogItemId`, `itemName`, `expiresAt`, `remainingQty`, `freshnessPercent` (% de fenêtre restante = (expiresAt − now) / expiryDays × 100)
**And** les résultats sont triés par `expiresAt` croissant (plus urgents en premier)
**And** `GET /api/v1/batches/expiring/count` renvoie `{ urgentCount: number }` (batches avec `freshnessPercent < 50%`)

**AC6 — Tolérance rétrécissement sur mouvements LOSS :**

**Given** un mouvement de stock de type `LOSS` est enregistré pour un article avec `shrinkageTolerance`
**When** la quantité perdue est ≤ `shrinkageTolerance %` du stock total
**Then** le mouvement est enregistré avec `reason: "NATURAL_VARIANCE"` (pas une perte signalée)
**And** ce mouvement n'apparaît pas dans les KPIs de pertes du dashboard

**Notes dev :**
- La dépletion FIFO est optionnelle en MVP — acceptable de décrémenter le stock global sans tracker le batch précis ; tracker le batch est la v2
- `ProductBatch` est dans `@@schema("shared")`

**Files to create:**
- `apps/backend/src/shared/batches/batches.module.ts`
- `apps/backend/src/shared/batches/batches.service.ts`
- `apps/backend/src/shared/batches/batches.controller.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_product_batches/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter `expiryDays`, `shrinkageTolerance` à `CatalogItem` + modèle `ProductBatch`
- `apps/backend/src/shared/inventory/inventory.service.ts` — créer batch à la réception + dépletion FIFO

---

### Story 24-2: Frontend — Code couleur dans catalogue et POS (vert/orange/rouge)

**As a** cashier or manager,
**I want** a color freshness indicator on product cards in the POS grid and catalog,
**So that** I can prioritize selling perishable articles before they expire (FR85).

**Acceptance Criteria:**

**AC1 — Widget indicateur fraîcheur :**

**Given** un article a `expiryDays != null` et un batch actif
**When** la card de l'article s'affiche (POS grid ou catalogue)
**Then** une bande de couleur ou un chip apparaît sur la card : **Vert** si `freshnessPercent > seuil_vert` (défaut 50%), **Orange** si entre `seuil_orange` et `seuil_vert` (défaut 20–50%), **Rouge** si `freshnessPercent < seuil_orange` ou date dépassée
**And** le chip affiche le nombre de jours restants (ex: "3j" en rouge, "12j" en vert)
**And** les articles sans `expiryDays` ou sans batch actif n'affichent aucun indicateur

**AC2 — Seuils configurables par tenant :**

**Given** l'owner modifie les seuils dans les paramètres tenant (`PATCH /api/v1/tenants/freshness-thresholds`)
**When** les seuils sont mis à jour (`greenThreshold: 50, orangeThreshold: 20`)
**Then** tous les indicateurs couleur recalculent selon les nouveaux seuils
**And** les seuils sont persistés et chargés au démarrage de l'app (Isar local)

**AC3 — Tri priorité orange/rouge dans la grille POS :**

**Given** la grille POS s'affiche
**When** des articles avec indicateurs orange ou rouge sont présents
**Then** ces articles apparaissent en premier dans la grille (avant les verts et les sans-indicateur)
**And** à l'intérieur du groupe rouge, tri par `expiresAt` croissant (plus urgent en premier)
**And** le tri fraîcheur est appliqué après le tri par catégorie (catégorie est prioritaire)

**AC4 — Filtre "Articles urgents" dans la grille POS :**

**Given** l'utilisateur est dans la grille POS
**When** il active le filtre "Articles urgents" (toggle ou chip dans la barre de filtres)
**Then** seuls les articles avec indicateur orange ou rouge sont affichés
**And** le filtre est persisté pour la session POS courante (disparaît à la fermeture du panier)

**AC5 — Offline :**

**Given** l'appareil est hors ligne
**When** la grille POS ou le catalogue s'affiche
**Then** la couleur est calculée localement depuis le batch Isar le plus récent de l'article (`expiresAt` vs date locale)
**And** aucun appel réseau n'est requis pour afficher les indicateurs

**Notes dev :**
- Créer un widget `FreshnessChip` réutilisable (couleur + texte jours)
- `freshnessPercent` peut être calculé localement : `(expiresAt.difference(now).inDays / expiryDays) × 100`
- Le modèle `Product` Dart doit exposer le batch courant (`nearestExpiryDate`, `freshnessPercent`)

**Files to create:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/freshness_chip.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `nearestExpiryDate`, `expiryDays`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — tri priorité + filtre urgent + chip fraîcheur
- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — toggle filtre urgent

---

### Story 24-3: Frontend — Onglet Fraîcheur dans InventoryScreen + action déclasser

**As a** manager,
**I want** a dedicated "Fraîcheur" tab in the inventory hub showing all expiring batches, with a declassify action,
**So that** I can proactively manage perishable stock and record natural shrinkage (FR84, FR85).

**Acceptance Criteria:**

**AC1 — Onglet "Fraîcheur" dans InventoryScreen :**

**Given** l'utilisateur ouvre le hub inventaire (`InventoryScreen`)
**When** les onglets s'affichent
**Then** un onglet "Fraîcheur" est ajouté aux onglets existants (Réceptions · Transferts · Pertes · Inventaire · Commandes)
**And** un badge numérique orange/rouge apparaît sur l'onglet si `urgentCount > 0`
**And** l'onglet charge `FreshnessScreen`

**AC2 — FreshnessScreen — liste des lots :**

**Given** `FreshnessScreen` se charge
**When** les données sont disponibles
**Then** la liste affiche tous les batches actifs avec fraîcheur trackée, triés par `expiresAt` croissant
**And** chaque item affiche : nom de l'article, date d'expiration, jours restants, quantité restante, indicateur couleur
**And** des sections séparent : "Expirés" (rouges dépassés), "Urgents" (rouges non dépassés), "À surveiller" (orange), "OK" (verts)
**And** si aucun batch urgent, l'écran affiche un état vide "Tous vos lots sont frais"

**AC3 — Action "Déclasser" un lot :**

**Given** l'utilisateur appuie longuement sur un item ou ouvre son menu contextuel
**When** il sélectionne "Déclasser"
**Then** une bottom sheet s'ouvre avec : quantité à déclasser (pré-remplie avec `remainingQty`), motif ("Péremption", "Détérioration qualité", "Variance naturelle")
**And** si le motif = "Variance naturelle" et la quantité ≤ `shrinkageTolerance %`, le formulaire indique "Sera enregistré comme variance naturelle (non comptabilisé en perte)"
**And** à la validation, un mouvement `LOSS` est créé avec le motif sélectionné et le batch est marqué `isDepleted = true`

**AC4 — KPI dashboard "Lots urgents" :**

**Given** le dashboard backoffice est chargé
**When** la section KPI s'affiche
**Then** une card "Lots urgents" affiche `urgentCount` (batches avec `freshnessPercent < orangeThreshold`)
**And** si urgentCount > 0, la card est colorée en orange
**And** tapper la card navigue vers `InventoryScreen` avec l'onglet "Fraîcheur" sélectionné

**Notes dev :**
- `FreshnessScreen` dans `apps/frontend/lib/features/shared/freshness/presentation/screens/`
- Le provider recharge depuis `GET /api/v1/batches/expiring?days=90` (large fenêtre pour tout afficher)
- L'action "Déclasser" réutilise l'endpoint de déclaration de perte existant (`POST /api/v1/inventory/loss`)

**Files to create:**
- `apps/frontend/lib/features/shared/freshness/presentation/screens/freshness_screen.dart`
- `apps/frontend/lib/features/shared/freshness/presentation/widgets/declassify_sheet.dart`
- `apps/frontend/lib/features/shared/freshness/presentation/providers/freshness_provider.dart`

**Files to modify:**
- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — ajouter onglet Fraîcheur
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — KPI "Lots urgents"

---

## Epic 25: Variantes, multi-tarifs & promotions

### Story 25-1: Backend — ProductVariant + endpoints CRUD

**As a** backend developer,
**I want** a `ProductVariant` model with its own price, stock and attributes, linked to a parent `CatalogItem`,
**So that** articles can have multiple sellable variants (size S/M/L, color blue/red) with independent inventory (FR89).

**Acceptance Criteria:**

**AC1 — Migration ProductVariant :**

**Given** le modèle `ProductVariant` est défini dans l'architecture v1.1 (§4.2.7)
**When** la migration est appliquée
**Then** la table `prod_variants` existe dans le schema `shared` avec : `id`, `catalog_item_id`, `tenant_id`, `sku`, `barcode`, `price`, `stock_quantity`, `attributes` (Json), `is_active`, `created_at`, `updated_at`
**And** `catalog_items.has_variants` est un booléen permettant de savoir si l'article parent a des variantes actives
**And** un index existe sur `(tenant_id, catalog_item_id)`

**AC2 — CRUD variantes :**

**Given** `POST /api/v1/catalog/:id/variants` est appelé avec `{ sku, price, stockQuantity, attributes: { taille: "M", couleur: "Bleu" } }`
**When** la requête est validée
**Then** une variante est créée liée à l'article parent du tenant
**And** `CatalogItem.hasVariants` est mis à `true` automatiquement si c'est la première variante active
**And** `GET /api/v1/catalog/:id/variants` retourne toutes les variantes actives de l'article
**And** `PATCH /api/v1/catalog/:id/variants/:variantId` permet de modifier prix, stock, attributs
**And** `DELETE /api/v1/catalog/:id/variants/:variantId` désactive la variante (`isActive = false`)

**AC3 — Stock agrégé sur l'article parent :**

**Given** un article parent a 3 variantes avec des stocks respectifs de 10, 5, 8
**When** `GET /api/v1/catalog/:id` est appelé
**Then** la réponse inclut `totalStockQuantity: 23` (somme des `stockQuantity` des variantes actives)
**And** le stock de l'article parent lui-même (`RetailProduct.stockQuantity`) n'est pas utilisé quand `hasVariants = true`

**AC4 — Lookup par barcode de variante :**

**Given** le caissier scanne un barcode de variante
**When** `GET /api/v1/catalog/barcode/:barcode` est appelé
**Then** si le barcode correspond à une variante, la réponse inclut l'article parent ET la variante correspondante (`matchedVariant: { id, attributes, price, stockQuantity }`)
**And** le flux POS sélectionne automatiquement la variante sans étape manuelle

**AC5 — Décrémentation stock variante à la vente :**

**Given** une variante est vendue au POS
**When** la transaction est traitée
**Then** `stockQuantity` de la variante spécifique est décrémenté (pas celui du parent)
**And** un `InventoryMovement` de type `SALE` est créé avec `catalogItemId` = parent et `variantId` = variante

**Notes dev :**
- Ajouter `variantId String? @map("variant_id") @db.Uuid` à `InventoryMovement` pour tracer les mouvements par variante
- Les attributs `{ taille, couleur }` sont libres (Json) — pas d'enum fixe côté backend

**Files to create:**
- `apps/backend/src/shared/catalog/variants/variants.service.ts`
- `apps/backend/src/shared/catalog/variants/variants.controller.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_product_variants/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter modèle `ProductVariant`, `hasVariants` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — `totalStockQuantity` agrégé + barcode lookup
- `apps/backend/src/shared/transactions/transactions.service.ts` — décrémenter stock variante

---

### Story 25-2: Frontend — Gestion variantes dans le catalogue (attributs configurables)

**As a** owner or manager,
**I want** to define variants for an article with tenant-configurable attribute labels, directly from the product sheet,
**So that** I can manage different sizes, colors, or grades without creating separate catalog entries (FR89).

**Acceptance Criteria:**

**AC1 — Toggle "Cet article a des variantes" dans ProductFormDialog :**

**Given** l'utilisateur édite un article dans `ProductFormDialog`
**When** il active le toggle "Cet article a des variantes"
**Then** une section "Variantes" apparaît avec un bouton "Ajouter une variante"
**And** un avertissement s'affiche : "Le prix et le stock de l'article seront gérés par variante"
**And** si des variantes existent déjà, elles sont listées sous forme de chips éditables

**AC2 — Formulaire de création de variante :**

**Given** l'utilisateur clique "Ajouter une variante"
**When** la bottom sheet s'ouvre
**Then** il peut saisir : SKU (optionnel), barcode (optionnel), prix (requis), stock initial (requis), et 1 à N attributs libres (ex: `Taille = XL`)
**And** les labels d'attributs proposés en autocomplete sont ceux définis dans les paramètres tenant (ex: "Taille", "Couleur", "Grade")
**And** le tenant peut créer de nouveaux labels d'attributs à la volée depuis ce formulaire

**AC3 — Vue liste variantes dans la fiche article :**

**Given** un article a des variantes
**When** sa fiche s'affiche dans le catalogue
**Then** un tableau récapitulatif liste les variantes avec : attributs, SKU, prix, stock
**And** chaque ligne est cliquable pour éditer la variante
**And** un agrégat "Stock total : X" est affiché en en-tête

**AC4 — Gestion attributs tenant depuis les paramètres :**

**Given** l'owner ouvre les paramètres catalogue
**When** la section "Attributs variantes" s'affiche
**Then** il peut créer/renommer/supprimer les labels d'attributs disponibles (ex: "Pointure", "Parfum")
**And** ces labels sont synchronisés sur tous les appareils

**Files to modify:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section variantes
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `hasVariants`, `variants`

**Files to create:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/variant_form_sheet.dart`
- `apps/frontend/lib/features/shared/catalog/data/models/product_variant.dart`

---

### Story 25-3: Frontend — POS sélection variante à la vente

**As a** cashier,
**I want** a variant selector to appear automatically when I tap an article with variants,
**So that** I can sell the exact variant the customer wants without leaving the POS screen (FR89).

**Acceptance Criteria:**

**AC1 — Sélecteur de variante au tap :**

**Given** un article avec `hasVariants = true` est tappé dans la grille POS
**When** la grille détecte le tap
**Then** une bottom sheet `VariantSelectorSheet` s'ouvre avec la liste des variantes actives
**And** chaque variante affiche ses attributs (ex: "Taille M — Bleu"), son prix et son stock
**And** les variantes en rupture de stock (`stockQuantity = 0`) sont grisées mais visibles

**AC2 — Ajout au panier avec variante :**

**Given** le caissier sélectionne une variante
**When** il confirme
**Then** la variante est ajoutée au panier avec son prix propre (pas le prix parent)
**And** la ligne panier affiche : nom article + attributs variante (ex: "T-Shirt — Taille M, Bleu")
**And** le reçu affiche également les attributs de la variante

**AC3 — Scan barcode variante :**

**Given** le caissier scanne un barcode de variante
**When** la grille POS reçoit le barcode
**Then** la variante est directement ajoutée au panier sans passer par le sélecteur
**And** si le barcode correspond à l'article parent (pas une variante), le sélecteur s'ouvre normalement

**AC4 — Offline :**

**Given** l'appareil est hors ligne
**When** le sélecteur de variantes s'ouvre
**Then** les variantes sont chargées depuis Isar (synchronisées lors de la dernière connexion)
**And** le stock affiché est le stock local (peut être décalé — acceptable offline)

**Files to create:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/variant_selector_sheet.dart`

**Files to modify:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — détecter `hasVariants` et ouvrir sélecteur
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — addToCart avec variantId
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — afficher attributs variante

---

### Story 25-4: Backend — PriceLevel + endpoints multi-tarifs

**As a** backend developer,
**I want** a `PriceLevel` model and price resolution logic that automatically selects the correct price per transaction context,
**So that** wholesale, loyalty, and promotional prices apply without manual cashier intervention (FR90).

**Acceptance Criteria:**

**AC1 — Migration PriceLevel :**

**Given** le modèle `PriceLevel` est défini dans l'architecture v1.1 (§4.2.8)
**When** la migration est appliquée
**Then** la table `price_levels` existe dans le schema `shared` avec : `id`, `catalog_item_id`, `tenant_id`, `level_code` (ex: "GROS", "FIDELITE"), `label` (libre), `price`, `min_qty` (nullable), `customer_types` (String[] nullable), `is_active`, `created_at`
**And** un index existe sur `(tenant_id, catalog_item_id)`

**AC2 — CRUD price levels :**

**Given** `POST /api/v1/catalog/:id/price-levels` est appelé avec `{ levelCode: "GROS", label: "Prix gros", price: 4500, minQty: 10 }`
**When** la requête est validée
**Then** un niveau de prix est créé pour l'article du tenant
**And** `GET /api/v1/catalog/:id/price-levels` retourne tous les niveaux actifs
**And** `PATCH` et `DELETE` (soft) sont disponibles

**AC3 — Résolution automatique du prix à la vente :**

**Given** une transaction inclut un article avec des niveaux de prix configurés
**When** la transaction est traitée
**Then** le service évalue dans l'ordre : (1) `minQty` — si `quantity >= minQty`, le niveau s'applique ; (2) `customerTypes` — si le contact a un `contactType` dans `customerTypes`, le niveau s'applique
**And** si plusieurs niveaux sont éligibles, le plus avantageux (prix le plus bas) est sélectionné
**And** si aucun niveau n'est éligible, le prix par défaut de l'article est utilisé
**And** la réponse transaction inclut `appliedPriceLevel: { levelCode, label }` par ligne de vente

**AC4 — Permission price_override :**

**Given** un cashier avec la permission `price_override` sélectionne manuellement un niveau de prix
**When** `POST /api/v1/transactions` est appelé avec `{ items: [{ ..., forcedPriceLevelCode: "GROS" }] }`
**Then** le niveau forcé est appliqué sans vérification des conditions `minQty`/`customerTypes`
**And** si l'utilisateur n'a pas `price_override`, une erreur 403 est renvoyée si `forcedPriceLevelCode` est présent

**Notes dev :**
- `contactType` sur le modèle `Contact` est déjà en place (Epic 3)
- Le niveau "RETAIL" (défaut) n'a pas besoin d'être stocké en `PriceLevel` — c'est le prix `CatalogItem.price`

**Files to create:**
- `apps/backend/src/shared/catalog/price-levels/price-levels.service.ts`
- `apps/backend/src/shared/catalog/price-levels/price-levels.controller.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_price_levels/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter modèle `PriceLevel`
- `apps/backend/src/shared/transactions/transactions.service.ts` — résolution prix + `forcedPriceLevelCode`

---

### Story 25-5: Frontend — Configuration prix par niveau dans ProductFormDialog + POS override

**As a** owner,
**I want** to configure price levels per article from the product form, and cashiers with permission to manually select a price level at the POS,
**So that** wholesale and loyalty pricing is managed centrally and applied consistently (FR90).

**Acceptance Criteria:**

**AC1 — Section "Prix par niveau" dans ProductFormDialog :**

**Given** l'utilisateur édite un article
**When** le formulaire s'affiche
**Then** une section "Tarification" liste les niveaux de prix actifs du tenant (ex: "Gros", "Fidélité")
**And** chaque niveau affiche un champ prix + champ "Quantité min" (optionnel) + champ "Types client" (multiselect optionnel)
**And** les niveaux du tenant sont configurables depuis les paramètres tenant ("Gérer les niveaux de prix")

**AC2 — Configuration des niveaux disponibles par tenant :**

**Given** l'owner ouvre `TenantSettingsScreen` section "Tarification"
**When** il crée un niveau "Grossiste" avec le code "GROS"
**Then** ce niveau apparaît dans tous les `ProductFormDialog` du tenant
**And** le tenant peut avoir entre 1 et N niveaux (pas de limite fixe)

**AC3 — Affichage du niveau appliqué dans le panier POS :**

**Given** un article est ajouté au panier et un niveau de prix est appliqué automatiquement
**When** la ligne panier s'affiche
**Then** un chip discret indique le niveau appliqué (ex: chip "GROS" en bleu sous le prix)
**And** si le prix par défaut (RETAIL) est appliqué, aucun chip n'est affiché

**AC4 — Override manuel par le caissier autorisé :**

**Given** un caissier avec la permission `price_override` appuie longuement sur une ligne du panier
**When** le menu contextuel s'ouvre
**Then** une option "Changer le niveau de prix" est visible
**And** une bottom sheet liste les niveaux disponibles pour cet article
**And** la sélection met à jour le prix de la ligne et affiche le chip du niveau sélectionné
**And** pour un caissier sans `price_override`, l'option "Changer le niveau de prix" est masquée

**Files to modify:**
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section Tarification
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — chip niveau + menu override
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `priceLevels`

---

### Story 25-6: Backend — Promotion + endpoints CRUD + moteur d'éligibilité

**As a** backend developer,
**I want** a `Promotion` model with a promotion engine that evaluates eligibility at POS cart time,
**So that** discounts apply automatically and the best promotion wins per article (FR91).

**Acceptance Criteria:**

**AC1 — Migration Promotion :**

**Given** le modèle `Promotion` est défini dans l'architecture v1.1 (§4.2.9)
**When** la migration est appliquée
**Then** la table `promotions` existe dans le schema `shared` avec : `id`, `tenant_id`, `type` (`PERCENT` | `BUY_N_GET_M` | `CROSSED_PRICE`), `scope` (`ITEM` | `CATEGORY`), `scope_id` (catalogItemId ou categoryId), `value` (Json — contient les paramètres selon le type), `start_date`, `end_date`, `status` (`active` | `inactive`), `conflict_rule` (`BEST` | `FIRST`), `created_at`
**And** un index existe sur `(tenant_id, status, start_date, end_date)`

**AC2 — CRUD promotions :**

**Given** `POST /api/v1/promotions` est appelé avec un payload typé PERCENT
**When** la requête est validée
**Then** une promotion est créée avec `status: active` et les dates configurées
**And** `GET /api/v1/promotions` liste les promotions avec filtre `?status=active&type=PERCENT`
**And** `PATCH /api/v1/promotions/:id` permet de modifier le statut, les dates, ou les paramètres
**And** `DELETE /api/v1/promotions/:id` soft-delete la promotion

**AC3 — Moteur d'éligibilité à la vente :**

**Given** une transaction inclut un article éligible à une ou plusieurs promotions actives
**When** la transaction est traitée
**Then** le moteur évalue toutes les promotions actives dont `start_date <= now <= end_date` et dont `scope` couvre l'article (par `catalogItemId` ou `categoryId`)
**And** pour `PERCENT` : le discount = `price × value.percent / 100`
**And** pour `BUY_N_GET_M` : si `quantity >= value.buyN`, `value.getMQty` articles supplémentaires sont offerts (ligne séparée avec prix 0)
**And** pour `CROSSED_PRICE` : le prix affiché = `value.newPrice`, le prix original est tracé
**And** si plusieurs promotions sont éligibles et `conflict_rule = BEST`, la promotion avec le discount le plus élevé est sélectionnée
**And** la réponse transaction inclut par ligne : `appliedPromotion: { id, type, originalPrice, discountedPrice }`

**AC4 — Endpoint GET promotions actives pour un article :**

**Given** `GET /api/v1/promotions/active?catalogItemId=:id` est appelé
**When** le backend répond
**Then** la réponse liste toutes les promotions actives couvrant cet article, avec leur type et valeur calculée

**Notes dev :**
- `value` est un Json flexible pour éviter d'avoir une table par type de promotion
- Exemple PERCENT : `{ "percent": 20 }` ; BUY_N_GET_M : `{ "buyN": 3, "getM": 1, "freeItemId": null }` ; CROSSED_PRICE : `{ "originalPrice": 5000, "newPrice": 3500 }`

**Files to create:**
- `apps/backend/src/shared/promotions/promotions.module.ts`
- `apps/backend/src/shared/promotions/promotions.service.ts`
- `apps/backend/src/shared/promotions/promotions.controller.ts`
- `apps/backend/src/shared/promotions/promotion-engine.service.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_promotions/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter modèle `Promotion`
- `apps/backend/src/shared/transactions/transactions.service.ts` — appeler `PromotionEngineService` avant calcul total

---

### Story 25-7: Frontend — PromotionsScreen (backoffice) + application auto au POS + prix barré reçu

**As a** owner or cashier,
**I want** to manage promotions from the backoffice and see them automatically applied at the POS with struck-through prices on the receipt,
**So that** promotional pricing is transparent and requires zero cashier intervention (FR91).

**Acceptance Criteria:**

**AC1 — PromotionsScreen dans le backoffice :**

**Given** l'owner navigue vers la section promotions du backoffice
**When** `PromotionsScreen` se charge
**Then** une liste des promotions est affichée avec : nom/type, article/catégorie cible, dates, statut (badge vert/gris)
**And** un bouton "Nouvelle promotion" ouvre `CreatePromotionSheet`
**And** des filtres permettent de voir : Actives, Planifiées, Expirées

**AC2 — Formulaire création promotion :**

**Given** l'owner ouvre `CreatePromotionSheet`
**When** il sélectionne le type "Remise %"
**Then** les champs apparaissent : article ou catégorie (autocomplete), pourcentage de remise, date début, date fin
**And** pour "Offre quantitative" : champs buyN, getM, article offert (optionnel)
**And** pour "Prix barré" : champ prix original (pré-rempli depuis l'article), nouveau prix
**And** un aperçu en temps réel montre l'effet sur le prix (ex: "5 000 F → 4 000 F (-20%)")

**AC3 — Application automatique au POS :**

**Given** une promotion active couvre un article
**When** cet article est ajouté au panier POS
**Then** la promotion est appliquée automatiquement — sans action du caissier
**And** la ligne panier affiche : prix original barré (strikethrough) + prix après remise en vert
**And** un badge "PROMO" apparaît sur la ligne

**AC4 — Offre quantitative BUY_N_GET_M :**

**Given** une promotion "3 achetés = 1 offert" est active
**When** le caissier ajoute 3 exemplaires de l'article au panier
**Then** une ligne supplémentaire "Article offert (×1)" est ajoutée automatiquement avec prix 0 F
**And** si le caissier ajoute un 4ème exemplaire, la ligne offerte reste à ×1 (pas de cumul partiel)
**And** si le caissier ajoute 6 exemplaires, ×2 articles sont offerts

**AC5 — Reçu avec prix barré :**

**Given** une transaction avec promotion est finalisée
**When** le reçu s'affiche ou est imprimé
**Then** chaque ligne remisée affiche : nom, prix original (barré), prix payé, et le label de la promotion (ex: "-20% Promo été")
**And** le total du reçu reflète les prix après remise
**And** le montant total d'économies est affiché en bas du reçu (ex: "Vous avez économisé 1 500 F")

**Notes dev :**
- Les promotions sont synchronisées localement (Isar) pour fonctionner offline — la promotion engine est dupliquée côté client
- La ligne "article offert" dans le panier est de type `CartLineType.freeItem` — non modifiable par le caissier

**Files to create:**
- `apps/frontend/lib/features/shared/promotions/presentation/screens/promotions_screen.dart`
- `apps/frontend/lib/features/shared/promotions/presentation/widgets/create_promotion_sheet.dart`
- `apps/frontend/lib/features/shared/promotions/data/models/promotion.dart`
- `apps/frontend/lib/features/shared/promotions/data/repositories/promotions_repository.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — appliquer promotions localement à l'ajout panier
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — afficher prix barré + badge PROMO
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — prix barré + total économies
- `apps/frontend/lib/features/retail/backoffice/presentation/widgets/dashboard_shell.dart` — lien vers PromotionsScreen

---

## Epic 26: Traçabilité Articles & Configurations Métier (FR92–FR97)

### Story 26-1: Suivi numéros de série (FR92)

**As a** owner or manager,
**I want** to track serial numbers per unit sold for eligible catalog items,
**So that** I can trace every sold unit back to its serial, customer, and sale date (FR92).

**Acceptance Criteria:**

**AC1 — Champ trackSerialNumbers sur CatalogItem :**

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `trackSerialNumbers Boolean @default(false)` est présent sur `catalog_items`
**And** le modèle `SerialRecord` existe dans le schema `shared` avec : `id`, `catalogItemId`, `serial`, `soldAt`, `warrantyUntil`, `tenantId`, `createdAt`
**And** un index unique `(tenantId, serial)` est appliqué

**AC2 — Endpoints SerialRecord :**

**Given** un article a `trackSerialNumbers = true`
**When** `POST /api/v1/catalog/:id/serials` est appelé avec `{ serial, soldAt, warrantyUntil? }`
**Then** un `SerialRecord` est créé lié à l'article et au tenant
**And** `GET /api/v1/catalog/:id/serials` retourne la liste des séries vendues (paginée)
**And** `GET /api/v1/serials?q=<serial>` permet la recherche par numéro de série cross-articles

**AC3 — Saisie numéro de série au POS :**

**Given** un article au panier a `trackSerialNumbers = true`
**When** le caissier valide le panier
**Then** une bottom sheet demande la saisie du numéro de série avant de finaliser la transaction
**And** le champ est obligatoire si `trackSerialNumbers = true`, optionnel sinon
**And** le numéro de série est transmis à la transaction et crée un `SerialRecord` côté backend

**AC4 — Historique des séries dans le backoffice :**

**Given** l'owner navigue sur la fiche d'un article avec `trackSerialNumbers = true`
**When** il ouvre l'onglet "Séries"
**Then** la liste des `SerialRecord` est affichée : numéro de série, date de vente, client (si lié)
**And** une barre de recherche permet de filtrer par numéro de série

**AC5 — Toggle dans le formulaire article :**

**Given** l'owner édite ou crée un article dans `ProductFormDialog`
**When** il active le toggle "Suivi par numéro de série"
**Then** `trackSerialNumbers` est mis à `true` sur l'article
**And** un avertissement s'affiche : "Le caissier devra saisir un numéro de série à chaque vente"

**Notes dev :**
- La saisie du serial au POS peut être une `AlertDialog` simple avant `CheckoutController.confirmSale()`
- Le serial est stocké dans les metadata de la transaction (JSON field) et dans `SerialRecord`
- Offline : le `SerialRecord` est créé côté backend lors de la sync de la transaction outbox

**Files to create:**
- `apps/backend/src/shared/catalog/serials/serials.service.ts`
- `apps/backend/src/shared/catalog/serials/serials.controller.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_serial_records/migration.sql`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/serial_input_dialog.dart`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — ajouter `SerialRecord` + `trackSerialNumbers` sur `CatalogItem`
- `apps/backend/src/shared/transactions/transactions.service.ts` — créer `SerialRecord` à la vente
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — déclencher saisie serial avant checkout
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — onglet Séries sur fiche article
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle trackSerialNumbers

---

### Story 26-2: Gestion des garanties (FR93)

**As a** owner or manager,
**I want** warranty certificates auto-generated at the point of sale for eligible articles,
**So that** customers have a traceable warranty and can be looked up by warranty number (FR93).

**Acceptance Criteria:**

**AC1 — Champ warrantyMonths sur CatalogItem :**

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `warrantyMonths Int?` est présent sur `catalog_items`
**And** le champ `warrantyUntil DateTime?` est présent sur `SerialRecord` (ajouté en story 26-1)

**AC2 — Génération automatique à la vente :**

**Given** un article vendu a `warrantyMonths > 0` ET un `SerialRecord` est créé (26-1)
**When** la transaction est finalisée
**Then** `SerialRecord.warrantyUntil` est calculé : `soldAt + warrantyMonths mois`
**And** un numéro de certificat de garantie est généré : `WAR-<tenantCode>-<serial>-<YYYYMM>`
**And** ce numéro est retourné dans la réponse de la transaction

**AC3 — Affichage certificat sur le reçu :**

**Given** la transaction comporte un article avec garantie
**When** le reçu s'affiche dans `ReceiptDialog`
**Then** une section "Garantie" apparaît avec : article, numéro de série, date de fin de garantie, numéro de certificat

**AC4 — Recherche client par numéro de garantie :**

**Given** l'owner ouvre la vue contacts ou l'écran de recherche
**When** il saisit un numéro de garantie dans la barre de recherche globale
**Then** le `SerialRecord` correspondant est affiché avec : article, client lié, date d'achat, date fin garantie

**AC5 — Toggle warrantyMonths dans le formulaire article :**

**Given** l'owner édite un article dans `ProductFormDialog`
**When** il active "Durée de garantie" et saisit un nombre de mois
**Then** `warrantyMonths` est sauvegardé sur l'article
**And** la valeur `0` ou champ vide désactive la garantie

**Notes dev :**
- `warrantyUntil` est calculé par le backend (`transactions.service.ts`) lors de la création du `SerialRecord`
- Le numéro de certificat n'est pas stocké séparément : il est re-généré depuis `(serial + soldAt)`
- Story 26-1 est un prérequis strict (SerialRecord doit exister)

**Files to create:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/warranty_receipt_section.dart`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — `warrantyMonths` sur `CatalogItem`
- `apps/backend/src/shared/transactions/transactions.service.ts` — calculer `warrantyUntil` sur `SerialRecord`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — section garantie
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — champ warrantyMonths
- `apps/frontend/lib/features/shared/contacts/presentation/screens/contacts_screen.dart` — recherche par n° garantie

---

### Story 26-3: Prescription obligatoire (FR94)

**As a** pharmacist or regulated-goods retailer,
**I want** certain articles to require a prescription number before sale,
**So that** I can comply with regulatory requirements and audit prescription-linked sales (FR94).

**Acceptance Criteria:**

**AC1 — Champ requiresPrescription sur CatalogItem :**

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `requiresPrescription Boolean @default(false)` est présent sur `catalog_items`
**And** la fonctionnalité est désactivée par défaut sur tous les tenants

**AC2 — Saisie ordonnance obligatoire au POS :**

**Given** un article au panier a `requiresPrescription = true`
**When** le caissier tente de valider le panier
**Then** une bottom sheet s'ouvre avec deux champs obligatoires : "Numéro d'ordonnance" et "Nom du prescripteur"
**And** la validation du panier est bloquée tant que ces champs ne sont pas remplis
**And** les valeurs saisies sont transmises à la transaction

**AC3 — Enregistrement sur la transaction :**

**Given** la transaction est finalisée avec une ordonnance
**When** `POST /api/v1/transactions` est appelé
**Then** les champs `prescriptionNumber` et `prescriberName` sont stockés dans les metadata JSON de la transaction
**And** `GET /api/v1/transactions/:id` retourne ces champs dans la réponse

**AC4 — Recherche par numéro d'ordonnance :**

**Given** l'owner accède à l'historique des transactions
**When** il recherche par numéro d'ordonnance
**Then** les transactions liées à cette ordonnance sont affichées

**AC5 — Toggle dans le formulaire article :**

**Given** l'owner édite un article dans `ProductFormDialog`
**When** il active "Requiert une ordonnance"
**Then** `requiresPrescription` est mis à `true` sur l'article
**And** un avertissement s'affiche : "Le caissier devra saisir un numéro d'ordonnance à chaque vente"

**Notes dev :**
- Les données ordonnance sont stockées en JSON (champ `metadata` sur transaction) — pas de table dédiée
- Le module "prescription" est désactivé par défaut et doit être activé explicitement dans les paramètres tenant
- Pas d'intégration avec un système externe d'ordonnances pour cette phase

**Files to create:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/prescription_input_dialog.dart`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — `requiresPrescription` sur `CatalogItem`
- `apps/backend/src/shared/transactions/transactions.service.ts` — stocker ordonnance dans metadata
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — déclencher saisie ordonnance avant checkout
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle requiresPrescription
- `apps/frontend/lib/features/shared/reports/presentation/screens/reports_screen.dart` ou historique transactions — filtre par n° ordonnance

---

### Story 26-4: Date de garde optimale sur lot (FR95)

**As a** retailer handling perishable goods with a best-before window (wine, cheese),
**I want** each product batch to optionally carry a best-before date distinct from the expiry date,
**So that** the freshness color code prioritises sale before the optimal consumption date (FR95).

**Acceptance Criteria:**

**AC1 — Champ bestBeforeDate sur ProductBatch :**

**Given** le modèle `ProductBatch` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `bestBeforeDate DateTime? @map("best_before_date")` est présent sur `product_batches`
**And** le champ est nullable — les lots existants sans garde ne sont pas affectés

**AC2 — Saisie bestBeforeDate à la réception :**

**Given** l'utilisateur enregistre une réception fournisseur
**When** il renseigne les détails du lot
**Then** un champ optionnel "Date de garde optimale" apparaît si l'article a des lots avec expiry
**And** ce champ accepte une date et la sauvegarde comme `bestBeforeDate` sur le `ProductBatch`
**And** la date de garde est indépendante de `expiresAt` (les deux peuvent coexister)

**AC3 — Priorité bestBeforeDate dans le code couleur fraîcheur :**

**Given** un lot a `bestBeforeDate` renseigné
**When** le code couleur fraîcheur est calculé (Epic 24)
**Then** le calcul utilise `bestBeforeDate` au lieu de `expiresAt`
**And** si `bestBeforeDate` est null mais `expiresAt` est renseigné, `expiresAt` est utilisé comme fallback
**And** si les deux sont null, aucun code couleur fraîcheur n'est affiché

**AC4 — Affichage bestBeforeDate dans l'onglet Fraîcheur :**

**Given** l'utilisateur ouvre l'onglet Fraîcheur dans `InventoryScreen`
**When** un lot a une `bestBeforeDate`
**Then** la carte du lot affiche "Garde optimale : <date>" distinct de "Expire : <expiresAt>"

**Notes dev :**
- La logique de code couleur est dans `FreshnessHelper` (Epic 24) — modifier la sélection de date de référence
- `bestBeforeDate` est inclus dans la réponse de `GET /api/v1/inventory/batches` et `GET /api/v1/inventory/batches/expiring`
- Story 24 (Fraîcheur) est un prérequis

**Files to create:**
- `apps/backend/prisma/migrations/YYYYMMDD_add_best_before_date/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — `bestBeforeDate` sur `ProductBatch`
- `apps/backend/src/shared/inventory/inventory.service.ts` — inclure `bestBeforeDate` dans les réponses batch
- `apps/frontend/lib/features/shared/inventory/data/models/product_batch.dart` — ajouter `bestBeforeDate`
- `apps/frontend/lib/core/utils/freshness_helper.dart` (ou équivalent) — logique de sélection `bestBeforeDate` vs `expiresAt`
- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — afficher "Garde optimale" dans l'onglet Fraîcheur
- `apps/frontend/lib/features/shared/inventory/presentation/widgets/reception_form.dart` — champ bestBeforeDate

---

### Story 26-5: Prix dynamique avec historique (FR96)

**As a** retailer selling commodities with fluctuating prices (gold, fuel, raw materials),
**I want** articles flagged as dynamic-priced to maintain a full price history,
**So that** the POS always uses the current price and I can audit past pricing decisions (FR96).

**Acceptance Criteria:**

**AC1 — Champ dynamicPricing + modèle PriceHistory :**

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `dynamicPricing Boolean @default(false)` est présent sur `catalog_items`
**And** le modèle `PriceHistory` existe dans le schema `shared` avec : `id`, `catalogItemId`, `price`, `effectiveFrom`, `reason`, `tenantId`, `createdAt`
**And** un index sur `(catalogItemId, effectiveFrom)` est appliqué

**AC2 — Enregistrement automatique dans PriceHistory :**

**Given** un article a `dynamicPricing = true`
**When** son prix est modifié via `PATCH /api/v1/catalog/:id` (champ `price`)
**Then** un `PriceHistory` est créé automatiquement avec `effectiveFrom = now()` et le motif optionnel (`reason`)
**And** le prix actuel de l'article (`CatalogItem.price`) est mis à jour normalement
**And** les articles sans `dynamicPricing` ne génèrent pas d'entrée dans `PriceHistory`

**AC3 — Endpoint historique des prix :**

**Given** `GET /api/v1/catalog/:id/price-history` est appelé
**When** l'article a des entrées dans `PriceHistory`
**Then** la liste est retournée triée par `effectiveFrom DESC` avec : prix, date effective, motif

**AC4 — POS utilise toujours le dernier prix :**

**Given** un article dynamicPricing a un prix mis à jour
**When** il est ajouté au panier POS
**Then** le prix utilisé est `CatalogItem.price` (le plus récent) — pas de calcul supplémentaire requis au POS

**AC5 — Vue historique des prix dans le backoffice :**

**Given** l'owner ouvre la fiche d'un article avec `dynamicPricing = true`
**When** il ouvre l'onglet "Historique des prix"
**Then** la liste des `PriceHistory` est affichée : date, prix, motif
**And** un graphique linéaire simple montre l'évolution du prix dans le temps

**AC6 — Toggle + champ reason dans le formulaire article :**

**Given** l'owner édite un article
**When** il active "Prix dynamique"
**Then** `dynamicPricing` est mis à `true`
**And** lors de chaque modification de prix, un champ optionnel "Motif de la modification" est disponible

**Notes dev :**
- Le hook de création `PriceHistory` est dans `catalog.service.ts` — intercepter `updateCatalogItem` quand `price` change et `dynamicPricing = true`
- Le graphique peut être un simple `LineChart` du package `fl_chart` (déjà utilisé pour le dashboard)
- Offline : la mise à jour de prix est une opération backoffice — pas de contrainte offline spécifique

**Files to create:**
- `apps/backend/src/shared/catalog/price-history/price-history.service.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_price_history/migration.sql`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/price_history_tab.dart`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — `PriceHistory` + `dynamicPricing` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — hook création `PriceHistory` sur update prix
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — onglet Historique des prix
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle dynamicPricing + champ reason

---

### Story 26-6: Articles uniques (dépôt-vente) (FR97)

**As a** retailer handling consignment goods, antiques, or one-off items,
**I want** certain articles to be marked as unique with a stock cap of 1,
**So that** they disappear from the active catalog after sale and I can duplicate them to create similar listings (FR97).

**Acceptance Criteria:**

**AC1 — Champ isUnique sur CatalogItem :**

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `isUnique Boolean @default(false)` est présent sur `catalog_items`

**AC2 — Stock plafonné à 1 :**

**Given** un article a `isUnique = true`
**When** une réception fournisseur ou un ajustement de stock tente de mettre `stockQuantity > 1`
**Then** le backend rejette la requête avec `400 Bad Request` : `"Un article unique ne peut avoir un stock supérieur à 1"`
**And** l'UI affiche ce message d'erreur clairement

**AC3 — Disparition après vente :**

**Given** un article unique est vendu (stock passe à 0)
**When** la transaction est finalisée
**Then** `CatalogItem.isActive` est mis à `false` automatiquement
**And** l'article n'apparaît plus dans la grille POS ni dans le catalogue actif
**And** il reste accessible dans les transactions historiques et via recherche "articles archivés"

**AC4 — Duplication depuis le backoffice :**

**Given** l'owner consulte un article unique (actif ou archivé)
**When** il clique "Dupliquer cet article"
**Then** un nouvel article est créé avec les mêmes données (nom, prix, catégorie) mais `isUnique = true`, `stockQuantity = 0`, et un nouveau `id`
**And** l'owner est redirigé vers la fiche du nouvel article pour compléter les détails (photos, description spécifique)

**AC5 — Indicateur visuel "Article unique" :**

**Given** un article a `isUnique = true` et `isActive = true`
**When** il s'affiche dans la grille POS ou dans le catalogue backoffice
**Then** un badge "UNIQUE" ou une icône distinctive apparaît sur la carte de l'article

**AC6 — Toggle isUnique dans le formulaire article :**

**Given** l'owner crée ou édite un article dans `ProductFormDialog`
**When** il active "Article unique (dépôt-vente)"
**Then** `isUnique` est mis à `true` et le stock est automatiquement plafonné à 1 dans l'UI
**And** un avertissement s'affiche : "Cet article sera automatiquement archivé après la vente"

**Notes dev :**
- L'archivage automatique (`isActive = false`) est déclenché dans `transactions.service.ts` après décrémentation du stock
- La duplication utilise un endpoint `POST /api/v1/catalog/:id/duplicate` (retourne le nouvel article)
- La contrainte stock ≤ 1 est validée dans `inventory.service.ts` avant tout mouvement entrant

**Files to create:**
- `apps/backend/prisma/migrations/YYYYMMDD_add_is_unique/migration.sql`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — `isUnique` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — endpoint duplication + contrainte stock
- `apps/backend/src/shared/inventory/inventory.service.ts` — validation stock ≤ 1 pour articles uniques
- `apps/backend/src/shared/transactions/transactions.service.ts` — archivage auto après vente
- `apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart` — badge UNIQUE
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — bouton Dupliquer + badge UNIQUE
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle isUnique

---

## Epic 27: Retours Articles & Réservations (FR98–FR99)

Le commercial peut enregistrer un retour article au POS lié à la vente originale, avec choix de résolution (remboursement cash, avoir client, échange) et réintégration automatique du stock (FR98, Phase 2a). Le Z-report de session distingue ventes brutes et retours. Le propriétaire configure la politique de retour par tenant (délai, motif obligatoire, approbation manager). Séparément, le commercial peut créer une réservation avec acompte partiel (10–50 % configurable) ; le solde est visible sur la fiche client, le dashboard affiche un KPI "Réservations en cours" (FR99, Phase 2b).

---

### Story 27-1: Backend — ReturnRecord + endpoints POST/GET + stock réintégré (FR98)

**As a** backend developer,
**I want** a `ReturnRecord` model, REST endpoints to create and query returns, automatic stock reinstatement, and tenant return-policy enforcement,
**So that** the POS can process article returns with full audit trail and configurable business rules (FR98).

**Acceptance Criteria:**

**AC1 — Migration Prisma ReturnRecord :**

**Given** le fichier `schema.prisma` est mis à jour
**When** la migration est appliquée
**Then** la table `return_records` existe dans le schéma `shared` avec les colonnes : `id`, `transaction_id`, `catalog_item_id`, `variant_id` (nullable), `quantity`, `reason` (nullable), `resolution`, `approved_by` (nullable), `tenant_id`, `created_by`, `created_at`
**And** les index `(tenant_id, transaction_id)` sont présents

**AC2 — Champs politique retour sur Tenant :**

**Given** la migration est appliquée
**When** on inspecte la table `tenants`
**Then** les colonnes `return_policy_days` (int, default 30), `return_requires_reason` (bool, default true), `return_requires_approval` (bool, default false) sont présentes

**AC3 — POST /api/v1/returns — création retour :**

**Given** un commercial authentifié envoie `POST /api/v1/returns` avec `{ transactionId, catalogItemId, quantity, reason?, resolution }`
**When** la transaction originale existe et appartient au même tenant
**And** la date de la transaction est dans la fenêtre `returnPolicyDays` du tenant
**And** `reason` est fourni si `returnRequiresReason = true`
**Then** un `ReturnRecord` est créé en base avec `createdBy = userId`
**And** un `StockMovement` de type `RETURN` est créé pour réintégrer la quantité dans le stock
**And** la réponse est `201 Created` avec le `ReturnRecord` complet

**AC4 — Validation politique retour :**

**Given** un commercial envoie `POST /api/v1/returns`
**When** la date de vente originale dépasse `returnPolicyDays` du tenant
**Then** le backend répond `400 Bad Request` : `"La période de retour autorisée est expirée"`

**When** `returnRequiresReason = true` et `reason` est absent ou vide
**Then** le backend répond `400 Bad Request` : `"Un motif est obligatoire pour les retours"`

**When** `returnRequiresApproval = true` et `approvedBy` est absent
**Then** le backend répond `403 Forbidden` : `"L'approbation d'un manager est requise"`

**AC5 — GET /api/v1/returns — liste des retours :**

**Given** un manager ou owner authentifié appelle `GET /api/v1/returns`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste paginée des `ReturnRecord` du tenant
**And** le filtre optionnel `?transactionId=:id` retourne uniquement les retours de cette transaction

**AC6 — Isolation tenant :**

**Given** un utilisateur appelle `GET /api/v1/returns` ou `POST /api/v1/returns`
**When** la requête est traitée
**Then** seuls les enregistrements du tenant de l'utilisateur sont accessibles ou créés

**Notes dev :**
- `ReturnModule` dans `apps/backend/src/shared/returns/` (controller, service, DTO, module)
- La réintégration stock appelle `InventoryService.recordMovement({ type: 'RETURN', ... })` — réutiliser le pattern existant
- `resolution` : enum `cash_refund | credit_note | exchange` — validé au niveau DTO (class-validator `@IsIn`)
- Pour `credit_note`, un champ `creditBalance` sera incrémenté sur le `Contact` du client (prévu en FR99, pas implémenté ici — logger un TODO)
- Le `TenantGuard` et `JwtAuthGuard` sur toutes les routes
- Ajouter `ReturnsModule` au `AppModule`

**Files to create:**
- `apps/backend/prisma/migrations/20260319100000_add_return_records/migration.sql`
- `apps/backend/src/shared/returns/returns.module.ts`
- `apps/backend/src/shared/returns/returns.controller.ts`
- `apps/backend/src/shared/returns/returns.service.ts`
- `apps/backend/src/shared/returns/dto/create-return.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — modèles `ReturnRecord` + champs `returnPolicy*` sur `Tenant`
- `apps/backend/src/app.module.ts` — importer `ReturnsModule`
- `apps/backend/src/shared/inventory/inventory.service.ts` — exposer `recordMovement` si pas déjà public

---

### Story 27-2: Frontend POS — Bouton retour, recherche vente originale, choix résolution (FR98)

**As a** commercial (Fatou),
**I want** a "Retour" button in the POS that lets me find the original sale by receipt number or barcode and choose how to resolve the return,
**So that** I can process article returns quickly without leaving the POS screen (FR98).

**Acceptance Criteria:**

**AC1 — Bouton "Retour" dans le POS :**

**Given** le commercial est sur l'écran POS
**When** il appuie sur le bouton "Retour" (icône undo, placement : panel actions)
**Then** une bottom sheet `ReturnSearchSheet` s'ouvre
**And** le champ de recherche par numéro de reçu est focalisé automatiquement

**AC2 — Recherche de la vente originale :**

**Given** la `ReturnSearchSheet` est ouverte
**When** le commercial saisit un numéro de reçu ou scanne un code-barres
**And** la transaction existe dans le tenant
**Then** la liste des articles de la vente s'affiche (nom, quantité vendue, prix unitaire)
**And** chaque article affiche un sélecteur de quantité à retourner (défaut : 0, max : quantité achetée)

**When** le numéro de reçu n'est pas trouvé
**Then** un message "Vente introuvable — vérifiez le numéro de reçu" s'affiche

**AC3 — Choix de résolution :**

**Given** le commercial a sélectionné au moins un article à retourner
**When** il appuie sur "Confirmer le retour"
**Then** un dialogue `ReturnResolutionDialog` s'affiche avec trois options :
- Remboursement cash (icône monnaie)
- Avoir client — crédité sur le compte (icône portefeuille)
- Échange article (icône refresh)

**AC4 — Motif obligatoire (si configuré) :**

**Given** `returnRequiresReason = true` pour le tenant
**When** le commercial appuie sur "Confirmer" dans `ReturnResolutionDialog`
**And** le champ "Motif du retour" est vide
**Then** un message d'erreur inline s'affiche : "Le motif est obligatoire"
**And** la confirmation est bloquée

**AC5 — Confirmation et feedback :**

**Given** le commercial a rempli tous les champs requis
**When** il valide le retour
**Then** l'appel `POST /api/v1/returns` est effectué
**And** en cas de succès, un `SnackBar` affiche "Retour enregistré — [résolution]"
**And** la `ReturnSearchSheet` se ferme et le POS revient à l'état initial (panier vide)

**When** le backend répond avec une erreur (délai expiré, motif manquant)
**Then** le message d'erreur du backend s'affiche dans le dialogue

**AC6 — Mode offline :**

**Given** le POS est hors ligne
**When** le commercial tente d'ouvrir la `ReturnSearchSheet`
**Then** un message s'affiche : "La recherche de reçu nécessite une connexion Internet"
**And** le bouton "Retour" est visuellement désactivé (avec tooltip explicatif)

**Notes dev :**
- `ReturnSearchSheet` : `apps/frontend/lib/features/retail/pos/presentation/widgets/return_search_sheet.dart`
- `ReturnResolutionDialog` : `apps/frontend/lib/features/retail/pos/presentation/widgets/return_resolution_dialog.dart`
- Utiliser `ref.read(returnsRepositoryProvider)` pour `POST /api/v1/returns`
- Le mode offline est détecté via `ConnectivityService` existant
- Pas de persistence locale des retours (online-only pour MVP)

**Files to create:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/return_search_sheet.dart`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/return_resolution_dialog.dart`
- `apps/frontend/lib/features/shared/returns/data/repositories/returns_repository.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — bouton "Retour" dans la barre d'actions
- `apps/frontend/lib/features/retail/pos/presentation/providers/pos_providers.dart` — `returnsRepositoryProvider`

---

### Story 27-3: Z-report — Distinction ventes brutes vs retours (FR98)

**As a** manager or owner,
**I want** the session Z-report to show gross sales, returns, and net sales as separate lines,
**So that** I can reconcile cash accurately and track return volume per session (FR98).

**Acceptance Criteria:**

**AC1 — Données retours dans le Z-report backend :**

**Given** une session POS est clôturée et a des retours enregistrés dans la même session
**When** `GET /api/v1/sessions/:id/zreport` est appelé
**Then** la réponse inclut :
```json
{
  "grossSales": { "count": N, "amount": X },
  "returns":    { "count": M, "amount": Y },
  "netSales":   { "amount": X - Y },
  ...
}
```
**And** `returns.amount` est la somme des montants des `ReturnRecord` créés pendant la session (via `created_at` dans la plage `session.openedAt → session.closedAt`)

**AC2 — Zéro retour :**

**Given** une session n'a aucun retour
**When** le Z-report est demandé
**Then** `returns` est présent avec `{ count: 0, amount: 0 }` (pas d'erreur, pas de champ absent)

**AC3 — Affichage Z-report frontend :**

**Given** le Z-report est affiché dans `SessionReportScreen` (ou le dialogue de clôture)
**When** la session a des retours
**Then** trois lignes distinctes s'affichent :
- "Ventes brutes : X FCFA (N transactions)"
- "Retours : − Y FCFA (M retours)" — en rouge
- "Ventes nettes : Z FCFA" — en gras

**When** la session n'a pas de retours
**Then** seule la ligne "Ventes nettes" s'affiche (identique aux ventes brutes) — pas de ligne "Retours : 0"

**AC4 — Cohérence avec le cash théorique :**

**Given** le Z-report calcule le montant cash théorique attendu
**When** des retours cash (`resolution = cash_refund`) ont été effectués
**Then** le cash théorique est ajusté : `float_ouverture + ventes_cash - remboursements_cash`
**And** la variance = cash_compté − cash_théorique reste correcte

**Notes dev :**
- Modifier `PosSessionService.getZReport()` pour joindre les `ReturnRecord` par plage de dates de session
- La jointure se fait via `created_at` des retours, pas via un `sessionId` sur `ReturnRecord` (les retours ne sont pas liés à une session, mais à une transaction)
- `netSales = grossSales - returns` côté backend, pas côté frontend
- Uniquement les retours de type `cash_refund` impactent le cash théorique

**Files to modify:**
- `apps/backend/src/shared/returns/returns.service.ts` — méthode `getReturnsSummaryForSession(sessionId, openedAt, closedAt)`
- `apps/backend/src/retail/retail-orchestration.service.ts` (ou équivalent POS session service) — intégrer `returnsSummary` dans le Z-report
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` ou `SessionReportScreen` — afficher les 3 lignes

---

### Story 27-4: Backend — Reservation model + endpoints acompte + completion (FR99)

**As a** backend developer,
**I want** a `Reservation` model with REST endpoints to create, complete, and cancel reservations with partial deposit logic,
**So that** the POS can offer deposit-based reservations with full lifecycle management (FR99).

**Acceptance Criteria:**

**AC1 — Migration Prisma Reservation :**

**Given** le fichier `schema.prisma` est mis à jour
**When** la migration est appliquée
**Then** la table `reservations` existe dans le schéma `shared` avec les colonnes : `id`, `customer_id`, `items_json`, `total_amount`, `deposit_amount`, `remaining_amount`, `status` (default `pending`), `deposit_transaction_id` (nullable), `completion_transaction_id` (nullable), `tenant_id`, `created_by`, `created_at`, `completed_at` (nullable)
**And** les index `(tenant_id, status)` et `(customer_id)` sont présents

**AC2 — POST /api/v1/reservations — création avec acompte :**

**Given** un commercial authentifié envoie `POST /api/v1/reservations` avec `{ customerId, items: [...], totalAmount, depositAmount }`
**When** `depositAmount` est compris entre 10 % et 50 % de `totalAmount` (bornes configurables — défaut tenant)
**Then** une `Reservation` est créée avec `status = "pending"`, `remainingAmount = totalAmount - depositAmount`
**And** une transaction de type `"reservation_deposit"` est créée pour l'acompte encaissé
**And** `depositTransactionId` pointe vers cette transaction
**And** la réponse est `201 Created` avec la réservation complète

**When** `depositAmount < 10 %` ou `> 50 %` de `totalAmount`
**Then** le backend répond `400 Bad Request` : `"L'acompte doit être compris entre 10 % et 50 % du total"`

**AC3 — PATCH /api/v1/reservations/:id/complete — finalisation paiement :**

**Given** une réservation est en statut `pending`
**When** un commercial envoie `PATCH /api/v1/reservations/:id/complete` avec `{ paymentMethod, amount }`
**And** `amount >= remainingAmount`
**Then** `status` passe à `"completed"`, `completedAt` est renseigné
**And** une transaction de type `"reservation_completion"` est créée
**And** `completionTransactionId` est mis à jour
**And** le stock des articles est décrémenté (via `InventoryService`)

**AC4 — PATCH /api/v1/reservations/:id/cancel — annulation :**

**Given** une réservation est en statut `pending`
**When** un owner ou manager envoie `PATCH /api/v1/reservations/:id/cancel` avec `{ depositResolution: "credit_note" | "cash_refund" }`
**Then** `status` passe à `"cancelled"`
**And** si `depositResolution = "credit_note"` : `Contact.creditBalance` du client est incrémenté du montant `depositAmount`
**And** si `depositResolution = "cash_refund"` : une transaction `"reservation_refund"` est créée pour trace audit
**And** la réponse est `200 OK` avec la réservation mise à jour

**AC5 — GET /api/v1/reservations — liste paginée :**

**Given** un manager ou owner appelle `GET /api/v1/reservations`
**When** la requête est valide
**Then** la réponse retourne les réservations paginées du tenant
**And** le filtre optionnel `?status=pending|completed|cancelled` fonctionne
**And** le filtre `?customerId=:id` retourne les réservations d'un client spécifique

**AC6 — GET /api/v1/reservations/kpi — KPI dashboard :**

**Given** un owner ou manager appelle `GET /api/v1/reservations/kpi`
**When** la requête est valide
**Then** la réponse retourne `{ pendingCount: N, totalDepositAmount: X }` pour les réservations `pending` du tenant

**Notes dev :**
- `ReservationsModule` dans `apps/backend/src/shared/reservations/`
- `items_json` est un tableau JSON : `[{ catalogItemId, variantId?, quantity, unitPrice }]`
- Le décrémentement stock à la completion utilise `InventoryService.recordMovement({ type: 'SALE', ... })` pour chaque article
- `Contact.creditBalance` : si le champ n'existe pas encore sur le modèle `Contact`, l'ajouter dans cette migration
- Ajouter `ReservationsModule` au `AppModule`
- Les transactions `reservation_deposit / reservation_completion / reservation_refund` utilisent le modèle `Transaction` existant avec un champ `type` étendu

**Files to create:**
- `apps/backend/prisma/migrations/20260319110000_add_reservations/migration.sql`
- `apps/backend/src/shared/reservations/reservations.module.ts`
- `apps/backend/src/shared/reservations/reservations.controller.ts`
- `apps/backend/src/shared/reservations/reservations.service.ts`
- `apps/backend/src/shared/reservations/dto/create-reservation.dto.ts`
- `apps/backend/src/shared/reservations/dto/complete-reservation.dto.ts`
- `apps/backend/src/shared/reservations/dto/cancel-reservation.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — modèle `Reservation` + `creditBalance` sur `Contact` si absent
- `apps/backend/src/app.module.ts` — importer `ReservationsModule`
- `apps/backend/src/shared/inventory/inventory.service.ts` — appelé à la completion

---

### Story 27-5: Frontend — Écran réservations, formulaire acompte POS, KPI dashboard (FR99)

**As a** commercial or owner,
**I want** to create a reservation with deposit from the POS, view active reservations from the backoffice, complete or cancel them, and see a live KPI on the dashboard,
**So that** reservation workflows are fully managed without paper or external tools (FR99).

**Acceptance Criteria:**

**AC1 — Bouton "Réservation" dans le POS :**

**Given** le commercial a des articles dans le panier POS
**When** il appuie sur "Réservation" (bouton alternatif à "Encaisser")
**Then** un dialogue `ReservationDepositDialog` s'ouvre avec :
- Sélecteur client (autocomplete sur `Contact`)
- Montant total pré-rempli depuis le panier
- Champ acompte (défaut : 30 % du total, modifiable)
- Indicateur en temps réel : "Acompte : X FCFA — Solde restant : Y FCFA"
- Bouton "Confirmer la réservation"

**AC2 — Validation acompte côté UI :**

**Given** le commercial saisit un acompte dans `ReservationDepositDialog`
**When** la valeur est < 10 % ou > 50 % du total
**Then** un texte d'erreur rouge s'affiche sous le champ : "L'acompte doit être entre 10 % et 50 % du total"
**And** le bouton "Confirmer" est désactivé

**AC3 — Confirmation et reçu d'acompte :**

**Given** le commercial valide la réservation
**When** `POST /api/v1/reservations` répond `201 Created`
**Then** le panier POS est vidé
**And** un `ReceiptDialog` adapté s'affiche avec le type "RÉSERVATION — ACOMPTE" et le numéro de réservation
**And** un `SnackBar` confirme : "Réservation créée — Solde restant : Y FCFA"

**AC4 — Écran liste des réservations (backoffice) :**

**Given** le manager ou owner navigue vers "Réservations" dans le backoffice
**When** l'écran `ReservationsScreen` s'affiche
**Then** la liste des réservations `pending` s'affiche avec : nom client, date, montant total, acompte versé, solde restant
**And** un onglet "Complétées" et "Annulées" permettent de consulter l'historique
**And** chaque réservation `pending` a deux actions : "Compléter le paiement" et "Annuler"

**AC5 — Compléter le paiement :**

**Given** le manager appuie sur "Compléter le paiement" d'une réservation `pending`
**When** un dialogue de paiement s'affiche avec le solde restant pré-rempli
**And** le manager confirme le mode de paiement
**Then** `PATCH /api/v1/reservations/:id/complete` est appelé
**And** la réservation passe dans l'onglet "Complétées"
**And** un reçu final est affiché

**AC6 — Annuler une réservation :**

**Given** le manager appuie sur "Annuler" d'une réservation `pending`
**When** un dialogue de confirmation s'affiche avec deux options : "Rembourser l'acompte (cash)" / "Convertir en avoir client"
**And** le manager confirme
**Then** `PATCH /api/v1/reservations/:id/cancel` est appelé avec `depositResolution`
**And** la réservation passe dans l'onglet "Annulées"
**And** un `SnackBar` confirme l'action choisie

**AC7 — Solde restant sur la fiche client :**

**Given** un client a une ou plusieurs réservations `pending`
**When** l'owner ou manager consulte la fiche du contact
**Then** une section "Réservations en cours" affiche la liste avec le solde restant total

**AC8 — KPI "Réservations en cours" sur le dashboard :**

**Given** le dashboard est chargé
**When** `GET /api/v1/reservations/kpi` répond avec `{ pendingCount, totalDepositAmount }`
**Then** une `KpiCard` "Réservations en cours" s'affiche avec `pendingCount` et le sous-texte "Acomptes : X FCFA"
**And** un tap sur la carte navigue vers `ReservationsScreen` filtré sur `pending`

**Notes dev :**
- `ReservationDepositDialog` : `apps/frontend/lib/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart`
- `ReservationsScreen` : `apps/frontend/lib/features/shared/reservations/presentation/screens/reservations_screen.dart`
- `ReservationsRepository` : `apps/frontend/lib/features/shared/reservations/data/repositories/reservations_repository.dart`
- `reservationsKpiProvider` : Riverpod `FutureProvider` — appelé dans `DashboardScreen`
- Le KPI se rafraîchit via `ref.invalidate(reservationsKpiProvider)` après tout create/complete/cancel
- Pas de mode offline pour les réservations (online-only, cohérent avec FR99)

**Files to create:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart`
- `apps/frontend/lib/features/shared/reservations/data/repositories/reservations_repository.dart`
- `apps/frontend/lib/features/shared/reservations/presentation/screens/reservations_screen.dart`
- `apps/frontend/lib/features/shared/reservations/presentation/providers/reservations_provider.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — bouton "Réservation" dans les actions panier
- `apps/frontend/lib/features/retail/pos/presentation/providers/pos_providers.dart` — `reservationsRepositoryProvider`
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — KPI card réservations
- `apps/frontend/lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart` — nouveau type KPI si nécessaire

---

## Epic 28: Plans Tarifaires & Facturation (FR100–FR103)

Le superadmin peut assigner un plan tarifaire par tenant (free, standard, premium, enterprise) défini dans une table `PlanDefinition` — le changement de plan active/désactive automatiquement les modules et ajuste `maxUsers` (FR100, Phase 2a). Il peut enregistrer des frais d'installation et de formation par tenant, et gérer le cycle de vie de facturation (trial → active → overdue → suspended) avec suspension automatique configurable (FR101, Phase 2a). Le propriétaire du tenant peut consulter son plan, ses modules inclus, son statut de facturation et l'historique des paiements depuis son backoffice, et demander un upgrade (FR102, Phase 2a — self-service préparé pour Phase 3). En Phase 3, un onboarding en ligne permettra au client de choisir son plan, payer via Mobile Money ou carte, et obtenir son tenant créé et activé automatiquement (FR103).

---

### Story 28-1: Backend — PlanDefinition model, seed 4 plans, endpoints CRUD (FR100)

**As a** superadmin,
**I want** a `PlanDefinition` model with seed data for the 4 standard plans and full CRUD REST endpoints,
**So that** plans are configurable without deployment and serve as the source of truth for module activation and fee suggestions (FR100).

**Acceptance Criteria:**

**AC1 — Migration Prisma PlanDefinition :**

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `PlanDefinition`
**When** la migration est appliquée
**Then** la table `plan_definitions` existe dans le schéma `kernel` avec les colonnes : `id`, `code` (unique), `name`, `monthly_price`, `max_users`, `included_modules` (String[]), `suggested_installation_fee` (nullable), `suggested_training_fee` (nullable), `is_active` (default true), `created_at`

**AC2 — Seed 4 plans :**

**Given** la commande `prisma db seed` est exécutée
**When** la base est vide ou les plans sont absents
**Then** 4 plans sont créés : `free` (0 FCFA, 1 user, modules: []), `standard` (15 000 FCFA, 4 users, modules: ["catalog","inventory","retail"]), `premium` (30 000 FCFA, 10 users, modules: ["catalog","inventory","retail","reporting","purchase_orders"]), `enterprise` (50 000 FCFA, 25 users, modules: ["catalog","inventory","retail","reporting","purchase_orders","variants","pricing","promotions"])
**And** le seed est idempotent (upsert par `code`)

**AC3 — GET /admin/plans — liste des plans :**

**Given** un superadmin authentifié appelle `GET /api/v1/admin/plans`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste de tous les `PlanDefinition` triés par `monthly_price` ASC
**And** les plans inactifs (`isActive = false`) sont inclus (superadmin voit tout)

**AC4 — POST /admin/plans — création plan :**

**Given** un superadmin envoie `POST /api/v1/admin/plans` avec `{ code, name, monthlyPrice, maxUsers, includedModules, suggestedInstallationFee?, suggestedTrainingFee? }`
**When** le `code` n'existe pas encore
**Then** un `PlanDefinition` est créé et retourné en `201 Created`
**When** le `code` existe déjà
**Then** la réponse est `409 Conflict` : `"Un plan avec ce code existe déjà"`

**AC5 — PATCH /admin/plans/:code — mise à jour plan :**

**Given** un superadmin envoie `PATCH /api/v1/admin/plans/:code` avec les champs à modifier
**When** le plan existe
**Then** les champs sont mis à jour et le plan modifié est retourné en `200 OK`
**And** les tenants déjà sur ce plan ne sont PAS rétroactivement affectés (la modification n'est effective que pour les prochaines assignations)

**AC6 — DELETE /admin/plans/:code — désactivation plan :**

**Given** un superadmin appelle `DELETE /api/v1/admin/plans/:code`
**When** le plan existe
**Then** `isActive` est passé à `false` (soft delete) et la réponse est `200 OK`
**And** les tenants actuellement sur ce plan conservent leur assignation

**Notes dev :**
- `PlanDefinitionModule` dans `apps/backend/src/kernel/billing/`
- `SuperadminGuard` sur toutes les routes (vérifier que le guard existe ou le créer)
- Les `includedModules` sont des codes correspondant aux `Module.code` de la table `modules` — pas de FK (liste flexible)
- Le seed Prisma est dans `apps/backend/prisma/seed.ts` — ajouter les plans dans la section kernel

**Files to create:**
- `apps/backend/prisma/migrations/20260320000000_add_plan_definitions/migration.sql`
- `apps/backend/src/kernel/billing/billing.module.ts`
- `apps/backend/src/kernel/billing/plan-definition/plan-definition.controller.ts`
- `apps/backend/src/kernel/billing/plan-definition/plan-definition.service.ts`
- `apps/backend/src/kernel/billing/plan-definition/dto/create-plan-definition.dto.ts`
- `apps/backend/src/kernel/billing/plan-definition/dto/update-plan-definition.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — modèle `PlanDefinition`
- `apps/backend/prisma/seed.ts` — seed 4 plans
- `apps/backend/src/app.module.ts` — importer `BillingModule`

---

### Story 28-2: Backend — PATCH /admin/tenants/:id/plan + activation modules auto (FR100)

**As a** superadmin,
**I want** a `PATCH /admin/tenants/:id/plan` endpoint that changes a tenant's plan, auto-applies module activation, validates user limits, and records a billing event,
**So that** plan changes are fully automated without manual module toggling (FR100).

**Acceptance Criteria:**

**AC1 — Champs billing sur Tenant :**

**Given** la migration est appliquée
**When** on inspecte la table `tenants`
**Then** les colonnes suivantes existent : `plan` (String, default "free"), `max_users` (Int, default 1), `installation_fee` (Decimal nullable), `installation_paid` (Boolean, default false), `training_fee` (Decimal nullable), `training_paid` (Boolean, default false), `billing_start_date` (DateTime nullable), `billing_status` (String, default "trial"), `trial_ends_at` (DateTime nullable), `notes` (String nullable)

**AC2 — PATCH /admin/tenants/:id/plan — changement de plan :**

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/plan` avec `{ planCode, confirmDowngrade? }`
**When** le plan cible existe et est actif
**Then** `tenant.plan` est mis à jour avec le nouveau `planCode`
**And** `tenant.maxUsers` est synchronisé avec `PlanDefinition.maxUsers`
**And** les modules listés dans `PlanDefinition.includedModules` sont activés dans `TenantModule` s'ils ne l'étaient pas
**And** un `BillingEvent` de type `"upgrade"` ou `"downgrade"` est créé selon l'écart de prix
**And** la réponse est `200 OK` avec le tenant mis à jour

**AC3 — Validation maxUsers :**

**Given** le nouveau plan a un `maxUsers` inférieur au nombre d'utilisateurs actifs du tenant
**When** le superadmin envoie la requête sans flag de force
**Then** la réponse est `403 Forbidden` : `"Le tenant a N utilisateurs actifs, le plan cible en autorise M. Désactivez des comptes avant de downgrader."`

**AC4 — Confirmation downgrade avec désactivation modules :**

**Given** le nouveau plan a moins de modules que le plan actuel
**When** le superadmin envoie la requête sans `confirmDowngrade: true`
**Then** la réponse est `409 Conflict` avec la liste des modules qui seront désactivés : `{ modulesToDeactivate: ["promotions", "variants"] }`
**When** le superadmin renvoie avec `confirmDowngrade: true`
**Then** les modules hors-plan sont désactivés dans `TenantModule` et l'assignation est appliquée

**AC5 — Plan "free" à la création tenant :**

**Given** un nouveau tenant est créé via `POST /api/v1/admin/tenants`
**When** aucun `planCode` n'est précisé
**Then** `tenant.plan` vaut `"free"`, `tenant.maxUsers` vaut `1`, `tenant.billingStatus` vaut `"trial"`, `tenant.trialEndsAt` vaut `createdAt + 30 jours`

**Notes dev :**
- Étendre `TenantService` existant (ne pas créer un service dupliqué)
- L'activation/désactivation modules appelle `ModuleRegistryService.setModuleStatus(tenantId, moduleCode, status)` — créer ou étendre cette méthode
- Le `BillingEvent` est créé via `BillingService.recordEvent(...)` — introduit dans la Story 28-3
- Logger un TODO si `BillingService` n'est pas encore disponible (injectable ultérieurement)

**Files to create:**
- `apps/backend/prisma/migrations/20260320010000_add_billing_fields_to_tenant/migration.sql`
- `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.controller.ts`
- `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.service.ts`
- `apps/backend/src/kernel/billing/tenant-plan/dto/assign-plan.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — champs billing + `billingEvents` relation sur `Tenant`
- `apps/backend/src/organization/organization.service.ts` — `plan: "free"`, `trialEndsAt` à la création
- `apps/backend/src/kernel/billing/billing.module.ts` — exporter `TenantPlanService`

---

### Story 28-3: Backend — BillingEvent model + endpoints + cron suspension auto (FR101)

**As a** superadmin,
**I want** a `BillingEvent` ledger with REST endpoints to record and query payments, automatic billing status transitions, and a daily cron job that suspends overdue tenants,
**So that** billing is tracked exhaustively and suspended tenants are blocked automatically (FR101).

**Acceptance Criteria:**

**AC1 — Migration Prisma BillingEvent :**

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `BillingEvent`
**When** la migration est appliquée
**Then** la table `billing_events` existe dans le schéma `kernel` avec les colonnes : `id`, `tenant_id` (FK tenants), `type`, `amount`, `description` (nullable), `paid_at` (nullable), `due_date` (nullable), `status` (default "pending"), `payment_method` (nullable), `payment_ref` (nullable), `created_at`
**And** l'index `(tenant_id, status)` est présent

**AC2 — POST /admin/tenants/:id/billing/events — enregistrement paiement :**

**Given** un superadmin envoie `POST /api/v1/admin/tenants/:id/billing/events` avec `{ type, amount, description?, paidAt?, dueDate?, paymentMethod?, paymentRef? }`
**When** le tenant existe
**Then** un `BillingEvent` est créé et retourné en `201 Created`
**When** `type` est `"subscription"` et `paidAt` est fourni
**Then** `tenant.billingStatus` passe automatiquement à `"active"` et `tenant.billingStartDate` est défini si null

**AC3 — GET /admin/tenants/:id/billing — historique facturation :**

**Given** un superadmin appelle `GET /api/v1/admin/tenants/:id/billing`
**When** le tenant existe
**Then** la réponse est `200 OK` avec `{ tenant: { plan, billingStatus, trialEndsAt, billingStartDate, installationFee, installationPaid, trainingFee, trainingPaid, notes }, events: BillingEvent[] }` trié par `createdAt` DESC

**AC4 — PATCH /admin/tenants/:id/billing — mise à jour frais et notes :**

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/billing` avec `{ installationFee?, installationPaid?, trainingFee?, trainingPaid?, notes?, billingStatus? }`
**When** le tenant existe
**Then** les champs sont mis à jour sur le `Tenant` et la réponse est `200 OK`

**AC5 — Cron job suspension automatique :**

**Given** le cron job tourne chaque jour à 02:00 UTC
**When** un tenant a `billingStatus = "overdue"` depuis plus de 30 jours (configurable via variable d'environnement `BILLING_SUSPENSION_DAYS`, default 30)
**Then** `tenant.billingStatus` passe à `"suspended"`
**And** un `BillingEvent` de type `"payment"` avec `description: "Suspension automatique — impayé > 30j"` et `status: "overdue"` est créé pour traçabilité

**AC6 — Transition trial → overdue :**

**Given** le cron job tourne
**When** un tenant a `billingStatus = "trial"` et `trialEndsAt < now()`
**Then** `tenant.billingStatus` passe à `"overdue"`

**Notes dev :**
- Utiliser `@nestjs/schedule` (`@Cron(CronExpression.EVERY_DAY_AT_2AM)`) dans un `BillingSchedulerService`
- La variable `BILLING_SUSPENSION_DAYS` est lue via `ConfigService` (valeur par défaut 30)
- `BillingService.recordEvent(tenantId, eventDto)` est la méthode partagée appelée depuis 28-2 et 28-3
- Ne pas réutiliser `status` de `Tenant` directement depuis le frontend — toujours passer par l'API billing

**Files to create:**
- `apps/backend/prisma/migrations/20260320020000_add_billing_events/migration.sql`
- `apps/backend/src/kernel/billing/billing-events/billing-events.controller.ts`
- `apps/backend/src/kernel/billing/billing-events/billing-events.service.ts`
- `apps/backend/src/kernel/billing/billing-events/billing-scheduler.service.ts`
- `apps/backend/src/kernel/billing/billing-events/dto/create-billing-event.dto.ts`
- `apps/backend/src/kernel/billing/billing-events/dto/update-billing.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — modèle `BillingEvent` + relation `Tenant.billingEvents`
- `apps/backend/src/kernel/billing/billing.module.ts` — déclarer `BillingSchedulerService`, importer `ScheduleModule`
- `apps/backend/src/app.module.ts` — importer `ScheduleModule.forRoot()` si non présent

---

### Story 28-4: Frontend admin — Dropdown plan, onglet Facturation, badge statut (FR100–FR101)

**As a** superadmin,
**I want** the admin panel to show a plan dropdown when creating a tenant, a "Facturation" tab in tenant detail, and a billing status badge in the tenant list,
**So that** I can manage plans and billing without leaving the admin interface (FR100, FR101).

**Acceptance Criteria:**

**AC1 — Dropdown plan dans NewTenantForm :**

**Given** le superadmin ouvre le formulaire de création de tenant
**When** il sélectionne un plan dans le dropdown
**Then** les champs `maxUsers`, `suggestedInstallationFee`, `suggestedTrainingFee` sont pré-remplis avec les valeurs du `PlanDefinition`
**And** ces valeurs restent modifiables avant soumission
**And** le plan `"free"` est sélectionné par défaut

**AC2 — Onglet "Facturation" dans TenantDetailScreen :**

**Given** le superadmin ouvre le détail d'un tenant
**When** il clique sur l'onglet "Facturation"
**Then** il voit : plan actuel (badge coloré), `billingStatus`, `trialEndsAt` (si trial), `billingStartDate`, frais d'installation (montant + statut payé/non payé), frais de formation (montant + statut), notes libres
**And** la liste des `BillingEvent` du tenant est affichée en ordre chronologique inverse avec : date, type, montant, statut
**And** chaque événement `pending` ou `overdue` a un bouton "Marquer payé" qui appelle `PATCH /admin/tenants/:id/billing/events/:eventId` avec `{ status: "paid", paidAt: now() }`

**AC3 — Badge billing status dans la liste tenants :**

**Given** le superadmin est sur l'écran liste des tenants
**When** la liste est chargée
**Then** chaque ligne affiche un badge coloré selon `billingStatus` : `trial` (bleu), `active` (vert), `overdue` (orange), `suspended` (rouge)
**And** un filtre rapide permet d'afficher uniquement les tenants `overdue` ou `suspended`

**AC4 — Bouton "Réactiver" pour tenants suspendus :**

**Given** le superadmin est sur l'onglet Facturation d'un tenant suspendu
**When** il clique sur "Réactiver"
**Then** un dialog de confirmation s'affiche : "Réactiver ce tenant ? Le statut passera à 'active'."
**When** il confirme
**Then** `PATCH /admin/tenants/:id/billing` est appelé avec `{ billingStatus: "active" }` et le badge se met à jour

**Notes dev :**
- Le panel admin est dans `apps/frontend/lib/features/admin/` (vérifier le chemin exact du panel)
- Utiliser `FutureProvider` Riverpod pour `planDefinitionsProvider` (chargé une fois, mis en cache)
- Le dropdown plan appelle `GET /api/v1/admin/plans` au chargement du formulaire

**Files to create:**
- `apps/frontend/lib/features/admin/billing/data/repositories/billing_repository.dart`
- `apps/frontend/lib/features/admin/billing/presentation/providers/billing_providers.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_tab.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_event_tile.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/plan_dropdown.dart`

**Files to modify:**
- `apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart` — ajouter onglet "Facturation"
- `apps/frontend/lib/features/admin/presentation/screens/tenants_list_screen.dart` — badge billingStatus + filtre
- `apps/frontend/lib/features/admin/presentation/widgets/new_tenant_form.dart` — dropdown plan + pré-remplissage

---

### Story 28-5: Frontend backoffice — Écran "Mon abonnement" dans Paramètres (FR102)

**As a** tenant owner,
**I want** an "Mon abonnement" screen in my backoffice Settings that shows my current plan, included modules, billing status, and payment history, with a button to request an upgrade,
**So that** I can understand what I'm paying for and escalate upgrades without contacting Carlos directly (FR102).

**Acceptance Criteria:**

**AC1 — Écran "Mon abonnement" accessible depuis les Paramètres :**

**Given** le propriétaire est sur l'écran Paramètres du backoffice
**When** il tape sur "Mon abonnement"
**Then** l'écran `SubscriptionScreen` s'ouvre avec : nom du plan actuel (badge coloré), prix mensuel, `maxUsers`, liste des modules inclus (icône + nom lisible), statut de facturation, prochaine échéance estimée (si `billingStartDate` défini : date + 30 jours)

**AC2 — Historique des paiements :**

**Given** le propriétaire est sur l'écran "Mon abonnement"
**When** la section "Historique" est chargée
**Then** la liste des `BillingEvent` du tenant est affichée (type, montant, date, statut)
**And** les événements `pending` affichent le label "En attente de paiement"
**And** les événements `paid` affichent la date de paiement

**AC3 — Bouton "Demander un upgrade" :**

**Given** le propriétaire tape sur "Demander un upgrade"
**When** un dialog de confirmation s'affiche avec un champ texte optionnel (message libre)
**And** il confirme
**Then** `POST /api/v1/settings/billing/upgrade-request` est appelé avec `{ message? }`
**And** une notification in-app est envoyée au superadmin : "Tenant [name] demande un upgrade de plan [current] → ?"
**And** le propriétaire voit un toast : "Votre demande a été envoyée. Carlos vous contactera sous 24h."

**AC4 — Message bloquant si tenant suspendu :**

**Given** le tenant a `billingStatus = "suspended"`
**When** le propriétaire ouvre n'importe quel écran du backoffice ou du POS
**Then** un écran bloquant remplace le contenu normal : titre "Abonnement expiré", message "Votre abonnement Scalario est suspendu. Contactez votre administrateur pour régulariser votre situation.", bouton "Contacter" (ouvre WhatsApp ou appel selon `notificationPhone` du tenant)
**And** aucun autre écran n'est accessible (navigation bloquée)

**Notes dev :**
- `GET /api/v1/settings/billing` retourne `{ plan: PlanDefinition, billingStatus, events: BillingEvent[] }` — protégé par `JwtAuthGuard` + `TenantGuard`, rôle `Owner` uniquement
- `POST /api/v1/settings/billing/upgrade-request` crée une notification interne (pas de paiement en Phase 2a)
- Le blocage "suspendu" est géré côté frontend dans le router guard principal (vérifier `billingStatus` au démarrage de session)
- Le blocage backend (403) est implémenté en Story 28-6

**Files to create:**
- `apps/frontend/lib/features/shared/billing/data/repositories/subscription_repository.dart`
- `apps/frontend/lib/features/shared/billing/presentation/providers/subscription_provider.dart`
- `apps/frontend/lib/features/shared/billing/presentation/screens/subscription_screen.dart`
- `apps/frontend/lib/features/shared/billing/presentation/widgets/plan_info_card.dart`
- `apps/frontend/lib/features/shared/billing/presentation/widgets/billing_history_list.dart`
- `apps/frontend/lib/features/shared/billing/presentation/screens/suspended_screen.dart`

**Files to modify:**
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/settings_screen.dart` — lien "Mon abonnement"
- `apps/backend/src/kernel/billing/billing-events/billing-events.controller.ts` — ajouter routes settings (`GET /settings/billing`, `POST /settings/billing/upgrade-request`)

---

### Story 28-6: Backend + Frontend — Enforcement statut suspendu (FR101)

**As a** system,
**I want** that all API endpoints return 403 when a tenant is suspended, and the Flutter client intercepts this code to display a blocking expiry screen,
**So that** suspended tenants cannot use the app until their subscription is regularised (FR101).

**Acceptance Criteria:**

**AC1 — BillingGuard backend — blocage global sur tenants suspendus :**

**Given** un utilisateur d'un tenant avec `billingStatus = "suspended"` envoie une requête authentifiée
**When** la requête atteint n'importe quel endpoint (sauf `POST /auth/login`, `POST /auth/refresh`, `GET /settings/billing`)
**Then** le backend répond `403 Forbidden` avec le body `{ error: "TENANT_SUSPENDED", message: "Abonnement expiré — contactez votre administrateur" }`

**AC2 — BillingGuard — tenants non suspendus non affectés :**

**Given** un utilisateur d'un tenant avec `billingStatus ≠ "suspended"`
**When** il envoie une requête normale
**Then** le `BillingGuard` laisse passer sans overhead perceptible
**And** le statut `trial` ou `overdue` ne bloque PAS l'accès (uniquement `suspended` bloque)

**AC3 — Flutter — interception globale 403 TENANT_SUSPENDED :**

**Given** le client Flutter reçoit une réponse `403` avec `error: "TENANT_SUSPENDED"`
**When** l'intercepteur HTTP détecte ce code d'erreur
**Then** la navigation est redirigée vers `SuspendedScreen` indépendamment de l'écran courant
**And** tous les appels API suivants sont annulés tant que la session n'est pas rechargée

**AC4 — Réactivation par le superadmin :**

**Given** le superadmin appelle `PATCH /api/v1/admin/tenants/:id/billing` avec `{ billingStatus: "active" }`
**When** le tenant était `"suspended"`
**Then** `tenant.billingStatus` passe à `"active"`
**And** un `BillingEvent` de type `"payment"` avec `description: "Réactivation manuelle par superadmin"` et `status: "paid"` est créé
**And** les prochaines requêtes de ce tenant ne sont plus bloquées par le `BillingGuard`

**AC5 — Whitelist routes exclues du guard :**

**Given** un utilisateur d'un tenant suspendu
**When** il appelle `POST /auth/login`, `POST /auth/refresh`, ou `GET /settings/billing`
**Then** le `BillingGuard` laisse passer (whitelist hardcodée dans le guard)
**And** l'utilisateur peut consulter son statut de facturation même si suspendu

**Notes dev :**
- `BillingGuard` est un `CanActivate` NestJS global (`APP_GUARD`) enregistré après `JwtAuthGuard` dans `AppModule` — il lit `tenant.billingStatus` depuis le contexte de requête déjà peuplé par `TenantGuard`
- Cache en mémoire du `billingStatus` par `tenantId` (TTL 60s) pour éviter une requête DB par appel — invalider le cache sur `PATCH /admin/tenants/:id/billing`
- Flutter : l'intercepteur est ajouté dans le `Dio` global (`apps/frontend/lib/core/network/api_client.dart`)
- Le `SuspendedScreen` est introduit en Story 28-5 — le réutiliser ici

**Files to create:**
- `apps/backend/src/kernel/billing/guards/billing.guard.ts`

**Files to modify:**
- `apps/backend/src/app.module.ts` — enregistrer `BillingGuard` comme `APP_GUARD` global
- `apps/frontend/lib/core/network/api_client.dart` — intercepteur `403 TENANT_SUSPENDED`
- `apps/backend/src/kernel/billing/billing-events/billing-events.service.ts` — `reactivateTenant()` crée le `BillingEvent` de réactivation

---

## Epic 29: Types de Business Configurables (FR104–FR106)

Le superadmin peut assigner un type de business à chaque tenant lors de sa création. Les types sont définis dans une table `BusinessTypeDefinition` configurable sans déploiement — chaque type porte un code unique, un nom affiché, des flags produit par défaut (`defaultFlags`), les sections visibles dans le formulaire produit (`visibleSections`), et une liste de catégories suggérées (FR104, Phase 2a). Le formulaire de création/édition de produit dans le backoffice lit le `businessType` du tenant pour afficher en priorité les champs pertinents, pré-remplir les flags par défaut, et masquer les champs non-pertinents derrière un toggle "Afficher plus d'options" — le propriétaire peut toujours override chaque flag par produit (FR105, Phase 2a). À la création d'un tenant avec un `businessType != "generaliste"`, les catégories suggérées sont automatiquement pré-créées dans son catalogue ; le propriétaire peut les renommer, supprimer ou en ajouter (FR106, Phase 2a).

---

### Story 29-1: Backend — BusinessTypeDefinition model, seed 13 types, endpoints (FR104)

**As a** superadmin,
**I want** a `BusinessTypeDefinition` model with seed data for 13 business types, two read endpoints listing and fetching types, and a `PATCH /admin/tenants/:id/business-type` endpoint to assign a type to a tenant,
**So that** business types are configurable without deployment and serve as the source of truth for product form defaults and suggested categories (FR104).

**Acceptance Criteria:**

**AC1 — Migration Prisma BusinessTypeDefinition :**

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `BusinessTypeDefinition`
**When** la migration est appliquée
**Then** la table `business_type_definitions` existe dans le schéma `kernel` avec les colonnes : `id`, `code` (unique), `name`, `description` (nullable), `default_flags` (Json), `visible_sections` (String[]), `suggested_categories` (String[]), `icon` (nullable), `is_active` (default true), `created_at`

**AC2 — Migration Prisma Tenant.businessType :**

**Given** la migration est appliquée
**When** on inspecte la table `tenants`
**Then** la colonne `business_type` (String, default `"generaliste"`) est présente
**And** aucune contrainte FK stricte sur `business_type` — le code est libre (flexibilité seed)

**AC3 — Seed 13 types :**

**Given** la commande `prisma db seed` est exécutée
**When** la base est vide ou les types sont absents
**Then** 13 types sont créés par upsert sur `code` :

| code | name | defaultFlags (clés non-nulles) | visibleSections | suggestedCategories |
|:---|:---|:---|:---|:---|
| `generaliste` | Généraliste | tous false/null | [] | [] |
| `epicerie` | Épicerie & Alimentation | expiryDays: 30 | ["expiry"] | ["Fruits & Légumes", "Épices", "Céréales", "Boissons", "Produits laitiers", "Conserves"] |
| `telephonie` | Téléphonie & Accessoires | hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 | ["variants", "serial", "warranty"] | ["Smartphones", "Accessoires", "Cartes SIM", "Recharge", "Réparation"] |
| `textile` | Textile & Habillement | hasVariants: true | ["variants"] | ["Hauts", "Bas", "Robes", "Chaussures", "Accessoires", "Tissu"] |
| `pharmacie` | Pharmacie & Parapharmacie | expiryDays: 365, requiresPrescription: false | ["expiry", "prescription"] | ["Médicaments", "Parapharmacie", "Matériel médical", "Vitamines"] |
| `quincaillerie` | Quincaillerie & Matériaux | hasVariants: true, unitType: "weight" | ["variants", "weight"] | ["Peinture", "Plomberie", "Électricité", "Outillage", "Ciment", "Fer"] |
| `cosmetique` | Cosmétique & Beauté | hasVariants: true, expiryDays: 730 | ["variants", "expiry"] | ["Soin visage", "Soin corps", "Cheveux", "Parfums", "Maquillage"] |
| `restaurant` | Restaurant & Restauration rapide | tous false/null | [] | ["Plats", "Boissons", "Entrées", "Desserts", "Menus"] |
| `boulangerie` | Boulangerie & Pâtisserie | expiryDays: 3 | ["expiry"] | ["Pain", "Viennoiseries", "Gâteaux", "Sandwichs", "Boissons"] |
| `services` | Services & Prestation | tous false/null | [] | ["Consultation", "Réparation", "Formation", "Livraison", "Autre"] |
| `informatique` | Informatique & Électronique | trackSerialNumbers: true, warrantyMonths: 12, hasVariants: true | ["variants", "serial", "warranty"] | ["Ordinateurs", "Téléphones", "Accessoires", "Composants", "Imprimantes", "Réparation"] |
| `vehicules` | Véhicules & Pièces détachées | trackSerialNumbers: true, warrantyMonths: 6 | ["serial", "warranty"] | ["Pièces moteur", "Carrosserie", "Pneumatiques", "Électronique auto", "Huiles & Filtres"] |
| `grossiste` | Commerce de gros | hasVariants: true, unitType: "weight" | ["variants", "weight"] | ["Alimentaire", "Cosmétique", "Textile", "Quincaillerie", "Électronique"] |

**And** le seed est idempotent (upsert par `code`)

**AC4 — GET /admin/business-types — liste :**

**Given** un superadmin authentifié appelle `GET /api/v1/admin/business-types`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste de tous les `BusinessTypeDefinition` actifs triés par `name` ASC
**And** les types inactifs (`isActive = false`) sont exclus (seuls les actifs sont affichés dans les sélecteurs)

**AC5 — GET /admin/business-types/:code — détail :**

**Given** un superadmin appelle `GET /api/v1/admin/business-types/:code`
**When** le code existe
**Then** la réponse est `200 OK` avec le `BusinessTypeDefinition` complet incluant `defaultFlags`, `visibleSections` et `suggestedCategories`
**When** le code n'existe pas
**Then** la réponse est `404 Not Found` : `"Type de business introuvable : :code"`

**AC6 — PATCH /admin/tenants/:id/business-type — assignation :**

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/business-type` avec `{ businessType: "telephonie" }`
**When** le tenant existe et le code correspond à un type actif
**Then** `tenant.businessType` est mis à jour et le tenant mis à jour est retourné en `200 OK`
**When** le code n'existe pas dans `business_type_definitions`
**Then** la réponse est `404 Not Found` : `"Type de business inconnu : :code"`
**And** le `businessType` du tenant n'est pas modifié

**Notes dev :**
- Module `BusinessTypeModule` dans `apps/backend/src/kernel/business-type/`
- `BusinessTypeService` expose : `listActive()`, `getDefinition(code)`, `seedCategories(tenantId, code)` (utilisée en 29-4)
- `SuperadminGuard` sur toutes les routes admin ; `TenantGuard` sur `PATCH /admin/tenants/:id/business-type`
- Le `defaultFlags` est un objet JSON libre — ne pas typer rigidement côté DTO (Prisma `Json`)
- À la création tenant (`POST /admin/tenants`), si un `businessType` est fourni, le setter appelle `BusinessTypeService.seedCategories()` — prévu pour Story 29-4
- Seed dans `apps/backend/prisma/seed.ts` section kernel — ajouter après le seed `PlanDefinition`

**Files to create:**
- `apps/backend/prisma/migrations/20260320040000_add_business_type_definitions/migration.sql`
- `apps/backend/src/kernel/business-type/business-type.module.ts`
- `apps/backend/src/kernel/business-type/business-type.controller.ts`
- `apps/backend/src/kernel/business-type/business-type.service.ts`
- `apps/backend/src/kernel/business-type/dto/assign-business-type.dto.ts`

**Files to modify:**
- `apps/backend/prisma/schema.prisma` — modèle `BusinessTypeDefinition` + champ `businessType` sur `Tenant`
- `apps/backend/prisma/seed.ts` — seed 13 types
- `apps/backend/src/app.module.ts` — importer `BusinessTypeModule`

---

### Story 29-2: Admin panel — Dropdown "Type de business" dans NewTenantForm + écran types (FR104)

**As a** superadmin,
**I want** a business type dropdown in the tenant creation form, the assigned type displayed on the tenant detail screen, and a read-only screen listing all available business types,
**So that** I can configure the business context of each tenant at creation time and consult available types from the admin panel (FR104).

**Acceptance Criteria:**

**AC1 — Dropdown "Type de business" dans NewTenantForm :**

**Given** le superadmin ouvre le formulaire de création de tenant dans l'admin panel Flutter
**When** il arrive sur le champ "Type de business"
**Then** un `DropdownButtonFormField` affiche la liste des types actifs chargée depuis `GET /api/v1/admin/business-types`
**And** la valeur par défaut est `"generaliste"` (Généraliste)
**And** chaque entrée affiche le nom du type (ex: "Téléphonie & Accessoires")

**AC2 — Soumission du formulaire avec businessType :**

**Given** le superadmin sélectionne un type (ex: `"telephonie"`) et soumet le formulaire
**When** l'appel `POST /api/v1/admin/tenants` est envoyé
**Then** le body inclut `businessType: "telephonie"`
**And** en cas de succès, un message de confirmation indique que les catégories suggérées ont été créées si `businessType != "generaliste"`

**AC3 — Affichage businessType dans TenantDetailScreen :**

**Given** le superadmin consulte la fiche d'un tenant existant
**When** le tenant a un `businessType` assigné
**Then** le nom complet du type (ex: "Téléphonie & Accessoires") est affiché dans la section informations générales
**And** un bouton "Modifier" ouvre une boîte de dialogue permettant de changer le type via `PATCH /admin/tenants/:id/business-type`

**AC4 — Changement de type depuis TenantDetailScreen :**

**Given** le superadmin clique sur "Modifier" dans la section type de business
**When** il sélectionne un nouveau type et confirme
**Then** `PATCH /api/v1/admin/tenants/:id/business-type` est appelé
**And** la fiche se met à jour avec le nouveau type affiché
**And** un message d'avertissement indique que les catégories suggérées du nouveau type ne sont pas recréées automatiquement (la création ne se fait qu'à la création initiale du tenant)

**AC5 — Écran lecture seule "Types de business" :**

**Given** le superadmin navigue vers la section "Types de business" de l'admin panel
**When** l'écran se charge
**Then** la liste de tous les types actifs est affichée avec : code, nom, nombre de catégories suggérées, icône (si disponible)
**And** en tapant sur un type, un panneau de détail affiche `defaultFlags` et `suggestedCategories` en lecture seule
**And** aucun bouton de modification n'est exposé (édition réservée à une Phase 3 du backoffice admin)

**Notes dev :**
- `BusinessTypeRepository` Flutter dans `apps/frontend/lib/features/admin/business_type/data/`
- Provider Riverpod `businessTypesProvider` charge la liste depuis l'API au montage de l'écran
- `NewTenantForm` est dans `apps/frontend/lib/features/admin/tenants/presentation/` — ajouter le champ `businessType` après le champ `plan`
- `TenantDetailScreen` est dans le même dossier — ajouter une section "Type de business" avec badge + bouton Modifier
- L'écran "Types de business" est accessible via la navigation latérale admin (item après "Plans tarifaires")

**Files to create:**
- `apps/frontend/lib/features/admin/business_type/data/business_type_repository.dart`
- `apps/frontend/lib/features/admin/business_type/presentation/screens/business_types_screen.dart`
- `apps/frontend/lib/features/admin/business_type/presentation/providers/business_type_providers.dart`

**Files to modify:**
- `apps/frontend/lib/features/admin/tenants/presentation/widgets/new_tenant_form.dart` — dropdown businessType
- `apps/frontend/lib/features/admin/tenants/presentation/screens/tenant_detail_screen.dart` — section type + bouton Modifier
- `apps/frontend/lib/features/admin/navigation/admin_navigation.dart` — item "Types de business"

---

### Story 29-3: Frontend backoffice — ProductFormDialog adaptatif selon businessType (FR105)

**As a** tenant owner,
**I want** the product creation/edit form to automatically show relevant fields first, pre-fill flag defaults, and hide non-relevant fields behind an "Afficher plus d'options" toggle based on my business type,
**So that** I can create products faster without being overwhelmed by irrelevant options, while keeping full control over every flag (FR105).

**Acceptance Criteria:**

**AC1 — Chargement de la config businessType au démarrage :**

**Given** le propriétaire ouvre l'application backoffice
**When** la session est établie
**Then** la config du type de business est chargée depuis `GET /api/v1/business-type/config` (endpoint tenant-scoped qui retourne le `BusinessTypeDefinition` correspondant à `Tenant.businessType`)
**And** la config est mise en cache localement (valide pour la durée de la session)

**AC2 — Sections visibles déterminées par visibleSections :**

**Given** le propriétaire ouvre `ProductFormDialog` pour créer ou éditer un produit
**When** son `businessType` est `"telephonie"` (visibleSections: ["variants", "serial", "warranty"])
**Then** les sections "Variantes", "Numéro de série" et "Garantie" sont affichées par défaut dans le formulaire
**And** les autres sections (ex: "Date de péremption", "Ordonnance") sont masquées par défaut

**AC3 — defaultFlags pré-remplissent les flags produit :**

**Given** le propriétaire ouvre `ProductFormDialog` pour créer un nouveau produit
**When** son `businessType` est `"telephonie"` (defaultFlags: { hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 })
**Then** le champ `hasVariants` est coché (true) par défaut
**And** le champ `trackSerialNumbers` est coché (true) par défaut
**And** le champ `warrantyMonths` est pré-rempli à `12`
**When** son `businessType` est `"generaliste"` (tous flags false/null)
**Then** tous les flags sont décochés et tous les champs optionnels sont vides par défaut

**AC4 — Toggle "Afficher plus d'options" :**

**Given** des sections sont masquées par défaut (non listées dans `visibleSections`)
**When** le propriétaire clique sur "Afficher plus d'options"
**Then** toutes les sections cachées deviennent visibles dans le formulaire
**And** le libellé du bouton devient "Masquer les options avancées"
**When** il clique à nouveau
**Then** les sections non-pertinentes sont à nouveau masquées (et non modifiées si l'utilisateur les avait remplies)

**AC5 — Override libre par le propriétaire :**

**Given** le formulaire est pré-rempli avec les defaults du businessType
**When** le propriétaire déccoche `trackSerialNumbers` ou modifie `warrantyMonths`
**Then** la valeur saisie est respectée et sauvegardée telle quelle
**And** aucun message d'avertissement ni blocage n'est affiché — l'override est silencieux et immédiat

**AC6 — Produits existants non affectés :**

**Given** le propriétaire édite un produit existant dont les flags ont été saisis manuellement
**When** le formulaire se charge
**Then** les valeurs sauvegardées du produit sont affichées (non écrasées par les defaults du businessType)
**And** les defaults du businessType s'appliquent uniquement à la création de nouveaux produits

**Notes dev :**
- Endpoint backend requis : `GET /api/v1/business-type/config` — retourne le `BusinessTypeDefinition` du tenant courant (lu depuis `Tenant.businessType`) ; protégé par `JwtAuthGuard` + `TenantGuard`
- Ajouter ce endpoint dans `BusinessTypeController` côté backend (non admin)
- `ProductFormDialog` est dans `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — lire la config depuis `businessTypeConfigProvider`
- Implémenter un provider Riverpod `businessTypeConfigProvider` qui appelle `BusinessTypeRepository.getMyConfig()` et met en cache le résultat
- La logique de masquage est purement Flutter : `visibleSections` drive `_showSection(String section)` → bool

**Files to create:**
- `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart`
- `apps/frontend/lib/features/shared/business_type/presentation/providers/business_type_config_provider.dart`

**Files to modify:**
- `apps/backend/src/kernel/business-type/business-type.controller.ts` — ajouter `GET /business-type/config` (tenant-scoped)
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — adapter selon `visibleSections` et `defaultFlags`

---

### Story 29-4: Backend + Frontend — Pré-création des catégories suggérées à la création du tenant (FR106)

**As a** tenant owner,
**I want** to find the suggested categories of my business type already created in my catalog when I first log in,
**So that** I can start adding products immediately without manual category setup (FR106).

**Acceptance Criteria:**

**AC1 — Seed des catégories à la création tenant :**

**Given** le superadmin crée un tenant avec `businessType = "telephonie"` (suggestedCategories: ["Smartphones", "Accessoires", "Cartes SIM", "Recharge", "Réparation"])
**When** le tenant est créé avec succès
**Then** `BusinessTypeService.seedCategories(tenantId, "telephonie")` est appelé automatiquement dans le flux de création
**And** 5 `CatalogCategory` sont créées dans le schéma `shared` pour ce tenant avec les noms correspondants
**And** chaque catégorie a `tenantId` correct, `createdBy` = id du superadmin (ou un uuid système), `isActive = true`

**AC2 — Pas de seed pour le type "generaliste" :**

**Given** le superadmin crée un tenant avec `businessType = "generaliste"` (suggestedCategories: [])
**When** le tenant est créé
**Then** `BusinessTypeService.seedCategories()` est appelé mais ne crée aucune catégorie (liste vide)
**And** aucune erreur n'est levée

**AC3 — Idempotence du seed de catégories :**

**Given** `BusinessTypeService.seedCategories(tenantId, code)` est appelé deux fois pour le même tenant
**When** la deuxième exécution se produit (ex: retry après erreur réseau)
**Then** aucune catégorie dupliquée n'est créée (upsert ou skip si `name` + `tenantId` existent déjà)

**AC4 — Propriétaire voit les catégories prêtes à l'emploi :**

**Given** le propriétaire se connecte pour la première fois après la création du tenant
**When** il navigue vers la gestion des catégories dans le backoffice
**Then** les catégories suggérées de son type de business sont listées et actives
**And** il peut immédiatement assigner ces catégories aux produits qu'il crée

**AC5 — Propriétaire peut renommer une catégorie suggérée :**

**Given** le propriétaire voit la catégorie "Cartes SIM" dans sa liste
**When** il la renomme en "Forfaits & SIM"
**Then** le nom est mis à jour via `PATCH /api/v1/catalog/categories/:id`
**And** aucune contrainte ne bloque le renommage (les catégories suggérées ne sont pas verrouillées)

**AC6 — Propriétaire peut supprimer une catégorie suggérée :**

**Given** le propriétaire voit la catégorie "Réparation" dans sa liste
**When** il la supprime (soft delete)
**Then** la catégorie est marquée inactive et disparaît de la liste principale
**And** aucune contrainte ne bloque la suppression (même si des produits y sont associés — les produits conservent leur catégorie, qui passe en état archivé)

**AC7 — Propriétaire peut ajouter de nouvelles catégories :**

**Given** le propriétaire a ses catégories suggérées créées
**When** il crée une nouvelle catégorie "Dongles WiFi" via l'interface habituelle
**Then** la nouvelle catégorie est créée normalement via `POST /api/v1/catalog/categories`
**And** elle coexiste avec les catégories suggérées sans distinction visuelle particulière

**Notes dev :**
- `BusinessTypeService.seedCategories(tenantId, code)` est appelé dans `OrganizationService.createTenant()` après la création du tenant, dans un try/catch — un échec du seed ne doit PAS faire échouer la création du tenant (erreur loggée, pas propagée)
- La méthode `seedCategories` appelle `CatalogService.createCategory()` ou insère directement via Prisma (dépendance à valider selon l'architecture du `CatalogModule`)
- Frontend : aucun changement requis sur les écrans existants — les catégories apparaissent automatiquement via le endpoint `GET /api/v1/catalog/categories` déjà implémenté
- Un log structuré est émis au moment du seed : `{ event: "business_type_categories_seeded", tenantId, businessType, count }` pour traçabilité admin

**Files to modify:**
- `apps/backend/src/kernel/business-type/business-type.service.ts` — implémenter `seedCategories(tenantId, code)`
- `apps/backend/src/organization/organization.service.ts` — appeler `BusinessTypeService.seedCategories()` dans le flux `createTenant()`
