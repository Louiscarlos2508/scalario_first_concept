import { Injectable, Logger } from '@nestjs/common';
import { KEY_PREFIX } from '../constants';
import type { IRateLimiter } from '../interfaces/rate-limiter.interface';
import { RedisService } from './redis.service';

/**
 * STORY-018 — Phase 2 stub.
 *
 * Fixed-window counter (INCR + EXPIRE on first hit). Not wired to any
 * route in Phase 1 — FR-024+ Phase 2 will register this against
 * LLM-bound endpoints with per-tenant quotas.
 */
@Injectable()
export class RateLimiterService implements IRateLimiter {
  private readonly logger = new Logger(RateLimiterService.name);

  constructor(private readonly redis: RedisService) {}

  async check(key: string, limit: number, windowSeconds: number): Promise<boolean> {
    const count = await this.increment(key, windowSeconds);
    return count <= limit;
  }

  async increment(key: string, windowSeconds: number): Promise<number> {
    if (!this.redis.isAvailable()) return 0;
    try {
      const fullKey = `${KEY_PREFIX.RATELIMIT}${key}`;
      const client = this.redis.getClient();
      const count = await client.incr(fullKey);
      if (count === 1) {
        await client.expire(fullKey, Math.ceil(windowSeconds));
      }
      return count;
    } catch (err) {
      this.logger.error(`rate-limit incr failed: ${(err as Error).message}`);
      return 0;
    }
  }
}
