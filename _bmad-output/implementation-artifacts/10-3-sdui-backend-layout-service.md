# Story 10.3 — SDUI Backend Layout Service

## Metadata
- **Epic:** Epic 10 — SDUI Foundation & Engine
- **Story ID:** 10-3-sdui-backend-layout-service
- **Status:** done
- **Priority:** High
- **Depends on:** 10-2-sdui-json-schema-definition (done)

---

## Story

**As a** backend developer,
**I want** a NestJS `SduiModule` that serves layout JSON based on the tenant's `business_type`,
**So that** the Flutter app can fetch its screen configuration dynamically at startup.

---

## Acceptance Criteria

1. **GET /sdui/layout?screen=pos** — Authenticated tenant calls the endpoint; HTTP 200 returns `retail.pos.json` content.

2. **ETag header** — Response includes `ETag` header set to MD5 of layout JSON content for client-side cache validation.

3. **KernelTenantService delegation** — Controller reads `tenant.business_type` from `TenancyService` and delegates to `SduiService.getLayout(businessType, screen)`. Since the current `Tenant` model has no `business_type` field, defaults to `'retail'` (only supported vertical in Phase 1).

4. **In-memory layout map** — `SduiService` implements `OnModuleInit`; at startup loads all `.json` files from `layouts/` into a `Map<string, object>` keyed by `{business_type}.{screen}` (e.g., `retail.pos`).

5. **NotFoundException** — Unknown `businessType.screen` combination throws `NotFoundException` with message `"Layout introuvable pour ce type de commerce"`.

---

## Tasks/Subtasks

- [x] **Task 1: Create `apps/backend/src/sdui/sdui.service.ts`**
  - [x] Implement `OnModuleInit` to load all `*.json` from `layouts/` directory
  - [x] Parse filename into `business_type.screen` key
  - [x] Expose `getLayout(businessType, screen): object` with `NotFoundException` fallback

- [x] **Task 2: Create `apps/backend/src/sdui/sdui.controller.ts`**
  - [x] `GET /sdui/layout?screen=` endpoint
  - [x] Read `tenantId` from guard chain via `@CurrentTenant()`; resolve `businessType` (defaults to `'retail'`)
  - [x] Set `ETag` response header (MD5 of layout JSON)
  - [x] Return layout object

- [x] **Task 3: Create `apps/backend/src/sdui/sdui.module.ts`**
  - [x] Module with `SduiController` + `SduiService`

- [x] **Task 4: Register `SduiModule` in `apps/backend/src/app.module.ts`**

- [x] **Task 5: Write tests**
  - [x] `sdui.service.spec.ts` — map loading, `getLayout` happy path, NotFoundException
  - [x] `sdui.controller.spec.ts` — HTTP 200 + ETag header, NotFoundException passthrough

- [x] **Task 6: Run full test suite — zero regressions**

---

## Dev Notes

### Technical Context

- **No `business_type` on Tenant schema** — The `Tenant` model does not have a `business_type` field in the current schema. For Phase 1 (Epics 1–10), all tenants are `'retail'`. The controller hardcodes `businessType = 'retail'` with a TODO comment for Phase 2+.
- **Layout file loading** — `SduiService.onModuleInit` uses `fs.readdirSync` + `path.join(__dirname, 'layouts')` to enumerate `.json` files. File name format: `{business_type}.{screen}.json`.
- **ETag** — Node.js built-in `crypto.createHash('md5').update(JSON.stringify(layout)).digest('hex')`.
- **Guard chain** — `KernelModule` registers `AuthGuard`, `TenantGuard`, `ModuleGuard`, `RolesGuard` globally. No extra decorators needed unless restricting roles.
- **Module pattern** — Simple `@Module({})` (no `DynamicModule.register()`) since no shared deps needed.
- **Test pattern** — Mock `fs` module for `SduiService` tests; mock `SduiService` for controller tests.

### File Paths

```
apps/backend/src/sdui/sdui.service.ts         ← CREATED
apps/backend/src/sdui/sdui.controller.ts      ← CREATED
apps/backend/src/sdui/sdui.module.ts          ← CREATED
apps/backend/src/sdui/sdui.service.spec.ts    ← CREATED
apps/backend/src/sdui/sdui.controller.spec.ts ← CREATED
apps/backend/src/app.module.ts                ← MODIFIED (SduiModule added)
```

---

## Dev Agent Record

### Debug Log

- `Tenant` model has no `business_type` field — defaulted to `'retail'` in controller with a TODO comment for Phase 2+.
- Used `jest.mock('fs')` to mock filesystem in `SduiService` tests — avoids needing actual JSON fixtures on disk.
- Controller uses `@Res()` express response directly to set `ETag` header before returning JSON body.

### Completion Notes

- `SduiService` — `OnModuleInit` loads `*.json` from `layouts/` into `Map<string, object>` keyed by filename stem (`retail.pos`, `retail.dashboard`)
- `SduiController` — `GET /sdui/layout?screen=` returns layout with `ETag: "md5hash"` header; businessType hardcoded to `'retail'` for Phase 1
- `SduiModule` — simple `@Module({controllers, providers, exports})`
- `SduiModule` registered in `app.module.ts`
- 11 new tests: 6 service + 5 controller; all pass
- 288/288 total tests pass — zero regressions

---

## File List

| Action | Path |
|--------|------|
| Created | `apps/backend/src/sdui/sdui.service.ts` |
| Created | `apps/backend/src/sdui/sdui.controller.ts` |
| Created | `apps/backend/src/sdui/sdui.module.ts` |
| Created | `apps/backend/src/sdui/sdui.service.spec.ts` |
| Created | `apps/backend/src/sdui/sdui.controller.spec.ts` |
| Modified | `apps/backend/src/app.module.ts` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story implemented — SduiModule with SduiService + SduiController; 11 tests; 288/288 pass |
