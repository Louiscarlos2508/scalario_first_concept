import type { TenantConfig } from '../../../auth/entities/tenant.entity';
import type { AbacAbility, AbacUser } from '../types';

/**
 * STORY-019 — Engine abstraction so the implementation can swap.
 *
 * Phase 1 implementation : `CaslAbacEngine` — straight CASL `MongoAbility`.
 * Phase 3 implementation : `ReteAbacEngine` (FR-037) — RETE algorithm
 * once a tenant exceeds ~50 rules or p95 evaluate() crosses 5ms.
 *
 * Keeping the surface small (build + evaluate) lets us swap engines
 * without touching the guard, the middleware, or the helpers.
 */
export interface ABACEngine {
  buildAbility(user: AbacUser, tenantConfig: TenantConfig): AbacAbility;
  evaluate(ability: AbacAbility, action: string, subject: unknown): boolean;
}

export const ABAC_ENGINE = Symbol('ABAC_ENGINE');
