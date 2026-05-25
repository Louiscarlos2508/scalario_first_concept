import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { LRUCache } from 'lru-cache';
import { gzipSync, gunzipSync } from 'node:zlib';
import {
  BDUI_COMPRESS_THRESHOLD_BYTES,
  BDUI_L1_MAX_ENTRIES,
  BDUI_L1_TTL_MS,
  CHANNEL,
  KEY_PREFIX,
  TTL_SECONDS,
} from '../constants';
import type { IBdUiCache } from '../interfaces/bdui-cache.interface';
import { RedisService } from './redis.service';

interface InvalidatePayload {
  tenant_id: string;
  screens?: string[];
}

/**
 * STORY-018 — two-tier BDUI layout cache.
 *
 * - L1: in-process LRU (≤100 entries, 60s TTL) — sub-ms hit for hot
 *   layouts on the same node.
 * - L2: Redis with 5-min TTL and gzip above 10 KB.
 * - Invalidation: pub/sub on `bdui:invalidate`. Each node listens and
 *   purges its L1 + L2 entries matching the tenant (and optional screen
 *   list). 5-min L2 TTL caps stale data on missed messages.
 *
 * Compressed payloads are stored as raw bytes and recognised by the
 * gzip magic bytes (0x1f 0x8b) — we use `getBuffer` to avoid utf-8
 * corruption of the binary.
 */
@Injectable()
export class BdUiCacheService implements IBdUiCache, OnModuleInit {
  private readonly logger = new Logger(BdUiCacheService.name);
  private readonly local = new LRUCache<string, object>({
    max: BDUI_L1_MAX_ENTRIES,
    ttl: BDUI_L1_TTL_MS,
  });

  constructor(private readonly redis: RedisService) {}

  async onModuleInit(): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      const sub = this.redis.getSubscriber();
      await sub.subscribe(CHANNEL.BDUI_INVALIDATE);
      sub.on('message', (channel, message) => {
        if (channel !== CHANNEL.BDUI_INVALIDATE) return;
        try {
          const payload = JSON.parse(message) as InvalidatePayload;
          this.invalidateLocal(payload.tenant_id, payload.screens);
        } catch (err) {
          this.logger.warn(`bdui:invalidate malformed message: ${(err as Error).message}`);
        }
      });
    } catch (err) {
      this.logger.error(`bdui pub/sub subscribe failed: ${(err as Error).message}`);
    }
  }

  private keyFor(tenant_id: string, screen_id: string, role: string): string {
    return `${KEY_PREFIX.BDUI}${tenant_id}:${screen_id}:${role}`;
  }

  async get<T>(tenant_id: string, screen_id: string, role: string): Promise<T | null> {
    const key = this.keyFor(tenant_id, screen_id, role);
    const hit = this.local.get(key);
    if (hit !== undefined) return hit as T;

    if (!this.redis.isAvailable()) return null;
    try {
      const raw = await this.redis.getClient().getBuffer(key);
      if (!raw) return null;
      const text =
        raw.length >= 2 && raw[0] === 0x1f && raw[1] === 0x8b
          ? gunzipSync(raw).toString('utf8')
          : raw.toString('utf8');
      const parsed = JSON.parse(text) as T;
      this.local.set(key, parsed as unknown as object);
      return parsed;
    } catch (err) {
      this.logger.error(`bdui get failed: ${(err as Error).message}`);
      return null;
    }
  }

  async set<T>(tenant_id: string, screen_id: string, role: string, value: T): Promise<void> {
    const key = this.keyFor(tenant_id, screen_id, role);
    this.local.set(key, value as unknown as object);
    if (!this.redis.isAvailable()) return;
    try {
      const json = JSON.stringify(value);
      const buf =
        Buffer.byteLength(json) > BDUI_COMPRESS_THRESHOLD_BYTES
          ? gzipSync(json)
          : Buffer.from(json, 'utf8');
      await this.redis.getClient().set(key, buf, 'EX', TTL_SECONDS.BDUI);
    } catch (err) {
      this.logger.error(`bdui set failed: ${(err as Error).message}`);
    }
  }

  async invalidate(tenant_id: string, screen_id?: string): Promise<void> {
    this.invalidateLocal(tenant_id, screen_id ? [screen_id] : undefined);
    if (!this.redis.isAvailable()) return;
    try {
      const client = this.redis.getClient();
      const pattern = screen_id
        ? `${KEY_PREFIX.BDUI}${tenant_id}:${screen_id}:*`
        : `${KEY_PREFIX.BDUI}${tenant_id}:*`;
      // SCAN avoids the O(N) blocking that KEYS would impose in prod.
      const stream = client.scanStream({ match: pattern, count: 100 });
      for await (const keys of stream) {
        const batch = keys as string[];
        if (batch.length) await client.del(...batch);
      }
      await client.publish(
        CHANNEL.BDUI_INVALIDATE,
        JSON.stringify({
          tenant_id,
          screens: screen_id ? [screen_id] : undefined,
        } satisfies InvalidatePayload),
      );
    } catch (err) {
      this.logger.error(`bdui invalidate failed: ${(err as Error).message}`);
    }
  }

  /** Test-only — clears the in-process L1. */
  clearLocal(): void {
    this.local.clear();
  }

  private invalidateLocal(tenant_id: string, screens?: string[]): void {
    const tenantPrefix = `${KEY_PREFIX.BDUI}${tenant_id}:`;
    for (const key of this.local.keys()) {
      if (!key.startsWith(tenantPrefix)) continue;
      if (screens && screens.length > 0) {
        const match = screens.some((s) => key.startsWith(`${tenantPrefix}${s}:`));
        if (!match) continue;
      }
      this.local.delete(key);
    }
  }
}
