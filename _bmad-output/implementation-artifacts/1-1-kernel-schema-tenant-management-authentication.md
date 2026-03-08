# Story 1.1: Kernel Schema, Tenant Management & Authentication

Status: in-progress

## Story

As a system administrator,
I want to create and configure tenants, and have users authenticate with tenant-scoped sessions,
So that each business operates in complete isolation with proper authentication.

## Acceptance Criteria

1. **Given** the database has no kernel schema **When** the Prisma migration runs **Then** the `kernel` schema is created with `tenants` and `organization_members` tables, and `Tenant` includes fields: `id`, `name`, `currency` (default XOF), `timezone` (default Africa/Abidjan), `fiscal_jurisdiction`, `status` (active/suspended/archived), `created_at`

2. **Given** an existing Tenant in the old public schema **When** the migration completes **Then** tenant data is preserved in the new kernel schema with new fields populated with defaults

3. **Given** a valid JWT token from Supabase Auth **When** a request hits any protected endpoint **Then** `AuthGuard` validates the token and attaches user context to the request via `@CurrentUser()` decorator

4. **Given** a request with `x-tenant-id` header **When** the request passes AuthGuard **Then** `TenantGuard` validates the user is a member of that tenant, attaches tenant context via `@CurrentTenant()` decorator, and Prisma middleware executes `SET LOCAL app.current_tenant_id` for RLS enforcement

5. **Given** a request without a valid JWT or with an invalid `x-tenant-id` **When** the request hits a protected endpoint **Then** the system returns 401 (no JWT) or 403 (wrong tenant) with clear error messages

6. **Given** a user session that has been idle longer than the configured timeout **When** the next request is made **Then** the session is rejected and the user must re-authenticate

7. **Given** a route decorated with `@Public()` **When** an unauthenticated request hits that route **Then** the request is allowed through without JWT validation

## Tasks / Subtasks

- [ ] Task 1: Create kernel schema in Prisma & migrate Tenant model (AC: #1, #2)
  - [ ] 1.1 Update `schema.prisma`: change `schemas = ["public"]` to `schemas = ["kernel", "public"]` (keep public for now — other models stay until their epics)
  - [ ] 1.2 Add new fields to Tenant model: `currency` (String, default "XOF"), `timezone` (String, default "Africa/Abidjan"), `fiscalJurisdiction` (String?, mapped `fiscal_jurisdiction`), `status` (String, default "active")
  - [ ] 1.3 Change Tenant `@@schema("public")` to `@@schema("kernel")`
  - [ ] 1.4 Change OrganizationMember `@@schema("public")` to `@@schema("kernel")`
  - [ ] 1.5 Run `npx prisma migrate dev --name kernel-schema-tenant-auth` — Prisma will generate SQL to create `kernel` schema and move/alter tables
  - [ ] 1.6 Verify migration preserves existing tenant data (3 existing clients) with new fields defaulted
  - [ ] 1.7 Keep all other models (Product, Order, Category, etc.) in `@@schema("public")` — they move in their respective epics

- [ ] Task 2: Create kernel directory structure & extract Auth module (AC: #3, #7)
  - [ ] 2.1 Create directory: `src/kernel/`
  - [ ] 2.2 Create `src/kernel/auth/` directory
  - [ ] 2.3 Move `src/core/guards/auth/auth.guard.ts` → `src/kernel/auth/auth.guard.ts`
  - [ ] 2.4 Create `src/kernel/auth/auth.decorator.ts` with `@CurrentUser()` param decorator (extracts `req.user`) and `@Public()` metadata decorator (uses `SetMetadata('isPublic', true)`)
  - [ ] 2.5 Update `AuthGuard` to check for `@Public()` metadata via `Reflector` — skip JWT validation if present
  - [ ] 2.6 Create `src/kernel/auth/auth.module.ts` — provides & exports `AuthGuard`, `SupabaseService`

- [ ] Task 3: Extract & enhance Tenancy module (AC: #4, #5)
  - [ ] 3.1 Create `src/kernel/tenancy/` directory
  - [ ] 3.2 Move `src/core/guards/tenant/tenant.guard.ts` → `src/kernel/tenancy/tenant.guard.ts`
  - [ ] 3.3 Create `src/kernel/tenancy/tenant.decorator.ts` with `@CurrentTenant()` param decorator (extracts `req.tenantId`)
  - [ ] 3.4 Consolidate `src/tenants/tenants.service.ts` into `src/kernel/tenancy/tenancy.service.ts` — keep `validateTenantAccess()` and `getTenantConfig()`, add tenant CRUD (create with defaults, update config)
  - [ ] 3.5 Create `src/kernel/tenancy/tenancy.module.ts` — provides & exports `TenantGuard`, `TenancyService`

- [ ] Task 4: Create Prisma middleware for RLS (AC: #4)
  - [ ] 4.1 Create `src/prisma/prisma.middleware.ts` — intercepts all queries, executes `SET LOCAL app.current_tenant_id = '<uuid>'` using the tenant context from TenantGuard
  - [ ] 4.2 Integrate middleware into `PrismaService` — apply on every request transaction
  - [ ] 4.3 Create SQL migration for RLS policies on `tenants` and `organization_members` tables in kernel schema:
    ```sql
    ALTER TABLE kernel.tenants ENABLE ROW LEVEL SECURITY;
    CREATE POLICY tenant_isolation ON kernel.tenants
      FOR ALL USING (id = current_setting('app.current_tenant_id')::uuid);
    ```

- [ ] Task 5: Create session timeout handling (AC: #6)
  - [ ] 5.1 Add `sessionTimeoutMinutes` field to Tenant model (Int, default 480 = 8 hours)
  - [ ] 5.2 In `AuthGuard`, after JWT validation, check token `iat` (issued at) against current time and tenant's configured timeout
  - [ ] 5.3 If expired, return 401 with message "Session expired. Please re-authenticate."

- [ ] Task 6: Create KernelModule & wire into AppModule (AC: #3, #4, #5, #7)
  - [ ] 6.1 Create `src/kernel/kernel.module.ts` — imports AuthModule, TenancyModule; exports all guards and decorators
  - [ ] 6.2 Apply `AuthGuard` and `TenantGuard` globally via `APP_GUARD` providers
  - [ ] 6.3 Update `src/app.module.ts`: replace `CoreModule` import with `KernelModule`; keep existing modules (OrganizationModule, PosModule, etc.) — they still work because guards are backward-compatible
  - [ ] 6.4 Update `OrganizationModule` imports to use kernel services instead of old core services

- [ ] Task 7: Backward compatibility for 3 existing clients (AC: all)
  - [ ] 7.1 Verify all existing POS endpoints (`/pos/*`) continue working with same request/response shapes
  - [ ] 7.2 Update `OrganizationController` to use new `TenancyService`
  - [ ] 7.3 Mark health check endpoint (`AppController`) with `@Public()` so it doesn't require auth
  - [ ] 7.4 Ensure `SupabaseService` is still accessible (re-exported from kernel)

- [ ] Task 8: Tests (AC: all)
  - [ ] 8.1 Unit test: `AuthGuard` — valid JWT passes, invalid JWT returns 401, `@Public()` bypasses
  - [ ] 8.2 Unit test: `TenantGuard` — valid tenant passes, non-member returns 403, missing header returns 400
  - [ ] 8.3 Unit test: `TenancyService` — `validateTenantAccess()`, `getTenantConfig()`, CRUD operations
  - [ ] 8.4 Unit test: session timeout logic
  - [ ] 8.5 Integration test: create tenant with defaults, verify currency=XOF, timezone=Africa/Abidjan, status=active
  - [ ] 8.6 Integration test: tenant isolation — create data in tenant A, query as tenant B, verify zero results

## Dev Notes

### Architecture Compliance

- **Target structure**: `src/kernel/` with subdirectories `auth/`, `tenancy/` — do NOT create `rbac/`, `events/`, or `modules/` yet (those are Stories 1.2, 1.3, 1.4)
- **Schema strategy**: Only move `Tenant` and `OrganizationMember` to `kernel` schema. All other models stay in `public` schema until their respective epics
- **Guard chain**: This story implements AuthGuard → TenantGuard only. ModuleGuard and RolesGuard come in Stories 1.2 and 1.3
- **Prisma multi-schema**: Already enabled (`previewFeatures: ["driverAdapters", "multiSchema"]`). Just need to add `"kernel"` to the `schemas` array

### Existing Code to Refactor (DO NOT Rewrite)

- `src/core/guards/auth/auth.guard.ts` → Move to `src/kernel/auth/auth.guard.ts`, enhance with `@Public()` check
- `src/core/guards/tenant/tenant.guard.ts` → Move to `src/kernel/tenancy/tenant.guard.ts`
- `src/core/services/supabase/supabase.service.ts` → Move to `src/kernel/auth/supabase.service.ts`
- `src/core/core.module.ts` → Replace with `src/kernel/kernel.module.ts`
- `src/tenants/tenants.service.ts` → Consolidate into `src/kernel/tenancy/tenancy.service.ts`
- `src/tenants/tenants.module.ts` → Absorbed into `src/kernel/tenancy/tenancy.module.ts`

### Critical Constraints

- **3 existing clients are live** — zero breaking changes to existing API contracts
- **Prisma migration must be reversible** — test migration on a copy first
- **RLS requires `SET LOCAL`** — must be done per-request in a transaction context. Use Prisma `$executeRaw` in middleware
- **OrganizationMember.role stays as String** for now — FK conversion happens in Story 1.2 (RBAC)
- **Do NOT remove the old `src/core/` directory yet** — clean it up only after verifying all imports are updated. Delete empty directories at the end.
- **Do NOT add RBAC tables (roles, permissions, role_permissions)** — that's Story 1.2
- **Do NOT add audit_log table** — that's Story 1.4
- **Do NOT add modules/tenant_modules tables** — that's Story 1.3

### Project Structure Notes

Current structure:
```
src/
├── core/           ← REFACTOR: Extract to kernel/
│   ├── guards/auth/
│   ├── guards/tenant/
│   └── services/supabase/
├── tenants/        ← REFACTOR: Merge into kernel/tenancy/
├── organization/   ← UPDATE: Use kernel imports
├── pos/            ← NO CHANGES (keep working)
├── prisma/         ← ADD: prisma.middleware.ts for RLS
└── app.module.ts   ← UPDATE: Import KernelModule instead of CoreModule
```

Target structure after this story:
```
src/
├── kernel/
│   ├── kernel.module.ts
│   ├── auth/
│   │   ├── auth.guard.ts
│   │   ├── auth.decorator.ts   (@CurrentUser, @Public)
│   │   ├── supabase.service.ts
│   │   └── auth.module.ts
│   └── tenancy/
│       ├── tenant.guard.ts
│       ├── tenant.decorator.ts (@CurrentTenant)
│       ├── tenancy.service.ts
│       └── tenancy.module.ts
├── organization/   ← Updated imports
├── pos/            ← Unchanged
├── prisma/
│   ├── prisma.module.ts
│   ├── prisma.service.ts
│   └── prisma.middleware.ts   ← NEW (RLS)
└── app.module.ts   ← KernelModule replaces CoreModule
```

### Library & Framework Requirements

| Library | Version | Purpose |
|:---|:---|:---|
| NestJS | 11.0.1 | Framework — use `@nestjs/common` for guards, decorators, modules |
| Prisma | 5.22.0 | ORM — multi-schema, `$executeRawUnsafe` for `SET LOCAL` |
| @supabase/supabase-js | 2.94.1 | Auth token validation via `supabase.auth.getUser(token)` |
| @nestjs/core | 11.x | `Reflector` for metadata-based guard logic |

### Testing Standards

- **Framework**: Jest (already configured)
- **Unit tests**: Mock PrismaService, mock SupabaseService. Use `Test.createTestingModule()` for NestJS testing
- **Integration tests**: Use test database with kernel schema. Create two tenants, verify isolation
- **Naming**: `*.spec.ts` for unit tests, `*.e2e-spec.ts` for integration
- **Coverage target**: 80% for guards and services

### Key Patterns

**NestJS Custom Decorator Pattern:**
```typescript
// @CurrentUser() - Parameter decorator
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);

// @Public() - Metadata decorator
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
```

**Prisma RLS Middleware Pattern:**
```typescript
// In PrismaService or middleware
async setTenantContext(tenantId: string) {
  await this.prisma.$executeRawUnsafe(
    `SET LOCAL app.current_tenant_id = '${tenantId}'`
  );
}
```
**SECURITY WARNING**: Use parameterized queries to prevent SQL injection. Use `$executeRaw` with template literals (tagged template), NOT `$executeRawUnsafe` with string concatenation:
```typescript
await this.prisma.$executeRaw`SET LOCAL app.current_tenant_id = ${tenantId}::uuid`;
```

**Global Guard Registration:**
```typescript
// In kernel.module.ts
providers: [
  { provide: APP_GUARD, useClass: AuthGuard },
  { provide: APP_GUARD, useClass: TenantGuard },
],
```

### References

- [Architecture: Kernel Auth Module](docs/architecture-scalario-2026-03-08.md#411-auth-module)
- [Architecture: Tenancy Module](docs/architecture-scalario-2026-03-08.md#412-tenancy-module)
- [Architecture: Prisma Target Schema](docs/architecture-scalario-2026-03-08.md#52-prisma-schema-target-state)
- [Architecture: RLS Policies](docs/architecture-scalario-2026-03-08.md#57-rls-policies)
- [Architecture: Target Project Structure](docs/architecture-scalario-2026-03-08.md#111-project-structure-target)
- [Architecture: Guard Chain](docs/architecture-scalario-2026-03-08.md#63-guard-chain)
- [PRD: FR1-FR6](/_bmad-output/planning-artifacts/prd.md#functional-requirements)
- [Epics: Story 1.1](/_bmad-output/planning-artifacts/epics.md#story-11)
- Current Prisma schema: `apps/backend/prisma/schema.prisma`
- Current AuthGuard: `apps/backend/src/core/guards/auth/auth.guard.ts`
- Current TenantGuard: `apps/backend/src/core/guards/tenant/tenant.guard.ts`
- Current TenantsService: `apps/backend/src/tenants/tenants.service.ts`

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
