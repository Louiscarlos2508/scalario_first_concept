import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { RedisService } from '../../cache/services/redis.service';
import { BduiLayoutCacheService } from './bdui-layout-cache.service';
import { CHANNEL } from '../../cache/constants';

interface InvalidatePayload {
  tenant_id: string;
  screens?: string[];
}

@Injectable()
export class TenantConfigEventsListener implements OnModuleInit {
  private readonly logger = new Logger(TenantConfigEventsListener.name);

  constructor(
    private readonly redis: RedisService,
    private readonly cache: BduiLayoutCacheService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      const sub = this.redis.getSubscriber();
      await sub.subscribe(CHANNEL.BDUI_INVALIDATE);
      sub.on('message', (channel: string, message: string) => {
        if (channel !== CHANNEL.BDUI_INVALIDATE) return;
        try {
          const payload = JSON.parse(message) as InvalidatePayload;
          this.logger.log(
            `Received tenant.config.updated for tenant=${payload.tenant_id}, flushing cache`,
          );
          void this.cache.invalidate(payload.tenant_id, payload.screens?.[0]);
        } catch (err) {
          this.logger.warn(`Malformed bdui:invalidate message: ${(err as Error).message}`);
        }
      });
      this.logger.log('Subscribed to bdui:invalidate channel');
    } catch (err) {
      this.logger.error(`Failed to subscribe to bdui:invalidate: ${(err as Error).message}`);
    }
  }
}
