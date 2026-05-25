/**
 * STORY-020 — Catalog of audit action names + sync/async classification.
 *
 * Sync events are inserted on the request path (await before the
 * service returns) so a crashing/incident-time process still leaves the
 * row. Everything else goes through the async buffer for throughput.
 */
export const AUDIT_ACTIONS = {
  // Auth
  AUTH_LOGIN_SUCCESS: 'AUTH_LOGIN_SUCCESS',
  AUTH_LOGIN_FAIL: 'AUTH_LOGIN_FAIL',
  AUTH_REFRESH: 'AUTH_REFRESH',
  AUTH_REFRESH_REUSE_DETECTED: 'AUTH_REFRESH_REUSE_DETECTED',
  AUTH_LOGOUT: 'AUTH_LOGOUT',
  TENANT_PROVISIONED: 'TENANT_PROVISIONED',
  // Security
  RBAC_DENY: 'RBAC_DENY',
  ABAC_DENY: 'ABAC_DENY',
  RLS_BYPASS_USED: 'RLS_BYPASS_USED',
  TENANT_VIOLATION_DETECTED: 'TENANT_VIOLATION_DETECTED',
  // Config
  TENANT_CONFIG_PATCHED: 'TENANT_CONFIG_PATCHED',
  TENANT_ROLES_PATCHED: 'TENANT_ROLES_PATCHED',
  TENANT_ABAC_RULES_PATCHED: 'TENANT_ABAC_RULES_PATCHED',
  // Meta
  AUDIT_PURGE: 'AUDIT_PURGE',
  AUDIT_LEGAL_DELETE: 'AUDIT_LEGAL_DELETE',
  // LLM (stub Phase 2)
  LLM_CALL: 'LLM_CALL',
} as const;

export type AuditAction = (typeof AUDIT_ACTIONS)[keyof typeof AUDIT_ACTIONS] | string;

/**
 * Critical events — inserted synchronously (await before return). Buffer
 * loss on crash is not acceptable for these.
 */
export const SYNC_AUDIT_ACTIONS = new Set<string>([
  AUDIT_ACTIONS.AUTH_LOGIN_FAIL,
  AUDIT_ACTIONS.AUTH_REFRESH_REUSE_DETECTED,
  AUDIT_ACTIONS.RLS_BYPASS_USED,
  AUDIT_ACTIONS.ABAC_DENY,
  AUDIT_ACTIONS.TENANT_VIOLATION_DETECTED,
]);

/** Buffer flush settings — exported so tests can override. */
export const AUDIT_BUFFER = {
  /** Max entries in memory before forced flush. */
  MAX_SIZE: 100,
  /** Periodic flush interval in milliseconds. */
  FLUSH_INTERVAL_MS: 1000,
  /** Hard cap to avoid unbounded growth if DB is down. */
  DROP_THRESHOLD: 10_000,
};

/** Retention bounds for the per-tenant purge cron (days). */
export const AUDIT_RETENTION = {
  DEFAULT_DAYS: 90,
  MIN_DAYS: 30,
  MAX_DAYS: 3650,
};
