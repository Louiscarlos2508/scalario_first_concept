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
| FR10 | Epic 1 | One vertical per tenant (MVP) |
| FR11 | Epic 2 | CRUD catalog items |
| FR12 | Epic 2 | itemType discriminator |
| FR13 | Epic 6 | Vertical extension fields (RetailProduct) |
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
| FR52 | Epic 9 | Zero-loss data migration |
| FR53 | Epic 9 | Multi-schema Prisma |
| FR54 | Epic 8 | Module-agnostic sync adapters |

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
Frontend repositories updated to new API endpoints, Isar models aligned with new response shapes, full offline-first experience preserved: delta sync, crash recovery (WAL), conflict resolution, outbox queue, connectivity indicator, configurable data retention. Module-agnostic sync adapters.
**FRs covered:** FR41, FR42, FR43, FR44, FR45, FR46, FR47, FR54

### Epic 9: Data Migration & Client Cutover
All 3 existing clients migrated from monolithic public schema to kernel/shared/retail multi-schema architecture with zero data loss. Old endpoint proxies removed, cleanup completed, full regression validated.
**FRs covered:** FR52, FR53

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
**Then** MVP roles are created for retail vertical: Owner (full access), Manager (stock/reports), Commercial (POS/sales), each with predefined permissions matching the PRD RBAC matrix

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

**Given** a tenant already has one active vertical
**When** admin attempts to activate a second vertical
**Then** the system rejects the activation (MVP: one vertical per tenant)

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
