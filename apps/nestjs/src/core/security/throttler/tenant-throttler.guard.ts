import { Injectable, Logger, ExecutionContext } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerModuleOptions, ThrottlerStorage, ThrottlerRequest } from '@nestjs/throttler';
import { Reflector } from '@nestjs/core';
import { RedisService } from '../../cache/services/redis.service';

@Injectable()
export class TenantThrottlerGuard extends ThrottlerGuard {
  private readonly logger = new Logger(TenantThrottlerGuard.name);

  constructor(
    options: ThrottlerModuleOptions,
    storageService: ThrottlerStorage,
    reflector: Reflector,
    private readonly redis: RedisService,
  ) {
    super(options, storageService, reflector);
  }

  async handleRequest(requestProps: ThrottlerRequest): Promise<boolean> {
    const { context, limit, ttl, throttler } = requestProps;
    const req = context.switchToHttp().getRequest();
    const tenantId = req.tenantId ?? 'anonymous';
    const userId = req.user?.id ?? 'anonymous';
    const endpoint = req.path;

    const routeLimits: Record<string, { limit: number; ttl: number }> = {
      '/api/ai': { limit: 20, ttl: 60 },
      '/api/payments': { limit: 10, ttl: 60 },
    };

    const matched = Object.entries(routeLimits).find(([prefix]) => endpoint.startsWith(prefix));
    const effective = matched ? matched[1] : { limit: 200, ttl: 60 };

    const key = `ratelimit:${tenantId}:${userId}:${endpoint}`;

    if (this.redis.isAvailable()) {
      const client = this.redis.getClient();
      const current = await client.incr(key);
      if (current === 1) {
        await client.expire(key, effective.ttl);
      }

      if (current > effective.limit) {
        this.logger.warn(`Rate limit exceeded: ${key} (${current}/${effective.limit})`);
        return false;
      }

      return true;
    }

    return super.handleRequest({
      ...requestProps,
      limit: effective.limit,
      ttl: effective.ttl,
    });
  }
}
