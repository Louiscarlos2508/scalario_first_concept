# Audit Events Catalog

STORY-020 — reference for every action name that may land in `audit_logs`.
New events MUST be added here and to `AUDIT_ACTIONS` in
`src/audit/constants.ts`. Sync events (caller awaits the INSERT) MUST
also be listed in `SYNC_AUDIT_ACTIONS`.

## Schema reminder

`audit_logs` columns (insert-only — `REVOKE UPDATE, DELETE` on
`scalario_app`):

| Column         | Type            | Notes                                                         |
| -------------- | --------------- | ------------------------------------------------------------- |
| `id`           | UUID PK         | auto                                                          |
| `tenant_id`    | UUID            | NOT NULL (auto-filled from `tenantContext` when omitted)      |
| `user_id`      | UUID, nullable  | request initiator (null for cron / system events)             |
| `action`       | TEXT            | one of the names below — UPPER_SNAKE_CASE                     |
| `module_id`    | TEXT, nullable  | module string (e.g. `invoices`) for `@Audited` routes         |
| `entity_id`    | UUID, nullable  | row id of the affected entity                                 |
| `payload_hash` | TEXT, nullable  | SHA-256 hex of request body — payload itself is NEVER stored  |
| `metadata`     | JSONB           | event-specific structured fields (see per-event tables below) |
| `created_at`   | TIMESTAMPTZ     | auto                                                          |

## Event catalog

### Auth events (STORY-014)

| Action                          | Sync | Source                           | metadata fields                                    |
| ------------------------------- | :--: | -------------------------------- | -------------------------------------------------- |
| `AUTH_LOGIN_SUCCESS`            |  —   | `AuthService.login`              | `roles: string[]`                                  |
| `AUTH_LOGIN_FAIL`               |  ✓   | `AuthService.validateLocalCredentials` | `reason: 'tenant_not_found' \| 'invalid_credentials' \| 'user_not_found_or_disabled'`, `tenant_slug?` |
| `AUTH_REFRESH`                  |  —   | `AuthService.refresh`            | —                                                  |
| `AUTH_REFRESH_REUSE_DETECTED`   |  ✓   | `AuthService.refresh`            | — (family already revoked at this point)           |
| `AUTH_LOGOUT`                   |  —   | `AuthService.logout`             | —                                                  |
| `TENANT_PROVISIONED`            |  —   | `TenantsProvisionController`     | `slug`, `template`, `roles: string[]`              |

### Security events (STORY-015 / STORY-017 / STORY-019)

| Action                     | Sync | Source                  | metadata fields                                                   |
| -------------------------- | :--: | ----------------------- | ----------------------------------------------------------------- |
| `RBAC_DENY`                |  —   | `RbacGuard`             | `required_roles: string[]`, `user_roles: string[]`, `reason`      |
| `ABAC_DENY`                |  ✓   | `AbacGuard`             | `action`, `subject`, `reason?: 'missing_ability'`                 |
| `RLS_BYPASS_USED`          |  ✓   | `RlsBypassService.withBypass` | `caller`, `reason`, `tenant_filter`                         |
| `TENANT_VIOLATION_DETECTED`|  ✓   | `TenantIsolationFilter` | `code: '42501'`                                                   |

### Config events

| Action                        | Sync | Source                     | metadata fields                                  |
| ----------------------------- | :--: | -------------------------- | ------------------------------------------------ |
| `TENANT_ROLES_PATCHED`        |  —   | `TenantsRolesController`   | `added: string[]`, `removed: string[]`, `resulting: string[]` |
| `TENANT_CONFIG_PATCHED`       |  —   | (Sprint 3+)                | `keys: string[]`                                 |
| `TENANT_ABAC_RULES_PATCHED`   |  —   | (Sprint 3+)                | `rules_version: number`, `rules_count: number`   |

### Meta-events

| Action               | Sync | Source              | metadata fields                                              |
| -------------------- | :--: | ------------------- | ------------------------------------------------------------ |
| `AUDIT_PURGE`        |  —   | `AuditPurgeService` | `rows_deleted: number`, `retention_days: number`, `cutoff`   |
| `AUDIT_LEGAL_DELETE` |  ✓   | ops procedure       | `case_id`, `approved_by`, `rows_deleted`                     |

### LLM events (Phase 2 — stub)

| Action     | Sync | Source             | metadata fields                                                  |
| ---------- | :--: | ------------------ | ---------------------------------------------------------------- |
| `LLM_CALL` |  —   | `AiRelayModule` (Phase 2) | `model`, `tokens_used`, `query_hash`, `latency_ms`         |

## Adding a new event

1. Add the constant to `AUDIT_ACTIONS` in `src/audit/constants.ts`.
2. If the event is forensic-critical (must not be lost on a crash),
   add it to `SYNC_AUDIT_ACTIONS`.
3. Document the metadata contract in this file — be explicit about which
   keys are guaranteed and which are optional.
4. Add a sync hook at the call site:
   - Service hook: `await this.audit.log({ action, ... })` (the helper
     wraps it for optional injection).
   - Controller hook: prefer `@Audited('ACTION')` if the action maps to
     a single HTTP route — the interceptor handles latency + success/error.
5. If the event flows from an inbound HTTP request, the request body
   gets hashed automatically (`payload_hash` column). Never put raw PII
   into `metadata`.

## Auditing for compliance reviewers

- The table is INSERT-only at the PostgreSQL privilege layer — even a
  compromised `scalario_app` connection cannot UPDATE or DELETE a row.
- The cron purge runs as `scalario_admin` and itself emits an
  `AUDIT_PURGE` meta-event with `rows_deleted` for each tenant.
- Retention is per-tenant, controlled by `tenants.config.audit_retention_days`,
  clamped to `[30, 3650]`. The default is 90 days.
- For long-running investigations: set `audit_retention_days = 3650`
  on the affected tenant; the purge will skip it. (Phase 2 plan:
  separate immutable `audit_meta_events` table for `RLS_BYPASS_USED`,
  `TENANT_VIOLATION_DETECTED`, and `AUDIT_PURGE` itself.)
