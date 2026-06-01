import { Injectable, Logger } from '@nestjs/common';
import type { ActionDispatcherPort } from './workflow-executor.types';

@Injectable()
export class ActionDispatcher implements ActionDispatcherPort {
  private readonly logger = new Logger(ActionDispatcher.name);

  async executeAction(
    tenantId: string,
    moduleId: string,
    actionId: string,
    payload: Record<string, unknown>,
    opts: { clientMutationId: string; userId: string },
  ): Promise<Record<string, unknown>> {
    this.logger.log(`Action [tenant=${tenantId}] module=${moduleId} action=${actionId}`);
    return { success: true, actionId };
  }
}