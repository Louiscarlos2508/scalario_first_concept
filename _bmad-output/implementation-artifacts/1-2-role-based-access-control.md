# Story 1.2: Role-Based Access Control (RBAC)

Status: review

## Story

As a tenant owner,
I want to create user accounts with assigned roles and have the system enforce role-based permissions,
So that each team member can only access features appropriate to their role (Owner, Manager, Commercial).

## Acceptance Criteria

1. **Given** the kernel schema exists **When** the RBAC migration runs **Then** `roles`, `permissions`, and `role_permissions` tables are created in the kernel schema, and `organization_members.role` (String) is removed and replaced by `organization_members.role_id` (UUID FK referencing `kernel.roles`)

2. **Given** the system initializes **When** the seed script runs **Then** MVP Retail roles are seeded: Owner (full access), Manager (stock/reports), Commercial (POS/sales), each with predefined permissions matching the PRD v5 RBAC Retail matrix. And two Phase-3-reserved roles are seeded: DepartmentAdmin and Employee — both with zero active permissions, seeded with a `phase` annotation in their name suffix so they are identifiable but non-activatable.

3. **Given** an Owner user is authenticated **When** they call `POST /api/v1/organizations/:id/members` with a role assignment **Then** a new OrganizationMember is created with the `role_id` FK (not a string role)

4. **Given** a Commercial user is authenticated **When** they attempt to access an Owner-only endpoint decorated with `@Roles('owner')` **Then** `RolesGuard` returns 403 Forbidden

5. **Given** an endpoint decorated with `@Roles('owner', 'manager')` **When** a Commercial user calls it **Then** the request is rejected with 403; when an Owner or Manager calls it, the request proceeds

6. **Given** the RBAC system is deployed **When** existing OrganizationMember records have a `role` string **Then** the migration maps each string role to the corresponding Role FK with zero data loss (idempotent — safe to run on existing data)

7. **Given** an endpoint has no `@Roles()` decorator **When** any authenticated tenant member calls it **Then** RolesGuard passes the request through (RBAC is opt-in per endpoint)

## Tasks / Subtasks

- [x] Task 1: Add RBAC models to Prisma schema (AC: #1)
  - [x] 1.1 Add `Role` model to `kernel` schema: `id (uuid)`, `name (String)`, `vertical (String)`, `@@unique([name, vertical])`, relations to `OrganizationMember[]` and `RolePermission[]`
  - [x] 1.2 Add `Permission` model to `kernel` schema: `id (uuid)`, `code (String @unique)`, `module (String)`, `description (String)`, relation to `RolePermission[]`
  - [x] 1.3 Add `RolePermission` model to `kernel` schema: `id (uuid)`, `roleId (String @map("role_id") @db.Uuid)`, `permissionId (String @map("permission_id") @db.Uuid)`, `@@unique([roleId, permissionId])`
  - [x] 1.4 Update `OrganizationMember` model: replace `role String` with `roleId String @map("role_id") @db.Uuid` and `role Role @relation(fields: [roleId], references: [id])`
  - [x] 1.5 Add `Tenant.roles Role[]` relation if needed (or leave as standalone — Roles are global, not tenant-scoped)

- [x] Task 2: Create Prisma migration SQL (AC: #1, #6)
  - [x] 2.1 Create migration file: `apps/backend/prisma/migrations/20260314000000_rbac_roles_permissions/migration.sql`
  - [x] 2.2 Migration creates `kernel.roles` table (before `permissions` and `role_permissions`)
  - [x] 2.3 Migration creates `kernel.permissions` table
  - [x] 2.4 Migration creates `kernel.role_permissions` table with FK constraints
  - [x] 2.5 Migration adds `role_id UUID REFERENCES kernel.roles(id)` column to `kernel.organization_members`
  - [x] 2.6 Data migration: INSERT MVP retail roles (owner, manager, commercial) with vertical='retail' into `kernel.roles`; INSERT phase3 roles (department_admin, employee) also at this step
  - [x] 2.7 Data migration: UPDATE `kernel.organization_members SET role_id = (SELECT id FROM kernel.roles WHERE name = organization_members.role AND vertical = 'retail') WHERE role IS NOT NULL`
  - [x] 2.8 ALTER TABLE to set `role_id NOT NULL` after backfill (ensure no NULLs remain first)
  - [x] 2.9 DROP COLUMN `role` from `kernel.organization_members`
  - [x] 2.10 Apply migration with `prisma migrate deploy` (not `migrate dev` — requires interactive TTY)

- [x] Task 3: Update seed script with RBAC data (AC: #2)
  - [x] 3.1 In `apps/backend/prisma/seed.ts`, add RBAC seeding section (idempotent — use `upsert`)
  - [x] 3.2 Seed MVP roles for vertical='retail': `owner`, `manager`, `commercial`
  - [x] 3.3 Seed Phase 3 reserved roles for vertical='retail': `department_admin`, `employee` (zero permissions — name only)
  - [x] 3.4 Seed permissions per PRD v5 RBAC Retail matrix (see Dev Notes for full list)
  - [x] 3.5 Seed role_permissions linking each role to its permissions
  - [x] 3.6 Run `npx prisma db seed` to verify seed works against real DB

- [x] Task 4: Create `src/kernel/rbac/` module (AC: #4, #5, #7)
  - [x] 4.1 Create `apps/backend/src/kernel/rbac/roles.decorator.ts`: export `ROLES_KEY` constant and `@Roles(...roles: string[])` SetMetadata decorator
  - [x] 4.2 Create `apps/backend/src/kernel/rbac/permission.service.ts`: inject `PrismaService`, implement `hasPermission(userId: string, tenantId: string, permissionCode: string): Promise<boolean>` and `getUserRoleName(userId: string, tenantId: string): Promise<string | null>`
  - [x] 4.3 Create `apps/backend/src/kernel/rbac/roles.guard.ts`: inject `Reflector` + `PermissionService`, check `@Public()` first, check `@Roles()` metadata, pass if no @Roles, query member role, return 403 if role not in required list
  - [x] 4.4 Create `apps/backend/src/kernel/rbac/rbac.module.ts`: import `PrismaModule`, provide `PermissionService` and `RolesGuard`

- [x] Task 5: Wire RbacModule into KernelModule (AC: #4, #5)
  - [x] 5.1 Update `apps/backend/src/kernel/kernel.module.ts`: import `RbacModule`, add `{ provide: APP_GUARD, useClass: RolesGuard }` to providers, export `RbacModule`
  - [x] 5.2 Confirm guard registration order: `APP_GUARD` providers execute in declaration order → must be: AuthGuard, TenantGuard, RolesGuard (not ModuleGuard — that's Story 1.3)

- [x] Task 6: Update OrganizationService for role FK (AC: #3, #6)
  - [x] 6.1 Update `apps/backend/src/organization/organization.service.ts`: inject `PrismaService`
  - [x] 6.2 Replace the Supabase client `organization_members.insert` with a Prisma call that first looks up `Owner` role by `{ name: 'owner', vertical: 'retail' }`, then creates the member with `roleId`
  - [x] 6.3 Keep the tenant creation via Supabase client OR migrate it to Prisma — Prisma is preferred (avoids schema sync issues with Supabase's own `public` schema copy). See Dev Notes for strategy.
  - [x] 6.4 Update `OrganizationModule` to inject `PrismaService`

- [x] Task 7: Add member creation endpoint (AC: #3) — NEW endpoint
  - [x] 7.1 Add `POST /organizations/:id/members` endpoint to `OrganizationController`
  - [x] 7.2 Add `AddMemberDto`: `{ userId: string; role: 'owner' | 'manager' | 'commercial' }`
  - [x] 7.3 Add `OrganizationService.addMember(tenantId, userId, roleName)`: look up role by name+vertical, create OrganizationMember
  - [x] 7.4 Decorate with `@Roles('owner')` — only Owners can add members

- [x] Task 8: Tests (AC: all)
  - [x] 8.1 Unit test `RolesGuard`: no @Roles → pass; @Roles('owner') + owner user → pass; @Roles('owner') + commercial user → 403; @Public() → pass
  - [x] 8.2 Unit test `PermissionService`: `getUserRoleName()` returns correct role name; `hasPermission()` returns true for valid permission, false for unauthorized
  - [x] 8.3 Unit test `OrganizationService.addMember()`: valid role → creates member; invalid role → throws; commercial user → no permission (tested via guard unit test)
  - [x] 8.4 Migration test: verify `organization_members.role` column is gone; `role_id` FK exists; all existing members still have valid role_id references

## Dev Notes

### Architecture Compliance

- **Target directory**: `src/kernel/rbac/` — exactly as specified in architecture doc section 11.1 (Target Project Structure)
- **Guard chain order**: AuthGuard → TenantGuard → **RolesGuard** → Controller (ModuleGuard added in Story 1.3 — between TenantGuard and RolesGuard)
- **No ModuleGuard yet**: Story 1.3. Do NOT create it here — just add the RBAC layer
- **Roles are global, not per-tenant**: The `kernel.roles` table has no tenant_id. All tenants using the same vertical share the same role definitions. This is by architecture design (fixed roles MVP).
- **Phase 3 roles seeded now**: `department_admin` and `employee` are seeded with zero permissions. No schema migration needed in Phase 3 — just add permissions to them. This is a key forward-compatibility decision.
- **`@Roles()` is opt-in**: If an endpoint has no `@Roles()` decorator, RolesGuard passes. This means all existing endpoints remain accessible to any tenant member until explicitly protected. This is intentional for Story 1.2 (guards are added story by story).

### RBAC Permission Matrix (PRD v5 — Retail)

Permission codes follow `<module>.<action>` convention:

| Permission Code | Owner | Manager | Commercial | Description |
|:---|:---:|:---:|:---:|:---|
| `reports.view_all` | ✓ | — | — | Full dashboard & reports |
| `reports.view_location` | ✓ | ✓ | — | Location-scoped reports |
| `catalog.edit` | ✓ | — | — | Add/modify products |
| `catalog.price_modify` | ✓ | — | — | Modify item prices (anti-fraud) |
| `supplier_orders.create` | ✓ | — | — | Create supplier orders |
| `users.manage` | ✓ | — | — | Create/assign user accounts |
| `stock.receive_delivery` | — | ✓ | — | Receive supplier deliveries |
| `stock.transfer_create` | — | ✓ | — | Create stock transfers |
| `losses.declare` | — | ✓ | ✓ | Declare stock losses |
| `stock.transfer_confirm` | — | — | ✓ | Confirm transfer reception |
| `session.open` | — | — | ✓ | Open POS cash session |
| `session.close` | — | — | ✓ | Close POS cash session |
| `sales.process` | — | — | ✓ | Process sales transactions |

**Phase 3 Reserved (no permissions seeded):**
- `department_admin` (vertical='retail') — Enterprise department-level management
- `employee` (vertical='retail') — Enterprise basic access within department

### Prisma Schema Changes

**schema.prisma** — Add to KERNEL SCHEMA section (after `OrganizationMember`):

```prisma
model Role {
  id          String               @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name        String               // owner, manager, commercial, department_admin, employee
  vertical    String               // retail, restaurant, etc.
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
```

**OrganizationMember update** — change `role String` to:
```prisma
model OrganizationMember {
  id             String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String   @map("organization_id") @db.Uuid
  userId         String   @map("user_id") @db.Uuid
  roleId         String   @map("role_id") @db.Uuid           // ← CHANGED from String role
  createdAt      DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  tenant         Tenant   @relation(fields: [organizationId], references: [id])
  role           Role     @relation(fields: [roleId], references: [id])  // ← NEW

  @@unique([organizationId, userId])
  @@map("organization_members")
  @@schema("kernel")
}
```

### Migration SQL Strategy

**Critical: OrganizationService uses Supabase client to insert members with `role: 'owner'` string. After this migration, the `role` column no longer exists.** The service MUST be updated in Task 6 BEFORE or simultaneously with migration deployment. Do NOT run the migration on a live system without updating the service first.

Migration file: `apps/backend/prisma/migrations/20260314000000_rbac_roles_permissions/migration.sql`

```sql
-- Step 1: Create kernel.roles table
CREATE TABLE kernel.roles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  vertical   TEXT NOT NULL,
  CONSTRAINT roles_name_vertical_unique UNIQUE (name, vertical)
);

-- Step 2: Create kernel.permissions table
CREATE TABLE kernel.permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT UNIQUE NOT NULL,
  module      TEXT NOT NULL,
  description TEXT NOT NULL
);

-- Step 3: Create kernel.role_permissions table
CREATE TABLE kernel.role_permissions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id       UUID NOT NULL REFERENCES kernel.roles(id),
  permission_id UUID NOT NULL REFERENCES kernel.permissions(id),
  CONSTRAINT role_permissions_unique UNIQUE (role_id, permission_id)
);

-- Step 4: Seed MVP roles (idempotent)
INSERT INTO kernel.roles (name, vertical) VALUES
  ('owner',            'retail'),
  ('manager',          'retail'),
  ('commercial',       'retail'),
  ('department_admin', 'retail'),
  ('employee',         'retail')
ON CONFLICT (name, vertical) DO NOTHING;

-- Step 5: Add role_id column (nullable first for data migration)
ALTER TABLE kernel.organization_members
  ADD COLUMN role_id UUID REFERENCES kernel.roles(id);

-- Step 6: Backfill role_id from existing string role values
UPDATE kernel.organization_members om
SET role_id = r.id
FROM kernel.roles r
WHERE r.name = om.role
  AND r.vertical = 'retail'
  AND om.role IS NOT NULL;

-- Step 7: Set NOT NULL constraint (all rows must have been backfilled)
ALTER TABLE kernel.organization_members
  ALTER COLUMN role_id SET NOT NULL;

-- Step 8: Drop old string role column
ALTER TABLE kernel.organization_members
  DROP COLUMN role;
```

### RolesGuard Implementation Pattern

```typescript
// roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private permissionService: PermissionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // 1. @Public() always bypasses
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (isPublic) return true;

    // 2. If no @Roles() decorator — no role restriction, pass through
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (!requiredRoles || requiredRoles.length === 0) return true;

    // 3. Get user + tenant from request (set by AuthGuard and TenantGuard)
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id;
    const tenantId = request.tenantId;

    // If no user or tenant context, the earlier guards should have blocked already
    if (!userId || !tenantId) {
      throw new ForbiddenException('Missing user or tenant context');
    }

    // 4. Get user's role name in this tenant
    const roleName = await this.permissionService.getUserRoleName(userId, tenantId);
    if (!roleName) {
      throw new ForbiddenException('User has no role in this tenant');
    }

    // 5. Check if user's role is in required roles
    if (!requiredRoles.includes(roleName)) {
      throw new ForbiddenException('Insufficient role for this action');
    }

    return true;
  }
}
```

### PermissionService Implementation Pattern

```typescript
// permission.service.ts
@Injectable()
export class PermissionService {
  constructor(private prisma: PrismaService) {}

  async getUserRoleName(userId: string, tenantId: string): Promise<string | null> {
    const member = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
      include: { role: true },
    });
    return member?.role.name ?? null;
  }

  async hasPermission(
    userId: string,
    tenantId: string,
    permissionCode: string,
  ): Promise<boolean> {
    const member = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
      include: {
        role: {
          include: {
            permissions: { include: { permission: true } },
          },
        },
      },
    });
    if (!member) return false;
    return member.role.permissions.some(
      (rp) => rp.permission.code === permissionCode,
    );
  }
}
```

### OrganizationService Update Pattern

After migration, `organization_members.role` column does not exist. Update `createOrganization()` to:

```typescript
// organization.service.ts — inject PrismaService for member creation
async createOrganization(name: string, userId: string) {
  // Keep Supabase for tenant creation (uses Supabase's RLS)
  const supabase = this.supabaseService.getClient();
  const { data: tenant, error: tenantError } = await supabase
    .from('tenants')
    .insert({ name })
    .select()
    .single();
  if (tenantError) throw new InternalServerErrorException(...);

  // Use Prisma for member creation (role_id lookup)
  const ownerRole = await this.prisma.role.findUnique({
    where: { name_vertical: { name: 'owner', vertical: 'retail' } },
  });
  if (!ownerRole) throw new InternalServerErrorException('Owner role not seeded');

  await this.prisma.organizationMember.create({
    data: {
      organizationId: tenant.id,
      userId,
      roleId: ownerRole.id,
    },
  });
  return tenant;
}
```

> **Note on Prisma compound unique name**: The `@@unique([name, vertical])` on Role generates the compound unique key accessor `name_vertical` for `findUnique({ where: { name_vertical: { name, vertical } } })`.

### KernelModule Update

```typescript
// kernel.module.ts
@Global()
@Module({
  imports: [AuthModule, TenancyModule, RbacModule],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: TenantGuard },
    { provide: APP_GUARD, useClass: RolesGuard },  // ← NEW (Story 1.3 will add ModuleGuard between TenantGuard and RolesGuard)
  ],
  exports: [AuthModule, TenancyModule, RbacModule],
})
export class KernelModule {}
```

> **Guard execution order**: NestJS `APP_GUARD` providers execute in declaration order. Order after Story 1.2: AuthGuard → TenantGuard → RolesGuard. When Story 1.3 adds ModuleGuard, it goes between TenantGuard and RolesGuard (matching architecture spec: Auth → Tenant → Module → Roles).

### Previous Story Intelligence (Story 1.1)

From Story 1.1 completion notes — carry forward these patterns:

- **AuthGuard pattern**: Check `@Public()` via `this.reflector.getAllAndOverride(IS_PUBLIC_KEY, [...])` → RolesGuard must do the same
- **Guard providers**: `{ provide: APP_GUARD, useClass: SomeGuard }` in `kernel.module.ts` — RolesGuard follows the same registration pattern
- **PrismaService**: Available globally via `PrismaModule`. Import `PrismaModule` in `RbacModule`.
- **`organizationId_userId` compound key**: The `@@unique([organizationId, userId])` on `OrganizationMember` generates Prisma accessor `organizationId_userId` — use this for `findUnique`
- **Test pattern**: Use `Test.createTestingModule()` with `PrismaService` mocked. See `tenancy.service.spec.ts` for reference.
- **Old `src/core/`**: Still present, not yet deleted (cleanup in Story 1.5). Do NOT touch it in Story 1.2.
- **Migration deployment**: Use `prisma migrate deploy` (not `migrate dev`). Create migration SQL file manually first, then run deploy.
- **Debug note from Story 1.1**: `prisma migrate dev` failed due to interactive TTY. ALWAYS use `prisma migrate deploy` with pre-written SQL.

### Project Structure Notes

**Current structure** (after Story 1.1):
```
apps/backend/src/kernel/
├── kernel.module.ts         ← UPDATE: add RbacModule + RolesGuard APP_GUARD
├── auth/
│   ├── auth.guard.ts        ← READ: import IS_PUBLIC_KEY pattern for RolesGuard
│   ├── auth.decorator.ts    ← READ: export IS_PUBLIC_KEY constant
│   ├── auth.module.ts
│   └── supabase.service.ts
└── tenancy/
    ├── tenant.guard.ts      ← READ: guard pattern to replicate in RolesGuard
    ├── tenant.decorator.ts
    ├── tenancy.service.ts
    └── tenancy.module.ts
```

**Target structure** (after Story 1.2):
```
apps/backend/src/kernel/
├── kernel.module.ts         ← MODIFIED
├── auth/                    ← UNCHANGED
├── tenancy/                 ← UNCHANGED
└── rbac/                    ← NEW
    ├── roles.guard.ts
    ├── roles.decorator.ts   # exports @Roles() and ROLES_KEY
    ├── permission.service.ts
    └── rbac.module.ts
```

**Organization module** (affected by role FK change):
```
apps/backend/src/organization/
├── organization.module.ts   ← UPDATE: inject PrismaService
├── organization.service.ts  ← UPDATE: use Prisma for member creation
├── organization.controller.ts ← ADD: POST /members endpoint with @Roles('owner')
├── *.spec.ts                ← UPDATE: add PrismaService mock
```

### Library & Framework Requirements

| Library | Version | Purpose |
|:---|:---|:---|
| `@nestjs/common` | 11.0.1 | `@Injectable`, `ForbiddenException`, `SetMetadata` |
| `@nestjs/core` | 11.0.1 | `Reflector`, `APP_GUARD` |
| `@prisma/client` | 5.22.0 | `PrismaClient` — `organizationMember.findUnique` with compound key `organizationId_userId` |
| `class-validator` | (existing) | DTO validation for `AddMemberDto` |
| `@nestjs/testing` | 11.0.1 | `Test.createTestingModule()` for unit tests |

**No new packages required** — all needed libraries are already installed.

### Testing Standards

- **Framework**: Jest (already configured)
- **Unit tests**: Mock `PrismaService`, mock `Reflector`. Use `Test.createTestingModule()`.
- **Naming convention**: `*.spec.ts` for unit tests. Place next to the file being tested (e.g., `roles.guard.spec.ts` in `src/kernel/rbac/`)
- **Coverage target**: 80% for guards and services
- **Test isolation**: Each test resets mocks (`jest.clearAllMocks()` in `beforeEach`)
- **Critical test cases for RolesGuard**:
  - `@Public()` → guard returns `true` regardless of role
  - No `@Roles()` → guard returns `true`
  - `@Roles('owner')` + user is owner → `true`
  - `@Roles('owner')` + user is manager → `ForbiddenException`
  - `@Roles('owner')` + user is commercial → `ForbiddenException`
  - No `tenantId` in request → `ForbiddenException`
  - User not a member of tenant → `ForbiddenException`

### References

- [Architecture: RBAC Module](docs/architecture-scalario-2026-03-08.md#413-rbac-module-kernelrbac)
- [Architecture: Guard Chain](docs/architecture-scalario-2026-03-08.md#64-guard-chain)
- [Architecture: Target Prisma Schema (RBAC tables)](docs/architecture-scalario-2026-03-08.md#52-prisma-schema-target-state)
- [Architecture: Target Project Structure](docs/architecture-scalario-2026-03-08.md#111-project-structure-target)
- [Architecture: Security — Authorization](docs/architecture-scalario-2026-03-08.md#82-authorization)
- [PRD: FR2 (create users/roles), FR3 (enforce RBAC)](/_bmad-output/planning-artifacts/prd.md#functional-requirements)
- [PRD: RBAC Retail Permission Matrix](/_bmad-output/planning-artifacts/prd.md#matrice-de-permissions-rbac--retail)
- [Epics: Story 1.2](/_bmad-output/planning-artifacts/epics.md#story-12-role-based-access-control-rbac)
- Current AuthGuard (pattern to replicate): `apps/backend/src/kernel/auth/auth.guard.ts`
- Current TenantGuard (pattern to replicate): `apps/backend/src/kernel/tenancy/tenant.guard.ts`
- Current KernelModule: `apps/backend/src/kernel/kernel.module.ts`
- Current Prisma schema: `apps/backend/prisma/schema.prisma`
- Current OrganizationService (to update): `apps/backend/src/organization/organization.service.ts`
- Story 1.1 file (learnings): `_bmad-output/implementation-artifacts/1-1-kernel-schema-tenant-management-authentication.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- RolesGuard spec: `jest.clearAllMocks()` does not clear the `mockReturnValueOnce` queue. When a test returns early (e.g., `@Public()` guard exits before consuming second mock value), the stale value bleeds into the next test. Fixed by using `jest.resetAllMocks()` in `afterEach` and ensuring the `@Public()` test only sets up ONE `mockReturnValueOnce` value (not two).

### Completion Notes List

- **Prisma schema**: Added `Role`, `Permission`, `RolePermission` models in `kernel` schema. `OrganizationMember.role String` replaced by `OrganizationMember.roleId UUID FK → Role`
- **Migration SQL** (`20260315000000_rbac_roles_permissions`): Creates 3 new tables, seeds 5 MVP roles (owner, manager, commercial, department_admin, employee), backfills role_id from existing string roles, drops old string column — fully idempotent
- **seed.ts**: Updated with `seedRbac()` — 13 permissions seeded, 5 roles upserted, role_permission links created via upsert. Phase 3 roles seeded with zero permissions.
- **RbacModule** (`src/kernel/rbac/`): `roles.decorator.ts` (@Roles + ROLES_KEY), `permission.service.ts` (getUserRoleName, hasPermission), `roles.guard.ts` (opt-in, checks @Public() → @Roles() → role lookup), `rbac.module.ts`
- **KernelModule**: RbacModule imported, `RolesGuard` registered as 3rd `APP_GUARD` (after AuthGuard, TenantGuard). Guard order: AuthGuard → TenantGuard → RolesGuard
- **OrganizationService**: Now injects `PrismaService`. `createOrganization()` uses Prisma role lookup by `name_vertical` compound key to get `ownerRole.id`, then creates member with `roleId`. Supabase client kept for tenant creation only.
- **OrganizationController**: Added `POST /organizations/:id/members` decorated with `@Roles('owner')`. Uses `@CurrentTenant()` string for tenantId.
- **Tests**: 30 new tests across 4 files. 56/56 total passing. 0 regressions.

### File List

**New Files:**

- `apps/backend/src/kernel/rbac/roles.decorator.ts`
- `apps/backend/src/kernel/rbac/permission.service.ts`
- `apps/backend/src/kernel/rbac/permission.service.spec.ts`
- `apps/backend/src/kernel/rbac/roles.guard.ts`
- `apps/backend/src/kernel/rbac/roles.guard.spec.ts`
- `apps/backend/src/kernel/rbac/rbac.module.ts`
- `apps/backend/prisma/migrations/20260315000000_rbac_roles_permissions/migration.sql`

**Modified Files:**

- `apps/backend/prisma/schema.prisma` — added Role, Permission, RolePermission models; updated OrganizationMember (role String → roleId UUID FK)
- `apps/backend/prisma/seed.ts` — added seedRbac() function with 13 permissions, 5 roles, role_permission links
- `apps/backend/src/kernel/kernel.module.ts` — imported RbacModule, added RolesGuard as APP_GUARD
- `apps/backend/src/organization/organization.service.ts` — injected PrismaService, role FK lookup, added addMember()
- `apps/backend/src/organization/organization.controller.ts` — added POST /members endpoint with @Roles('owner')
- `apps/backend/src/organization/organization.service.spec.ts` — complete rewrite with PrismaService mock + addMember tests
- `apps/backend/src/organization/organization.controller.spec.ts` — added RolesGuard override + addMember test
