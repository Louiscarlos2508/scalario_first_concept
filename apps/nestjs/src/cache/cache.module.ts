import { Global, Module } from '@nestjs/common';
import { BdUiCacheService } from './services/bdui-cache.service';
import { RateLimiterService } from './services/rate-limiter.service';
import { RedisService } from './services/redis.service';
import { TokenBlacklistService } from './services/token-blacklist.service';

/**
 * STORY-018 — Global cache layer.
 *
 * Global so any module (Auth, Security, BDUI…) can inject these
 * services without importing CacheModule explicitly. The Redis
 * client itself is a singleton via `RedisService`.
 */
@Global()
@Module({
  providers: [RedisService, TokenBlacklistService, BdUiCacheService, RateLimiterService],
  exports: [RedisService, TokenBlacklistService, BdUiCacheService, RateLimiterService],
})
export class CacheModule {}
