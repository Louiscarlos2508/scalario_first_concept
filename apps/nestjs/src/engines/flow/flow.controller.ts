import { Controller, Post, Body, Logger } from '@nestjs/common';
import { MindEngineService } from '../mind/mind-engine.service';
import { FlowCompilerService } from './flow-compiler.service';
import { FlowRuntimeService } from './flow-runtime.service';
import type { ExecutionContext } from '../shared/engine-core';

export interface FlowGenerateRequest {
  tenantId: string;
  userId: string;
  intent: string;
  data?: Record<string, unknown>;
}

export interface FlowExecuteRequest {
  tenantId: string;
  userId: string;
  flowAst: string;
  data: Record<string, unknown>;
}

@Controller(':tenant/flow')
export class FlowController {
  private readonly logger = new Logger(FlowController.name);

  constructor(
    private readonly mind: MindEngineService,
    private readonly compiler: FlowCompilerService,
    private readonly runtime: FlowRuntimeService,
  ) {}

  @Post('generate')
  async generate(@Body() body: FlowGenerateRequest) {
    this.logger.log(`Flow generate: intent="${body.intent}"`);

    const result = await this.mind.generate({
      surfaceId: `flow_${Date.now()}`,
      intent: body.intent,
      engine: 'flow',
      context: { data: body.data },
    });

    if (result.degraded) {
      return { success: false, error: 'AI service unavailable', degraded: true };
    }

    const ast = this.extractSteps(result.text);

    return {
      success: true,
      engine: 'flow',
      ast,
      compiled: true,
      model: result.model,
      retries: result.retries,
    };
  }

  @Post('execute')
  async execute(@Body() body: FlowExecuteRequest) {
    let steps: ReturnType<FlowController['parseFlowJson']>;
    try {
      steps = this.parseFlowJson(body.flowAst);
    } catch (e) {
      return { success: false, error: `Invalid flow AST: ${(e as Error).message}` };
    }

    const compiled = this.compiler.compile(steps);

    const context: ExecutionContext = {
      tenantId: body.tenantId,
      userId: body.userId,
      data: body.data ?? {},
    };

    const result = await this.runtime.execute(compiled, context);

    return {
      success: result.success,
      stepResults: result.stepResults,
      data: result.data,
    };
  }

  private extractSteps(raw: string): import('../shared/engine-core').AstNode[] {
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error('No JSON found');

    const parsed = JSON.parse(jsonMatch[0]);
    const flow = (parsed as Record<string, unknown>).flow as Record<string, unknown>;
    const steps = flow?.steps as Array<Record<string, unknown>> | undefined;

    if (!steps) throw new Error('No flow.steps found in AST');

    return steps.map((s, i) => ({
      id: (s.id as string) ?? `step_${i}`,
      type: (s.type as string) ?? 'unknown',
      ...s,
    }));
  }

  private parseFlowJson(raw: string): import('../shared/engine-core').AstNode[] {
    return this.extractSteps(raw);
  }
}
