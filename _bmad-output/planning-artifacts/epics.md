---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories']
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - docs/architecture-scalario-2026-03-31.md
---

# Scalario - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Scalario, decomposing the requirements from the PRD v8.3, Architecture v2.0, into implementable stories.

## Requirements Inventory

### Functional Requirements

**Identity & Access (FR1–FR6)**
FR1: Admin can create and configure a new tenant (currency, timezone, fiscal jurisdiction, business type, org_mode)
FR2: Owner can create user accounts, assign roles, and assign departments (Enterprise mode)
FR3: System enforces RBAC permissions at the intersection of (tenant, department, role). Retail: boundaries per active sector. Enterprise: boundaries per department.
FR4: JWT authentication scoped to tenant
FR5: Tenant isolation enforced automatically — no user can access another tenant's data
FR6: Sessions expire after configurable timeout

**Modules & Sectors (FR7–FR10)**
FR7: Admin can activate or deactivate shared and sectoral modules per tenant
FR8: Sectoral modules validate their dependencies at activation
FR9: Deactivating a module for one tenant has zero impact on other tenants
FR10: Retail mode: one active sector per tenant. Enterprise mode: multiple business_type active simultaneously per configured departments.

**Catalog (FR11–FR15)**
FR11: Owner can create, edit, and deactivate items (name, price, category, barcode)
FR12: Items support a type discriminator (physical, bookable, service)
FR13: Sectoral modules can extend items with sector-specific fields via UI-Driven Engine
FR14: Owner can manage product categories
FR15: Catalog data is available offline on device

**Transactions (FR16–FR22)**
FR16: Commercial can create a sale transaction by selecting items and quantities
FR17: Commercial can apply a payment method (cash, mobile money, customer credit)
FR18: System calculates totals with currency-specific rounding (XOF: 5 FCFA)
FR19: System records change given for cash payments
FR20: Transactions support lifecycle states (instant, accumulating, scheduled)
FR21: Sectoral modules can extend transactions (e.g. sessionId, receiptNumber for Retail)
FR22: All transactions are written locally first and queued for sync

**POS Session (FR23–FR28)**
FR23: Commercial can open a session by declaring the initial cash float
FR24: All sales during an active session are associated with that session
FR25: Commercial can close a session by declaring the counted amount
FR26: System calculates and displays the theoretical/real discrepancy
FR27: Commercial must provide an explanation for any discrepancy before closing
FR28: Manager can consult closing reports of all commercials at their location

**Inventory & Stock (FR29–FR36)**
FR29: Manager can receive supplier deliveries and record received vs. expected quantities
FR30: System traces receipt variances with observer notes
FR31: Manager can create store → shelf transfers with declared quantities
FR32: Commercial can confirm receipt of a transfer and declare the quantity actually received
FR33: System traces and automatically assigns transfer variances
FR34: Commercial can declare stock losses with mandatory reason
FR35: Manager can perform partial inventories with variance signaling
FR36: Inventory data is maintained locally for offline mode

**Contacts (FR37–FR40)**
FR37: Users can create and manage customer profiles (name, phone, type)
FR38: Commercial can associate a transaction with a customer profile
FR39: Commercial can record a credit sale against a customer profile, updating balance
FR40: Customer profiles and balances are available offline

**Sync & Offline (FR41–FR47)**
FR41: All CRUD operations work identically online or offline
FR42: System queues (outbox) all local mutations for automatic sync on reconnection
FR43: Sync engine transmits only deltas (incremental sync)
FR44: System resolves conflicts (last-write-wins for non-critical data, manual resolution queue for financial data)
FR45: Connectivity indicator visible only in status bar (< 5% screen area), never blocks operations
FR46: System recovers consistent state after unexpected termination, zero data loss
FR47: Local database retains operational data for a configurable period (30–90 days)

**Reporting & Accountability (FR48–FR51)**
FR48: Manager can generate a daily consolidation report (sales, losses, variances, transfers)
FR49: Owner can view dashboard (revenue, sale count, losses, cash discrepancies, critical stock)
FR50: System maintains an immutable audit trail of all mutations
FR51: Audit trail retained indefinitely server-side, configurable period locally

**Scalario Connect — Anticipated DB Structure (FR52–FR55)**
FR52: Tenants table includes `referred_by` (nullable UUID) and `network_visible` (bool)
FR53: Contacts table includes `linked_tenant_id` (nullable UUID) to link a supplier to a Scalario tenant
FR54: Catalog_items table includes `supplier_reference` (nullable UUID)
FR55: Transaction types support `transfer_inter_tenant` for future inter-tenant operations

**Migration & Architecture (FR56–FR58)**
FR56: Migration of existing client data to multi-schema architecture without loss
FR57: Prisma operates on kernel, shared, and retail schemas with referential integrity
FR58: Sync engine operates module-agnostically with per-module adapters

**Scalario Enterprise — Anticipated DB Structure (FR59–FR62)**
FR59: Tenants table includes `org_mode` (enum: standalone | integrated | federated) and `parent_tenant_id` (nullable UUID)
FR60: Users table includes `department_ids` (UUID array) for multi-department membership
FR61: TenantModule table includes `department_id` (nullable UUID) for per-department activation
FR62: System supports internal inter-department events via Kernel event bus

**HR & Payroll Enterprise (FR63–FR68)**
FR63: HR manager can create and manage employee records
FR64: System automatically calculates net salary from gross applying active payroll plugin rules (pluggable: CNSS BF, IPRES SN, CNPS CI, etc.)
FR65: HR manager can record absences; factored into monthly payroll
FR66: System generates payslips for all active employees in one operation; validated payslip is immutable
FR67: System generates social declaration file (employees + employer) in local format, exportable CSV/PDF
FR68: Payslip validation emits inter-department event to Accounting for automatic salary expense entry

**Accounting & Finance Enterprise (FR69–FR72)**
FR69: System provides a pre-loaded chart of accounts per active accounting plugin (OHADA default for UEMOA, pluggable for others)
FR70: Accountant can enter manual journal entries; auto-generated entries are pre-filled and editable before validation
FR71: System supports bank reconciliation: statement import (CSV/PDF), automatic match suggestions, manual validation of discrepancies
FR72: Accountant can close a month; entries freeze. System generates balance sheet and income statement per active accounting plugin, exportable PDF/Excel.

**Enterprise Import & Error Management (FR73–FR74)**
FR73: System accepts CSV imports for employees, chart of accounts, opening balances, equipment. Per-line error report. Partial import allowed.
FR74: Retail tenant (standalone) can be migrated to Enterprise (integrated) without data loss and without maintenance window

**Sync Failure Management (FR75)**
FR75: System implements full lifecycle for failed mutations: outbox → 3 retries (exponential backoff) → FAILED marking → admin/user notification → manual resolution interface. Financial mutations never subject to last-write-wins — mandatory manual resolution queue.

**Advanced Inventory & Configurable Sales (FR76–FR88)**
FR76: Owner can configure unitType per item (unit, weight, volume, length) with native unit. Default: unit.
FR77: For weight/volume/length items, POS shows floating-point quantity field; total auto-calculated; exact quantity and unit recorded.
FR78: Owner can define per item: sale unit label, unit price, optional conversion factor to stock unit.
FR79: Owner/authorized manager can create purchase orders (supplier, items, expected quantity, delivery date, status lifecycle: draft→confirmed→partially_received→received→cancelled)
FR80: Manager can link a delivery reception to an existing purchase order, record received quantities, note quality observations. Variances traced in audit trail.
FR81: Owner can define low stock threshold (lowStockThreshold) per item, in native stock unit.
FR82: After each stock movement, system evaluates stock vs. threshold; triggers push notification and flags in daily summary if threshold breached.
FR83: Owner can define repackaging rules (source article, target article, conversion factor). Repackaging decrements source, increments target, generates REPACKAGING stock movement. *(Phase 2b)*
FR84: Owner can configure freshness window (days) and natural loss tolerance (%) per item. Expiry auto-calculated on reception. *(Phase 2b)*
FR85: Items with freshness configured display color indicator in POS grid and stock views (Green/Orange/Red). Configurable thresholds. *(Phase 2b)*
FR86: Each day at configurable time (default 20h00 local), system sends daily summary to owner via WhatsApp (opt-in) and/or push: revenue, losses, low-stock items, top 3 best sellers.
FR87: During loss declaration (FR34), user must select loss location from tenant-configurable list. Loss reports filterable by location.
FR88: Commercial can create internal replenishment request (item, quantity, urgency). Configurable circuit: Commercial → Manager (optional) → Owner approval. Approved request auto-generates store→shelf transfer.

**Variants, Multi-pricing & Promotions (FR89–FR91)**
FR89: Catalog item can have tenant-configured variants (attributes: free labels). Each variant has own SKU, optional barcode, price, independent stock. *(Phase 2b)*
FR90: Item can have multiple price levels (retail, wholesale, loyalty, promotional). Auto-applied by customerType or quantity threshold. Manual override with price_override permission. *(Phase 2b)*
FR91: Owner can create promotion rules: % discount, quantity offer (X+Y), temporary crossed-out price. Auto-applied at POS. *(Phase 3)*

**Article Traceability & Business Configurations (FR92–FR97)**
FR92: Item can have traceable serial number (IMEI, chassis) per unit sold. Link item–serial–customer–date recorded. *(Phase 2b)*
FR93: Item can have configurable warranty duration. On sale, system generates warranty certificate (unique number, purchase date, expiry, customer). *(Phase 2b)*
FR94: Item can be marked requiresPrescription. On sale, system requires prescription number and prescriber name. *(Phase 2b)*
FR95: Product batch can have bestBeforeDate in addition to expiresAt. Freshness color code uses bestBeforeDate if set. *(Phase 2b)*
FR96: Item can be marked dynamicPricing. Price updated daily by owner. Price history maintained. POS always uses latest active price. *(Phase 2b)*
FR97: Item can be marked isUnique (consignment, antiques). Max stock = 1. Once sold, removed from active catalog. *(Phase 2b)*

**Returns & Reservations (FR98–FR99)**
FR98: Commercial can record a return at POS (linked to original transaction). Options: cash refund, customer credit, item exchange. Stock auto-reintegrated (RETURN). Tenant-configurable return policy. *(Phase 2a)*
FR99: Commercial can create reservation with partial deposit (configurable minimum %). Reservation creates pending transaction. Balance visible on customer profile. Owner can cancel → deposit becomes credit or is refunded. *(Phase 2b)*

**Pricing Plans & Billing (FR100–FR103)**
FR100: Superadmin can assign pricing plan per tenant (free, standard, premium, enterprise) via PlanDefinition. Plan change auto-updates active modules and maxUsers. *(Phase 2a)*
FR101: Superadmin can record installation and training fees per tenant. Billing status: trial/active/overdue/suspended. Auto-suspension configurable. *(Phase 2a)*
FR102: Tenant owner can view current plan, included modules, billing status, payment history from backoffice Settings. Can request plan upgrade (manual validation by superadmin in Phase 2a). *(Phase 2a)*
FR103: System supports online subscription payment (plan selection, Mobile Money/card, auto-provisioning on confirmation). *(Phase 3)*

**Business Type Configuration (FR104–FR106)**
FR104: Superadmin can assign business type per tenant. BusinessTypeDefinition configurable without deployment (code, name, product default flags, visible sections, suggested categories). 14 types seeded. *(Phase 2a)*
FR105: Product creation/edit form adapts to tenant businessType. Relevant fields prioritized and pre-filled. Non-relevant fields hidden with "Show more options" toggle. Per-product override always possible. *(Phase 2a)*
FR106: On tenant creation with businessType, system pre-creates suggested categories. Owner can rename, delete, or add freely. *(Phase 2a)*

**Client Orders (FR107–FR111)**
FR107: Commercial can create a client order (customer, products+quantities, delivery date, payment mode, notes). Lifecycle: draft→confirmed→preparing→ready→delivered→invoiced→paid. *(Phase 2a)*
FR108: Manager/owner validates order (draft→confirmed). Stock availability checked (alerts but doesn't block). Manager prepares (confirmed→preparing→ready) by checking each line. Stock reserved (RESERVED). *(Phase 2a)*
FR109: Commercial records delivery (ready→delivered). Actual delivered quantities entered. Delivery auto-generates linked sale transaction. Document type configurable by businessType (ticket/delivery note/invoice). *(Phase 2a)*
FR110: Owner views open orders in backoffice (filterable). KPIs: open orders count, pending revenue. Partial payments recorded on order. Balance visible on customer profile. *(Phase 2a)*
FR111: Each BusinessTypeDefinition includes roleLabels JSON mapping role codes to business-specific labels (e.g. "commercial" → "Delivery Driver"). Labels change display only; underlying permissions unchanged. *(Phase 2a)*

**AI Assistant (FR-AI-01 to FR-AI-05)**
FR-AI-01: Dedicated AI section — lateral panel on demand, global keyboard shortcut, optional full-screen. Never injected on module screens. *(Phase 1 architecture, Phase 2b activation)*
FR-AI-02: AI-invocable actions per module — each module exposes a catalog of actions AI can invoke via function calling. AI can only invoke declared actions, never direct DB access. *(Phase 2b)*
FR-AI-03: Excel/CSV AI-guided import — catalog items, customer lists, transaction histories. Column mapping driven by AI. *(Phase 2b)*
FR-AI-04: Natural language configuration — user configures business parameters via AI chat. AI translates to validated JSON mutations applied server-side. *(Phase 2b)*
FR-AI-05: Universal Config Wizard — guided onboarding for any new organization type. Conversational dialog to generate initial tenant configuration. Selects and adapts appropriate sectoral template. *(Phase 3)*

**Template Builder (FR-TEMPLATE-01 to FR-TEMPLATE-02)**
FR-TEMPLATE-01: AI-driven Template Builder — tool for integrators to create and publish sectoral templates via JSON/YAML configuration. AI suggests modules, workflows, and default parameters. No Flutter screen generation — pure configuration. *(Phase 3)*
FR-TEMPLATE-02: Natural language module configuration — integrator describes a need in natural language, AI generates module configuration (fields, rules, workflows). Output: JSON/YAML validated against Scalario schema before publishing. *(Phase 3)*

**Multi-POS Management (FR-MULTISTORE-01)**
FR-MULTISTORE-01: Centralized owner dashboard to supervise N POS locations of same tenant. Three stock models: A (central shared), B (independent per POS), C (mix). Inter-site transfers with traceability, consolidated sales reports, stock-out alerts per site. *(Phase 2b)*

**Multi-Client Professional Dashboard (FR-MULTISERVICE-01)**
FR-MULTISERVICE-01: Interface for service professionals managing multiple clients (accounting firms, consultants, franchisors). Delegated access to N client tenants from single professional account. Aggregated KPI view cross-tenant. Cross-tenant notifications. Xero model: client invites accountant → accountant sees all clients in dedicated dashboard. *(Phase 3)*

**User Session Management (FR-SESSION-01)**
FR-SESSION-01: Active session dashboard per user (device, approximate location, connection time). Instant single-session revocation from admin backoffice (forced logout < 5s). Unusual login alerts (new unrecognized device, abnormal geolocation). Configurable session expiry per tenant (default: 8h). *(Phase 2b)*

**Integrator Model (FR-INTEGRATOR-01 to FR-INTEGRATOR-04)**
FR-INTEGRATOR-01: Floor price enforcement — system rejects integrator subscription if resale price is below Scalario-configured floor. *(Phase 2b)*
FR-INTEGRATOR-02: Ceiling price enforcement — system rejects integrator subscription if resale price is above configured ceiling. *(Phase 2b)*
FR-INTEGRATOR-03: Volume-degressive fee — wholesale fee auto-recalculated per billing cycle: standard (1–5 clients), -10% (6–20), -20% (21–50), contract (50+). *(Phase 2b)*
FR-INTEGRATOR-04: Recurring integrator commission — integrator earns margin (resale – wholesale) monthly while client is active and attached. Commission suspended on cancellation, migration to direct, or integrator suspension. 30-day grace period. *(Phase 2b)*

**Sectoral Core Modules — Phase 3+ (FR-DEVIS-01 to FR-APPOINTMENT-01)**
FR-DEVIS-01: Quote/Manufacturing module — quote with materials, labor, margin. Lifecycle: draft→submitted→accepted/rejected→converted to work_order. *(Phase 3+)*
FR-WORKORDER-01: Work Order module — manufacturing order with configurable kanban steps. Each step has status, assigned owner, estimated date. *(Phase 3+)*
FR-BOM-01: Bill of Materials module — materials required per manufactured product (quantity, unit, catalog item). On work_order validation, stock auto-consumed via Inventory module. *(Phase 3+)*
FR-ATELIERPLANNING-01: Workshop Planning module — calendar view of work orders by workshop/operator. Queue management, configurable daily capacity, promised vs. actual delivery dates. *(Phase 3+)*
FR-TABLE-01: Table Management module — configurable floor plan (tables, zones, capacity). Table → active order assignment. Real-time status: free/occupied/reserved/cleaning. Table merge/split. *(Phase 3+)*
FR-KDS-01: Kitchen Display System — real-time preparation tickets from POS to kitchen. Statuses: received/in-progress/ready. Floor notification on validation. View by station. *(Phase 3+)*
FR-APPOINTMENT-01: Appointment module — slot booking by service and operator. Operator agenda view (day/week). Automatic customer reminders (push/SMS). Cancellation and rescheduling. Linked to catalog (service) and contacts (customer). *(Phase 3+)*

**Dynamic RBAC (FR-RBAC-01)**
FR-RBAC-01: Dynamic RBAC per tenant — roles are data stored in DB per tenant, not global enums. Each tenant defines role names (free text) and permission sets per module. Template sectoral roles are the starting point. Guards check permission codes (catalog.edit, session.open) not role names. Architecture H1 — API Phase 2b — AI RBAC Phase 2c.

**Super Admin (FR-SUPERADMIN-01 to FR-SUPERADMIN-06)**
FR-SUPERADMIN-01: Tenant creation via Super Admin form — plan selection, active modules, initial sectoral template, attached integrator (optional). Immediate provisioning. *(H1)*
FR-SUPERADMIN-02: Tenant suspension/reactivation with traced reason. Suspension expires active client sessions in < 5s. *(H1)*
FR-SUPERADMIN-03: Billing dashboard — active subscriptions, confirmed vs. pending payments, payment delay alerts. Auto-suspension after configurable days. *(Phase 2b)*
FR-SUPERADMIN-04: Integrator onboarding — create integrator account, configure initial fee tier, activate wholesale rights. *(Phase 2b)*
FR-SUPERADMIN-05: Feature flags per tenant — activate/deactivate a module or experimental feature on a specific tenant without deployment. Stored in tenant_features. *(Phase 2b)*
FR-SUPERADMIN-06: Template marketplace review — submission queue from integrators, validation interface (approve/reject + comment), versioning of approved templates. *(Phase 3)*

---

### Non-Functional Requirements

**Performance**
NFR1: Product grid render < 500ms for 2,000 items
NFR2: Transaction recording < 200ms local write
NFR3: Full-day sync < 30s for 150+ transactions
NFR4: Cold start < 3s to usable state
NFR5: Session closing report < 2s generation
NFR6: RAM footprint < 150MB stable state
NFR7: Local database size < 500MB for 90 days

**Security**
NFR8: Tenant isolation — zero inter-tenant data leak; applicative tenant_id + Supabase RLS defense-in-depth
NFR9: Authentication — JWT with configurable session timeout
NFR10: Local encryption — local database encrypted; device loss/theft protection
NFR11: Transport encryption — TLS 1.2+ for all server communications
NFR12: Price modification audit — every price change traced: actor, timestamp, before/after
NFR13: Financial data integrity — all financial mutations are atomic and logged

**Reliability & Availability**
NFR14: Offline autonomy — 8h+ continuous operation without connectivity
NFR15: Crash recovery — zero data loss on unexpected termination (validated by crash-recovery test)
NFR16: Sync resilience — automatic retry on sync failure (5s, 30s, 2min). Zero manual intervention for recoverable cases.
NFR17: Server uptime — 99% (self-hosted Supabase, solo admin — realistic target)
NFR18: Data durability — zero transaction loss, ever

**Scalability**
NFR19: Tenant capacity — 30+ concurrent tenants (12-month objective)
NFR20: Users per tenant — Retail: 10 concurrent (Standard), 20 (Premium multi-site). Enterprise: 50 concurrent (Pro).
NFR21: Transaction volume — Retail: 500 sales/day per tenant. Enterprise: 2,000 events/day per tenant.
NFR22: Catalog size — Retail: 5,000 items per tenant. Enterprise: 10,000 records per tenant.
NFR23: Horizontal growth — adding tenants or departments requires no code changes

**Network & Bandwidth**
NFR24: Sync compression — delta payloads compressed only
NFR25: Minimum bandwidth — sync functional on 2G (50 kbps)
NFR26: No heavy asset sync — images and files excluded from sync; data only
NFR27: Initial provisioning — catalog + full config < 5MB

**Usability**
NFR28: Cashier onboarding — autonomous after < 1h training
NFR29: Error handling — clear, actionable messages in user's language; zero technical jargon
NFR30: Offline transparency — user does not perceive connectivity state during normal operations

**Internationalization**
NFR31: Full i18n — zero hardcoded French strings in Flutter or NestJS code. All UI strings via i18n system. Native multi-currency support (FCFA default, extensible).

**Pluggable Compliance**
NFR32: Pluggable compliance framework — OHADA, CNSS, CARFO, local fiscal regimes implemented as country plugins, not core logic. Each tenant activates plugin for their jurisdiction. Adding new jurisdiction requires no core modification.

**Payment Adapters**
NFR33: Payment adapter pattern — Wave, Orange Money, Moov Money, and future payment methods implemented as interchangeable adapters. Core contains no direct payment provider integration.

**Universal Configuration**
NFR34: Configurable units — measurement units, currencies, date/time formats configurable per tenant; no non-overridable defaults.

**Versioned API**
NFR35: Versioned REST API — all API routes under /api/v1/; semantic versioning; 12-month backward compatibility guarantee before deprecation.

**Mobile Security**
NFR36: Flutter certificate pinning — Flutter app implements certificate pinning for all communications to Scalario backend. Certificate validated client-side on every HTTPS request.

**Rate Limiting**
NFR37: Rate limiting — applied on all public and authenticated API routes. Limits per tenant, per IP, and per endpoint. HTTP 429 responses with Retry-After header.

**Subscription Enforcement**
NFR38: Server-side only subscription enforcement — subscription-level restrictions (features, user limits, active modules) enforced exclusively server-side via Kernel. Zero enforcement logic in Flutter client.

**Anomaly Detection (H2)**
NFR39: Financial anomaly detection — H2 — automatic monitoring of abnormal transaction patterns (unusual volumes, out-of-range price modifications, atypical discounts). Alerts < 60s after detection to tenant owner. Configurable thresholds per tenant.

**Scalable Architecture**
NFR40: Microservices trajectory — H1: modular NestJS monolith. H2: dedicated Python/FastAPI service for AI features. H3: extract to independent microservices on proven production bottlenecks only.

**Infrastructure**
NFR-INFRA-01: Backend deploy < 5 min end-to-end (git push → live). *(H1)*
NFR-INFRA-02: Zero data loss on deploy (additive migrations only on prod without maintenance window). *(H1)*
NFR-INFRA-03: Backend rollback < 2 min in case of post-deploy incident. *(H1)*
NFR-INFRA-04: Automatic daily prod backup with minimum 7-day retention. Restore test performed before each new active client. *(H1)*
NFR-INFRA-05: Isolated staging environment activated before opening integrator channel — no integrator tests on prod. *(H2)*

---

### Additional Requirements

**From Architecture v2.0:**
- Guard chain order enforced on all Level 2 module endpoints: `AuthGuard → TenantGuard → BillingGuard → ModuleGuard → RolesGuard`
- Outbox pattern mandatory for all Flutter mutations: widget → repository → Isar outbox → SyncEngine background isolate → API (never call API directly from widget or provider)
- Every Level 2 shared module must declare an `AiActionsManifest` (H1 — connects to AI microservice H2)
- PaymentAdapter interface H1: no code may call a payment provider directly; must go through `PaymentAdapter` interface
- RBAC migration H1: add `tenant_id` to `kernel.roles`, change guard from role-name comparison to permission-code checking (`@Permissions('catalog.edit')`)
- i18n discipline effective 2026-03-31: no new hardcoded user-facing strings in Flutter; NestJS error responses return `{ key: 'error.domain.code', params: {} }` never raw English strings
- Python AI microservice: NestJS ↔ Python communication via HTTP REST localhost:8001; Flutter never calls AI service directly
- Wave integration: webhook primary + polling fallback
- Default AI model: Claude Sonnet 4.6 (speed/cost for real-time); Config Wizard: Claude Opus 4.6 (complex reasoning)
- Money stored as DECIMAL(10,2) in Prisma, serialized as string in JSON responses (never float)
- Delta sync param `?since=ISO8601` on every list endpoint supporting offline sync
- Brownfield project — no starter template; existing codebase to be progressively restructured

**From PRD v8.3 — Phase constraints:**
- H1 (Phase 1–2a): Demo mid-April (Blandine), foundation architectural patterns (interfaces, adapters, registries), no H2 features
- H2 (Phase 2b): AI Assistant activation, integrator channel, ambassador program, advanced inventory features
- H3 (Phase 3+): Scalario Connect B2B, Enterprise full, self-service onboarding, sectoral core modules

---

### FR Coverage Map

FR1: Epic 1 — Tenant creation & configuration
FR2: Epic 1 — User accounts & role assignment
FR3: Epic 1 — RBAC permissions enforcement
FR4: Epic 1 — JWT tenant-scoped authentication
FR5: Epic 1 — Tenant isolation enforcement
FR6: Epic 1 — Session timeout
FR7: Epic 8 — Module activation/deactivation per tenant
FR8: Epic 8 — Module dependency validation on activation
FR9: Epic 8 — Module isolation between tenants
FR10: Epic 8 — Retail single sector / Enterprise multi-department
FR11: Epic 2 — Item creation, edit, deactivation
FR12: Epic 2 — Item type discriminator (physical/bookable/service)
FR13: Epic 2 — Sectoral item field extension via UI-Driven Engine
FR14: Epic 2 — Category management
FR15: Epic 2 — Offline catalog availability
FR16: Epic 3 — Sale transaction creation
FR17: Epic 3 — Payment method (cash/mobile money/credit)
FR18: Epic 3 — Currency-specific total rounding
FR19: Epic 3 — Cash change recording
FR20: Epic 3 — Transaction lifecycle states
FR21: Epic 3 — Sectoral transaction extension
FR22: Epic 3 — Local-first write & sync queue
FR23: Epic 3 — POS session open with float declaration
FR24: Epic 3 — Session-scoped sales
FR25: Epic 3 — Session close with counted amount
FR26: Epic 3 — Theoretical/real discrepancy calculation
FR27: Epic 3 — Mandatory discrepancy explanation
FR28: Epic 3 — Manager session closing report access
FR29: Epic 4 — Supplier delivery reception
FR30: Epic 4 — Receipt variance tracing
FR31: Epic 4 — Store→shelf transfer creation
FR32: Epic 4 — Transfer receipt confirmation
FR33: Epic 4 — Transfer variance auto-assignment
FR34: Epic 4 — Loss declaration with reason
FR35: Epic 4 — Partial inventory with variance signal
FR36: Epic 4 — Offline inventory data maintenance
FR37: Epic 5 — Customer profile creation & management
FR38: Epic 5 — Transaction–customer association
FR39: Epic 5 — Credit sale recording & balance update
FR40: Epic 5 — Offline customer profiles & balances
FR41: Epic 6 — Online/offline CRUD parity
FR42: Epic 6 — Outbox mutation queuing
FR43: Epic 6 — Delta-only incremental sync
FR44: Epic 6 — Conflict resolution (LWW for data, manual for financial)
FR45: Epic 6 — Non-blocking connectivity status indicator
FR46: Epic 6 — Crash recovery with zero data loss
FR47: Epic 6 — Configurable local data retention (30–90 days)
FR48: Epic 7 — Daily consolidation report
FR49: Epic 7 — Owner dashboard (revenue, sales, losses, discrepancies, stock)
FR50: Epic 7 — Immutable audit trail
FR51: Epic 7 — Audit trail retention policy
FR52: Epic 8 — Tenants.referred_by & network_visible fields (Connect seed)
FR53: Epic 8 — Contacts.linked_tenant_id field (Connect seed)
FR54: Epic 8 — Catalog_items.supplier_reference field (Connect seed)
FR55: Epic 8 — Transaction type transfer_inter_tenant (Connect seed)
FR56: Epic 8 — Multi-schema data migration without loss
FR57: Epic 8 — Prisma multi-schema integrity (kernel/shared/retail)
FR58: Epic 8 — Module-agnostic sync engine with per-module adapters
FR59: Epic 8 — Tenants.org_mode & parent_tenant_id fields (Enterprise seed)
FR60: Epic 8 — Users.department_ids field (Enterprise seed)
FR61: Epic 8 — TenantModule.department_id field (Enterprise seed)
FR62: Epic 8 — Inter-department event bus (Enterprise seed)
FR63: Epic 15 — Employee record management
FR64: Epic 15 — Net salary calculation via payroll plugin
FR65: Epic 15 — Absence recording & payroll impact
FR66: Epic 15 — Bulk payslip generation (immutable on validation)
FR67: Epic 15 — Social declaration file export (CNSS/IPRES/CNPS)
FR68: Epic 15 — Payslip validation → accounting expense entry event
FR69: Epic 15 — Pre-loaded chart of accounts (OHADA plugin)
FR70: Epic 15 — Manual journal entries; auto-generated entries editable
FR71: Epic 15 — Bank reconciliation (CSV/PDF import, auto-matching)
FR72: Epic 15 — Month close; balance sheet & income statement export
FR73: Epic 15 — CSV import for employees, accounts, balances, equipment
FR74: Epic 15 — Retail→Enterprise migration without data loss
FR75: Epic 6 — Sync failure lifecycle (outbox→retry→FAILED→manual resolution)
FR76: Epic 2 — Per-item unitType configuration (unit/weight/volume/length)
FR77: Epic 3 — Float-quantity POS input for weight/volume items
FR78: Epic 2 — Sale unit label, unit price, conversion factor to stock unit
FR79: Epic 4 — Purchase order creation & lifecycle management
FR80: Epic 4 — Delivery reception linked to purchase order + variance tracing
FR81: Epic 4 — Per-item low stock threshold definition
FR82: Epic 4 — Automatic low-stock notification after stock movements
FR83: Epic 11 — Repackaging rules (source→target, conversion factor) *(2b)*
FR84: Epic 11 — Freshness window & natural loss tolerance per item *(2b)*
FR85: Epic 11 — Freshness color indicator (Green/Orange/Red) in POS & stock *(2b)*
FR86: Epic 7 — Automatic daily summary to owner (WhatsApp/push)
FR87: Epic 4 — Loss location selection from configurable list
FR88: Epic 4 — Internal replenishment request circuit
FR89: Epic 11 — Item variants with tenant-configured attributes *(2b)*
FR90: Epic 11 — Multi-level pricing (retail/wholesale/loyalty) *(2b)*
FR91: Epic 14 — Promotion rules (% discount, quantity offer, crossed-out price) *(Phase 3)*
FR92: Epic 11 — Serial number traceability per unit sold *(2b)*
FR93: Epic 11 — Warranty certificate generation on sale *(2b)*
FR94: Epic 11 — Prescription requirement enforcement per item *(2b)*
FR95: Epic 11 — ProductBatch bestBeforeDate for freshness code *(2b)*
FR96: Epic 11 — Dynamic pricing with price history *(2b)*
FR97: Epic 11 — Unique item flag (consignment/antiques) *(2b)*
FR98: Epic 9 — POS return with refund/credit/exchange options *(2a)*
FR99: Epic 9 — Reservation with partial deposit *(2b)*
FR100: Epic 10 — Pricing plan assignment per tenant (PlanDefinition) *(2a)*
FR101: Epic 10 — Installation fees & billing status management *(2a)*
FR102: Epic 10 — Tenant owner plan view & upgrade request *(2a)*
FR103: Epic 10 — Online subscription payment & auto-provisioning *(Phase 3)*
FR104: Epic 2 — BusinessTypeDefinition (flags, sections, categories) *(2a)*
FR105: Epic 2 — Adaptive product form per businessType *(2a)*
FR106: Epic 2 — Suggested category pre-creation on tenant creation *(2a)*
FR107: Epic 9 — Client order creation (customer, products, delivery date) *(2a)*
FR108: Epic 9 — Order validation & stock reservation *(2a)*
FR109: Epic 9 — Delivery recording with actual quantities & linked transaction *(2a)*
FR110: Epic 9 — Open orders dashboard + partial payments tracking *(2a)*
FR111: Epic 9 — BusinessType role labels mapping *(2a)*
FR-AI-01: Epic 12 — Dedicated AI panel (architecture H1, activation 2b)
FR-AI-02: Epic 12 — AI-invocable module actions via function calling *(2b)*
FR-AI-03: Epic 12 — AI-guided Excel/CSV import *(2b)*
FR-AI-04: Epic 12 — Natural language business configuration *(2b)*
FR-AI-05: Epic 17 — Universal Config Wizard *(Phase 3)*
FR-TEMPLATE-01: Epic 17 — AI-driven Template Builder for integrators *(Phase 3)*
FR-TEMPLATE-02: Epic 17 — Natural language module configuration *(Phase 3)*
FR-MULTISTORE-01: Epic 11 — Multi-POS centralized dashboard & stock models *(2b)*
FR-MULTISERVICE-01: Epic 17 — Multi-client professional dashboard *(Phase 3)*
FR-SESSION-01: Epic 13 — Active session management & revocation *(2b)*
FR-INTEGRATOR-01: Epic 13 — Floor price enforcement *(2b)*
FR-INTEGRATOR-02: Epic 13 — Ceiling price enforcement *(2b)*
FR-INTEGRATOR-03: Epic 13 — Volume-degressive wholesale fee *(2b)*
FR-INTEGRATOR-04: Epic 13 — Recurring integrator commission *(2b)*
FR-DEVIS-01: Epic 17 — Quote/Manufacturing module *(Phase 3+)*
FR-WORKORDER-01: Epic 17 — Work Order module *(Phase 3+)*
FR-BOM-01: Epic 17 — Bill of Materials module *(Phase 3+)*
FR-ATELIERPLANNING-01: Epic 17 — Workshop Planning module *(Phase 3+)*
FR-TABLE-01: Epic 17 — Table Management module *(Phase 3+)*
FR-KDS-01: Epic 17 — Kitchen Display System *(Phase 3+)*
FR-APPOINTMENT-01: Epic 17 — Appointment module *(Phase 3+)*
FR-RBAC-01: Epic 1 — Dynamic RBAC (H1 schema + guard migration; API 2b; AI 2c)
FR-SUPERADMIN-01: Epic 1 — Tenant creation via Super Admin *(H1)*
FR-SUPERADMIN-02: Epic 1 — Tenant suspension/reactivation *(H1)*
FR-SUPERADMIN-03: Epic 10 — Billing dashboard & auto-suspension *(2b)*
FR-SUPERADMIN-04: Epic 13 — Integrator onboarding *(2b)*
FR-SUPERADMIN-05: Epic 13 — Feature flags per tenant *(2b)*
FR-SUPERADMIN-06: Epic 17 — Template marketplace review *(Phase 3)*

---

## Epic List

### Epic 1: Secure Multi-Tenant Access & RBAC Foundation
Users can sign in securely, access only their tenant's data, and operate within properly scoped role-based permissions. Carlos can provision and suspend tenants instantly from Super Admin.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR-RBAC-01, FR-SUPERADMIN-01, FR-SUPERADMIN-02
**Horizon:** H1

### Epic 2: Product Catalog & Business Configuration
Owner can build a complete product catalog with units of measure, categories, and business-type-appropriate defaults pre-configured — no irrelevant fields cluttering the interface.
**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR76, FR77 (POS part → Epic 3), FR78, FR104, FR105, FR106
**Horizon:** H1 (FR104–FR106: Phase 2a)

### Epic 3: Point-of-Sale Operations
Commercial can open a session, sell products with any payment method, and close the session with a complete Z-report — including weight/volume-based items.
**FRs covered:** FR16, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR24, FR25, FR26, FR27, FR28, FR77 (POS float input)
**Horizon:** H1

### Epic 4: Stock & Inventory Management
Manager can fully control stock operations: receive deliveries (with or without purchase orders), make transfers, declare losses with location, perform inventories, define stock alerts, and process replenishment requests.
**FRs covered:** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36, FR79, FR80, FR81, FR82, FR87, FR88
**Horizon:** H1 (FR79–FR80: Phase 2a)

### Epic 5: Customer Management & Credit Sales
Commercial can manage customer profiles, sell on credit, and track customer balances — fully available offline.
**FRs covered:** FR37, FR38, FR39, FR40
**Horizon:** H1

### Epic 6: Offline-First Sync Engine & Data Reliability
The entire business runs uninterrupted during network outages. All operations (sales, stock, reports) continue offline, sync automatically on reconnection, and no data is ever lost — even on power cut or crash.
**FRs covered:** FR41, FR42, FR43, FR44, FR45, FR46, FR47, FR75
**NFRs addressed:** NFR14, NFR15, NFR16, NFR17, NFR18, NFR24, NFR25, NFR26, NFR27
**Horizon:** H1

### Epic 7: Operations Reporting & Daily Intelligence
Owner and manager have complete visibility: daily consolidated reports, live dashboard KPIs, immutable audit trail, and an automatic end-of-day summary pushed to the owner every evening.
**FRs covered:** FR48, FR49, FR50, FR51, FR86
**Horizon:** H1

### Epic 8: Module Registry & Platform Architecture Foundations
The platform's architectural contracts are established: modular per-tenant activation, payment adapter pattern, AiActionsManifest registry, guard chain, i18n discipline, versioned API, infrastructure CI/CD pipeline. Every future epic builds on this foundation.
**FRs covered:** FR7, FR8, FR9, FR10, FR52, FR53, FR54, FR55, FR56, FR57, FR58, FR59, FR60, FR61, FR62
**NFRs addressed:** NFR31, NFR32, NFR33, NFR34, NFR35, NFR36, NFR37, NFR38, NFR40, NFR-INFRA-01–05
**Horizon:** H1

### Epic 9: Client Orders & Delivery Workflow
Commercial can manage the full client order lifecycle — create, validate stock, prepare, deliver, invoice, and collect partial payments — with returns and reservations fully handled.
**FRs covered:** FR98, FR99, FR107, FR108, FR109, FR110, FR111
**Horizon:** Phase 2a (FR99: Phase 2b)

### Epic 10: Billing Plans & Super Admin Backoffice
Carlos can manage all tenant subscriptions, billing status, business type assignments, and feature flags from a Super Admin interface — no code deployments required.
**FRs covered:** FR100, FR101, FR102, FR103, FR-SUPERADMIN-03, FR-SUPERADMIN-04 (partial), FR-SUPERADMIN-05
**Horizon:** Phase 2a/2b (FR103: Phase 3)

### Epic 11: Advanced Product Features & Multi-Site Management
Owner can unlock advanced product capabilities — variants, multi-pricing, freshness tracking, serial numbers, warranty certificates, dynamic pricing, unique items, and manage inventory across multiple POS locations.
**FRs covered:** FR83, FR84, FR85, FR89, FR90, FR92, FR93, FR94, FR95, FR96, FR97, FR-MULTISTORE-01
**Horizon:** Phase 2b

### Epic 12: AI Assistant Layer
Users can interact with their business data via a dedicated AI panel — ask questions, import Excel/CSV catalogs, configure business parameters in natural language, and trigger module actions via function calling.
**FRs covered:** FR-AI-01, FR-AI-02, FR-AI-03, FR-AI-04
**Horizon:** Phase 2b (architecture pattern: H1)

### Epic 13: Integrator Channel & Platform Governance
Integrators can onboard, manage client portfolios, earn degressive commissions, and operate within Scalario's pricing guardrails. Tenant admins get full session visibility and security controls.
**FRs covered:** FR-INTEGRATOR-01, FR-INTEGRATOR-02, FR-INTEGRATOR-03, FR-INTEGRATOR-04, FR-SUPERADMIN-04 (wholesale), FR-SUPERADMIN-05, FR-SESSION-01
**Horizon:** Phase 2b

### Epic 14: Promotions & Revenue Growth Tools
Owner can create and run promotions that auto-apply at POS: percentage discounts on items or categories, quantity offers (buy X get Y), and temporary crossed-out prices with start/end dates.
**FRs covered:** FR91
**Horizon:** Phase 3

### Epic 15: Enterprise Operations (HR, Payroll & Accounting)
A PME can manage its full back-office: employee records, payroll with local compliance plugins (CNSS, IPRES, CNPS), OHADA accounting, bank reconciliation, and regulatory declarations — all from one platform.
**FRs covered:** FR63, FR64, FR65, FR66, FR67, FR68, FR69, FR70, FR71, FR72, FR73, FR74
**Horizon:** Phase 3

### Epic 16: Scalario Connect B2B Network
Any tenant can transact directly with suppliers or partner businesses on the Scalario network — purchase orders, deliveries, and payments flow between tenants without leaving the platform.
**FRs covered:** FR52–FR55 (DB seeds planted in Epic 8), full Connect feature layer
**Horizon:** Phase 3

### Epic 17: AI Config Wizard, Template Builder & Sectoral Core Modules
Integrators can deploy any business sector without writing code. Any organization type — artisan workshop, restaurant, medical practice, salon, hotel — can be fully onboarded via AI-generated configuration and sectoral templates.
**FRs covered:** FR-AI-05, FR-TEMPLATE-01, FR-TEMPLATE-02, FR-MULTISERVICE-01, FR-RBAC-01 (API 2b, AI 2c), FR-SUPERADMIN-06, FR-DEVIS-01, FR-WORKORDER-01, FR-BOM-01, FR-ATELIERPLANNING-01, FR-TABLE-01, FR-KDS-01, FR-APPOINTMENT-01
**Horizon:** Phase 3+

---

## Epic 1: Secure Multi-Tenant Access & RBAC Foundation

Users can sign in securely, access only their tenant's data, and operate within properly scoped role-based permissions. Carlos can provision and suspend tenants instantly from Super Admin.

### Story 1.1: Super Admin Provisions a New Tenant

As a Super Admin (Carlos),
I want to create and configure a new tenant from the admin backoffice,
So that a new client is immediately live on the platform without any manual database operations.

**Acceptance Criteria:**

**Given** I am authenticated as Super Admin
**When** I submit the tenant creation form with: name, currency (XOF default), timezone, fiscal jurisdiction, business type, org_mode (standalone default), pricing plan, initial modules, sector template, and optional integrator
**Then** the tenant is provisioned immediately with status `active`
**And** the tenant's suggested product categories are pre-created based on the selected business type
**And** the assigned plan's module list is activated for the tenant
**And** an audit log entry records: creator, timestamp, all configuration values

**Given** a tenant is created with plan "free"
**When** an API request is made by that tenant exceeding the free plan's maxUsers limit
**Then** the server returns HTTP 402 with key `error.billing.limit_exceeded`

### Story 1.2: Tenant-Scoped User Authentication

As a user,
I want to authenticate and receive a JWT token scoped to my tenant,
So that all my operations are automatically isolated to my organization's data without me having to specify it.

**Acceptance Criteria:**

**Given** a user has valid credentials for tenant T
**When** they authenticate via `POST /api/v1/auth/login`
**Then** they receive a JWT containing `tenantId`, `userId`, `roles`, and expiry
**And** every subsequent API call with that JWT only accesses tenant T's data

**Given** a valid JWT for tenant A
**When** a request attempts to access any resource belonging to tenant B
**Then** the server returns HTTP 403
**And** no tenant B data is exposed in the response body or error message

**Given** a JWT whose tenant has been suspended
**When** any API call is made with that token
**Then** the server returns HTTP 401 with key `error.auth.tenant_inactive`

### Story 1.3: Owner Manages User Accounts & Role Assignment

As a tenant owner,
I want to create user accounts and assign them roles with business-appropriate labels for my trade,
So that my team members can access the system with the right permissions from day one.

**Acceptance Criteria:**

**Given** I am authenticated as owner of tenant T
**When** I create a new user with email, name, and a role from the available roles for my tenant
**Then** the user receives an invitation with setup credentials
**And** the user's role label in the UI matches the BusinessTypeDefinition roleLabels for my business type (e.g. "Livreur" instead of "commercial" for a distribution business)

**Given** I attempt to create a user that would exceed the plan's `maxUsers` limit
**When** I submit the form
**Then** the system rejects the creation with key `error.billing.max_users_reached`

**Given** I am in Enterprise mode (org_mode: integrated)
**When** I create a user
**Then** I can assign them to one or more departments
**And** their access is scoped to those departments' activated modules

### Story 1.4: RBAC Permission Enforcement at API & UI Level

As a tenant user,
I want the system to consistently enforce my role's permissions across every screen and API endpoint,
So that I can only perform actions my role is authorized for — no more, no less.

**Acceptance Criteria:**

**Given** a user with role `commercial` (has `session.open`, `catalog.read`; does NOT have `catalog.edit`)
**When** they call `POST /api/v1/catalog/items` (requires `catalog.edit`)
**Then** the server returns HTTP 403 with key `error.rbac.permission_denied`
**And** the Flutter UI does not render the "Add Product" button for this user

**Given** the guard chain: `AuthGuard → TenantGuard → BillingGuard → ModuleGuard → RolesGuard`
**When** a request reaches a protected endpoint
**Then** each guard executes in order; the first failing guard blocks the request and returns its specific error key
**And** no guard after the failing one executes

**Given** a user's role permissions are updated by the owner
**When** the user makes their next API request (after JWT refresh)
**Then** the updated permissions are enforced immediately with zero regression on previously allowed actions

### Story 1.5: RBAC Foundation Migration — Tenant-Scoped Roles & Permission Codes

As a platform developer,
I want roles stored per-tenant in the database with permission-code-based guards,
So that sector templates can define distinct role structures per business type without code deployments.

**Acceptance Criteria:**

**Given** the current `kernel.roles` table has no `tenant_id`
**When** the H1 migration runs
**Then** `kernel.roles` gains `tenant_id UUID FK nullable` and the unique constraint becomes `@@unique([name, tenantId])`
**And** existing global template roles retain `tenantId = null`
**And** no existing role data or user access is disrupted (zero regression)

**Given** the guard currently checks `@Roles('owner')` via string name comparison
**When** the guard is migrated to `@Permissions('catalog.edit')` using the existing `hasPermission()` in PermissionService
**Then** all existing permission sets continue to resolve correctly
**And** no new hardcoded role name strings are introduced anywhere in the backend

**Given** a sector template is applied to a tenant (e.g. restaurant template with roles "Gérant" / "Serveur")
**When** a different template is applied to another tenant (e.g. pharmacy with "Pharmacien" / "Préparateur")
**Then** each tenant has isolated role records with its own `tenantId`
**And** no cross-tenant role pollution occurs in any query

### Story 1.6: Session Timeout Configuration

As a tenant owner,
I want to configure how long user sessions stay active,
So that unattended devices automatically lock out after inactivity without disrupting active work.

**Acceptance Criteria:**

**Given** a tenant has configured session timeout of N hours (default: 8h)
**When** a user's JWT age exceeds N hours without activity
**Then** the next API call returns HTTP 401 with key `error.auth.session_expired`
**And** the Flutter app redirects to the login screen without data loss

**Given** a user is actively making API calls
**When** each call occurs within the timeout window
**Then** the session sliding window resets
**And** no interruption occurs during normal operation

### Story 1.7: Super Admin Suspends and Reactivates a Tenant

As a Super Admin (Carlos),
I want to suspend a non-paying or misbehaving tenant with a traced reason,
So that their team is immediately locked out while their data is fully preserved for reactivation.

**Acceptance Criteria:**

**Given** a tenant is `active` with users currently connected
**When** I suspend it from Super Admin with a mandatory reason
**Then** the tenant status becomes `suspended` within < 1s
**And** all active sessions for that tenant are invalidated within < 5s (Supabase Realtime forced logout)
**And** suspension reason, actor, and timestamp are written to the audit log

**Given** a tenant is `suspended`
**When** any user from that tenant attempts to authenticate or make an API call
**Then** the server returns HTTP 403 with key `error.tenant.suspended`
**And** the Flutter app displays the message resolved from that i18n key

**Given** a suspended tenant
**When** I reactivate it from Super Admin with a reason
**Then** the tenant status returns to `active` immediately
**And** users can log in again without any additional steps
**And** reactivation actor, reason, and timestamp are recorded in the audit log

---

## Epic 2: Product Catalog & Business Configuration

Owner can build a complete product catalog with units of measure, categories, and business-type-appropriate defaults. No irrelevant fields cluttering the interface.

### Story 2.1: Create, Edit and Deactivate Catalog Items

As an owner,
I want to create, edit, and deactivate catalog items with all essential attributes,
So that my product list accurately reflects what my business sells.

**Acceptance Criteria:**

**Given** I am authenticated as owner
**When** I create an item with: name, price (DECIMAL, never float), category, barcode (optional), and type discriminator (physical | bookable | service)
**Then** the item is saved with `tenantId` automatically set from my JWT
**And** the price is stored as `DECIMAL(10,2)` and serialized as string in all API responses

**Given** an item with `status: active`
**When** I deactivate it
**Then** it no longer appears in POS search results or catalog grids
**And** the item record is retained (soft delete) with its full history intact

**Given** I edit an existing item's price
**When** the change is saved
**Then** an audit entry is created with: actor, timestamp, old price, new price (NFR12)
**And** the POS reflects the new price on the next catalog sync

### Story 2.2: Product Category Management

As an owner,
I want to create and manage product categories,
So that my catalog is organized and easy to browse at the POS.

**Acceptance Criteria:**

**Given** I am authenticated as owner
**When** I create a category with a name
**Then** the category is available for item assignment and scoped to my tenant only

**Given** a category has items assigned to it
**When** I attempt to delete the category
**Then** the system prevents deletion and returns key `error.catalog.category_has_items`
**And** I am prompted to reassign items first

**Given** categories exist
**When** they are fetched via `GET /api/v1/catalog/categories`
**Then** the response supports `?since=ISO8601` delta sync for offline-first devices

### Story 2.3: Configure Item Unit Types for Weight & Volume Sales

As an owner,
I want to configure each item with its unit type, sale unit label, and optional stock conversion factor,
So that the POS correctly handles items sold by weight, volume, or length — not just by piece.

**Acceptance Criteria:**

**Given** I open an item's edit form
**When** I set `unitType` to `weight` and `nativeUnit` to `kg`
**Then** the POS displays a float-precision quantity input labeled "kg" for this item
**And** `unitType: unit` remains the default for unconfigured items

**Given** I define sale unit "sachet 500g" with price 500 FCFA and conversion factor 0.5 (= 0.5 kg per sachet)
**When** a commercial sells 3 sachets
**Then** the transaction records: quantity = 3, unit = "sachet 500g", total = 1500 FCFA
**And** stock is decremented by 1.5 kg (3 × 0.5)

**Given** an item with `unitType: weight` is sold
**When** the total is calculated
**Then** it is rounded according to the tenant's currency rule (XOF: nearest 5 FCFA)

### Story 2.4: Sectoral Catalog Extension via UI-Driven Engine

As a sectoral module,
I want to extend base catalog items with sector-specific fields,
So that each business type sees only the fields relevant to their operations without modifying the shared catalog schema.

**Acceptance Criteria:**

**Given** the retail sector module is active for a tenant
**When** an item is created
**Then** the item can include retail-specific fields (stockQuantity, reorderPoint, expiresAt) without altering the base CatalogItem schema

**Given** a non-retail sector template is active
**When** catalog items are fetched
**Then** only fields declared by the active sector module's extension are included
**And** no retail-specific fields appear for non-retail tenants

**Given** a tenant has no sector module active
**When** catalog items are accessed
**Then** items function correctly with base fields only (name, price, category, type, barcode)

### Story 2.5: Offline Catalog Availability

As a commercial,
I want the full product catalog available on my device without an internet connection,
So that I can search, browse, and sell even when the network is down.

**Acceptance Criteria:**

**Given** the device has completed at least one full catalog sync
**When** the device goes offline
**Then** all catalog items, categories, prices, and unit configurations remain fully accessible in Isar
**And** no "loading" or "unavailable" state appears in the POS grid

**Given** catalog items were updated server-side while the device was offline
**When** the device reconnects and sync runs
**Then** only changed items are transmitted via `?since=ISO8601` delta sync
**And** the local Isar catalog reflects all updates within the sync cycle

**Given** an item is deactivated server-side
**When** the delta sync runs on the device
**Then** the item is removed from the local Isar collection and disappears from POS immediately

### Story 2.6: Business Type Definition Configuration *(Phase 2a)*

As a Super Admin,
I want to configure BusinessTypeDefinitions without code deployment,
So that new business types can be added and existing ones updated as Scalario expands to new sectors.

**Acceptance Criteria:**

**Given** I am authenticated as Super Admin
**When** I create a BusinessTypeDefinition with: code (unique), name, default product flags (trackSerialNumbers, hasVariants, warrantyMonths, expiryDays, requiresPrescription, isUnique, dynamicPricing, unitType), visible form sections, suggested categories, roleLabels JSON, and documentType
**Then** the definition is immediately available for tenant assignment
**And** all 14 seeded business types (generaliste, epicerie, telephonie, textile, pharmacie, etc.) are present with correct defaults on first migration

**Given** a BusinessTypeDefinition default flag is updated
**When** the change is saved
**Then** the change applies to new tenants of that type only
**And** existing tenants' per-item overrides are not retroactively altered

### Story 2.7: Adaptive Product Form by Business Type *(Phase 2a)*

As a tenant owner,
I want the product creation form to show only the fields relevant to my business type by default,
So that I'm not overwhelmed by irrelevant options when adding items.

**Acceptance Criteria:**

**Given** a tenant with businessType "telephonie"
**When** I open the product creation form
**Then** `trackSerialNumbers` and `warrantyMonths` are visible and pre-filled with the type's defaults
**And** `expiryDays` and `requiresPrescription` are hidden behind a "Show more options" toggle

**Given** I toggle "Show more options" and enable `expiryDays` on a specific product
**When** the product is saved
**Then** that product uses `expiryDays` regardless of business type defaults
**And** the per-product override is retained independently of any future BusinessTypeDefinition changes

**Given** a product is created without any flag override
**When** the business type defaults are read
**Then** the product inherits those defaults at read time (not stored redundantly on the product record)

### Story 2.8: Suggested Category Auto-Creation on Tenant Setup *(Phase 2a)*

As an owner of a newly provisioned tenant,
I want my starting category list to match my business type out of the box,
So that I can begin adding products immediately without manually building my category structure.

**Acceptance Criteria:**

**Given** a tenant is created with businessType "telephonie"
**When** provisioning completes
**Then** the categories ["Smartphones", "Accessoires", "Cartes SIM", "Tablettes"] are created in the tenant's catalog
**And** these categories are fully owned by the tenant (rename, delete, or add freely)

**Given** a tenant is created with businessType "generaliste"
**When** provisioning completes
**Then** no suggested categories are pre-created (blank slate)

**Given** a tenant's suggested categories exist
**When** the owner deletes one
**Then** the deletion succeeds without restriction and no system behavior depends on its existence

---

## Epic 3: Point-of-Sale Operations

Commercial can open a session, sell products with any payment method, and close the session with a complete Z-report — including weight/volume-based items.

### Story 3.1: Open a POS Session with Cash Float Declaration

As a commercial,
I want to open a POS session by declaring my starting cash float,
So that all my sales during the shift are tracked within a single accountable session.

**Acceptance Criteria:**

**Given** I am authenticated as commercial and no session is currently open on my device
**When** I open a new session and declare the starting float amount (e.g. 10,000 FCFA)
**Then** a session is created with status `open`, `openedAt` timestamp, my `userId`, and the declared `openingFloat`
**And** all subsequent sales I create are automatically associated with this session via `sessionId`

**Given** a session is already open on my device
**When** I attempt to open a second session
**Then** the system prevents it with key `error.session.already_open`
**And** I must close the existing session before opening a new one

**Given** I open a session with float 0 FCFA
**When** the session is created
**Then** it is accepted (zero float is valid)

### Story 3.2: Create a Sale Transaction with Payment

As a commercial,
I want to select items, quantities, and a payment method to complete a sale,
So that the customer's purchase is recorded instantly and the correct change is calculated.

**Acceptance Criteria:**

**Given** I have an active open session
**When** I add items to the cart and select payment method "cash" with amount tendered 10,000 FCFA for a 9,750 FCFA total
**Then** the transaction is created with: `tenantId`, `sessionId`, line items (itemId, qty, unitPrice, subtotal), total = 9,750 FCFA, paymentMethod = cash, changeDue = 250 FCFA
**And** the transaction is written to Isar immediately (local-first) and queued in the outbox for server sync
**And** total is stored as `DECIMAL(10,2)` and rounded to nearest 5 FCFA (XOF rule)

**Given** a sale with payment method "mobile money"
**When** the transaction is created
**Then** `changeDue` is 0 and the payment method is recorded via the `PaymentAdapter` interface (never a direct provider call)

**Given** a sale with payment method "credit" linked to a customer contact
**When** the transaction is created
**Then** the customer's outstanding balance is incremented by the transaction total
**And** the transaction `lifecycle` is set to `accumulating`

**Given** a transaction is synced to the server
**When** the server processes it
**Then** `tenantId` is validated from JWT (never from request body)
**And** the response includes the server-assigned `receiptNumber` (sequential, tenant-scoped)

### Story 3.3: Float-Quantity Sales for Weight & Volume Items

As a commercial,
I want to enter a decimal quantity for items sold by weight or volume,
So that items like loose produce, liquids, or fabric are priced accurately at the POS.

**Acceptance Criteria:**

**Given** an item configured with `unitType: weight` and `nativeUnit: kg`
**When** I add it to the cart
**Then** the POS displays a numeric input accepting decimal values (e.g. 1.35) labeled "kg"
**And** the line total is auto-calculated as `unitPrice × quantity`, rounded per currency rule

**Given** an item with sale unit "sachet 500g" and conversion factor 0.5
**When** I enter quantity 4
**Then** the cart shows 4 × sachet 500g and the stock decrement queued in the outbox is 2 kg (4 × 0.5)

**Given** an item with `unitType: unit` (default)
**When** I add it to the cart
**Then** the quantity input accepts only whole numbers

### Story 3.4: Close POS Session with Z-Report

As a commercial,
I want to close my session by counting my cash and submitting a Z-report,
So that my shift is formally closed with a full reconciliation record.

**Acceptance Criteria:**

**Given** I have an active session with completed sales
**When** I initiate session close and enter my counted cash amount
**Then** the system calculates `discrepancy = countedAmount - (openingFloat + cashSalesTotal - changeGiven)`
**And** the Z-report is generated in < 2s showing: opening float, sales by payment method, expected cash, counted amount, discrepancy

**Given** the discrepancy is non-zero
**When** I attempt to submit the close
**Then** the system requires a mandatory text explanation before allowing submission

**Given** the discrepancy is 0 FCFA
**When** I submit the close
**Then** the session closes without requiring an explanation and status changes to `closed` with `closedAt` timestamp

**Given** a session is closed
**When** the closure syncs to the server
**Then** the Z-report and all sale lines are immutably recorded in the audit trail and the session cannot be reopened or modified

### Story 3.5: Manager Reviews Session Closing Reports

As a manager,
I want to consult the closing reports of all commercials at my location,
So that I can verify daily reconciliation and identify discrepancies across the team.

**Acceptance Criteria:**

**Given** I am authenticated as manager
**When** I access the session reports section
**Then** I see all closed sessions for my location, filterable by date range, commercial, and status
**And** each report shows: commercial name, opening float, total sales, discrepancy, explanation (if any)

**Given** a session with a non-zero discrepancy
**When** I view it
**Then** the discrepancy is highlighted and the commercial's explanation is clearly displayed

**Given** I am authenticated as commercial (not manager)
**When** I access session reports
**Then** I can only see my own sessions (RBAC: `session.read.own` vs `session.read.all`)

---

## Epic 4: Stock & Inventory Management

Manager can fully control stock operations — receive deliveries, make transfers, declare losses, perform inventories, set alerts, and process replenishment requests.

### Story 4.1: Receive Supplier Delivery

As a manager,
I want to record a supplier delivery by entering quantities received versus expected,
So that my stock is immediately updated and any reception variance is traced.

**Acceptance Criteria:**

**Given** I am authenticated as manager
**When** I create a delivery reception with supplier contact, items, expected vs. received quantities, and optional observation notes per item
**Then** a `InventoryMovement` of type `RECEIPT` is created per item with the actual received quantity
**And** stock levels are incremented by received quantities
**And** variances (received − expected) are stored on the reception record
**And** all data is written locally first and queued in the outbox

**Given** I add observation notes (e.g. "produits trop mûrs")
**When** the reception is saved
**Then** notes are attached to the inventory movement and visible in reception reports

**Given** the reception syncs to the server
**When** processed
**Then** `tenantId` is validated from JWT and the reception is added to the immutable audit trail

### Story 4.2: Create and Process Store→Shelf Transfers

As a manager,
I want to create stock transfers from the store to a shelf or section,
So that sales staff always have sufficient stock on the selling floor.

**Acceptance Criteria:**

**Given** I am authenticated as manager
**When** I create a transfer with: source (store), destination (shelf/section), items and declared quantities
**Then** a `StockTransfer` is created with status `pending` and stock reserved from the source location

**Given** a transfer is pending
**When** the receiving commercial confirms it and enters the actually received quantity
**Then** the transfer status changes to `completed`
**And** a variance record is created if actual ≠ declared (FR33), attributed to the transfer and visible in reports
**And** source stock is decremented by the actual received quantity only

### Story 4.3: Declare Stock Losses with Location Attribution

As a commercial,
I want to declare stock losses with a mandatory reason and location,
So that losses are traceable and attributable to the right area of the business.

**Acceptance Criteria:**

**Given** my tenant has configured loss locations (e.g. "Magasin", "Rayon")
**When** I declare a loss for an item
**Then** the location selector is mandatory and the form cannot be submitted without it
**And** a `InventoryMovement` of type `LOSS` is created with: item, quantity, reason, location, actor, timestamp

**Given** my tenant has no loss locations configured
**When** I declare a loss
**Then** the location field is optional

**Given** losses are recorded
**When** the manager views the loss report
**Then** losses are filterable and aggregatable by location and date range for responsibility attribution

### Story 4.4: Partial Inventory with Variance Signaling

As a manager,
I want to perform a partial inventory count for selected items or categories,
So that I can detect and correct stock discrepancies without a full store closure.

**Acceptance Criteria:**

**Given** I am authenticated as manager
**When** I enter counted quantities for each item in the partial inventory
**Then** the system calculates `variance = counted - systemStock` per item
**And** items with non-zero variance are flagged in the inventory report

**Given** I validate the counts
**When** the inventory is completed
**Then** stock is adjusted to match counted quantities
**And** each adjustment generates a `InventoryMovement` of type `ADJUSTMENT` with actor and timestamp

**Given** the device is offline during an inventory count (FR36)
**When** the count is completed offline
**Then** adjustments are queued in the outbox and synced on reconnection without data loss

### Story 4.5: Create and Manage Purchase Orders *(Phase 2a)*

As an owner or authorized manager,
I want to create purchase orders for suppliers with full lifecycle tracking,
So that expected deliveries are documented and receivable against a reference.

**Acceptance Criteria:**

**Given** I am authenticated as owner or manager with PO permissions
**When** I create a PO with: supplier contact, item lines (item, expected qty, unit), expected delivery date, optional notes
**Then** the PO is created with a unique identifier and status `draft`

**Given** a PO in `draft`
**When** I confirm it
**Then** status becomes `confirmed` and the PO is available to link to future receptions

**Given** POs exist
**When** I view the list
**Then** I can filter by status (draft / confirmed / partially_received / received / cancelled), supplier, and date range

**Given** I cancel a PO
**When** cancellation is submitted
**Then** status becomes `cancelled`, no stock adjustments are made, and the cancellation is recorded in the audit trail

### Story 4.6: Receive Delivery Linked to a Purchase Order *(Phase 2a)*

As a manager,
I want to link a supplier delivery to an existing purchase order,
So that received quantities are automatically compared to what was ordered.

**Acceptance Criteria:**

**Given** a confirmed PO exists
**When** I create a delivery reception and link it to the PO
**Then** the PO's expected quantities are pre-filled in the reception form

**Given** I enter actually received quantities
**When** I save the reception
**Then** variance per line (received − ordered) is calculated and stored
**And** PO status updates to `partially_received` if some lines are incomplete or `received` if all fulfilled

**Given** a reception without a linked PO
**When** I record it
**Then** the reception is valid and processed normally (PO linkage is optional)

### Story 4.7: Configure Low Stock Thresholds and Automatic Alerts

As an owner,
I want to set a low stock threshold per item and receive automatic alerts when stock drops below it,
So that I can reorder before running out without manually monitoring every item.

**Acceptance Criteria:**

**Given** I set `lowStockThreshold: 5` (kg) on item "Riz"
**When** a sale reduces stock from 6 kg to 4.5 kg
**Then** a push notification is sent to owner and manager: "Stock bas: Riz (4.5 kg restants)"
**And** "Riz" is flagged in the next daily summary
**And** the alert does not re-trigger until stock rises above 5 kg again and drops back below

**Given** an item with `lowStockThreshold: null`
**When** any stock movement occurs
**Then** no alert is triggered

### Story 4.8: Internal Replenishment Request Circuit

As a commercial,
I want to submit an internal replenishment request for a low-stock item,
So that the manager and owner can review and fulfill it without me leaving the floor.

**Acceptance Criteria:**

**Given** I am authenticated as commercial
**When** I create a replenishment request with: item, quantity, unit, urgency (Normal | Urgent)
**Then** the request is created and a push notification is sent to the next actor in the configured circuit
**And** status is `pending_manager` (or `pending_owner` if the intermediate step is disabled for this tenant)

**Given** the manager approves and optionally adjusts the quantity
**When** approval is submitted
**Then** the request advances to `pending_owner` and the owner is notified

**Given** the owner approves
**When** approval is confirmed
**Then** a `StockTransfer` store→shelf is automatically created for the approved quantity and follows the standard transfer confirmation flow

**Given** the owner rejects with a mandatory reason
**When** rejection is submitted
**Then** request status becomes `rejected` and the commercial is notified with the reason

---

## Epic 5: Customer Management & Credit Sales

Commercial can manage customer profiles, sell on credit, and track customer balances — fully available offline.

### Story 5.1: Create and Manage Customer Profiles

As a commercial,
I want to create and manage customer profiles with name, phone, and type,
So that I can identify customers at the POS and build a client relationship history.

**Acceptance Criteria:**

**Given** I am authenticated as commercial
**When** I create a customer with: name (required), phone (optional), type (individual | business | vip)
**Then** the profile is saved with `tenantId` from JWT and immediately available for transaction association

**Given** a customer profile exists
**When** I search by name or phone at the POS
**Then** results appear within 500ms even with 1,000+ contacts in the local Isar collection

**Given** I update a customer's phone number
**When** saved
**Then** the change is queued in the outbox and reflected on all devices after their next sync

### Story 5.2: Associate a Transaction with a Customer

As a commercial,
I want to link a sale to a customer profile,
So that the customer's purchase history is built and I can apply credit or customer-specific pricing.

**Acceptance Criteria:**

**Given** I have items in the cart
**When** I search for and select a customer before finalizing the sale
**Then** the transaction is saved with `contactId` referencing the customer

**Given** I complete a sale without selecting a customer
**When** the transaction is saved
**Then** `contactId` is null and the sale is valid (customer association is optional)

**Given** a customer is linked to transactions
**When** the manager views the customer's profile
**Then** all linked transactions are visible in chronological order

### Story 5.3: Record Credit Sales and Track Customer Balance

As a commercial,
I want to record a sale on credit against a customer's account,
So that outstanding balances are tracked and the owner always knows what is owed.

**Acceptance Criteria:**

**Given** I select payment method "credit" and associate a customer
**When** the transaction is finalized
**Then** `lifecycle` is set to `accumulating` and the customer's `outstandingBalance` is incremented by the total
**And** the balance update is written locally first and queued in the outbox

**Given** a customer has an existing balance of 15,000 FCFA
**When** a new credit sale of 5,000 FCFA is recorded
**Then** the customer's balance becomes 20,000 FCFA

**Given** a customer makes a full or partial repayment
**When** the payment is recorded
**Then** `outstandingBalance` is decremented accordingly and a payment record (actor, timestamp, amount) is appended to their history

**Given** the owner views the customer list
**When** sorted by outstanding balance
**Then** customers with the highest balances appear first
**And** total outstanding credit across all customers is shown as a dashboard KPI

### Story 5.4: Offline Customer Profiles and Balance Access

As a commercial,
I want full access to customer profiles and balances without connectivity,
So that I can identify customers and apply credit correctly during a network outage.

**Acceptance Criteria:**

**Given** customer data has been synced to the device
**When** the device goes offline
**Then** all customer records remain searchable and their balances are accurate as of the last sync

**Given** a credit sale is made offline
**When** written to Isar
**Then** the customer's local balance is updated immediately
**And** the outbox mutation syncs the balance update to the server on reconnection

**Given** a balance conflict arises (e.g. same customer updated on two offline devices)
**When** sync runs
**Then** financial balance conflicts are NOT auto-resolved via last-write-wins
**And** they enter the manual resolution queue (FR75) and the owner is notified

---

## Epic 6: Offline-First Sync Engine & Data Reliability

The entire business runs uninterrupted during network outages. All operations continue offline, sync automatically on reconnection, and no data is ever lost — even on power cut.

### Story 6.1: Local-First Writes via Outbox Mutation Queue

As a user performing any operation,
I want every mutation written locally to Isar first and queued for server sync,
So that the app is always responsive and no operation is lost waiting for network confirmation.

**Acceptance Criteria:**

**Given** I perform any create/update/delete operation (sale, transfer, loss, customer update)
**When** the operation executes
**Then** it is written to Isar immediately (< 200ms, NFR2)
**And** an `OutboxItem` is created with: `entityType`, `entityId`, `operation`, `payload`, `status: pending`, `createdAt`
**And** the UI reflects the result immediately without waiting for server confirmation

**Given** the device is online and the SyncEngine background isolate picks up an outbox item
**When** it POSTs to `/api/v1/{resource}`
**Then** on HTTP 200: the item is marked `synced` and local record updated with server response (e.g. server-assigned `receiptNumber`)
**And** on HTTP 4xx (permanent error): the item is marked `FAILED` and enters the failure management flow (FR75)

**Given** the SyncEngine runs as a background isolate
**When** the main Flutter thread is active
**Then** the sync runs without blocking or interrupting the UI thread

### Story 6.2: Incremental Delta Sync on Reconnection

As a user,
I want the app to sync only what changed since the last sync,
So that reconnection is fast even after hours of offline operation, even on 2G.

**Acceptance Criteria:**

**Given** the device reconnects after being offline
**When** the SyncEngine initiates a pull sync
**Then** it requests `GET /api/v1/{resource}?since={lastSyncTimestamp}` for each module
**And** a full day of transactions (150+) syncs in < 30s (NFR3)

**Given** a sync payload is transmitted
**When** sent over the network
**Then** it contains only data deltas (no images or binary assets, NFR26), is compressed (NFR24), and functions on 2G at 50 kbps (NFR25)

**Given** a successful sync cycle completes
**When** all modules are reconciled
**Then** `lastSyncTimestamp` is updated per module in Isar metadata and the next sync starts from the new timestamp

### Story 6.3: Conflict Resolution — LWW for Data, Manual Queue for Financial

As a platform,
I want non-financial conflicts resolved automatically and financial conflicts flagged for manual review,
So that data integrity is maintained without overwhelming operators with false alerts.

**Acceptance Criteria:**

**Given** the same non-financial record (e.g. item name) is updated on two offline devices
**When** both updates sync
**Then** the record with the later `updatedAt` wins (last-write-wins) without notification

**Given** a financial mutation (sale, customer balance, stock movement) conflicts with a server-side record
**When** the sync detects the conflict
**Then** it is NOT auto-resolved via LWW
**And** it is placed in the manual resolution queue with: local value, server value, timestamps, actor
**And** the owner receives a notification

**Given** a conflict is in the queue
**When** the owner opens the resolution interface
**Then** they see both versions side by side and can select which to keep or enter a corrected value
**And** the resolution is recorded in the audit trail

### Story 6.4: Non-Blocking Connectivity Status Indicator

As a user,
I want to see my connectivity status without it interrupting what I'm doing,
So that network state is informational only and never blocks operations.

**Acceptance Criteria:**

**Given** the device loses connectivity during an active POS session
**When** the state changes to offline
**Then** a small indicator appears in the status bar only (< 5% screen area, NFR30)
**And** no modal, toast, or blocking alert is shown
**And** all POS actions remain fully functional without delay

**Given** the device is offline and I create a sale or perform any operation
**When** the operation executes
**Then** it succeeds immediately (written to Isar) with no connectivity-related confirmation prompt

**Given** the device reconnects
**When** the SyncEngine begins syncing
**Then** the indicator transitions to "syncing" then "synced" silently without interrupting the user

### Story 6.5: Crash Recovery with Zero Data Loss

As a commercial,
I want the app to recover to a consistent state after an unexpected termination,
So that no sales or operations are ever lost even if the device shuts down mid-operation.

**Acceptance Criteria:**

**Given** a submitted operation was in the outbox when the device lost power
**When** the app restarts
**Then** the outbox item is still present and retried by the SyncEngine
**And** no operation not yet submitted by the user is partially written

**Given** an outbox item was mid-sync when the device crashed
**When** the SyncEngine resumes after restart
**Then** the item is retried from the beginning (idempotent sync)
**And** no duplicates are created server-side (server deduplicates by `clientId`)

**Given** a simulated crash-recovery test (power cut simulation, NFR15)
**When** the app restarts
**Then** zero transactions are lost and the app reaches a usable state in < 3s (NFR4)

### Story 6.6: Configurable Local Data Retention

As a tenant owner,
I want to configure how many days of data the app keeps locally,
So that device storage stays within limits while preserving enough history for daily operations.

**Acceptance Criteria:**

**Given** local retention is set to 30 days (range: 30–90, default: 30)
**When** the nightly maintenance task runs
**Then** records older than 30 days are purged from Isar
**And** the local database stays under 500MB (NFR7)
**And** records with un-synced outbox items are never purged

**Given** a user queries data beyond the local retention window
**When** the query runs
**Then** the app fetches it from the server (not shown as "unavailable")

### Story 6.7: Sync Failure Lifecycle and Manual Resolution

As an owner,
I want failed sync mutations tracked, retried automatically, and surfaced for manual resolution,
So that no operation is silently lost and I have full control over irrecoverable failures.

**Acceptance Criteria:**

**Given** an outbox item fails (server 5xx or network timeout)
**When** the failure occurs
**Then** the SyncEngine retries with exponential backoff: 5s, 30s, 2min (NFR16)
**And** after 3 failed attempts the item is marked `FAILED`
**And** a push notification is sent to the owner and on-device user

**Given** a mutation is `FAILED`
**When** the owner opens the manual resolution interface
**Then** they see: entity type, operation, payload, error message, failure timestamp, retry count

**Given** the owner acts on a failed mutation
**When** they choose Retry
**Then** the mutation is re-queued in the outbox with `attempts` reset to 0
**And** financial mutations (sales, balance updates, stock movements) can never be silently discarded — explicit owner action is always required

---

## Epic 7: Operations Reporting & Daily Intelligence

Owner and manager get complete visibility on daily operations — consolidated reports, live dashboard KPIs, immutable audit trail, and an automatic nightly summary pushed to the owner.

### Story 7.1: Manager Generates Daily Consolidation Report

As a manager,
I want to generate a daily consolidation report covering sales, losses, variances, and transfers,
So that I have a complete picture of the day's operations in one view.

**Acceptance Criteria:**

**Given** I am authenticated as manager
**When** I request the daily report for a specific date
**Then** it includes: total sales by payment method, total losses by location, transfer variances, session discrepancies, and top items by quantity sold
**And** the report generates in < 2s (NFR5)

**Given** the device is offline
**When** I request today's report
**Then** it is generated from local Isar data without a server call

**Given** I request a past date beyond local retention
**When** the query executes
**Then** the report fetches from the server with the same structure

### Story 7.2: Owner Views Live Operations Dashboard

As an owner,
I want a real-time dashboard showing key performance indicators of my business,
So that I can monitor operations at a glance — even remotely from abroad.

**Acceptance Criteria:**

**Given** I am authenticated as owner
**When** I open the dashboard
**Then** I see: today's revenue (CA), number of sales, total declared losses, session discrepancy total, and count of stock-critical items (below `lowStockThreshold`)
**And** the data refreshes automatically when a new sync cycle completes via Supabase Realtime

**Given** no sales have been recorded today
**When** the dashboard loads
**Then** all KPIs show 0 with an i18n-resolved "no activity" label (not null, not blank)

### Story 7.3: Immutable Audit Trail for All Mutations

As an owner,
I want every mutation permanently recorded with actor, timestamp, and before/after values,
So that I can always trace what happened, who did it, and when — with no possibility of tampering.

**Acceptance Criteria:**

**Given** any mutation occurs (sale, price change, stock adjustment, role modification)
**When** committed server-side
**Then** an audit entry is written with: `tenantId`, `actorId`, `entityType`, `entityId`, `operation`, `before` (nullable), `after`, `timestamp`
**And** the audit record is immutable — no UPDATE or DELETE is permitted on audit entries

**Given** I query the audit trail for a specific item, user, or date range
**When** the query runs
**Then** the full history is returned chronologically
**And** every price change shows exact before/after values and actor (NFR12)

**Given** local data is purged beyond the retention window
**When** the server audit trail is queried
**Then** it remains intact and queryable indefinitely (FR51)

### Story 7.4: Automatic Daily Summary to Owner

As an owner,
I want an automatic summary of my business delivered every evening,
So that I stay informed about the day's performance without opening the app — especially when not on-site.

**Acceptance Criteria:**

**Given** the tenant's summary time is configured (default: 20h00 local) and owner has opted in to push notifications
**When** the scheduled time arrives
**Then** a push notification is sent with: (1) total revenue, (2) total declared losses, (3) items below `lowStockThreshold`, (4) top 3 best-selling items by quantity

**Given** the owner has opted in to WhatsApp summaries
**When** the message is generated
**Then** all strings use i18n-resolved templates with zero hardcoded French strings (NFR31)
**And** currency and date formats match the tenant's configured locale

**Given** there was no activity during the day
**When** the summary is generated
**Then** it sends with an i18n-resolved "no activity" message — not skipped silently

**Given** the owner changes the summary time to 22h00
**When** the next nightly cycle runs
**Then** the summary fires at 22h00 local time

---

## Epic 8: Platform Foundations — Module System, Payments, i18n & Compliance Infrastructure

**Goal:** Deliver the cross-cutting technical foundations that all functional epics depend on: dynamic module registry, pluggable payment adapters, AiActionsManifest registry, zero-hardcoded-string i18n, versioned API with rate limiting, pluggable compliance framework, anticipated DB schema seeds for H2/H3, and CI/CD infrastructure.

**FR Coverage:** FR-TEMPLATE-01, FR-TEMPLATE-02, FR33 (payment), NFR31, NFR32, NFR33, NFR35, NFR36, NFR37, NFR38, NFR-INFRA-01–05, FR-MULTISTORE-01 (schema seed), FR51 (audit arch)

---

### Story 8.1: Module Registry — Per-Tenant Activation & Dependency Validation

As a Super Admin,
I want to activate or deactivate modules per tenant from the backoffice,
So that each tenant only pays for and sees what their subscription entitles them to.

**Acceptance Criteria:**

**Given** a new tenant is provisioned
**When** the platform creates their record
**Then** a module activation record is created for each default module (Sales, Inventory, CRM) with `isActive: true`
**And** optional modules (Appointments, Reservations, HR, etc.) are created with `isActive: false`

**Given** Super Admin activates the Appointments module for a tenant
**When** the activation request is processed
**Then** `ModuleGuard` allows `/appointments/**` routes for that tenant's users
**And** the UI shows the Appointments nav item on next app launch (FR-TEMPLATE-01)

**Given** a module has declared dependencies (e.g., Reservations requires CRM)
**When** an attempt is made to deactivate a dependency module while a dependent module is active
**Then** the operation is rejected with a clear error listing the blocking dependent modules (FR-TEMPLATE-02)

**Given** a user on the Flutter client attempts to access a deactivated module route
**When** the `ModuleGuard` evaluates the request
**Then** it returns HTTP 403 with code `MODULE_NOT_ACTIVE`
**And** the Flutter client shows a paywall/upgrade screen

### Story 8.2: Payment Adapter Interface — Cash & Wave Adapters

As a developer,
I want all payment processing to go through a `PaymentAdapter` interface,
So that adding new payment providers (Orange Money, Stripe) requires no changes to business logic.

**Acceptance Criteria:**

**Given** the `PaymentAdapter` interface defines `initiate(amount, currency, metadata)`, `verify(ref)`, `refund(ref, amount)`
**When** the Cash adapter is invoked
**Then** it immediately returns a confirmed payment result with no external API call (NFR33)

**Given** the Wave adapter is configured with valid API credentials
**When** `initiate()` is called with a valid amount and recipient
**Then** the adapter calls the Wave API, stores the reference, and returns `{ status: 'pending', ref }`
**And** no Wave-specific logic leaks into the service layer

**Given** a payment provider is temporarily unavailable
**When** `initiate()` throws an error
**Then** the error is caught by the adapter and rethrown as a standardized `PaymentError` with provider-agnostic fields
**And** the business-layer service never receives a provider-specific error object

**Given** a new `OrangeMoneyAdapter` is implemented by implementing the interface
**When** it is registered in the `PaymentAdapterRegistry`
**Then** it is available for selection without any modification to existing service code (NFR33)

### Story 8.3: AiActionsManifest Registry on All Level 2 Modules

As a platform architect,
I want every functional module to register its actions in the `AiActionsManifest`,
So that the H2 AI layer can discover and invoke any operation without hardcoded routing logic.

**Acceptance Criteria:**

**Given** the Sales module is loaded
**When** the platform initializes
**Then** the Sales module registers at minimum: `createSale`, `voidSale`, `applyCoupon` in the manifest with their input schemas

**Given** the Inventory module is loaded
**When** the platform initializes
**Then** it registers: `addStock`, `deductStock`, `setThreshold`, `declareWaste` in the manifest

**Given** the AI assistant (H2) calls `manifest.resolve('createSale')`
**When** the resolution completes
**Then** it receives the handler reference, input schema, and required permissions — and can invoke it directly (FR-AI-01)

**Given** a module is deactivated for a tenant
**When** the manifest is queried for that tenant
**Then** the deactivated module's actions are excluded from the resolution results

### Story 8.4: i18n Infrastructure — Zero Hardcoded Strings

As a developer,
I want all user-facing strings on both backend and frontend to be resolved through the i18n system,
So that Scalario can serve users in any language with no code changes (NFR31).

**Acceptance Criteria:**

**Given** a new backend error or notification string is needed
**When** a developer adds it
**Then** it MUST be added to the i18n key registry — PRs with hardcoded French or English strings in user-facing contexts are rejected by CI lint rule

**Given** the tenant locale is set to `fr-SN`
**When** any API response includes a user-facing message
**Then** the message is resolved in French (Senegal) with correct currency symbol and date format

**Given** the Flutter client renders any label, button, error, or notification
**When** the widget builds
**Then** it uses `AppLocalizations.of(context).key` — direct string literals in user-facing widgets fail the CI lint check

**Given** a new locale (`en-GH`) is added to the i18n registry
**When** a tenant switches to that locale
**Then** all strings resolve in that locale with zero code changes — only translation file additions are needed

### Story 8.5: Versioned API, Rate Limiting & Server-Side Subscription Enforcement

As a platform operator,
I want all API routes versioned, rate-limited, and protected by subscription tier,
So that the platform scales safely and tenants cannot exceed their plan limits.

**Acceptance Criteria:**

**Given** all routes are prefixed with `/v1/`
**When** a future breaking change requires a new API version
**Then** `/v2/` routes are added without removing `/v1/` — existing clients are not broken (NFR35)

**Given** a tenant sends more than the configured rate limit (e.g., 100 req/min)
**When** the limit is exceeded
**Then** HTTP 429 is returned with `Retry-After` header
**And** legitimate traffic is not throttled

**Given** a tenant's subscription tier allows max 500 products
**When** a request to create product #501 is received
**Then** `BillingGuard` intercepts it and returns HTTP 402 with code `PLAN_LIMIT_EXCEEDED` before any DB write occurs (NFR36)

**Given** a tenant's subscription expires
**When** any protected route is accessed
**Then** `BillingGuard` returns HTTP 402 with code `SUBSCRIPTION_EXPIRED`
**And** the tenant is redirected to the upgrade/renewal screen

### Story 8.6: Pluggable Compliance Framework Interface

As a platform architect,
I want accounting and compliance rules to be injected via a `CompliancePlugin` interface,
So that Scalario can operate correctly under OHADA, CNSS, or any other regulatory framework without core code changes (NFR32).

**Acceptance Criteria:**

**Given** the `CompliancePlugin` interface defines `validateTransaction(tx)`, `generateReport(period)`, `getChartOfAccounts()`
**When** the OHADA plugin is loaded for a tenant in a OHADA-zone country
**Then** `validateTransaction` applies OHADA-specific posting rules
**And** `generateReport` returns an OHADA-compliant balance sheet structure

**Given** a tenant is in a country without a registered compliance plugin
**When** compliance functions are called
**Then** a `NullCompliancePlugin` is used that passes all validations and returns empty report structures — no crash

**Given** a `CNSSPlugin` is implemented and registered
**When** payroll is processed for a Senegalese tenant
**Then** CNSS contribution calculations are handled by the plugin with no core payroll logic changes (NFR32)

### Story 8.7: Connect & Enterprise Anticipated DB Schema Seeds

As a platform architect,
I want the H2/H3 feature DB schemas (B2B Connect network tables, multi-store aggregation tables) seeded in the initial migration,
So that enabling these features later requires only data population, not schema migrations on live tenants.

**Acceptance Criteria:**

**Given** the initial database migration runs
**When** it completes
**Then** the `b2b_connections`, `b2b_offers`, `b2b_orders` tables exist with all planned columns but are empty (FR-MULTISTORE-01 seed)

**Given** a developer inspects the schema after H1 deploy
**When** they query these tables
**Then** they are present and correctly indexed — no migration error occurs
**And** no H1 application code writes to these tables

**Given** H3 B2B Connect is activated in a future release
**When** the feature flag is enabled
**Then** no schema migration is needed — only service layer code is added

### Story 8.8: Multi-Schema Data Migration Without Loss

As a platform operator,
I want all schema migrations to be reversible and zero-data-loss,
So that deployments can be rolled back without destroying tenant data (NFR37).

**Acceptance Criteria:**

**Given** a Prisma migration adds a new non-nullable column
**When** the migration runs on a database with existing rows
**Then** a default value is provided so existing rows remain valid — no migration fails on non-empty tables

**Given** a migration is deployed and a critical bug is discovered
**When** a rollback migration is run
**Then** the schema returns to the previous state and all pre-migration data is intact

**Given** migrations are run in a CI pipeline against a seeded test database
**When** the pipeline runs
**Then** all up and down migrations pass without errors before the build is considered green (NFR-INFRA-01)

### Story 8.9: Infrastructure CI/CD, Deploy Pipeline & Security Baseline

As a platform operator,
I want a complete CI/CD pipeline with security scanning, test gates, and automated deployment,
So that every merge to main is deployable with high confidence and no manual steps (NFR-INFRA-01–05).

**Acceptance Criteria:**

**Given** a PR is opened against `main`
**When** CI runs
**Then** it executes: lint → unit tests → integration tests (real DB) → migration dry-run → SAST scan
**And** the PR cannot be merged if any step fails (NFR-INFRA-01)

**Given** all CI checks pass on `main`
**When** the deploy pipeline triggers
**Then** the NestJS API is containerized, pushed to the registry, and deployed to the staging environment automatically (NFR-INFRA-02)

**Given** a SAST scan detects a high-severity vulnerability in a dependency
**When** the scan reports it
**Then** the build fails and the vulnerability is surfaced in the PR review interface (NFR-INFRA-03)

**Given** the production environment handles secrets (DB credentials, payment API keys)
**When** the application reads them
**Then** they are injected via environment variables from a secrets manager — no secrets exist in the codebase or Docker images (NFR-INFRA-04)

---

## Epic 9: Client Orders & Delivery Workflow

**Goal:** Enable clients to place orders via WhatsApp/phone, track delivery status, and receive digital confirmations — creating a complete order-to-delivery loop for B2C commerce.

**FR Coverage:** FR98, FR99, FR107, FR108, FR109, FR110, FR111

---

### Story 9.1: Client Order Intake via WhatsApp & Phone

As a shop owner,
I want to log client orders received via WhatsApp or phone call directly in Scalario,
So that verbal and message orders are tracked in the same system as walk-in sales.

**Acceptance Criteria:**

**Given** I receive a WhatsApp order message from a client
**When** I open the "New Client Order" screen
**Then** I can search for the client by name/phone, select items with quantities, set a delivery address and scheduled delivery time, and add order notes (FR98)

**Given** I submit the order
**When** it is saved
**Then** it appears in the "Pending Orders" queue with status `PENDING`
**And** stock availability is checked — unavailable items are flagged with a warning (not blocked)

**Given** the client does not exist in CRM yet
**When** I enter their phone number
**Then** a new contact is created automatically with the order linked (FR99)

### Story 9.2: Order-to-Delivery Status Tracking

As a shop owner,
I want to move orders through a `PENDING → CONFIRMED → OUT_FOR_DELIVERY → DELIVERED` pipeline,
So that I always know what's been promised, what's in transit, and what's been completed.

**Acceptance Criteria:**

**Given** an order is in `PENDING` status
**When** I confirm it
**Then** its status changes to `CONFIRMED`
**And** the reserved stock is locked against other sales (FR107)

**Given** an order is `CONFIRMED`
**When** I assign it to a delivery person and tap "Dispatch"
**Then** status changes to `OUT_FOR_DELIVERY`
**And** the delivery person's name is recorded on the order (FR108)

**Given** the delivery person confirms delivery
**When** I tap "Mark Delivered"
**Then** status changes to `DELIVERED`, the delivery timestamp is recorded, and the stock deduction is finalized (FR109)

**Given** a delivered order
**When** the client later reports non-delivery
**Then** an owner/manager can open a dispute that changes status to `DISPUTED` and triggers a review notification (FR110)

### Story 9.3: Digital Delivery Receipt & Client Notification

As a client,
I want to receive a digital receipt when my order is delivered,
So that I have proof of delivery and the order details without needing a paper receipt.

**Acceptance Criteria:**

**Given** an order is marked `DELIVERED`
**When** the delivery confirmation is submitted
**Then** a digital receipt is generated with: order items, quantities, total, delivery address, and delivery timestamp (FR111)

**Given** the receipt is generated
**When** the client has a WhatsApp number on record
**Then** the receipt is sent via WhatsApp automatically
**And** it uses an i18n-resolved template — no hardcoded strings (NFR31)

**Given** the owner reviews the order history
**When** they open any past delivered order
**Then** the digital receipt is accessible and can be resent on demand

### Story 9.4: Client Order Analytics

As an owner,
I want to see a breakdown of client orders by status, delivery time, and client,
So that I can identify delivery bottlenecks and high-value delivery clients.

**Acceptance Criteria:**

**Given** I open the Orders Analytics view
**When** I filter by date range
**Then** I see: total orders by status, average fulfillment time (CONFIRMED → DELIVERED), top 5 clients by order volume (FR99)

**Given** orders have been in `PENDING` status for more than a configurable threshold (default: 2 hours)
**When** I view the pending orders list
**Then** overdue orders are highlighted with a visual indicator

---

## Epic 10: Billing Plans, Tenant Provisioning & Super Admin Backoffice

**Goal:** Give Scalario operators a complete backoffice to manage tenant lifecycle — provisioning, billing plan assignment, module activation, and platform-wide monitoring — without touching the database directly.

**FR Coverage:** FR100, FR101, FR102, FR103, FR-SUPERADMIN-01–06

---

### Story 10.1: Tenant Provisioning from Super Admin Backoffice

As a Super Admin,
I want to create a new tenant from the backoffice with a single form,
So that onboarding a new business requires no manual DB intervention.

**Acceptance Criteria:**

**Given** I fill in: business name, owner email, country, currency, sector template, and billing plan
**When** I submit the provisioning form
**Then** the system creates: tenant record, owner user account, default roles (Owner, Manager, Cashier), default module activations, and initial DB schema (FR-SUPERADMIN-01)
**And** the owner receives a welcome email with their login credentials

**Given** the provisioning completes
**When** I view the tenant in the backoffice
**Then** I see their full profile: created date, sector, plan, active modules, owner contact

**Given** I try to provision a tenant with an email already in use
**When** I submit the form
**Then** a validation error is shown — no duplicate tenant is created

### Story 10.2: Billing Plan Management

As a Super Admin,
I want to create and manage billing plans with tier limits and module inclusions,
So that I can adjust pricing without deploying new code (FR100).

**Acceptance Criteria:**

**Given** I create a new billing plan "Pro" with: max 1000 products, max 5 users, modules [Sales, Inventory, CRM, Appointments]
**When** the plan is saved
**Then** it is immediately available for assignment to new or existing tenants

**Given** I update the "Starter" plan to increase the product limit from 200 to 300
**When** the update is saved
**Then** all tenants on the Starter plan have their effective limit updated immediately
**And** tenants who were previously over the new limit are flagged for review (FR101)

**Given** I assign a tenant to a new billing plan
**When** the assignment is confirmed
**Then** `BillingGuard` enforces the new limits on the next API call — no restart required (FR102)

### Story 10.3: Module Activation per Tenant

As a Super Admin,
I want to activate or deactivate individual modules per tenant from the backoffice,
So that I can grant trial access or respond to plan downgrades without code changes (FR103).

**Acceptance Criteria:**

**Given** a tenant wants to trial the Reservations module
**When** I activate it from the backoffice
**Then** their `ModuleGuard` allows access within 60 seconds (next auth token refresh cycle)

**Given** a tenant downgrades and the HR module is no longer included
**When** I deactivate it
**Then** HR routes return 403 for that tenant's users on the next request
**And** existing HR data is preserved — not deleted

### Story 10.4: Platform Health Monitoring & Alerting

As a Super Admin,
I want a real-time platform health dashboard,
So that I can detect degraded tenants, failed sync jobs, and infrastructure issues before clients report them (FR-SUPERADMIN-02).

**Acceptance Criteria:**

**Given** I open the platform health dashboard
**When** it loads
**Then** I see: active tenants count, API error rate (last 1h), pending sync queue depth, and infrastructure health indicators

**Given** a tenant's outbox sync queue has been stalled for more than 10 minutes
**When** the monitoring job detects it
**Then** an alert is raised in the Super Admin dashboard with the tenant ID and stall duration (NFR-INFRA-05)

**Given** I click on a specific tenant in the health view
**When** the detail panel opens
**Then** I see their last activity timestamp, sync queue status, and recent error log entries (FR-SUPERADMIN-06)

### Story 10.5: Super Admin Impersonation for Support

As a Super Admin,
I want to impersonate any tenant's account for support purposes,
So that I can diagnose issues from the tenant's perspective without sharing credentials (FR-SUPERADMIN-03).

**Acceptance Criteria:**

**Given** a tenant reports a bug
**When** I initiate impersonation from the backoffice
**Then** I receive a short-lived token (30-min TTL) that grants me the impersonated tenant's permissions

**Given** I am impersonating a tenant
**When** I perform any action
**Then** the audit trail records: `actorId: superadmin_id`, `impersonating: tenant_id` — my actions are permanently distinguished from the tenant's own actions (FR-SUPERADMIN-04)

**Given** the impersonation token expires
**When** I make an API call
**Then** the session ends and I am returned to the Super Admin context — no silent extension

---

## Epic 11: Advanced Product & Inventory Features

**Goal:** Cover the full product management surface: variants, compound products (recipes), batch/lot tracking, inter-location transfers, and multi-store aggregation visibility — enabling complex inventory operations beyond basic stock-in/stock-out.

**FR Coverage:** FR83–97, FR-MULTISTORE-01

---

### Story 11.1: Product Variants (Size, Color, Unit)

As a shop owner,
I want to define product variants (e.g., Small/Medium/Large T-shirts, 1L/5L oil),
So that I track each variant's stock separately without creating duplicate products.

**Acceptance Criteria:**

**Given** I create a product "T-Shirt"
**When** I add variant attributes (Size: S, M, L) and (Color: Red, Blue)
**Then** variant SKUs are auto-generated for each combination (S-Red, S-Blue, M-Red, etc.)
**And** each variant has its own stock level (FR83)

**Given** a sale is made for "T-Shirt M-Red"
**When** it is committed
**Then** only the M-Red variant stock is decremented — other variants are unaffected (FR84)

**Given** I view the product detail for "T-Shirt"
**When** the variants panel renders
**Then** I see all variants with their individual stock levels, prices, and low-stock indicators (FR85)

### Story 11.2: Compound Products & Recipe Management

As a restaurateur or food producer,
I want to define compound products (recipes) that automatically deduct ingredient stock when sold,
So that I never manually track ingredient consumption for produced items.

**Acceptance Criteria:**

**Given** I define "Smoothie Bowl" with recipe: 200g Mango + 100g Banana + 50g Oats
**When** a Smoothie Bowl is sold
**Then** 200g is deducted from Mango stock, 100g from Banana, 50g from Oats — atomically (FR86)

**Given** Mango stock is insufficient for the recipe quantity
**When** a sale of Smoothie Bowl is attempted
**Then** the system warns: "Insufficient ingredient: Mango (need 200g, have 150g)" before confirming the sale (FR87)

**Given** I update the recipe (change Oats from 50g to 75g)
**When** the next Smoothie Bowl is sold
**Then** the updated recipe quantities are used for stock deduction

### Story 11.3: Batch & Lot Tracking with Expiry

As a shop owner selling perishables,
I want to track product batches with expiry dates and apply FEFO (First-Expired-First-Out) selection,
So that I always sell the oldest stock first and receive alerts before items expire.

**Acceptance Criteria:**

**Given** I receive a new batch of "Yogurt" with expiry 2026-04-15
**When** I record the stock entry with the batch's expiry date
**Then** a `BatchRecord` is created with `lotNumber`, `quantity`, `expiryDate`, `receivedAt` (FR88)

**Given** I sell 5 units of Yogurt
**When** the sale is committed
**Then** the system deducts from the batch with the earliest expiry date first (FEFO)
**And** if multiple batches are needed to fulfill the quantity, they are deducted in expiry order (FR89)

**Given** a batch has an expiry date within the next 3 days
**When** the nightly check runs
**Then** the owner receives a push notification: "Yogurt batch (Lot #X) expires in 3 days — 12 units remaining" (FR90)

### Story 11.4: Inter-Location Stock Transfer

As a multi-location business owner,
I want to transfer stock between my locations (warehouse → store),
So that I can balance inventory without recording fake sales or purchases.

**Acceptance Criteria:**

**Given** I initiate a transfer of 50kg "Rice" from Warehouse A to Store B
**When** the transfer is submitted
**Then** Warehouse A stock decreases by 50kg and Store B stock increases by 50kg — atomically (FR92)

**Given** the transfer is initiated offline on a field device
**When** the device syncs
**Then** the transfer is replayed on the server via the outbox pattern with conflict detection (FR92 + outbox arch)

**Given** I view the transfer history for Store B
**When** the history loads
**Then** all incoming and outgoing transfers are listed with: source/destination, quantity, actor, and timestamp

### Story 11.5: Multi-Store Aggregated Inventory View

As a business owner with multiple locations,
I want to see a consolidated inventory view across all my stores,
So that I can identify where stock is concentrated and make redistribution decisions.

**Acceptance Criteria:**

**Given** I have 3 stores with different stock levels of "Cooking Oil 5L"
**When** I open the Multi-Store Inventory view
**Then** I see a table: Store | Stock Level | Below Threshold? — for every location (FR-MULTISTORE-01)

**Given** the aggregated view loads
**When** it renders
**Then** total aggregated stock across all stores is shown at the top
**And** locations below threshold are highlighted

**Given** I tap a specific store row
**When** the detail view opens
**Then** I navigate to that store's full product list with their individual levels

### Story 11.6: Supplier Management & Purchase Orders

As an inventory manager,
I want to manage supplier profiles and create purchase orders directly in Scalario,
So that my restocking workflow is tracked end-to-end within the system.

**Acceptance Criteria:**

**Given** I create a supplier profile: name, contact, lead time, preferred currency
**When** saved
**Then** the supplier is available when creating purchase orders (FR93)

**Given** I create a PO for 100kg Rice from Supplier X at 500 XOF/kg
**When** the PO is submitted
**Then** a `PurchaseOrder` record is created with status `PENDING` and line items stored (FR94)

**Given** the goods arrive and I confirm receipt
**When** I mark the PO as received and enter actual quantities
**Then** stock is increased by the received quantities
**And** if actual ≠ ordered, a discrepancy is flagged for review (FR95)

### Story 11.7: Waste & Loss Declaration with Category Tracking

As an inventory manager,
I want to declare waste or losses with a reason category,
So that I can analyze where inventory shrinkage is coming from and optimize accordingly.

**Acceptance Criteria:**

**Given** 5 units of Yogurt have expired
**When** I declare the waste with category `EXPIRED`
**Then** stock is reduced by 5, a `WasteRecord` is created, and the loss value is added to the day's declared losses (FR96)

**Given** I declare a theft loss with category `THEFT`
**When** committed
**Then** a security alert notification is sent to the owner if a `THEFT` threshold is configured (FR97)

**Given** I view the Waste Report for the month
**When** it loads
**Then** waste is grouped by category (EXPIRED, DAMAGED, THEFT, OTHER) with total units and value per category

---

## Epic 12: AI Assistant Layer (H2)

**Goal:** Deliver the AI assistant that understands natural language queries about the business, executes actions via the AiActionsManifest, proactively surfaces insights, and maintains data sovereignty — all within the guard chain so AI never bypasses RBAC.

**FR Coverage:** FR-AI-01–04 (+ NFR39, NFR40 for safety constraints)

---

### Story 12.1: Natural Language Business Query

As an owner,
I want to ask questions about my business in plain language (French or English),
So that I get instant answers without knowing which report screen to navigate to.

**Acceptance Criteria:**

**Given** I type "Quels sont mes 5 produits les plus vendus ce mois?"
**When** the AI processes the query
**Then** it resolves the intent to `getSalesReport(period: current_month, groupBy: product, limit: 5)` via AiActionsManifest
**And** returns a ranked list with product names, units sold, and revenue — using my tenant data only (FR-AI-01)

**Given** I ask "Do I have enough stock to last the week?"
**When** the AI analyzes current stock vs. average daily sales velocity
**Then** it returns a per-product estimate: "Product X: ~3 days remaining. Product Y: sufficient for 14+ days." (FR-AI-02)

**Given** I ask a question that cannot be answered with available data
**When** the AI processes it
**Then** it responds with an honest "I don't have enough data to answer that" — not a hallucinated answer (NFR39)

### Story 12.2: AI-Driven Action Execution

As an owner,
I want to execute business operations via voice/text commands,
So that I can restock, adjust prices, or generate reports hands-free.

**Acceptance Criteria:**

**Given** I say "Add 50kg of Rice to inventory"
**When** the AI processes the command
**Then** it resolves to `addStock({ productId: rice_id, quantity: 50, unit: 'kg' })` via AiActionsManifest
**And** presents a confirmation: "Add 50kg Rice — confirm?" before executing (FR-AI-03)

**Given** I confirm the action
**When** it executes
**Then** the stock is increased, an audit trail entry is written with `actorId: ai_assistant`, and I receive a success confirmation

**Given** the action requires a permission I don't have (e.g., price change requires Manager role)
**When** the AI attempts to execute it
**Then** it is blocked by `RolesGuard` within the guard chain — the AI NEVER bypasses RBAC (NFR40)

### Story 12.3: Proactive Business Insights

As an owner,
I want the AI to proactively surface insights I didn't think to ask for,
So that I discover opportunities and risks I might have missed.

**Acceptance Criteria:**

**Given** the AI detects that Product X's sales velocity increased 40% this week
**When** the daily insight run executes
**Then** I receive a proactive notification: "Rice sales up 40% this week — current stock may last only 4 days. Consider restocking." (FR-AI-04)

**Given** the AI detects an unusual spike in waste declarations (3x the 30-day average)
**When** the anomaly detection runs
**Then** I receive an alert: "Unusual waste spike detected — 15 units declared in the last 24h. Review?" (FR-AI-04)

**Given** I have disabled proactive notifications in my AI preferences
**When** the insight engine runs
**Then** no proactive push notifications are sent — insights are available on demand only

### Story 12.4: Data Sovereignty & AI Safety Constraints

As a tenant,
I want to know that the AI assistant cannot access data from other tenants and cannot perform destructive actions autonomously,
So that I trust the AI layer with sensitive business data.

**Acceptance Criteria:**

**Given** the AI processes any query
**When** it constructs database queries via AiActionsManifest handlers
**Then** every query includes `tenantId` scoping — tenant isolation is enforced at the data layer, not by the AI (NFR40)

**Given** the AI is asked to "delete all sales from last month"
**When** it processes the command
**Then** it refuses: destructive bulk operations (DELETE, bulk UPDATE without specific criteria) are blocked at the manifest layer regardless of user instruction (NFR40)

**Given** the AI calls an external LLM API for natural language processing
**When** the request is constructed
**Then** only aggregated metrics and anonymized patterns are sent — no raw PII (customer names, phone numbers) leaves the tenant's data boundary (NFR39)

---

## Epic 13: Integrator Channel & Platform Governance

**Goal:** Enable third-party integrators to embed Scalario modules into their own platforms via a white-label API, managing their reseller tenants under their own branding and access controls — unlocking a B2B2B distribution channel.

**FR Coverage:** FR-INTEGRATOR-01–04, FR-SESSION-01

---

### Story 13.1: Integrator Account Registration & API Credential Management

As an integrator (ISV or reseller),
I want to register as an integrator on the Scalario platform and receive API credentials,
So that I can embed Scalario modules in my own product under my branding.

**Acceptance Criteria:**

**Given** I submit an integrator registration request with: company name, contact, intended use case, and agreement to ToS
**When** a Super Admin approves the application
**Then** an integrator account is created with: `integrator_id`, `api_key`, `api_secret`, and a default rate limit tier (FR-INTEGRATOR-01)

**Given** I have an integrator account
**When** I access my developer dashboard
**Then** I can: view my API credentials, rotate the secret, configure webhook endpoints, and see my API usage metrics (FR-INTEGRATOR-02)

**Given** I rotate my API secret
**When** the rotation completes
**Then** the old secret is invalidated immediately
**And** my existing active sessions using the old secret receive a 401 on the next request

### Story 13.2: Integrator-Managed Tenant Provisioning

As an integrator,
I want to provision tenants under my integrator account via API,
So that my clients onboard into Scalario without ever seeing the Scalario brand.

**Acceptance Criteria:**

**Given** I call `POST /v1/integrator/tenants` with tenant details and my API credentials
**When** the request is processed
**Then** a new tenant is created with: my `integrator_id` as parent, white-label branding config, and modules I am licensed to distribute (FR-INTEGRATOR-03)

**Given** the tenant is provisioned under my account
**When** they log in via my platform
**Then** they see my branding — no Scalario logos or references unless I configure it (FR-INTEGRATOR-03)

**Given** I try to provision a tenant with a module I am not licensed for
**When** the request is received
**Then** it is rejected with HTTP 403: `INTEGRATOR_MODULE_NOT_LICENSED`

### Story 13.3: Integrator Revenue Share & Usage Reporting

As an integrator,
I want to see usage metrics for all tenants under my account,
So that I can calculate my revenue share and identify high-value clients to upsell.

**Acceptance Criteria:**

**Given** I access the integrator analytics endpoint
**When** I query for a date range
**Then** I receive: active tenant count, API call volume per tenant, module activation breakdown, and MRR contribution per tenant (FR-INTEGRATOR-04)

**Given** a tenant under my account churns (subscription cancelled)
**When** the cancellation is processed
**Then** I receive a webhook event: `tenant.churned` with the tenant ID and final billing period

### Story 13.4: Session Management & Concurrent Login Control

As a platform administrator,
I want to control concurrent session limits per user and provide session revocation,
So that shared devices and security incidents can be managed without resetting passwords (FR-SESSION-01).

**Acceptance Criteria:**

**Given** a user logs in from a third device when the plan allows max 2 concurrent sessions
**When** the third login is attempted
**Then** the oldest session is automatically invalidated and the user is notified of the session displacement

**Given** an owner suspects their account was compromised
**When** they trigger "Revoke all sessions"
**Then** all active tokens for that user are invalidated immediately
**And** all devices are logged out on the next API call

**Given** a Super Admin reviews a suspicious tenant
**When** they access the tenant's session list
**Then** they can revoke any individual session with reason logging (FR-SESSION-01)

---

## Epic 14: Promotions, Coupons & Revenue Optimization Tools

**Goal:** Give merchants a flexible promotions engine — fixed-amount and percentage coupons, flash sales, loyalty point programs, and automatic discount application at POS — to drive repeat purchases and increase basket size.

**FR Coverage:** FR91 (coupons/promotions), FR-DEVIS-01 (quote-to-sale), FR105 (flash sales), FR106 (loyalty)

---

### Story 14.1: Coupon & Promotion Code Engine

As a shop owner,
I want to create discount codes (percentage or fixed amount) with usage limits and validity windows,
So that I can run targeted promotions without manually adjusting prices at checkout.

**Acceptance Criteria:**

**Given** I create a coupon "RAMADAN10" with: 10% discount, max 50 uses, valid 2026-03-01 to 2026-03-31
**When** saved
**Then** the coupon is active and usable at POS (FR91)

**Given** a cashier applies coupon code "RAMADAN10" at checkout
**When** the code is validated
**Then** the discount is applied to the subtotal, the use count is incremented, and the coupon ID is recorded on the sale

**Given** the coupon has reached its 50-use limit
**When** a cashier attempts to apply it
**Then** it is rejected with message: "Coupon limit reached" — no discount is applied

**Given** the coupon's validity window has expired
**When** it is applied
**Then** it is rejected with an i18n-resolved "coupon expired" error (NFR31)

### Story 14.2: Flash Sales & Time-Limited Price Overrides

As a shop owner,
I want to set temporary price reductions on specific products for a defined window,
So that I can run flash sales without manually changing and reverting prices.

**Acceptance Criteria:**

**Given** I set a flash sale on "Mango Juice 1L": 25% off from 2026-03-15 12:00 to 2026-03-15 18:00
**When** a sale occurs within that window
**Then** the POS automatically applies the reduced price — no manual coupon entry needed (FR105)

**Given** the flash sale window has passed
**When** a sale occurs
**Then** the original price is charged — no manual revert required

**Given** I view the product at POS during an active flash sale
**When** it is displayed
**Then** the original price is shown with a strikethrough and the flash price is highlighted

### Story 14.3: Loyalty Points Program

As a shop owner,
I want clients to earn points on purchases and redeem them for discounts,
So that I reward repeat customers and increase retention.

**Acceptance Criteria:**

**Given** the loyalty program is configured: 1 point per 100 XOF spent, 100 points = 500 XOF discount
**When** a sale of 1500 XOF is completed for a loyalty member
**Then** 15 points are credited to the client's account (FR106)

**Given** a loyalty member has 200 points and wants to redeem
**When** they request redemption at checkout
**Then** 100 points are deducted, a 500 XOF discount is applied, and 100 points remain

**Given** I view a client's loyalty profile
**When** the profile loads
**Then** I see: total points, points history (earn/redeem), current tier (if tiered program), and estimated next reward threshold

### Story 14.4: Quote-to-Sale Conversion

As a sales representative,
I want to generate a formal quote for a client and convert it to a confirmed sale upon acceptance,
So that I handle high-value or custom orders with a professional proposal step.

**Acceptance Criteria:**

**Given** I create a quote for Client X with 3 line items, a validity date, and a 5% custom discount
**When** saved
**Then** a PDF quote is generated with my business branding, quote number, and line items (FR-DEVIS-01)

**Given** the client accepts the quote
**When** I convert it to a sale
**Then** a sale record is created with the same line items and discount — no re-entry required
**And** the quote status changes to `CONVERTED`

**Given** the quote validity date passes without conversion
**When** the client later tries to accept it
**Then** the system warns: "Quote expired — prices may have changed" before allowing conversion

---

## Epic 15: Enterprise Operations — HR, Payroll, Accounting & Reporting

**Goal:** Serve growing businesses with multi-location operations: staff scheduling, leave management, payroll calculation with CNSS/IPRES compliance, OHADA-aligned chart of accounts, and comprehensive financial reporting for business owners and accountants.

**FR Coverage:** FR63–74

---

### Story 15.1: Staff Scheduling & Shift Management

As an HR manager,
I want to create weekly shift schedules for staff across locations,
So that coverage is planned, visible to all staff, and conflicts are flagged before the week starts.

**Acceptance Criteria:**

**Given** I open the schedule builder for Week 2026-03-16
**When** I assign shifts to staff members
**Then** I can set: employee, location, start time, end time — and the schedule is saved per employee per day (FR63)

**Given** I assign the same employee to two overlapping shifts
**When** I attempt to save
**Then** a conflict warning is shown: "Employee X is already scheduled for [time range] — confirm override?" (FR63)

**Given** an employee views their schedule on the mobile app
**When** the week loads
**Then** they see only their own shifts with location, start/end times

### Story 15.2: Leave & Absence Management

As an HR manager,
I want to manage leave requests, approvals, and balances,
So that absences are tracked and their impact on scheduling is visible.

**Acceptance Criteria:**

**Given** an employee submits a leave request for 2026-03-20 to 2026-03-22
**When** submitted
**Then** it appears in the manager's approval queue with status `PENDING` (FR64)

**Given** the manager approves the leave
**When** approved
**Then** the employee's leave balance is decremented by 3 days
**And** any shifts scheduled during the leave period are flagged for reassignment

**Given** the manager rejects the leave with a reason
**When** the employee next logs in
**Then** they see the rejection reason and can submit a revised request

### Story 15.3: Payroll Calculation with CNSS/IPRES Compliance

As an HR manager,
I want to calculate payroll for the month, including CNSS and IPRES deductions, via the compliance plugin,
So that I produce accurate pay slips without manual calculation.

**Acceptance Criteria:**

**Given** attendance records and salary configs are in place for the month
**When** I trigger payroll calculation for March 2026
**Then** the system calculates: gross salary, CNSS employee deduction, CNSS employer contribution, IPRES deduction, net salary — per employee (FR65, NFR32)

**Given** the CNSS plugin is active for a Senegalese tenant
**When** payroll runs
**Then** CNSS rates are sourced from the plugin — not hardcoded in payroll logic

**Given** payroll is calculated
**When** I approve it
**Then** a pay slip is generated per employee in PDF format with all line items

### Story 15.4: OHADA Chart of Accounts & Accounting Entries

As an accountant,
I want all transactions automatically posted to the correct OHADA account codes,
So that I can generate compliant financial statements without manual journal entries.

**Acceptance Criteria:**

**Given** a sale of 10,000 XOF is made
**When** committed
**Then** an accounting entry is posted: DR 411 (Clients) 10,000 / CR 701 (Sales) 10,000 — per OHADA plan (FR66, NFR32)

**Given** a stock purchase of 5,000 XOF is recorded
**When** committed
**Then** DR 601 (Purchases) 5,000 / CR 401 (Suppliers) 5,000 is posted

**Given** a non-OHADA country tenant
**When** transactions are recorded
**Then** the `NullCompliancePlugin` posts to a generic chart of accounts — no OHADA codes, no crash

### Story 15.5: Financial Reporting — P&L, Balance Sheet, Cash Flow

As an owner or accountant,
I want to generate P&L, balance sheet, and cash flow statements for any period,
So that I have the financial visibility required for investors, banks, and tax authorities.

**Acceptance Criteria:**

**Given** I request a P&L for Q1 2026
**When** the report generates
**Then** it shows: revenue by category, COGS, gross profit, operating expenses, and net profit — with prior period comparison (FR67)

**Given** I request a balance sheet as of 2026-03-31
**When** it generates
**Then** it shows: assets (current + fixed), liabilities (current + long-term), and equity — per OHADA structure for OHADA tenants (FR68)

**Given** I export the report
**When** export is triggered
**Then** a PDF and an XLSX are available for download

### Story 15.6: Multi-Location Consolidated Reporting

As an owner with multiple locations,
I want consolidated reports across all my stores as well as per-location breakdowns,
So that I see both the group picture and individual store performance.

**Acceptance Criteria:**

**Given** I have 3 active locations
**When** I open the consolidated P&L
**Then** it shows aggregated figures with a per-location column breakdown (FR69)

**Given** I drill into Store B's P&L
**When** the view loads
**Then** it shows only Store B's data — correctly isolated from the other stores

**Given** I compare Q1 vs Q4 2025 for the group
**When** the comparison loads
**Then** growth rates are shown per line item as percentage deltas

### Story 15.7: Tax Declaration Preparation & Export

As an accountant,
I want to generate tax declaration summaries (VAT, CNSS employer contributions) ready for filing,
So that tax preparation time is reduced to review and submission — not data compilation.

**Acceptance Criteria:**

**Given** I request the monthly VAT report for March 2026
**When** it generates
**Then** it shows: output VAT (collected on sales), input VAT (paid on purchases), net VAT due — grouped by tax code (FR70)

**Given** I request the CNSS employer contributions summary for Q1 2026
**When** it generates
**Then** it shows total contributions per employee and the aggregate due — formatted per CNSS declaration requirements (FR71, NFR32)

**Given** I export the tax summary
**When** the export runs
**Then** a formatted XLSX is generated that maps to the official declaration form fields

---

## Epic 16: Scalario Connect — B2B Supplier Network

**Goal:** Launch the B2B marketplace layer where tenants can discover suppliers, place bulk orders, and receive connected-supply confirmations — transforming Scalario from a single-business tool into a connected commerce network.

**FR Coverage:** FR-MULTISERVICE-01, FR-MULTISTORE-01 (B2B), FR-AI-05 (supplier matching)

---

### Story 16.1: Supplier & Buyer Profile on the Connect Network

As a business owner,
I want to create a Connect profile listing my products, minimum order quantities, and pricing tiers,
So that other Scalario tenants can discover and order from me.

**Acceptance Criteria:**

**Given** I enable the Connect module for my tenant
**When** I complete my seller profile: business name, location, product catalog excerpt, MOQ, and delivery zones
**Then** my profile is visible to other verified Scalario tenants in my region (FR-MULTISERVICE-01)

**Given** another tenant searches for "Rice 50kg Dakar"
**When** the search executes
**Then** my profile appears if I list that product and serve the Dakar delivery zone

**Given** I set my catalog item as private (not listed)
**When** another tenant searches
**Then** that item does not appear in their search results — only approved connections can see it

### Story 16.2: B2B Order Placement & Confirmation

As a buyer tenant,
I want to place bulk orders from supplier tenants in the Connect network,
So that my restocking workflow is automated and tracked end-to-end within Scalario.

**Acceptance Criteria:**

**Given** I find Supplier X's Rice listing on Connect
**When** I place an order for 500kg at the listed bulk price
**Then** a `B2BOrder` is created with status `PENDING_CONFIRMATION` linked to both tenants (FR-MULTISTORE-01)

**Given** Supplier X receives the order
**When** they confirm and set an estimated delivery date
**Then** the order status changes to `CONFIRMED`
**And** I receive a push notification with the confirmation details

**Given** the delivery is completed
**When** the supplier marks it `DELIVERED`
**Then** my inventory is automatically increased by the received quantity
**And** an incoming PO record is created on my side

### Story 16.3: AI-Assisted Supplier Matching

As a buyer tenant,
I want the AI to proactively suggest suppliers when my stock of an item is critically low,
So that I can reorder with minimal effort.

**Acceptance Criteria:**

**Given** my Rice stock drops below the low-stock threshold
**When** the AI insight engine runs
**Then** it suggests the top 3 Connect suppliers for Rice ranked by: price, proximity, and past order reliability (FR-AI-05)

**Given** I accept a supplier suggestion
**When** I confirm
**Then** a draft B2B order is pre-filled with the suggested supplier, quantity (based on reorder formula), and price — ready for review

**Given** no Connect suppliers are available for that product in my region
**When** the AI checks
**Then** it acknowledges: "No Connect suppliers found for this product in your region" — not a blank response

### Story 16.4: Connect Network Analytics for Suppliers

As a supplier tenant,
I want to see analytics on my Connect profile performance and order history,
So that I can optimize my pricing and product listing for the B2B market.

**Acceptance Criteria:**

**Given** I open my Connect analytics dashboard
**When** it loads
**Then** I see: profile views (last 30 days), orders received (count and value), average fulfillment time, and top 3 products by B2B order volume

**Given** a buyer leaves a rating after a delivered order
**When** the rating is submitted
**Then** my supplier profile shows the updated average rating visible to future buyers

---

## Epic 17: AI Configuration Wizard, Sector Templates & Tenant Onboarding

**Goal:** Eliminate the cold-start problem: the AI Config Wizard guides new tenants from zero to a fully configured Scalario in under 10 minutes, using sector templates, intelligent defaults, and guided data import — so the first session ends with a working system, not a blank screen.

**FR Coverage:** FR-TEMPLATE-01, FR-TEMPLATE-02, FR-MULTISERVICE-01 (sector), FR-AI-01 (onboarding AI), NFR-ONBOARDING-01

---

### Story 17.1: Sector Template Selection & Auto-Configuration

As a new tenant,
I want to select my business sector during onboarding and have Scalario auto-configure the right modules, categories, and workflows,
So that I start with a system that already understands my business type.

**Acceptance Criteria:**

**Given** I am a new tenant completing onboarding
**When** I select sector "Fresh Produce Market"
**Then** the platform activates: Sales, Inventory, CRM, Client Orders modules
**And** pre-creates product categories: Fruits, Vegetables, Dairy, Beverages
**And** configures default units: kg, g, piece, litre (FR-TEMPLATE-01)

**Given** I select "Restaurant"
**When** onboarding completes
**Then** the platform activates: Sales, Inventory, CRM, Reservations, Recipes modules
**And** pre-creates menu categories and a default recipe template

**Given** I want to customize the template after selection
**When** I reach the review step
**Then** I can add/remove modules and categories before finalizing — the template is a starting point, not a lock-in (FR-TEMPLATE-02)

### Story 17.2: AI-Guided Product Import from Photo

As a new tenant,
I want to photograph my existing product labels or price lists and have the AI extract product data,
So that I don't spend hours manually entering my catalog before I can start selling.

**Acceptance Criteria:**

**Given** I photograph a handwritten price list or product label
**When** I submit it during onboarding
**Then** the AI extracts: product name, unit price, unit of measure — and pre-fills the import form (FR-AI-01 onboarding variant)

**Given** the AI extracts 20 products from a photo
**When** the extraction is shown
**Then** I can review, correct, and confirm each item before importing — no silent auto-import

**Given** the AI cannot confidently extract a field
**When** showing the result
**Then** that field is left blank with a highlight — never filled with a low-confidence guess

### Story 17.3: Guided Initial Configuration Wizard

As a new tenant,
I want a step-by-step wizard that walks me through: business profile, team setup, first products, and first sale,
So that I understand how to use Scalario and have real data before closing the onboarding flow.

**Acceptance Criteria:**

**Given** I complete tenant registration
**When** I first open the app
**Then** the onboarding wizard launches automatically with steps: (1) Business profile, (2) Add your team, (3) Import your products, (4) Make your first sale

**Given** I complete step 3 (import products)
**When** I reach step 4
**Then** a practice POS screen opens with my real product catalog — I make a "test sale" that I can void after

**Given** I close the wizard mid-way
**When** I reopen the app
**Then** the wizard resumes at the step I left — progress is persisted (FR-TEMPLATE-02)

### Story 17.4: Tenant Self-Service Configuration After Onboarding

As a tenant owner,
I want to modify my configuration (activate new modules, change currency, update business profile) from the settings screen at any time,
So that my Scalario setup evolves with my business without needing to contact support.

**Acceptance Criteria:**

**Given** I want to add the Reservations module after onboarding
**When** I navigate to Settings → Modules
**Then** I see available modules with descriptions and upgrade requirements
**And** I can request activation (pending billing plan check) (FR-TEMPLATE-01)

**Given** I change my business currency from XOF to GHS
**When** the change is saved
**Then** all future transactions use GHS
**And** historical transactions retain their original currency — no retroactive conversion

**Given** I update my business logo and display name
**When** saved
**Then** receipts, reports, and notifications immediately reflect the new branding
