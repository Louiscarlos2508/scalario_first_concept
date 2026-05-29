import { Injectable, Logger } from '@nestjs/common';
import { FlowCompilerService } from '../../flow/flow-compiler.service';
import { FlowRuntimeService } from '../../flow/flow-runtime.service';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';
import type { ExecutionContext } from '../../shared/engine-core';
import type { AstNode } from '../../shared/engine-core';

@Injectable()
export class FlowExecuteHandler implements Handler {
  readonly type = 'flow.execute';
  private readonly logger = new Logger(FlowExecuteHandler.name);

  constructor(
    private readonly compiler: FlowCompilerService,
    private readonly runtime: FlowRuntimeService,
  ) {}

  async execute(ctx: HandlerContext): Promise<HandlerResult> {
    const flowAst = ctx.payload.flowAst as AstNode[] | undefined;
    if (!flowAst || !Array.isArray(flowAst)) {
      throw new Error('flow.execute handler requires flowAst array in payload');
    }

    const data = (ctx.payload.data as Record<string, unknown>) ?? {};

    this.logger.log(`Executing flow with ${flowAst.length} AST nodes`);

    const compiled = this.compiler.compile(flowAst);

    const execCtx: ExecutionContext = {
      tenantId: ctx.tenantId,
      userId: ctx.userId,
      data,
    };

    const result = await this.runtime.execute(compiled, execCtx);

    return {
      data: {
        flowId: compiled.id,
        success: result.success,
        data: result.data,
        stepResults: result.stepResults,
      },
    };
  }
}
