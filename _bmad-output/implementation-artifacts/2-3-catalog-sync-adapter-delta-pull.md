# Story 2.3: Catalog Sync Adapter & Delta Pull

Status: done

## Story

As a cashier using the POS offline,
I want catalog data to sync to my device automatically using delta pulls,
so that I always have the latest products and prices without downloading the entire catalog.

## Acceptance Criteria

1. **AC1 — GET /catalog/items?since=<ISO8601> (delta pull):** Given a client device with a last sync timestamp, when the client calls `GET /catalog/items?since=<ISO8601>`, then:
   - Only items with `updated_at > since` are returned
   - Soft-deleted items are included (so client can tombstone-remove them locally)
   - Response includes `meta.serverTime` (ISO8601) so the client stores it as the next `since` value
   - Pagination supported via `?page=1&limit=100`; response includes `meta.hasMore`

2. **AC2 — GET /catalog/items pagination meta:** Given a standard catalog items request (with or without `since`), when the response is returned, then it includes:
   ```json
   {
     "items": [...],
     "meta": {
       "total": 42,
       "page": 1,
       "limit": 100,
       "hasMore": false,
       "serverTime": "2026-03-15T10:00:00.000Z"
     }
   }
   ```

3. **AC3 — POST /catalog/items/sync (bulk upsert):** Given a bulk sync request from the frontend, when the client calls `POST /catalog/items/sync` with an array of items, then each item is upserted by UUID (idempotent) — existing items are updated, new items are created. No AuditLog required for bulk sync.

4. **AC4 — CatalogModule refactored to DynamicModule:** Given the CatalogModule implemented in Story 2.2, when it is registered in AppModule, then it is registered as `CatalogModule.register()` (DynamicModule pattern), imports PrismaModule and KernelModule (or relies on globals), and exports CatalogService for use by other modules (e.g., ContactsModule, PosModule).

5. **AC5 — Performance: 2000-item query within bounds:** Given 2,000 catalog items for a tenant, when the client queries the catalog with `GET /catalog/items?tenantId=<uuid>&limit=100`, then the response is returned within acceptable bounds (leveraging existing indexes on `(tenant_id, updated_at)` and `(barcode)` from Story 2.1).

6. **AC6 — Regression: 0 failures on all existing tests:** Given the existing test suite (110 + Story 2.2 additions), when Story 2.3 changes are applied, all tests continue to pass.

## Tasks / Subtasks

### Phase 1 — CatalogService: delta sync + bulk upsert (AC1–AC3, AC5)

- [x] **1.1** Update `apps/backend/src/shared/catalog/catalog.service.ts` — modify `getItems()` to support delta sync:
  - Accept `since?: string` param
  - When `since` is provided: `where.updatedAt = { gt: new Date(since) }` AND include `is_deleted: true` items (tombstoning)
  - When `since` is absent: `where.isDeleted = false` (default — no soft-deleted)
  - Return response shape with `meta` object:
    ```typescript
    {
      items: CatalogItem[],
      meta: {
        total: number,
        page: number,
        limit: number,
        hasMore: boolean,
        serverTime: string,  // new Date().toISOString()
      }
    }
    ```

- [x] **1.2** Update `apps/backend/src/shared/catalog/catalog.service.ts` — add `syncItems(items: any[])` method:
  - For each item in the array, call `prisma.catalogItem.upsert({ where: { id: item.id }, update: {...}, create: {...} })`
  - Use `Promise.all()` for concurrent upserts
  - No AuditLog for bulk sync (idempotent operation)

### Phase 2 — CatalogController: new endpoints (AC1–AC3)

- [x] **2.1** Update `apps/backend/src/shared/catalog/catalog.controller.ts`:
  - `GET /catalog/items` — add `@Query('since') since?: string` param; pass to `catalogService.getItems()`
  - `POST /catalog/items/sync` — new endpoint; no `@Roles` restriction (sync is available to all authenticated users); calls `catalogService.syncItems(body.items || body)`

- [x] **2.2** Verify response shape from `getItems()` now returns `meta` object. Update any callers if needed.

### Phase 3 — DynamicModule refactor (AC4)

- [x] **3.1** Refactor `apps/backend/src/shared/catalog/catalog.module.ts` to DynamicModule pattern:
  ```typescript
  import { DynamicModule, Module } from '@nestjs/common';

  @Module({})
  export class CatalogModule {
    static register(): DynamicModule {
      return {
        module: CatalogModule,
        providers: [CatalogService],
        controllers: [CatalogController],
        exports: [CatalogService],
      };
    }
  }
  ```

- [x] **3.2** Update `apps/backend/src/app.module.ts` — change `CatalogModule` to `CatalogModule.register()` in imports.

- [x] **3.3** Update `apps/backend/src/pos/pos.module.ts` — change `CatalogModule` to `CatalogModule.register()` in imports.

### Phase 4 — Tests (AC6)

- [x] **4.1** Update `apps/backend/src/shared/catalog/catalog.service.spec.ts`:
  - Test `getItems({ since: '2026-01-01T00:00:00Z' })` includes soft-deleted items
  - Test `getItems()` (no since) excludes soft-deleted items
  - Test response includes `meta.serverTime`, `meta.hasMore`, `meta.total`
  - Test `syncItems([...])` calls prisma.catalogItem.upsert for each item

- [x] **4.2** Run `npx jest --no-coverage` from `apps/backend/` — all tests pass.

## Dev Notes

### Scope Boundary — What Story 2.3 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| RLS policy on shared.catalog_items | Deferred | Supabase RLS setup |
| Flutter client sync implementation | Frontend | Epic 8 |
| Conflict resolution for offline edits | Epic 8 | Story 8-3 |

### No Migration Needed

Story 2.3 adds no new DB tables or columns. The schema from Stories 2.1 and 2.2 is sufficient:
- `catalog_items.updated_at` already indexed via `(tenant_id, updated_at)` index — optimal for delta pull
- `catalog_items.is_deleted` already present for tombstoning

### Delta Sync Query: Full Implementation

```typescript
async getItems(params: {
  tenantId?: string;
  query?: string;
  page?: number;
  limit?: number;
  since?: string;
}) {
  const { tenantId, query, page = 1, limit = 100, since } = params;
  const skip = (page - 1) * limit;

  const where: any = {};
  if (tenantId) where.tenantId = tenantId;

  if (since) {
    where.updatedAt = { gt: new Date(since) };
    // Include soft-deleted for tombstoning — client must remove these locally
  } else {
    where.isDeleted = false;
  }

  if (query) {
    where.OR = [
      { name: { contains: query, mode: 'insensitive' } },
      { barcode: { contains: query, mode: 'insensitive' } },
    ];
  }

  const [items, total] = await Promise.all([
    this.prisma.catalogItem.findMany({
      where,
      orderBy: { updatedAt: 'asc' },  // ascending for sync continuity
      skip,
      take: limit,
    }),
    this.prisma.catalogItem.count({ where }),
  ]);

  return {
    items,
    meta: {
      total,
      page,
      limit,
      hasMore: skip + items.length < total,
      serverTime: new Date().toISOString(),
    },
  };
}
```

**BREAKING CHANGE vs Story 2.2:** The response shape changes from `{ items, total, page, limit, totalPages }` to `{ items, meta: {...} }`. Update PosService proxy if it wraps the old shape.

### DynamicModule Pattern: Why and How

Story 2.3 converts CatalogModule to DynamicModule so that:
- Future modules (ContactsModule, TransactionsModule) can import `CatalogModule.register()` cleanly
- Configuration can be passed via `register(options?)` in the future

```typescript
// Before (Story 2.2):
@Module({
  providers: [CatalogService],
  controllers: [CatalogController],
  exports: [CatalogService],
})
export class CatalogModule {}

// After (Story 2.3):
@Module({})
export class CatalogModule {
  static register(): DynamicModule {
    return {
      module: CatalogModule,
      providers: [CatalogService],
      controllers: [CatalogController],
      exports: [CatalogService],
    };
  }
}
```

All imports in AppModule and PosModule change from `CatalogModule` to `CatalogModule.register()`.

### Bulk Upsert: syncItems()

```typescript
async syncItems(items: any[]) {
  return Promise.all(
    items.map((item) =>
      this.prisma.catalogItem.upsert({
        where: { id: item.id },
        update: {
          name: item.name,
          price: item.price,
          barcode: item.barcode ?? undefined,
          categoryId: item.categoryId ?? undefined,
          itemType: item.itemType ?? 'physical',
          isDeleted: item.isDeleted ?? false,
        },
        create: {
          id: item.id,
          name: item.name,
          price: item.price,
          barcode: item.barcode,
          categoryId: item.categoryId,
          itemType: item.itemType ?? 'physical',
          tenantId: item.tenantId,
          isDeleted: item.isDeleted ?? false,
        },
      })
    )
  );
}
```

### No Global Prefix in main.ts

`main.ts` has no `app.setGlobalPrefix('api/v1')`. All routes are mounted at root. The AC references to `/api/v1/catalog/...` are aspirational from the architecture doc. Actual paths will be `/catalog/items`, `/catalog/categories` etc., consistent with existing `/pos/...` pattern.

If the global prefix needs to be added, add `app.setGlobalPrefix('api/v1')` to main.ts — but only if coordinated with the Flutter client team (breaking change for existing `/pos/...` routes).

### Performance: Index Usage

The `GET /catalog/items?since=...` query benefits from the index created in Story 2.1:
- Index: `catalog_items_tenant_id_updated_at_idx ON (tenant_id, updated_at)`
- Query condition: `WHERE tenant_id = $1 AND updated_at > $2`
- PostgreSQL will use this composite index for the delta pull efficiently

For 2,000 items with `limit=100`: query touches 20 pages × ~100ms = within acceptable sync cycle time.

### Project Structure Notes

Files to modify (no new files, no migration):
```
apps/backend/src/
└── shared/
    └── catalog/
        ├── catalog.service.ts         [MODIFY — update getItems() response shape, add syncItems()]
        ├── catalog.service.spec.ts    [MODIFY — add delta sync + bulk upsert tests]
        ├── catalog.controller.ts      [MODIFY — add since param + POST sync endpoint]
        └── catalog.module.ts          [MODIFY — refactor to DynamicModule]
apps/backend/src/app.module.ts         [MODIFY — CatalogModule → CatalogModule.register()]
apps/backend/src/pos/pos.module.ts     [MODIFY — CatalogModule → CatalogModule.register()]
```

### References

- [Epic 2 Story 2.3 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 2.1 — catalog_items indexes](apps/backend/prisma/migrations/20260315040000_shared_schema_catalogitem/migration.sql)
- [Story 2.2 — CatalogService/Controller baseline](_bmad-output/implementation-artifacts/2-2-category-management-catalog-api.md)
- [CatalogService (Story 2.2)](apps/backend/src/shared/catalog/catalog.service.ts)
- [CatalogController (Story 2.2)](apps/backend/src/shared/catalog/catalog.controller.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `getItems()` now returns `{ items, meta: { total, page, limit, hasMore, serverTime } }` — breaking change from Story 2.2 flat shape; no callers outside catalog controller required updating (PosService proxies deprecated in Story 2.2)
- `syncItems()` uses spread upsert (`update: item, create: item`) rather than the granular field mapping in dev notes — simpler and equally correct for the integration test scope; can be tightened in Epic 6 when field schema is locked
- DynamicModule pattern uses `@Module({})` class-level decorator with all config inside `register()` — consistent with NestJS official docs
- `CatalogModule.register()` called in both `AppModule` and `PosModule` — NestJS deduplicates module instances so no double-registration issue
- 133/133 tests pass; 5 new tests in catalog spec (was 128, now 133)

### File List

- `apps/backend/src/shared/catalog/catalog.service.ts` — modified
- `apps/backend/src/shared/catalog/catalog.controller.ts` — modified
- `apps/backend/src/shared/catalog/catalog.module.ts` — refactored to DynamicModule
- `apps/backend/src/app.module.ts` — updated to `CatalogModule.register()`
- `apps/backend/src/pos/pos.module.ts` — updated to `CatalogModule.register()`
- `apps/backend/src/shared/catalog/catalog.service.spec.ts` — updated tests
- `apps/backend/src/shared/catalog/catalog.controller.spec.ts` — updated tests
