import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThanOrEqual, Repository } from 'typeorm';
import { FlowPendingDelay } from './entities/flow-pending-delay.entity';
import { FlowRuntimeService } from './flow-runtime.service';
import type { CompiledFlow, CompiledStep } from './flow.types';
import type { ExecutionContext } from '../shared/engine-core';

@Injectable()
export class FlowResumeService {
  private readonly logger = new Logger(FlowResumeService.name);

  constructor(
    @InjectRepository(FlowPendingDelay)
    private readonly repo: Repository<FlowPendingDelay>,
    @Inject(forwardRef(() => FlowRuntimeService))
    private readonly runtime: FlowRuntimeService,
  ) {}

  async enqueueDelay(
    flowId: string,
    stepId: string,
    tenantId: string,
    userId: string,
    context: ExecutionContext,
    flow: CompiledFlow,
    durationSec: number,
  ): Promise<void> {
    const resumeAt = new Date(Date.now() + durationSec * 1000);

    const adjacencyRecord: Record<string, { onSuccess: string[]; onFailure?: string[] }> = {};
    for (const [key, val] of flow.adjacency) {
      adjacencyRecord[key] = val;
    }

    const record = this.repo.create({
      flow_id: flowId,
      step_id: stepId,
      tenant_id: tenantId,
      user_id: userId,
      context,
      flow_definition: {
        id: flow.id,
        name: flow.name,
        trigger: flow.trigger,
        steps: flow.steps,
        adjacency: adjacencyRecord,
      } as unknown as Record<string, unknown>,
      resume_at: resumeAt,
    });
    await this.repo.save(record, { reload: false });

    this.logger.log(
      `Delay enqueued: flow=${flowId} step=${stepId} duration=${durationSec}s resume_at=${resumeAt.toISOString()}`,
    );
  }

  @Cron(CronExpression.EVERY_5_SECONDS)
  async resumeDelayedFlows(): Promise<void> {
    const now = new Date();
    let pending: FlowPendingDelay[];

    try {
      pending = await this.repo.find({
        where: { resume_at: LessThanOrEqual(now) },
      });
    } catch (e) {
      this.logger.error(`Failed to query pending delays: ${(e as Error).message}`);
      return;
    }

    if (pending.length === 0) return;

    this.logger.log(`Resuming ${pending.length} delayed flow(s)`);

    for (const delay of pending) {
      try {
        await this.resumeOne(delay);
      } catch (e) {
        this.logger.error(
          `Failed to resume delay flow=${delay.flow_id} step=${delay.step_id}: ${(e as Error).message}`,
        );
      }
    }
  }

  private async resumeOne(delay: FlowPendingDelay): Promise<void> {
    const context: ExecutionContext = {
      tenantId: delay.tenant_id,
      userId: delay.user_id,
      data:
        ((delay.context as unknown as Record<string, unknown>)?.data as Record<string, unknown>) ?? {},
    };

    const def = delay.flow_definition as Record<string, unknown> | undefined;
    if (!def || !def.steps) {
      this.logger.warn(`No flow definition for delay ${delay.id} — deleting`);
      await this.repo.delete(delay.id);
      return;
    }

    const adjacency = new Map<string, { onSuccess: string[]; onFailure?: string[] }>();
    const adjRecord = def.adjacency as Record<string, { onSuccess: string[]; onFailure?: string[] }> | undefined;
    if (adjRecord) {
      for (const [key, val] of Object.entries(adjRecord)) {
        adjacency.set(key, val);
      }
    }

    const flow: CompiledFlow = {
      id: (def.id as string) ?? delay.flow_id,
      name: (def.name as string) ?? '',
      trigger: (def.trigger as CompiledFlow['trigger']) ?? { type: 'manual' },
      steps: (def.steps as CompiledStep[]) ?? [],
      adjacency,
    };

    const delayAdj = adjacency.get(delay.step_id);
    const children = delayAdj?.onSuccess ?? [];

    if (children.length === 0) {
      this.logger.log(`No children for delay step ${delay.step_id} — nothing to resume`);
      await this.repo.delete(delay.id);
      return;
    }

    const results: Array<{ stepId: string; status: string; output?: unknown }> = [];
    const visited = new Set<string>();

    for (const childId of children) {
      await this.runtime.executeStep(childId, flow, context, results, visited);
    }

    await this.repo.delete(delay.id);
    this.logger.log(`Delay resumed: flow=${delay.flow_id} step=${delay.step_id} → ${children.join(', ')}`);
  }
}
