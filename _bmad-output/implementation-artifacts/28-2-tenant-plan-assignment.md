# Story 28.2 — Backend PATCH /admin/tenants/:id/plan + activation modules auto (FR100)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-2-tenant-plan-assignment
- **Status:** backlog
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 28-1 (PlanDefinition + BillingModule), Epic 1 (ModuleRegistry), Epic 19 (admin tenant endpoints)

---

## Story

**As a** superadmin,
**I want** a `PATCH /admin/tenants/:id/plan` endpoint that changes a tenant's plan, auto-applies module activation, validates user limits, and records a billing event,
**So that** plan changes are fully automated without manual module toggling (FR100).

---

## Acceptance Criteria

### AC1 — Champs billing sur Tenant (migration)

**Given** le fichier `schema.prisma` est mis à jour
**When** la migration est appliquée
**Then** les colonnes suivantes existent sur la table `tenants` :
- `plan` (String, default "free")
- `max_users` (Int, default 1)
- `installation_fee` (Decimal(10,0) nullable)
- `installation_paid` (Boolean, default false)
- `training_fee` (Decimal(10,0) nullable)
- `training_paid` (Boolean, default false)
- `billing_start_date` (DateTime nullable)
- `billing_status` (String, default "trial")
- `trial_ends_at` (DateTime nullable)
- `notes` (String nullable)

### AC2 — Plan "free" par défaut à la création

**Given** un nouveau tenant est créé via `POST /api/v1/admin/tenants`
**When** aucun `planCode` n'est précisé dans la requête
**Then** `tenant.plan = "free"`, `tenant.maxUsers = 1`, `tenant.billingStatus = "trial"`, `tenant.trialEndsAt = createdAt + 30 jours`

### AC3 — PATCH /admin/tenants/:id/plan — changement de plan simple

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/plan` avec `{ planCode: "standard" }`
**When** le plan cible existe, est actif, et le tenant a ≤ 4 utilisateurs actifs
**Then** `tenant.plan` est mis à jour avec `"standard"`
**And** `tenant.maxUsers` est synchronisé avec `PlanDefinition.maxUsers` (4)
**And** les modules `["catalog","inventory","retail"]` sont activés dans `TenantModule` s'ils ne l'étaient pas
**And** un `BillingEvent` de type `"upgrade"` est créé (price standard > price free)
**And** la réponse est `200 OK` avec le tenant mis à jour

### AC4 — Validation maxUsers avant downgrade

**Given** le nouveau plan a `maxUsers = 1` (free) et le tenant a 3 utilisateurs actifs
**When** le superadmin envoie `PATCH /api/v1/admin/tenants/:id/plan` avec `{ planCode: "free" }`
**Then** la réponse est `403 Forbidden` :
`"Le tenant a 3 utilisateurs actifs, le plan cible en autorise 1. Désactivez des comptes avant de downgrader."`

### AC5 — Confirmation avant downgrade de modules

**Given** le tenant est sur `premium` (modules: [..., "reporting", "purchase_orders"])
**When** le superadmin envoie `PATCH /api/v1/admin/tenants/:id/plan` avec `{ planCode: "standard" }` SANS `confirmDowngrade: true`
**Then** la réponse est `409 Conflict` avec :
`{ modulesToDeactivate: ["reporting", "purchase_orders"], message: "Confirmation requise pour désactiver ces modules" }`

**When** le superadmin renvoie avec `{ planCode: "standard", confirmDowngrade: true }`
**Then** les modules `reporting` et `purchase_orders` sont désactivés dans `TenantModule`
**And** le plan est mis à jour et un `BillingEvent` de type `"downgrade"` est créé

### AC6 — Plan inexistant ou inactif

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/plan` avec `{ planCode: "inexistant" }`
**Then** la réponse est `404 Not Found` : `"Plan introuvable ou inactif"`

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration champs billing sur Tenant** (AC1)
  - [ ] Ajouter les 10 champs billing dans le modèle `Tenant` de `schema.prisma`
  - [ ] Ajouter la relation `billingEvents BillingEvent[]` (utilisée en story 28-3)
  - [ ] Générer la migration : `npx prisma migrate dev --name add_billing_fields_to_tenant`

- [ ] **Task 2 — Valeur par défaut à la création tenant** (AC2)
  - [ ] Dans `OrganizationService.createTenant()` (ou équivalent), ajouter :
    - `plan: "free"`, `maxUsers: 1`, `billingStatus: "trial"`
    - `trialEndsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)`
  - [ ] Vérifier que les migrations ne cassent pas les tenants existants (valeurs par défaut en DB)

- [ ] **Task 3 — TenantPlanService** (AC3–AC6)
  - [ ] Créer `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.service.ts`
    - `assignPlan(tenantId, planCode, confirmDowngrade?)` :
      1. Charger `PlanDefinition` par code → 404 si absent ou inactif
      2. Compter utilisateurs actifs du tenant → 403 si > `plan.maxUsers`
      3. Calculer modules à désactiver → 409 si downgrade sans confirmation
      4. Appliquer `tenant.plan`, `tenant.maxUsers`
      5. Activer/désactiver `TenantModule` via `ModuleRegistryService`
      6. Créer `BillingEvent` (type: upgrade/downgrade selon delta prix) — via `BillingService` (TODO si 28-3 pas encore dispo : `prisma.billingEvent.create(...)` directement)
  - [ ] Créer `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.controller.ts`
    - `PATCH /admin/tenants/:id/plan` — `@UseGuards(SuperadminGuard)`
  - [ ] Créer `apps/backend/src/kernel/billing/tenant-plan/dto/assign-plan.dto.ts`
    - `planCode: string @IsString()`
    - `confirmDowngrade?: boolean @IsOptional() @IsBoolean()`

- [ ] **Task 4 — Enregistrer dans BillingModule** (AC3)
  - [ ] Exporter `TenantPlanService` depuis `BillingModule`
  - [ ] Importer `PrismaModule` et `ModuleRegistryModule` dans `BillingModule`

- [ ] **Task 5 — Tests** (AC2–AC6)
  - [ ] Test : assignation plan simple → 200 + modules activés + BillingEvent créé
  - [ ] Test : downgrade avec maxUsers dépassé → 403
  - [ ] Test : downgrade modules sans confirmDowngrade → 409 + liste modules
  - [ ] Test : downgrade modules avec confirmDowngrade → 200 + modules désactivés
  - [ ] Test : planCode inexistant → 404
  - [ ] Test : création tenant → billingStatus = "trial", trialEndsAt = now + 30j

---

## Files to Create

- `apps/backend/prisma/migrations/20260320010000_add_billing_fields_to_tenant/migration.sql`
- `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.controller.ts`
- `apps/backend/src/kernel/billing/tenant-plan/tenant-plan.service.ts`
- `apps/backend/src/kernel/billing/tenant-plan/dto/assign-plan.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — champs billing + relation `billingEvents` sur `Tenant`
- `apps/backend/src/organization/organization.service.ts` — defaults billing à la création
- `apps/backend/src/kernel/billing/billing.module.ts` — déclarer + exporter `TenantPlanService`

---

## Dev Notes

### ModuleRegistryService

Appeler `ModuleRegistryService.setModuleStatus(tenantId, moduleCode, 'active' | 'inactive')`.
Si la méthode n'existe pas, l'ajouter dans `apps/backend/src/kernel/modules/module-registry.service.ts`.
Pattern existant : `isModuleActive(tenantId, moduleId)` — étendre avec un setter.

### BillingEvent en attente de 28-3

Si `BillingService` n'est pas encore disponible, créer directement via Prisma :
```typescript
await this.prisma.billingEvent.create({
  data: { tenantId, type: isUpgrade ? 'upgrade' : 'downgrade', amount: priceDelta, status: 'paid' }
})
```
Logger un TODO pour refactorer vers `BillingService.recordEvent()` en 28-3.

### Comptage utilisateurs actifs

```typescript
const activeUserCount = await this.prisma.organizationMember.count({
  where: { tenantId, status: 'active' }
})
```
Vérifier le champ `status` sur `OrganizationMember` — peut être `role` uniquement si pas de status.

### References

- [Source: docs/architecture-scalario-2026-03-08.md v1.4 — Tenant billing fields]
- [Source: _bmad-output/planning-artifacts/prd.md — FR100]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-2]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
