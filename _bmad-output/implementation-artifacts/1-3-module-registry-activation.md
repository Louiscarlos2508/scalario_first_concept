# Story 1.3 — Module Registry & Activation

## Metadata
- **Epic:** Epic 1 — Kernel: Identity, Tenancy & Access Control
- **Story ID:** 1-3-module-registry-activation
- **Status:** review
- **Priority:** High
- **Depends on:** Story 1.2 (RBAC — `OrganizationMember.roleId` FK, guard chain foundation)

---

## Story

**As a** backend system,
**I want** a Module Registry that tracks which functional modules (catalog, POS, inventory, etc.) are available and which are activated per tenant,
**So that** routes belonging to inactive modules are blocked at the guard layer before controller logic runs, enabling feature gating and future paid-tier differentiation.

---

## Business Context

Scalario's modular ERP architecture separates concerns into Shared and Vertical modules. A `commercial` user must not reach POS endpoints if the POS module is not activated for their tenant. The guard chain established in Story 1.2 (`Auth → Tenant → [Module] → Roles`) has a deliberate gap: `ModuleGuard` goes **between** `TenantGuard` and `RolesGuard`. Story 1.3 fills that gap.

Phase 3 modules (`connect`, `enterprise`) are pre-registered now with `status = 'available_phase3'` so their activation path requires no future migration on a live multi-tenant system.

---

## Acceptance Criteria

1. **Schema — `modules` table** exists in `kernel` schema with fields: `id UUID PK`, `code VARCHAR UNIQUE`, `name VARCHAR`, `type VARCHAR` (values: `shared`, `vertical`), `dependencies TEXT[]`, timestamps.

2. **Schema — `tenant_modules` table** exists in `kernel` schema with fields: `id UUID PK`, `tenant_id UUID FK → tenants`, `module_id UUID FK → modules`, `status VARCHAR` (values: `active`, `inactive`, `available_phase3`), `activated_at TIMESTAMPTZ?`, `department_id UUID? @Phase3`. Unique constraint on `(tenant_id, module_id)`.

3. **Schema — `org_mode` column** added to `kernel.tenants` with `DEFAULT 'standalone'`. Values: `standalone` (single vertical, Phase 1–2), `multi` (Phase 3+).

4. **Seed — modules** 9 modules seeded:
   - Shared (type=`shared`): `catalog`, `contacts`, `inventory`, `transactions`, `reporting`, `dashboard`
   - Vertical (type=`vertical`): `pos` (retail)
   - Phase 3 (type=`vertical`): `connect`, `enterprise` — seeded with `status = 'available_phase3'` in `tenant_modules` for existing tenants (or left for activation later — no tenant_modules row required at seed time)

5. **`ModuleRegistryService.isModuleActive(tenantId, moduleCode)`** returns `true` only when a `tenant_modules` row exists with `status = 'active'` for the given tenant and module code.

6. **`@RequiresModule('code')` decorator** marks a controller or route as requiring a specific module.

7. **`ModuleGuard`** — when `@RequiresModule()` is set and the module is not active for the request's tenant, throws `ForbiddenException('Module not activated for this tenant')`. When no decorator is set, passes through (opt-in guard). Reads `tenantId` from `request.tenantId` (set by `TenantGuard`).

8. **Guard chain updated** in `KernelModule`: `AuthGuard → TenantGuard → ModuleGuard → RolesGuard` (ModuleGuard inserted between TenantGuard and RolesGuard).

9. **Unit tests** cover: `ModuleGuard` (no decorator → pass, active module → pass, inactive module → ForbiddenException, missing tenantId → ForbiddenException) and `ModuleRegistryService` (active → true, inactive → false, no row → false).

---

## Technical Notes

### Guard chain order matters
`APP_GUARD` providers in `KernelModule` execute in **declaration order**. The current order after Story 1.2:
```
AuthGuard (1st) → TenantGuard (2nd) → RolesGuard (3rd)
```
Story 1.3 inserts `ModuleGuard` at position 3, pushing `RolesGuard` to position 4:
```
AuthGuard → TenantGuard → ModuleGuard → RolesGuard
```
The `KernelModule` `providers` array must be updated accordingly.

### `PrismaModule` is `@Global()`
`PrismaService` is available everywhere without explicit import — `ModulesModule` does NOT need to import `PrismaModule`.

### Migration strategy
- Use `prisma migrate deploy` (not `migrate dev`) — no interactive TTY required.
- Add `org_mode` to `tenants` as a nullable column first, then set `DEFAULT 'standalone'` and backfill, then add `NOT NULL`. This is safe for existing rows.

### `dependencies` field
Stored as `TEXT[]` (PostgreSQL array). Prisma type: `String[]`. Used for future dependency validation (e.g., `pos` depends on `catalog`, `inventory`). Not enforced by a DB constraint — validated in application layer.

### Phase 3 modules in `tenant_modules`
No `tenant_modules` row is required for Phase 3 modules at seed time. Their existence in `modules` table is sufficient. `ModuleRegistryService.isModuleActive()` returns `false` for any module without an `active` row — this naturally blocks Phase 3 features.

### `org_mode` constraint (Story 1.3 scope)
`ModuleGuard` reads `request.tenantId` (already set by `TenantGuard`). It does **not** need to read `org_mode` directly — `org_mode` is a field on `Tenant` used by higher-level business logic (e.g., preventing multi-vertical activation in Phase 1). The guard itself only checks `tenant_modules.status`.

### Learnings from Story 1.2
- Use `jest.resetAllMocks()` in `afterEach` (not `jest.clearAllMocks()`) — `clearAllMocks` does NOT flush the `mockReturnValueOnce` queue, causing stale values to bleed into subsequent tests when the guard returns early.
- Compound unique key `@@unique([tenantId, moduleId])` → Prisma accessor: `tenantId_moduleId` used in `findUnique({ where: { tenantId_moduleId: { tenantId, moduleId } } })`.

---

## Implementation Tasks

### Phase 1 — Schema & Migration

- [x] **1.1** Add `Module` and `TenantModule` models to `apps/backend/prisma/schema.prisma`. Add `orgMode` field to `Tenant`.
- [x] **1.2** Create migration file `apps/backend/prisma/migrations/20260315010000_module_registry/migration.sql` with:
  - `CREATE TABLE kernel.modules (...)`
  - `CREATE TABLE kernel.tenant_modules (...)`
  - `ALTER TABLE kernel.tenants ADD COLUMN org_mode VARCHAR NOT NULL DEFAULT 'standalone'`

### Phase 2 — Seed

- [x] **2.1** Add `seedModules()` function to `apps/backend/prisma/seed.ts`. Seed 9 modules (6 shared, 1 retail, 2 phase3).

### Phase 3 — NestJS Module Registry

- [x] **3.1** Create `apps/backend/src/kernel/modules/module.decorator.ts` — `REQUIRES_MODULE_KEY` constant + `@RequiresModule()` decorator.
- [x] **3.2** Create `apps/backend/src/kernel/modules/module-registry.service.ts` — `ModuleRegistryService` with `isModuleActive(tenantId, moduleCode)`.
- [x] **3.3** Create `apps/backend/src/kernel/modules/module.guard.ts` — `ModuleGuard`.
- [x] **3.4** Create `apps/backend/src/kernel/modules/modules.module.ts` — `ModulesModule` providing and exporting `ModuleRegistryService` and `ModuleGuard`.

### Phase 4 — Kernel Integration

- [x] **4.1** Update `apps/backend/src/kernel/kernel.module.ts` — import `ModulesModule`, insert `ModuleGuard` as `APP_GUARD` between `TenantGuard` and `RolesGuard`.

### Phase 5 — Tests

- [x] **5.1** Create `apps/backend/src/kernel/modules/module-registry.service.spec.ts`.
- [x] **5.2** Create `apps/backend/src/kernel/modules/module.guard.spec.ts`.

---

## Implementation Reference

### 1. Prisma Schema Additions

Add to `apps/backend/prisma/schema.prisma`:

```prisma
// Add to Tenant model:
//   orgMode  String  @default("standalone") @map("org_mode")
//   tenantModules TenantModule[]

model Module {
  id           String        @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  code         String        @unique
  name         String
  type         String        // "shared" | "vertical"
  dependencies String[]
  createdAt    DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  tenants      TenantModule[]

  @@map("modules")
  @@schema("kernel")
}

model TenantModule {
  id          String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  tenantId    String    @map("tenant_id") @db.Uuid
  moduleId    String    @map("module_id") @db.Uuid
  status      String    @default("inactive") // "active" | "inactive" | "available_phase3"
  activatedAt DateTime? @map("activated_at") @db.Timestamptz(6)
  // departmentId String? @map("department_id") @db.Uuid  -- Phase 3
  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  module      Module    @relation(fields: [moduleId], references: [id])

  @@unique([tenantId, moduleId])
  @@map("tenant_modules")
  @@schema("kernel")
}
```

Update `Tenant` model to add:
```prisma
  orgMode       String         @default("standalone") @map("org_mode")
  tenantModules TenantModule[]
```

### 2. Migration SQL

`apps/backend/prisma/migrations/20260315010000_module_registry/migration.sql`:

```sql
-- CreateTable kernel.modules
CREATE TABLE "kernel"."modules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" VARCHAR(100) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "dependencies" TEXT[] NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "modules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "modules_code_key" ON "kernel"."modules"("code");

-- CreateTable kernel.tenant_modules
CREATE TABLE "kernel"."tenant_modules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "module_id" UUID NOT NULL,
    "status" VARCHAR(50) NOT NULL DEFAULT 'inactive',
    "activated_at" TIMESTAMPTZ(6),

    CONSTRAINT "tenant_modules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tenant_modules_tenant_id_module_id_key"
    ON "kernel"."tenant_modules"("tenant_id", "module_id");

-- AddForeignKey
ALTER TABLE "kernel"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kernel"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_module_id_fkey"
    FOREIGN KEY ("module_id") REFERENCES "kernel"."modules"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AlterTable kernel.tenants — add org_mode
ALTER TABLE "kernel"."tenants"
    ADD COLUMN "org_mode" VARCHAR(50) NOT NULL DEFAULT 'standalone';
```

### 3. Seed — `seedModules()`

Add to `apps/backend/prisma/seed.ts`:

```typescript
async function seedModules(prisma: PrismaClient) {
  const modules = [
    // Shared modules
    { code: 'catalog',      name: 'Catalogue',     type: 'shared',   dependencies: [] },
    { code: 'contacts',     name: 'Contacts',      type: 'shared',   dependencies: [] },
    { code: 'inventory',    name: 'Inventaire',    type: 'shared',   dependencies: ['catalog'] },
    { code: 'transactions', name: 'Transactions',  type: 'shared',   dependencies: ['catalog', 'contacts'] },
    { code: 'reporting',    name: 'Rapports',      type: 'shared',   dependencies: [] },
    { code: 'dashboard',    name: 'Tableau de bord', type: 'shared', dependencies: [] },
    // Retail vertical
    { code: 'pos',          name: 'Point de Vente', type: 'vertical', dependencies: ['catalog', 'inventory', 'transactions'] },
    // Phase 3 — pre-registered, not yet activatable
    { code: 'connect',      name: 'Scalario Connect',    type: 'vertical', dependencies: [] },
    { code: 'enterprise',   name: 'Scalario Enterprise', type: 'vertical', dependencies: [] },
  ];

  for (const mod of modules) {
    await prisma.module.upsert({
      where: { code: mod.code },
      update: { name: mod.name, type: mod.type, dependencies: mod.dependencies },
      create: mod,
    });
  }

  console.log(`Seeded ${modules.length} modules`);
}
```

Call `await seedModules(prisma)` from the main `seed()` function.

### 4. `module.decorator.ts`

`apps/backend/src/kernel/modules/module.decorator.ts`:

```typescript
import { SetMetadata } from '@nestjs/common';

export const REQUIRES_MODULE_KEY = 'requires_module';

export const RequiresModule = (moduleCode: string) =>
  SetMetadata(REQUIRES_MODULE_KEY, moduleCode);
```

### 5. `module-registry.service.ts`

`apps/backend/src/kernel/modules/module-registry.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ModuleRegistryService {
  constructor(private readonly prisma: PrismaService) {}

  async isModuleActive(tenantId: string, moduleCode: string): Promise<boolean> {
    const tenantModule = await this.prisma.tenantModule.findFirst({
      where: {
        tenantId,
        status: 'active',
        module: { code: moduleCode },
      },
    });
    return tenantModule !== null;
  }
}
```

### 6. `module.guard.ts`

`apps/backend/src/kernel/modules/module.guard.ts`:

```typescript
import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { REQUIRES_MODULE_KEY } from './module.decorator';
import { ModuleRegistryService } from './module-registry.service';

@Injectable()
export class ModuleGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly moduleRegistryService: ModuleRegistryService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredModule = this.reflector.getAllAndOverride<string | undefined>(
      REQUIRES_MODULE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredModule) return true;

    const request = context.switchToHttp().getRequest();
    const tenantId: string | undefined = request.tenantId;

    if (!tenantId) {
      throw new ForbiddenException('Missing tenant context for module check');
    }

    const isActive = await this.moduleRegistryService.isModuleActive(tenantId, requiredModule);

    if (!isActive) {
      throw new ForbiddenException('Module not activated for this tenant');
    }

    return true;
  }
}
```

### 7. `modules.module.ts`

`apps/backend/src/kernel/modules/modules.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ModuleRegistryService } from './module-registry.service';
import { ModuleGuard } from './module.guard';

@Module({
  providers: [ModuleRegistryService, ModuleGuard],
  exports: [ModuleRegistryService, ModuleGuard],
})
export class ModulesModule {}
```

### 8. Updated `kernel.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { TenancyModule } from './tenancy/tenancy.module';
import { RbacModule } from './rbac/rbac.module';
import { ModulesModule } from './modules/modules.module';
import { AuthGuard } from './auth/auth.guard';
import { TenantGuard } from './tenancy/tenant.guard';
import { ModuleGuard } from './modules/module.guard';
import { RolesGuard } from './rbac/roles.guard';

@Global()
@Module({
  imports: [AuthModule, TenancyModule, RbacModule, ModulesModule],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: TenantGuard },
    { provide: APP_GUARD, useClass: ModuleGuard },   // ← NEW (Story 1.3)
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [AuthModule, TenancyModule, RbacModule, ModulesModule],
})
export class KernelModule {}
```

### 9. Test — `module-registry.service.spec.ts`

`apps/backend/src/kernel/modules/module-registry.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { ModuleRegistryService } from './module-registry.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('ModuleRegistryService', () => {
  let service: ModuleRegistryService;

  const mockPrismaService = {
    tenantModule: {
      findFirst: jest.fn(),
    },
  };

  const validTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModuleRegistryService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<ModuleRegistryService>(ModuleRegistryService);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('isModuleActive', () => {
    it('should return true when module is active for tenant', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue({
        id: 'tm-1',
        tenantId: validTenantId,
        moduleId: 'mod-pos',
        status: 'active',
      });

      const result = await service.isModuleActive(validTenantId, 'pos');

      expect(result).toBe(true);
      expect(mockPrismaService.tenantModule.findFirst).toHaveBeenCalledWith({
        where: {
          tenantId: validTenantId,
          status: 'active',
          module: { code: 'pos' },
        },
      });
    });

    it('should return false when no tenant_module row exists', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      const result = await service.isModuleActive(validTenantId, 'pos');

      expect(result).toBe(false);
    });

    it('should return false when module exists but status is inactive', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null); // findFirst with status='active' returns null

      const result = await service.isModuleActive(validTenantId, 'connect');

      expect(result).toBe(false);
    });

    it('should pass moduleCode to module filter', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      await service.isModuleActive(validTenantId, 'catalog');

      expect(mockPrismaService.tenantModule.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            module: { code: 'catalog' },
          }),
        }),
      );
    });
  });
});
```

### 10. Test — `module.guard.spec.ts`

`apps/backend/src/kernel/modules/module.guard.spec.ts`:

```typescript
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, TestingModule } from '@nestjs/testing';
import { ModuleGuard } from './module.guard';
import { ModuleRegistryService } from './module-registry.service';
import { REQUIRES_MODULE_KEY } from './module.decorator';

describe('ModuleGuard', () => {
  let guard: ModuleGuard;

  const mockModuleRegistryService = {
    isModuleActive: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModuleGuard,
        { provide: Reflector, useValue: mockReflector },
        { provide: ModuleRegistryService, useValue: mockModuleRegistryService },
      ],
    }).compile();

    guard = module.get<ModuleGuard>(ModuleGuard);
  });

  afterEach(() => {
    // resetAllMocks flushes mockReturnValueOnce queue — prevents bleed between tests
    jest.resetAllMocks();
  });

  const buildContext = (tenantId?: string): ExecutionContext =>
    ({
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({ tenantId }),
      }),
    }) as unknown as ExecutionContext;

  describe('when no @RequiresModule() decorator is set', () => {
    it('should return true (opt-in guard)', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce(undefined);

      const context = buildContext('tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockModuleRegistryService.isModuleActive).not.toHaveBeenCalled();
    });
  });

  describe('when @RequiresModule() is set', () => {
    it('should allow access when module is active for tenant', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(true);

      const context = buildContext('tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockModuleRegistryService.isModuleActive).toHaveBeenCalledWith('tenant-1', 'pos');
    });

    it('should throw ForbiddenException when module is not active', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(false);

      const context = buildContext('tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when tenantId is missing', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');

      const context = buildContext(undefined);

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
      expect(mockModuleRegistryService.isModuleActive).not.toHaveBeenCalled();
    });

    it('should use the module code from the decorator', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('catalog');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(true);

      const context = buildContext('tenant-1');
      await guard.canActivate(context);

      expect(mockModuleRegistryService.isModuleActive).toHaveBeenCalledWith('tenant-1', 'catalog');
    });
  });

  describe('reflector key usage', () => {
    it('should check REQUIRES_MODULE_KEY', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce(undefined);

      const context = buildContext('tenant-1');
      await guard.canActivate(context);

      expect(mockReflector.getAllAndOverride).toHaveBeenCalledWith(
        REQUIRES_MODULE_KEY,
        expect.any(Array),
      );
    });
  });
});
```

---

## Files to Create / Modify

| Action | Path |
|--------|------|
| **Modify** | `apps/backend/prisma/schema.prisma` |
| **Create** | `apps/backend/prisma/migrations/20260315010000_module_registry/migration.sql` |
| **Modify** | `apps/backend/prisma/seed.ts` |
| **Create** | `apps/backend/src/kernel/modules/module.decorator.ts` |
| **Create** | `apps/backend/src/kernel/modules/module-registry.service.ts` |
| **Create** | `apps/backend/src/kernel/modules/module.guard.ts` |
| **Create** | `apps/backend/src/kernel/modules/modules.module.ts` |
| **Modify** | `apps/backend/src/kernel/kernel.module.ts` |
| **Create** | `apps/backend/src/kernel/modules/module-registry.service.spec.ts` |
| **Create** | `apps/backend/src/kernel/modules/module.guard.spec.ts` |

---

## Definition of Done

- [x] All schema changes reflected in `schema.prisma` and migration SQL created
- [x] `seedModules()` called from main seed function, 9 modules seeded
- [x] `ModuleGuard`, `ModuleRegistryService`, `RequiresModule` decorator created
- [x] Guard chain in `KernelModule`: Auth → Tenant → **Module** → Roles
- [x] All unit tests pass (`module.guard.spec.ts`, `module-registry.service.spec.ts`)
- [x] No `jest.clearAllMocks()` — `jest.resetAllMocks()` used in all `afterEach`
- [x] `prisma migrate deploy` verified (not `migrate dev`)

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/backend/prisma/schema.prisma` |
| Created | `apps/backend/prisma/migrations/20260315010000_module_registry/migration.sql` |
| Modified | `apps/backend/prisma/seed.ts` |
| Created | `apps/backend/src/kernel/modules/module.decorator.ts` |
| Created | `apps/backend/src/kernel/modules/module-registry.service.ts` |
| Created | `apps/backend/src/kernel/modules/module.guard.ts` |
| Created | `apps/backend/src/kernel/modules/modules.module.ts` |
| Modified | `apps/backend/src/kernel/kernel.module.ts` |
| Created | `apps/backend/src/kernel/modules/module-registry.service.spec.ts` |
| Created | `apps/backend/src/kernel/modules/module.guard.spec.ts` |

---

## Dev Agent Record

### Implementation Notes

- `Module` and `TenantModule` Prisma models added to `kernel` schema; `orgMode String @default("standalone")` added to `Tenant`.
- Migration uses `NOT NULL DEFAULT 'standalone'` on `org_mode` — PostgreSQL backfills existing rows automatically, no separate UPDATE needed.
- `ModuleRegistryService.isModuleActive()` uses `findFirst` with nested `module: { code }` filter (not `findUnique` on compound key) because the filter spans a relation join — this is the correct Prisma pattern for filtering across related model fields.
- `ModulesModule` does NOT import `PrismaModule` — `PrismaModule` is `@Global()` so `PrismaService` is available everywhere.
- Guard chain in `KernelModule`: `AuthGuard → TenantGuard → ModuleGuard → RolesGuard` (declaration order = execution order for `APP_GUARD`).
- All tests use `jest.resetAllMocks()` in `afterEach` to prevent `mockReturnValueOnce` queue bleed.
- 12 new tests added (5 guard + 5 service + 2 additional edge cases); 0 regressions — full suite: 68/68 pass.

### Change Log

- 2026-03-15: Implemented Story 1.3 — Module Registry & Activation. Added Module/TenantModule schema, migration, seed (9 modules), ModuleGuard, ModuleRegistryService, RequiresModule decorator, ModulesModule, updated KernelModule guard chain. 12 new tests, 68 total passing.
