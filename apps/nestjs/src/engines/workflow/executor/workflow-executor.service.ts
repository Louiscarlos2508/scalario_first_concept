import { randomUUID } from 'node:crypto';
import { Injectable, Logger } from '@nestjs/common';
import { WorkflowValidatorService } from '../validator/workflow-validator.service';
import type { WorkflowStep } from '../validator/workflow-validator.types';
import type {
  ExecutionInput,
  ExecutionResult,
  ExecutionContext,
  StepExecution,
  ExecutableWorkflowStep,
} from './workflow-executor.types';
import {
  WorkflowInvalidError,
  WorkflowExecutionError,
  WorkflowAlreadyRunningError,
} from './workflow-executor.types';
import { StepDispatcher } from './step-dispatcher';
import { ConditionEvaluator } from './condition-evaluator';
import { WorkflowStateRepository } from './workflow-state.repository';
import { AuditLogService } from '../../../core/audit/services/audit-log.service';

const MAX_CONCURRENCY = (() => {
  const raw = parseInt(process.env.WORKFLOW_MAX_CONCURRENCY ?? '4', 10);
  return Number.isNaN(raw) || raw <= 0 ? 4 : raw;
})();

type WorkflowFinalState = 'completed' | 'failed' | 'awaiting_approval';

interface StepError {
  stepId: string;
  code: string;
  message: string;
}

@Injectable()
export class WorkflowExecutorService {
  private readonly logger = new Logger(WorkflowExecutorService.name);

  constructor(
    private readonly validator: WorkflowValidatorService,
    private readonly stateRepo: WorkflowStateRepository,
    private readonly dispatcher: StepDispatcher,
    private readonly auditLog: AuditLogService,
    private readonly conditionEvaluator: ConditionEvaluator,
  ) {}

  async run(input: ExecutionInput): Promise<ExecutionResult> {
    if (input.entityId) {
      const existing = await this.stateRepo.findByEntityAndWorkflow(
        input.tenantId,
        input.entityId,
        input.workflowId,
      );
      if (existing && existing.current_state === 'running') {
        throw new WorkflowAlreadyRunningError(input.workflowId, input.entityId);
      }
    }

    const steps = await this.loadWorkflow(input.tenantId, input.workflowId);

    const validation = this.validator.validateDAG(input.workflowId, steps);
    if (!validation.valid) {
      throw new WorkflowInvalidError(
        input.workflowId,
        validation.errors.map((e) => ({ code: e.code, message: e.message })),
      );
    }

    const runId = randomUUID();
    const ctx: ExecutionContext = {
      runId,
      tenantId: input.tenantId,
      entityId: input.entityId,
      triggeredBy: input.triggeredBy,
      data: { ...input.initialContext },
      stepStatus: new Map(),
      stepOutput: new Map(),
      history: [],
      clientMutationId: input.clientMutationId,
    };

    await this.stateRepo.create({
      tenantId: input.tenantId,
      runId,
      workflowId: input.workflowId,
      entityId: input.entityId,
      triggeredBy: input.triggeredBy,
      currentState: 'running',
      history: [],
    });

    try {
      const result = await this.executeDag(steps, validation.entryPoints, ctx);

      const finalState = result.finalState;

      if (finalState === 'awaiting_approval') {
        return {
          runId,
          workflowId: input.workflowId,
          finalState,
          history: ctx.history,
        };
      }

      await this.stateRepo.update(runId, {
        currentState: finalState,
        history: ctx.history,
      });

      return {
        runId,
        workflowId: input.workflowId,
        finalState,
        history: ctx.history,
        ...(result.stepError ? { error: result.stepError } : {}),
      };
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);

      await this.stateRepo.update(runId, {
        currentState: 'failed',
        history: ctx.history,
      });

      await this.auditLog.log({
        action: 'workflow.failed',
        tenant_id: input.tenantId,
        user_id: input.triggeredBy,
        module_id: 'workflow',
        metadata: { runId, error: errorMessage },
      });

      if (err instanceof WorkflowExecutionError) {
        return {
          runId,
          workflowId: input.workflowId,
          finalState: 'failed',
          history: ctx.history,
          error: {
            stepId: (err.details?.stepId as string) ?? 'unknown',
            code: err.code,
            message: err.message,
          },
        };
      }

      return {
        runId,
        workflowId: input.workflowId,
        finalState: 'failed',
        history: ctx.history,
        error: {
          stepId: 'unknown',
          code: 'INTERNAL_ERROR',
          message: errorMessage,
        },
      };
    }
  }

  private async executeDag(
    steps: WorkflowStep[],
    entryPoints: string[],
    ctx: ExecutionContext,
  ): Promise<{ finalState: WorkflowFinalState; stepError?: StepError }> {
    const stepMap = new Map(steps.map((s) => [s.id, s]));
    const inDegree = new Map<string, number>();
    const adjFrom = new Map<string, string[]>();

    for (const step of steps) {
      inDegree.set(step.id, step.dependsOn?.length ?? 0);
      adjFrom.set(step.id, []);
    }

    for (const step of steps) {
      for (const dep of step.dependsOn ?? []) {
        if (adjFrom.has(dep)) {
          adjFrom.get(dep)!.push(step.id);
        }
      }
    }

    const ready: string[] = [...entryPoints];
    const completed = new Set<string>();
    const skipped = new Set<string>();
    let stepError: StepError | undefined;

    while (ready.length > 0) {
      const batch: string[] = [];
      while (ready.length > 0 && batch.length < MAX_CONCURRENCY) {
        const stepId = ready.shift()!;
        if (completed.has(stepId) || skipped.has(stepId)) continue;
        batch.push(stepId);
      }

      if (batch.length === 0) continue;

      const results = await Promise.allSettled(
        batch.map((stepId) => this.processStep(stepId, stepMap, ctx)),
      );

      for (let i = 0; i < results.length; i++) {
        const result = results[i];
        const stepId = batch[i];

        if (result.status === 'rejected') {
          const err = result.reason as Error;
          this.logger.error(`Step '${stepId}' failed: ${err.message}`);

          ctx.stepStatus.set(stepId, {
            status: 'failed',
            attempts: ctx.stepStatus.get(stepId)?.attempts ?? 1,
          });

          const failedRecord = ctx.history.find(
            (h) => h.stepId === stepId && h.status === 'failed',
          );
          stepError = {
            stepId,
            code: err instanceof WorkflowExecutionError ? err.code : 'STEP_FAILED',
            message: err.message,
          };

          if (!failedRecord) {
            ctx.history.push({
              stepId,
              startedAt: new Date().toISOString(),
              completedAt: new Date().toISOString(),
              status: 'failed',
              attempts: 1,
              output: { error: { code: stepError.code, message: stepError.message } },
            });
          }

          await this.stateRepo.update(ctx.runId, { currentState: 'running', history: ctx.history });

          await this.auditLog.log({
            action: 'workflow.failed',
            tenant_id: ctx.tenantId,
            user_id: ctx.triggeredBy,
            module_id: 'workflow',
            entity_id: ctx.entityId,
            metadata: { runId: ctx.runId, stepId, error: err.message },
          });

          completed.add(stepId);

          if (batch.every((_, idx) => results[idx].status === 'rejected')) {
            break;
          }
          continue;
        }

        const { status, skippedBranches } = result.value;

        if (status === 'awaiting_approval') {
          return { finalState: 'awaiting_approval' };
        }

        if (status === 'failed') {
          stepError = {
            stepId,
            code: 'STEP_FAILED',
            message: `Step '${stepId}' execution failed`,
          };
          completed.add(stepId);
        } else if (status === 'skipped') {
          skipped.add(stepId);
        } else {
          completed.add(stepId);
        }

        await this.stateRepo.update(ctx.runId, { currentState: 'running', history: ctx.history });

        if (skippedBranches) {
          for (const branchId of skippedBranches) {
            this.skipBranch(branchId, stepMap, adjFrom, inDegree, ready, completed, skipped, ctx);
          }
        }

        this.enqueueSuccessors(stepId, adjFrom, inDegree, ready, completed, skipped);
      }

      if (stepError) {
        return { finalState: 'failed', stepError };
      }
    }

    return { finalState: 'completed' };
  }

  private async processStep(
    stepId: string,
    stepMap: Map<string, WorkflowStep>,
    ctx: ExecutionContext,
  ): Promise<{
    status: 'success' | 'skipped' | 'failed' | 'awaiting_approval';
    skippedBranches?: string[];
    conditionResult?: boolean;
  }> {
    const step = stepMap.get(stepId)!;
    const executable = this.toExecutable(step);

    const startRecord: StepExecution = {
      stepId,
      startedAt: new Date().toISOString(),
      status: 'running',
      attempts: 0,
    };
    ctx.history.push(startRecord);
    const recordIndex = ctx.history.length - 1;

    try {
      const dispatchResult = await this.dispatcher.dispatch(executable, ctx);

      ctx.history[recordIndex].status = dispatchResult.status;
      ctx.history[recordIndex].completedAt = new Date().toISOString();
      ctx.history[recordIndex].attempts = ctx.stepStatus.get(stepId)?.attempts ?? 1;
      if (dispatchResult.output !== undefined) {
        ctx.history[recordIndex].output = dispatchResult.output;
      }

      if (step.type === 'approval' && dispatchResult.status === 'success') {
        ctx.history[recordIndex].status = 'awaiting_approval';
        ctx.history[recordIndex].completedAt = undefined;

        await this.auditLog.log({
          action: 'workflow.step.completed',
          tenant_id: ctx.tenantId,
          user_id: ctx.triggeredBy,
          module_id: 'workflow',
          entity_id: ctx.entityId,
          metadata: {
            runId: ctx.runId,
            stepId,
            status: 'awaiting_approval',
            durationMs: Date.now() - new Date(startRecord.startedAt).getTime(),
          },
        });

        await this.stateRepo.update(ctx.runId, {
          currentState: `awaiting_approval:${stepId}`,
          history: ctx.history,
        });

        return { status: 'awaiting_approval' };
      }

      let skippedBranches: string[] | undefined;
      const conditionEvalResult = dispatchResult.conditionResult;
      if (
        step.type === 'condition' &&
        step.next &&
        typeof step.next === 'object' &&
        'true' in step.next
      ) {
        const nextObj = step.next as { true: string; false: string };
        const branchResult =
          conditionEvalResult ??
          (step.condition ? this.conditionEvaluator.evaluate(step.condition, ctx) : true);
        skippedBranches = branchResult ? [nextObj.false] : [nextObj.true];
      }

      await this.auditLog.log({
        action: 'workflow.step.completed',
        tenant_id: ctx.tenantId,
        user_id: ctx.triggeredBy,
        module_id: 'workflow',
        entity_id: ctx.entityId,
        metadata: {
          runId: ctx.runId,
          stepId,
          status: dispatchResult.status,
          durationMs: Date.now() - new Date(startRecord.startedAt).getTime(),
        },
      });

      return {
        status: dispatchResult.status,
        skippedBranches,
        conditionResult: conditionEvalResult,
      };
    } catch (err) {
      ctx.history[recordIndex].status = 'failed';
      ctx.history[recordIndex].completedAt = new Date().toISOString();
      ctx.history[recordIndex].attempts = ctx.stepStatus.get(stepId)?.attempts ?? 1;

      if (err instanceof WorkflowExecutionError) {
        ctx.history[recordIndex].output = {
          error: { code: err.code, message: err.message },
        };
      }

      ctx.stepStatus.set(stepId, {
        status: 'failed',
        attempts: ctx.stepStatus.get(stepId)?.attempts ?? 1,
      });

      await this.auditLog.log({
        action: 'workflow.step.completed',
        tenant_id: ctx.tenantId,
        user_id: ctx.triggeredBy,
        module_id: 'workflow',
        entity_id: ctx.entityId,
        metadata: {
          runId: ctx.runId,
          stepId,
          status: 'failed',
          durationMs: Date.now() - new Date(startRecord.startedAt).getTime(),
          error: err instanceof Error ? err.message : String(err),
        },
      });

      throw err;
    }
  }

  private enqueueSuccessors(
    stepId: string,
    adjFrom: Map<string, string[]>,
    inDegree: Map<string, number>,
    ready: string[],
    completed: Set<string>,
    skipped: Set<string>,
  ): void {
    const successors = adjFrom.get(stepId) ?? [];
    for (const nextId of successors) {
      if (completed.has(nextId) || skipped.has(nextId)) continue;
      const currentDeg = inDegree.get(nextId) ?? 0;
      const newDeg = currentDeg - 1;
      inDegree.set(nextId, newDeg);
      if (newDeg <= 0) {
        ready.push(nextId);
      }
    }
  }

  private skipBranch(
    branchStart: string,
    stepMap: Map<string, WorkflowStep>,
    adjFrom: Map<string, string[]>,
    inDegree: Map<string, number>,
    ready: string[],
    completed: Set<string>,
    skipped: Set<string>,
    ctx: ExecutionContext,
  ): void {
    const toProcess = [branchStart];
    while (toProcess.length > 0) {
      const current = toProcess.shift()!;
      if (skipped.has(current) || completed.has(current)) continue;

      const predecessors = stepMap.get(current)?.dependsOn ?? [];
      const isBranchStart = current === branchStart;
      const onlySkippedPredecessors = predecessors.every((dep) => skipped.has(dep));

      if (!isBranchStart && !onlySkippedPredecessors) {
        continue;
      }

      skipped.add(current);

      ctx.history.push({
        stepId: current,
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
        status: 'skipped',
        attempts: 0,
      });

      const successors = adjFrom.get(current) ?? [];
      for (const nextId of successors) {
        if (!skipped.has(nextId) && !completed.has(nextId)) {
          toProcess.push(nextId);
        }
      }

      this.enqueueSuccessors(current, adjFrom, inDegree, ready, completed, skipped);
    }
  }

  private toExecutable(step: WorkflowStep): ExecutableWorkflowStep {
    return {
      id: step.id,
      type: step.type,
      dependsOn: step.dependsOn,
      next: step.next as ExecutableWorkflowStep['next'],
      action: step.action,
      params: step.params,
      condition: step.condition as ExecutableWorkflowStep['condition'] | undefined,
    };
  }

  protected async loadWorkflow(tenantId: string, workflowId: string): Promise<WorkflowStep[]> {
    void tenantId;
    void workflowId;
    throw new WorkflowExecutionError('WORKFLOW_NOT_FOUND', {
      workflowId,
      tenantId,
    });
  }
}
