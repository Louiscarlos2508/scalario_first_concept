---
stepsCompleted: []
inputDocuments:
  - docs/architecture-scalario-2026-03-08.md
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/innovation-strategy-2026-03-29.md
  - _bmad-output/design-thinking-2026-03-29.md
  - apps/backend/prisma/schema.prisma
workflowType: architecture
project_name: scalario
user_name: Carlos-simpore
date: '2026-03-31'
---

# Architecture Document — Scalario Platform
**Author:** Carlos-simpore
**Date:** 2026-03-31
**Version:** 2.0
**Status:** Approved
**Replaces:** `docs/architecture-scalario-2026-03-08.md` (v1.6)
**PRD Reference:** `_bmad-output/planning-artifacts/prd.md` (v8.3)

---

## Table of Contents

1. [Executive Summary — What Changed and Why](#1-executive-summary)
2. [Architecture Overview — 4 Levels](#2-architecture-overview)
3. [System Components (Revised)](#3-system-components)
4. [Data Models (Revised)](#4-data-models)
5. [API Design (Revised)](#5-api-design)
6. [AI Architecture (New)](#6-ai-architecture)
7. [Flywheel Architecture (New)](#7-flywheel-architecture)
8. [ADRs — Architectural Decision Records](#8-adrs)
9. [Migration Path v1 → v2](#9-migration-path)
10. [What to Build When — H1/H2/H3](#10-what-to-build-when)

---

## 1. Executive Summary

### The Vision Shift

Architecture v1 was designed for a **vertical ERP focused on UEMOA Retail**. The vision has moved: Scalario is now a **universal management platform for any organization in the world** — commerce, industry, health, education, hospitality, agriculture, NGOs, cooperatives. UEMOA Retail remains the beachhead, not the ceiling.

This changes nothing that is already built. It changes how we extend it.

### What v1 Got Right (Keep)

| Component | Why It Holds |
|---|---|
| Offline-first (Isar + outbox + WAL) | Non-negotiable for UEMOA. Structurally sound. |
| Prisma multi-schema (kernel/shared/retail) | The cleanest isolation pattern available. Adding new schemas is zero-risk. |
| Kernel/Shared/Vertical separation | Proved correct — kernel untouched across all vertical tests. |
| RBAC in DB (Role + Permission + RolePermission) | Data-driven foundation. Right call. |
| businessType config pattern (BusinessTypeDefinition) | First implementation of config-over-code. Compatible with Templates Sectoriels. |
| API versioning `/api/v1/` | Already in place. Non-negotiable. |
| SDUI (Epic 10) | Compatible with Templates Sectoriels. Templates will reference SDUI layout configs. |
| Phase 3 anticipation fields | `orgMode`, `networkVisible`, `departmentIds`, `linkedTenantId`, `supplierReference`, `referredBy` — all still valid. |

### What v1 Got Wrong or Missed (Fix/Add)

| Issue | Severity | Impact | Decision |
|---|---|---|---|
| **3 tiers, not 4** — no Templates Sectoriels level | High | Blocks H2 multi-sector expansion without new architecture | Add 4th tier in architecture now, data model in H1 |
| **`roleScreenAccess` JSON in BusinessTypeDefinition** | Medium | Hardcodes screen access, blocks data-driven RBAC | Keep for H1, migrate to dedicated table in H2 — document as known debt |
| **No payment adapter pattern** | High | Wave integration will create direct coupling, hard to swap | Define PaymentAdapter interface now, implement in H1 |
| **No AI architecture** | High | Retrofitting AI into existing screens = UX disaster | Define AI section architecture now, Python microservice interface, defer implementation to H2 |
| **No i18n infrastructure** | Medium | Every hardcoded string is migration work at H2 | Add i18n rule to all new strings from today — no full implementation now |
| **No compliance framework** | Low | OHADA-specific code will pollute core modules | Define CompliancePlugin interface now, OHADA plugin in H2 |
| **`Role` has no `tenantId`** — shared across tenants | Medium | Custom roles per tenant impossible without migration | Anticipate with nullable `tenantId` on Role now |
| **`PlanDefinition` missing `limits` JSON** | Low | Usage enforcement middleware has no data to read | Add `limits` Json field to PlanDefinition now |
| **AuditLog userId NOT NULL** — inconsistency between doc and schema | Low | Schema is correct (nullable), doc was wrong | Document schema as authoritative |

### Critical Technical Debts — Rank Ordered

**Debt #1 — `roleScreenAccess` JSON in BusinessTypeDefinition (H2 blocker)**
The `roleScreenAccess` JSON field on `BusinessTypeDefinition` conflates business type config with RBAC. It works for Retail with fixed roles but breaks when: (a) a tenant has custom roles, (b) a Template Sectoriel defines its own role-to-screen mapping, (c) the AI needs to modify permissions. The field must be migrated to a dedicated `RoleScreenAccess` table in H2. The migration is not breaking — the existing JSON becomes the seed data.

**Debt #2 — No PaymentAdapter abstraction (H1 risk)**
Wave integration planned for H1 (post-Blandine). Without an adapter pattern, Wave logic goes directly into `PaymentsService`. When Orange Money, MTN MoMo, or Moov Money follow, each becomes a copy-paste. Define the interface before Wave implementation begins.

**Debt #3 — Strings in Flutter/NestJS code are not i18n-ready (H2 pain)**
No i18n infrastructure exists. All French labels, error messages, and notifications are hardcoded. This is acceptable for H1 (UEMOA-only, French-first) but becomes painful at H2 when English-speaking markets or multi-language intégrateurs arrive. Rule for all new code from today: no hardcoded user-facing strings. Use an i18n key pattern. Full implementation deferred to H2.

---

## 2. Architecture Overview

### 2.1 The 4-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│  LEVEL 4 — SECTORIAL TEMPLATES                                           │
│                                                                          │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────┐  ┌────────┐  │
│  │ Template       │  │ Template        │  │ Template     │  │ ...N   │  │
│  │ Épicerie       │  │ Pharmacie       │  │ Restauration │  │ future │  │
│  │ (config only)  │  │ (config only)   │  │ (config only)│  │        │  │
│  └────────────────┘  └─────────────────┘  └──────────────┘  └────────┘  │
│  Pure configuration bundles (modules + roles + screens + SDUI layout)   │
│  No code generation. Never touch Level 1–3.                              │
└─────────────────────────────────┬────────────────────────────────────────┘
                                  │ uses
┌─────────────────────────────────▼────────────────────────────────────────┐
│  LEVEL 3 — FUNCTIONAL MODULES                                            │
│                                                                          │
│  ┌─────────┐ ┌───────────┐ ┌─────────┐ ┌────────┐ ┌────────────────┐   │
│  │ Retail  │ │ Distribution│ │Restaur- │ │Services│ │ Future sectors │   │
│  │ POS +   │ │ ClientOrders│ │ation   │ │ Appts  │ │ (H2/H3)        │   │
│  │ Sessions│ │ Deliveries │ │ Tables  │ │        │ │                │   │
│  └─────────┘ └───────────┘ └─────────┘ └────────┘ └────────────────┘   │
│  Sector-specific behavior. Uses shared modules. Registered in kernel.   │
└─────────────────────────────────┬────────────────────────────────────────┘
                                  │ uses
┌─────────────────────────────────▼────────────────────────────────────────┐
│  LEVEL 2 — SHARED MODULES                                                │
│                                                                          │
│  ┌─────────┐ ┌────────────┐ ┌───────────┐ ┌────────┐ ┌──────────────┐  │
│  │ Catalog │ │Transactions│ │ Inventory │ │Payments│ │  Contacts    │  │
│  └─────────┘ └────────────┘ └───────────┘ └────────┘ └──────────────┘  │
│  ┌──────────┐ ┌────────┐ ┌─────────┐ ┌────────────┐ ┌──────────────┐  │
│  │Reporting │ │Variants│ │ Pricing │ │ Promotions │ │ PurchaseOrds │  │
│  └──────────┘ └────────┘ └─────────┘ └────────────┘ └──────────────┘  │
│  ┌────────────────┐ ┌──────────────┐ ┌────────────────────────────────┐ │
│  │InternalRequests│ │   Batches    │ │       ClientOrders             │ │
│  └────────────────┘ └──────────────┘ └────────────────────────────────┘ │
│  Cross-vertical. Each exposes AI-invocable actions (H2).                │
└─────────────────────────────────┬────────────────────────────────────────┘
                                  │ provides platform to
┌─────────────────────────────────▼────────────────────────────────────────┐
│  LEVEL 1 — KERNEL                                                        │
│                                                                          │
│  ┌──────┐ ┌────────┐ ┌──────┐ ┌─────────┐ ┌──────────┐ ┌────────────┐  │
│  │ Auth │ │Tenancy │ │ RBAC │ │EventBus │ │ Module   │ │  Billing   │  │
│  │      │ │        │ │      │ │         │ │ Registry │ │            │  │
│  └──────┘ └────────┘ └──────┘ └─────────┘ └──────────┘ └────────────┘  │
│  ┌──────────────────┐ ┌─────────────────────────────────────────────┐   │
│  │  BusinessType    │ │         SDUI Layout Engine                  │   │
│  │  Module          │ │         (LayoutRegistry + LayoutService)    │   │
│  └──────────────────┘ └─────────────────────────────────────────────┘   │
│  Infrastructure. Never depends on Level 2–3.                            │
└──────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Orthogonal Layer — AI

AI is **not a level in the hierarchy** — it is an orthogonal layer that cuts across Levels 2–3. It lives in a dedicated UI section (not injected into existing screens) and communicates with Level 2–3 modules via pre-declared AI-invocable actions.

```
┌────────────────────────────────────────────────────────┐
│  AI LAYER (Orthogonal — H2)                            │
│                                                        │
│  Python/FastAPI Microservice                           │
│  ┌────────────────────┐  ┌─────────────────────────┐  │
│  │  LLM Chat Panel    │  │  Command Bar (Cmd+K)    │  │
│  │  (GenUI output)    │  │  (intent → action)      │  │
│  └────────────────────┘  └─────────────────────────┘  │
│  ↕ Function Calling                                    │
│  ┌────────────────────────────────────────────────────┐│
│  │  AI Actions Catalog                                ││
│  │  (registered by each Level 2 module)               ││
│  └────────────────────────────────────────────────────┘│
│  ↕ Internal API                                        │
│  NestJS Backend (AI Actions Executor)                  │
└────────────────────────────────────────────────────────┘
```

### 2.3 Full System Architecture (Updated)

```
┌──────────────────────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT (Offline-First)                     │
│                                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Isar    │  │  Sync    │  │ Realtime │  │   UI Layer           │  │
│  │  (WAL)   │  │  Engine  │  │ Service  │  │  (Riverpod + SDUI)   │  │
│  │  Local DB│  │ (Isolate)│  │(Supabase)│  │  ┌──────────────────┐│  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │  │  AI Panel (H2)  ││  │
│       │             │              │         │  │  (dedicated UI) ││  │
│       └─────────────┴──────────────┘         │  └──────────────────┘│  │
│                     │ HTTPS (Delta Sync)       └──────────────────────┘  │
└─────────────────────┼────────────────────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────────────────────┐
│             NestJS BACKEND (Modular Monolith)                         │
│                     │                                                │
│  ┌──────────────────┴─────────────────────────────────────────────┐  │
│  │  API Gateway (AuthGuard + TenantGuard + ModuleGuard + i18n)   │  │
│  └──────────────────┬─────────────────────────────────────────────┘  │
│                     │                                                │
│  KERNEL ────────────┼───────────────────────────────────────────     │
│  Auth │ Tenancy │ RBAC │ EventBus │ ModuleRegistry │ Billing         │
│  BusinessType │ LayoutService (SDUI)                                │
│                     │                                                │
│  SHARED MODULES ────┼───────────────────────────────────────────     │
│  Catalog │ Transactions │ Inventory │ Payments │ Contacts            │
│  Reporting │ Variants │ Pricing │ Promotions │ PurchaseOrders        │
│  InternalRequests │ Batches │ ClientOrders                           │
│                     │                                                │
│  FUNCTIONAL MODULES ─────────────────────────────────────────────    │
│  retail/ │ distribution/ │ restaurant/ (H2) │ services/ (H2)        │
│                     │                                                │
│  PAYMENT ADAPTERS ───────────────────────────────────────────────    │
│  CashAdapter │ WaveAdapter (H1) │ OrangeMoneyAdapter (H2)            │
│                     │                                                │
│  COMPLIANCE PLUGINS ─────────────────────────────────────────────    │
│  OhadaPlugin (H2) │ TvaPlugin (H2) │ future                         │
│                     │                                                │
│  PRISMA DATA LAYER ──────────────────────────────────────────────    │
│  kernel schema │ shared schema │ retail schema │ ai schema (H2)     │
└─────────────────────┼────────────────────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────────────────────┐
│  AI MICROSERVICE (Python/FastAPI — H2)                               │
│  Separate process. Internal API only.                                │
│  NestJS ↔ Python via REST (internal /ai/* endpoints)                │
└─────────────────────┼────────────────────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────────────────────┐
│              SUPABASE (Self-Hosted — current + future)               │
│  PostgreSQL (RLS) │ Auth (JWT) │ Realtime (WS) │ Storage (H2)       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. System Components

### 3.1 Kernel Components (Unchanged from v1 except where noted)

#### 3.1.1 Auth Module — `kernel/auth`
No changes from v1.6. Supabase JWT, `AuthGuard`, `@CurrentUser()`.

#### 3.1.2 Tenancy Module — `kernel/tenancy`
No changes from v1.6. `TenantGuard`, `@CurrentTenant()`, tenant lifecycle.

**H2 addition:** Add `tenantLanguage` field to Tenant for i18n resolution. Default `"fr"`.

#### 3.1.3 RBAC Module — `kernel/rbac`

**Current state (H1):** `Role` table scoped by `vertical`, not by tenant. Fixed roles (owner, manager, commercial, cashier) seeded per vertical. `roleScreenAccess` JSON on `BusinessTypeDefinition` drives screen visibility per role.

**Known debt:** `roleScreenAccess` in `BusinessTypeDefinition` conflates business type config with access control. Acceptable for H1. **Must be migrated in H2.**

**H1 additions required (from PRD FR-RBAC-01):**
- Add nullable `tenantId` to `Role` table now to unblock custom roles in H2 without a breaking migration
- Seed system roles with `tenantId = null` (shared); custom roles will have `tenantId` set

**H2 target:**
```
RoleScreenAccess(id, roleId, screen, tenantId?, isVisible, createdAt)
```
Replaces `roleScreenAccess` JSON on `BusinessTypeDefinition`. Migration: seed from existing JSON, then drop JSON field.

#### 3.1.4 Event Bus — `kernel/events`
No changes from v1.6. NestJS `EventEmitter2`. In-process, no external broker.

**H2 addition:** Each `DomainEvent` must declare `aiRelevant: boolean`. Events marked `aiRelevant` are forwarded to the AI microservice for context building.

#### 3.1.5 Module Registry — `kernel/modules`
No changes from v1.6. `Module`, `TenantModule`, `ModuleGuard`, `@RequiresModule()`.

**H2 addition:** `Module` gets `aiActions: string[]` field — list of AI-invocable action codes registered by this module. Used by the AI layer to discover what is callable.

#### 3.1.6 Billing Module — `kernel/billing`
Current state (v1.6): `PlanDefinition`, `BillingEvent`, billing lifecycle on `Tenant`.

**Gap:** `PlanDefinition` is missing `limits Json` field. Add now. This field powers the Usage Limits Engine (H2 middleware) without a future migration:
```
PlanDefinition.limits Json @default("{}")
// e.g. {"maxUsers":5,"maxTransactions":500,"maxProducts":200,"maxStorageMb":500,"historyMonths":6}
```
**H1 rule:** The `limits` field is populated but the enforcement middleware is NOT implemented. Field anticipation only, identical to Story 1.6 pattern.

#### 3.1.7 Business Type Module — `kernel/business-type`
Current state: `BusinessTypeDefinition` with `code`, `name`, `defaultFlags`, `visibleSections`, `suggestedCategories`, `roleLabels`, `documentType`, `roleScreenAccess`, `transferLabels`, `vertical`.

**H1 status:** This module is the precursor to Sectorial Templates. It is compatible — the business type IS the lightweight version of a template.

**Technical debt:** `roleScreenAccess` JSON mixes RBAC concerns into business type config. See §3.1.3 for migration plan.

**H2 expansion:** `BusinessTypeDefinition` will be linked to a `SectorTemplate` record. The template aggregates: business type config + module activation list + SDUI layout config + role definitions.

#### 3.1.8 SDUI Layout Engine — `kernel/layout` (Epic 10, in progress)

Provides JSON-driven UI layout configuration. Reads from `LayoutDefinition` table, serves to Flutter `LayoutEngine`.

**Compatibility with Templates Sectoriels:** Full. A Sectorial Template's UI is expressed as a `LayoutDefinition` reference. No code change required in H2 — templates simply point to a layout config.

**Design rule (from design-thinking 2026-03-29):** SDUI layouts define screen structure. The AI panel is NOT part of any SDUI layout — it is a standalone dedicated component, always separate from module screens.

---

### 3.2 Shared Modules (Updated)

All 13 shared modules from v1.6 are retained unchanged in H1. Each module now has an explicit **AI-invocable actions interface** that must be declared in H2 before the Python microservice is wired. Below: interface spec (declare H1, implement H2).

#### AI-Invocable Actions Interface (declare in H1, implement in H2)

Each module must export an `AiActionsManifest`:
```typescript
interface AiAction {
  code: string;           // e.g. "catalog.create_product"
  description: string;    // Natural language description for the LLM
  parameters: JsonSchema; // Parameters the LLM must provide
  requiredPermission: string; // Permission code needed to execute
  offlineCacheable: boolean;  // Can be a cached action chip
}

interface AiActionsManifest {
  module: string;
  actions: AiAction[];
}
```

**Top-priority AI actions to register (H2) — the top-20 cacheable offline chips:**

| Module | Action code | Offline cacheable |
|---|---|---|
| catalog | `catalog.search_product` | ✅ |
| catalog | `catalog.create_product` | ❌ |
| inventory | `inventory.check_stock` | ✅ |
| inventory | `inventory.record_loss` | ❌ |
| inventory | `inventory.create_restock_request` | ❌ |
| transactions | `transactions.get_daily_summary` | ✅ |
| contacts | `contacts.search_customer` | ✅ |
| contacts | `contacts.check_balance` | ✅ |
| purchase_orders | `purchase_orders.create_order` | ❌ |
| reporting | `reporting.get_sales_report` | ✅ |
| reporting | `reporting.get_top_products` | ✅ |
| internal_requests | `internal_requests.list_pending` | ✅ |
| client_orders | `client_orders.list_in_progress` | ✅ |
| billing | `billing.get_current_plan` | ✅ |
| kernel | `rbac.list_users` | ✅ |

---

### 3.3 Functional Modules (Level 3)

#### 3.3.1 Retail Module (`vertical/retail`) — Current
Components: `retail/pos`, `retail/sessions`, `retail/stock`.
Status: Implemented (Epics 1–10, partially).
No structural changes for H1.

#### 3.3.2 Distribution Module (`vertical/distribution`) — H1 partial
Functional basis: `shared/client-orders` + `shared/inventory` + `shared/contacts`.
What distinguishes it from Retail: B2B order workflows, delivery notes, credit terms.
**H1 action:** Not a new module — the shared `ClientOrders` module + `distribution` business type configuration covers the Distribution use case. No new module code needed.

#### 3.3.3 Restauration Module (`vertical/restaurant`) — H2
Requires new tables: `Table`, `TableGroup`, `KitchenTicket`, `MenuComposition`.
Not in H1. Data model anticipation: add `itemType: 'service'` and `'bookable'` support to `CatalogItem` (already present).

#### 3.3.4 Services Module (`vertical/services`) — H2
Requires new tables: `Appointment`, `ServiceSlot`.
Not in H1. Data model anticipation: `Reservation` model already exists (FR99) — compatible.

---

### 3.4 Sectorial Templates (Level 4) — Architecture Definition

A **Sectorial Template** is a pure configuration bundle. It contains no code. It references:
1. A list of modules to activate (`TenantModule` records to create)
2. A `BusinessTypeDefinition` code (or new one to seed)
3. A SDUI `LayoutDefinition` reference
4. A set of `Role` + `Permission` + `RolePermission` seeds
5. A set of suggested categories to pre-create
6. A set of notification alert defaults

**What a template is NOT:**
- It does not generate Flutter screens
- It does not generate NestJS modules
- It does not contain business logic
- It does not require a code deployment to add a new template

**Template Builder** (H2): A UI allowing a superadmin or authorized integrator to compose a new template by configuring the above 5 elements. Output: a JSON config that seeds the DB. No code involved.

**H1 action:** Define the `SectorTemplate` data model now (see §4). Seed it with the `retail` and `distribution` templates using existing business type configs. Zero UI needed in H1.

---

### 3.5 Payment Adapter Pattern (New)

**Motivation:** Wave integration planned for H1 post-Blandine. Without an adapter, Wave logic goes into `PaymentsService` directly, making future payment providers (Orange Money, Moov Money, MTN, card) copy-paste additions.

**Interface (define in H1, implement Wave in H1):**

```typescript
interface PaymentAdapter {
  readonly provider: string;                     // 'cash' | 'wave' | 'orange_money' | ...
  readonly requiresOnlineVerification: boolean;  // false for cash, true for mobile money

  initiatePayment(params: {
    amount: Decimal;
    currency: string;
    reference: string;
    recipientPhone?: string;
  }): Promise<PaymentInitResult>;

  verifyPayment(reference: string): Promise<PaymentVerifyResult>;

  refund(reference: string, amount: Decimal): Promise<PaymentRefundResult>;
}
```

**Implementations:**
- `CashAdapter` — sync, no external call, always succeeds
- `WaveAdapter` (H1) — calls Wave API, async webhook verification
- `OrangeMoneyAdapter` (H2)

**Registry:** `PaymentAdapterRegistry` in `shared/payments` maps `paymentMethod` string to adapter instance. `PaymentsService` calls the registry, never a specific adapter directly.

**H1 action:** Create the interface + `CashAdapter` + `WaveAdapter` stub (can throw `NotImplementedError`). Wire `WaveAdapter` when Wave API integration is ready.

---

### 3.6 Compliance Framework (Pluggable) — Architecture Definition

**Motivation:** OHADA compliance (fiscal year, chart of accounts, SYSCOHADA reporting) must not be baked into core modules. France TVA, Sénégal DGI, other CEMAC rules are different plugins.

**Plugin interface (define in H1, implement OHADA plugin in H2):**

```typescript
interface CompliancePlugin {
  readonly jurisdiction: string;        // 'OHADA' | 'FR_TVA' | 'SN_DGI' | ...
  readonly requiredModules: string[];   // Modules this plugin hooks into

  onTransactionCreated(tx: Transaction): ComplianceAnnotation | null;
  onSessionClosed(session: PosSession): ComplianceSummary | null;
  generateFiscalReport(tenantId: string, period: DateRange): FiscalReport;
}
```

**Compliance Registry:** `ComplianceRegistry` in kernel. Each tenant has a `fiscalJurisdiction` field (already on Tenant). The registry resolves the active plugin by jurisdiction.

**H1 action:** Create the interface + a `NullCompliancePlugin` (no-op) that is the default for all tenants. OHADA plugin = H2. The `fiscalJurisdiction` field on Tenant already exists — no migration needed.

---

### 3.7 Client-Side Components (Flutter)

#### 3.7.1 Sync Engine — Unchanged from v1.6
Delta pull + outbox push + exponential backoff. Background isolate.

#### 3.7.2 Local Database (Isar) — Unchanged from v1.6
WAL, offline-first, data retention 30–90 days.

#### 3.7.3 AI Panel — New component (H2)
A dedicated Flutter widget, independently mounted alongside module screens. Never embedded inside existing screens.

Architecture:
```
AIPanel (Flutter widget)
  ├── AIInputBar (text input + voice input H3)
  ├── AIChatHistory (scroll list)
  ├── AIActionChips (top-20 cached actions, offline-servable)
  └── AIResponseCard (GenUI output: buttons, lists, cards)
```

**Offline behavior:** The AI panel is unavailable offline (no LLM without connectivity). The `AIActionChips` component caches the top-20 action chips locally in Isar. When offline, chips are shown but tapping one queues the action in the outbox rather than making an AI call — it executes directly against the local NestJS-defined action.

**Design principle (from design-thinking 2026-03-29, insight #6):** The AI has its space; the screens keep theirs. No conditional UI in module screens based on AI availability.

---

## 4. Data Models

### 4.1 Current Schema Summary

Three schemas in Prisma: `kernel`, `shared`, `retail`. All models from v1.6 are retained. The actual `schema.prisma` file is the authoritative source — the architecture document documents intent, the schema file documents reality. Where they conflict, the schema file wins.

**Divergences fixed in this document:**
- `AuditLog.userId` is nullable in the actual schema (correct — system events have no userId). Architecture v1 doc said NOT NULL incorrectly.

### 4.2 New Models Required (H1 additions)

#### 4.2.1 SectorTemplate (Kernel Schema)

```prisma
model SectorTemplate {
  id              String   @id @default(uuid()) @db.Uuid
  code            String   @unique            // 'retail_epicerie', 'pharmacie', 'restaurant', etc.
  name            String                      // "Épicerie & Alimentation"
  description     String?
  vertical        String                      // 'retail' | 'distribution' | 'restaurant' | 'services'

  // Module activation bundle: list of module codes to activate on deployment
  moduleBundle    String[]  @map("module_bundle")

  // Points to a BusinessTypeDefinition.code
  businessTypeCode String   @map("business_type_code")

  // Points to a LayoutDefinition.code (SDUI layout reference, nullable until Epic 10 complete)
  layoutCode      String?   @map("layout_code")

  // Seed data: default alert thresholds, notification defaults, etc.
  defaultConfig   Json      @default("{}") @map("default_config")

  // Who can use this template: 'system' | 'integrator' | 'public'
  visibility      String    @default("system")

  isActive        Boolean   @default(true) @map("is_active")
  createdAt       DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)

  @@map("sector_templates")
  @@schema("kernel")
}
```

**H1 seed data:** 2 templates: `retail_epicerie` (maps to Blandine use case) and `distribution_grossiste`.

#### 4.2.2 AIAction (AI Schema — define now, create schema in H2)

```prisma
// In 'ai' schema (add to datasource schemas in H2: schemas = ["kernel","shared","retail","ai"])

model AIAction {
  id               String   @id @default(uuid()) @db.Uuid
  code             String   @unique           // 'catalog.create_product'
  module           String                     // 'catalog'
  description      String                     // For LLM function calling description
  parametersSchema Json     @map("parameters_schema")  // JSON Schema
  requiredPermission String @map("required_permission") // 'catalog.edit'
  offlineCacheable Boolean  @default(false) @map("offline_cacheable")
  isActive         Boolean  @default(true) @map("is_active")
  createdAt        DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@map("ai_actions")
  @@schema("ai")
}

model AIConversation {
  id         String     @id @default(uuid()) @db.Uuid
  tenantId   String     @map("tenant_id") @db.Uuid
  userId     String     @map("user_id") @db.Uuid
  messages   Json                           // Array of {role, content, timestamp}
  context    Json       @default("{}")       // Active module, current screen, etc.
  createdAt  DateTime   @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt  DateTime   @updatedAt @map("updated_at") @db.Timestamptz(6)

  @@index([tenantId, userId])
  @@map("ai_conversations")
  @@schema("ai")
}
```

**H1 action:** Do NOT create the `ai` schema yet. Add it to architecture docs. Create when Python microservice is built (H2).

#### 4.2.3 Role — Tenant-scoped extension (H1 addition)

Add nullable `tenantId` to `Role` to support custom roles per tenant in H2 without a breaking migration:

```prisma
model Role {
  id          String               @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name        String
  vertical    String
  // NEW: null = system role (shared across tenants), set = custom role for specific tenant
  tenantId    String?              @map("tenant_id") @db.Uuid
  members     OrganizationMember[]
  permissions RolePermission[]

  @@unique([name, vertical, tenantId])  // Updated unique constraint
  @@map("roles")
  @@schema("kernel")
}
```

#### 4.2.4 PlanDefinition — Limits field (H1 addition)

```prisma
model PlanDefinition {
  // ... existing fields ...

  // NEW: Usage limits enforced by H2 middleware. Seeded now, not enforced until H2.
  limits Json @default("{}") @map("limits")
  // e.g. {"maxUsers":5,"maxTransactions":500,"maxProducts":200,"maxStorageMb":500,"historyMonths":6}
}
```

### 4.3 RBAC Dynamic Migration Path

**Today (H1):** `roleScreenAccess` on `BusinessTypeDefinition.roleScreenAccess Json` — maps role codes to screen arrays. Drives `BusinessTypeService.getScreensForRole(businessType, role)`. Acceptable for H1. Documented as debt.

**H2 target (non-breaking migration):**
```prisma
model RoleScreenAccess {
  id          String   @id @default(uuid()) @db.Uuid
  roleId      String   @map("role_id") @db.Uuid
  screen      String   // 'pos', 'stock', 'losses', 'orders', etc.
  tenantId    String?  @map("tenant_id") @db.Uuid  // null = system default
  isVisible   Boolean  @default(true) @map("is_visible")
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  role        Role     @relation(fields: [roleId], references: [id])

  @@unique([roleId, screen, tenantId])
  @@map("role_screen_access")
  @@schema("kernel")
}
```

**Migration script:** Read `BusinessTypeDefinition.roleScreenAccess` JSON → insert into `RoleScreenAccess` for each role × screen combination → keep JSON field in parallel for 1 sprint → remove JSON field when API consumers are migrated.

### 4.4 Schema Compatibility Assessment

| Current model | Compatible with new vision? | Notes |
|---|---|---|
| `Tenant` with `vertical`, `businessType`, `orgMode`, `parentTenantId` | ✅ Full | All Phase 3 anticipation fields still valid |
| `BusinessTypeDefinition` with `vertical`, `roleLabels`, `documentType` | ✅ Full | Will link to SectorTemplate in H2 |
| `BusinessTypeDefinition.roleScreenAccess` Json | ⚠️ Debt | Works in H1, migrate to `RoleScreenAccess` in H2 |
| `Role` with `vertical`, no `tenantId` | ⚠️ Add | Add nullable `tenantId` in H1 |
| `Module` + `TenantModule` | ✅ Full | Templates reference module codes to activate |
| `PlanDefinition` without `limits` | ⚠️ Add | Add `limits Json` field in H1 |
| All shared models (CatalogItem, Transaction, etc.) | ✅ Full | Compatible with all sectors |
| `CatalogItem.itemType` ('physical'|'bookable'|'service') | ✅ Full | Supports restaurant and services sectors |
| `Transaction.lifecycleType` ('instant'|'accumulating'|'scheduled') | ✅ Full | Covers services and restaurant billing models |
| `Reservation` (FR99) | ✅ Full | Services sector appointments are reservations |
| Retail schema (RetailProduct, RetailSale, PosSession) | ✅ Full | Vertical extension pattern holds |

---

## 5. API Design

### 5.1 Existing API Architecture (Unchanged)

| Aspect | Decision |
|---|---|
| Style | REST (JSON) |
| Versioning | URL path: `/api/v1/...` |
| Authentication | Bearer JWT (Supabase Auth) |
| Tenant Context | `x-tenant-id` header |
| Response Format | `{ data: T, meta?: { page, limit, total } }` |
| Error Format | `{ statusCode, message, error }` |
| Delta Sync | `?since=<ISO8601>` |

### 5.2 New Endpoints — AI (H2)

```
# AI Chat (proxied by NestJS → Python microservice)
POST   /api/v1/ai/chat
Body:  { message: string, context: { screen, moduleOpen, tenantId } }
Response: { response: string, actions?: AIActionSuggestion[], uiComponents?: GenUIComponent[] }

# AI Action execution
POST   /api/v1/ai/actions/:actionCode
Body:  { parameters: Record<string, unknown> }
Response: { result: unknown, executedAt: DateTime }

# AI Actions catalog (for Flutter offline cache)
GET    /api/v1/ai/actions
Response: { data: AIAction[] }  -- cacheable, long TTL

# AI Action chips (top-20, cacheable offline)
GET    /api/v1/ai/actions/chips
Response: { data: AIAction[] }  -- ordered by usage frequency
```

**Security:** All AI endpoints respect tenant isolation. The Python microservice NEVER has direct DB access — it calls NestJS action executors. Tenant ID is always propagated from the original JWT.

**Offline behavior:** `/api/v1/ai/chat` and `/api/v1/ai/actions` are unavailable offline. `/api/v1/ai/actions/chips` response is cached in Isar with a 24h TTL.

### 5.3 New Endpoints — Template Builder (H2)

```
# List available templates
GET    /api/v1/templates
Response: { data: SectorTemplate[] }

# Get a specific template's full config
GET    /api/v1/templates/:code
Response: { data: SectorTemplate }

# Apply a template to a tenant (superadmin or integrator)
POST   /api/v1/tenants/:id/apply-template
Body:  { templateCode: string, overrides?: Partial<SectorTemplate> }
Response: { data: { activatedModules: string[], seedsApplied: string[] } }

# Create/update a custom template (authorized integrators in H3)
POST   /api/v1/templates
PATCH  /api/v1/templates/:code
DELETE /api/v1/templates/:code
```

### 5.4 API i18n versioning

**H1 rule:** All user-facing error messages and labels from the API must use i18n keys, not hardcoded French strings. Pattern:

```typescript
// Bad (don't do this):
throw new BadRequestException('Le stock est insuffisant');

// Good:
throw new BadRequestException({
  key: 'error.inventory.insufficient_stock',
  params: { productName: item.name, available: stock }
});
```

The Flutter client resolves the key against its local i18n bundle. The backend returns the key. No translation on the backend in H1. Full i18n infrastructure (multi-language backend responses) is H2.

### 5.5 Full Endpoint Catalog (v1 + new)

All v1.6 endpoints are retained. New additions:

```
# Templates
GET    /api/v1/templates
GET    /api/v1/templates/:code
POST   /api/v1/tenants/:id/apply-template

# AI (H2)
POST   /api/v1/ai/chat
POST   /api/v1/ai/actions/:actionCode
GET    /api/v1/ai/actions
GET    /api/v1/ai/actions/chips

# RBAC Dynamic (H2)
GET    /api/v1/roles
POST   /api/v1/roles           -- create custom role (owner only)
PATCH  /api/v1/roles/:id
GET    /api/v1/roles/:id/screen-access
PATCH  /api/v1/roles/:id/screen-access

# Compliance (H2)
GET    /api/v1/compliance/reports/:period
POST   /api/v1/compliance/exports/:format   -- OHADA/SYSCOHADA export
```

---

## 6. AI Architecture

### 6.1 Design Principle

> **AI is the universal interface layer — not a feature injected into modules.**

Every configurable action in Scalario must be reachable via AI. Every screen that exists must exist independently of AI. The AI panel is a dedicated section, like a side panel or command bar, that users open intentionally.

Sources: Innovation Strategy 2026-03-29 (PRINCIPE ARCHITECTURAL AI), Design Thinking 2026-03-29 (insight #6).

### 6.2 Separation of Concerns

```
Module Screens (Core)          AI Panel (Dedicated)
──────────────────────         ────────────────────
- Predictable UI               - Generative UI (GenUI)
- Works offline                - Requires connectivity
- No AI elements               - Can invoke module actions
- Always the same              - Context-aware
- Trusted by cashiers          - Used by owners/managers
```

Screens never degrade based on AI availability. AI panel never owns business logic — it calls module actions.

### 6.3 Python Microservice Architecture

**Why Python, not NestJS:**
- LLM SDK ecosystem is Python-first (Anthropic, OpenAI, Langchain, function calling)
- AI/ML libraries (numpy, pandas, scikit-learn for H3 analytics) are Python
- Isolation: AI service failures do not affect the core NestJS API
- Independent deployment and scaling

**Communication pattern:**
```
Flutter Client
    ↓ HTTPS
NestJS /api/v1/ai/*
    ↓ Internal HTTP (localhost:8001)
Python FastAPI AI Service
    ↓ Function calling
NestJS /api/v1/ai/actions/:code (action executor)
    ↓
Module service (e.g. CatalogService.createProduct)
    ↓
PostgreSQL
```

**The Python service NEVER touches PostgreSQL directly.** All data access is via NestJS action executors. Tenant isolation is guaranteed by always passing `tenantId` from the original JWT through every hop.

### 6.4 Function Calling Pattern

Each AI-invocable action is a NestJS endpoint `POST /api/v1/ai/actions/:code` protected by:
1. JWT auth (same as all endpoints)
2. Permission check (the action's `requiredPermission`)
3. Tenant guard

The Python service receives the user's message and the current context (tenant, user role, active module), calls the LLM with the registered action catalog as tools, and when the LLM returns a tool call, it POSTs to the NestJS action executor.

```python
# Python FastAPI — simplified
@app.post("/chat")
async def chat(request: ChatRequest, tenant_id: str, user_token: str):
    tools = await get_ai_actions_catalog(tenant_id)  # GET /api/v1/ai/actions

    response = claude.messages.create(
        model="claude-opus-4-6",
        system=build_system_prompt(request.context),
        messages=request.conversation_history,
        tools=tools  # Actions from catalog
    )

    if response.stop_reason == "tool_use":
        action_result = await execute_action(
            action_code=response.tool_use.name,
            params=response.tool_use.input,
            token=user_token  # Forward original JWT
        )
        return build_response_with_action_result(action_result)

    return ChatResponse(response=response.content)
```

### 6.5 Offline Action Chips

The top-20 most-used AI actions are pre-computed as `AIActionChip` records and cached in Isar with 24h TTL.

When offline, the chip UI is shown but tapping executes the action directly via the local queue (not via AI), with a notification that "AI is unavailable but action was queued."

**Cache invalidation:** When connectivity is restored, chips are refreshed from `GET /api/v1/ai/actions/chips`.

**Personalization (H3):** Chips are reordered by the user's actual usage patterns, computed by the Python service.

### 6.6 H1 Actions (Define interfaces, no implementation)

**H1 deliverable:** The `AiActionsManifest` interface and `AIActionRegistry` class in NestJS. Each module registers its manifest at bootstrap. No Python service. No LLM calls.

**Rationale:** Defining the interfaces now means H2 Python microservice integration requires zero changes to module code — it just reads the registry. If we skip this in H1, H2 becomes a cross-cutting refactor of all modules simultaneously.

---

## 7. Flywheel Architecture

### 7.1 The Core Insight

> One core module deployed → unlocks N sectors via template configuration.

Every new sector added without new module code = compounding returns on existing infrastructure investment.

```
Carlos builds:           Unlocks (via template config):
──────────────           ──────────────────────────────
Catalog module      →    Retail, Restaurant (menu), Services (offerings), Artisan (materials)
Transactions        →    All sectors (every business records income)
Inventory           →    Retail, Restaurant (ingredients), Artisan (materials), Distribution
Contacts            →    All sectors (every business has clients)
Appointments        →    Services, Healthcare, Hospitality
(H2 module)
Document Mgmt       →    Legal, Notary, HR, Administration
(H3 module)
Payroll module      →    All sectors with employees
(H3 module)
```

### 7.2 Flywheel Diagram

```
    Build Core Module
          ↓
    Register AI Actions
          ↓
    Create Sector Template
    (config, no code)
          ↓
    New sector addressable
    (Integrators deploy)
          ↓
    More clients in sector
          ↓
    AI learns sector patterns
          ↓
    AI Configuration Wizard
    improves for that sector
          ↓
    Integrators deploy faster
          ↓
    → More clients → more revenue → fund next core module
          ↑_________________________________________________|
```

### 7.3 Template Marketplace (H3)

At scale (H3), integrators build and publish their own templates:
- SDK: A `TemplateBuilder` CLI that validates config before submission
- Marketplace: `GET /api/v1/marketplace/templates` — community templates
- Review: Carlos team reviews templates before publishing (quality gate)
- Revenue: 20-30% commission on templates sold in marketplace

**H1 architecture implication:** The `SectorTemplate.visibility` field (`'system'|'integrator'|'public'`) anticipates this. H1 = only `'system'` templates. H3 = all visibility levels.

### 7.4 Sector Roadmap (Template-driven)

| Phase | Sectors | Template strategy | Core modules needed |
|---|---|---|---|
| H1 (now) | Retail, Distribution | Business type configs → seed into SectorTemplate | Existing modules |
| H2 (12m) | Restaurant, Services | New SectorTemplate + restaurant/services functional modules | + Appointments module |
| H3 (36m) | Healthcare, Artisan, Legal | Templates only — no new modules if core is sufficient | TBD per audit |
| H4 | Education, NGO, Mining, Agriculture | Templates + sector-specific compliance plugins | + per-sector plugins |

---

## 8. ADRs — Architectural Decision Records

### ADR-001: Template Builder = Configuration, Not Code Generation

**Date:** 2026-03-31
**Status:** Accepted

**Context:** To support N sectors without N codebases, we need a mechanism for adding new sector support. Options: (A) Generate Flutter/NestJS code per sector. (B) Pure configuration bundles.

**Decision:** Option B. A SectorTemplate is a JSON configuration record in the DB. It references existing modules, roles, screens, and layout configs. No code is generated. No deployment is needed to add a new template.

**Consequences:** Each new sector requires that the necessary modules already exist. A restaurant sector template cannot exist if there is no table management module. This means module development is still needed for genuinely new functionality — but the "last mile" of sector deployment is configuration, not code.

**Why not A:** Code generation creates maintenance debt. Generated code diverges from the source template. Flutter codegen for multi-platform is fragile. Config is reversible; generated code is not.

---

### ADR-002: AI = Dedicated Section, Not Injected Into Module Screens

**Date:** 2026-03-31
**Status:** Accepted

**Context:** Multiple patterns for AI integration: (A) inject AI buttons into each screen. (B) AI sidebar/panel separate from module screens.

**Decision:** Option B. The AI panel is a dedicated Flutter widget, separately accessible. Module screens contain zero AI-conditional UI elements. A user on the POS screen sees the same UI whether AI is available or not.

**Consequences:** AI cannot proactively surface suggestions within module screens. Users must intentionally open the AI panel. This reduces "magic" moments but prevents screen complexity and eliminates UX debt when AI is unavailable.

**Why not A:** Injecting AI into screens creates conditional UI that degrades when AI is offline. Cashiers working in low-connectivity environments must trust their screens unconditionally. Mixing AI availability into core screens violates the offline-first contract.

---

### ADR-003: Python Microservice for AI — Separation from NestJS Day 1

**Date:** 2026-03-31
**Status:** Accepted

**Context:** AI capabilities could be added as a NestJS module (same process) or as a separate Python service. The v1 architecture anticipated a future "AI Service Layer" as a separate process.

**Decision:** Python/FastAPI microservice, separate from NestJS. Internal communication via REST (NestJS calls Python; Python calls NestJS action executors). Python service has zero direct DB access.

**Consequences:** Additional operational complexity (two processes to deploy). Requires defining the internal API contract now (H1) even if H2 implementation.

**Why not NestJS module:** Python LLM SDKs (Anthropic, OpenAI), ML libraries (H3 analytics), and the AI/data science ecosystem are overwhelmingly Python-first. Building AI in TypeScript would be swimming against the current. The isolation also means AI failures cannot cascade into the core API.

---

### ADR-004: Payment Adapter Pattern — Wave = Adapter, Not Integration

**Date:** 2026-03-31
**Status:** Accepted

**Context:** Wave integration for H1. Options: (A) Direct Wave API calls in PaymentsService. (B) Abstract PaymentAdapter interface + WaveAdapter implementation.

**Decision:** Option B. `PaymentAdapter` interface defined in H1. `CashAdapter` and `WaveAdapter` are first implementations.

**Consequences:** More initial code for the same Wave outcome. Every future payment provider (OrangeMoneyAdapter, MoovAdapter, etc.) follows the same pattern at zero architectural cost.

**Why not A:** Option A is faster for H1 but creates coupling that is extremely painful to refactor once Wave is live and clients depend on it. The adapter interface is 2 hours of work. Removing hardcoded Wave coupling from a live system is days of careful migration.

---

### ADR-005: OHADA = Compliance Plugin, Not Core Code

**Date:** 2026-03-31
**Status:** Accepted

**Context:** OHADA compliance requirements for UEMOA markets. Options: (A) Hardcode OHADA logic into Transaction and Reporting modules. (B) Pluggable `CompliancePlugin` interface.

**Decision:** Option B. `CompliancePlugin` interface in kernel. `NullCompliancePlugin` (no-op) is default. `OhadaPlugin` is H2.

**Consequences:** H1 has no OHADA compliance — acceptable since first clients (Blandine, standard retailers) do not require it. H2 OHADA plugin can be added without touching core modules.

**Why not A:** OHADA is specific to 8 CEMAC/OHADA countries. France TVA, Sénégal DGI, and future jurisdictions have different rules. Baking OHADA into core means the codebase assumes OHADA everywhere, blocking international expansion and polluting non-OHADA tenant data flows.

---

### ADR-006: RBAC is Data-Driven (Roles in DB, Never Hardcoded in TypeScript)

**Date:** 2026-03-31
**Status:** Accepted (extends v1 decision)

**Context:** v1 established roles in DB. v1.6 added `roleScreenAccess` JSON on `BusinessTypeDefinition`. This is a partial violation of the data-driven principle.

**Decision:** All role-to-screen-access mappings must live in DB rows, not in JSON fields or TypeScript enums. The `roleScreenAccess` JSON field is acknowledged as H1 technical debt and will be migrated to a `RoleScreenAccess` table in H2.

**H1 rule:** No new screen access logic may be added to `roleScreenAccess` JSON that cannot be expressed as a future `RoleScreenAccess` row. If adding new screens in H1, add the access config to the existing JSON AND document the corresponding future `RoleScreenAccess` row.

---

### ADR-007: i18n Complete from Today — No Hardcoded User-Facing Strings

**Date:** 2026-03-31
**Status:** Accepted

**Context:** All current user-facing strings in Flutter and NestJS are hardcoded in French. Moving to multi-language requires finding and extracting every string.

**Decision:** No new hardcoded user-facing strings after today. All new API error messages use i18n keys. All new Flutter UI strings use the localization system. Existing strings are not retroactively migrated in H1 — only net-new strings follow the rule.

**Full i18n infrastructure** (multi-language support, language selector, backend language resolution) is an H2 deliverable.

**Consequences:** Some inconsistency between old (hardcoded) and new (i18n key) strings in H1. Acceptable — the boundary is "new code written after 2026-03-31."

---

### ADR-008: Self-Hosted Supabase — Already Done, Maintain as Default

**Date:** 2026-03-31
**Status:** Accepted (reaffirmed)

**Context:** Architecture v1 already specified self-hosted Supabase. This is reaffirmed in Innovation Strategy as critical before enterprise clients demand it.

**Decision:** Self-hosted Supabase is the only deployment target. Supabase Cloud is not used for production. This decision is already implemented.

**Impact on future:** Enterprise clients requiring data sovereignty will have a pre-existing answer. The operational overhead of self-hosting is already accepted and managed.

---

### ADR-009: Modular Monolith Remains Correct for H1–H2

**Date:** 2026-03-31
**Status:** Accepted

**Context:** The Innovation Strategy mentions a "trajectoire microservices" NFR40. Should we start microservices extraction now?

**Decision:** No. Modular monolith (NestJS DynamicModules) is the right architecture for H1–H2. The only exception is the Python AI microservice (ADR-003), which is justified by the LLM SDK ecosystem, not by scaling.

**H2 microservices review gate:** At 50+ tenants or when a specific module shows independent scaling need (e.g., Reporting queries slow down the API), revisit. Until then, module boundaries in the monolith are the preparation work that makes future extraction clean.

---

### ADR-010: Single Flutter App, N Sectors via Configuration (UI-Driven Architecture)

**Date:** 2026-03-31
**Status:** Accepted (reaffirmed from v1)

**Context:** Could we generate separate Flutter apps per sector? Or have separate app builds per client?

**Decision:** One Flutter app binary. SDUI (Epic 10) + Template config drives which screens are visible, what labels are shown, and which modules are accessible. No app build per client.

**Consequences:** Every feature ships to every user. Module Guard controls what is accessible. App size grows with all features, but only relevant screens are shown.

**Why not separate builds:** Solo developer. CI/CD for N builds × M platforms is operationally unsustainable. Apple App Store and Play Store review delays make per-client builds impossible.

---

### ADR-011: Document State Machine — Workflow Engine Pattern

**Date:** 2026-04-01
**Status:** Accepted — Architecture H1, Implementation V2

**Context:** Business documents (ticket, invoice, order, inventory session, delivery note) currently have ad-hoc lifecycle states per module. As client complexity grows (ticket → normalized invoice, order → delivery note → invoice, multi-step inventory with SOD), hardcoded per-module state logic becomes unmaintainable. Observed in enterprise ERP review: document workflows vary per client — same document type, different transition rules.

**Decision:** Every business document has a `type`, a `state`, and allowed `transitions` — evaluated server-side against the current user's capabilities. Flutter renders action buttons from the transitions array returned by the backend. No permission logic client-side. WorkflowStep ownership (FR-WORKFLOW-02) enables SOD: the person who creates a session ≠ the person who executes ≠ the person who validates.

**Consequences:**

- New `WorkflowDefinition` and `WorkflowStep` tables required (V2 schema addition)
- Document state transitions become a backend responsibility (NestJS service), never Flutter
- SDUI action buttons are rendered from `allowedTransitions[]` — consistent with existing SDUI pattern
- Enables any client workflow complexity via template configuration, not custom code

**Why not now (H1):** The current 3 clients have simple enough workflows. The architecture must not block this extension — it must not hardcode transitions in Flutter or in business logic that bypasses a state check.

---

### ADR-012: SDUI Capability Filtering — Permissions Down to Widget Level

**Date:** 2026-04-01
**Status:** Accepted — Architecture H1, Implementation V2

**Context:** Enterprise clients require permissions granular to the button and widget level — not just module access. Observed: same screen, different users see different actions based on individual permissions. RBAC per role is insufficient; permission must propagate to every rendered component.

**Decision:** Every SDUI layout component carries an optional `requires: "capability.code"` field. The backend filters the layout JSON before sending to the client, silently removing components whose capability the current user lacks. Flutter never receives components it cannot render. Fundamental rule: SDUI = presentation layer only. Business logic, permission evaluation, and state transitions stay in NestJS.

**Consequences:**

- Backend layout serialization adds a capability filter pass before response
- Flutter rendering logic unchanged — it renders what it receives
- Permission changes are immediate server-side — no app update required
- Enables per-user UI customization without custom Flutter code

**Why this matters for Scalario's vision:** A Template Sectoriel can define which capabilities are required for each widget. An integrator can create a "Pharmacist" role that sees dispensing actions but not pricing override buttons — without writing Flutter code.

---

### ADR-013: RBAC → ABAC Evolution Trajectory

**Date:** 2026-04-01
**Status:** Accepted — Trajectory documented, ABAC Phase 3+

**Context:** Current FR-RBAC-01 (capability-based RBAC per tenant, Phase 2b) covers PME needs. Enterprise clients and regulated sectors require conditions on permissions: amount thresholds, department scope, document state, time-of-day, geographic zone. This is ABAC (Attribute-Based Access Control).

**Decision:** The RBAC → ABAC evolution is planned in 4 stages. The current architecture does not block this evolution — the `permissions` table accepts optional condition columns additive to the existing schema.

| Stage | Model | Horizon | Coverage |
|---|---|---|---|
| 1 | Dynamic RBAC (capability codes per tenant) | Phase 2b | PME standard |
| 2 | RBAC + SOD (WorkflowStep ownership) | V2 | Multi-actor workflows |
| 3 | ABAC simplified (conditions: department, amount) | Phase 3 | Enterprise multi-department |
| 4 | ABAC full (contextual conditions: state, time, zone) | Phase 4+ | Large enterprise, regulated sectors |

**Consequences:** No rework required at Phase 2b. Stage 3 adds optional `conditions JSONB` column to permissions table. Guard evaluation adds condition check when column is non-null. Fully additive, non-breaking.

---

## 9. Migration Path v1 → v2

### 9.1 What Is Already v2

The codebase is already partially v2:
- Multi-schema Prisma (kernel/shared/retail) ✅
- BusinessTypeDefinition config pattern ✅
- Billing module ✅
- RBAC in DB ✅
- Phase 3 anticipation fields ✅

No migration needed for these. Architecture v2 is primarily an **extension** of v1, not a replacement.

### 9.2 H1 Migrations Required (Non-Breaking)

These are additive changes only. No existing data is affected.

| Migration | Type | Impact | Script needed? |
|---|---|---|---|
| Add `SectorTemplate` table | New table | None | Yes — create table + seed 2 templates |
| Add `Role.tenantId` nullable | New nullable column | None | Yes — `ALTER TABLE kernel.roles ADD COLUMN tenant_id UUID` |
| Add `PlanDefinition.limits` Json | New column with default | None | Yes — `ALTER TABLE kernel.plan_definitions ADD COLUMN limits JSONB DEFAULT '{}'` |
| Add `AiActionsManifest` TypeScript interface | New TS file | None | No — just add file |
| Add `PaymentAdapter` interface + `CashAdapter` | New TS files | None | No — just add files |
| Add `CompliancePlugin` interface + `NullCompliancePlugin` | New TS files | None | No — just add files |

### 9.3 H2 Migrations (Breaking — Plan Carefully)

| Migration | Complexity | Breaking? | Strategy |
|---|---|---|---|
| `RoleScreenAccess` table (replaces JSON field) | Medium | Soft-breaking (JSON field removal) | Dual-write period: write to both JSON and table for 1 sprint. Remove JSON field after consumers migrated. |
| Add `ai` schema to Prisma | Low | None | Add to `schemas` array. Deploy Python service. |
| Add `tenantLanguage` to Tenant | Low | None | New nullable column, default `'fr'` |

### 9.4 What NOT to Migrate (Avoid These Pitfalls)

1. **Do not migrate `BusinessTypeDefinition` to `SectorTemplate` yet.** They coexist in H1/H2. A `SectorTemplate` REFERENCES a `BusinessTypeDefinition.code`. They are not the same model.

2. **Do not remove `roleScreenAccess` JSON until the `RoleScreenAccess` table is fully seeded and all guard code has been migrated.** This is a dual-write → read new → remove old pattern.

3. **Do not merge the `retail` schema into `shared`.** The extension pattern (CatalogItem → RetailProduct) must remain clean for future vertical schemas (restaurant, services).

---

## 10. What to Build When

### 10.1 H1 — Now (0–12 months)

**Goal:** First paying client (Blandine), 10 clients by month 12, revenue positive.

**Architecture work this week (blockers for Blandine demo):**
- Zero architecture changes needed for Blandine demo. All required features are in the existing schema.

**Architecture work H1 (non-blocking for demo, blocking for H2):**

| Task | Priority | Effort | Blocks |
|---|---|---|---|
| Define `PaymentAdapter` interface + `CashAdapter` | High | 2h | Wave integration (H1 feature) |
| Define `CompliancePlugin` interface + `NullCompliancePlugin` | High | 1h | OHADA plugin (H2) |
| Define `AiActionsManifest` + `AIActionRegistry` in NestJS | High | 3h | Python microservice (H2) |
| Add `SectorTemplate` model + migration + seed 2 templates | Medium | 4h | Template Builder UI (H2) |
| Add `Role.tenantId` nullable + migration | Medium | 1h | Custom roles per tenant (H2) |
| Add `PlanDefinition.limits` Json + migration | Low | 1h | Usage limits enforcement (H2) |
| Establish i18n key pattern for new API errors | Low | 2h | Multi-language (H2) |

**Architecture work H1 — strictly deferred (do NOT start):**
- Python microservice implementation (no LLM calls in H1)
- `RoleScreenAccess` table migration
- `ai` Prisma schema
- Template Builder UI
- Compliance OHADA plugin

**Product features H1 (already defined in sprint plan):**
- Wave & Orange Money integration → implement using `WaveAdapter` pattern
- WhatsApp Business API (Blandine daily summary) → implement in Notification module
- Self-Demo Mode (pre-loaded data) → configuration, not architecture

### 10.2 H2 — 12–36 months

**Gate:** 5 paying clients + core product stable on 3 real use cases (PRD Gate 5).

| Feature | Architecture dependencies from H1 |
|---|---|
| Python AI microservice + LLM chat panel | `AiActionsManifest` interface must be defined in H1 |
| AI Configuration Wizard | AI microservice + all modules with registered actions |
| AI Excel/CSV import | AI microservice + Catalog module AI actions |
| Template Builder UI | `SectorTemplate` model must exist from H1 |
| RBAC Dynamic per tenant | `Role.tenantId` nullable must exist from H1 |
| OHADA compliance plugin | `CompliancePlugin` interface from H1 |
| Wave payment full integration | `PaymentAdapter` interface from H1 |
| Orange Money adapter | `PaymentAdapter` interface from H1 |
| Restaurant sector | Requires new: Tables, KitchenTicket, MenuComposition models |
| Services sector | Requires new: Appointment, ServiceSlot models |
| Multi-language (i18n full) | Requires i18n key discipline from H1 |
| Usage limits enforcement | `PlanDefinition.limits` field must exist from H1 |

### 10.3 H3 — 36+ months

| Feature | Architecture dependencies from H2 |
|---|---|
| AI Advanced Analytics | Python AI microservice + 50+ active tenants for training data |
| B2B Canal Inter-Entreprises (Scalario Connect) | `networkVisible`, `linkedTenantId` fields already anticipate this |
| Template Marketplace | `SectorTemplate.visibility = 'integrator'/'public'` + SDK |
| Auto fiscal reporting (TVA, SYSCOHADA) | Compliance plugin framework from H2 |
| White-label / OEM | Tenant config + billing model, no new architecture |
| Multi-language local (Mooré, Dioula, Wolof) | i18n full infrastructure from H2 |
| Network Intelligence (cross-tenant anonymous analytics) | Strict opt-in required. Python data service (separate from AI service). Zero individual data shared. |

### 10.4 Irreversible Decisions — Lock These In H1

These decisions, if not made in H1, become significantly more expensive to implement later:

| Decision | Why Irreversible After H1 |
|---|---|
| `/api/v1/` prefix on all endpoints | Clients (Flutter + integrators) will hardcode this. Changing breaks everything. **Already done.** |
| UUID primary keys everywhere | Sync protocol depends on UUIDs for idempotent push. Changing to sequential IDs breaks the offline outbox. **Already done.** |
| `PaymentAdapter` interface before Wave | Once Wave is live with clients, removing direct coupling requires testing against live transactions. Define first. |
| `AiActionsManifest` interface before AI | Once 20+ modules exist and none have a registered manifest, H2 becomes a massive cross-cutting refactor. Define first. |
| `tenantId` nullable on `Role` | Once 50+ tenants have roles assigned, migrating the unique constraint is a data migration with production risk. Add nullable field now. |
| i18n key discipline for new strings | Once 500 new strings are hardcoded, the migration to i18n is 3+ days of search-and-replace. The discipline costs nothing in H1. |

### 10.5 Decisions That Can Be Deferred Without Technical Debt

| Decision | Why Deferrable |
|---|---|
| `RoleScreenAccess` table migration | JSON field works correctly for H1 fixed roles. Data model is documented. |
| `ai` Prisma schema | No Python service in H1. Just an empty declaration. |
| Template Builder UI | Templates are seeded via migration scripts in H1. UI is a convenience, not a blocker. |
| OHADA compliance plugin | No client requires OHADA compliance in H1. `NullCompliancePlugin` is sufficient. |
| Restaurant/Services functional modules | No H1 client in these sectors. Template config cannot enable what doesn't exist. |
| Multi-language full infrastructure | All H1 clients are French-speaking UEMOA. |

---

*End of Architecture Document v2.0*

*Next review scheduled when: H2 AI microservice is ready to begin, or at Gate 3 (5 paying clients), whichever comes first.*
