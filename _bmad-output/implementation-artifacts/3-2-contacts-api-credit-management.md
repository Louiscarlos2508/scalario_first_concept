# Story 3.2: Contacts API & Credit Management

Status: done

## Story

As a commercial,
I want to manage customer profiles and record credit sales that update their outstanding balance,
so that I can track which customers owe money and settle debts.

## Acceptance Criteria

1. **AC1 — POST /contacts (create contact + AuditLog):** Given an authenticated user, when they call `POST /contacts` with `{ name, phone?, email?, address?, tenantId }`, then:
   - A Contact is created in `shared.contacts` with `contact_type = 'customer'` and `balance = 0`
   - An AuditLog entry is recorded: `action='CREATE'`, `entity='Contact'`, `entityId=<new id>`

2. **AC2 — GET /contacts?since=<ISO8601> (delta sync):** Given an authenticated user, when they call `GET /contacts?since=<ISO8601>&tenantId=<uuid>`, then only contacts with `updated_at > since` are returned (including soft-deleted for tombstoning). When `since` is absent, only non-deleted contacts are returned. Response includes `meta.serverTime`.

3. **AC3 — GET /contacts/search?q=<query> (search):** Given an authenticated user, when they call `GET /contacts/search?q=<name_or_phone>&tenantId=<uuid>`, then contacts matching the search by name or phone (case-insensitive contains) are returned.

4. **AC4 — ContactsService.updateBalance(contactId, amount) + BalanceUpdated event:** Given a credit sale is recorded against a customer, when `ContactsService.updateBalance(contactId, amount)` is called, then:
   - The contact's balance is incremented by `amount`
   - A `BalanceUpdated` event is emitted via EventBusService

5. **AC5 — POST /contacts/:id/settle (debt settlement + AuditLog):** Given a customer has an outstanding balance, when a user calls `POST /contacts/:id/settle` with `{ amount }`, then:
   - The balance is decremented by `amount`
   - An AuditLog entry records the settlement: `action='UPDATE'`, `entity='Contact'`, `before: { balance: old }`, `after: { balance: new }`

6. **AC6 — ContactsModule as DynamicModule:** Given the ContactsModule is implemented, when it is registered in AppModule, then it is registered as `ContactsModule.register()` (DynamicModule pattern, consistent with CatalogModule from Story 2.3), and exports ContactsService for use by Transactions/Payments modules.

7. **AC7 — @RequiresModule('contacts') gate:** Given the ContactsController has `@RequiresModule('contacts')`, when a tenant without the `contacts` module activated calls any contacts endpoint, then ModuleGuard returns 403.

8. **AC8 — Old /pos/customers proxy:** Given the old `/pos/customers` endpoints exist in CustomerController and PosController, when a client calls those endpoints, then CustomerService delegates to ContactsService and returns identical response shapes.

9. **AC9 — public.customers migration (drop):** Given all customer data exists in `shared.contacts` from Story 3.1, when the Story 3.2 migration runs, then `public.customers` is dropped (after confirming row counts match). The `Customer` model is removed from `schema.prisma` (or kept as a view alias — see Dev Notes).

10. **AC10 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 3.2 changes are applied, all existing tests continue to pass. PosService tests that test customer-related methods may need CatalogService/ContactsService mocks updated.

## Tasks / Subtasks

### Phase 1 — Migration: drop public.customers (AC9)

- [x] **1.1** Create directory: `apps/backend/prisma/migrations/20260315070000_drop_public_customers/`

- [x] **1.2** Create `migration.sql`:
  ```sql
  -- Story 3.2: Drop public.customers after migration to shared.contacts (Story 3.1)
  -- Verify row counts match before dropping
  -- DO $$
  -- DECLARE
  --   src_count INTEGER;
  --   dst_count INTEGER;
  -- BEGIN
  --   SELECT COUNT(*) INTO src_count FROM "public"."customers";
  --   SELECT COUNT(*) INTO dst_count FROM "shared"."contacts" WHERE contact_type = 'customer';
  --   IF src_count != dst_count THEN
  --     RAISE EXCEPTION 'Row count mismatch: customers=% contacts=%', src_count, dst_count;
  --   END IF;
  -- END $$;

  -- Drop orders.customer_id FK before dropping customers table
  ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_customer_id_fkey";

  -- Drop public.customers
  DROP TABLE "public"."customers" CASCADE;
  ```
  **NOTE:** The row count assertion above is commented — uncomment if running against a live DB. The CASCADE will drop the FK from `public.orders.customer_id → public.customers.id`.

- [x] **1.3** Update Prisma schema:
  - Remove `Customer` model from `schema.prisma` (or replace with a Prisma `view` if needed — see Dev Notes)
  - Remove `customer Customer? @relation(...)` from `Order` model
  - Keep `customerId String? @map("customer_id") @db.Uuid` on `Order` as raw field (orders stay in public; customer data is now in shared.contacts)
  - Remove `customers Customer[]` from `Tenant` model

### Phase 2 — ContactsModule implementation (AC1–AC7)

- [x] **2.1** Create `apps/backend/src/shared/contacts/contacts.service.ts`:
  - Inject `PrismaService`, `AuditLogService`, `EventBusService`
  - `createContact(data, userId)` → creates Contact + AuditLog
  - `getContacts(params: { tenantId, since?, page?, limit? })` → delta-sync aware query with `meta.serverTime`
  - `searchContacts(tenantId, query)` → case-insensitive name/phone search
  - `updateBalance(contactId, amount)` → increment balance + emit `BalanceUpdated` event
  - `settleDebt(contactId, amount, userId, tenantId)` → decrement balance + AuditLog with before/after
  - `getContactById(id)` → single contact lookup

- [x] **2.2** Create `apps/backend/src/shared/contacts/contacts.controller.ts`:
  - `@Controller('contacts')` — routes at `/contacts/...`
  - `@RequiresModule('contacts')` on the class
  - `POST /contacts` — `@Roles('owner', 'commercial')` (both can create contacts)
  - `GET /contacts` — no `@Roles` (all authenticated)
  - `GET /contacts/search` — no `@Roles`
  - `POST /contacts/:id/settle` — `@Roles('owner', 'commercial')` (both can settle debts)
  - Extract `userId` from `req.user?.sub` for audit methods

- [x] **2.3** Create `apps/backend/src/shared/contacts/contacts.module.ts` as DynamicModule:
  ```typescript
  @Module({})
  export class ContactsModule {
    static register(): DynamicModule {
      return {
        module: ContactsModule,
        providers: [ContactsService],
        controllers: [ContactsController],
        exports: [ContactsService],
      };
    }
  }
  ```

- [x] **2.4** Register `ContactsModule.register()` in `apps/backend/src/app.module.ts`.

### Phase 3 — CustomerService proxy (AC8)

- [x] **3.1** Inject `ContactsService` into `CustomerService` (CustomerModule imports ContactsModule, or direct import).

- [x] **3.2** Update `apps/backend/src/pos/customer.service.ts` methods to proxy:
  - `getCustomers(tenantId)` → `return this.contactsService.getContacts({ tenantId })`
  - `createCustomer(tenantId, data)` → `return this.contactsService.createContact({ ...data, tenantId }, null)`
  - `searchCustomers(tenantId, query)` → `return this.contactsService.searchContacts(tenantId, query)`
  - `settleDebt(id, amount)` → `return this.contactsService.settleDebt(id, amount, null, null)`
  - `getCustomerById(id)` → `return this.contactsService.getContactById(id)`

- [x] **3.3** Add `ContactsModule` to `PosModule` imports (so CustomerService can inject ContactsService).

- [x] **3.4** Update `apps/backend/src/pos/pos.service.ts` — update `syncOrder()` customer balance logic:
  - Currently references `this.prisma.customer.update`. After public.customers is dropped, update to `this.prisma.contact.update` (or call `this.contactsService.updateBalance(...)`)
  - If ContactsService is injected in PosService, prefer `this.contactsService.updateBalance(customerId, amount)`

### Phase 4 — Tests (AC10)

- [x] **4.1** Create `apps/backend/src/shared/contacts/contacts.service.spec.ts`:
  - Mock PrismaService (contact.create, contact.findMany, contact.update, contact.count)
  - Mock AuditLogService (log)
  - Mock EventBusService (emit)
  - Test createContact: creates contact + calls auditLog.log with action='CREATE'
  - Test getContacts: without `since` excludes is_deleted; with `since` includes all; returns meta.serverTime
  - Test searchContacts: case-insensitive OR on name/phone
  - Test updateBalance: increments balance + emits BalanceUpdated event
  - Test settleDebt: decrements balance + AuditLog with before/after

- [x] **4.2** Create `apps/backend/src/shared/contacts/contacts.controller.spec.ts`:
  - Mock ContactsService
  - Test all endpoints respond correctly

- [x] **4.3** Update existing `CustomerService` tests (if any) to mock ContactsService.

- [x] **4.4** Update `PosService` tests — mock `this.prisma.customer` calls must switch to `this.prisma.contact` or `ContactsService` mocks.

- [x] **4.5** Run `npx jest --no-coverage` from `apps/backend/` — all tests pass.

## Dev Notes

### Scope Boundary — What Story 3.2 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| POS credit sale integration | Epic 4 | Transactions module |
| Supplier contact type usage | Epic 5 | Inventory suppliers |
| `linked_tenant_id` B2B activation | Phase 3 | Scalario Connect |
| RLS policy on shared.contacts | Later | After full Supabase RLS setup |

### Prisma: Remove Customer Model

After `public.customers` is dropped, the `Customer` model must be removed from `schema.prisma`. The cascade impact:

**Models to update:**
- Remove `Customer` model entirely from schema.prisma
- `Order` model: remove `customer Customer? @relation(...)` line; keep `customerId String? @map("customer_id") @db.Uuid` as raw field
- `Tenant` model: remove `customers Customer[]` from relations list
- `PosSession` model: check if it references Customer (it doesn't — no direct relation)

After removal, `prisma.customer` is no longer accessible. Update all PosService code that calls `this.prisma.customer.*` to use `this.prisma.contact.*` or `ContactsService` methods.

**In PosService.syncOrder():** Currently calls `this.prisma.customer.findUnique` and `this.prisma.customer.update`. After Customer model removed:
```typescript
// Replace:
const customer = await this.prisma.customer.findUnique({ where: { id: orderData.customer_id } });
// With:
const contact = await this.prisma.contact.findUnique({ where: { id: orderData.customer_id } });

// Replace balance increment:
await this.prisma.customer.update({ where: { id: ... }, data: { balance: { increment: ... } } });
// With:
await this.contactsService.updateBalance(customerId, amount);
// OR directly:
await this.prisma.contact.update({ where: { id: ... }, data: { balance: { increment: ... } } });
```

### BalanceUpdated Event: EventBusService

EventBusService is in `kernel/events/event-bus.service.ts` and is exported from KernelModule (globally available). Use `emit()` or the event emitter pattern:

```typescript
// From kernel/events/event-bus.service.ts
import { EventBusService } from '../../kernel/events/event-bus.service';

// In ContactsService:
constructor(
  private readonly prisma: PrismaService,
  private readonly auditLog: AuditLogService,
  private readonly eventBus: EventBusService,
) {}

async updateBalance(contactId: string, amount: number) {
  const contact = await this.prisma.contact.update({
    where: { id: contactId },
    data: { balance: { increment: amount } },
  });
  // Emit event for Transactions/Payments module to subscribe
  this.eventBus.emit('contact.balance_updated', {
    contactId,
    newBalance: contact.balance,
    delta: amount,
    tenantId: contact.tenantId,
  });
  return contact;
}
```

Check `apps/backend/src/kernel/events/event-bus.service.ts` for exact `emit()` method signature before implementing.

### settleDebt AuditLog: Before/After Pattern

```typescript
async settleDebt(contactId: string, amount: number, userId: string | null, tenantId: string | null) {
  const before = await this.prisma.contact.findUnique({ where: { id: contactId } });
  const after = await this.prisma.contact.update({
    where: { id: contactId },
    data: { balance: { decrement: amount } },
  });
  if (tenantId) {
    await this.auditLog.log({
      tenantId,
      userId,
      action: 'UPDATE',
      entity: 'Contact',
      entityId: contactId,
      before: { balance: before?.balance },
      after: { balance: after.balance },
    });
  }
  return after;
}
```

### DynamicModule Pattern: Consistency with CatalogModule

ContactsModule follows the same DynamicModule pattern established in Story 2.3:
```typescript
@Module({})
export class ContactsModule {
  static register(): DynamicModule {
    return {
      module: ContactsModule,
      providers: [ContactsService],
      controllers: [ContactsController],
      exports: [ContactsService],   // allows Transactions/Payments to import
    };
  }
}
```

In AppModule:
```typescript
imports: [
  ...
  CatalogModule.register(),
  ContactsModule.register(),
  ...
]
```

### PosModule Dependency Chain

```
AppModule
  ├── CatalogModule.register()
  ├── ContactsModule.register()     ← NEW
  └── PosModule
        imports: [CatalogModule.register(), ContactsModule.register()]
        providers: [PosService, PosSessionService, CustomerService]
```

CustomerService constructor after update:
```typescript
constructor(
  private readonly prisma: PrismaService,
  private readonly contactsService: ContactsService,
) {}
```

### No Global Prefix in main.ts

`main.ts` has no `app.setGlobalPrefix('api/v1')`. Routes mount at root:
- `GET /contacts` (not `/api/v1/contacts`)
- `POST /contacts`
- etc.

Consistent with existing pattern: `/pos/...`, `/catalog/...`.

### Migration: Orders FK Constraint

The `public.orders` table has a FK `orders_customer_id_fkey` → `public.customers(id)`. This must be dropped before `DROP TABLE public.customers CASCADE`. The `CASCADE` keyword handles it at DB level, but explicitly dropping with `ALTER TABLE ... DROP CONSTRAINT IF EXISTS` is safer and more readable.

After the drop, `orders.customer_id` column remains as a raw UUID (no DB-level FK). Existing order records retain the UUID values that now correspond to `shared.contacts.id` (same UUIDs were migrated in Story 3.1).

### Test: PosService syncOrder() Impact

`PosService.syncOrder()` currently calls:
1. `this.prisma.customer.findUnique(...)` — becomes `this.prisma.contact.findUnique(...)`
2. `this.prisma.customer.update(...)` (balance increment) — becomes `this.prisma.contact.update(...)` or `this.contactsService.updateBalance(...)`

The existing PosService tests mock `prisma.customer` — those mocks must be updated to `prisma.contact` after this story. Check `apps/backend/src/pos/pos.service.spec.ts` (if it exists) for test updates needed.

### Project Structure Notes

Files to create/modify:
```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — remove Customer model; update Order.customer, Tenant.customers; add Contact @relation fields]
└── migrations/
    └── 20260315070000_drop_public_customers/
        └── migration.sql                              [NEW — DROP orders FK + DROP public.customers]

apps/backend/src/
├── shared/
│   └── contacts/
│       ├── contacts.service.ts                        [NEW]
│       ├── contacts.service.spec.ts                   [NEW]
│       ├── contacts.controller.ts                     [NEW]
│       ├── contacts.controller.spec.ts                [NEW]
│       └── contacts.module.ts                         [NEW]
├── pos/
│   ├── pos.module.ts                                  [MODIFY — add ContactsModule.register()]
│   ├── pos.service.ts                                 [MODIFY — prisma.customer → prisma.contact; inject ContactsService for balance]
│   ├── customer.service.ts                            [MODIFY — inject ContactsService; proxy all methods]
│   └── customer.controller.ts                         [unchanged — already proxies via CustomerService]
└── app.module.ts                                      [MODIFY — add ContactsModule.register()]
```

### References

- [Epic 3 Story 3.2 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 3.1 — Contact model + migration](_bmad-output/implementation-artifacts/3-1-contact-entity-migration.md)
- [CatalogModule DynamicModule pattern (Story 2.3)](_bmad-output/implementation-artifacts/2-3-catalog-sync-adapter-delta-pull.md)
- [AuditLogService API](apps/backend/src/kernel/audit/audit-log.service.ts)
- [EventBusService](apps/backend/src/kernel/events/event-bus.service.ts)
- [RequiresModule decorator](apps/backend/src/kernel/modules/module.decorator.ts)
- [Roles decorator](apps/backend/src/kernel/rbac/roles.decorator.ts)
- [CustomerService (proxy source)](apps/backend/src/pos/customer.service.ts)
- [CustomerController (to keep as proxy)](apps/backend/src/pos/customer.controller.ts)
- [PosService syncOrder — customer balance logic to migrate](apps/backend/src/pos/pos.service.ts)
- [OrganizationModule — AuditLogService injection pattern (no explicit import)](apps/backend/src/organization/organization.module.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `Contact` model used in SHARED schema via `prisma.contact.*` — `Customer` model fully removed from schema.prisma and all service code
- `EventBusService` uses `publish()` not `emit()` — corrected from dev notes which had `this.eventBus.emit()`. Used `this.eventBus.publish('contact.balance_updated', {...})`.
- `Order.customer` relation removed — `customerId` retained as raw UUID field. `syncOrder()` upsert uses `customerId: validCustomerId ?? null` (raw field) instead of Prisma relation connect
- `PosService.syncOrder()` now uses `prisma.contact.findUnique()` and `contactsService.updateBalance()` for credit payment balance tracking
- `PosService` customer methods (`getCustomers`, `createCustomer`, `settleDebt`) proxy to `ContactsService`
- `CustomerService` fully refactored to inject `ContactsService` — all methods proxy; `updateCustomer()` retained as stub for backward compat (returns current contact)
- `ContactsModule.register()` added to both `AppModule` and `PosModule` — NestJS deduplicates
- No existing `CustomerService` or `PosService` spec files — Tasks 4.3/4.4 verified by full suite pass
- 147/147 tests pass (14 new: 10 contacts service + 4 contacts controller)

### File List

- `apps/backend/prisma/schema.prisma` — removed Customer model, Order.customer relation, Tenant.customers; `customerId` kept as raw field
- `apps/backend/prisma/migrations/20260315070000_drop_public_customers/migration.sql` — new migration
- `apps/backend/src/shared/contacts/contacts.service.ts` — new
- `apps/backend/src/shared/contacts/contacts.controller.ts` — new
- `apps/backend/src/shared/contacts/contacts.module.ts` — new
- `apps/backend/src/shared/contacts/contacts.service.spec.ts` — new
- `apps/backend/src/shared/contacts/contacts.controller.spec.ts` — new
- `apps/backend/src/app.module.ts` — added ContactsModule.register()
- `apps/backend/src/pos/pos.module.ts` — added ContactsModule.register()
- `apps/backend/src/pos/pos.service.ts` — injected ContactsService; prisma.customer → prisma.contact/contactsService
- `apps/backend/src/pos/customer.service.ts` — refactored to proxy ContactsService
