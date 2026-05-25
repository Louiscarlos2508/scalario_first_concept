import { Injectable, Logger } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { BdUiCacheService } from '../../core/cache/services/bdui-cache.service';
import type { ScreenConfig } from '../interfaces';

@Injectable()
export class BduiLayoutCacheService {
  private readonly logger = new Logger(BduiLayoutCacheService.name);

  constructor(private readonly cache: BdUiCacheService) {}

  buildKey(tenantId: string, screenId: string, roles: string[]): string {
    const roleHash = createHash('sha256')
      .update([...roles].sort().join(','))
      .digest('hex')
      .slice(0, 12);
    return `bdui:${tenantId}:${screenId}:${roleHash}`;
  }

  async get(tenantId: string, screenId: string, roles: string[]): Promise<ScreenConfig | null> {
    const roleString = this.roleKey(roles);
    const cached = await this.cache.get<ScreenConfig>(tenantId, screenId, roleString);
    if (cached) {
      this.logger.debug(`cache HIT: tenant=${tenantId} screen=${screenId} role=${roleString}`);
    }
    return cached;
  }

  async set(
    tenantId: string,
    screenId: string,
    roles: string[],
    value: ScreenConfig,
  ): Promise<void> {
    const roleString = this.roleKey(roles);
    await this.cache.set(tenantId, screenId, roleString, value);
    this.logger.debug(`cache SET: tenant=${tenantId} screen=${screenId} role=${roleString}`);
  }

  async invalidate(tenantId: string, screenId?: string): Promise<void> {
    await this.cache.invalidate(tenantId, screenId);
    this.logger.log(`cache INVALIDATE: tenant=${tenantId} screen=${screenId ?? '*'}`);
  }

  private roleKey(roles: string[]): string {
    return createHash('sha256')
      .update([...roles].sort().join(','))
      .digest('hex')
      .slice(0, 12);
  }
}
