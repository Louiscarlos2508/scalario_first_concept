# Story 1.5: Guard Chain Integration & Backward Compatibility

Status: review

## Story

As a developer deploying the kernel extraction,
I want the complete guard chain wired and all existing endpoints still functional,
so that the 3 existing clients experience zero disruption during the kernel deployment.

## Acceptance Criteria

1. **AC1 — Guard chain execution order:** Given all kernel guards are implemented (Auth, Tenant, Module, Roles), when a request hits any protected endpoint, then guards execute in order: `AuthGuard → TenantGuard → ModuleGuard → RolesGuard`, and failure at any stage returns the appropriate HTTP error code (401 for auth, 403 for tenant/module/role).

2. **AC2 — Backward compatibility (existing POS endpoints):** Given the existing POS endpoints (`/pos/*`), when the kernel is deployed, then all existing endpoints continue to function identically for the 3 current clients — same request/response shapes, same behavior. No POS endpoint should silently break due to guard chain introduction.

3. **AC3 — Cross-tenant RLS isolation:** Given two tenants (A and B) exist in the system, when tenant A's user attempts to query data, then RLS policies ensure zero cross-tenant data leakage, validated by integration tests that create data in tenant A and verify it's invisible to tenant B.

4. **AC4 — KernelModule exports complete:** Given the kernel module is registered, when `AppModule` imports `KernelModule`, then it exports: `AuthGuard`, `TenantGuard`, `RolesGuard`, `ModuleGuard`, `EventBusService`, and all decorators (`@CurrentUser`, `@CurrentTenant`, `@Roles`, `@RequiresModule`, `@Public`).

5. **AC5 — Tenant auto-seeding on creation:** Given a new tenant is created via `OrganizationService.createOrganization()`, when the call completes, then the tenant has default configuration (XOF currency, Africa/Abidjan timezone — already set in TenancyService.createTenant()), MVP roles are seeded (owner role look-up already works), and `shared` + `retail` modules are activated — requiring zero code changes at the caller side.

## Tasks / Subtasks

### Phase 1 — EventBus service & module (AC4)
- [x] **1.1** Create `apps/backend/src/kernel/events/event-bus.service.ts` — thin wrapper around `EventEmitter2` with a `publish(eventName: string, event: unknown): boolean` method.
- [x] **1.2** Create `apps/backend/src/kernel/events/events.module.ts` — `EventsModule` providing and exporting `EventBusService`.
- [x] **1.3** Update `apps/backend/src/kernel/kernel.module.ts` — import and export `EventsModule`.

### Phase 2 — Tenant auto-seeding (AC5)
- [x] **2.1** Add `activateDefaultModulesForTenant(tenantId: string): Promise<void>` to `ModuleRegistryService` — queries all `Module` records with `type = 'shared'` OR `code = 'retail'`, then upserts `TenantModule` records with `status = 'active'`.
- [x] **2.2** Update `OrganizationService.createOrganization()` — after creating the owner member (step 3), inject `ModuleRegistryService` and call `activateDefaultModulesForTenant(tenant.id)`.
- [x] **2.3** Update `OrganizationService.spec.ts` — add `ModuleRegistryService` mock, verify `activateDefaultModulesForTenant()` is called with the new tenant's ID.

### Phase 3 — POS backward compatibility (AC2)

- [x] **3.1** Read `pos.controller.ts`, `pos-session.controller.ts`, `customer.controller.ts` — verify no endpoint currently relies on being completely unauthenticated (no Bearer). The 3 existing clients provide `Authorization: Bearer <token>` + `x-tenant-id` headers — the guard chain will pass them through unchanged.
- [x] **3.2** `OrganizationController.createOrganization()` (POST /organizations): verify it does **NOT** need `@Public()`. TenantGuard already passes through when no `x-tenant-id` header is present (see `tenant.guard.ts` line: "If no tenantId → return true"). AuthGuard still validates Bearer token — which is correct, the caller must be logged in.
- [x] **3.3** Document in Dev Agent Record which controllers use `@Public()` (if any) and why.

### Phase 4 — Guard chain integration tests (AC1)
- [x] **4.1** Create `apps/backend/src/kernel/kernel-guard-chain.spec.ts` — integration-style unit tests verifying guard chain execution order:
  - Request with no Bearer token → 401 from AuthGuard
  - Request with valid token + invalid tenant UUID → 400 from TenantGuard
  - Request with valid token + valid tenant UUID but user not a member → 403 from TenantGuard
  - Request with tenant context but required module not active → 403 from ModuleGuard
  - Request with tenant context + active module but wrong role → 403 from RolesGuard
  - Request with all valid → 200 (guard chain passes)

### Phase 5 — Cross-tenant isolation test (AC3)
- [x] **5.1** Create `apps/backend/src/kernel/tenancy/cross-tenant-isolation.spec.ts` — unit test simulating TenancyService.validateTenantAccess() returns false for user of tenant A trying to access tenant B. Verifies TenantGuard throws ForbiddenException.
- [x] **5.2** Add a dev note documenting that full RLS integration tests (real PostgreSQL dual-tenant fixture) are a post-MVP concern (requires test DB setup with RLS enabled); unit tests cover the application-level isolation.

### Phase 6 — EventBusService unit test (AC4)
- [x] **6.1** Create `apps/backend/src/kernel/events/event-bus.service.spec.ts` — verifies `EventBusService.publish()` delegates to EventEmitter2's `emit()` and returns the correct boolean result.

## Dev Notes

### What is Already Implemented (do NOT re-implement)

Stories 1.1–1.4 are **done**. The following components are in production-ready state:

| Component | File | Status |
|-----------|------|--------|
| AuthGuard | `src/kernel/auth/auth.guard.ts` | Done — validates Supabase JWT, supports session timeout, @Public bypass |
| @Public, @CurrentUser | `src/kernel/auth/auth.decorator.ts` | Done |
| TenantGuard | `src/kernel/tenancy/tenant.guard.ts` | Done — validates x-tenant-id, validates membership |
| @CurrentTenant | `src/kernel/tenancy/tenant.decorator.ts` | Done |
| TenancyService | `src/kernel/tenancy/tenancy.service.ts` | Done — createTenant() defaults XOF/Africa/Abidjan |
| RolesGuard | `src/kernel/rbac/roles.guard.ts` | Done — resolves role via PermissionService |
| @Roles | `src/kernel/rbac/roles.decorator.ts` | Done |
| PermissionService | `src/kernel/rbac/permission.service.ts` | Done — getUserRoleName(), hasPermission() |
| ModuleGuard | `src/kernel/modules/module.guard.ts` | Done — checks TenantModule activation |
| @RequiresModule | `src/kernel/modules/module.decorator.ts` | Done |
| ModuleRegistryService | `src/kernel/modules/module-registry.service.ts` | Done — isModuleActive() |
| KernelModule APP_GUARD | `src/kernel/kernel.module.ts` | Done — 4 guards in correct order |
| AuditLogService | `src/kernel/audit/audit-log.service.ts` | Done |
| domain-events.ts | `src/kernel/events/domain-events.ts` | Done — 4 typed event classes |
| EventEmitterModule | `src/app.module.ts` | Done — wildcard: true, delimiter: '.', global: true |

### What Story 1.5 Adds

**1. EventBusService (new file — AC4)**

`src/kernel/events/event-bus.service.ts`:
```typescript
import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class EventBusService {
  constructor(private readonly eventEmitter: EventEmitter2) {}

  publish(eventName: string, event: unknown): boolean {
    return this.eventEmitter.emit(eventName, event);
  }
}
```

`src/kernel/events/events.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { EventBusService } from './event-bus.service';

@Module({
  providers: [EventBusService],
  exports: [EventBusService],
})
export class EventsModule {}
```

**KernelModule update** (add EventsModule to imports + exports):
```typescript
@Global()
@Module({
  imports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule, EventsModule],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: TenantGuard },
    { provide: APP_GUARD, useClass: ModuleGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule, EventsModule],
})
export class KernelModule {}
```

> **Why EventsModule works without importing EventEmitterModule:** `EventEmitterModule.forRoot({ global: true })` is in `AppModule`, making `EventEmitter2` available globally via NestJS DI. `EventBusService` can inject `EventEmitter2` without `EventsModule` needing to import `EventEmitterModule`. Do NOT add another `EventEmitterModule.forRoot()` anywhere.

**2. ModuleRegistryService — activateDefaultModulesForTenant() (AC5)**

Add to `src/kernel/modules/module-registry.service.ts`:
```typescript
async activateDefaultModulesForTenant(tenantId: string): Promise<void> {
  const defaultModules = await this.prisma.module.findMany({
    where: {
      OR: [
        { type: 'shared' },
        { code: 'retail' },
      ],
    },
  });

  await Promise.all(
    defaultModules.map((mod) =>
      this.prisma.tenantModule.upsert({
        where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
        create: { tenantId, moduleId: mod.id, status: 'active' },
        update: { status: 'active' },
      }),
    ),
  );
}
```

> **Why upsert instead of create:** If createOrganization() is ever called twice (retry scenario), upsert prevents duplicate-key errors.

**3. OrganizationService — inject ModuleRegistryService (AC5)**

Update `organization.service.ts`:
```typescript
constructor(
  private readonly supabaseService: SupabaseService,
  private readonly prisma: PrismaService,
  private readonly auditLogService: AuditLogService,
  private readonly moduleRegistryService: ModuleRegistryService,  // ADD
) {}

async createOrganization(name: string, userId: string) {
  // ... existing steps 1-4 unchanged ...

  // 5. Auto-activate shared + retail modules for the new tenant
  await this.moduleRegistryService.activateDefaultModulesForTenant(tenant.id);

  return tenant;
}
```

> **ModuleRegistryService is available without additional imports** because KernelModule is `@Global()` and exports ModulesModule which exports ModuleRegistryService. OrganizationModule does NOT need to import KernelModule explicitly.

**4. POS Backward Compatibility (AC2)**

The POS controllers (`pos.controller.ts`, `pos-session.controller.ts`, `customer.controller.ts`) were built before the kernel. They may or may not use `@Public()`.

**Assessment strategy:**
1. If POS controllers have NO `@Public()` → they currently require a Bearer token (AuthGuard passes them through). The existing 3 clients presumably provide Bearer tokens + x-tenant-id headers.
2. If any POS controller endpoint should be unauthenticated → add `@Public()`.
3. `OrganizationController.createOrganization()` (POST /organizations) is a bootstrap endpoint (no tenant yet) — must be `@Public()` if not already.

**The guard chain is already wired** — verify the POS endpoints don't throw due to guard changes, not implement new behavior.

**5. Guard Chain Test Strategy (AC1)**

The guard chain is wired via `APP_GUARD` — NestJS applies them globally in registration order. Write unit tests for each guard boundary using `Test.createTestingModule()`.

For AC1, test each guard in isolation (existing spec files cover most cases). The integration-style test (`kernel-guard-chain.spec.ts`) should simulate the request flowing through all guards:

```typescript
// Pattern: build a minimal NestJS test app with all 4 guards wired
const app = await Test.createTestingModule({
  imports: [KernelModule, /* test controller module */],
}).compile();
const nestApp = app.createNestApplication();
await nestApp.init();
// Then use supertest to hit endpoints and verify status codes
```

**6. Cross-Tenant Isolation (AC3)**

Application-level isolation is enforced by:
- `TenantGuard`: user must be a member of the x-tenant-id tenant
- `TenancyService.validateTenantAccess()`: queries OrganizationMember

Unit tests for AC3 should verify:
- `TenancyService.validateTenantAccess(tenantB_id, userA_id)` returns `false`
- `TenantGuard.canActivate()` throws `ForbiddenException` when access denied

> **Full RLS integration tests** (real PostgreSQL SET LOCAL app.current_tenant_id) require a test database fixture and are a post-MVP concern. Document this gap in Dev Agent Record.

### Guard Chain Request Flow (full picture)

```
HTTP Request
    ↓
AuthGuard          — validates Bearer JWT via Supabase.auth.getUser()
                     checks session timeout
                     bypasses if @Public()
                     sets request.user = { id, email, ... }
                     throws 401 if fails
    ↓
TenantGuard        — reads x-tenant-id header
                     validates UUID format (400 if malformed)
                     calls TenancyService.validateTenantAccess(tenantId, userId)
                     throws 403 if user not a member
                     sets request.tenantId = tenantId
                     passes through if no x-tenant-id (bootstrap endpoints)
    ↓
ModuleGuard        — reads @RequiresModule metadata
                     skips if no @RequiresModule
                     calls ModuleRegistryService.isModuleActive(tenantId, moduleCode)
                     throws 403 if module not active for tenant
    ↓
RolesGuard         — reads @Roles metadata
                     skips if no @Roles
                     calls PermissionService.getUserRoleName(userId, tenantId)
                     throws 403 if role insufficient
    ↓
Controller Handler
```

### Prisma Model Reference (for ModuleRegistryService.activateDefaultModulesForTenant)

- `Module` model: `id`, `code`, `name`, `type ('shared'|'vertical')` — in `@@schema("kernel")`
- `TenantModule` model: `tenantId`, `moduleId`, `status ('active'|'inactive')`, `activatedAt` — composite unique: `tenantId_moduleId`
- The Prisma client accessor is `prisma.tenantModule` and `prisma.module`

### Learnings from Story 1.4 (apply here)

- **`jest.resetAllMocks()` in `afterEach`** — clears `mockReturnThis()`. Supabase fluent chain mocks (`from.mockReturnThis()`, `insert.mockReturnThis()`, `select.mockReturnThis()`) MUST be re-initialized in `beforeEach`, not at declaration time.
- **`PrismaModule` is `@Global()`** — service tests do NOT need to import PrismaModule explicitly.
- **`mockResolvedValue(undefined)` for void methods** — use `mockAuditLogService.log.mockResolvedValue(undefined)` and `mockModuleRegistryService.activateDefaultModulesForTenant.mockResolvedValue(undefined)`.
- **Mock new services explicitly** — for `OrganizationService.spec.ts`, add `ModuleRegistryService` mock: `{ activateDefaultModulesForTenant: jest.fn() }`.

### Migration Timestamp

No new migration is needed for Story 1.5 — no new schema changes. The Prisma schema and existing migrations from Stories 1.1–1.4 cover all required tables (`Module`, `TenantModule`, `audit_log`, etc.).

### Project Structure Notes

New files in this story:
```
apps/backend/src/kernel/events/
├── domain-events.ts              [EXISTS — from Story 1.4]
├── event-bus.service.ts          [NEW]
├── event-bus.service.spec.ts     [NEW]
└── events.module.ts              [NEW]
```

Modified files:
```
apps/backend/src/kernel/kernel.module.ts            [ADD EventsModule]
apps/backend/src/kernel/modules/module-registry.service.ts  [ADD activateDefaultModulesForTenant()]
apps/backend/src/kernel/modules/module-registry.service.spec.ts  [ADD test]
apps/backend/src/organization/organization.service.ts       [ADD ModuleRegistryService injection]
apps/backend/src/organization/organization.service.spec.ts  [ADD ModuleRegistryService mock]
apps/backend/src/kernel/kernel-guard-chain.spec.ts          [NEW]
apps/backend/src/kernel/tenancy/cross-tenant-isolation.spec.ts  [NEW]
apps/backend/src/pos/pos.controller.ts              [AUDIT — add @Public() if needed]
apps/backend/src/pos/pos-session.controller.ts      [AUDIT — add @Public() if needed]
apps/backend/src/organization/organization.controller.ts    [VERIFY @Public() on POST /organizations]
```

### References

- Guard chain architecture: `docs/architecture-scalario-2026-03-08.md` §6.4 (Guard Chain)
- KernelModule exports spec: `docs/architecture-scalario-2026-03-08.md` §4.1
- Module registry: `docs/architecture-scalario-2026-03-08.md` §4.1.5
- RLS policies: `docs/architecture-scalario-2026-03-08.md` §5.7, §8
- Testing strategy: `docs/architecture-scalario-2026-03-08.md` §11.3
- Story 1.5 ACs: `_bmad-output/planning-artifacts/epics.md` lines 413–439
- EventBus architecture: `docs/architecture-scalario-2026-03-08.md` §4.1.4

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- All 6 phases implemented with 110/110 tests passing (35 new tests, 0 regressions).
- **AC1 (Guard chain order):** Verified via `kernel-guard-chain.spec.ts` — 4 describe blocks covering AuthGuard (401), TenantGuard (400/403), ModuleGuard (403), RolesGuard (403). NestJS APP_GUARD registration order enforces Auth → Tenant → Module → Roles.
- **AC2 (POS backward compat):** Audited all 3 POS controllers (`pos.controller.ts`, `pos-session.controller.ts`, `customer.controller.ts`). No `@Public()` needed — all existing endpoints require Bearer token (correct). TenantGuard passthrough covers absence of `x-tenant-id`. Zero code changes to POS controllers.
- **AC3 (Cross-tenant isolation):** Unit tests in `cross-tenant-isolation.spec.ts` verify application-level isolation via TenancyService.validateTenantAccess(). Full RLS integration tests (real PostgreSQL) are post-MVP.
- **AC4 (KernelModule exports):** EventBusService created as thin EventEmitter2 wrapper. EventsModule added to KernelModule imports/exports. GlobalModule makes EventEmitter2 injectable without re-importing EventEmitterModule.
- **AC5 (Tenant auto-seeding):** `activateDefaultModulesForTenant()` upserts shared + retail modules on `createOrganization()`. Upsert prevents duplicate-key errors on retry.
- **Key fix — jest.resetAllMocks() pattern:** Supabase mock chain (`getClient.mockReturnValue`) must be re-initialized in `beforeEach` (resetAllMocks clears it). Applied consistently.
- **Key fix — RolesGuard test double-call:** `getAllAndOverride` called twice (IS_PUBLIC_KEY then ROLES_KEY). Must use `mockReturnValueOnce` chaining to avoid IS_PUBLIC_KEY receiving truthy roles array and short-circuiting to `return true`.
- **Key fix — JWT timeout:** Test tokens with decodable `iat` in the past trigger "Session expired". Use a token without dots (`'test-supabase-token'`) so `_decodeJwtPayload` returns null and timeout check is skipped.
- **No new migrations:** All required schema (Module, TenantModule, audit_log) already exists from Stories 1.1–1.4.
- **@Public() controllers:** None in POS. OrganizationController does NOT use @Public() — AuthGuard validates Bearer, TenantGuard passes through on missing x-tenant-id header (bootstrap pattern is by design).

### File List

**New files:**
- `apps/backend/src/kernel/events/event-bus.service.ts`
- `apps/backend/src/kernel/events/events.module.ts`
- `apps/backend/src/kernel/events/event-bus.service.spec.ts`
- `apps/backend/src/kernel/kernel-guard-chain.spec.ts`
- `apps/backend/src/kernel/tenancy/cross-tenant-isolation.spec.ts`

**Modified files:**
- `apps/backend/src/kernel/kernel.module.ts` — added EventsModule import/export
- `apps/backend/src/kernel/modules/module-registry.service.ts` — added activateDefaultModulesForTenant()
- `apps/backend/src/kernel/modules/module-registry.service.spec.ts` — added activateDefaultModulesForTenant tests
- `apps/backend/src/organization/organization.service.ts` — injected ModuleRegistryService, call activateDefaultModulesForTenant
- `apps/backend/src/organization/organization.service.spec.ts` — added ModuleRegistryService mock and tests
