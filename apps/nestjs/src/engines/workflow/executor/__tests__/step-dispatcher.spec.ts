import { StepDispatcher } from '../step-dispatcher';
import { ConditionEvaluator } from '../condition-evaluator';
import { RetryPolicy } from '../retry-policy';
import type {
  ExecutionContext,
  ActionDispatcherPort,
  NotificationQueuePort,
  ExecutableWorkflowStep,
} from '../workflow-executor.types';
import { WorkflowExecutionError } from '../workflow-executor.types';

describe('StepDispatcher', () => {
  let dispatcher: StepDispatcher;
  let mockActionDispatcher: jest.Mocked<ActionDispatcherPort>;
  let mockNotificationQueue: jest.Mocked<NotificationQueuePort>;
  let conditionEvaluator: ConditionEvaluator;
  let retryPolicy: RetryPolicy;

  const makeCtx = (data?: Record<string, unknown>): ExecutionContext => ({
    runId: 'run-1',
    tenantId: 'tenant-1',
    triggeredBy: 'user-1',
    data: data ?? { montant: 100000 },
    stepStatus: new Map(),
    stepOutput: new Map(),
    history: [],
  });

  beforeEach(() => {
    mockActionDispatcher = {
      executeAction: jest.fn().mockResolvedValue({ success: true }),
    };
    mockNotificationQueue = {
      publish: jest.fn().mockResolvedValue(undefined),
    };
    conditionEvaluator = new ConditionEvaluator();
    retryPolicy = new RetryPolicy([0]);
    dispatcher = new StepDispatcher(
      conditionEvaluator,
      mockActionDispatcher,
      mockNotificationQueue,
      retryPolicy,
    );
  });

  describe('action type', () => {
    it('calls action dispatcher with correct parameters', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'step-1',
        type: 'action',
        action: 'compute_diff',
        params: { moduleId: 'caisse', payload: { amount: 100 } },
      };
      const ctx = makeCtx();

      const result = await dispatcher.dispatch(step, ctx);

      expect(result.status).toBe('success');
      expect(mockActionDispatcher.executeAction).toHaveBeenCalledWith(
        'tenant-1',
        'caisse',
        'compute_diff',
        { amount: 100 },
        { clientMutationId: 'run-1:step-1', userId: 'user-1' },
      );
    });

    it('defaults moduleId to "default" when not provided', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'step-1',
        type: 'action',
        action: 'do_something',
      };
      const ctx = makeCtx();

      await dispatcher.dispatch(step, ctx);

      expect(mockActionDispatcher.executeAction).toHaveBeenCalledWith(
        'tenant-1',
        'default',
        'do_something',
        {},
        expect.any(Object),
      );
    });
  });

  describe('condition type', () => {
    it('evaluates condition and dispatches true branch', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'check_amount',
        type: 'condition',
        condition: { field: 'montant', op: '>', value: 500000 },
        next: { true: 'high_value', false: 'low_value' },
      };
      const ctx = makeCtx({ montant: 600000 });

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
    });

    it('evaluates condition and dispatches false branch (skipped)', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'check_amount',
        type: 'condition',
        condition: { field: 'montant', op: '>', value: 500000 },
        next: { true: 'high_value', false: 'low_value' },
      };
      const ctx = makeCtx({ montant: 100000 });

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('skipped');
    });

    it('condition without next object returns success when true', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'check_amount',
        type: 'condition',
        condition: { field: 'montant', op: '>', value: 500000 },
      };
      const ctx = makeCtx({ montant: 600000 });

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
    });
  });

  describe('notification type', () => {
    it('publishes notification and returns success', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'notify_owner',
        type: 'notification',
        params: {
          template: 'cloture_complete',
          recipientUserId: 'user-2',
          notificationParams: { total: 500000 },
        },
      };
      const ctx = makeCtx();

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
      expect(mockNotificationQueue.publish).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId: 'tenant-1',
          template: 'cloture_complete',
          recipientUserId: 'user-2',
        }),
      );
    });

    it('continues workflow even if notification publish fails', async () => {
      mockNotificationQueue.publish.mockRejectedValueOnce(new Error('queue down'));

      const step: ExecutableWorkflowStep = {
        id: 'notify_owner',
        type: 'notification',
        params: { template: 'test' },
      };
      const ctx = makeCtx();

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
    });
  });

  describe('approval type', () => {
    it('returns success with running status for approval step', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'manager_approval',
        type: 'approval',
      };
      const ctx = makeCtx();

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
      expect(ctx.stepOutput.get('manager_approval')).toEqual({ awaitingApproval: true });
    });
  });

  describe('unsupported step type', () => {
    it('throws WorkflowExecutionError for unknown type', async () => {
      const step = {
        id: 'bad_step',
        type: 'unknown' as any,
      };
      const ctx = makeCtx();

      await expect(dispatcher.dispatch(step, ctx)).rejects.toThrow(WorkflowExecutionError);
      await expect(dispatcher.dispatch(step, ctx)).rejects.toThrow(
        expect.objectContaining({ code: 'UNSUPPORTED_STEP_TYPE' }),
      );
    });
  });

  describe('condition guard (step.condition on any step type)', () => {
    it('skips action step when condition is false', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'big_order',
        type: 'action',
        action: 'process_big',
        condition: { field: 'montant', op: '>', value: 500000 },
      };
      const ctx = makeCtx({ montant: 100000 });

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('skipped');
      expect(mockActionDispatcher.executeAction).not.toHaveBeenCalled();
    });

    it('executes action step when condition is true', async () => {
      const step: ExecutableWorkflowStep = {
        id: 'big_order',
        type: 'action',
        action: 'process_big',
        condition: { field: 'montant', op: '>', value: 500000 },
      };
      const ctx = makeCtx({ montant: 600000 });

      const result = await dispatcher.dispatch(step, ctx);
      expect(result.status).toBe('success');
      expect(mockActionDispatcher.executeAction).toHaveBeenCalled();
    });
  });
});
