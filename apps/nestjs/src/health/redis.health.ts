import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';
import Redis from 'ioredis';

@Injectable()
export class RedisHealthIndicator extends HealthIndicator {
  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    const url = process.env.REDIS_URL;
    if (!url) {
      throw new HealthCheckError(
        `${key} check failed`,
        this.getStatus(key, false, { error: 'REDIS_URL not set' }),
      );
    }

    const client = new Redis(url, {
      lazyConnect: true,
      connectTimeout: 2000,
      maxRetriesPerRequest: 1,
    });

    try {
      await client.connect();
      const pong = await client.ping();
      const ok = pong === 'PONG';
      const result = this.getStatus(key, ok);
      if (!ok) {
        throw new HealthCheckError(`${key} ping failed`, result);
      }
      return result;
    } catch (err) {
      throw new HealthCheckError(
        `${key} check failed`,
        this.getStatus(key, false, { error: (err as Error).message }),
      );
    } finally {
      client.disconnect();
    }
  }
}
