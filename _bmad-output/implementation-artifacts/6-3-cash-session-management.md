# Story 6.3: Cash Session Management

Status: review

## Story

As a commercial,
I want to open and close cash sessions with balance tracking and mandatory variance explanation,
so that cash accountability is enforced and the owner can track cash handling accuracy.

## Acceptance Criteria

1. **AC1 — retail.pos_sessions table (with variance_explanation):** Given the retail schema exists, when the sessions migration runs, then the `retail.pos_sessions` table is created (or migrated from public) with: `id`, `opening_balance` (Decimal 10,2), `closing_balance` (nullable), `theoretical_balance` (nullable), `variance` (nullable), `variance_explanation` (nullable), `status` (OPEN/CLOSED), `user_id`, `tenant_id`, `opened_at`, `closed_at`, with index on `(tenant_id, user_id, status)`.

2. **AC2 — POST /api/v1/retail/sessions/open:** Given an authenticated Commercial user with no open session, when they call `POST /api/v1/retail/sessions/open` with an opening balance, then a new PosSession is created with status OPEN and the declared opening balance. If user already has an open session, the request is rejected (only one open session per user).

3. **AC3 — POST /api/v1/retail/sessions/close/:id with variance logic:** Given a Commercial has an open session with sales totaling cash, when they call `POST /api/v1/retail/sessions/close/:id` with closing_balance, then: `theoretical_balance = opening_balance + cash_sales`, `variance = closing_balance - theoretical_balance`. If `variance != 0` and no `variance_explanation` is provided, closure is rejected with a 400 error. If explanation provided, session status changes to CLOSED, `closed_at` is set, and a `session.closed` event is emitted.

4. **AC4 — GET /api/v1/retail/sessions/summary/:id:** Given an authenticated Manager user, when they call `GET /api/v1/retail/sessions/summary/:id`, then the session summary is returned with: total sales, breakdown by payment method, opening balance, closing balance, theoretical balance, variance, and explanation.

5. **AC5 — GET /api/v1/reports/sessions:** Given an authenticated Manager user, when they call `GET /api/v1/reports/sessions`, then they can view session closure reports for all commercials in their location.

6. **AC6 — Fix broken getSessionSummary (uses prisma.order which no longer exists):** The existing `pos-session.service.ts::getSessionSummary()` uses `prisma.order.findMany` which was removed in Story 4.2. This must be replaced with `prisma.transaction.findMany` filtered by sessionId.

7. **AC7 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 6.3 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Database: migrate pos_sessions to retail schema (AC1)

- [x] **1.1** Added `varianceExplanation String? @map("variance_explanation")` to `PosSession` model (kept in `public` schema — Option A).
  - Added `@@index([tenantId, userId, status])` composite index.

- [x] **1.2** Created SQL migration `apps/backend/prisma/migrations/20260315160000_pos_sessions_variance_explanation/migration.sql`:
  - `ALTER TABLE public.pos_sessions ADD COLUMN IF NOT EXISTS variance_explanation TEXT;`
  - `CREATE INDEX IF NOT EXISTS pos_sessions_tenant_user_status_idx ON public.pos_sessions (tenant_id, user_id, status);`

### Phase 2 — PosSessionService: open/close/summary rewrite (AC2, AC3, AC4, AC6)

- [x] **2.1** Rewrote `PosSessionService` — added EventBusService injection; `openSession()` unchanged (already correct).

- [x] **2.2** Rewrote `closeSession(sessionId, closingBalance, varianceExplanation?)`:
  - Validates session exists and is OPEN
  - Computes variance via `getSessionSummary()`
  - Enforces varianceExplanation when variance != 0 (BadRequestException)
  - Updates all balance fields + varianceExplanation; emits `session.closed` event

- [x] **2.3** Fixed `getSessionSummary()`:
  - Replaced `prisma.order.findMany` (broken) with `prisma.transaction.findMany({ where: { sessionId } })`
  - Returns: totalsByMethod, totalSales, theoreticalCash, openingBalance, closingBalance, theoreticalBalance, variance, varianceExplanation
  - Added `getSessionReports(tenantId)`: returns CLOSED sessions ordered by closedAt desc (AC5)

### Phase 3 — Controller: retail/sessions endpoints (AC2, AC3, AC4, AC5)

- [x] **3.1** Created `apps/backend/src/retail/retail-session.controller.ts` (`@Controller('retail/sessions')` + `@RequiresModule('retail')`):
  - `POST open` — `@Roles('owner', 'manager', 'commercial')` → userId from `req.user?.sub` or body
  - `POST close/:id` — `@Roles('owner', 'manager', 'commercial')` → passes `varianceExplanation`
  - `GET summary/:id` — `@Roles('owner', 'manager')`
  - `GET reports` — `@Roles('owner', 'manager')` → `getSessionReports(tenantId)`

### Phase 4 — Tests (AC2, AC3, AC4, AC6, AC7)

- [x] **4.1** Created `apps/backend/src/pos/pos-session.service.spec.ts` (13 tests):
  - openSession: creates OPEN; rejects if already OPEN (AC2)
  - closeSession: correct variance calc; rejects if variance!=0 and no explanation; closes with zero variance; emits event; throws if not found (AC3)
  - getSessionSummary: uses transaction.findMany; correct totals; varianceExplanation; invalid UUID; not found (AC4, AC6)
  - getSessionReports: CLOSED sessions ordered by closedAt desc (AC5)

- [x] **4.2** Created `apps/backend/src/retail/retail-session.controller.spec.ts` (5 tests):
  - POST /open with userId from req.user.sub / body fallback; POST /close/:id with/without explanation; GET /summary/:id; GET /reports

- [x] **4.3** Run `npx jest --no-coverage` — 238/238 tests pass, 0 regressions (AC7).

## Dev Notes

### CRITICAL: broken getSessionSummary

Fixed by replacing `prisma.order.findMany` with `prisma.transaction.findMany({ where: { sessionId } })`. Transaction model already has `sessionId` field.

### variance_explanation enforcement

```typescript
if (variance !== 0 && (!varianceExplanation || varianceExplanation.trim() === '')) {
  throw new BadRequestException('variance_explanation is required when variance is non-zero');
}
```

### Schema decision: Option A (keep in public)

PosSession stays in `public` schema. Only `variance_explanation` column added.

### UUID regex in tests

The service validates UUIDs with a strict regex requiring `[89ab]` in the 4th group. Use `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11` as test SESSION_ID.

### References

- [Story 4.2 — Transaction API (Order removed)](4-2-transaction-api-local-first-recording.md)
- [Story 6.1 — retail schema](6-1-retail-schema-product-extensions.md)
- [Story 6.2 — RetailSale + session_id](6-2-retailsale-extensions-session-scoping.md)
- [epics.md — Epic 6 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- UUID regex fix: `SESSION_ID` must match `[89ab]` in 4th group. Switched to `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`.

### Completion Notes List

- **PosSession.varianceExplanation:** `String?` field added, `public` schema (Option A), plus `@@index([tenantId, userId, status])` (AC1).
- **SQL migration 20260315160000:** `ADD COLUMN IF NOT EXISTS variance_explanation TEXT` + composite index (AC1).
- **PosSessionService rewrite:** EventBusService injected. `closeSession()` enforces varianceExplanation when variance != 0; emits `session.closed`. `getSessionSummary()` fixed — `prisma.order` → `prisma.transaction`. `getSessionReports()` added (AC2, AC3, AC4, AC5, AC6).
- **RetailSessionController:** `@Controller('retail/sessions')` + `@RequiresModule('retail')`. 4 endpoints. Old `pos/sessions/*` controller preserved for backward compat.
- **18 new tests:** 13 service + 5 controller. 238/238 pass, 0 regressions (AC7).

### File List

- apps/backend/prisma/schema.prisma [MODIFIED — PosSession.varianceExplanation + @@index]
- apps/backend/prisma/migrations/20260315160000_pos_sessions_variance_explanation/migration.sql [NEW]
- apps/backend/src/pos/pos-session.service.ts [MODIFIED — EventBus, variance logic, AC6 fix, getSessionReports]
- apps/backend/src/retail/retail-session.controller.ts [NEW — 4 retail session endpoints]
- apps/backend/src/pos/pos-session.service.spec.ts [NEW — 13 tests]
- apps/backend/src/retail/retail-session.controller.spec.ts [NEW — 5 tests]

## Change Log

- 2026-03-15: Story 6.3 created — pos_sessions variance_explanation, open/close session with mandatory explanation, fix broken getSessionSummary.
- 2026-03-15: Story 6.3 implemented — varianceExplanation + migration, PosSessionService rewrite (variance enforcement, session.closed event, AC6 fix), RetailSessionController, 238/238 tests pass.
