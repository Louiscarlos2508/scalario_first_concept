import { Global, Module } from '@nestjs/common';
import { IdempotencyCacheService } from './idempotency-cache.service';
import { IdempotencyInterceptor } from './idempotency.interceptor';

/**
 * STORY-036 — HTTP-level idempotency module. CacheService + Interceptor.
 *
 * Global so the interceptor wired via APP_INTERCEPTOR can resolve its
 * deps without an explicit import in AppModule's providers list.
 */
@Global()
@Module({
  providers: [IdempotencyCacheService, IdempotencyInterceptor],
  exports: [IdempotencyCacheService, IdempotencyInterceptor],
})
export class IdempotencyModule {}
