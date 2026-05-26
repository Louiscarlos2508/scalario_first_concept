import { Injectable, Logger } from '@nestjs/common';
import { ScalarioLiveService, LiveEvent } from '../live/scalario-live.service';

export interface PushPayload {
  type: LiveEvent['type'];
  data: Record<string, unknown>;
}

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private readonly pushTokens = new Map<string, { token: string; platform: string }[]>();

  constructor(private readonly live: ScalarioLiveService) {}

  async notify(userId: string, tenantId: string, payload: PushPayload): Promise<void> {
    const event: LiveEvent = {
      type: payload.type,
      data: payload.data,
      timestamp: new Date().toISOString(),
    };

    if (this.live.isUserConnected(userId)) {
      this.live.emit(tenantId, event);
      return;
    }

    const tokens = this.pushTokens.get(userId) ?? [];
    for (const { token, platform } of tokens) {
      this.logger.log(`[STUB] Would send ${payload.type} to ${platform}:${token}`);
    }
  }

  registerToken(userId: string, token: string, platform: string): void {
    if (!this.pushTokens.has(userId)) {
      this.pushTokens.set(userId, []);
    }
    this.pushTokens.get(userId)!.push({ token, platform });
    this.logger.log(`Push token registered: user=${userId} platform=${platform}`);
  }

  removeToken(userId: string, token: string): void {
    const tokens = this.pushTokens.get(userId);
    if (tokens) {
      const idx = tokens.findIndex((t) => t.token === token);
      if (idx >= 0) tokens.splice(idx, 1);
    }
  }

  getTokens(userId: string): { token: string; platform: string }[] {
    return this.pushTokens.get(userId) ?? [];
  }
}
