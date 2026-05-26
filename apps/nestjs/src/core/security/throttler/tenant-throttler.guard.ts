import { Injectable, Logger } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerModuleOptions, ThrottlerStorage } from '@nestjs/throttler';
import { ExecutionContext } from '@nestjs/common';
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

  async handleRequest(
    context: ExecutionContext,
    limit: number,
    ttl: number,
    throttler: { name: string },
  ): Promise<boolean> {
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

    if (!this.redis.isAvailable()) {
      return super.handleRequest(context, effective.limit, effective.ttl, throttler);
    }

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

  protected getTracker(req: Record<string, any>): string {
    return `${req.tenantId ?? 'anon'}:${req.user?.id ?? 'anon'}:${req.path}`;
  }
}
