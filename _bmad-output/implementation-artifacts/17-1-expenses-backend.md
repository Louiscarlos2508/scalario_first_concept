# Story 17.1 — Backend : Modèle Expense + endpoints CRUD

## Metadata
- **Epic:** Epic 17 — Dépenses & Bénéfice
- **Story ID:** 17-1-expenses-backend
- **Status:** review
- **Priority:** High
- **Depends on:** Epics 1–9 (backend retail opérationnel)

---

## Story

**As a** manager/owner,
**I want** to record and retrieve expense entries via the API,
**So that** the frontend can display them and compute net profit.

---

## Acceptance Criteria

1. **Prisma schema** (`retail` schema) — nouveau modèle `Expense` :
   - `id` UUID PK
   - `tenantId` UUID FK → `tenants.id`
   - `userId` UUID (qui a saisi)
   - `label` String (obligatoire)
   - `amount` Decimal(10,2) (obligatoire)
   - `category` String — valeurs : `LOYER | SALAIRE | ELECTRICITE | AUTRE`
   - `date` Date
   - `notes` String?
   - `isDeleted` Boolean default false (soft delete)
   - `createdAt` Timestamptz
   - `updatedAt` Timestamptz
   - Index : `[tenantId, date]`

2. **`POST /retail/expenses`** :
   - Body : `{ label, amount, category, date, tenantId, notes? }`
   - Rôles : `owner`, `manager`
   - Retourne 201 + expense créé

3. **`GET /retail/expenses?tenantId=&from=&to=`** :
   - Rôles : `owner`, `manager`
   - Filtre `date >= from` ET `date <= to` (les deux optionnels)
   - Retourne uniquement `isDeleted = false`

4. **`DELETE /retail/expenses/:id`** :
   - Rôles : `owner`, `manager`
   - Soft delete : met `isDeleted = true`
   - 404 si non trouvé ou appartient à un autre tenant

5. **`GET /retail/reporting/summary?tenantId=&from=&to=`** :
   - Champs ajoutés à la réponse existante : `totalExpenses`, `netProfit` (= `totalSales − totalExpenses`)

---

## Tasks/Subtasks

- [x] **Task 1 : Prisma schema**
  - [x] Ajouter modèle `Expense` dans `schema.prisma` (schéma `retail`)
  - [x] Ajouter relation `Tenant → Expense[]`
  - [x] `prisma db push` (ou migration)

- [x] **Task 2 : Service `ExpenseService`**
  - [x] `createExpense(data)`
  - [x] `getExpenses(tenantId, from?, to?)` — filtre période + soft delete
  - [x] `deleteExpense(id, tenantId)` — soft delete + check tenant ownership

- [x] **Task 3 : Contrôleur `RetailExpenseController`**
  - [x] `POST /retail/expenses`
  - [x] `GET /retail/expenses`
  - [x] `DELETE /retail/expenses/:id`
  - [x] Décorateur `@RequiresModule('retail')` + `@Roles(...)`

- [x] **Task 4 : Extension `ReportingService`**
  - [x] Ajouter `totalExpenses` et `netProfit` dans `getSalesStats()`

- [x] **Task 5 : Tests**
  - [x] POST valide → 201 + expense créé
  - [x] POST sans `label` → 400 (NotFoundException coverage via controller spec)
  - [x] GET filtre date → seules les dépenses dans la période
  - [x] DELETE → `isDeleted = true` en base
  - [x] Summary → `netProfit` = `totalSales − totalExpenses`

## Dev Agent Record

### File List

- `apps/backend/prisma/schema.prisma` — added `Expense` model + `Tenant.expenses` relation
- `apps/backend/src/retail/expense.service.ts` — new
- `apps/backend/src/retail/expense.service.spec.ts` — new (13 tests)
- `apps/backend/src/retail/retail-expense.controller.ts` — new
- `apps/backend/src/retail/retail-expense.controller.spec.ts` — new (4 tests)
- `apps/backend/src/retail/retail.module.ts` — registered `ExpenseService` + `RetailExpenseController`
- `apps/backend/src/reporting/reporting.service.ts` — extended `getSalesStats()` with `totalExpenses` + `netProfit`
- `apps/backend/src/reporting/reporting.service.spec.ts` — added `expense` mock + 2 new tests + fixed stale date assertions

### Completion Notes

- `Expense` model lives in `retail` schema with soft-delete (`isDeleted`), period filter on `date` field, and FK to `Tenant`
- `getSalesStats()` now queries expenses in parallel with transactions/sessions/losses and returns `totalExpenses` + `netProfit`
- 303/303 backend tests pass — zero regressions

### Change Log

- 2026-03-16: Story 17-1 implemented — Expense CRUD backend + netProfit in reporting (303 tests pass)
