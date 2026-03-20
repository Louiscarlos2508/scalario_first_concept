# Story 28.3 — Backend BillingEvent model + endpoints + cron suspension auto (FR101)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-3-billing-events-backend
- **Status:** backlog
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 28-2 (champs billing sur Tenant), Epic 1 (kernel schema)

---

## Story

**As a** superadmin,
**I want** a `BillingEvent` ledger with REST endpoints to record and query payments, automatic billing status transitions, and a daily cron job that suspends overdue tenants,
**So that** billing is tracked exhaustively and suspended tenants are blocked automatically (FR101).

---

## Acceptance Criteria

### AC1 — Migration Prisma BillingEvent

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `BillingEvent`
**When** la migration est appliquée
**Then** la table `billing_events` existe dans le schéma `kernel` avec les colonnes : `id` (uuid), `tenant_id` (FK tenants.id), `type`, `amount` (Decimal 10,0), `description` (nullable), `paid_at` (nullable), `due_date` (nullable), `status` (default "pending"), `payment_method` (nullable), `payment_ref` (nullable), `created_at`
**And** l'index `(tenant_id, status)` est présent
**And** `@@map("billing_events")` et `@@schema("kernel")` sont appliqués

### AC2 — POST /admin/tenants/:id/billing/events — enregistrement événement

**Given** un superadmin envoie `POST /api/v1/admin/tenants/:id/billing/events` avec `{ type, amount, description?, paidAt?, dueDate?, paymentMethod?, paymentRef? }`
**When** le tenant existe
**Then** un `BillingEvent` est créé et retourné en `201 Created`

**When** `type = "subscription"` et `paidAt` est fourni dans la requête
**Then** `tenant.billingStatus` passe automatiquement à `"active"`
**And** `tenant.billingStartDate` est défini si actuellement null (= `paidAt`)

### AC3 — GET /admin/tenants/:id/billing — tableau de bord facturation

**Given** un superadmin appelle `GET /api/v1/admin/tenants/:id/billing`
**When** le tenant existe
**Then** la réponse est `200 OK` avec :
```json
{
  "tenant": {
    "plan": "standard",
    "billingStatus": "active",
    "trialEndsAt": null,
    "billingStartDate": "2026-03-01T00:00:00Z",
    "installationFee": 25000,
    "installationPaid": true,
    "trainingFee": 10000,
    "trainingPaid": false,
    "notes": "early adopter, remise 20%"
  },
  "events": [ /* BillingEvent[] tri createdAt DESC */ ]
}
```

### AC4 — PATCH /admin/tenants/:id/billing — mise à jour frais/notes/status

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/billing` avec `{ installationFee?, installationPaid?, trainingFee?, trainingPaid?, notes?, billingStatus? }`
**When** le tenant existe
**Then** les champs sont mis à jour sur le `Tenant` et la réponse est `200 OK` avec le tenant mis à jour
**And** si `billingStatus` est mis à `"active"`, un `BillingEvent` de type `"payment"` avec `description: "Activation manuelle par superadmin"` est créé automatiquement

### AC5 — Cron job : transition trial → overdue

**Given** le cron job tourne chaque jour à 02:00 UTC
**When** un tenant a `billingStatus = "trial"` et `trialEndsAt < now()`
**Then** `tenant.billingStatus` passe à `"overdue"`

### AC6 — Cron job : suspension automatique overdue

**Given** le cron job tourne
**When** un tenant a `billingStatus = "overdue"` depuis plus de `BILLING_SUSPENSION_DAYS` jours (default 30, configurable via env)
**Then** `tenant.billingStatus` passe à `"suspended"`
**And** un `BillingEvent` est créé : `{ type: "payment", status: "overdue", description: "Suspension automatique — impayé > 30j" }`

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma BillingEvent** (AC1)
  - [ ] Ajouter le modèle `BillingEvent` dans `schema.prisma` (schéma `kernel`)
  - [ ] Ajouter la relation `tenant Tenant @relation(...)` sur `BillingEvent`
  - [ ] Vérifier que la relation `billingEvents BillingEvent[]` sur `Tenant` (ajoutée en 28-2) compile
  - [ ] Générer la migration : `npx prisma migrate dev --name add_billing_events`

- [ ] **Task 2 — BillingService partagé** (AC2–AC4)
  - [ ] Créer `apps/backend/src/kernel/billing/billing-events/billing-events.service.ts`
    - `recordEvent(tenantId, dto)` → crée `BillingEvent` + side-effects sur `Tenant` (billingStatus, billingStartDate)
    - `getHistory(tenantId)` → retourne `{ tenant, events }` pour l'endpoint GET
    - `updateBilling(tenantId, dto)` → patch tenant + crée BillingEvent "payment" si activation
  - [ ] Exposer `recordEvent()` comme méthode `public` — utilisée par `TenantPlanService` (28-2) et `BillingSchedulerService`

- [ ] **Task 3 — BillingEventsController** (AC2–AC4)
  - [ ] Créer `apps/backend/src/kernel/billing/billing-events/billing-events.controller.ts`
    - `POST /admin/tenants/:id/billing/events` — `@UseGuards(SuperadminGuard)`
    - `GET /admin/tenants/:id/billing` — `@UseGuards(SuperadminGuard)`
    - `PATCH /admin/tenants/:id/billing` — `@UseGuards(SuperadminGuard)`
  - [ ] Créer `dto/create-billing-event.dto.ts` et `dto/update-billing.dto.ts`

- [ ] **Task 4 — BillingSchedulerService + cron** (AC5, AC6)
  - [ ] Créer `apps/backend/src/kernel/billing/billing-events/billing-scheduler.service.ts`
    - `@Cron('0 2 * * *')` (02:00 UTC quotidien)
    - `checkTrialExpiry()` → `billingStatus = "trial"` + `trialEndsAt < now()` → `"overdue"`
    - `checkOverdueSuspension()` → `billingStatus = "overdue"` + date dépassée `BILLING_SUSPENSION_DAYS` → `"suspended"` + BillingEvent
  - [ ] Lire `BILLING_SUSPENSION_DAYS` via `ConfigService` (default 30)
  - [ ] Vérifier `ScheduleModule.forRoot()` dans `AppModule` — ajouter si absent

- [ ] **Task 5 — Enregistrer dans BillingModule** (toutes AC)
  - [ ] Déclarer `BillingEventsService`, `BillingEventsController`, `BillingSchedulerService` dans `BillingModule`
  - [ ] Exporter `BillingEventsService` (utilisé par `TenantPlanService` en 28-2 via refacto TODO)
  - [ ] Importer `ScheduleModule` dans `BillingModule` ou `AppModule`

- [ ] **Task 6 — Tests** (AC2–AC6)
  - [ ] Test : `POST billing/events` type=subscription avec paidAt → billingStatus = "active"
  - [ ] Test : `GET billing` → structure { tenant, events }
  - [ ] Test : `PATCH billing` billingStatus="active" → BillingEvent "payment" créé
  - [ ] Test cron : tenant trial + trialEndsAt passé → overdue
  - [ ] Test cron : tenant overdue > 30j → suspended + BillingEvent créé

---

## Files to Create

- `apps/backend/prisma/migrations/20260320020000_add_billing_events/migration.sql`
- `apps/backend/src/kernel/billing/billing-events/billing-events.controller.ts`
- `apps/backend/src/kernel/billing/billing-events/billing-events.service.ts`
- `apps/backend/src/kernel/billing/billing-events/billing-scheduler.service.ts`
- `apps/backend/src/kernel/billing/billing-events/dto/create-billing-event.dto.ts`
- `apps/backend/src/kernel/billing/billing-events/dto/update-billing.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `BillingEvent` (kernel)
- `apps/backend/src/kernel/billing/billing.module.ts` — déclarer scheduler + importer ScheduleModule
- `apps/backend/src/app.module.ts` — `ScheduleModule.forRoot()` si absent

---

## Dev Notes

### @nestjs/schedule

```bash
npm install @nestjs/schedule
```

Importer dans `AppModule` :
```typescript
import { ScheduleModule } from '@nestjs/schedule';
// dans imports:
ScheduleModule.forRoot()
```

### Calcul date suspension

```typescript
const suspensionThreshold = parseInt(process.env.BILLING_SUSPENSION_DAYS ?? '30');
const cutoff = new Date(Date.now() - suspensionThreshold * 24 * 60 * 60 * 1000);
// tenants avec billingStatus=overdue ET updatedAt < cutoff
```

Le champ `updatedAt` doit exister sur `Tenant` ou utiliser un champ dédié `overdueAt`. Si absent, ajouter `overdueAt DateTime?` dans la migration 28-2 ou ici.

### Type BillingEvent

Valeurs autorisées pour `type` : `subscription`, `installation`, `training`, `upgrade`, `downgrade`, `payment`
Valeurs autorisées pour `status` : `pending`, `paid`, `overdue`, `cancelled`
Valeurs autorisées pour `paymentMethod` : `cash`, `mobile_money`, `card`, `bank_transfer`

### References

- [Source: docs/architecture-scalario-2026-03-08.md v1.4 — BillingEvent model]
- [Source: _bmad-output/planning-artifacts/prd.md — FR101]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-3]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
