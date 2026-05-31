import { Injectable, Logger, Optional } from '@nestjs/common';
import type { EngineRuntime, ExecutionContext, ExecutionResult } from '../shared/engine-core';
import type { CompiledFlow, CompiledStep } from './flow.types';
import { FlowResumeService } from './flow-resume.service';
import { FlowWebhookService } from './flow-webhook.service';

@Injectable()
export class FlowRuntimeService implements EngineRuntime<CompiledFlow> {
  private readonly logger = new Logger(FlowRuntimeService.name);

  constructor(
    @Optional() private readonly resumeService?: FlowResumeService,
    @Optional() private readonly webhookService?: FlowWebhookService,
  ) {}

  async execute(config: CompiledFlow, context: ExecutionContext): Promise<ExecutionResult> {
    this.logger.log(`Executing flow ${config.id}`);

    if (config.steps.length === 0) {
      return { success: true, data: context.data };
    }

    const results: Array<{ stepId: string; status: string; output?: unknown }> = [];
    const entrySteps = this.findEntrySteps(config);
    const visited = new Set<string>();

    for (const entryId of entrySteps) {
      await this.executeStep(entryId, config, context, results, visited);
    }

    const allSuccess = results.every((r) => r.status === 'success');

    return {
      success: allSuccess,
      data: context.data,
      stepResults: results,
    };
  }

  async executeStep(
    stepId: string,
    flow: CompiledFlow,
    context: ExecutionContext,
    results: Array<{ stepId: string; status: string; output?: unknown }>,
    visited: Set<string>,
  ): Promise<void> {
    if (visited.has(stepId)) return;
    visited.add(stepId);

    const step = flow.steps.find((s) => s.id === stepId);
    if (!step) {
      this.logger.warn(`Step ${stepId} not found in compiled flow`);
      results.push({ stepId, status: 'error', output: 'Step not found' });
      return;
    }

    const adj = flow.adjacency.get(stepId);
    let status = 'success';
    let output: unknown;
    let conditionMet: boolean | undefined;
    let pendingDelay = false;

    try {
      if (step.type === 'loop') {
        const loopResult = await this.executeLoop(step, flow, context, results);
        status = loopResult.success ? 'success' : 'failure';
        output = loopResult.output;
      } else {
        const result = await this.dispatchStep(step, context, flow);
        status = result.success ? 'success' : 'failure';
        output = result.output;
        conditionMet = result.conditionMet;
        pendingDelay = result.pendingDelay ?? false;
      }
    } catch (e) {
      status = 'error';
      output = (e as Error).message;
      this.logger.error(`Step ${stepId} (${step.type}) failed: ${output}`);
    }

    results.push({ stepId: step.id, status, output });

    if (!adj) return;

    if (step.type === 'loop') {
      for (const childId of adj.onSuccess) {
        visited.add(childId);
      }
      return;
    }

    if (pendingDelay) return;

    if (step.type === 'condition' && conditionMet !== undefined) {
      const branch = conditionMet ? adj.onSuccess : (adj.onFailure ?? []);
      for (const nextId of branch) {
        await this.executeStep(nextId, flow, context, results, visited);
      }
    } else if (status === 'success') {
      for (const nextId of adj.onSuccess) {
        await this.executeStep(nextId, flow, context, results, visited);
      }
    } else if (status === 'failure' && adj.onFailure) {
      for (const nextId of adj.onFailure) {
        await this.executeStep(nextId, flow, context, results, visited);
      }
    }
  }

  private async dispatchStep(
    step: CompiledStep,
    context: ExecutionContext,
    flow?: CompiledFlow,
  ): Promise<{ success: boolean; output?: unknown; conditionMet?: boolean; pendingDelay?: boolean }> {
    switch (step.type) {
      case 'condition':
        return this.evaluateCondition(step.config, context);
      case 'delay':
        return this.executeDelay(step, context, flow);
      case 'approval':
        return this.requestApproval(step.config, context);
      case 'notify':
        return this.sendNotification(step.config, context);
      case 'assign':
        return this.executeAssign(step.config, context);
      case 'webhook':
        return this.callWebhook(step.config);
      case 'end':
        return { success: true, output: step.config.output };
      default:
        return { success: true };
    }
  }

  private async evaluateCondition(
    config: Record<string, unknown>,
    context: ExecutionContext,
  ): Promise<{ success: boolean; output?: unknown; conditionMet: boolean }> {
    const expr = config.expression as string;
    if (!expr) return { success: true, conditionMet: true };

    const match = expr.match(/\/data\/(\w+)\s*(>|<|>=|<=|==|!=)\s*(.+)/);
    if (!match) return { success: true, conditionMet: true };

    const [, field, operator, rawValue] = match;
    const actualValue = (context.data as Record<string, unknown>)[field];
    const expectedValue = isNaN(Number(rawValue)) ? rawValue.replace(/['"]/g, '') : Number(rawValue);
    let conditionMet = false;

    switch (operator) {
      case '>': conditionMet = Number(actualValue) > Number(expectedValue); break;
      case '<': conditionMet = Number(actualValue) < Number(expectedValue); break;
      case '>=': conditionMet = Number(actualValue) >= Number(expectedValue); break;
      case '<=': conditionMet = Number(actualValue) <= Number(expectedValue); break;
      case '==': conditionMet = actualValue == expectedValue; break;
      case '!=': conditionMet = actualValue != expectedValue; break;
    }

    return { success: true, conditionMet, output: `/${field} ${operator} ${rawValue} → ${conditionMet}` };
  }

  private async executeDelay(
    step: CompiledStep,
    context: ExecutionContext,
    flow?: CompiledFlow,
  ): Promise<{ success: boolean; output?: unknown; pendingDelay?: boolean }> {
    const duration = (step.config.duration as number) ?? 0;

    if (duration > 0 && this.resumeService && flow) {
      await this.resumeService.enqueueDelay(
        flow.id,
        step.id,
        context.tenantId,
        context.userId,
        context,
        flow,
        duration,
      );
      return { success: true, output: { status: 'pending', duration }, pendingDelay: true };
    }

    if (duration > 0) {
      await new Promise((resolve) => setTimeout(resolve, Math.min(duration * 1000, 30000)));
    }

    return { success: true };
  }

  private async requestApproval(
    config: Record<string, unknown>,
    context: ExecutionContext,
  ): Promise<{ success: boolean; output?: unknown }> {
    const role = config.role as string;
    this.logger.log(`Approval required: role=${role}`);
    return { success: true, output: `pending_approval:${role}` };
  }

  private async sendNotification(
    config: Record<string, unknown>,
    context: ExecutionContext,
  ): Promise<{ success: boolean }> {
    const channel = config.channel as string;
    const template = config.template as string;
    this.logger.log(`Notification: channel=${channel} template=${template}`);
    return { success: true };
  }

  private async executeAssign(
    config: Record<string, unknown>,
    context: ExecutionContext,
  ): Promise<{ success: boolean }> {
    const target = config.target as string;
    const value = config.value;
    const valueType = (config.valueType as string) ?? 'literal';

    const pathMatch = target?.match(/\/data\/(\w+)/);
    if (pathMatch && valueType === 'literal') {
      (context.data as Record<string, unknown>)[pathMatch[1]] = value;
    }

    return { success: true };
  }

  private async callWebhook(
    config: Record<string, unknown>,
  ): Promise<{ success: boolean; status?: number; body?: string; duration?: number }> {
    if (this.webhookService) {
      return this.webhookService.call(config);
    }
    const url = config.url as string;
    this.logger.log(`Webhook: ${config.method as string} ${url}`);
    return { success: true };
  }

  private async executeLoop(
    step: CompiledStep,
    flow: CompiledFlow,
    context: ExecutionContext,
    results: Array<{ stepId: string; status: string; output?: unknown }>,
  ): Promise<{ success: boolean; output?: unknown }> {
    const config = step.config;
    const collection = this.resolvePath(config.over as string, context);

    if (!Array.isArray(collection)) {
      return { success: false, output: `Loop step ${step.id}: '${config.over}' is not an array` };
    }

    const loopResults: Array<{ item: unknown; status: string; output?: unknown }> = [];
    const varName = config.as as string | undefined;
    const subEntrySteps = (config.stepIds as string[]) ?? [];

    for (let i = 0; i < collection.length; i++) {
      const item = collection[i];
      if (varName) {
        (context.data as Record<string, unknown>)[varName] = item;
      }

      const iterVisited = new Set<string>();
      for (const subId of subEntrySteps) {
        await this.executeStep(subId, flow, context, results, iterVisited);
      }

      loopResults.push({ item, status: 'success' });
    }

    if (varName) {
      delete (context.data as Record<string, unknown>)[varName];
    }

    return { success: true, output: loopResults };
  }

  private resolvePath(path: string, context: ExecutionContext): unknown {
    const match = path?.match(/^\/data\/(.+)/);
    if (!match) return undefined;
    const keys = match[1].split('/');
    let current: unknown = context.data;
    for (const key of keys) {
      if (current == null || typeof current !== 'object') return undefined;
      current = (current as Record<string, unknown>)[key];
    }
    return current;
  }

  private findEntrySteps(flow: CompiledFlow): string[] {
    const hasIncoming = new Set<string>();
    for (const [, adj] of flow.adjacency) {
      for (const id of adj.onSuccess) hasIncoming.add(id);
      if (adj.onFailure) for (const id of adj.onFailure) hasIncoming.add(id);
    }
    return flow.steps
      .filter((s) => !hasIncoming.has(s.id))
      .map((s) => s.id);
  }
}
