# Story 19.2 — Backend : Activation/Désactivation Modules par Tenant

## Metadata

- **Epic:** Epic 19 — Admin Backoffice — Gestion Plateforme
- **Story ID:** 19-2-admin-endpoints-modules
- **Status:** review
- **Priority:** High
- **Depends on:** 19-1 (AdminModule + SuperAdminGuard créés)

---

## Story

**As a** superadmin,
**I want** endpoints to manage which modules are active per tenant,
**So that** I can enable or disable features for a client without touching the database.

---

## Context

Le `Module` registry existe déjà dans `kernel.modules` (catalog, inventory, transactions, retail, etc.).
La relation tenant ↔ module est dans `kernel.tenant_modules` avec `status: 'active' | 'inactive'`.

Le `ModuleRegistryService` expose déjà `isModuleActive()` et `activateDefaultModulesForTenant()`.
Cette story ajoute des endpoints REST d'administration au-dessus de ces services.

### Modules existants dans le seed (à vérifier)

| code          | type     | dependencies                         |
|---------------|----------|--------------------------------------|
| catalog       | shared   | []                                   |
| inventory     | shared   | [catalog]                            |
| transactions  | shared   | []                                   |
| retail        | vertical | [catalog, inventory, transactions]   |

### Modèles Prisma impliqués

- `kernel.Module` — `id`, `code`, `name`, `type`, `dependencies`
- `kernel.TenantModule` — `tenantId`, `moduleId`, `status`, `activatedAt`

---

## Acceptance Criteria

### AC1 — GET /admin/modules

Retourne le catalogue complet des modules disponibles :

```json
[
  {
    "id": "uuid",
    "code": "retail",
    "name": "Retail POS",
    "type": "vertical",
    "dependencies": ["catalog", "inventory", "transactions"]
  }
]
```

Source : `prisma.module.findMany()` — aucun filtre tenant.

### AC2 — GET /admin/tenants/:tenantId/modules

Retourne tous les modules avec leur statut pour ce tenant :

```json
[
  {
    "moduleCode": "catalog",
    "name": "Catalogue",
    "type": "shared",
    "status": "active",
    "activatedAt": "ISO8601"
  },
  {
    "moduleCode": "retail",
    "name": "Retail POS",
    "type": "vertical",
    "status": "inactive",
    "activatedAt": null
  }
]
```

Logique : LEFT JOIN `Module` avec `TenantModule` pour ce tenant.
Si aucun `TenantModule` n'existe pour un module → `status = 'inactive'`, `activatedAt = null`.

### AC3 — POST /admin/tenants/:tenantId/modules/:moduleCode/activate

1. Récupérer le `Module` par `code` — si inexistant → 404
2. Récupérer les dépendances du module (`module.dependencies` — array de codes)
3. Pour chaque dépendance : vérifier que `TenantModule.status = 'active'` pour ce tenant
4. Si une dépendance manque :
   ```json
   { "error": "MISSING_DEPENDENCY", "missing": ["catalog", "inventory"] }
   ```
   → 422
5. Si toutes les dépendances sont satisfaites : upsert `TenantModule` avec `status = 'active'`, `activatedAt = now()`
6. Réponse 200 : `{ moduleCode, status: 'active', activatedAt }`

### AC4 — POST /admin/tenants/:tenantId/modules/:moduleCode/deactivate

1. Récupérer le `Module` par `code` — si inexistant → 404
2. Trouver tous les modules actifs pour ce tenant dont `dependencies` contient ce `moduleCode`
3. Si des dépendants existent :
   ```json
   { "error": "HAS_DEPENDENTS", "dependents": ["retail"] }
   ```
   → 422
4. Si aucun dépendant : upsert `TenantModule` avec `status = 'inactive'`, `activatedAt = null`
5. Réponse 200 : `{ moduleCode, status: 'inactive' }`

### AC5 — Seed automatique à la création d'un tenant retail (lien 19-1)

Confirmation : `ModuleRegistryService.activateDefaultModulesForTenant()` active les modules
`catalog`, `inventory`, `transactions`, `retail` dans cet ordre (les dépendances avant les verticaux).

### AC6 — Tests NestJS

- `GET /admin/modules` → liste complète, sans filtre tenant
- `GET /admin/tenants/:id/modules` → LEFT JOIN correct, modules inactifs avec `status: 'inactive'`
- Activate avec dépendances manquantes → 422 MISSING_DEPENDENCY
- Activate avec dépendances présentes → 200, TenantModule status = active
- Deactivate avec dépendant actif → 422 HAS_DEPENDENTS
- Deactivate sans dépendant → 200, status = inactive

---

## Tasks/Subtasks

- [x] **Task 1 : AdminModulesController**
  - [x] Créer `apps/backend/src/admin/modules/admin-modules.controller.ts`
  - [x] Endpoints : `GET /admin/modules`, `GET /admin/tenants/:tenantId/modules`
  - [x] Endpoints : `POST /admin/tenants/:tenantId/modules/:moduleCode/activate`
  - [x] Endpoints : `POST /admin/tenants/:tenantId/modules/:moduleCode/deactivate`

- [x] **Task 2 : AdminModulesService**
  - [x] Créer `apps/backend/src/admin/modules/admin-modules.service.ts`
  - [x] `listModules()` — catalogue complet
  - [x] `listTenantModules(tenantId)` — LEFT JOIN avec statut
  - [x] `activateModule(tenantId, moduleCode)` — validation dépendances + upsert
  - [x] `deactivateModule(tenantId, moduleCode)` — validation dépendants + upsert

- [x] **Task 3 : Tests**
  - [x] Tests unitaires `AdminModulesService` — 11 tests (listModules, listTenantModules LEFT JOIN, activate happy/sad paths, deactivate happy/sad paths)
  - [x] Note: tests e2e non créés — couverture unitaire complète des 4 méthodes de service

---

## Dev Notes

- `module.dependencies` est un `String[]` dans Prisma — array de codes (ex: `['catalog', 'inventory']`)
- Pour la vérification des dépendants (deactivate) : `prisma.module.findMany({ where: { tenants: { some: { tenantId, status: 'active' } } } })` puis filtrer ceux dont `dependencies.includes(moduleCode)`
- Ne pas modifier `ModuleRegistryService` — l'étendre ou créer `AdminModulesService` séparé
- Le `SuperAdminGuard` de la story 19-1 s'applique via `AdminModule` — ne pas le recréer

---

## Dev Agent Record

### Implementation Plan

- `AdminModulesController` utilise `@Controller('admin')` avec des routes différenciées (pas de conflit avec `AdminTenantsController` qui préfixe `/admin/tenants`)
- `listTenantModules()` : LEFT JOIN en TypeScript — `Promise.all([module.findMany, tenantModule.findMany])` + Map lookup par moduleId
- `activateModule()` : query `tenantModule.findMany({ where: { tenantId, status: 'active' } })` pour vérifier les dépendances — filtre nativement les inactives
- `deactivateModule()` : même query active-only + filter `module.dependencies.includes(moduleCode)` pour trouver les dépendants bloquants
- Deux controllers dans `AdminModule` : `AdminTenantsController` + `AdminModulesController` — pas de conflit de routes NestJS

### Completion Notes

- ✅ 11 nouveaux tests, tous verts
- ✅ 328/328 tests totaux — zero regressions
- ✅ `listModules` : 1 test
- ✅ `listTenantModules` : 2 tests (LEFT JOIN avec actifs/inactifs, tenant sans modules)
- ✅ `activateModule` : 4 tests (404, no-deps success, MISSING_DEPENDENCY, all-deps success)
- ✅ `deactivateModule` : 4 tests (404, HAS_DEPENDENTS, success, inactive-dependents = OK)

---

## File List

### New Files

- `apps/backend/src/admin/modules/admin-modules.controller.ts`
- `apps/backend/src/admin/modules/admin-modules.service.ts`
- `apps/backend/src/admin/modules/admin-modules.service.spec.ts`

### Modified Files

- `apps/backend/src/admin/admin.module.ts` — ajout `AdminModulesController` + `AdminModulesService`

---

## Change Log

- 2026-03-17 — Story 19-2 implémentée : AdminModulesController + AdminModulesService (listModules, listTenantModules LEFT JOIN, activate avec validation dépendances, deactivate avec validation dépendants). 11 nouveaux tests, 328/328 total.
