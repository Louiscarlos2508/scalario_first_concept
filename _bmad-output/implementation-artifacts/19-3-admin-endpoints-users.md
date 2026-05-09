# Story 19.3 — Backend : Gestion Users par Tenant

## Metadata

- **Epic:** Epic 19 — Admin Backoffice — Gestion Plateforme
- **Story ID:** 19-3-admin-endpoints-users
- **Status:** review
- **Priority:** Medium
- **Depends on:** 19-1 (AdminModule + SuperAdminGuard + SupabaseAdminService créés)

---

## Story

**As a** superadmin,
**I want** endpoints to create, list, update, and deactivate users within a tenant,
**So that** I can manage client team members without Supabase dashboard access.

---

## Context

Les users sont stockés dans deux endroits :
1. **Supabase Auth** — email, password, `lastSignInAt`, `bannedUntil`
2. **`kernel.organization_members`** — lien `userId ↔ tenantId ↔ roleId`

La désactivation ne supprime pas le user Supabase (préserve l'audit trail) — elle le banne et supprime l'`OrganizationMember`.

### Modèles Prisma impliqués

- `kernel.OrganizationMember` — `organizationId`, `userId`, `roleId`
- `kernel.Role` — `id`, `name`, `vertical`

### SupabaseAdminService (créé en 19-1)

Méthodes à utiliser :
- `createUser(email, password)` → `{ userId }`
- `getUserById(userId)` → `{ email, lastSignInAt }`
- `disableUser(userId)` → bannissement (`banned_until = '2099-01-01'`)

---

## Acceptance Criteria

### AC1 — POST /admin/tenants/:tenantId/users

Body : `{ email: string, password: string, role: 'owner' | 'manager' | 'cashier' }`

1. Valider `role` dans `['owner', 'manager', 'cashier']` — sinon 400
2. `supabase.auth.admin.createUser({ email, password })` → obtenir `userId`
3. Récupérer `Role` par `name = role` et `vertical = 'retail'`
4. `prisma.organizationMember.create({ organizationId: tenantId, userId, roleId })`
5. Réponse 201 :
   ```json
   { "userId": "uuid", "email": "user@example.com", "role": "manager", "createdAt": "ISO8601" }
   ```

Si l'email existe déjà dans Supabase Auth → 422 `{ error: 'EMAIL_ALREADY_EXISTS' }`

### AC2 — GET /admin/tenants/:tenantId/users

Retourne tous les membres de ce tenant avec leurs infos Supabase :

```json
[
  {
    "userId": "uuid",
    "email": "owner@boutique.com",
    "role": "owner",
    "createdAt": "ISO8601",
    "lastSignInAt": "ISO8601 or null"
  }
]
```

Logique : `prisma.organizationMember.findMany({ where: { organizationId: tenantId }, include: { role: true } })`
puis enrichir chaque entrée avec `supabase.auth.admin.getUserById(userId)` pour `email` et `lastSignInAt`.

Note : N+1 acceptable pour le MVP (faible volume). Batch via `Promise.all()`.

### AC3 — PATCH /admin/tenants/:tenantId/users/:userId

Body : `{ role: 'owner' | 'manager' | 'cashier' }`

1. Vérifier que l'`OrganizationMember` existe pour ce `(tenantId, userId)` — sinon 404
2. Récupérer le nouveau `Role` par `name = role` et `vertical = 'retail'`
3. `prisma.organizationMember.update({ where: { organizationId_userId: { organizationId: tenantId, userId } }, data: { roleId } })`
4. Réponse 200 : membre mis à jour avec `role` nouveau

### AC4 — DELETE /admin/tenants/:tenantId/users/:userId

1. Vérifier que l'`OrganizationMember` existe — sinon 404
2. Vérifier qu'il ne s'agit pas du **dernier owner** du tenant :
   - Compter les membres avec `role.name = 'owner'` dans ce tenant
   - Si count == 1 ET ce membre est owner → 422 `{ error: 'CANNOT_REMOVE_LAST_OWNER' }`
3. `prisma.organizationMember.delete({ where: { organizationId_userId: { organizationId: tenantId, userId } } })`
4. `supabase.auth.admin.updateUserById(userId, { ban_duration: 'none', banned_until: '2099-01-01T00:00:00Z' })` — bannissement long
5. Réponse 204 No Content

### AC5 — Tests NestJS

- `POST` email existant → 422 EMAIL_ALREADY_EXISTS
- `POST` rôle invalide → 400
- `POST` valide → 201, orgMember créé
- `GET` → liste avec `email` et `lastSignInAt` enrichis
- `PATCH` user inexistant → 404
- `PATCH` valide → 200, rôle mis à jour
- `DELETE` dernier owner → 422 CANNOT_REMOVE_LAST_OWNER
- `DELETE` valide → 204, orgMember supprimé + Supabase user banni

---

## Tasks/Subtasks

- [x] **Task 1 : AdminUsersController**
  - [x] Créer `apps/backend/src/admin/users/admin-users.controller.ts`
  - [x] Routes : `POST`, `GET`, `PATCH /:userId`, `DELETE /:userId` sous `/admin/tenants/:tenantId/users`

- [x] **Task 2 : AdminUsersService**
  - [x] Créer `apps/backend/src/admin/users/admin-users.service.ts`
  - [x] `createUser(tenantId, dto)` — Supabase + orgMember
  - [x] `listUsers(tenantId)` — orgMembers + enrichissement Supabase
  - [x] `updateUserRole(tenantId, userId, role)` — mise à jour roleId
  - [x] `removeUser(tenantId, userId)` — suppression orgMember + bannissement Supabase

- [x] **Task 3 : DTOs**
  - [x] `CreateTenantUserDto` — inline interface, validation manuelle dans service (pas de class-validator)
  - [x] `UpdateTenantUserRoleDto` — inline interface

- [x] **Task 4 : Tests**
  - [x] 12 tests unitaires `AdminUsersService` (createUser, listUsers, updateUserRole, removeUser)
  - [x] Note: tests e2e non créés — couverture unitaire complète des 4 méthodes de service

---

## Dev Notes

- `SupabaseAdminService` doit avoir `supabaseAdmin = createClient(url, SERVICE_ROLE_KEY)` — pas le client anon
- Pour GET, `Promise.all(members.map(m => supabaseAdmin.auth.admin.getUserById(m.userId)))` — batch parallèle
- Le bannissement Supabase avec `banned_until` très loin empêche le login sans supprimer le compte ni les données audit
- Contrainte unique Prisma : `@@unique([organizationId, userId])` dans `OrganizationMember` — gérer `PrismaClientKnownRequestError` code `P2002` pour les duplicates
- `cashier` role ajouté au seed (même permissions que `commercial` — rôle POS caissier)

---

## Dev Agent Record

### Implementation Plan

- `AdminUsersController` utilise `@Controller('admin/tenants/:tenantId/users')` — routes POST/GET/PATCH/:userId/DELETE/:userId
- `createUser` : validation manuelle du rôle, createUser Supabase, findUnique Role (retail), create OrganizationMember — compensation deleteUser si Prisma échoue
- `listUsers` : findMany orgMembers, Promise.all pour enrichir avec getUserById Supabase
- `updateUserRole` : findUnique member (404 si absent), findUnique new role, update orgMember
- `removeUser` : findUnique member (404 si absent), count owners (422 si dernier), delete orgMember, banUser Supabase

### Completion Notes

- ✅ 12 nouveaux tests, tous verts
- ✅ 340/340 tests totaux — zero regressions
- ✅ `createUser` : 4 tests (400 invalid role, 422 email exists, 201 success, P2002 rollback)
- ✅ `listUsers` : 1 test (enrichissement Supabase)
- ✅ `updateUserRole` : 3 tests (404, 400 invalid role, 200 success)
- ✅ `removeUser` : 4 tests (404, 422 last owner, 204 success, allow remove non-last owner)
- ✅ `cashier` role ajouté à `prisma/seed.ts`

---

## File List

### New Files

- `apps/backend/src/admin/users/admin-users.controller.ts`
- `apps/backend/src/admin/users/admin-users.service.ts`
- `apps/backend/src/admin/users/admin-users.service.spec.ts`

### Modified Files

- `apps/backend/src/admin/admin.module.ts` — ajout `AdminUsersController` + `AdminUsersService`
- `apps/backend/prisma/seed.ts` — ajout rôle `cashier` (vertical: retail)

---

## Change Log

- 2026-03-17 — Story 19-3 implémentée : AdminUsersController + AdminUsersService (createUser, listUsers, updateUserRole, removeUser). 12 nouveaux tests, 340/340 total.
