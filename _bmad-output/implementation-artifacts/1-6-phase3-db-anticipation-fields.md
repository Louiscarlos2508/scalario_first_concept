# Story 1.6: Phase 3 DB Anticipation Fields

Status: review

## Story

As a system architect,
I want to add all Phase 2b/3 anticipation fields in a single dedicated Prisma migration,
so that Scalario Connect, Enterprise, and Programme Ambassadeurs can be activated in future phases without a breaking migration on a live multi-tenant system.

## Acceptance Criteria

1. **AC1 — kernel.tenants anticipation fields:** Given Epic 1 stories 1.1–1.5 are complete, when the Phase 3 anticipation migration runs, then the following fields are added to `kernel.tenants` with zero data loss:
   - `referred_by UUID nullable FK → tenants.id` (FR52 — Programme Ambassadeurs Phase 2b)
   - `network_visible Boolean DEFAULT false` (FR52 — Scalario Connect Phase 3)
   - `parent_tenant_id UUID nullable FK → tenants.id` (FR59 — Enterprise Fédéré Phase 3)
   - **Note:** `org_mode` already exists in the schema (added in Story 1.1). Do NOT re-add it.

2. **AC2 — kernel.organization_members anticipation field:** Given the migration runs, when existing organization member rows are read, then `department_ids UUID[] DEFAULT []` is present with an empty array for all existing rows (FR60 — Enterprise Phase 3).

3. **AC3 — kernel.tenant_modules anticipation field:** Given the migration runs, when existing tenant_module rows are read, then `department_id UUID nullable` is present with null for all existing rows (FR61 — Enterprise Phase 3).

4. **AC4 — Shared schema fields deferred to respective Epics:** Given `CatalogItem`, `Contact`, and `Transaction` models do not yet exist in the Prisma schema, then:
   - `shared.contacts.linked_tenant_id` — add when `Contact` model is created in **Epic 3, Story 3-1**
   - `shared.catalog_items.supplier_reference` — add when `CatalogItem` model is created in **Epic 2, Story 2-1**
   - `shared.transactions.transaction_type += 'transfer_inter_tenant'` — add when `Transaction` model is created in **Epic 4, Story 4-1**
   - Story 1.6 explicitly excludes these (models don't exist). Dev Notes for Epics 2–4 must include these fields.

5. **AC5 — Backward compatibility:** Given existing RLS policies and guard chain are unchanged, when the 3 existing POS clients continue to operate after the migration, then all nullable fields return null, `network_visible` returns false, and no existing query is broken. No endpoint, service, or guard is modified.

6. **AC6 — Prisma schema comments:** Given each new column is added, then each Prisma field has a triple-slash comment (`///`) documenting its phase and purpose (matching the architecture doc pattern).

## Tasks / Subtasks

### Phase 1 — Schema update (Prisma)
- [x] **1.1** Update `apps/backend/prisma/schema.prisma` — add 3 fields to `Tenant` model:
  - `referredBy String? @map("referred_by") @db.Uuid` with `/// Phase 2b — Programme Ambassadeurs` comment
  - `networkVisible Boolean @default(false) @map("network_visible")` with `/// Phase 3 — Scalario Connect` comment
  - `parentTenantId String? @map("parent_tenant_id") @db.Uuid` with `/// Phase 3 — Scalario Enterprise (federated mode)` comment
- [x] **1.2** Update `apps/backend/prisma/schema.prisma` — add 1 field to `OrganizationMember` model:
  - `departmentIds String[] @default([]) @map("department_ids") @db.Uuid` with `/// Phase 3 — Scalario Enterprise` comment
- [x] **1.3** Update `apps/backend/prisma/schema.prisma` — uncomment/add 1 field to `TenantModule` model:
  - `departmentId String? @map("department_id") @db.Uuid` with `/// Phase 3 — Scalario Enterprise (department-scoped module activation)` comment

### Phase 2 — Migration
- [x] **2.1** Run `npx prisma migrate dev --name phase3_anticipation_fields` from `apps/backend/` to generate the migration SQL. Verify the migration file is created under `prisma/migrations/YYYYMMDD_phase3_anticipation_fields/`.
- [x] **2.2** Verify the generated SQL adds only ADD COLUMN statements — no DROP, no ALTER TYPE breaking changes, no data loss.
- [x] **2.3** Run `npx prisma generate` to regenerate the Prisma client types.

### Phase 3 — Regression check
- [x] **3.1** Run `npx jest --testPathPattern=organization.service.spec` and confirm all existing tests pass. The new nullable fields on Tenant/OrganizationMember/TenantModule must not affect existing mock expectations (mocks return plain objects; Prisma doesn't validate extra fields).
- [x] **3.2** Run the full test suite (`npx jest`) from `apps/backend/` — verify 0 regressions. The schema change is additive; no service or guard code changes, so no test should fail.

## Dev Notes

### Critical: What Already Exists — Do NOT Re-Add

The following field was already added to `Tenant` in Story 1.1's migration (`20260313000000_kernel_schema_tenant_auth`):

```prisma
orgMode String @default("standalone") @map("org_mode")
```

**DO NOT add `orgMode` again** — it's already in the schema and migration. Adding it again would produce a Prisma migrate error ("field already exists").

### Architecture Target State for Kernel Models

From `docs/architecture-scalario-2026-03-08.md` §5.2, the target `Tenant` model (post Story 1.6):

```prisma
model Tenant {
  id                    String               @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name                  String
  currency              String               @default("XOF")
  timezone              String               @default("Africa/Abidjan")
  fiscalJurisdiction    String?              @map("fiscal_jurisdiction")
  status                String               @default("active")
  sessionTimeoutMinutes Int                  @default(480) @map("session_timeout_minutes")
  orgMode               String               @default("standalone") @map("org_mode")  // ALREADY EXISTS
  createdAt             DateTime             @default(now()) @map("created_at") @db.Timestamptz(6)

  // Phase 2b — Programme Ambassadeurs. FK to tenants.id (self-reference).
  /// Phase 2b — Programme Ambassadeurs. Populated when tenant is created via referral.
  referredBy            String?              @map("referred_by") @db.Uuid

  // Phase 3 — Scalario Connect
  /// Phase 3 — Scalario Connect. Tenant discoverable on B2B network.
  networkVisible        Boolean              @default(false) @map("network_visible")

  // Phase 3 — Scalario Enterprise (federated mode only)
  /// Phase 3 — Scalario Enterprise. FK to tenants.id of parent Groupe tenant.
  parentTenantId        String?              @map("parent_tenant_id") @db.Uuid

  // Relations (unchanged)
  members               OrganizationMember[]
  tenantModules         TenantModule[]
  auditLogs             AuditLog[]
  // ... other existing relations

  @@map("tenants")
  @@schema("kernel")
}
```

Target `OrganizationMember` model (post Story 1.6):

```prisma
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
```

Target `TenantModule` model (post Story 1.6):

```prisma
model TenantModule {
  id          String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  tenantId    String    @map("tenant_id") @db.Uuid
  moduleId    String    @map("module_id") @db.Uuid
  status      String    @default("inactive")
  activatedAt DateTime? @map("activated_at") @db.Timestamptz(6)
  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  module      Module    @relation(fields: [moduleId], references: [id])

  /// Phase 3 — Scalario Enterprise. Null = tenant-wide activation (Retail). Set = department-scoped.
  departmentId String?  @map("department_id") @db.Uuid

  @@unique([tenantId, moduleId])
  @@map("tenant_modules")
  @@schema("kernel")
}
```

### Shared Schema Fields — NOT in This Story

The following anticipation fields exist in the architecture target but **their parent models don't exist yet** in Prisma. They are deferred to the respective epics and must be included when creating those models:

| Field | Model | Target Story |
|-------|-------|-------------|
| `linked_tenant_id UUID nullable` | `Contact` (shared) | Epic 3, Story 3-1 (FR53) |
| `supplier_reference UUID nullable` | `CatalogItem` (shared) | Epic 2, Story 2-1 (FR54) |
| `transaction_type += 'transfer_inter_tenant'` | `Transaction` (shared) | Epic 4, Story 4-1 (FR55) |

**The SM (story creator) for those stories MUST include these fields** — otherwise Phase 3 will require breaking migrations.

### Migration File Naming

The existing migration sequence:
```
20260209122705_init_pos_schema
20260210185902_add_terminal_status
20260211001729_add_categories_and_fix_naming
20260313000000_kernel_schema_tenant_auth
20260315000000_rbac_roles_permissions
20260315010000_module_registry
20260315020000_audit_log_event_bus
```

The new migration generated by `prisma migrate dev --name phase3_anticipation_fields` will be timestamped automatically. The `--name` flag sets the suffix; Prisma adds the timestamp prefix.

### Expected Migration SQL Shape

The generated migration SQL should contain **only ADD COLUMN statements**:

```sql
-- AddColumn: kernel.tenants
ALTER TABLE "kernel"."tenants" ADD COLUMN "referred_by" UUID;
ALTER TABLE "kernel"."tenants" ADD COLUMN "network_visible" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "kernel"."tenants" ADD COLUMN "parent_tenant_id" UUID;

-- AddColumn: kernel.organization_members
ALTER TABLE "kernel"."organization_members" ADD COLUMN "department_ids" UUID[] NOT NULL DEFAULT '{}';

-- AddColumn: kernel.tenant_modules
ALTER TABLE "kernel"."tenant_modules" ADD COLUMN "department_id" UUID;
```

**No DROP COLUMN, no ALTER TABLE renames, no data transforms** — purely additive.

### Prisma `@db.Uuid` on Array Fields

PostgreSQL supports `UUID[]` natively. In Prisma, for array UUID fields:
```prisma
departmentIds String[] @default([]) @map("department_ids") @db.Uuid
```
Note: `@db.Uuid` applies to the element type, not the array itself. This is correct Prisma syntax for `UUID[]`.

### Self-Referential FK in Tenant (`parentTenantId → tenants.id`)

The `parentTenantId` is a plain nullable `String?` (not a Relation in Prisma). This avoids circular relation complexity for now. When Enterprise mode is implemented (Epic 13), the relation will be added then. For now, it's stored as a raw UUID:

```prisma
/// Phase 3 — Scalario Enterprise. FK to tenants.id of parent Groupe tenant.
parentTenantId String? @map("parent_tenant_id") @db.Uuid
// NOT declared as @relation — Epic 13 adds the relation when needed
```

Same pattern for `referredBy`:
```prisma
/// Phase 2b — Programme Ambassadeurs. FK to tenants.id (self-reference via referral).
referredBy String? @map("referred_by") @db.Uuid
// NOT declared as @relation — Epic 11 adds the relation when needed
```

This avoids Prisma requiring matching `@relation` fields on the same model, which would complicate seeds and tests.

### Test Impact Analysis

**No service, guard, or controller changes** — this is schema-only. The only things to verify:

1. `OrganizationService.spec.ts` mocks return `{}` objects for Prisma calls — adding nullable fields to the model doesn't break these mocks (TypeScript structural typing + jest mock ignores extra fields).
2. `TenancyService.spec.ts` mocks Prisma `tenant.create` — new nullable fields won't affect the mock (they're optional in the generated type).
3. `ModuleRegistryService.spec.ts` mocks `tenantModule.findFirst` and `tenantModule.upsert` — `departmentId` is nullable, doesn't affect existing test expectations.

**No new unit test file needed** — the spec files remain unchanged. The regression check (Task 3.2) runs the existing suite.

### Learnings from Story 1.5 (apply here)

- **`jest.resetAllMocks()` pattern:** If adding mock data for Tenant in future tests, re-initialize `getClient.mockReturnValue` in `beforeEach`.
- **`PrismaModule` is `@Global()`** — service tests don't import PrismaModule directly.
- **`mockResolvedValue(undefined)` for void methods.**
- **Migration state:** `prisma migrate dev` against a real DB. If running in CI without a DB, use `prisma migrate deploy` + `prisma generate`.

### Business Logic Guard

> **ZERO business logic in this story.** No controller, service, guard, decorator, or module changes. If you find yourself writing TypeScript application code beyond `schema.prisma` edits and migration commands, STOP — you are out of scope.

### Functional Requirements Traceability

| FR | Description | Field | Covered By |
|----|-------------|-------|------------|
| FR52 | Connect: tenant network visibility + referral tracking | `tenants.referred_by`, `tenants.network_visible` | AC1 |
| FR59 | Enterprise: org mode + hierarchy | `tenants.org_mode` (done S1.1), `tenants.parent_tenant_id` | AC1 |
| FR60 | Enterprise: department membership | `organization_members.department_ids` | AC2 |
| FR61 | Enterprise: department-scoped module activation | `tenant_modules.department_id` | AC3 |
| FR53 | Connect: supplier contact linkage | `contacts.linked_tenant_id` | Deferred → Epic 3 |
| FR54 | Connect: catalog supplier reference | `catalog_items.supplier_reference` | Deferred → Epic 2 |
| FR55 | Connect: inter-tenant transaction type | `transaction_type` enum value | Deferred → Epic 4 |

### Project Structure Notes

Files to modify in this story:
```
apps/backend/prisma/
├── schema.prisma                          [MODIFY — add 5 fields across 3 models]
└── migrations/
    └── <timestamp>_phase3_anticipation_fields/
        └── migration.sql                  [GENERATED by prisma migrate dev]
```

**No other files.** Not kernel/, not organization/, not pos/.

### References

- Architecture §5.2 (Prisma multi-schema target state): `docs/architecture-scalario-2026-03-08.md`
- Architecture §AD8 (Multi-phase expansion driver): `docs/architecture-scalario-2026-03-08.md` line 44
- Epics file — Story 1.6 ACs: `_bmad-output/planning-artifacts/epics.md` lines 441–517
- FR52–FR61 traceability: `docs/architecture-scalario-2026-03-08.md` §FR Traceability Table
- Schema evolution strategy: `docs/architecture-scalario-2026-03-08.md` §15.1

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Schema-only story — 0 service/guard/controller changes, 0 new test files.
- **AC1 (kernel.tenants):** Added `referredBy` (nullable UUID), `networkVisible` (Boolean default false), `parentTenantId` (nullable UUID). `orgMode` already existed from Story 1.1 — not re-added.
- **AC2 (kernel.organization_members):** Added `departmentIds` (UUID[] default []). Existing rows get empty array automatically via column DEFAULT.
- **AC3 (kernel.tenant_modules):** Uncommented `departmentId` (nullable UUID). Existing rows get null automatically.
- **AC4 (shared schema deferred):** `contacts.linked_tenant_id`, `catalog_items.supplier_reference`, `transactions.transfer_inter_tenant` deferred to Epics 2–4 (models don't exist yet). Cross-references documented in story Dev Notes.
- **AC5 (backward compat):** 110/110 existing tests pass — 0 regressions. Additive schema change doesn't affect mock-based unit tests.
- **AC6 (Prisma comments):** All 5 new fields have `///` triple-slash comments documenting phase and purpose.
- **Migration:** `prisma migrate dev` blocked by non-interactive environment. Used `prisma migrate diff --script` to verify exact SQL (5 pure ADD COLUMN statements, no DROP/ALTER breaking changes), then created migration file manually at `prisma/migrations/20260315030000_phase3_anticipation_fields/migration.sql`.
- **`prisma generate`:** Ran successfully — Prisma Client v5.22.0 regenerated with new field types.
- **Self-referential FKs:** `referredBy` and `parentTenantId` stored as raw `String?` (no `@relation`) to avoid circular Prisma relation complexity. Full relations added in Epics 11/13.

### File List

**Modified files:**
- `apps/backend/prisma/schema.prisma` — added 5 Phase 3 anticipation fields across 3 kernel models

**New files:**
- `apps/backend/prisma/migrations/20260315030000_phase3_anticipation_fields/migration.sql` — 5 ADD COLUMN statements, purely additive
