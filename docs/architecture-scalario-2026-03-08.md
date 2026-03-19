# Architecture Document — Scalario ERP

**Author:** Carlos-simpore
**Date:** 2026-03-19
**Version:** 1.1
**Status:** Approved
**PRD Reference:** `_bmad-output/planning-artifacts/prd.md`

**Revision History:**
| Version | Date | Changes |
|:---|:---|:---|
| 1.0 | 2026-03-08 | Initial architecture document (FR1–FR75) |
| 1.1 | 2026-03-19 | FR76–FR91: unit types, weight sales, variants, multi-tarifs, promotions, purchase orders, internal requests, freshness batches, loss location, notification config |

---

## Table of Contents

1. [Architectural Drivers](#1-architectural-drivers)
2. [High-Level Architecture](#2-high-level-architecture)
3. [Technology Stack](#3-technology-stack)
4. [System Components](#4-system-components)
5. [Data Architecture](#5-data-architecture)
6. [API Design](#6-api-design)
7. [NFR Coverage](#7-nfr-coverage)
8. [Security Architecture](#8-security-architecture)
9. [Scalability & Performance](#9-scalability--performance)
10. [Reliability & Availability](#10-reliability--availability)
11. [Development & Deployment](#11-development--deployment)
12. [FR Traceability](#12-fr-traceability)
13. [NFR Traceability](#13-nfr-traceability)
14. [Trade-offs & Decisions](#14-trade-offs--decisions)
15. [Migration Strategy](#15-migration-strategy)

---

## 1. Architectural Drivers

These NFRs have the highest impact on architectural decisions. They are ordered by priority.

| Priority | Driver | NFR Source | Architectural Impact |
|:---|:---|:---|:---|
| **#1** | **Offline-First Operations** | NFR14, NFR15, NFR30 | Local-first data model, WAL crash recovery, sync engine in background isolate, outbox pattern for all mutations |
| **#2** | **Tenant Data Isolation** | NFR8 | `tenant_id` on every entity, Supabase RLS defense-in-depth, schema-level logical separation |
| **#3** | **Low-Bandwidth Sync** | NFR3, NFR24, NFR25, NFR26 | Delta-only sync, compressed payloads, exponential backoff, 2G/3G compatible design |
| **#4** | **Financial Data Integrity** | NFR13, NFR18 | Atomic local writes, WAL, immutable audit trail, no partial transaction states |
| **#5** | **Low-End Device Performance** | NFR1, NFR2, NFR4, NFR6, NFR7 | <150MB RAM, <500MB storage, <500ms grid render, <200ms transaction write |
| **#6** | **Modular Architecture** | FR7-FR10, FR56-FR58 | Three-tier kernel/shared/vertical, Prisma multi-schema, module registry |
| **#7** | **RBAC & Anti-Fraud** | NFR12, FR3, FR50 | Fixed roles MVP, permission table architecture, chain-of-custody audit trail |
| **#8** | **Multi-Phase Product Expansion** | FR52-FR55, FR59-FR75 | DB anticipation fields for Connect (Phase 3) and Enterprise (Phase 3) seeded in Phase 1 (Story 1.6) — org_mode, department_ids, linked_tenant_id, supplier_reference. Zero breaking migration at Phase 3 launch. |

---

## 2. High-Level Architecture

### Pattern: Modular Monolith with Offline-First Client

**Why Modular Monolith (not Microservices):**
- Solo developer — operational complexity of microservices is unjustifiable
- 30 tenants / 10 users per tenant — no scaling driver for independent service deployment
- Module boundaries are being discovered during restructuring — premature service extraction risks wrong boundaries
- NestJS dynamic modules provide clean isolation without deployment overhead
- Can extract to microservices later if scaling demands it (unlikely in 12-month horizon)

**Architecture Tiers:**

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT (Offline-First)             │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │  Isar   │  │  Sync    │  │ Realtime │  │   UI Layer   │  │
│  │  (WAL)  │  │  Engine  │  │ Service  │  │  (Riverpod)  │  │
│  │  Local  │  │ (Isolate)│  │(Supabase)│  │              │  │
│  │  DB     │  │          │  │          │  │              │  │
│  └────┬────┘  └────┬─────┘  └────┬─────┘  └──────────────┘  │
│       │            │              │                           │
│       └────────────┴──────────────┘                           │
│                    │ HTTPS (Delta Sync)                       │
└────────────────────┼─────────────────────────────────────────┘
                     │
┌────────────────────┼─────────────────────────────────────────┐
│              NestJS BACKEND (Modular Monolith)               │
│                    │                                         │
│  ┌─────────────────┴───────────────────────────────────┐     │
│  │                 API Gateway Layer                    │     │
│  │        (AuthGuard + TenantGuard + ModuleGuard)      │     │
│  └─────────────────┬───────────────────────────────────┘     │
│                    │                                         │
│  ┌─────────────────┴───────────────────────────────────┐     │
│  │                   KERNEL                             │     │
│  │  ┌──────┐ ┌────────┐ ┌──────┐ ┌─────┐ ┌─────────┐  │     │
│  │  │ Auth │ │Tenancy │ │ RBAC │ │Event│ │ Module  │  │     │
│  │  │      │ │        │ │      │ │ Bus │ │Registry │  │     │
│  │  └──────┘ └────────┘ └──────┘ └─────┘ └─────────┘  │     │
│  └─────────────────┬───────────────────────────────────┘     │
│                    │                                         │
│  ┌─────────────────┴───────────────────────────────────┐     │
│  │              SHARED MODULES                          │     │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌────────┐  │     │
│  │  │ Catalog │ │Transactions│ │ Inventory │ │Payments│  │     │
│  │  └─────────┘ └──────────┘ └───────────┘ └────────┘  │     │
│  │  ┌──────────┐ ┌───────────┐                          │     │
│  │  │ Contacts │ │ Reporting │                          │     │
│  │  └──────────┘ └───────────┘                          │     │
│  └─────────────────┬───────────────────────────────────┘     │
│                    │                                         │
│  ┌─────────────────┴───────────────────────────────────┐     │
│  │              VERTICAL: RETAIL                        │     │
│  │  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐  │     │
│  │  │  POS Sales  │ │ Cash Session │ │ Retail Stock  │  │     │
│  │  └─────────────┘ └──────────────┘ └──────────────┘  │     │
│  └─────────────────────────────────────────────────────┘     │
│                    │                                         │
│  ┌─────────────────┴───────────────────────────────────┐     │
│  │              PRISMA DATA LAYER                       │     │
│  │     kernel schema │ shared schema │ retail schema    │     │
│  └─────────────────┬───────────────────────────────────┘     │
└────────────────────┼─────────────────────────────────────────┘
                     │
┌────────────────────┼─────────────────────────────────────────┐
│              SUPABASE (Self-Hosted)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │PostgreSQL│  │   Auth   │  │ Realtime │  │   Storage   │  │
│  │ (RLS)    │  │  (JWT)   │  │  (WS)    │  │  (future)   │  │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

> **PRD v5 — Future Architecture Layers (not in current diagram):**
> - **Server-Driven UI (Epic 10):** Flutter layout engine reads JSON layout config from server. Planned after Epic 6. Adds a `LayoutRegistry` service in KERNEL and a `LayoutEngine` module in the client. No backend structural change.
> - **Scalario Connect (Epic 12, Phase 3):** Inter-tenant B2B mesh. DB anticipation fields seeded in Phase 1 (Story 1.6). Adds a Connect vertical module + inter-tenant API layer.
> - **Scalario Enterprise (Epic 13, Phase 3):** Multi-department overlay on the kernel. DB anticipation fields seeded in Phase 1 (Story 1.6). Adds Enterprise vertical module, department-scoped RBAC, and intra-tenant event flows (FR62).
> - **Programme Ambassadeurs (Epic 11, Phase 2b):** Referral tracking via `referred_by` on Tenant (seeded in Story 1.6). Adds referral service + Mobile Money payout automation.

### Data Flow Patterns

**1. Local-First Write (Primary Path):**
```
User Action → Isar Write (WAL) → UI Update (immediate)
                                → Outbox Queue (pending)
                                → Sync Engine (background isolate)
                                → NestJS API (idempotent upsert)
                                → PostgreSQL (tenant-scoped)
                                → Supabase Realtime → Other devices
```

**2. Delta Pull (Background):**
```
Sync Engine Timer → GET /api/{resource}?since=<lastSync>
                  → Conflict Resolution (LWW / server-wins)
                  → Isar Upsert → UI Provider Invalidation
```

**3. Realtime Push (Server-Initiated):**
```
PostgreSQL Change → Supabase Realtime Channel
                  → Flutter RealtimeService
                  → SyncService.forceSync()
                  → Delta Pull (as above)
```

---

## 3. Technology Stack

### Frontend

| Technology | Version | Rationale |
|:---|:---|:---|
| **Flutter** | 3.x | Cross-platform (mobile, desktop, web) from single codebase. Critical for solo developer. Native performance on low-end Android tablets |
| **Isar** | 3.x | Local NoSQL database with WAL support, background isolate compatibility, <50MB overhead. Meets NFR6/NFR7 |
| **Riverpod** | 2.x | Compile-safe state management, provider scoping, async support. No boilerplate compared to BLoC |
| **Supabase Flutter SDK** | Latest | Auth session management, realtime subscriptions. Direct integration with self-hosted Supabase |
| **pdf + printing** | Latest | Thermal receipt generation (80mm). No external dependency |

**Trade-off:** Isar is NoSQL (no relational joins) — mitigated by denormalized local models that mirror what the UI needs. Complex queries happen server-side.

### Backend

| Technology | Version | Rationale |
|:---|:---|:---|
| **NestJS** | 10.x | TypeScript, modular architecture (DynamicModule), dependency injection. Perfect fit for kernel/shared/vertical module system |
| **Prisma** | 5.x | Type-safe ORM, multi-schema support (`previewFeatures: ["multiSchema"]`), migration tooling. Already in use |
| **@prisma/adapter-pg** | Latest | Direct PostgreSQL connection pooling via `pg` driver |
| **Node.js** | 20 LTS | Stable, long-term support, async I/O for sync operations |

**Trade-off:** Prisma multi-schema is a preview feature — mitigated by the fact that it's stable for logical schema separation (our use case) and we're already using it.

### Infrastructure

| Technology | Role | Rationale |
|:---|:---|:---|
| **Supabase (Self-Hosted)** | Auth, DB, Realtime | Full control, no vendor lock-in, RLS for tenant isolation, realtime subscriptions for push |
| **PostgreSQL 15** | Primary database | ACID compliance for financial data (NFR13/NFR18), RLS for multi-tenancy (NFR8), JSONB for flexible fields |
| **Docker Compose** | Deployment | Self-hosted Supabase runs as Docker stack. Simple deployment for solo operator |
| **Nginx** | Reverse proxy | TLS termination, rate limiting, request routing |

**Trade-off:** Self-hosted means solo admin responsibility — mitigated by Docker Compose simplicity, automated backups, and 99% uptime target (not 99.9%).

### Development Tools

| Tool | Purpose |
|:---|:---|
| **Git** | Version control |
| **GitHub Actions** | CI/CD (lint, test, build, deploy) |
| **Jest** | Backend unit/integration testing |
| **Flutter Test** | Frontend unit/widget testing |
| **Prisma Migrate** | Database schema migrations |

---

## 4. System Components

### 4.1 Kernel Components

#### 4.1.1 Auth Module (`kernel/auth`)

**Purpose:** Authentication via Supabase JWT, session management

**Responsibilities:**
- Validate JWT tokens from Supabase Auth
- Attach user context to requests
- Enforce session timeout (configurable per tenant)
- Provide `@Public()` decorator for unauthenticated routes

**Interfaces:**
- `AuthGuard` — NestJS guard applied globally
- `@CurrentUser()` — parameter decorator for extracting user

**Dependencies:** Supabase Auth

**FRs Addressed:** FR4, FR6

**Current State:** Exists as `core/guards/auth/auth.guard.ts`. Extract to `kernel/auth/`.

---

#### 4.1.2 Tenancy Module (`kernel/tenancy`)

**Purpose:** Multi-tenant context management, tenant configuration

**Responsibilities:**
- Extract and validate `x-tenant-id` from request headers
- Validate user membership in tenant (via OrganizationMember)
- Provide tenant configuration (currency, timezone, fiscal jurisdiction, active modules)
- Manage tenant lifecycle (create, activate, suspend, archive)

**Interfaces:**
- `TenantGuard` — NestJS guard applied globally
- `@CurrentTenant()` — parameter decorator
- `TenantsService.getTenantConfig()` — tenant settings

**Dependencies:** Prisma (kernel schema)

**FRs Addressed:** FR1, FR5, FR9, FR23

**Current State:** Split across `core/guards/tenant/` and `tenants/`. Consolidate into `kernel/tenancy/`.

---

#### 4.1.3 RBAC Module (`kernel/rbac`)

**Purpose:** Role-based access control with fixed roles (MVP) and granular permissions (future)

**Responsibilities:**
- Enforce role-based permissions per endpoint
- Check module activation for tenant before allowing access
- Provide `@Roles('owner', 'manager', 'commercial')` decorator
- Seed default permissions per vertical

**Interfaces:**
- `RolesGuard` — NestJS guard (after AuthGuard + TenantGuard)
- `@Roles()` — method decorator
- `PermissionService.hasPermission(userId, permissionCode)` — programmatic check

**Dependencies:** Auth Module, Tenancy Module, Prisma (kernel schema)

**FRs Addressed:** FR2, FR3, FR7, FR8, FR10

**Current State:** Does not exist. Role is stored in OrganizationMember but not enforced. New module.

**Data Model:**
```
Permission(id, code, module, description)
Role(id, name, vertical)
RolePermission(roleId, permissionId)
OrganizationMember.role → references Role
```

---

#### 4.1.4 Event Bus (`kernel/events`)

**Purpose:** Internal cross-module communication via typed events

**Responsibilities:**
- Publish domain events (e.g., `TransactionCreated`, `StockAdjusted`, `SessionClosed`)
- Subscribe handlers across module boundaries
- Maintain event ordering within a tenant context

**Interfaces:**
- `EventBus.publish(event: DomainEvent)` — fire event
- `@OnEvent('transaction.created')` — NestJS event handler decorator
- Uses NestJS built-in `EventEmitter2` (no external dependency)

**Dependencies:** None (core infrastructure)

**FRs Addressed:** FR50 (audit trail via events), cross-module communication

**Current State:** Does not exist. Modules currently call each other directly. New module.

**Design Decision:** Use NestJS `@nestjs/event-emitter` (EventEmitter2) — in-process, synchronous by default, async optional. No need for external message broker at current scale.

---

#### 4.1.5 Module Registry (`kernel/modules`)

**Purpose:** Track which shared/vertical modules are activated per tenant

**Responsibilities:**
- Maintain registry of available modules with dependency declarations
- Per-tenant module activation/deactivation
- Validate module dependencies on activation
- Provide `ModuleGuard` that checks activation before allowing API access

**Interfaces:**
- `ModuleGuard` — NestJS guard (checks tenant has module activated)
- `@RequiresModule('catalog')` — method decorator
- `ModuleRegistryService.isModuleActive(tenantId, moduleId)` — programmatic check

**Dependencies:** Tenancy Module, Prisma (kernel schema)

**FRs Addressed:** FR7, FR8, FR9, FR10

**Current State:** Does not exist. New module.

**Data Model:**
```
Module(id, code, name, type: 'shared'|'vertical', dependencies: string[])
TenantModule(tenantId, moduleId, activatedAt, status: 'active'|'inactive')
```

---

### 4.2 Shared Modules

#### 4.2.1 Catalog Module (`shared/catalog`)

**Purpose:** Base catalog item management with polymorphic type support

**Responsibilities:**
- CRUD for CatalogItem (base entity with `itemType` discriminator)
- Category management
- Barcode association
- Soft-delete support
- Sync adapter for offline clients (delta pull by `updatedAt`)

**Interfaces:**
- REST API: `/api/catalog/items`, `/api/catalog/categories`
- `CatalogService.getItems(tenantId, filters)` — internal
- `CatalogSyncAdapter` — provides delta data for sync engine

**Dependencies:** Kernel (auth, tenancy, RBAC, events)

**FRs Addressed:** FR11, FR12, FR13, FR14, FR15

**Current State:** Exists as Product/Category in PosService. Extract and generalize.

**Extension Pattern:**
```
CatalogItem (shared.catalog_items)
  ├── id, name, price, barcode, categoryId, itemType, tenantId
  ├── itemType: 'physical' | 'bookable' | 'service'
  └── isDeleted, createdAt, updatedAt

RetailProduct (retail.retail_products)  -- vertical extension
  ├── catalogItemId (FK → CatalogItem)
  ├── stockQuantity, weightUnit, minStockLevel
  └── retailSpecificFields...
```

---

#### 4.2.2 Transactions Module (`shared/transactions`)

**Purpose:** Base transaction processing with lifecycle state support

**Responsibilities:**
- Create transactions (base entity with `lifecycleType` discriminator)
- Calculate totals with currency-specific rounding
- Associate with customer (optional credit sale)
- Queue for sync (outbox pattern)
- Immutable audit trail

**Interfaces:**
- REST API: `/api/transactions`
- `TransactionService.create(tenantId, data)` — internal
- Emits `TransactionCreated` event

**Dependencies:** Kernel, Catalog (for item validation), Contacts (for customer), Payments

**FRs Addressed:** FR16, FR17, FR18, FR19, FR20, FR21, FR22

**Current State:** Exists as Order in PosService. Extract and generalize.

**Extension Pattern:**
```
Transaction (shared.transactions)
  ├── id, totalAmount, itemsJson, paymentMethod, customerId
  ├── lifecycleType: 'instant' | 'accumulating' | 'scheduled'
  ├── tenantId, createdAt
  └── paymentSplits (JSON)

RetailSale (retail.retail_sales)  -- vertical extension
  ├── transactionId (FK → Transaction)
  ├── sessionId (FK → PosSession)
  ├── receiptNumber, cashierId
  └── retailSpecificFields...
```

---

#### 4.2.3 Inventory Module (`shared/inventory`)

**Purpose:** Stock tracking, movements, and chain-of-custody

**Responsibilities:**
- Track stock movements (SALE, DELIVERY, TRANSFER_OUT, TRANSFER_IN, LOSS, ADJUSTMENT)
- Calculate current stock levels
- Chain-of-custody: double validation on transfers
- Variance tracking (expected vs actual)

**Interfaces:**
- REST API: `/api/inventory/movements`, `/api/inventory/stock`
- `InventoryService.adjustStock(productId, quantity, type, reason)` — internal
- Emits `StockAdjusted`, `TransferCreated`, `TransferConfirmed` events
- Listens to `TransactionCreated` → auto-decrement stock

**Dependencies:** Kernel, Catalog (for product reference), Events

**FRs Addressed:** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36

**Current State:** Exists as StockMovement in PosService. Extract.

---

#### 4.2.4 Payments Module (`shared/payments`)

**Purpose:** Payment method handling, currency rules, split payments

**Responsibilities:**
- Payment method registry (CASH, MOBILE_MONEY, CREDIT, SPLIT)
- Currency-specific rounding (FCFA: round to nearest 5)
- Split payment calculation and recording
- Customer balance management for credit sales

**Interfaces:**
- `PaymentsService.calculateTotal(items, currency)` — with rounding
- `PaymentsService.processPayment(transactionId, method, splits)` — internal
- Emits `PaymentProcessed` event

**Dependencies:** Kernel, Contacts (for credit balance)

**FRs Addressed:** FR17, FR18, FR19, FR39

**Current State:** Inline in PosService (payment logic scattered). Extract and formalize.

**FCFA Rounding Rule:**
```typescript
function roundFCFA(amount: Decimal): Decimal {
  return amount.div(5).round().mul(5);
}
// 1247 → 1245, 1248 → 1250
```

---

#### 4.2.5 Contacts Module (`shared/contacts`)

**Purpose:** Customer/contact management across verticals

**Responsibilities:**
- CRUD for contacts (name, phone, email, address, type)
- Outstanding balance tracking
- Debt settlement recording
- Sync adapter for offline (delta pull)

**Interfaces:**
- REST API: `/api/contacts`
- `ContactsService.updateBalance(customerId, amount)` — internal
- Emits `BalanceUpdated` event

**Dependencies:** Kernel

**FRs Addressed:** FR37, FR38, FR39, FR40

**Current State:** Exists as Customer in PosService/CustomerService. Extract.

---

#### 4.2.7 Variants Module (`shared/variants`)

**Purpose:** Per-article variant management (size, color, flavor, or any tenant-defined attribute)

**Responsibilities:**
- CRUD for `ProductVariant` — independent SKU, price, and stock per variant
- Tenant-configurable attribute schema (JSON — no hardcoded attribute names)
- Variant selection UI contract: attributes JSON exposed to frontend via catalog API
- Module-guarded: only active when `variants` module is enabled for the tenant

**Interfaces:**
- REST API: `/api/v1/catalog/items/:id/variants`
- `VariantsService.getVariants(catalogItemId, tenantId)` — internal
- `VariantsService.adjustVariantStock(variantId, delta)` — called by Inventory on sale

**Dependencies:** Kernel, Catalog, Inventory

**FRs Addressed:** FR76 (unitType), FR88 (variant-as-unit for weight/volume), FR89 (tenant-configurable attributes)

**Data Model:**
```
ProductVariant (shared.product_variants)
  ├── id, catalogItemId, sku, barcode?
  ├── attributes Json  -- e.g. {"couleur": "rouge", "taille": "M"}
  ├── price Decimal, stockQuantity Decimal
  └── tenantId, createdAt, updatedAt
```

---

#### 4.2.8 Pricing Module (`shared/pricing`)

**Purpose:** Multi-tariff price levels per article (e.g., retail price, wholesale price, VIP price)

**Responsibilities:**
- N price levels per article, fully configurable per tenant
- Optional minimum quantity per level (volume pricing)
- Price level selection at sale time (integrated into POS cart)
- Module-guarded: only active when `pricing` module is enabled

**Interfaces:**
- REST API: `/api/v1/catalog/items/:id/price-levels`
- `PricingService.getPriceLevels(catalogItemId, tenantId)` — internal
- `PricingService.resolvePrice(catalogItemId, levelId, quantity)` — used by Transactions

**Dependencies:** Kernel, Catalog

**FRs Addressed:** FR90 (multi-tarifs configurables)

**Data Model:**
```
PriceLevel (shared.price_levels)
  ├── id, catalogItemId, level (String label), price Decimal
  ├── minQuantity Decimal?  -- optional volume threshold
  └── tenantId, createdAt, updatedAt
```

---

#### 4.2.9 Promotions Module (`shared/promotions`)

**Purpose:** Time-bounded discount and free-item promotions

**Responsibilities:**
- Three promotion types: `percent_discount` | `temporary_price` | `buy_x_get_y`
- Scope: per item, per category, or tenant-wide
- Active promotion detection at cart calculation time
- Promotion status lifecycle: `draft` → `active` → `expired`
- Module-guarded: only active when `promotions` module is enabled

**Interfaces:**
- REST API: `/api/v1/promotions`
- `PromotionsService.getActivePromotions(tenantId, date)` — internal
- `PromotionsService.applyPromotion(cartItems, promotions)` — used by POS cart

**Dependencies:** Kernel, Catalog

**FRs Addressed:** FR91 (promotions configurables)

**Data Model:**
```
Promotion (shared.promotions)
  ├── id, name, type, value Decimal?, buyQuantity Int?, getQuantity Int?
  ├── catalogItemId? (item-scoped), categoryId? (category-scoped)
  ├── startDate DateTime, endDate DateTime, status
  └── tenantId, createdAt, updatedAt
```

---

#### 4.2.10 Purchase Orders Module (`shared/purchase-orders`)

**Purpose:** Supplier order lifecycle management with reception variance tracking

**Responsibilities:**
- Create purchase orders with line items (expected quantities per article)
- Status lifecycle: `draft` → `sent` → `partially_received` → `received` → `cancelled`
- Reception recording: actual quantity received vs expected, quality notes per line
- On reception: triggers `DeliveryReceived` event → Inventory auto-increments stock

**Interfaces:**
- REST API: `/api/v1/purchase-orders`
- Emits `DeliveryReceived` event (payload: lines with received quantities, tenantId)
- Inventory listens to `DeliveryReceived` → creates DELIVERY stock movements

**Dependencies:** Kernel, Catalog, Contacts (supplier), Inventory (via events)

**FRs Addressed:** FR79 (commandes fournisseurs), FR80 (réception + variance)

**Data Model:**
```
PurchaseOrder (shared.purchase_orders)
  ├── id, supplierId (FK → Contact), status, expectedDate?, notes?
  └── tenantId, createdBy, createdAt, updatedAt

PurchaseOrderLine (shared.purchase_order_lines)
  ├── id, purchaseOrderId, catalogItemId
  ├── expectedQuantity Decimal, receivedQuantity Decimal?, qualityNotes?
  └── createdAt
```

---

#### 4.2.11 Internal Requests Module (`shared/internal-requests`)

**Purpose:** Configurable internal restock circuit (Commercial → Manager → Owner)

**Responsibilities:**
- Commercial creates a restock request for an article
- Configurable approval chain per tenant (request → prepare → approve)
- Status lifecycle: `pending` → `prepared` → `approved` → `fulfilled` → `rejected`
- On fulfillment: triggers `InternalTransferFulfilled` event → Inventory adjusts stock

**Interfaces:**
- REST API: `/api/v1/internal-requests`
- `InternalRequestsService.create(tenantId, userId, data)` — internal
- Emits `InternalTransferFulfilled` event on status → `fulfilled`

**Dependencies:** Kernel, Catalog, Inventory (via events)

**FRs Addressed:** FR88 (circuit demande réapprovisionnement interne)

**Data Model:**
```
InternalRequest (shared.internal_requests)
  ├── id, catalogItemId, quantity Decimal, urgency
  ├── status, requestedBy, preparedBy?, approvedBy?, reason?
  └── tenantId, createdAt, updatedAt
```

---

#### 4.2.12 Batches Module (`shared/batches`)

**Purpose:** Freshness and batch tracking for perishable products

**Responsibilities:**
- Track product batches with reception date and expiry date
- FIFO stock depletion: oldest batch consumed first on sale
- Freshness status derivation: `fresh` | `expiring_soon` | `expired` (based on tenant-configurable threshold)
- Low-stock alerts integration: alert when stock < configurable `minStockLevel` per article
- Module-guarded: only active when `batches` module is enabled

**Interfaces:**
- REST API: `/api/v1/catalog/items/:id/batches`
- `BatchesService.getActiveBatches(catalogItemId, tenantId)` — internal
- `BatchesService.getFreshnessStatus(batch, now)` — returns color-coded status
- Listens to `DeliveryReceived` → auto-creates batches

**Dependencies:** Kernel, Catalog, Inventory (via events)

**FRs Addressed:** FR81 (alertes stock bas), FR82 (alertes configurables), FR84 (dates fraîcheur), FR85 (code couleur fraîcheur)

**Data Model:**
```
ProductBatch (shared.product_batches)
  ├── id, catalogItemId, quantity Decimal
  ├── receivedAt DateTime, expiresAt DateTime?
  └── tenantId, createdAt
```

---

#### 4.2.6 Reporting Module (`shared/reporting`)

**Purpose:** Cross-module reporting and analytics

**Responsibilities:**
- Sales statistics (daily, weekly, monthly)
- Product performance reports
- Session closure summaries
- Stock movement history
- Dashboard aggregations

**Interfaces:**
- REST API: `/api/reports/sales`, `/api/reports/inventory`, `/api/reports/sessions`
- Read-only queries against shared and vertical schemas

**Dependencies:** Kernel, Catalog, Transactions, Inventory

**FRs Addressed:** FR48, FR49

**Current State:** Exists as stats/reports methods in PosService. Extract.

---

### 4.2b Frontend Module Boundaries (Shared Activatable Modules)

The following shared modules have corresponding Flutter feature folders. Each is independently activatable per tenant via the Module Registry. If the module is inactive for a tenant, the related UI sections and routes are hidden — no separate app build required.

| Module Code | Flutter Feature Folder | Activation Condition | FRs |
|:---|:---|:---|:---|
| `variants` | `features/catalog/variants/` | `hasVariants = true` on at least one item | FR89 |
| `pricing` | `features/catalog/pricing/` | `pricing` module active for tenant | FR90 |
| `promotions` | `features/promotions/` | `promotions` module active for tenant | FR91 |
| `purchase_orders` | `features/inventory/purchase_orders/` | `purchase_orders` module active | FR79, FR80 |
| `internal_requests` | `features/inventory/internal_requests/` | `internal_requests` module active | FR88 |
| `batches` | `features/inventory/batches/` | `batches` module active | FR84, FR85 |

**Design Rule:** Each Flutter feature folder contains its own `data/`, `presentation/`, and `state/` subdirectories. Cross-module navigation uses deep links (route names), never direct widget imports.

**Offline behavior:** `variants`, `pricing`, and `batches` are sync-pulled to Isar on startup (delta pull). `promotions` is sync-pulled and evaluated locally at cart calculation time. `purchase_orders` and `internal_requests` are online-only (manager/owner workflows, not cashier-critical).

---

### 4.3 Vertical: Retail

#### 4.3.1 POS Sales (`retail/pos`)

**Purpose:** Point-of-sale retail interface and workflow

**Responsibilities:**
- Product grid display optimized for touch
- Cart management (add, remove, discount, park/restore)
- Receipt generation and printing
- Barcode scanner integration
- Wraps Catalog + Transactions + Payments for retail workflow

**Dependencies:** Catalog, Transactions, Payments, Contacts, Inventory

**FRs Addressed:** FR16, FR21

---

#### 4.3.2 Cash Session Management (`retail/sessions`)

**Purpose:** Cashier shift management with cash accountability

**Responsibilities:**
- Open/close cash sessions with balance tracking
- Theoretical balance calculation (opening + cash sales)
- Variance detection and mandatory explanation
- Session-scoped transaction association

**Dependencies:** Transactions, Reporting

**FRs Addressed:** FR23, FR24, FR25, FR26, FR27, FR28

**Current State:** Exists as PosSessionService. Wrap as vertical module.

---

#### 4.3.3 Retail Stock Extensions (`retail/stock`)

**Purpose:** Retail-specific stock operations

**Responsibilities:**
- RetailProduct extension fields (stockQuantity, weightUnit, minStockLevel)
- Stock level display in POS grid
- Low-stock alerts
- Cross-branch stock visibility (future)

**Dependencies:** Inventory, Catalog

**FRs Addressed:** FR13, FR36

---

### 4.4 Client-Side Components

#### 4.4.1 Sync Engine (`core/services/sync_service.dart`)

**Purpose:** Background data synchronization between Isar and backend

**Responsibilities:**
- Run in isolated Dart thread (no UI blocking)
- Push: pending orders → sessions → customers
- Pull: delta products → delta customers → full categories
- Exponential backoff retry (30s base, 5min max)
- Broadcast sync status to UI

**Key Design:**
- Module-agnostic: sync adapters per entity type
- Idempotent: all pushes use UUID-based upsert
- Delta: all pulls use `since` timestamp parameter
- Compressed payloads (future: gzip)

**FRs Addressed:** FR41, FR42, FR43, FR44, FR45, FR46

---

#### 4.4.2 Local Database (`core/services/isar_service.dart`)

**Purpose:** Offline-first data store with crash recovery

**Responsibilities:**
- WAL-enabled Isar instance
- Collection management for all entity types
- Pending queue management (syncStatus filtering)
- Data retention enforcement (configurable 30-90 days)

**FRs Addressed:** FR15, FR41, FR46, FR47

---

#### 4.4.3 Realtime Service (`core/services/realtime_service.dart`)

**Purpose:** Server-push notifications via Supabase channels

**Responsibilities:**
- Subscribe to table change events (products, stock_movements, orders)
- Trigger immediate sync on relevant changes
- Invalidate dashboard providers for fresh data

---

## 5. Data Architecture

### 5.1 Prisma Multi-Schema Design

Current state: All tables in `public` schema.
Target state: Three logical schemas.

```
┌─────────────────────────────────────────────────┐
│                  PostgreSQL                      │
│                                                  │
│  ┌──────────────────┐                            │
│  │  kernel schema   │                            │
│  │  ├── tenants     │                            │
│  │  ├── org_members │                            │
│  │  ├── roles       │                            │
│  │  ├── permissions │                            │
│  │  ├── role_perms  │                            │
│  │  ├── modules     │                            │
│  │  ├── tenant_mods │                            │
│  │  └── audit_log   │                            │
│  └──────────────────┘                            │
│                                                  │
│  ┌──────────────────┐                            │
│  │  shared schema   │                            │
│  │  ├── catalog_items│                           │
│  │  ├── categories  │                            │
│  │  ├── transactions│                            │
│  │  ├── stock_movs  │                            │
│  │  ├── contacts    │                            │
│  │  ├── payments    │                            │
│  │  ├── terminal_st │                            │
│  │  ├── prod_variants│  ← FR76/FR89              │
│  │  ├── price_levels│   ← FR90                  │
│  │  ├── promotions  │   ← FR91                  │
│  │  ├── purchase_ord│   ← FR79                  │
│  │  ├── po_lines    │   ← FR80                  │
│  │  ├── internal_req│   ← FR88                  │
│  │  └── prod_batches│   ← FR84/FR85             │
│  └──────────────────┘                            │
│                                                  │
│  ┌──────────────────┐                            │
│  │  retail schema   │                            │
│  │  ├── retail_prods│                            │
│  │  ├── retail_sales│                            │
│  │  ├── pos_sessions│                            │
│  │  └── parked_carts│                            │
│  └──────────────────┘                            │
└─────────────────────────────────────────────────┘
```

### 5.2 Prisma Schema (Target State)

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters", "multiSchema"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  schemas  = ["kernel", "shared", "retail"]
}

// ═══════════════════════════════════════════
// KERNEL SCHEMA
// ═══════════════════════════════════════════

model Tenant {
  id               String              @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name             String
  currency         String              @default("XOF")
  timezone         String              @default("Africa/Abidjan")
  fiscalJurisdiction String?           @map("fiscal_jurisdiction")
  status           String              @default("active") // active, suspended, archived
  createdAt        DateTime            @default(now()) @map("created_at") @db.Timestamptz(6)
  members          OrganizationMember[]
  tenantModules    TenantModule[]
  // Relations to shared/vertical via tenantId on each entity

  // FR86 — Notification channel for daily summaries and alerts. Tenant-configurable.
  notificationChannel  String?          @map("notification_channel") // whatsapp | sms | push | null
  // FR86 — Phone/recipient address for notifications (WhatsApp or SMS number).
  notificationPhone    String?          @map("notification_phone")
  // FR86 — Enable automatic daily summary notification.
  dailySummaryEnabled  Boolean          @default(false) @map("daily_summary_enabled")
  // FR86 — Local time to send daily summary (HH:MM format, interpreted in tenant timezone).
  dailySummaryTime     String?          @default("18:00") @map("daily_summary_time")

  /// Phase 2b — Programme Ambassadeurs. FK to tenants.id. Set at creation if referred by existing tenant.
  referredBy       String?             @map("referred_by") @db.Uuid
  /// Phase 3 — Scalario Connect. Visible in B2B supplier discovery network.
  networkVisible   Boolean             @default(false) @map("network_visible")
  /// Phase 3 — Scalario Enterprise. standalone = Retail. integrated = Enterprise single-tenant. federated = Groupe/Holding.
  orgMode          String              @default("standalone") @map("org_mode")
  /// Phase 3 — Scalario Enterprise (federated mode). FK to tenants.id of the parent Groupe tenant.
  parentTenantId   String?             @map("parent_tenant_id") @db.Uuid

  @@map("tenants")
  @@schema("kernel")
}

model OrganizationMember {
  id             String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String   @map("organization_id") @db.Uuid
  userId         String   @map("user_id") @db.Uuid
  roleId         String   @map("role_id") @db.Uuid
  createdAt      DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  tenant         Tenant   @relation(fields: [organizationId], references: [id])
  role           Role     @relation(fields: [roleId], references: [id])
  /// Phase 3 — Scalario Enterprise. Department memberships. Empty array in Retail mode.
  departmentIds  String[] @default([]) @map("department_ids") @db.Uuid

  @@unique([organizationId, userId])
  @@map("organization_members")
  @@schema("kernel")
}

model Role {
  id          String              @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name        String              // owner, manager, commercial
  vertical    String              // retail, restaurant, etc.
  members     OrganizationMember[]
  permissions RolePermission[]

  @@unique([name, vertical])
  @@map("roles")
  @@schema("kernel")
}

model Permission {
  id          String           @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  code        String           @unique // e.g., "catalog.edit", "session.open"
  module      String           // catalog, transactions, inventory, etc.
  description String
  roles       RolePermission[]

  @@map("permissions")
  @@schema("kernel")
}

model RolePermission {
  id           String     @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  roleId       String     @map("role_id") @db.Uuid
  permissionId String     @map("permission_id") @db.Uuid
  role         Role       @relation(fields: [roleId], references: [id])
  permission   Permission @relation(fields: [permissionId], references: [id])

  @@unique([roleId, permissionId])
  @@map("role_permissions")
  @@schema("kernel")
}

model Module {
  id           String         @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  code         String         @unique // e.g., "catalog", "retail"
  name         String
  type         String         // shared, vertical
  dependencies String[]       // module codes this depends on
  tenants      TenantModule[]

  @@map("modules")
  @@schema("kernel")
}

model TenantModule {
  id          String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  tenantId    String   @map("tenant_id") @db.Uuid
  moduleId    String   @map("module_id") @db.Uuid
  status      String   @default("active") // active, inactive
  activatedAt DateTime @default(now()) @map("activated_at") @db.Timestamptz(6)
  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  module      Module   @relation(fields: [moduleId], references: [id])
  /// Phase 3 — Scalario Enterprise. Null = tenant-wide activation (Retail). Set = department-scoped activation.
  departmentId String? @map("department_id") @db.Uuid

  @@unique([tenantId, moduleId])
  @@map("tenant_modules")
  @@schema("kernel")
}

model AuditLog {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  tenantId  String   @map("tenant_id") @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  action    String   // CREATE, UPDATE, DELETE
  entity    String   // catalog_item, transaction, etc.
  entityId  String   @map("entity_id") @db.Uuid
  before    Json?    // previous state
  after     Json?    // new state
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@index([tenantId, createdAt])
  @@index([entityId])
  @@map("audit_log")
  @@schema("kernel")
}

// ═══════════════════════════════════════════
// SHARED SCHEMA
// ═══════════════════════════════════════════

model CatalogItem {
  id                  String          @id @default(uuid()) @db.Uuid
  name                String
  price               Decimal         @db.Decimal(10, 2)
  barcode             String?
  itemType            String          @default("physical") @map("item_type") // physical, bookable, service
  categoryId          String?         @map("category_id") @db.Uuid
  tenantId            String          @map("tenant_id") @db.Uuid
  isDeleted           Boolean         @default(false) @map("is_deleted")
  createdAt           DateTime        @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime        @updatedAt @map("updated_at") @db.Timestamptz(6)

  // FR76 — Unit type (piece, weight, volume, length). All UI logic driven by this value, never hardcoded.
  unitType            String          @default("piece") @map("unit_type") // piece | weight | volume | length
  // FR76 — Base price per unit (e.g., price per kg). Used when unitType != 'piece'.
  pricePerUnit        Decimal?        @map("price_per_unit") @db.Decimal(10, 2)
  // FR81/FR82 — Configurable low-stock threshold per article.
  minStockLevel       Decimal?        @map("min_stock_level") @db.Decimal(10, 2)
  // FR84 — Default freshness window in days (expiry = receivedAt + expiryDays).
  expiryDays          Int?            @map("expiry_days")
  // FR87 — Acceptable shrinkage tolerance as a percentage (e.g., 2.50 = 2.5%).
  shrinkageTolerance  Decimal?        @map("shrinkage_tolerance") @db.Decimal(5, 2)
  // FR83 — Parent item for bulk→detail conversion (e.g., bag of rice → portions).
  parentItemId        String?         @map("parent_item_id") @db.Uuid
  // FR83 — Conversion rate from parent unit to this unit (e.g., 1 bag = 50 portions).
  conversionRate      Decimal?        @map("conversion_rate") @db.Decimal(10, 4)
  // FR89 — Has per-variant stock/price tracking enabled.
  hasVariants         Boolean         @default(false) @map("has_variants")

  category            Category?       @relation(fields: [categoryId], references: [id])
  stockMovements      StockMovement[]
  retailProduct       RetailProduct?
  variants            ProductVariant[]
  priceLevels         PriceLevel[]
  batches             ProductBatch[]
  purchaseOrderLines  PurchaseOrderLine[]
  internalRequests    InternalRequest[]
  promotions          Promotion[]

  /// Phase 3 — Scalario Connect. Supplier's reference ID for this item on the Connect B2B network.
  supplierReference   String?         @map("supplier_reference") @db.Uuid

  @@index([tenantId, updatedAt])
  @@index([tenantId, categoryId])
  @@index([barcode])
  @@map("catalog_items")
  @@schema("shared")
}

model Category {
  id        String        @id @default(uuid()) @db.Uuid
  name      String
  tenantId  String        @map("tenant_id") @db.Uuid
  createdAt DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  items     CatalogItem[]

  @@index([tenantId])
  @@map("categories")
  @@schema("shared")
}

model Transaction {
  id            String      @id @default(uuid()) @db.Uuid
  totalAmount   Decimal     @map("total_amount") @db.Decimal(10, 2)
  itemsJson     Json        @map("items_json")
  paymentMethod String?     @map("payment_method")
  paymentSplits Json?       @map("payment_splits")
  lifecycleType String      @default("instant") @map("lifecycle_type") // instant, accumulating, scheduled
  customerId    String?     @map("customer_id") @db.Uuid
  tenantId      String      @map("tenant_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  customer      Contact?    @relation(fields: [customerId], references: [id])
  retailSale    RetailSale?

  @@index([tenantId, createdAt])
  @@index([customerId])
  @@map("transactions")
  @@schema("shared")
}

model StockMovement {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @map("catalog_item_id") @db.Uuid
  quantity      Decimal     @db.Decimal(10, 2)
  type          String      // SALE, DELIVERY, TRANSFER_OUT, TRANSFER_IN, LOSS, ADJUSTMENT
  reason        String?
  // FR87 — Loss location (e.g., "magasin", "rayon", "transit"). Null for non-LOSS movements.
  location      String?
  tenantId      String      @map("tenant_id") @db.Uuid
  userId        String?     @map("user_id") @db.Uuid
  referenceId   String?     @map("reference_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@index([tenantId, createdAt])
  @@index([catalogItemId])
  @@index([referenceId])
  @@map("stock_movements")
  @@schema("shared")
}

model Contact {
  id           String        @id @default(uuid()) @db.Uuid
  name         String
  phone        String?
  email        String?
  address      String?
  contactType  String        @default("customer") @map("contact_type") // customer, supplier (future)
  balance      Decimal       @default(0) @db.Decimal(10, 2)
  tenantId     String        @map("tenant_id") @db.Uuid
  createdAt    DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt    DateTime      @updatedAt @map("updated_at") @db.Timestamptz(6)
  transactions Transaction[]
  /// Phase 3 — Scalario Connect. Links this supplier Contact to their Scalario tenant on the network.
  linkedTenantId String?     @map("linked_tenant_id") @db.Uuid

  @@index([tenantId])
  @@index([tenantId, phone])
  @@map("contacts")
  @@schema("shared")
}

model TerminalStatus {
  id       String   @id @default(uuid()) @db.Uuid
  deviceId String   @unique @map("device_id")
  status   String
  lastSeen DateTime @default(now()) @map("last_seen") @db.Timestamptz(6)
  tenantId String   @map("tenant_id") @db.Uuid

  @@map("terminal_statuses")
  @@schema("shared")
}

// ─── FR76/FR89: Product Variants ──────────────────────────────────────────────
// Each variant is an independent SKU with its own price and stock.
// Attribute keys are tenant-defined (no hardcoded names like "color" or "size").

model ProductVariant {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @map("catalog_item_id") @db.Uuid
  sku           String?
  barcode       String?
  // Tenant-configurable JSON — e.g. {"couleur": "rouge", "taille": "M"}
  attributes    Json        @default("{}")
  price         Decimal     @db.Decimal(10, 2)
  stockQuantity Decimal     @default(0) @map("stock_quantity") @db.Decimal(10, 2)
  tenantId      String      @map("tenant_id") @db.Uuid
  isDeleted     Boolean     @default(false) @map("is_deleted")
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt     DateTime    @updatedAt @map("updated_at") @db.Timestamptz(6)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@index([catalogItemId])
  @@index([tenantId])
  @@map("product_variants")
  @@schema("shared")
}

// ─── FR90: Price Levels (Multi-tarifs) ────────────────────────────────────────
// N configurable price levels per article (e.g., retail, wholesale, VIP).
// Level label is a free string — tenants name their own price tiers.

model PriceLevel {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @map("catalog_item_id") @db.Uuid
  level         String      // Tenant-defined label, e.g. "gros", "detail", "vip"
  price         Decimal     @db.Decimal(10, 2)
  // Optional: minimum quantity to qualify for this price level
  minQuantity   Decimal?    @map("min_quantity") @db.Decimal(10, 2)
  tenantId      String      @map("tenant_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt     DateTime    @updatedAt @map("updated_at") @db.Timestamptz(6)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@unique([catalogItemId, level])
  @@index([catalogItemId])
  @@index([tenantId])
  @@map("price_levels")
  @@schema("shared")
}

// ─── FR91: Promotions ─────────────────────────────────────────────────────────
// Time-bounded promotions. Scope: item, category, or tenant-wide (both FKs null).
// Types: percent_discount | temporary_price | buy_x_get_y

model Promotion {
  id            String      @id @default(uuid()) @db.Uuid
  name          String
  type          String      // percent_discount | temporary_price | buy_x_get_y
  value         Decimal?    @db.Decimal(10, 2) // % for percent_discount, price for temporary_price
  buyQuantity   Int?        @map("buy_quantity") // X in buy_x_get_y
  getQuantity   Int?        @map("get_quantity") // Y in buy_x_get_y
  // Item-scoped (null = not item-scoped)
  catalogItemId String?     @map("catalog_item_id") @db.Uuid
  // Category-scoped (null = not category-scoped)
  categoryId    String?     @map("category_id") @db.Uuid
  startDate     DateTime    @map("start_date") @db.Timestamptz(6)
  endDate       DateTime    @map("end_date") @db.Timestamptz(6)
  status        String      @default("draft") // draft | active | expired
  tenantId      String      @map("tenant_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt     DateTime    @updatedAt @map("updated_at") @db.Timestamptz(6)
  catalogItem   CatalogItem? @relation(fields: [catalogItemId], references: [id])

  @@index([tenantId, status, startDate, endDate])
  @@index([catalogItemId])
  @@map("promotions")
  @@schema("shared")
}

// ─── FR79/FR80: Purchase Orders ───────────────────────────────────────────────

model PurchaseOrder {
  id           String              @id @default(uuid()) @db.Uuid
  supplierId   String              @map("supplier_id") @db.Uuid // FK → Contact (contactType = supplier)
  status       String              @default("draft") // draft | sent | partially_received | received | cancelled
  expectedDate DateTime?           @map("expected_date") @db.Date
  notes        String?
  tenantId     String              @map("tenant_id") @db.Uuid
  createdBy    String              @map("created_by") @db.Uuid
  createdAt    DateTime            @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt    DateTime            @updatedAt @map("updated_at") @db.Timestamptz(6)
  lines        PurchaseOrderLine[]

  @@index([tenantId, status])
  @@index([supplierId])
  @@map("purchase_orders")
  @@schema("shared")
}

model PurchaseOrderLine {
  id               String        @id @default(uuid()) @db.Uuid
  purchaseOrderId  String        @map("purchase_order_id") @db.Uuid
  catalogItemId    String        @map("catalog_item_id") @db.Uuid
  expectedQuantity Decimal       @map("expected_quantity") @db.Decimal(10, 2)
  receivedQuantity Decimal?      @map("received_quantity") @db.Decimal(10, 2)
  qualityNotes     String?       @map("quality_notes")
  createdAt        DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  purchaseOrder    PurchaseOrder @relation(fields: [purchaseOrderId], references: [id])
  catalogItem      CatalogItem   @relation(fields: [catalogItemId], references: [id])

  @@index([purchaseOrderId])
  @@map("purchase_order_lines")
  @@schema("shared")
}

// ─── FR88: Internal Restock Requests ──────────────────────────────────────────
// Configurable approval chain: Commercial → Manager → Owner (per tenant config).
// Status lifecycle: pending → prepared → approved → fulfilled | rejected

model InternalRequest {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @map("catalog_item_id") @db.Uuid
  quantity      Decimal     @db.Decimal(10, 2)
  urgency       String      @default("normal") // normal | urgent
  status        String      @default("pending") // pending | prepared | approved | fulfilled | rejected
  requestedBy   String      @map("requested_by") @db.Uuid
  preparedBy    String?     @map("prepared_by") @db.Uuid
  approvedBy    String?     @map("approved_by") @db.Uuid
  reason        String?
  tenantId      String      @map("tenant_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt     DateTime    @updatedAt @map("updated_at") @db.Timestamptz(6)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@index([tenantId, status])
  @@index([catalogItemId])
  @@map("internal_requests")
  @@schema("shared")
}

// ─── FR84/FR85: Product Batches (Freshness Tracking) ──────────────────────────
// One batch per received lot. FIFO depletion on sales.
// Freshness status derived at query time: fresh | expiring_soon | expired

model ProductBatch {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @map("catalog_item_id") @db.Uuid
  quantity      Decimal     @db.Decimal(10, 2)
  receivedAt    DateTime    @map("received_at") @db.Timestamptz(6)
  // Null = no expiry tracking for this batch
  expiresAt     DateTime?   @map("expires_at") @db.Timestamptz(6)
  tenantId      String      @map("tenant_id") @db.Uuid
  createdAt     DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@index([catalogItemId, expiresAt])
  @@index([tenantId])
  @@map("product_batches")
  @@schema("shared")
}

// ═══════════════════════════════════════════
// RETAIL SCHEMA (Vertical Extension)
// ═══════════════════════════════════════════

model RetailProduct {
  id            String      @id @default(uuid()) @db.Uuid
  catalogItemId String      @unique @map("catalog_item_id") @db.Uuid
  stockQuantity Decimal     @default(0) @map("stock_quantity") @db.Decimal(10, 2)
  weightUnit    String?     @map("weight_unit") // kg, g, l (future: weight-based sales)
  minStockLevel Decimal?    @map("min_stock_level") @db.Decimal(10, 2)
  catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])

  @@map("retail_products")
  @@schema("retail")
}

model RetailSale {
  id            String      @id @default(uuid()) @db.Uuid
  transactionId String      @unique @map("transaction_id") @db.Uuid
  sessionId     String?     @map("session_id") @db.Uuid
  receiptNumber String?     @map("receipt_number")
  cashierId     String?     @map("cashier_id") @db.Uuid
  transaction   Transaction @relation(fields: [transactionId], references: [id])
  session       PosSession? @relation(fields: [sessionId], references: [id])

  @@map("retail_sales")
  @@schema("retail")
}

model PosSession {
  id                 String       @id @default(uuid()) @db.Uuid
  openingBalance     Decimal      @map("opening_balance") @db.Decimal(10, 2)
  closingBalance     Decimal?     @map("closing_balance") @db.Decimal(10, 2)
  theoreticalBalance Decimal?     @map("theoretical_balance") @db.Decimal(10, 2)
  variance           Decimal?     @db.Decimal(10, 2)
  varianceExplanation String?     @map("variance_explanation")
  status             String       @default("OPEN") // OPEN, CLOSED
  userId             String       @map("user_id") @db.Uuid
  tenantId           String       @map("tenant_id") @db.Uuid
  openedAt           DateTime     @default(now()) @map("opened_at") @db.Timestamptz(6)
  closedAt           DateTime?    @map("closed_at") @db.Timestamptz(6)
  retailSales        RetailSale[]

  @@index([tenantId, userId, status])
  @@map("pos_sessions")
  @@schema("retail")
}
```

### 5.3 Cross-Schema Relations

Prisma multi-schema supports cross-schema foreign keys natively. Key relations:

| From (Schema) | To (Schema) | Relation |
|:---|:---|:---|
| `CatalogItem` (shared) | `Category` (shared) | Many-to-one |
| `CatalogItem` (shared) | `RetailProduct` (retail) | One-to-one extension |
| `Transaction` (shared) | `Contact` (shared) | Many-to-one |
| `Transaction` (shared) | `RetailSale` (retail) | One-to-one extension |
| `RetailSale` (retail) | `PosSession` (retail) | Many-to-one |
| `StockMovement` (shared) | `CatalogItem` (shared) | Many-to-one |
| `AuditLog` (kernel) | — | No FK (stores entityId as reference) |

### 5.4 Entity Mapping: Current → Target

| Current Entity (public) | Target Entity | Schema | Notes |
|:---|:---|:---|:---|
| `Product` | `CatalogItem` + `RetailProduct` | shared + retail | Decompose: base fields → CatalogItem, stock → RetailProduct |
| `Category` | `Category` | shared | Rename table, same structure |
| `Order` | `Transaction` + `RetailSale` | shared + retail | Decompose: base → Transaction, session/receipt → RetailSale |
| `Customer` | `Contact` | shared | Rename, add contactType |
| `PosSession` | `PosSession` | retail | Move to retail schema, add varianceExplanation |
| `StockMovement` | `StockMovement` | shared | Rename productId → catalogItemId |
| `Tenant` | `Tenant` | kernel | Add currency, timezone, fiscalJurisdiction, status |
| `OrganizationMember` | `OrganizationMember` | kernel | Change role from String to FK |
| `TerminalStatus` | `TerminalStatus` | shared | Move schema |

### 5.5 Isar Local Schema (Frontend)

The local Isar collections mirror the API response shape (denormalized for offline use):

| Isar Collection | Maps To | Sync Strategy |
|:---|:---|:---|
| `Product` | `CatalogItem` + `RetailProduct` (joined) | Delta pull by `updatedAt` |
| `Category` | `Category` | Full pull |
| `Order` | `Transaction` + `RetailSale` (joined) | Push (outbox) |
| `Customer` | `Contact` | Delta pull + push |
| `PosSession` | `PosSession` | Push (outbox) |
| `ParkedCart` | — (local only) | Never synced |
| `SyncMetadata` | — (local only) | Never synced |

**Design Decision:** Isar models remain denormalized (Product contains stockQuantity from RetailProduct, Order contains sessionId from RetailSale). The API layer joins across schemas and returns flat objects that the client stores directly. This avoids relational complexity on the client.

### 5.6 Indexing Strategy

**Performance-Critical Indexes:**

| Table | Index | Reason |
|:---|:---|:---|
| `catalog_items` | `(tenant_id, updated_at)` | Delta sync queries (NFR3) |
| `catalog_items` | `(tenant_id, category_id)` | Product grid filtering (NFR1) |
| `catalog_items` | `(barcode)` | Barcode scan lookup (<100ms) |
| `transactions` | `(tenant_id, created_at)` | Sales reports, session summaries |
| `stock_movements` | `(tenant_id, created_at)` | Movement history queries |
| `stock_movements` | `(catalog_item_id)` | Per-product history |
| `contacts` | `(tenant_id, phone)` | Customer search by phone |
| `pos_sessions` | `(tenant_id, user_id, status)` | Active session lookup |
| `audit_log` | `(tenant_id, created_at)` | Audit queries (append-only, time-range) |

### 5.7 RLS Policies (Defense-in-Depth)

Supabase Row-Level Security policies enforce tenant isolation at the database level:

```sql
-- Example: catalog_items
ALTER TABLE shared.catalog_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON shared.catalog_items
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Applied to ALL tables with tenant_id
-- Set per-request: SET LOCAL app.current_tenant_id = '<tenant-uuid>';
```

**Implementation:** Prisma executes `SET LOCAL app.current_tenant_id` at the beginning of each request via a middleware, using the tenant ID from TenantGuard. This ensures every query is automatically scoped.

---

## 6. API Design

### 6.1 API Architecture

| Aspect | Decision |
|:---|:---|
| **Style** | REST (JSON) |
| **Versioning** | URL path: `/api/v1/...` |
| **Authentication** | Bearer JWT (Supabase Auth) |
| **Tenant Context** | `x-tenant-id` header on all requests |
| **Response Format** | `{ data: T, meta?: { page, limit, total } }` |
| **Error Format** | `{ statusCode, message, error }` (NestJS default) |
| **Pagination** | Offset-based: `?page=1&limit=50` |
| **Delta Sync** | `?since=<ISO8601>` returns records with `updated_at > since` |

### 6.2 API Endpoints

#### Kernel APIs

```
# Auth (handled by Supabase — no custom endpoints)

# Tenancy
GET    /api/v1/tenants/:id/config          → Tenant config (currency, timezone, modules)
PATCH  /api/v1/tenants/:id/config          → Update tenant config (Owner only)

# Organization
POST   /api/v1/organizations               → Create organization + tenant
GET    /api/v1/organizations/:id/members    → List members
POST   /api/v1/organizations/:id/members    → Add member with role
PATCH  /api/v1/organizations/:id/members/:mid → Update member role

# Module Registry
GET    /api/v1/modules                      → List available modules
GET    /api/v1/tenants/:id/modules          → List activated modules for tenant
POST   /api/v1/tenants/:id/modules          → Activate module
DELETE /api/v1/tenants/:id/modules/:mid     → Deactivate module
```

#### Shared Module APIs

```
# Catalog
GET    /api/v1/catalog/items                → List items (?since, ?category, ?search, ?page, ?limit)
POST   /api/v1/catalog/items                → Create item (sync upsert)
POST   /api/v1/catalog/items/sync           → Bulk upsert (frontend sync)
DELETE /api/v1/catalog/items/:id            → Soft delete
GET    /api/v1/catalog/categories           → List categories
POST   /api/v1/catalog/categories           → Create category
DELETE /api/v1/catalog/categories/:id       → Delete category

# Transactions
GET    /api/v1/transactions                 → List transactions (?since, ?session, ?customer)
POST   /api/v1/transactions                 → Create transaction (sync upsert, idempotent by UUID)
GET    /api/v1/transactions/:id             → Get transaction detail

# Inventory
GET    /api/v1/inventory/stock              → Current stock levels (?catalogItemId)
POST   /api/v1/inventory/movements          → Record stock movement
GET    /api/v1/inventory/movements          → Movement history (?since, ?type, ?catalogItemId)
POST   /api/v1/inventory/adjust             → Adjust stock (with movement logging)
GET    /api/v1/inventory/cross-branch       → Stock across branches (future)

# Contacts
GET    /api/v1/contacts                     → List contacts (?since, ?search, ?type)
POST   /api/v1/contacts                     → Create contact (sync upsert)
GET    /api/v1/contacts/search              → Search by name/phone
POST   /api/v1/contacts/:id/settle          → Record debt settlement

# Reporting
GET    /api/v1/reports/sales                → Sales report (?from, ?to, ?groupBy)
GET    /api/v1/reports/sales/stats           → Aggregated stats (?from, ?to)
GET    /api/v1/reports/inventory             → Inventory report
GET    /api/v1/reports/sessions              → Session reports
```

#### Retail Vertical APIs

```
# POS Sessions
POST   /api/v1/retail/sessions/open         → Open cash session
POST   /api/v1/retail/sessions/close/:id    → Close session (with balance)
GET    /api/v1/retail/sessions/active        → Get active session
GET    /api/v1/retail/sessions/summary/:id  → Session summary (by payment method)
POST   /api/v1/retail/sessions              → Sync session (offline push)

# Sync & Connectivity
POST   /api/v1/sync/heartbeat               → Terminal heartbeat
GET    /api/v1/sync/terminals                → List online terminals
```

### 6.3 Sync Protocol

**Push Flow (Client → Server):**
```
POST /api/v1/transactions
Body: { id: "<client-generated-uuid>", ... }
Response: { data: { id, syncedAt } }

Idempotency: If UUID exists, return existing record (no error).
```

**Pull Flow (Server → Client):**
```
GET /api/v1/catalog/items?since=2026-03-08T10:00:00Z&limit=100
Response: {
  data: [...items with updated_at > since...],
  meta: { total, hasMore, serverTime }
}

Client stores serverTime as next 'since' value.
Includes soft-deleted items (isDeleted: true) so client can remove them.
```

### 6.4 Guard Chain

Every request passes through guards in order:

```
Request → AuthGuard → TenantGuard → ModuleGuard → RolesGuard → Controller
           │            │              │              │
           │            │              │              └── @Roles('commercial')
           │            │              └── @RequiresModule('catalog')
           │            └── x-tenant-id → req.tenantId
           └── Bearer JWT → req.user
```

---

## 7. NFR Coverage

### NFR1: Product Grid Rendering (<500ms for 2,000 items)

**Solution:**
- Isar indexed query on `tenantId + categoryId` — local read, no network
- Flutter `ListView.builder` with lazy rendering (only visible items in memory)
- Category filter reduces dataset before rendering

**Validation:** Benchmark with 2,000 products on Samsung Galaxy Tab A (low-end target device)

---

### NFR2: Transaction Recording (<200ms local write)

**Solution:**
- Single Isar `writeTxn` — atomic local write
- No network call in write path — sync is background-only
- Cart items pre-calculated (subtotals computed in CartNotifier)

**Validation:** Instrument Isar write duration in debug builds

---

### NFR3: Full-Day Sync (<30s for 150+ transactions)

**Solution:**
- Delta-only sync (not full dataset)
- Batch push: all pending orders in single request array
- Compressed payloads (gzip on HTTP layer)
- Sync in background isolate — UI not blocked

**Validation:** Test with 200 transactions + 50 stock movements on 3G (300kbps)

---

### NFR4: App Cold Start (<3s)

**Solution:**
- Isar opens from disk in <100ms (memory-mapped)
- No network call required for cold start
- Riverpod providers lazy-loaded (only active screen)
- Sync engine spawns after UI is interactive

**Validation:** Measure time from `main()` to first frame on target device

---

### NFR5: Session Closure Report (<2s)

**Solution:**
- Local Isar query: filter orders by sessionId, group by paymentMethod
- All data already local — no network dependency
- Pre-computed theoretical balance in SessionNotifier

---

### NFR6: Memory Footprint (<150MB RAM)

**Solution:**
- Isar uses memory-mapped files (not in-heap)
- ListView.builder disposes off-screen widgets
- Sync isolate has independent memory space
- No image caching (text-only catalog)

**Validation:** Android Studio profiler on target device during full shift simulation

---

### NFR7: Local Database Size (<500MB for 90 days)

**Solution:**
- Text-only data (no images in sync)
- Configurable retention: auto-purge synced orders/movements older than threshold
- SyncMetadata tracks purge timestamps
- Estimated: 150 orders/day × 90 days × ~2KB/order = ~27MB. Well within limit.

---

### NFR8: Tenant Data Isolation (Zero leakage)

**Solution:**
- Application level: `tenant_id` on every entity, TenantGuard on every request
- Database level: Supabase RLS policies on all tables
- Query level: Prisma middleware sets `SET LOCAL app.current_tenant_id` per request
- Local (client): Single tenant per device (tenant selected at login)

**Validation:** Integration tests with two tenants — verify no cross-tenant data access

---

### NFR9-NFR11: Auth & Encryption

**Solution:**
- JWT from Supabase Auth with configurable expiry
- TLS 1.2+ for all API communication (Nginx termination)
- Isar encryption: AES-256 with device-specific key (Flutter secure storage)

---

### NFR12: Price Modification Audit

**Solution:**
- AuditLog entry on every CatalogItem.price change
- Captures: userId, before price, after price, timestamp
- RolesGuard enforces: only `owner` role can call price update endpoint

---

### NFR13: Financial Data Integrity

**Solution:**
- All financial writes use Prisma `$transaction` (database-level atomicity)
- Isar writes use `writeTxn` (local atomicity)
- No partial states: order + stock adjustment + customer balance in single transaction
- `Decimal(10,2)` throughout — no floating-point arithmetic

---

### NFR14-NFR15: Offline Autonomy & Crash Recovery

**Solution:**
- Isar WAL (Write-Ahead Log) enabled by default
- All operations write locally first — network is optional
- On crash: Isar replays WAL on next open, recovering uncommitted transactions
- SyncStatus enum tracks what has/hasn't been pushed to server

---

### NFR16: Sync Resilience (Exponential Backoff)

**Solution:**
- Already implemented in SyncService: 30s base, 5min max, 6 retries
- On permanent failure: status broadcasts `SyncUiStatus.error`
- On connectivity return: `forceSync()` triggered by RealtimeService reconnection

---

### NFR17: Server Uptime (99%)

**Solution:**
- Docker Compose with automatic container restart
- PostgreSQL WAL + daily pg_dump backups
- Nginx health checks
- Acceptable: clients work offline during downtime

---

### NFR18: Data Durability (Zero transaction loss)

**Solution:**
- Local: Isar WAL ensures write durability
- Transit: Idempotent sync with UUID-based dedup
- Server: PostgreSQL WAL + fsync + daily backups
- Verification: SyncStatus.synced only after server 200 response

---

### NFR19-NFR23: Scalability

**Solution:**
- 30 tenants × 10 users × 500 txn/day = 150,000 txn/day max
- Single PostgreSQL instance handles this easily (indexed queries)
- No code changes for new tenants — configuration only
- Connection pooling via @prisma/adapter-pg

---

### NFR24-NFR27: Network & Bandwidth

**Solution:**
- Delta sync: only changed records since last sync
- No image/file sync — data only
- Gzip compression on HTTP responses (Nginx)
- Initial provisioning: catalog + config < 5MB (text only)
- Estimated delta payload: ~50KB for typical sync cycle

---

### NFR28-NFR30: Usability

**Solution:**
- Role-based UI: Commercial sees POS only (simple, focused)
- Error messages in user's language (French for Burkina Faso)
- Sync status: subtle indicator, no popups or blocking modals
- Offline = default state — no "offline mode" concept in UI

---

## 8. Security Architecture

### 8.1 Authentication

| Aspect | Implementation |
|:---|:---|
| **Provider** | Supabase Auth (self-hosted) |
| **Method** | Email/password → JWT |
| **Token Type** | Access token (short-lived) + Refresh token |
| **Token Lifetime** | Access: 1 hour, Refresh: 7 days (configurable) |
| **Session Timeout** | Configurable per tenant (default: 8 hours idle) |
| **MFA** | Not required MVP. Architecture supports it via Supabase |

### 8.2 Authorization

| Layer | Mechanism |
|:---|:---|
| **Guard 1: AuthGuard** | Validates JWT, attaches user to request |
| **Guard 2: TenantGuard** | Validates x-tenant-id, checks user membership |
| **Guard 3: ModuleGuard** | Checks module is activated for tenant |
| **Guard 4: RolesGuard** | Checks user role has required permission |

**Permission Enforcement:**
```typescript
@UseGuards(AuthGuard, TenantGuard, ModuleGuard, RolesGuard)
@RequiresModule('catalog')
@Roles('owner')
@Patch('catalog/items/:id')
async updateItem(@Param('id') id: string, @Body() dto: UpdateItemDto) { ... }
```

### 8.3 Data Protection

| Layer | Protection |
|:---|:---|
| **At Rest (Server)** | PostgreSQL tablespace encryption (filesystem-level) |
| **At Rest (Client)** | Isar AES-256 encryption with key in Flutter SecureStorage |
| **In Transit** | TLS 1.2+ (Nginx SSL termination) |
| **API Keys** | Supabase anon key (public, RLS-protected) + service role key (server-only) |

### 8.4 Anti-Fraud Controls

| Control | Implementation |
|:---|:---|
| **Price Lock** | Only Owner role can modify CatalogItem.price |
| **Session Accountability** | Variance > threshold → mandatory explanation before close |
| **Chain of Custody** | Stock transfers: emitter declares out, receiver confirms in, delta auto-traced |
| **Audit Trail** | AuditLog captures every mutation with before/after state |
| **Immutable History** | AuditLog is append-only — no UPDATE or DELETE allowed |

### 8.5 Input Validation

- All API inputs validated via NestJS DTOs with `class-validator` decorators
- UUIDs validated with `@IsUUID()`
- Decimals validated with `@IsDecimal()` and `@Min(0)`
- Strings sanitized (trim, max length)
- No raw SQL — all queries via Prisma (parameterized)

---

## 9. Scalability & Performance

### 9.1 Scaling Strategy

**Current Scale (MVP):**
- 3 tenants, ~10 users total
- Single server handles everything

**12-Month Target:**
- 30 tenants, ~100 users
- Still single server — PostgreSQL easily handles 150K transactions/day

**Scaling Path (if needed):**

| Threshold | Action |
|:---|:---|
| >50 tenants | Add read replica for reporting queries |
| >200 concurrent users | Horizontal NestJS scaling behind load balancer |
| >1M transactions/month | Partition transactions table by tenant_id + month |
| >500 tenants | Consider tenant-per-database (major architecture change) |

**Design Decision:** Do not pre-optimize. Current architecture handles 10x growth without changes. Vertical scaling (bigger server) is cheapest intervention.

### 9.2 Performance Optimization

| Area | Technique |
|:---|:---|
| **Database** | Indexes on hot query paths (see §5.6), connection pooling |
| **API** | Response compression (gzip), pagination (max 100/page) |
| **Client** | Lazy loading (ListView.builder), isolate-based sync |
| **Sync** | Delta-only, batch push, skip unchanged records |

### 9.3 Caching Strategy

**MVP: No application-level cache.** Rationale:
- Clients operate on local Isar data (effectively cached locally)
- Server queries are tenant-scoped (small datasets per tenant)
- Adding Redis adds operational complexity for solo admin
- Can add later if reporting queries become slow

---

## 10. Reliability & Availability

### 10.1 High Availability

| Component | Strategy |
|:---|:---|
| **Client** | Fully autonomous offline. Server downtime = invisible to cashiers |
| **NestJS** | Docker restart policy: `always`. Single instance sufficient |
| **PostgreSQL** | WAL + streaming replication (standby) if budget allows |
| **Supabase** | Docker Compose with health checks and auto-restart |

### 10.2 Disaster Recovery

| Metric | Target |
|:---|:---|
| **RPO** (Recovery Point Objective) | 1 hour (daily backup + WAL archiving) |
| **RTO** (Recovery Time Objective) | 4 hours (restore from backup + replay WAL) |

**Backup Strategy:**
- `pg_dump` daily at 02:00 UTC → compressed, stored off-server
- WAL archiving for point-in-time recovery
- Backup retention: 30 days
- Monthly restore test

### 10.3 Monitoring & Alerting

| What | How |
|:---|:---|
| **Server health** | Docker healthchecks + simple uptime monitor (e.g., UptimeRobot) |
| **API errors** | NestJS exception filter → structured JSON logs |
| **Sync failures** | Count pending orders > 24h → alert (future: WhatsApp to admin) |
| **Database** | PostgreSQL `pg_stat_statements` for slow queries |
| **Disk usage** | Alert at 80% capacity |

**MVP Logging:** Structured JSON logs to stdout (Docker captures). No ELK stack — `docker logs` + `grep` sufficient for current scale.

---

## 11. Development & Deployment

### 11.1 Project Structure (Target)

```
apps/
├── backend/
│   ├── prisma/
│   │   └── schema.prisma          # Multi-schema (kernel, shared, retail)
│   │   └── migrations/
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── kernel/
│   │   │   ├── kernel.module.ts    # Exports: AuthGuard, TenantGuard, RolesGuard, EventBus
│   │   │   ├── auth/
│   │   │   │   ├── auth.guard.ts
│   │   │   │   ├── auth.decorator.ts    # @CurrentUser, @Public
│   │   │   │   └── auth.module.ts
│   │   │   ├── tenancy/
│   │   │   │   ├── tenant.guard.ts
│   │   │   │   ├── tenant.decorator.ts  # @CurrentTenant
│   │   │   │   ├── tenancy.service.ts
│   │   │   │   └── tenancy.module.ts
│   │   │   ├── rbac/
│   │   │   │   ├── roles.guard.ts
│   │   │   │   ├── roles.decorator.ts   # @Roles
│   │   │   │   ├── permission.service.ts
│   │   │   │   └── rbac.module.ts
│   │   │   ├── events/
│   │   │   │   ├── event-bus.service.ts
│   │   │   │   ├── domain-events.ts     # Event type definitions
│   │   │   │   └── events.module.ts
│   │   │   └── modules/
│   │   │       ├── module.guard.ts
│   │   │       ├── module.decorator.ts  # @RequiresModule
│   │   │       ├── module-registry.service.ts
│   │   │       └── modules.module.ts
│   │   ├── shared/
│   │   │   ├── catalog/
│   │   │   │   ├── catalog.module.ts
│   │   │   │   ├── catalog.controller.ts
│   │   │   │   ├── catalog.service.ts
│   │   │   │   └── dto/
│   │   │   ├── transactions/
│   │   │   │   ├── transactions.module.ts
│   │   │   │   ├── transactions.controller.ts
│   │   │   │   ├── transactions.service.ts
│   │   │   │   └── dto/
│   │   │   ├── inventory/
│   │   │   │   ├── inventory.module.ts
│   │   │   │   ├── inventory.controller.ts
│   │   │   │   ├── inventory.service.ts
│   │   │   │   └── dto/
│   │   │   ├── payments/
│   │   │   │   ├── payments.module.ts
│   │   │   │   ├── payments.service.ts  # No controller — internal only
│   │   │   │   └── currency-rules.ts    # FCFA rounding, etc.
│   │   │   ├── contacts/
│   │   │   │   ├── contacts.module.ts
│   │   │   │   ├── contacts.controller.ts
│   │   │   │   ├── contacts.service.ts
│   │   │   │   └── dto/
│   │   │   └── reporting/
│   │   │       ├── reporting.module.ts
│   │   │       ├── reporting.controller.ts
│   │   │       └── reporting.service.ts
│   │   ├── retail/                      # Vertical
│   │   │   ├── retail.module.ts
│   │   │   ├── pos/
│   │   │   │   ├── pos.controller.ts
│   │   │   │   └── pos.service.ts       # Orchestrates catalog+transactions+payments
│   │   │   ├── sessions/
│   │   │   │   ├── sessions.controller.ts
│   │   │   │   └── sessions.service.ts
│   │   │   └── stock/
│   │   │       └── retail-stock.service.ts
│   │   └── prisma/
│   │       ├── prisma.module.ts
│   │       ├── prisma.service.ts
│   │       └── prisma.middleware.ts     # RLS tenant context setting
│   └── test/
├── frontend/
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── auth/
│       │   ├── models/
│       │   └── services/
│       │       ├── isar_service.dart
│       │       ├── sync_service.dart
│       │       ├── realtime_service.dart
│       │       ├── receipt_service.dart
│       │       └── barcode_scanner_service.dart
│       └── features/
│           ├── pos/                     # Retail vertical UI
│           │   ├── data/
│           │   │   ├── models/          # Isar collections (unchanged)
│           │   │   └── repositories/    # API calls update to new endpoints
│           │   └── presentation/
│           └── dashboard/
```

### 11.2 Module Registration Pattern

Each module registers as a NestJS `DynamicModule`:

```typescript
// shared/catalog/catalog.module.ts
@Module({})
export class CatalogModule {
  static register(): DynamicModule {
    return {
      module: CatalogModule,
      imports: [PrismaModule, KernelModule],
      controllers: [CatalogController],
      providers: [CatalogService],
      exports: [CatalogService],
    };
  }
}

// app.module.ts
@Module({
  imports: [
    KernelModule,
    CatalogModule.register(),
    TransactionsModule.register(),
    InventoryModule.register(),
    PaymentsModule.register(),
    ContactsModule.register(),
    ReportingModule.register(),
    RetailModule.register(),  // Vertical
    PrismaModule,
  ],
})
export class AppModule {}
```

### 11.3 Testing Strategy

| Level | Scope | Target Coverage | Tool |
|:---|:---|:---|:---|
| **Unit** | Services, guards, currency rules | 80% | Jest (backend), flutter_test (frontend) |
| **Integration** | API endpoints with real DB | Key flows | Jest + Prisma test utils |
| **E2E** | Full sync cycle (client → server → client) | Critical paths | Manual (MVP), automated (post-MVP) |
| **Regression** | Existing POS behavior preserved | 100% | Comparison tests: same inputs → same outputs |

**Priority Tests:**
1. Tenant isolation (cross-tenant data leak = critical bug)
2. Sync idempotency (duplicate push = no duplicate data)
3. FCFA rounding (financial correctness)
4. Session variance calculation (accountability)
5. Offline → online transition (pending orders sync correctly)

### 11.4 CI/CD Pipeline

```
Push to main → GitHub Actions:
  1. Lint (ESLint + Prettier)
  2. Backend unit tests (Jest)
  3. Frontend unit tests (flutter test)
  4. Prisma migrate deploy (staging DB)
  5. Build backend Docker image
  6. Deploy to staging
  7. Manual promotion to production
```

### 11.5 Deployment

| Component | Method |
|:---|:---|
| **Backend** | Docker container behind Nginx reverse proxy |
| **Supabase** | Docker Compose (self-hosted stack) |
| **Frontend (mobile)** | APK distribution (direct install, not Play Store MVP) |
| **Frontend (web)** | Flutter web build, served by Nginx |
| **Database migrations** | `prisma migrate deploy` in CI pipeline |

---

## 12. FR Traceability

| FR | Description | Component(s) | Schema |
|:---|:---|:---|:---|
| FR1 | Create/configure tenant | Tenancy | kernel |
| FR2 | Create users, assign roles | RBAC | kernel |
| FR3 | Enforce role permissions | RolesGuard | kernel |
| FR4 | Authenticate, scoped session | Auth (Supabase) | kernel |
| FR5 | Tenant isolation | TenantGuard + RLS | kernel |
| FR6 | Session timeout | Auth | kernel |
| FR7 | Activate/deactivate modules | Module Registry | kernel |
| FR8 | Module dependency validation | Module Registry | kernel |
| FR9 | Module isolation per tenant | Module Registry | kernel |
| FR10 | One active vertical per tenant | Module Registry | kernel |
| FR11 | CRUD catalog items | Catalog | shared |
| FR12 | itemType discriminator | Catalog (CatalogItem.itemType) | shared |
| FR13 | Vertical extension fields | RetailProduct | retail |
| FR14 | Category management | Catalog | shared |
| FR15 | Offline catalog availability | Isar + SyncService | client |
| FR16 | Create sales transaction | Transactions + POS | shared + retail |
| FR17 | Payment method selection | Payments | shared |
| FR18 | Currency rounding (FCFA) | Payments (currency-rules) | shared |
| FR19 | Change due calculation | Payments | shared |
| FR20 | Transaction lifecycle types | Transactions (lifecycleType) | shared |
| FR21 | Vertical transaction extension | RetailSale | retail |
| FR22 | Local-first write + sync queue | Isar + SyncService | client |
| FR23 | Open cash session | Sessions | retail |
| FR24 | Session-scoped transactions | RetailSale.sessionId | retail |
| FR25 | Close session with balance | Sessions | retail |
| FR26 | Variance display | Sessions | retail |
| FR27 | Mandatory variance explanation | Sessions (varianceExplanation) | retail |
| FR28 | View session reports | Reporting | shared |
| FR29 | Receive supplier deliveries | Inventory | shared |
| FR30 | Track reception variances | Inventory (StockMovement) | shared |
| FR31 | Create stock transfers | Inventory | shared |
| FR32 | Confirm transfer reception | Inventory | shared |
| FR33 | Track transfer variances | Inventory (auto-delta) | shared |
| FR34 | Declare stock losses | Inventory | shared |
| FR35 | Partial inventory counts | Inventory | shared |
| FR36 | Offline inventory data | Isar + SyncService | client |
| FR37 | Customer CRUD | Contacts | shared |
| FR38 | Associate transaction to customer | Transactions.customerId | shared |
| FR39 | Credit sale, balance update | Payments + Contacts | shared |
| FR40 | Offline customer data | Isar + SyncService | client |
| FR41 | Online/offline identical ops | Isar (local-first) | client |
| FR42 | Outbox queue sync | SyncService | client |
| FR43 | Delta-only sync | SyncService (`since` param) | client + API |
| FR44 | Conflict resolution | SyncService (LWW / server-wins) | client |
| FR45 | Connectivity status indicator | SyncStatusIndicator | client |
| FR46 | Crash recovery (zero loss) | Isar WAL | client |
| FR47 | Configurable data retention | Isar purge job | client |
| FR48 | Daily consolidation report | Reporting | shared |
| FR49 | Owner dashboard | Reporting | shared |
| FR50 | Immutable audit trail | AuditLog + EventBus | kernel |
| FR51 | Audit retention policy | AuditLog (server: forever, client: configurable) | kernel + client |
| FR52 (DB) | Connect: tenants.referred_by + network_visible | Story 1.6 migration | kernel |
| FR53 (DB) | Connect: contacts.linked_tenant_id | Story 1.6 migration | shared |
| FR54 (DB) | Connect: catalog_items.supplier_reference | Story 1.6 migration | shared |
| FR55 (DB) | Connect: transaction_type += transfer_inter_tenant | Story 1.6 migration | shared |
| FR56 | Data migration zero-loss | Migration scripts | infra |
| FR57 | Multi-schema Prisma | schema.prisma (kernel/shared/retail) | all |
| FR58 | Module-agnostic sync | SyncService with adapters | client |
| FR59 (DB) | Enterprise: tenants.org_mode + parent_tenant_id | Story 1.6 migration | kernel |
| FR60 (DB) | Enterprise: organization_members.department_ids | Story 1.6 migration | kernel |
| FR61 (DB) | Enterprise: tenant_modules.department_id | Story 1.6 migration | kernel |
| FR62 | Inter-department events via EventBus extension | Epic 13 | kernel |
| FR63–FR68 | RH & Paie Enterprise (CNSS, CARFO, bulletins) | Epic 13 | enterprise |
| FR69–FR72 | Comptabilité OHADA (plan comptable, clôture, FEC) | Epic 13 | enterprise |
| FR73–FR74 | Import Enterprise CSV + Retail → Enterprise migration | Epic 13 | enterprise |
| FR75 | Sync failure lifecycle: outbox → retry → FAILED → resolution | Epic 8 | client + API |
| FR76 | Unit type per article (piece/weight/volume/length), price×quantity calculation | Catalog (CatalogItem.unitType + pricePerUnit) | shared |
| FR77 | Tenant-configurable unitType via UI-Driven settings (no hardcoded types) | Catalog + Module Registry | shared |
| FR78 | Weight/volume sale: quantity input at POS, total = pricePerUnit × quantity | POS cart + Payments | retail + shared |
| FR79 | Create/manage purchase orders with supplier and line items | PurchaseOrders | shared |
| FR80 | Record delivery reception with per-line variance (expected vs actual) | PurchaseOrders (PurchaseOrderLine.receivedQuantity) + Inventory event | shared |
| FR81 | Low-stock alert when stock < CatalogItem.minStockLevel | Batches / Reporting | shared |
| FR82 | minStockLevel configurable per article via UI | Catalog (CatalogItem.minStockLevel) | shared |
| FR83 | Bulk→detail unit conversion (parentItemId + conversionRate) | Catalog | shared |
| FR84 | Freshness date tracking per received batch (ProductBatch.expiresAt) | Batches | shared |
| FR85 | Color-coded freshness status: fresh / expiring_soon / expired | Batches (BatchesService.getFreshnessStatus) | shared |
| FR86 | Automatic daily summary notification (WhatsApp/SMS/push), tenant-configurable | Reporting + Tenant.notificationChannel/dailySummaryEnabled | shared + kernel |
| FR87 | Loss declaration with location field (magasin / rayon / transit) | Inventory (StockMovement.location) | shared |
| FR88 | Internal restock request circuit (Commercial → Manager → Owner, configurable) | InternalRequests | shared |
| FR89 | Per-variant stock/price tracking with tenant-defined attribute schema | Variants (ProductVariant.attributes JSON) | shared |
| FR90 | Multi-tariff price levels per article, tenant-configurable labels | Pricing (PriceLevel) | shared |
| FR91 | Time-bounded promotions: percent discount, temporary price, buy-X-get-Y | Promotions | shared |

**Coverage:** 91/91 FRs mapped to components. (DB-only FRs marked with (DB) are addressed in Story 1.6 — schema only, no business logic. FR52–FR55 and FR59–FR61 business logic activates in Epics 11–13. FR76–FR91 added in architecture v1.1 — implementation in Phase 2 epics.)

---

## 13. NFR Traceability

| NFR | Requirement | Solution | Validation |
|:---|:---|:---|:---|
| NFR1 | Grid <500ms / 2K items | Isar indexed query + ListView.builder | Benchmark on Galaxy Tab A |
| NFR2 | Transaction write <200ms | Single Isar writeTxn | Instrument write duration |
| NFR3 | Full-day sync <30s | Delta-only, batch push, gzip | Test 200 txn on 3G |
| NFR4 | Cold start <3s | Isar memory-mapped, lazy providers | Measure main() → first frame |
| NFR5 | Session report <2s | Local Isar query, pre-computed | Measure on target device |
| NFR6 | RAM <150MB | Isar mmap, ListView.builder | Android profiler |
| NFR7 | DB <500MB / 90 days | Text-only, auto-purge | Calculate actual data volume |
| NFR8 | Zero cross-tenant leakage | tenant_id + RLS + TenantGuard | Cross-tenant integration tests |
| NFR9 | JWT auth, configurable timeout | Supabase Auth | Auth flow tests |
| NFR10 | Local DB encrypted | Isar AES-256 + SecureStorage | Verify DB file unreadable |
| NFR11 | TLS 1.2+ | Nginx SSL termination | SSL Labs test |
| NFR12 | Price change audit | AuditLog + RolesGuard(owner) | Unit test: non-owner blocked |
| NFR13 | Atomic financial writes | Prisma $transaction + Isar writeTxn | Simulate partial failure |
| NFR14 | 8h+ offline autonomy | Isar local-first, no network dependency | 8h shift simulation |
| NFR15 | Zero crash data loss | Isar WAL | Kill process mid-write, verify recovery |
| NFR16 | Exponential backoff sync | SyncService retry logic | Network failure simulation |
| NFR17 | 99% uptime | Docker restart + backups | Uptime monitoring |
| NFR18 | Zero transaction loss | WAL + idempotent sync + backup | End-to-end sync verification |
| NFR19 | 30+ tenants | Indexed queries, tenant_id scoping | Load test with 30 tenants |
| NFR20 (Retail) | 10 users concurrent (Standard) / 20 (Premium multi-sites) | Connection pooling | Concurrent user load test — Retail tenant |
| NFR20 (Enterprise) | 50 users concurrent (Pro) across 4 departments, non-simultaneous peaks | Connection pooling + department-scoped queries | Concurrent load test — Enterprise tenant, 4-dept simulation |
| NFR21 | 500 txn/day/tenant | PostgreSQL capacity | Volume test |
| NFR22 | 5K catalog items/tenant | Indexed queries | Query benchmark |
| NFR23 | Zero-code new tenant | Configuration only | Create tenant via API |
| NFR24 | Compressed delta payloads | Nginx gzip + delta sync | Measure payload sizes |
| NFR25 | Works on 2G (50kbps) | Small payloads, retry logic | Throttled network test |
| NFR26 | No heavy asset sync | Data-only (no images) | Verify sync payloads |
| NFR27 | Initial provision <5MB | Catalog + config only | Measure initial sync |
| NFR28 | <1h cashier onboarding | Role-based simple UI | User testing |
| NFR29 | Actionable error messages | French error messages, no jargon | UX review |
| NFR30 | Seamless offline | No "offline mode" indicator | User testing |

**Coverage:** 30/30 NFRs mapped to solutions. NFR20, NFR21, and NFR22 have dual targets (Retail vs Enterprise) per PRD v5.

---

## 14. Trade-offs & Decisions

### Decision 1: Modular Monolith over Microservices

**Trade-off:**
- ✓ **Gain:** Simple deployment, single codebase, easy debugging, no distributed transaction complexity
- ✗ **Lose:** Independent scaling per module, independent deployment per team
- **Rationale:** Solo developer, <100 users, <30 tenants. Microservices overhead (service mesh, distributed tracing, API gateways) vastly exceeds benefits. Can extract services later if needed.

### Decision 2: Isar (NoSQL) for Local Database

**Trade-off:**
- ✓ **Gain:** Flutter-native, WAL support, isolate-compatible, fast writes, small footprint
- ✗ **Lose:** No relational joins locally, schema must be denormalized
- **Rationale:** Client needs fast writes and offline reads for flat data (products, orders). Complex relational queries happen server-side. Denormalized Isar models match API response shapes directly.

### Decision 3: Supabase (Self-Hosted) over Firebase/AWS

**Trade-off:**
- ✓ **Gain:** Full control, no vendor lock-in, PostgreSQL + RLS, Auth + Realtime in one stack
- ✗ **Lose:** Solo admin responsibility for infrastructure
- **Rationale:** RLS is critical for tenant isolation (NFR8). Firebase Firestore security rules are less powerful. Self-hosted = data sovereignty in African market.

### Decision 4: Prisma Multi-Schema (Preview Feature)

**Trade-off:**
- ✓ **Gain:** Clean logical separation (kernel/shared/retail), migration tooling, type safety
- ✗ **Lose:** Preview feature risk, may have edge cases
- **Rationale:** Already using multiSchema preview. Logical schema separation is stable use case. Alternative (separate Prisma clients per schema) is far more complex.

### Decision 5: EventEmitter2 over External Message Broker

**Trade-off:**
- ✓ **Gain:** No infrastructure dependency, synchronous by default, simple
- ✗ **Lose:** No persistence, no cross-service communication, no replay
- **Rationale:** In-process events are sufficient for modular monolith. Audit trail is handled by AuditLog table, not event replay. Can add RabbitMQ/NATS later if needed.

### Decision 6: No Application-Level Cache (MVP)

**Trade-off:**
- ✓ **Gain:** No Redis operational overhead, no cache invalidation complexity
- ✗ **Lose:** Slightly higher DB load for repeated queries
- **Rationale:** Clients cache locally in Isar. Server queries are tenant-scoped (small datasets). Adding Redis for 30 tenants is premature optimization.

### Decision 7: Base Entity + Extension Table (not STI)

**Trade-off:**
- ✓ **Gain:** Clean separation between shared and vertical data, no nullable column bloat
- ✗ **Lose:** JOIN required to get full entity (CatalogItem + RetailProduct)
- **Rationale:** Extension tables allow different verticals to add fields without modifying shared schema. JOIN cost is minimal for indexed 1:1 relations. STI would pollute shared tables with vertical-specific nullable columns.

### Decision 8: Server-Driven UI (Layout-as-Data) over Native Screens per Vertical

**Context:** PRD v5 introduces multiple business types (Retail, Pharmacy, Restaurant, Enterprise departments). Building a separate Flutter screen set per vertical means an N × M maintenance matrix unsustainable for a solo developer.

**Trade-off:**
- ✓ **Gain:** Single Flutter binary. Adding a new vertical = new JSON layout config + backend module, zero Flutter code change. Enables UI config updates without an app store release. Validated by PRD v5 Annex A Test 5 ("Activer le type Pharmacie affiche les champs DCI sans mise à jour de l'app").
- ✗ **Lose:** Layout engine complexity upfront. JSON schema must be strictly validated server-side. Complex animations or device-specific interactions are harder to express in data.
- **Rationale:** Scalario targets N verticals and N Enterprise departments. The refactoring cost of N native screen sets grows linearly; the layout engine cost is paid once. A server-validated JSON schema with a hardcoded fallback layout mitigates malformed-config risk.
- **Implementation timing:** Epic 10, after Epic 6. All Retail screens (Epics 2–6) built conventionally first to validate business logic, then refactored to use the layout engine in Epic 10. The refactoring cost is accepted in exchange for unblocking the full backend restructuring.

---

## 15. Migration Strategy

### 15.1 Incremental Extraction Sequence

Each step is independently deployable. Clients stay operational throughout.

```
Step 1: Kernel Extraction
  ├── Create kernel schema
  ├── Move tenants, org_members to kernel
  ├── Add Role, Permission, RolePermission tables
  ├── Seed MVP roles (Owner, Manager, Commercial)
  ├── Add Module, TenantModule tables
  ├── Add AuditLog table
  ├── Implement AuthGuard, TenantGuard, RolesGuard, ModuleGuard
  ├── Add EventBus (EventEmitter2)
  └── Deploy: existing API unchanged, new guards active

Step 2: Shared Module Extraction (Catalog)
  ├── Create shared schema
  ├── Rename products → catalog_items, add itemType column
  ├── Move categories to shared schema
  ├── Extract CatalogService from PosService
  ├── New endpoints: /api/v1/catalog/*
  ├── Old endpoints (/pos/products) redirect to new
  └── Deploy: both old and new endpoints work

Step 3: Shared Module Extraction (Contacts)
  ├── Rename customers → contacts, add contactType
  ├── Extract ContactsService from CustomerService
  ├── New endpoints: /api/v1/contacts/*
  └── Deploy

Step 4: Shared Module Extraction (Transactions + Payments)
  ├── Rename orders → transactions, add lifecycleType
  ├── Extract PaymentsService (FCFA rounding)
  ├── Extract TransactionsService
  ├── New endpoints: /api/v1/transactions/*
  └── Deploy

Step 5: Shared Module Extraction (Inventory)
  ├── Move stock_movements to shared, rename productId → catalogItemId
  ├── Extract InventoryService
  ├── New endpoints: /api/v1/inventory/*
  └── Deploy

Step 6: Retail Vertical Wrapper
  ├── Create retail schema
  ├── Create retail_products (extension of catalog_items)
  ├── Create retail_sales (extension of transactions)
  ├── Move pos_sessions to retail
  ├── Create RetailModule wrapping POS logic
  ├── Retail endpoints: /api/v1/retail/*
  └── Deploy

Step 7: Reporting Module
  ├── Extract reporting queries from PosService
  ├── Create ReportingService
  ├── New endpoints: /api/v1/reports/*
  └── Deploy

Step 8: Frontend Sync Update
  ├── Update repository API URLs to new endpoints
  ├── Update Isar models if response shapes changed
  ├── Test full sync cycle
  └── Deploy new APK

Step 9: Cleanup
  ├── Remove old PosModule, PosService
  ├── Remove old endpoint redirects
  ├── Remove public schema (all migrated)
  ├── Final regression testing
  └── Deploy
```

### 15.2 Data Migration (Per Step)

Each step uses a Prisma migration that:
1. Creates new table/schema
2. Copies data from old to new with `INSERT INTO ... SELECT FROM`
3. Adds indexes on new tables
4. Keeps old table as read-only fallback (until cleanup step)
5. Updates RLS policies on new tables

**Rollback:** Each migration has a reverse script. Old tables not dropped until Step 9.

### 15.3 Client Compatibility

During migration, the backend maintains backward compatibility:
- Old endpoints proxy to new services
- API response shapes preserved (frontend doesn't need immediate update)
- Frontend update (Step 8) can happen after all backend steps are complete

---

## Summary

| Metric | Value |
|:---|:---|
| **Architecture Pattern** | Modular Monolith (NestJS) + Offline-First Client (Flutter/Isar) |
| **Schemas** | 3 (kernel, shared, retail) |
| **Backend Components** | 5 kernel + 12 shared + 3 retail = 20 |
| **Client Components** | 3 core services + 5 repositories + 7 Isar collections |
| **API Endpoints** | ~50 REST endpoints |
| **FRs Covered** | 91/91 (100%) |
| **NFRs Covered** | 30/30 (100%) |
| **Migration Steps** | 9 incremental steps |
| **Key Innovation** | Offline-first ERP with polymorphic shared entities + chain-of-custody trust pattern |
| **v1.1 Additions** | 7 new shared models (variants, price levels, promotions, purchase orders, internal requests, batches) + 13 new fields across CatalogItem / StockMovement / Tenant |

---

*This architecture serves as the foundation for all implementation work. All development should trace back to the requirements and components documented here.*
