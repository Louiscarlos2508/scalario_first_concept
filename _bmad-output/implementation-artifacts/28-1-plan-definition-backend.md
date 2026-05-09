# Story 28.1 — Backend PlanDefinition model, seed 4 plans, endpoints CRUD (FR100)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-1-plan-definition-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a — prérequis de toutes les stories 28-x
- **Depends on:** Epic 1 (kernel schema, SuperadminGuard), Epic 19 (admin endpoints pattern)

---

## Story

**As a** superadmin,
**I want** a `PlanDefinition` model with seed data for the 4 standard plans and full CRUD REST endpoints,
**So that** plans are configurable without deployment and serve as the source of truth for module activation and fee suggestions (FR100).

---

## Acceptance Criteria

### AC1 — Migration Prisma PlanDefinition

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `PlanDefinition`
**When** la migration est appliquée
**Then** la table `plan_definitions` existe dans le schéma `kernel` avec les colonnes : `id` (uuid), `code` (unique), `name`, `monthly_price` (Decimal 10,0), `max_users` (int), `included_modules` (String[]), `suggested_installation_fee` (Decimal nullable), `suggested_training_fee` (Decimal nullable), `is_active` (bool, default true), `created_at`
**And** `@@map("plan_definitions")` et `@@schema("kernel")` sont appliqués

### AC2 — Seed 4 plans

**Given** la commande `prisma db seed` est exécutée
**When** les plans sont absents ou la table est vide
**Then** 4 plans sont créés avec les valeurs suivantes :

| code | name | monthlyPrice | maxUsers | includedModules |
|:---|:---|:---|:---|:---|
| free | Gratuit | 0 | 1 | [] |
| standard | Standard | 15000 | 4 | ["catalog","inventory","retail"] |
| premium | Premium | 30000 | 10 | ["catalog","inventory","retail","reporting","purchase_orders"] |
| enterprise | Enterprise | 50000 | 25 | ["catalog","inventory","retail","reporting","purchase_orders","variants","pricing","promotions"] |

**And** le seed est idempotent — `upsert` par `code`, pas de doublon si réexécuté
**And** `suggestedInstallationFee` et `suggestedTrainingFee` sont `null` pour `free`, respectivement 25 000 et 10 000 FCFA pour `standard`, 50 000 et 20 000 pour `premium`, 100 000 et 50 000 pour `enterprise`

### AC3 — GET /admin/plans — liste des plans

**Given** un superadmin authentifié appelle `GET /api/v1/admin/plans`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste complète des `PlanDefinition` triés par `monthlyPrice` ASC
**And** les plans inactifs (`isActive = false`) sont inclus

**Given** un utilisateur non-superadmin appelle `GET /api/v1/admin/plans`
**Then** la réponse est `403 Forbidden`

### AC4 — POST /admin/plans — création

**Given** un superadmin envoie `POST /api/v1/admin/plans` avec `{ code, name, monthlyPrice, maxUsers, includedModules, suggestedInstallationFee?, suggestedTrainingFee? }`
**When** le `code` n'existe pas encore
**Then** un `PlanDefinition` est créé et retourné en `201 Created`

**When** le `code` existe déjà
**Then** la réponse est `409 Conflict` : `"Un plan avec ce code existe déjà"`

### AC5 — PATCH /admin/plans/:code — mise à jour

**Given** un superadmin envoie `PATCH /api/v1/admin/plans/:code` avec les champs à modifier
**When** le plan existe
**Then** les champs sont mis à jour et le plan est retourné en `200 OK`
**And** les tenants existants sur ce plan ne sont PAS rétroactivement affectés

### AC6 — DELETE /admin/plans/:code — désactivation soft

**Given** un superadmin appelle `DELETE /api/v1/admin/plans/:code`
**When** le plan existe
**Then** `isActive` passe à `false` et la réponse est `200 OK`
**And** les tenants actuellement sur ce plan conservent leur assignation

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma PlanDefinition** (AC1)
  - [ ] Ajouter le modèle `PlanDefinition` dans `schema.prisma` (schéma `kernel`)
  - [ ] Générer la migration SQL : `npx prisma migrate dev --name add_plan_definitions`
  - [ ] Vérifier `@@map("plan_definitions")` et `@@schema("kernel")`

- [ ] **Task 2 — Seed 4 plans** (AC2)
  - [ ] Ajouter la section plans dans `apps/backend/prisma/seed.ts`
  - [ ] Utiliser `prisma.planDefinition.upsert({ where: { code }, ... })` pour chaque plan
  - [ ] Tester : `npx prisma db seed` → 4 lignes dans `plan_definitions`, idempotent

- [ ] **Task 3 — BillingModule + PlanDefinitionService** (AC3–AC6)
  - [ ] Créer `apps/backend/src/kernel/billing/billing.module.ts`
  - [ ] Créer `plan-definition.service.ts` avec :
    - `findAll()` → liste triée par `monthlyPrice`
    - `create(dto)` → vérifie unicité du `code` avant insert
    - `update(code, dto)` → patch partiel
    - `deactivate(code)` → soft delete `isActive = false`
  - [ ] Créer `plan-definition.controller.ts` avec les 4 routes sous `/admin/plans`
  - [ ] Appliquer `SuperadminGuard` sur toutes les routes (vérifier existence ou créer)
  - [ ] Créer `create-plan-definition.dto.ts` et `update-plan-definition.dto.ts`

- [ ] **Task 4 — Enregistrement module** (AC3)
  - [ ] Importer `BillingModule` dans `AppModule`
  - [ ] Vérifier que le préfixe global `/api/v1` est appliqué

- [ ] **Task 5 — Tests** (AC3–AC6)
  - [ ] Test : `GET /admin/plans` → 200 + liste triée (superadmin)
  - [ ] Test : `GET /admin/plans` → 403 (non-superadmin)
  - [ ] Test : `POST /admin/plans` code unique → 201
  - [ ] Test : `POST /admin/plans` code dupliqué → 409
  - [ ] Test : `PATCH /admin/plans/:code` → 200 + champs mis à jour
  - [ ] Test : `DELETE /admin/plans/:code` → 200 + `isActive = false`

---

## Files to Create

- `apps/backend/prisma/migrations/20260320000000_add_plan_definitions/migration.sql`
- `apps/backend/src/kernel/billing/billing.module.ts`
- `apps/backend/src/kernel/billing/plan-definition/plan-definition.controller.ts`
- `apps/backend/src/kernel/billing/plan-definition/plan-definition.service.ts`
- `apps/backend/src/kernel/billing/plan-definition/dto/create-plan-definition.dto.ts`
- `apps/backend/src/kernel/billing/plan-definition/dto/update-plan-definition.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `PlanDefinition` (kernel)
- `apps/backend/prisma/seed.ts` — upsert 4 plans
- `apps/backend/src/app.module.ts` — importer `BillingModule`

---

## Dev Notes

### Architecture Reference

- `PlanDefinition` est défini dans `docs/architecture-scalario-2026-03-08.md` v1.4 (kernel schema)
- Pattern module de référence : `apps/backend/src/organization/` (tenancy kernel module)
- `SuperadminGuard` : vérifier s'il existe dans `apps/backend/src/` — sinon le créer dans `kernel/auth/guards/`

### includedModules Values

Les codes de modules correspondent aux `Module.code` de la table `modules` (kernel). Valeurs valides actuelles (vérifier `apps/backend/prisma/seed.ts` ou la table `modules`) :
`catalog`, `inventory`, `retail`, `reporting`, `purchase_orders`, `variants`, `pricing`, `promotions`, `returns`, `reservations`

### Pas de FK sur includedModules

`includedModules` est un `String[]` sans FK vers la table `modules`. Cela permet une flexibilité totale pour les plans futurs sans migration. La validation métier (code de module valide) est faite au niveau du DTO avec `@IsIn(VALID_MODULE_CODES)`.

### References

- [Source: docs/architecture-scalario-2026-03-08.md v1.4 — PlanDefinition model]
- [Source: _bmad-output/planning-artifacts/prd.md — FR100]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-1]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
