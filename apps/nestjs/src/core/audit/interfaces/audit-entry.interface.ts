/**
 * STORY-020 — Public input shape consumed by `AuditLogService.log`.
 *
 * `payload` is hashed (SHA-256) before persistence — the original is
 * never written to disk (architecture line 836 — confidentiality).
 * Tenant/user are auto-filled from `tenantContext.get()` when omitted.
 */
export interface AuditEntryInput {
  action: string;
  tenant_id?: string | null;
  user_id?: string | null;
  module_id?: string | null;
  entity_id?: string | null;
  /** Raw payload — SHA-256 hashed before persistence. */
  payload?: unknown;
  /** Arbitrary structured metadata (kept verbatim). */
  metadata?: Record<string, unknown>;
}

/** Internal shape inserted into `audit_logs`. */
export interface AuditEntry {
  tenant_id: string | null;
  user_id: string | null;
  action: string;
  module_id: string | null;
  entity_id: string | null;
  payload_hash: string | null;
  metadata: Record<string, unknown>;
  created_at: Date;
}
