# Story 1.4: Event Bus & Audit Trail

Status: review

## Story

As a platform operator,
I want every data mutation to be logged in an immutable audit trail and cross-module events to be published,
so that we have complete accountability and modules can react to events from other modules.

## Acceptance Criteria

1. **AC1 — `audit_log` schema:** The `kernel.audit_log` table is created with fields: `id UUID PK`, `tenant_id UUID FK → tenants`, `user_id UUID` (auth user, nullable for system events), `action VARCHAR` (CREATE/UPDATE/DELETE), `entity VARCHAR`, `entity_id UUID`, `before JSONB` (null for CREATE), `after JSONB` (null for DELETE), `created_at TIMESTAMPTZ`. Indexes on `(tenant_id, created_at)` and `(entity_id)`.

2. **AC2 — EventEmitter2 configured:** `@nestjs/event-emitter` is installed and `EventEmitterModule.forRoot({ wildcard: true, delimiter: '.' })` is registered in `AppModule`. Typed domain event classes are defined: `TransactionCreatedEvent`, `StockAdjustedEvent`, `SessionClosedEvent`, `BalanceUpdatedEvent`. The `@OnEvent('transaction.created')` decorator pattern is usable from any module without additional imports.

3. **AC3 — Audit logging on mutations:** `AuditLogService.log()` is implemented and wired into `OrganizationService.createOrganization()` and `OrganizationService.addMember()` to demonstrate the pattern. Each call records: tenant context, authenticated user, action type (CREATE), entity name, entity ID, before state (null for CREATE), after state (the created object).

4. **AC4 — Immutability enforced at DB level:** A PostgreSQL trigger `audit_log_immutability` on `kernel.audit_log` rejects any UPDATE or DELETE with an exception. `AuditLogService` exposes only a `log()` (append) method — no update or delete methods exist.

5. **AC5 — Server-side retention:** The server never purges `audit_log` rows (perpetual retention by design). AC4 (immutability trigger) satisfies this at the DB level. Client-side retention (Epic 8) is a separate concern.

6. **AC6 — Event handler pattern:** A `@OnEvent('domain.event')` handler can be registered in any NestJS provider and receives typed event payloads. Verified via unit test that publishes a typed event and asserts the handler was called.

## Tasks / Subtasks

### Phase 1 — New Dependency
- [x] **1.1** Install `@nestjs/event-emitter` in `apps/backend`:
  ```bash
  npm install @nestjs/event-emitter --workspace=apps/backend
  ```
  **Note:** This is a new dependency requiring installation before any code changes.

### Phase 2 — Schema & Migration
- [x] **2.1** Add `AuditLog` Prisma model to `apps/backend/prisma/schema.prisma`.
- [x] **2.2** Create migration `apps/backend/prisma/migrations/20260315020000_audit_log_event_bus/migration.sql`:
  - `CREATE TABLE kernel.audit_log (...)` with all required fields
  - Two indexes: `(tenant_id, created_at)` and `(entity_id)`
  - FK constraint `audit_log → tenants`
  - Immutability trigger function + trigger

### Phase 3 — Domain Event Classes
- [x] **3.1** Create `apps/backend/src/kernel/events/domain-events.ts` with typed event classes: `TransactionCreatedEvent`, `StockAdjustedEvent`, `SessionClosedEvent`, `BalanceUpdatedEvent`.

### Phase 4 — EventBus Configuration
- [x] **4.1** Add `EventEmitterModule.forRoot({ wildcard: true, delimiter: '.' })` to `apps/backend/src/app.module.ts`.

### Phase 5 — AuditLog Service & Module
- [x] **5.1** Create `apps/backend/src/kernel/audit/audit-log.service.ts` — `AuditLogService` with `log()` method (append-only, no update/delete).
- [x] **5.2** Create `apps/backend/src/kernel/audit/audit-log.module.ts` — `AuditLogModule` providing and exporting `AuditLogService`.
- [x] **5.3** Update `apps/backend/src/kernel/kernel.module.ts` — import and export `AuditLogModule`.

### Phase 6 — Wire AuditLog into OrganizationService
- [x] **6.1** Update `apps/backend/src/organization/organization.service.ts` — inject `AuditLogService`, call `log()` in `createOrganization()` (CREATE tenant) and `addMember()` (CREATE member).

### Phase 7 — Tests
- [x] **7.1** Create `apps/backend/src/kernel/audit/audit-log.service.spec.ts` — unit tests for `AuditLogService.log()`: verify Prisma create called with correct payload, null before for CREATE, null after for DELETE.
- [x] **7.2** Update `apps/backend/src/organization/organization.service.spec.ts` — add `AuditLogService` mock, verify `log()` called with correct entity/action on `createOrganization()` and `addMember()`.

## Dev Notes

### New Dependency: `@nestjs/event-emitter`
`@nestjs/event-emitter` is NOT currently in `package.json`. It must be installed before implementation:

```bash
npm install @nestjs/event-emitter --workspace=apps/backend
```

This wraps `eventemitter2` and provides NestJS DI integration. For NestJS 11, use `@nestjs/event-emitter@^3.x`.

**Usage pattern:**
```typescript
// Publishing
constructor(private readonly eventEmitter: EventEmitter2) {}
this.eventEmitter.emit('transaction.created', new TransactionCreatedEvent(...));

// Subscribing (in any @Injectable())
@OnEvent('transaction.created')
handleTransactionCreated(event: TransactionCreatedEvent) { ... }
```

### `audit_log` — kernel schema, append-only
- Model in `@@schema("kernel")` — consistent with all kernel models.
- `before` and `after` fields are `Json` type in Prisma (→ JSONB in PostgreSQL).
- Immutability enforced at DB level via trigger (not application-only) so even direct SQL cannot mutate records.
- `user_id` is `String?` (nullable) to accommodate system-generated events with no authenticated user.
- `entity_id` stored as `String @db.Uuid` — the referenced entity's primary key.

### AuditLogService API
```typescript
interface AuditLogParams {
  tenantId: string;
  userId: string | null;
  action: 'CREATE' | 'UPDATE' | 'DELETE';
  entity: string;       // e.g., 'Tenant', 'OrganizationMember', 'Order'
  entityId: string;
  before?: Record<string, unknown> | null;
  after?: Record<string, unknown> | null;
}

// Usage example in OrganizationService.createOrganization():
await this.auditLogService.log({
  tenantId: tenant.id,
  userId,
  action: 'CREATE',
  entity: 'Tenant',
  entityId: tenant.id,
  before: null,
  after: { id: tenant.id, name: tenant.name },
});
```

### EventEmitter2 — wildcard mode
Configure with `wildcard: true, delimiter: '.'` so handlers can use patterns like `@OnEvent('transaction.*')` to listen to all transaction events. This is required by the architecture (FR62 inter-department events in Phase 3).

### `AppModule` vs `KernelModule` for EventEmitter
`EventEmitterModule.forRoot()` must be in `AppModule` (not `KernelModule`) because it is a global singleton module. Adding it to `KernelModule` would risk double-registration if `KernelModule` is imported multiple times. `KernelModule` can import `AuditLogModule` without needing direct EventEmitter awareness.

### PrismaModule is `@Global()`
`AuditLogModule` does NOT need to import `PrismaModule` — `PrismaService` is injected automatically since `PrismaModule` is `@Global()`.

### AC5 — Retention is by design (no implementation needed)
"Server keeps indefinitely" is satisfied by: (1) the immutability trigger prevents DELETE, (2) no scheduled purge job. The Flutter client-side retention policy (configurable days) is an Epic 8 story and does not affect the server. **No additional work needed for AC5.**

### Migration Timestamp
Next available: `20260315020000` (following `20260315010000` from Story 1.3).

### Learnings from Story 1.3
- `jest.resetAllMocks()` in `afterEach` — NOT `jest.clearAllMocks()` (prevents `mockReturnValueOnce` queue bleed).
- `PrismaModule` is `@Global()` — `AuditLogModule` needs no PrismaModule import.
- `prisma migrate deploy` (not `migrate dev`) — no interactive TTY.
- New NestJS modules go in `apps/backend/src/kernel/<name>/`.

### Project Structure Notes
- New files under `src/kernel/audit/` and `src/kernel/events/` — consistent with established pattern (`src/kernel/rbac/`, `src/kernel/modules/`).
- `AuditLogModule` imported by `KernelModule` and exported globally.
- `EventEmitterModule.forRoot()` goes in `src/app.module.ts` — not `kernel.module.ts`.
- `domain-events.ts` in `src/kernel/events/` — available to all modules that import `KernelModule`.

### References
- Event Bus architecture: `epics.md` line 112 — `NestJS EventEmitter2 for cross-module communication`
- Story AC: `epics.md` lines 381–412
- FR50 (immutable audit trail): `epics.md` line 67, `prd.md` line 881
- FR51 (audit retention): `epics.md` line 179
- Guard chain (for context): `epics.md` line 111

## Implementation Reference

### 1. Prisma Schema Addition

Add to `apps/backend/prisma/schema.prisma` (in KERNEL SCHEMA section):

```prisma
model AuditLog {
  id         String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  tenantId   String    @map("tenant_id") @db.Uuid
  userId     String?   @map("user_id") @db.Uuid
  action     String    // "CREATE" | "UPDATE" | "DELETE"
  entity     String
  entityId   String    @map("entity_id") @db.Uuid
  before     Json?
  after      Json?
  createdAt  DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
  tenant     Tenant    @relation(fields: [tenantId], references: [id])

  @@index([tenantId, createdAt])
  @@index([entityId])
  @@map("audit_log")
  @@schema("kernel")
}
```

Also add `auditLogs AuditLog[]` to the `Tenant` model relations.

### 2. Migration SQL

`apps/backend/prisma/migrations/20260315020000_audit_log_event_bus/migration.sql`:

```sql
-- CreateTable kernel.audit_log
CREATE TABLE "kernel"."audit_log" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "user_id" UUID,
    "action" VARCHAR(20) NOT NULL,
    "entity" VARCHAR(100) NOT NULL,
    "entity_id" UUID NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: (tenant_id, created_at) — for per-tenant chronological queries
CREATE INDEX "audit_log_tenant_id_created_at_idx"
    ON "kernel"."audit_log"("tenant_id", "created_at");

-- CreateIndex: entity_id — for per-entity history queries
CREATE INDEX "audit_log_entity_id_idx"
    ON "kernel"."audit_log"("entity_id");

-- AddForeignKey: audit_log → tenants
ALTER TABLE "kernel"."audit_log"
    ADD CONSTRAINT "audit_log_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Immutability: prevent UPDATE and DELETE on audit_log rows
CREATE OR REPLACE FUNCTION kernel.prevent_audit_log_mutation()
RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is immutable — updates and deletes are not permitted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "audit_log_immutability"
    BEFORE UPDATE OR DELETE ON "kernel"."audit_log"
    FOR EACH ROW
    EXECUTE FUNCTION kernel.prevent_audit_log_mutation();
```

### 3. Domain Event Classes

`apps/backend/src/kernel/events/domain-events.ts`:

```typescript
export class TransactionCreatedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly transactionId: string,
    public readonly amount: number,
    public readonly userId: string,
  ) {}
}

export class StockAdjustedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly productId: string,
    public readonly delta: number,
    public readonly reason: string,
  ) {}
}

export class SessionClosedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly sessionId: string,
    public readonly variance: number,
    public readonly userId: string,
  ) {}
}

export class BalanceUpdatedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly contactId: string,
    public readonly previousBalance: number,
    public readonly newBalance: number,
  ) {}
}
```

### 4. App.module.ts — EventEmitterModule

Add `EventEmitterModule.forRoot()` to imports:

```typescript
import { EventEmitterModule } from '@nestjs/event-emitter';

@Module({
  imports: [
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
      global: true,
    }),
    KernelModule,
    // ... other modules
  ],
})
export class AppModule {}
```

### 5. AuditLogService

`apps/backend/src/kernel/audit/audit-log.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface AuditLogParams {
  tenantId: string;
  userId: string | null;
  action: 'CREATE' | 'UPDATE' | 'DELETE';
  entity: string;
  entityId: string;
  before?: Record<string, unknown> | null;
  after?: Record<string, unknown> | null;
}

@Injectable()
export class AuditLogService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: AuditLogParams): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        tenantId: params.tenantId,
        userId: params.userId ?? undefined,
        action: params.action,
        entity: params.entity,
        entityId: params.entityId,
        before: params.before ?? undefined,
        after: params.after ?? undefined,
      },
    });
  }
}
```

### 6. AuditLogModule

`apps/backend/src/kernel/audit/audit-log.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { AuditLogService } from './audit-log.service';

@Module({
  providers: [AuditLogService],
  exports: [AuditLogService],
})
export class AuditLogModule {}
```

### 7. Updated KernelModule

```typescript
import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { TenancyModule } from './tenancy/tenancy.module';
import { RbacModule } from './rbac/rbac.module';
import { ModulesModule } from './modules/modules.module';
import { AuditLogModule } from './audit/audit-log.module';
import { AuthGuard } from './auth/auth.guard';
import { TenantGuard } from './tenancy/tenant.guard';
import { ModuleGuard } from './modules/module.guard';
import { RolesGuard } from './rbac/roles.guard';

@Global()
@Module({
  imports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: TenantGuard },
    { provide: APP_GUARD, useClass: ModuleGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule],
})
export class KernelModule {}
```

### 8. Updated OrganizationService (excerpt)

```typescript
@Injectable()
export class OrganizationService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createOrganization(name: string, userId: string) {
    // ... existing Supabase + Prisma logic ...
    const tenant = /* result */;

    await this.auditLogService.log({
      tenantId: tenant.id,
      userId,
      action: 'CREATE',
      entity: 'Tenant',
      entityId: tenant.id,
      before: null,
      after: { id: tenant.id, name: tenant.name },
    });

    return tenant;
  }

  async addMember(tenantId: string, userId: string, roleName: string) {
    // ... existing logic ...
    const member = /* result */;

    await this.auditLogService.log({
      tenantId,
      userId,
      action: 'CREATE',
      entity: 'OrganizationMember',
      entityId: member.id,
      before: null,
      after: { id: member.id, userId, roleId: member.roleId },
    });

    return member;
  }
}
```

### 9. Test — `audit-log.service.spec.ts`

`apps/backend/src/kernel/audit/audit-log.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { AuditLogService } from './audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AuditLogService', () => {
  let service: AuditLogService;

  const mockPrismaService = {
    auditLog: {
      create: jest.fn(),
    },
  };

  const validTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';
  const validUserId  = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const validEntityId = 'b2c3d4e5-f6a7-7890-abcd-ef1234567890';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuditLogService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AuditLogService>(AuditLogService);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('log', () => {
    it('should create a CREATE audit entry with null before', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'CREATE',
        entity: 'Tenant',
        entityId: validEntityId,
        before: null,
        after: { name: 'Test Store' },
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: {
          tenantId: validTenantId,
          userId: validUserId,
          action: 'CREATE',
          entity: 'Tenant',
          entityId: validEntityId,
          before: undefined,
          after: { name: 'Test Store' },
        },
      });
    });

    it('should create a DELETE audit entry with null after', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'DELETE',
        entity: 'OrganizationMember',
        entityId: validEntityId,
        before: { userId: 'some-user' },
        after: null,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          action: 'DELETE',
          before: { userId: 'some-user' },
          after: undefined,
        }),
      });
    });

    it('should create an UPDATE audit entry with both before and after', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'UPDATE',
        entity: 'Product',
        entityId: validEntityId,
        before: { price: 1000 },
        after: { price: 1200 },
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          action: 'UPDATE',
          before: { price: 1000 },
          after: { price: 1200 },
        }),
      });
    });

    it('should accept null userId for system-generated events', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: null,
        action: 'CREATE',
        entity: 'SystemEvent',
        entityId: validEntityId,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: undefined, // null → undefined for Prisma optional field
        }),
      });
    });

    it('should call prisma.auditLog.create with tenantId and entity', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'CREATE',
        entity: 'OrganizationMember',
        entityId: validEntityId,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            tenantId: validTenantId,
            entity: 'OrganizationMember',
            entityId: validEntityId,
          }),
        }),
      );
    });
  });
});
```

## Files to Create / Modify

| Action | Path |
|--------|------|
| Install pkg | `@nestjs/event-emitter` (npm install in apps/backend) |
| Modify | `apps/backend/prisma/schema.prisma` |
| Create | `apps/backend/prisma/migrations/20260315020000_audit_log_event_bus/migration.sql` |
| Create | `apps/backend/src/kernel/events/domain-events.ts` |
| Modify | `apps/backend/src/app.module.ts` |
| Create | `apps/backend/src/kernel/audit/audit-log.service.ts` |
| Create | `apps/backend/src/kernel/audit/audit-log.module.ts` |
| Modify | `apps/backend/src/kernel/kernel.module.ts` |
| Modify | `apps/backend/src/organization/organization.service.ts` |
| Create | `apps/backend/src/kernel/audit/audit-log.service.spec.ts` |
| Modify | `apps/backend/src/organization/organization.service.spec.ts` |

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `@nestjs/event-emitter@^3.0.1` installed via `npm install` in `apps/backend`.
- `jest.resetAllMocks()` in `afterEach` clears `mockReturnThis()` chains — Supabase fluent chain mocks must be re-initialized in `beforeEach`, not just at declaration time. This is the key learning added to Story 1.4 that was not documented in Story 1.3.
- `AuditLogService.log()` converts `null` params to `undefined` for Prisma optional fields (`userId`, `before`, `after`).
- 75 tests pass total (7 new audit-log service + 2 new org service audit assertions), 0 regressions.

### File List

| Action | Path |
|--------|------|
| Installed | `apps/backend/package.json` — `@nestjs/event-emitter@^3.0.1` |
| Modified | `apps/backend/prisma/schema.prisma` |
| Created | `apps/backend/prisma/migrations/20260315020000_audit_log_event_bus/migration.sql` |
| Created | `apps/backend/src/kernel/events/domain-events.ts` |
| Modified | `apps/backend/src/app.module.ts` |
| Created | `apps/backend/src/kernel/audit/audit-log.service.ts` |
| Created | `apps/backend/src/kernel/audit/audit-log.module.ts` |
| Modified | `apps/backend/src/kernel/kernel.module.ts` |
| Modified | `apps/backend/src/organization/organization.service.ts` |
| Created | `apps/backend/src/kernel/audit/audit-log.service.spec.ts` |
| Modified | `apps/backend/src/organization/organization.service.spec.ts` |
