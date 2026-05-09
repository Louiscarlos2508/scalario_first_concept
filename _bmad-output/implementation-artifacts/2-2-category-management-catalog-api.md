# Story 2.2: Category Management & Catalog API

Status: review

## Story

As a shop owner,
I want to create and manage product categories and catalog items through the new shared API,
so that my products are organized and manageable from any vertical.

## Acceptance Criteria

1. **AC1 — shared.categories table + data migration:** Given the shared schema with catalog_items exists, when the categories migration runs, then:
   - `shared.categories` table is created with: `id` (UUID PK), `name` (TEXT NOT NULL), `tenant_id` (UUID NOT NULL), `created_at` (TIMESTAMPTZ default now())
   - Index exists on `(tenant_id)` for query performance
   - All rows from `public.categories` are migrated to `shared.categories` with same UUIDs (zero data loss)
   - `shared.catalog_items.category_id` has FK constraint → `shared.categories.id` ON DELETE SET NULL
   - `public.categories` table is dropped (data fully migrated to shared schema)

2. **AC2 — Prisma schema: Category in shared + CatalogItem @relation:** Given the migration is applied, when `prisma generate` runs, then:
   - `Category` model has `@@schema("shared")`
   - `CatalogItem` model has `@relation` on `categoryId` → `Category`
   - `Category` model has `items CatalogItem[]` reverse relation
   - `Product.categoryId` becomes a raw `String?` with no `@relation` (public.categories dropped; Product decomposed in Epic 6)
   - `products Product[]` reverse relation is removed from `Category` model

3. **AC3 — GET /api/v1/catalog/categories:** Given an authenticated user, when they call `GET /api/v1/catalog/categories?tenantId=<uuid>`, then all non-deleted categories for the tenant are returned ordered by name.

4. **AC4 — POST /api/v1/catalog/categories:** Given an authenticated Owner user, when they call `POST /api/v1/catalog/categories` with `{ name, tenantId }`, then a new Category is created in `shared.categories` and the created record is returned. A Commercial role user gets 403.

5. **AC5 — GET /api/v1/catalog/items:** Given an authenticated user, when they call `GET /api/v1/catalog/items` with optional `tenantId`, `q` (search), `page`, `limit`, then CatalogItems are returned with pagination shape `{ items, total, page, limit, totalPages }` — soft-deleted items excluded by default.

6. **AC6 — POST /api/v1/catalog/items + AuditLog:** Given an authenticated Owner user, when they call `POST /api/v1/catalog/items` with `{ name, price, tenantId, barcode?, categoryId?, itemType? }`, then:
   - A CatalogItem is created in `shared.catalog_items` with `item_type` defaulting to `'physical'`
   - An AuditLog entry is recorded: `action='CREATE'`, `entity='CatalogItem'`, `entityId=<new id>`
   - A Commercial role user gets 403.

7. **AC7 — DELETE /api/v1/catalog/items/:id + AuditLog:** Given an authenticated Owner user, when they call `DELETE /api/v1/catalog/items/:id`, then:
   - The item is soft-deleted (`is_deleted = true`), not physically removed
   - An AuditLog entry is recorded: `action='DELETE'`, `entity='CatalogItem'`, `entityId=<id>`
   - A Commercial role user gets 403.

8. **AC8 — @RequiresModule('catalog') gate:** Given the CatalogController has `@RequiresModule('catalog')` on the class, when a tenant without the `catalog` module activated calls any catalog endpoint, then ModuleGuard returns 403.

9. **AC9 — Old /pos/categories proxy:** Given the old `/pos/categories` endpoints still exist in PosController, when a client calls `GET /pos/categories`, `POST /pos/categories`, or `DELETE /pos/categories/:id`, then PosService delegates to CatalogService and returns identical response shapes.

10. **AC10 — Regression: 0 failures on existing 110 tests:** Given the existing test suite, when Story 2.2 changes are applied, all 110 tests continue to pass with zero regressions.

## Tasks / Subtasks

### Phase 1 — Migration file (AC1)

- [x] **1.1** Create directory: `apps/backend/prisma/migrations/20260315050000_shared_categories/`

- [x] **1.2** Create `migration.sql` with the following steps **in order**:
  1. `CREATE TABLE "shared"."categories"` with fields from AC1
  2. `CREATE INDEX "shared_categories_tenant_id_idx" ON "shared"."categories"("tenant_id")`
  3. `INSERT INTO "shared"."categories" SELECT id, name, tenant_id, created_at FROM "public"."categories"` (preserving UUIDs)
  4. `ALTER TABLE "shared"."catalog_items" ADD CONSTRAINT "catalog_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "shared"."categories"("id") ON DELETE SET NULL`
  5. `DROP TABLE "public"."categories" CASCADE` — removes public.categories and the FK from public.products.category_id → public.categories.id (CASCADE drops DB-level constraint only; Prisma @relation already removed in schema.prisma)

- [x] **1.3** Verify migration SQL: no DROP on `shared.catalog_items`, no DROP on `public.products`, no DROP on `shared.categories`. Only `public.categories` is dropped.

### Phase 2 — Prisma schema update (AC2)

- [x] **2.1** Update `Category` model in `apps/backend/prisma/schema.prisma`:
  - Change `@@schema("public")` → `@@schema("shared")`
  - Remove `products Product[]` relation (Product.category being removed)
  - Add `items CatalogItem[]` reverse relation
  - Keep `tenant Tenant @relation(fields: [tenantId], references: [id])` — cross-schema kernel→shared relation is valid since both are in the datasource schemas array
  - Keep all existing fields: id, name, tenantId, createdAt

- [x] **2.2** Update `CatalogItem` model:
  - Remove the comment `// Raw FK — no @relation yet; Category moves to shared in Story 2.2`
  - Add `@relation`: `category   Category?  @relation(fields: [categoryId], references: [id])`

- [x] **2.3** Update `Product` model:
  - Remove `category   Category?  @relation(fields: [categoryId], references: [id])` line entirely
  - Keep `categoryId     String?         @map("category_id") @db.Uuid` as raw field
  - Add comment: `// Raw FK — no @relation; Category moved to shared in Story 2.2; Product decomposed in Epic 6`

- [x] **2.4** Update `Tenant` model relation list: `categories Category[]` stays as-is (cross-schema kernel→shared relation; valid with multiSchema)

- [x] **2.5** Run `npx prisma generate` from `apps/backend/` to verify schema is valid and regenerate client. Confirm no cross-schema relation errors. If cross-schema Tenant→Category @relation causes errors, see Dev Notes fallback strategy.

### Phase 3 — CatalogModule implementation (AC3–AC8)

- [x] **3.1** Create `apps/backend/src/shared/catalog/catalog.service.ts` with:
  - Inject `PrismaService` and `AuditLogService` (both available globally — no explicit module import needed)
  - `getCategories(tenantId: string)` → `prisma.category.findMany({ where: { tenantId }, orderBy: { name: 'asc' } })`
  - `createCategory(data: { name: string; tenantId: string })` → `prisma.category.create({ data })`
  - `deleteCategory(id: string)` → `prisma.category.delete({ where: { id } })`
  - `getItems(params: { tenantId?: string; query?: string; page?: number; limit?: number })` → `prisma.catalogItem.findMany(...)` with pagination; returns `{ items, total, page, limit, totalPages }`
  - `createItem(data: { name, price, tenantId, barcode?, categoryId?, itemType? }, userId: string | null)` → creates CatalogItem + calls `auditLog.log({ action: 'CREATE', entity: 'CatalogItem', ... })`
  - `deleteItem(id: string, userId: string | null, tenantId: string)` → soft-delete (`is_deleted: true`) + calls `auditLog.log({ action: 'DELETE', entity: 'CatalogItem', ... })`

- [x] **3.2** Create `apps/backend/src/shared/catalog/catalog.controller.ts`:
  - `@Controller('catalog')` — routes mount at `/catalog` (global prefix `/api/v1` gives `/api/v1/catalog`)
  - `@RequiresModule('catalog')` on the class (applies ModuleGuard to all endpoints)
  - No explicit `@UseGuards()` — APP_GUARD chain handles everything globally
  - `GET /catalog/categories` — no `@Roles` (all authenticated members)
  - `POST /catalog/categories` — `@Roles('owner')`
  - `GET /catalog/items` — no `@Roles`
  - `POST /catalog/items` — `@Roles('owner')`; inject `@Req() req: any`; pass `req.user?.sub ?? null` as userId
  - `DELETE /catalog/items/:id` — `@Roles('owner')`; inject `@Req() req: any` and `@Query('tenantId') tenantId`; pass userId
  - Use `@Query`, `@Body`, `@Param` — no DTOs, consistent with existing controllers

- [x] **3.3** Create `apps/backend/src/shared/catalog/catalog.module.ts`:
  ```typescript
  @Module({
    providers: [CatalogService],
    controllers: [CatalogController],
    exports: [CatalogService],
  })
  export class CatalogModule {}
  ```
  No explicit imports needed (PrismaService and AuditLogService come from global modules).

- [x] **3.4** Register `CatalogModule` in `apps/backend/src/app.module.ts` imports array.

### Phase 4 — POS proxy (AC9)

- [x] **4.1** Add `CatalogModule` to `PosModule` imports in `apps/backend/src/pos/pos.module.ts`.

- [x] **4.2** Inject `CatalogService` into `PosService` constructor.

- [x] **4.3** Update `PosService` proxy methods:
  - `getCategories(tenantId: string)` → `return this.catalogService.getCategories(tenantId)`
  - `createCategory(data: any)` → `return this.catalogService.createCategory(data)`
  - `deleteCategory(id: string)` → `return this.catalogService.deleteCategory(id)`

### Phase 5 — Tests (AC10)

- [x] **5.1** Create `apps/backend/src/shared/catalog/catalog.service.spec.ts`:
  - Mock `PrismaService` (catalogItem.findMany, catalogItem.create, catalogItem.update, catalogItem.count, category.findMany, category.create, category.delete)
  - Mock `AuditLogService` (log method)
  - Test getCategories, createCategory, deleteCategory
  - Test getItems pagination
  - Test createItem: item created + auditLog.log called with action='CREATE'
  - Test deleteItem: item soft-deleted + auditLog.log called with action='DELETE'

- [x] **5.2** Create `apps/backend/src/shared/catalog/catalog.controller.spec.ts`:
  - Mock `CatalogService`
  - Test all 5 endpoints respond correctly and call the right service method

- [x] **5.3** Run `npx jest --no-coverage` from `apps/backend/` — all 110 existing + new tests pass.

## Dev Notes

### Scope Boundary — What Story 2.2 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| Delta sync `/catalog/items?since=...` | Story 2.3 | Sync adapter |
| `CatalogModule.register()` DynamicModule pattern | Story 2.3 | Module refactor |
| `POST /catalog/items/sync` (bulk upsert) | Story 2.3 | Bulk sync |
| RLS policy on shared.categories | Story 2.3+ | After full catalog API |
| `RetailProduct` model + stock_quantity | Epic 6 | Vertical extension |
| Remove `public.products` | Epic 6 | After full decomposition |
| StockMovement → CatalogItem relation | Epic 5 | Inventory module |
| AuditLog on category create/delete | Optional | Not in Epic 2 ACs |

### Critical: Cross-Schema @relation on Category

After Category moves to `@@schema("shared")`, the `tenant Tenant @relation` creates a cross-schema relation: `shared.categories.tenant_id → kernel.tenants.id`. Prisma multiSchema supports cross-schema relations **when both schemas are listed in the datasource `schemas` array**. Both `kernel` and `shared` are in `schemas = ["kernel", "shared", "public"]`, so this is valid.

**If `npx prisma generate` fails with a cross-schema relation error on Tenant↔Category**, use this fallback:
- Remove `tenant Tenant @relation(...)` from Category model
- Keep `tenantId String @map("tenant_id") @db.Uuid` as raw field (no @relation)
- Remove `categories Category[]` from Tenant model
- This is the same pattern as CatalogItem.tenantId

Run `npx prisma generate` immediately after schema changes. It will catch cross-schema relation issues before migration.

### Critical: Product.category @relation Must Be Removed

`Product` currently has:
```prisma
categoryId     String?         @map("category_id") @db.Uuid
category       Category?       @relation(fields: [categoryId], references: [id])
```

After `public.categories` is dropped (Category moves to `shared`), a cross-schema `public.products → shared.categories` relation would be architecturally incorrect (Product will be decomposed in Epic 6). Remove the `@relation` line. Keep `categoryId` as a raw `String?`.

Also remove `products Product[]` from the Category model — it was the reverse side of this relation.

### Migration: Exact SQL with DROP Order

```sql
-- Story 2.2: Migrate public.categories → shared.categories
-- shared schema already exists from Story 2.1
-- public.products remains intact (unchanged — decomposed in Epic 6)

-- Step 1: Create shared.categories table
CREATE TABLE "shared"."categories" (
    "id"         UUID         NOT NULL DEFAULT gen_random_uuid(),
    "name"       TEXT         NOT NULL,
    "tenant_id"  UUID         NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- Step 2: Index on tenant_id for query performance
CREATE INDEX "shared_categories_tenant_id_idx"
    ON "shared"."categories"("tenant_id");

-- Step 3: Data migration — preserve UUIDs for catalog_items FK integrity
INSERT INTO "shared"."categories" ("id", "name", "tenant_id", "created_at")
SELECT "id", "name", "tenant_id", "created_at"
FROM "public"."categories";

-- Step 4: Add FK constraint on catalog_items.category_id → shared.categories.id
ALTER TABLE "shared"."catalog_items"
    ADD CONSTRAINT "catalog_items_category_id_fkey"
    FOREIGN KEY ("category_id")
    REFERENCES "shared"."categories"("id")
    ON DELETE SET NULL;

-- Step 5: Drop public.categories
-- CASCADE removes DB-level FK from public.products.category_id → public.categories.id
-- public.products.category_id column itself is NOT dropped (stays as orphaned UUID column)
DROP TABLE "public"."categories" CASCADE;

-- NOTE: public.products is NOT dropped (stays intact until Epic 6)
-- NOTE: shared.catalog_items is NOT dropped (Story 2.1 table, now has FK to shared.categories)
-- NOTE: Product.categoryId data in DB remains valid as raw UUIDs (no DB-level constraint after DROP CASCADE)
```

### UUID Preservation Is Critical

Categories must keep the same UUIDs in shared.categories. The existing `shared.catalog_items.category_id` values (migrated in Story 2.1) reference `public.categories.id`. After migration, the FK constraint on catalog_items.category_id will reference shared.categories.id. Both tables have the same UUID values, so the FK constraint will be satisfied.

Order **must** be:
1. INSERT shared.categories (from public.categories) ← UUIDs now in shared
2. ADD FK on catalog_items.category_id → shared.categories.id ← can validate existing UUIDs
3. DROP public.categories ← safe after FK is added to shared.categories

### CatalogService: AuditLogService Injection Pattern

KernelModule is `@Global()` and exports AuditLogModule, which exports AuditLogService. This means AuditLogService is injectable in **any module** without explicit import. Proven by OrganizationModule which injects AuditLogService without importing AuditLogModule.

CatalogModule does NOT need to import KernelModule or AuditLogModule:
```typescript
@Module({
  providers: [CatalogService],
  controllers: [CatalogController],
  exports: [CatalogService],
})
export class CatalogModule {}
```

CatalogService constructor (both globally provided):
```typescript
constructor(
  private readonly prisma: PrismaService,
  private readonly auditLog: AuditLogService,
) {}
```

### CatalogService: getItems() Response Shape

Must match PosService.getProducts() shape exactly for backward compat:
```typescript
{
  items: CatalogItem[],
  total: number,
  page: number,
  limit: number,
  totalPages: number
}
```

Filter logic (mirrors PosService.getProducts):
- Exclude `is_deleted: true` by default
- `since` query: include all (including deleted) for delta sync tombstoning (Story 2.3 adds this properly)
- `query` string: case-insensitive contains on `name` and `barcode`

### CatalogController: How to Get userId for AuditLog

AuthGuard sets `request.user` to the decoded JWT payload. Use `@Req() req: any` and extract `req.user?.sub`:
```typescript
@Post('items')
@Roles('owner')
async createItem(@Body() body: any, @Req() req: any) {
  const userId = req.user?.sub ?? null;
  return this.catalogService.createItem(body, userId);
}

@Delete('items/:id')
@Roles('owner')
async deleteItem(@Param('id') id: string, @Query('tenantId') tenantId: string, @Req() req: any) {
  const userId = req.user?.sub ?? null;
  return this.catalogService.deleteItem(id, userId, tenantId);
}
```

No `@UseGuards()` needed — the APP_GUARD chain (Auth → Tenant → Module → Roles) handles everything globally.

### Guard Chain: How @RequiresModule and @Roles Work

From [kernel.module.ts](apps/backend/src/kernel/kernel.module.ts), the guard chain is registered via APP_GUARD:
- `AuthGuard` — validates JWT token
- `TenantGuard` — validates tenant context
- `ModuleGuard` — reads `REQUIRES_MODULE_KEY` metadata; blocks if tenant doesn't have module active
- `RolesGuard` — reads `ROLES_KEY` metadata; blocks if user role not in allowed list

Usage in CatalogController:
```typescript
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('catalog')
@RequiresModule('catalog')    // applies to all methods via ModuleGuard
export class CatalogController {
  @Get('categories')          // no @Roles — all authenticated members can read
  async getCategories(@Query('tenantId') tenantId: string) { ... }

  @Post('categories')
  @Roles('owner')             // only owner role can create
  async createCategory(@Body() body: any) { ... }
  ...
}
```

### PosModule: Import CatalogModule for Proxy

```typescript
// pos.module.ts
import { CatalogModule } from '../shared/catalog/catalog.module';

@Module({
  imports: [CatalogModule],
  providers: [PosService, PosSessionService, CustomerService],
  controllers: [PosController, PosSessionController, CustomerController],
})
export class PosModule {}
```

PosService constructor receives CatalogService:
```typescript
constructor(
  private prisma: PrismaService,
  private catalogService: CatalogService,
) {}
```

The proxy methods in PosService just delegate:
```typescript
async getCategories(tenantId: string) {
  return this.catalogService.getCategories(tenantId);
}
async createCategory(data: any) {
  return this.catalogService.createCategory(data);
}
async deleteCategory(id: string) {
  return this.catalogService.deleteCategory(id);
}
```

### Global Route Prefix

Verify the global prefix in `apps/backend/src/main.ts`. If `app.setGlobalPrefix('api/v1')` is set, then `@Controller('catalog')` registers endpoints at `/api/v1/catalog/...`. Check main.ts before implementing to confirm the prefix.

### prisma migrate dev Is Blocked

Same constraint as Stories 1.6 and 2.1 — `prisma migrate dev` is blocked in non-interactive environments.

Procedure:
1. Create directory manually: `apps/backend/prisma/migrations/20260315050000_shared_categories/`
2. Write `migration.sql` manually (see exact SQL above)
3. Run `npx prisma generate` to validate schema changes
4. Verify migration SQL has zero `DROP TABLE` on anything except `public.categories`

### Test: Mock Patterns

For CatalogService spec, use the standard mock pattern (no `jest.resetAllMocks()` risk if you use `jest.clearAllMocks()` instead):

```typescript
const mockPrisma = {
  catalogItem: {
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  },
  category: {
    findMany: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
  },
};

const mockAuditLog = {
  log: jest.fn(),
};
```

If using `jest.resetAllMocks()` in `beforeEach`, re-initialize all `mockReturnValue` calls inside `beforeEach` (not in `describe` scope). See learnings from Story 1.x.

### Existing Test Suite: PosService Mocks

PosService tests currently mock `prisma.category` methods. After injecting CatalogService into PosService, PosService tests will need CatalogService mocked too. Add a `mockCatalogService` to the PosService spec if it exists, OR leave it as-is if PosService tests don't test the proxy methods (they may test syncOrder, syncProduct etc which don't use catalogService).

Check existing PosService spec (if any) before modifying.

### Project Structure Notes

Files to create/modify:
```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — Category @@schema → shared; CatalogItem @relation; Product.category removed]
└── migrations/
    └── 20260315050000_shared_categories/
        └── migration.sql                              [NEW]

apps/backend/src/
├── shared/
│   └── catalog/
│       ├── catalog.service.ts                         [NEW]
│       ├── catalog.service.spec.ts                    [NEW]
│       ├── catalog.controller.ts                      [NEW]
│       ├── catalog.controller.spec.ts                 [NEW]
│       └── catalog.module.ts                          [NEW]
├── pos/
│   ├── pos.module.ts                                  [MODIFY — add CatalogModule import]
│   └── pos.service.ts                                 [MODIFY — inject CatalogService; proxy 3 category methods]
└── app.module.ts                                      [MODIFY — add CatalogModule import]
```

### References

- [Architecture §5.1 Shared Catalog + Category](docs/architecture-scalario-2026-03-08.md)
- [Architecture §5.3 Multi-schema datasource + cross-schema relations](docs/architecture-scalario-2026-03-08.md)
- [Architecture §6.1 Guard chain + @RequiresModule pattern](docs/architecture-scalario-2026-03-08.md)
- [Epic 2 Story 2.2 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 2.1 learnings](_bmad-output/implementation-artifacts/2-1-shared-schema-catalogitem-entity.md)
- [AuditLogService API](apps/backend/src/kernel/audit/audit-log.service.ts)
- [Roles decorator](apps/backend/src/kernel/rbac/roles.decorator.ts)
- [RequiresModule decorator](apps/backend/src/kernel/modules/module.decorator.ts)
- [OrganizationModule — AuditLogService injection pattern](apps/backend/src/organization/organization.module.ts)
- [PosService — proxy source + getCategories/createCategory/deleteCategory](apps/backend/src/pos/pos.service.ts)
- [KernelModule @Global exports](apps/backend/src/kernel/kernel.module.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- **AC1 (migration):** Created `20260315050000_shared_categories/migration.sql`. Steps: CREATE TABLE shared.categories → CREATE INDEX (tenant_id) → INSERT from public.categories (UUID-preserving) → ADD FK on catalog_items.category_id → DROP public.categories CASCADE. Verified: only executable DROP is `public.categories`.
- **AC2 (Prisma schema):** Category moved from `@@schema("public")` → `@@schema("shared")`. `products Product[]` removed; `items CatalogItem[]` added. `CatalogItem.category Category? @relation(...)` added. `Product.category @relation` removed; `categoryId` kept as raw String?. `Tenant.categories Category[]` retained (cross-schema kernel→shared — valid with multiSchema). `prisma generate` succeeded, Prisma Client v5.22.0 regenerated.
- **AC3–AC5 (catalog read endpoints):** `GET /catalog/categories`, `GET /catalog/items` implemented in CatalogController. CatalogService.getCategories() and getItems() with pagination `{ items, total, page, limit, totalPages }`.
- **AC6 (POST /catalog/items + AuditLog):** CatalogService.createItem() creates in shared.catalog_items with itemType defaulting to 'physical', then logs CREATE audit entry.
- **AC7 (DELETE /catalog/items/:id + AuditLog):** CatalogService.deleteItem() soft-deletes (isDeleted=true) + logs DELETE audit entry with before/after.
- **AC8 (@RequiresModule):** `@RequiresModule('catalog')` applied at CatalogController class level. No explicit @UseGuards — APP_GUARD chain handles it.
- **AC9 (POS proxy):** PosModule imports CatalogModule. PosService injects CatalogService. getCategories/createCategory/deleteCategory delegate to catalogService.
- **AC10 (regressions):** **128/128 tests pass** (110 existing + 18 new catalog tests). Zero regressions.
- **Key finding:** `main.ts` has no `app.setGlobalPrefix('api/v1')` — catalog routes mount at `/catalog/...` (consistent with existing `/pos/...` pattern). Story 2.3 stories should use same convention.
- **AuditLogService injection:** Confirmed via OrganizationModule pattern — @Global KernelModule re-exports AuditLogModule → AuditLogService injectable without explicit import in CatalogModule.
- **Cross-schema @relation confirmed working:** Tenant (`@@schema("kernel")`) → Category (`@@schema("shared")`) relation validated by `prisma generate`.

### File List

**New files:**
- `apps/backend/prisma/migrations/20260315050000_shared_categories/migration.sql`
- `apps/backend/src/shared/catalog/catalog.service.ts`
- `apps/backend/src/shared/catalog/catalog.service.spec.ts`
- `apps/backend/src/shared/catalog/catalog.controller.ts`
- `apps/backend/src/shared/catalog/catalog.controller.spec.ts`
- `apps/backend/src/shared/catalog/catalog.module.ts`

**Modified files:**
- `apps/backend/prisma/schema.prisma` — Category moved to shared schema; CatalogItem @relation added; Product.category @relation removed
- `apps/backend/src/app.module.ts` — CatalogModule registered
- `apps/backend/src/pos/pos.module.ts` — CatalogModule imported
- `apps/backend/src/pos/pos.service.ts` — CatalogService injected; 3 category methods proxied
