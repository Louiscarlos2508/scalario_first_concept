import { Injectable, Logger } from '@nestjs/common';

interface CacheStrategy {
  ttlSeconds: number;
  description: string;
}

const STRATEGIES: Record<string, CacheStrategy> = {
  config: { ttlSeconds: 3600, description: 'Tenant configuration (1h)' },
  user_data: { ttlSeconds: 30, description: 'User session data (30s)' },
  llm_response: { ttlSeconds: 300, description: 'LLM response cache (5min)' },
  permissions: { ttlSeconds: 120, description: 'Permission/role cache (2min)' },
} as const;

/**
 * CacheStrategiesService — Phase 1.
 *
 * Defines TTLs per cache type and provides invalidation by tenantId.
 * Phase 2+ will wire this into RedisService for actual cache store/evict
 * operations.
 */
@Injectable()
export class CacheStrategiesService {
  private readonly logger = new Logger(CacheStrategiesService.name);

  getStrategy(type: string): CacheStrategy {
    const strategy = STRATEGIES[type];
    if (!strategy) {
      this.logger.warn(`Unknown cache type "${type}", falling back to config strategy`);
      return STRATEGIES.config;
    }
    return strategy;
  }

  invalidateTenant(tenantId: string): void {
    this.logger.log(`[STUB] invalidate all cache keys for tenantId=${tenantId}`);
  }
}
