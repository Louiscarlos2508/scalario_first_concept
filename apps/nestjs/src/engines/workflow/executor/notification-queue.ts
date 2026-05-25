import { Injectable, Logger } from '@nestjs/common';
import type { NotificationQueuePort } from './workflow-executor.types';

@Injectable()
export class NotificationQueue implements NotificationQueuePort {
  private readonly logger = new Logger(NotificationQueue.name);

  async publish(params: {
    tenantId: string;
    recipientUserId?: string;
    template: string;
    params: Record<string, unknown>;
  }): Promise<void> {
    this.logger.log(
      `Notification [tenant=${params.tenantId}] template=${params.template} recipient=${params.recipientUserId ?? 'broadcast'} params=${JSON.stringify(params.params)}`,
    );
  }
}
