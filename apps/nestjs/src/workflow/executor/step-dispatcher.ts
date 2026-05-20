import { Injectable, Logger } from '@nestjs/common';
import type {
  ExecutableWorkflowStep,
  ExecutionContext,
  ActionDispatcherPort,
  NotificationQueuePort,
} from './workflow-executor.types';
import { WorkflowExecutionError } from './workflow-executor.types';
import { ConditionEvaluator } from './condition-evaluator';
import { RetryPolicy } from './retry-policy';

export interface StepDispatchResult {
  status: 'success' | 'skipped' | 'failed';
  output?: unknown;
  conditionResult?: boolean;
}

@Injectable()
export class StepDispatcher {
  private readonly logger = new Logger(StepDispatcher.name);

  constructor(
    private readonly conditionEvaluator: ConditionEvaluator,
    private readonly actionDispatcher: ActionDispatcherPort,
    private readonly notificationQueue: NotificationQueuePort,
    private readonly retryPolicy: RetryPolicy,
  ) {}

  async dispatch(step: ExecutableWorkflowStep, ctx: ExecutionContext): Promise<StepDispatchResult> {
    if (step.condition) {
      const conditionResult = this.conditionEvaluator.evaluate(step.condition, ctx);
      ctx.stepStatus.set(step.id, { status: conditionResult ? 'success' : 'skipped', attempts: 1 });
      if (!conditionResult) {
        if (step.type !== 'condition') {
          return { status: 'skipped', conditionResult: false };
        }
      }
    }

    switch (step.type) {
      case 'action':
        return this.dispatchAction(step, ctx);
      case 'condition':
        return this.dispatchCondition(step, ctx);
      case 'notification':
        return this.dispatchNotification(step, ctx);
      case 'approval':
        return this.dispatchApproval(step, ctx);
      default:
        throw new WorkflowExecutionError('UNSUPPORTED_STEP_TYPE', {
          stepId: step.id,
          stepType: step.type,
        });
    }
  }

  private async dispatchAction(
    step: ExecutableWorkflowStep,
    ctx: ExecutionContext,
  ): Promise<StepDispatchResult> {
    const clientMutationId = `${ctx.runId}:${step.id}`;
    const moduleId = (step.params?.moduleId as string) ?? 'default';
    const actionId = step.action ?? step.id;

    const { result, attempts } = await this.retryPolicy.execute(
      () =>
        this.actionDispatcher.executeAction(
          ctx.tenantId,
          moduleId,
          actionId,
          (step.params?.payload as Record<string, unknown>) ?? {},
          { clientMutationId, userId: ctx.triggeredBy },
        ),
      { stepId: step.id },
    );

    ctx.stepStatus.set(step.id, { status: 'success', attempts });
    ctx.stepOutput.set(step.id, result);
    return { status: 'success', output: result };
  }

  private dispatchCondition(
    step: ExecutableWorkflowStep,
    ctx: ExecutionContext,
  ): StepDispatchResult {
    const conditionPassed = step.condition
      ? this.conditionEvaluator.evaluate(step.condition, ctx)
      : true;

    if (step.next && typeof step.next === 'object' && 'true' in step.next) {
      if (conditionPassed) {
        ctx.stepStatus.set(step.id, { status: 'success', attempts: 1 });
        ctx.stepOutput.set(step.id, { branch: 'true' });
        return { status: 'success', output: { branch: 'true' }, conditionResult: true };
      }
      ctx.stepStatus.set(step.id, { status: 'skipped', attempts: 1 });
      ctx.stepOutput.set(step.id, { branch: 'false' });
      return { status: 'skipped', output: { branch: 'false' }, conditionResult: false };
    }

    if (!conditionPassed) {
      ctx.stepStatus.set(step.id, { status: 'skipped', attempts: 1 });
      return { status: 'skipped', conditionResult: false };
    }

    ctx.stepStatus.set(step.id, { status: 'success', attempts: 1 });
    return { status: 'success', conditionResult: true };
  }

  private async dispatchNotification(
    step: ExecutableWorkflowStep,
    ctx: ExecutionContext,
  ): Promise<StepDispatchResult> {
    try {
      await this.notificationQueue.publish({
        tenantId: ctx.tenantId,
        recipientUserId: step.params?.recipientUserId as string | undefined,
        template: (step.params?.template as string) ?? step.action ?? step.id,
        params: (step.params?.notificationParams as Record<string, unknown>) ?? step.params ?? {},
      });
    } catch {
      this.logger.warn(
        `Notification step '${step.id}' publish failed (fire-and-forget, continuing workflow)`,
      );
    }

    ctx.stepStatus.set(step.id, { status: 'success', attempts: 1 });
    return { status: 'success' };
  }

  private dispatchApproval(
    step: ExecutableWorkflowStep,
    ctx: ExecutionContext,
  ): StepDispatchResult {
    ctx.stepStatus.set(step.id, { status: 'running', attempts: 1 });
    ctx.stepOutput.set(step.id, { awaitingApproval: true });
    return { status: 'success' };
  }
}
