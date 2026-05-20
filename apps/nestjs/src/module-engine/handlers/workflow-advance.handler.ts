import { Injectable, Logger } from '@nestjs/common';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';

@Injectable()
export class WorkflowAdvanceHandler implements Handler {
  readonly type = 'workflow.advance';
  private readonly logger = new Logger(WorkflowAdvanceHandler.name);

  async execute(ctx: HandlerContext): Promise<HandlerResult> {
    this.logger.log(
      `Workflow advance stub: module=${ctx.moduleConfig.id} action=${ctx.actionDef.handler} payload_keys=${Object.keys(ctx.payload).join(',')}`,
    );

    return {
      entity: ctx.payload as Record<string, unknown>,
      data: {
        status: 'workflow_advanced',
        note: 'Workflow advance handler — full implementation in STORY-030',
        workflow_id: ctx.actionDef.handler,
      },
    };
  }
}
