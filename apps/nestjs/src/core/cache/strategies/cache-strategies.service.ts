import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../services/redis.service';

export type CacheType = 'config' | 'user_data' | 'llm_response' | 'permissions';

const TTL_CONFIG: Record<CacheType, number> = {
  config: 3600,
  user_data: 30,
  llm_response: 300,
  permissions: 120,
};

@Injectable()
export class CacheStrategiesService {
  private readonly logger = new Logger(CacheStrategiesService.name);

  constructor(private readonly redis: RedisService) {}

  getTTL(type: CacheType): number {
    return TTL_CONFIG[type] ?? 60;
  }

  async get(type: CacheType, key: string): Promise<string | null> {
    if (!this.redis.isAvailable()) return null;
    try {
      return await this.redis.getClient().get(`cache:${type}:${key}`);
    } catch (err) {
      this.logger.warn(`Cache get failed: ${(err as Error).message}`);
      return null;
    }
  }

  async set(type: CacheType, key: string, value: string): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      await this.redis.getClient().set(`cache:${type}:${key}`, value, 'EX', this.getTTL(type));
    } catch (err) {
      this.logger.warn(`Cache set failed: ${(err as Error).message}`);
    }
  }

  async invalidateTenant(tenantId: string): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      const client = this.redis.getClient();
      const keys = await client.keys(`cache:*:*${tenantId}*`);
      if (keys.length > 0) {
        await client.del(...keys);
        this.logger.log(`Invalidated ${keys.length} cache keys for tenant ${tenantId}`);
      }
    } catch (err) {
      this.logger.warn(`Cache invalidation failed: ${(err as Error).message}`);
    }
  }
}
