# Story 1: Auth & Organization Foundation

**Goal:** Establish the multi-tenant foundation with Authentication (Supabase) and Organization management (Tenants/Branches).

## Context
Scalario is a multi-tenant ERP. Every user belongs to an Organization (Tenant). We need to secure the application so that users can only access their own tenant's data.

## Requirements

### 1. Authentication (Supabase)
- [ ] Implement Supabase Auth (Email/Password).
- [ ] Create `auth_repository.dart` in `packages/core`.
- [ ] Implement Login Screen in `apps/frontend`.

### 2. Multi-Tenancy (Backend/DB)
- [ ] Verify `tenants` and `organization_members` tables (Schema already exists).
- [ ] Implement RLS policies (already in schema.sql, verify with tests).
- [ ] Create `TenantService` in NestJS backend (`apps/backend`) to fetch current tenant config.

### 3. User Profiles & Roles
- [ ] Create `UserProfile` model in Flutter.
- [ ] Implement role-based routing (Admin -> Dashboard, Cashier -> POS).

## Acceptance Criteria
- User can log in with Email/Password.
- Upon login, app fetches the User's Organization and Role.
- "Cashier" role is redirected to POS screen (placeholder).
- "Admin" role is redirected to Dashboard screen (placeholder).
- Attempting to access another tenant's data throws 403 or returns empty list (RLS).
