import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis, { RedisOptions } from 'ioredis';

/**
 * STORY-018 — single ioredis client + dedicated subscriber for pub/sub.
 *
 * ioredis best practice: a connection that has called `SUBSCRIBE`
 * cannot run other commands. So we keep two connections — `client`
 * for commands and `subscriber` for channel listening. Both target the
 * same Redis instance via `REDIS_URL`.
 *
 * Fail-open boot: if Redis is unreachable at startup, NestJS does NOT
 * crash. ioredis keeps retrying in the background; `/health` reports
 * `redis: down` until it reconnects. The blacklist guard also
 * fail-opens (see TokenBlacklistService) so a Redis outage degrades
 * gracefully instead of locking everyone out.
 */
@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private clientRef: Redis | null = null;
  private subscriberRef: Redis | null = null;

  async onModuleInit(): Promise<void> {
    const url = process.env.REDIS_URL;
    if (!url) {
      // Don't crash NestJS — but log loudly. Health check will report down.
      this.logger.error('REDIS_URL not set — cache layer disabled');
      return;
    }
    if (!process.env.REDIS_PASSWORD && !url.includes('@')) {
      // AC-23 — Redis must be password-protected. Allow either env var or
      // embedded credentials in the URL.
      throw new Error(
        'REDIS_PASSWORD is required (or embed credentials in REDIS_URL) — refusing to start',
      );
    }

    const opts: RedisOptions = {
      maxRetriesPerRequest: 3,
      retryStrategy: (times) => Math.min(times * 200, 2000),
      lazyConnect: false,
      enableOfflineQueue: true,
    };

    this.clientRef = new Redis(url, opts);
    this.subscriberRef = this.clientRef.duplicate();

    this.clientRef.on('error', (err) => {
      this.logger.error(`redis client error: ${err.message}`);
    });
    this.subscriberRef.on('error', (err) => {
      this.logger.error(`redis subscriber error: ${err.message}`);
    });

    try {
      const pong = await this.clientRef.ping();
      if (pong !== 'PONG') {
        this.logger.error(`redis ping returned unexpected value: ${pong}`);
      }
    } catch (err) {
      this.logger.error(`redis ping failed at boot: ${(err as Error).message}`);
    }
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.allSettled([this.clientRef?.quit(), this.subscriberRef?.quit()]);
  }

  /**
   * Returns the command client. Throws when Redis is not configured —
   * callers (blacklist, BDUI cache) handle the throw and fail-open.
   */
  getClient(): Redis {
    if (!this.clientRef) throw new Error('Redis client not initialised');
    return this.clientRef;
  }

  getSubscriber(): Redis {
    if (!this.subscriberRef) throw new Error('Redis subscriber not initialised');
    return this.subscriberRef;
  }

  isAvailable(): boolean {
    return this.clientRef !== null;
  }
}
