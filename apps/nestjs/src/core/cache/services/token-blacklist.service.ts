import { Injectable, Logger } from '@nestjs/common';
import { KEY_PREFIX } from '../constants';
import type { ITokenBlacklist } from '../interfaces/token-blacklist.interface';
import { RedisService } from './redis.service';

/**
 * STORY-018 — Layer 1.5 instant revocation.
 *
 * Stores `blacklist:<jti|hash> = 1` with TTL = remaining token lifetime.
 * `JwtAuthGuard` consults this on every request: O(1) Redis `EXISTS`.
 * On Redis error we fail-open (allow the request through) per the
 * trade-off documented in the story — outage of Redis must not equal
 * outage of Scalario. Phase 2 switches to fail-closed with a circuit
 * breaker.
 */
@Injectable()
export class TokenBlacklistService implements ITokenBlacklist {
  private readonly logger = new Logger(TokenBlacklistService.name);

  constructor(private readonly redis: RedisService) {}

  async add(key: string, ttlSeconds: number): Promise<void> {
    if (!key || ttlSeconds <= 0) return;
    if (!this.redis.isAvailable()) return;
    try {
      await this.redis
        .getClient()
        .set(`${KEY_PREFIX.BLACKLIST}${key}`, '1', 'EX', Math.ceil(ttlSeconds));
    } catch (err) {
      this.logger.error(`blacklist add failed: ${(err as Error).message}`);
    }
  }

  async isRevoked(key: string): Promise<boolean> {
    if (!key) return false;
    if (!this.redis.isAvailable()) return false;
    try {
      const result = await this.redis.getClient().exists(`${KEY_PREFIX.BLACKLIST}${key}`);
      return result === 1;
    } catch (err) {
      this.logger.error(`blacklist check failed (fail-open): ${(err as Error).message}`);
      return false;
    }
  }
}
