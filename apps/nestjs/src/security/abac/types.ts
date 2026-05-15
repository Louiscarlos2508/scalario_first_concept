import type { MongoAbility } from '@casl/ability';

/**
 * STORY-019 — shared types for the ABAC layer.
 *
 * `AbacUser` is the subset of the authenticated user that the rule
 * substitutor reads from. It mirrors `AuthenticatedUser` from auth/, but
 * we redeclare it here so the abac module has no upward dependency on
 * auth/.
 */
export interface AbacUser {
  user_id: string;
  tenant_id: string;
  roles: string[];
  department_id: string | null;
  metadata?: Record<string, unknown>;
}

export type AbacAbility = MongoAbility;

export interface AbilityCacheKey {
  user_id: string;
  tenant_id: string;
  config_version: number;
}
