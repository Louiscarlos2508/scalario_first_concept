import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../cache/services/redis.service';

export interface CachedHttpResponse {
  status: number;
  body: unknown;
  contentType: string;
  capturedAt: string;
  userId?: string;
}

/**
 * STORY-036 — HTTP-level idempotency cache for POST endpoints.
 *
 * Distinct from the business-layer `IdempotencyService` (sync_mutations
 * table, Postgres) which prevents double-execution at the action level.
 * This service caches the full HTTP response so that re-played requests
 * (network retry, SyncQueueWorker drain) short-circuit before reaching
 * the controller.
 *
 * Key shape: `idem:{tenant_id}:{client_mutation_id}`. TTL 24h. Fail-open
 * on Redis errors — the request continues without cache (the business
 * layer still prevents doubles in DB).
 */
@Injectable()
export class IdempotencyCacheService {
  private readonly logger = new Logger(IdempotencyCacheService.name);
  private readonly ttlSeconds = 86_400; // 24h
  private collisionCount = 0;
  private hitCount = 0;
  private missCount = 0;

  constructor(private readonly redis: RedisService) {}

  private key(tenantId: string, mutationId: string): string {
    return `idem:${tenantId}:${mutationId}`;
  }

  async lookup(tenantId: string, mutationId: string): Promise<CachedHttpResponse | null> {
    if (!this.redis.isAvailable()) return null;
    try {
      const raw = await this.redis.getClient().get(this.key(tenantId, mutationId));
      if (raw) {
        this.hitCount++;
        this.logger.log(`idempotency.metric.hit tenant=${tenantId} key=${mutationId}`);
        return JSON.parse(raw) as CachedHttpResponse;
      }
      this.missCount++;
      return null;
    } catch (err) {
      // Fail-open: Redis hiccup must not block requests. Business layer
      // still guards against doubles via sync_mutations.
      this.logger.warn(
        `idempotency lookup failed tenant=${tenantId} key=${mutationId}: ${(err as Error).message}`,
      );
      return null;
    }
  }

  async store(tenantId: string, mutationId: string, response: CachedHttpResponse): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      const k = this.key(tenantId, mutationId);
      const client = this.redis.getClient();
      const existing = await client.get(k);
      const payload = JSON.stringify(response);
      if (existing && existing !== payload) {
        this.collisionCount++;
        this.logger.warn(
          `idempotency.metric.collision tenant=${tenantId} key=${mutationId} — replay payload differs from cached; keeping original`,
        );
        // Stripe-like: keep the first-write response. Do NOT overwrite.
        return;
      }
      await client.set(k, payload, 'EX', this.ttlSeconds);
    } catch (err) {
      this.logger.warn(
        `idempotency store failed tenant=${tenantId} key=${mutationId}: ${(err as Error).message}`,
      );
    }
  }

  /**
   * Test-only accessor for counters. Exposed so unit tests can assert
   * metric behaviour without wiring prom-client (deferred).
   */
  getMetrics(): { hits: number; misses: number; collisions: number } {
    return {
      hits: this.hitCount,
      misses: this.missCount,
      collisions: this.collisionCount,
    };
  }
}
