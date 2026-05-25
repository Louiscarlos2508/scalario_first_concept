/**
 * Cross-tenant system roles — STORY-015.
 *
 * These are the ONLY roles hardcoded in the NestJS codebase. They are
 * cross-tenant (signed in the JWT for Scalario internal ops) and are NEVER
 * present in `tenants.config.roles[]`. Business roles (OWNER, MANAGER,
 * COMMERCIAL, LIVREUR, MEDECIN…) are data-driven per tenant.
 *
 * Adding a new system role is a deliberate code change; adding a business
 * role is a runtime config change with zero deploy (FR-010).
 */
export const SUPER_ADMIN = 'SUPER_ADMIN' as const;

export const SYSTEM_ROLES: readonly string[] = [SUPER_ADMIN] as const;

/**
 * Validation regex applied to every business role string at PATCH time and
 * at template-validation time. UPPER_SNAKE, ≤ 32 chars, must start by a
 * letter. Mirrored in `UpdateRolesSchema` (Zod) — keep both in sync.
 */
export const ROLE_NAME_REGEX = /^[A-Z][A-Z0-9_]{0,31}$/;

export function isSystemRole(role: string): boolean {
  return SYSTEM_ROLES.includes(role);
}
