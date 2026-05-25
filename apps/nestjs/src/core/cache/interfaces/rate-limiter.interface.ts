/**
 * STORY-018 — Rate limiter Phase 2 stub.
 *
 * Interface only — concrete `RedisRateLimiter` ships but is not wired
 * to any route in Phase 1. Phase 2 (FR-024+) will plug per-tenant LLM
 * rate limiting through this contract.
 */
export interface IRateLimiter {
  /** Returns true if `key` is below `limit` within `windowSeconds`. */
  check(key: string, limit: number, windowSeconds: number): Promise<boolean>;
  /** Atomically increments the counter for `key`. Returns the new value. */
  increment(key: string, windowSeconds: number): Promise<number>;
}
