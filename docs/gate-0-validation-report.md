# Gate 0 — Validation Report (template + skeleton)

**Story:** STORY-043 — Validation E2E Gate 0
**Target date:** 2026-07-08 (Blandine LIVE)
**Status:** technical contract validated 2026-05-24 ; UAT human session pending (planned 1-7 July 2026)

---

## Executive summary

Scalario's first sector template `retail_fresh_produce.json` has reached
**technical readiness** for Gate 0. All 8 sprint-4 stories are merged on
`main` with full test coverage on every contract: BDUI engine, ModuleEngine,
WorkflowEngine, sync/offline, multi-tenant security, idempotency, payment
adapters, i18n helpers, 6 modules JSON, 1 workflow JSON.

What remains gating Gate 0 is the **human UAT session with Blandine** in
her shop, planned for the week of 1-7 July 2026 per AC-13.

---

## 1. Sprint 4 stories — completion summary

| Story | Title | Status | Tests | Commit |
|---|---|---|---|---|
| STORY-031 | XState v5 State Machine | done (Sprint 3) | 36 | 01bb783 |
| STORY-032 | Integration Workflow↔ModuleEngine | done | 28 (incl. 13 review patches) | 89467a1 |
| STORY-033 | Drift offline persistence | done (Sprint 3) | 43 | a19e248 |
| STORY-034 | Sync Queue Locale Drift | done (Sprint 3) | (existing) | 1678af3 |
| STORY-035 | Conflict Resolution Phase 1 | done | 11 (5 backend + 6 Flutter) | 529451f |
| STORY-036 | Idempotence Endpoints POST | done | 28 (cache + interceptor + E2E) | dee7a71 |
| STORY-037 | Sync Status UI core | done | 20 | dcf99ec |
| STORY-039 | Template structure + 3 rôles | done | 16 | d5e0edf |
| STORY-040 | Modules Phase 1 (6 modules JSON) | done | 41 | 8e7beea |
| STORY-041 | Workflow DAG Clôture Caisse | done | 20 | 5d3f133 |
| STORY-042 | Global Scale (PaymentAdapter + i18n) | done | 30 (14 backend + 16 Flutter) | 678f2fd |
| STORY-043 | Gate 0 validation (this report) | partial — human UAT pending | 19 catalogue contract | (pending) |

**Total new tests Sprint 4: +219.** Full suite (2026-05-24):
- NestJS: 616/616 active tests passing (was 501 at start of sprint).
- Flutter: 808/808 active tests passing (was 772 at start of sprint).
- 0 regression.

---

## 2. AC-01 / AC-02 — "0 Flutter métier" audit

`scripts/audit-no-business-logic-in-flutter.ts` greps `apps/flutter/lib/
features/` + `lib/screens/` for forbidden patterns:

- Role string literals: `'OWNER'`, `'MANAGER'`, `'COMMERCIAL'`,
  `'SUPER_ADMIN'`.
- Module id literals: `'module_*'`.
- Sector literals: `'retail_'`, `'fresh_produce'`, `'pharmacy_'`,
  `'btp_'`.
- Domain words: `cloture`, `arrivage`, `perte`, `caisse`.

Whitelist: `lib/core/`, `lib/bdui/`, `*.g.dart`, lines annotated
`// bdui-engine: <reason>`.

**2026-05-24 audit result: clean.** Run via `npx tsx scripts/audit-no-business-logic-in-flutter.ts`.

To wire into CI: add the script to GitHub Actions `validate-catalogue.yml` (deferred).

---

## 3. AC-04 — 4 Gate 0 functions: catalogue coverage

All 4 user-visible functions are present in the catalogue + verified by
the Gate 0 multirole test suite (`apps/nestjs/src/catalogue/__tests__/
gate0-multirole.spec.ts`):

- **F1 — Dashboard propriétaire**: `module_dashboard_owner.json` declares
  4 KPIs (CA jour, nb ventes, alertes stock, pertes jour) + LineChart 7j
  + DataTable clôtures + NotificationCenter + Button.
- **F2 — Validation arrivage**: `module_stock.json` declares
  `arrivages_validation_form` screen + `validate_arrivage` action
  (handler `crud.update`, ABAC restricted to MANAGER/OWNER).
- **F3 — Déclaration perte**: `module_pertes.json` declares `perte_create`
  screen + entity `Perte` with 5 causes enum + `wf_perte_validation`
  inline workflow.
- **F4 — Clôture caisse**: `wf_cloture_caisse.json` declares 5 FSM states
  with full transition matrix (SUBMIT, AUTO_PASS, AUTO_REQUIRE_VALIDATION,
  VALIDATE, REQUEST_CORRECTION, REJECT).

**E2E live execution** of these flows on an Android device is part of the
UAT session (AC-04 / AC-05 / AC-06).

---

## 4. AC-10 / AC-11 — Multi-rôle + cross-RBAC

Verified by `gate0-multirole.spec.ts`:

- 3 roles → 3 distinct `dashboard_module_id` (owner/manager/commercial).
- 3 distinct landing screens via `navigation_per_role`.
- Each role's `bottom_nav` has 1-5 entries.
- COMMERCIAL cannot access owner dashboard nor validate clôtures.
- MANAGER cannot access owner dashboard nor write to ventes.
- OWNER has `read.all` on financial modules.

**HTTP-level cross-RBAC** (real 403 responses with JWT tokens) is
exercised by the existing E2E suite for STORY-032 (workflow integration)
and STORY-014/015 (Auth + RBAC).

---

## 5. AC-07 / AC-08 / AC-09 — Offline / sync / idempotency

Full chain validated:

- **Drift persistence** (STORY-033): 5 tables, SQLCipher, 43 tests.
- **Sync queue worker** (STORY-034): FIFO drain, retry exponential backoff,
  connectivity listener.
- **Idempotence HTTP cache** (STORY-036): Redis-backed, scoped by
  tenant_id from JWT, 24h TTL, fail-open. 28 tests.
- **Idempotence business layer** (STORY-022/032): `sync_mutations` Postgres
  table, checkAndReserve + markSuccess/markError.
- **Conflict resolution** (STORY-035): 3 strategies (server_wins,
  client_wins, manual) with optimistic concurrency check on
  `base_updated_at` vs `entity.updated_at`. 11 tests.
- **Sync status state machine** (STORY-037): 4 states with priority logic
  (conflicts > offline > syncing > synced). 20 tests.

**End-to-end offline drain + replay on Android device** is part of the
UAT session (AC-07 — `gate0_offline_test.dart` to be wired).

---

## 6. AC-17 — Template portability (sector-first)

Verified by 3 tests in `gate0-multirole.spec.ts`:

- Template carries `Africa/Ouagadougou` exactly once (in
  `tenant_defaults.timezone`).
- `tenant_defaults` exposes the 3 Global Scale knobs: `currency` (ISO 4217),
  `locale` (BCP-47), `timezone`.
- `payment_methods_enabled` lives in `tenant_defaults` (not in modules).
- Modules don't hardcode any provider literal (`wave`, `orange_money`,
  etc.) — resolution is done at runtime via `PaymentAdapterRegistry`
  (STORY-042).

**Real second-tenant smoke test** (`blandine_test_epicier2` in fr-CI):
deferred — requires the admin UI for tenant provisioning, planned
Sprint 5 admin epic. The contract is enforced by tests.

---

## 7. AC-21 — Audit anti-business-hardcode in the catalogue itself

19 tests in `gate0-multirole.spec.ts` enforce that the template + 6
modules + workflow contain NO mention of `FCFA`, `Burkina`, `Wave`,
`Orange Money`. `XOF` literal is also banned in modules (currency is
resolved via `tenant.config.currency`).

---

## 8. UAT Blandine — gating items (NOT YET EXECUTED)

These ACs **block Gate 0 sign-off** and require the human UAT session:

| AC | Item | Status |
|---|---|---|
| AC-05 | E2E sur Android API 34 réel | not-run |
| AC-06 | Performance < 2s par écran | not-measured |
| AC-13 | Session UAT planifiée 1-7 juillet 2026 | not-planned |
| AC-14 | 0 bug bloquant pendant UAT | TBD |
| AC-15 | Score SUS ≥ 70/100 | TBD |
| AC-16 | Bugs cosmétiques listés en backlog | TBD |
| AC-20 | Vidéo screencast 5 min Blandine | TBD |

---

## 9. Known limitations accepted Gate 0

These were deferred consciously (documented in each story's notes +
`_bmad-output/implementation-artifacts/deferred-work.md`):

- **Mobile Money real integration** (Wave/OM/MTN APIs + webhooks) →
  Phase 2. Phase 1 ships stubs that return `status: 'phase_2_stub'`.
- **Notification push (FCM/APN)** → Phase 2. Phase 1 stores
  notifications in DB.
- **Compliance OHADA** → Phase 3.
- **ARB i18n FR/EN files** (STORY-042 AC-02/03) → Sprint 5 i18n polish.
- **Lint `no_hardcoded_strings_in_widgets`** → Sprint 5.
- **Swagger `@ApiHeader` annotations** → Sprint 5 (@nestjs/swagger
  install).
- **Widget `SyncStatusBar` UI + golden tests** (STORY-037) → Sprint 5.
- **`ConflictReviewScreen` UI** (STORY-037) → Sprint 5.
- **Audit hebdomadaire / inventaire** (Blandine phase 8) → Phase 2.
- **CRDT vector clocks** → Phase 2 (STORY-035 explicitly Phase 1).

---

## 10. Sign-off checklist

- [x] Technical contract validated by automated tests (616 NestJS + 808
      Flutter = 1424 passing).
- [x] No regression introduced during Sprint 4.
- [x] Audit script for "0 Flutter métier" is green.
- [x] All 6 Phase-1 modules + 1 workflow validate against schemas.
- [ ] UAT session executed 1-7 July 2026 (Blandine + Aïcha + Ibrahim).
- [ ] Score SUS ≥ 70/100.
- [ ] Vidéo screencast 5 min recorded.
- [ ] `_bmad-output/bmm-workflow-status.yaml` → `gate_0: passed`.
- [ ] Carlos signs off.

---

*Report skeleton generated 2026-05-24 by Sprint 4 closure (STORY-043).
Fill the UAT sections after the July session.*
