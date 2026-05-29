import { Injectable, Logger } from '@nestjs/common';
import type { EngineCompiler } from '../shared/engine-core';
import type { EngineAst } from '../shared/engine-core';
import type { FlowAstPayload, FlowStepNode, CompiledFlow, CompiledStep } from './flow.types';

@Injectable()
export class FlowCompilerService implements EngineCompiler<CompiledFlow> {
  private readonly logger = new Logger(FlowCompilerService.name);

  compile(ast: EngineAst, context?: Record<string, unknown>): CompiledFlow {
    const payload = this.parseAst(ast);
    const steps = new Map<string, FlowStepNode>();

    for (const step of payload.flow.steps) {
      steps.set(step.id, step);
    }

    const compiledSteps: CompiledStep[] = [];
    const adjacency = new Map<string, { onSuccess: string[]; onFailure?: string[] }>();

    for (const step of payload.flow.steps) {
      compiledSteps.push(this.compileStep(step));
      adjacency.set(step.id, this.buildAdjacency(step, steps));
    }

    const compiled: CompiledFlow = {
      id: payload.flow.id,
      name: payload.flow.name,
      trigger: payload.flow.trigger,
      steps: compiledSteps,
      adjacency,
    };

    this.logger.log(`Compiled flow ${compiled.id} (${compiled.steps.length} steps)`);
    return compiled;
  }

  private parseAst(ast: EngineAst): FlowAstPayload {
    const stepNodes = ast.filter((n) => n.type !== 'flow_meta');
    const metaNode = ast.find((n) => n.type === 'flow_meta') as Record<string, unknown> | undefined;

    const flow = {
      id: (metaNode?.flowId as string) ?? 'flow_' + Date.now(),
      name: (metaNode?.name as string) ?? 'Unnamed Flow',
      trigger: {
        type: ((metaNode?.triggerType as FlowAstPayload['flow']['trigger']['type']) ?? 'manual'),
        event: metaNode?.triggerEvent as string | undefined,
      } as FlowAstPayload['flow']['trigger'],
      steps: stepNodes as FlowStepNode[],
    };

    return {
      version: 'v0.9',
      engine: 'flow',
      flow,
    };
  }

  private compileStep(step: FlowStepNode): CompiledStep {
    const base = { id: step.id, type: step.type };
    const config: Record<string, unknown> = {};

    switch (step.type) {
      case 'condition':
        config.expression = step.expression;
        break;
      case 'delay':
        config.duration = step.duration;
        break;
      case 'approval':
        config.role = step.role;
        config.message = step.message;
        break;
      case 'notify':
        config.channel = step.channel;
        config.to = step.to;
        config.template = step.template;
        config.data = step.data;
        break;
      case 'loop':
        config.over = step.over;
        config.as = step.as;
        config.stepIds = step.steps;
        break;
      case 'assign':
        config.target = step.target;
        config.value = step.value;
        config.valueType = step.value_type ?? 'literal';
        break;
      case 'webhook':
        config.url = step.url;
        config.method = step.method ?? 'POST';
        config.headers = step.headers;
        config.body = step.body;
        break;
      case 'end':
        config.output = step.output;
        break;
    }

    return { ...base, config };
  }

  private buildAdjacency(
    step: FlowStepNode,
    allSteps: Map<string, FlowStepNode>,
  ): { onSuccess: string[]; onFailure?: string[] } {
    switch (step.type) {
      case 'condition':
        return {
          onSuccess: step.then ?? [],
          onFailure: step.else ?? [],
        };
      case 'approval':
        return {
          onSuccess: step.on_approved ?? [],
          onFailure: step.on_rejected ?? [],
        };
      case 'webhook':
        return {
          onSuccess: step.on_success ?? [],
          onFailure: step.on_error ?? [],
        };
      case 'loop':
        return { onSuccess: step.steps ?? [] };
      case 'delay':
      case 'notify':
      case 'assign':
      case 'end':
      default:
        return { onSuccess: [] };
    }
  }
}
