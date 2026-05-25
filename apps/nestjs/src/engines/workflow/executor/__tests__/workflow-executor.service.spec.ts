import { WorkflowExecutorService } from '../workflow-executor.service';
import { WorkflowValidatorService } from '../../validator/workflow-validator.service';
import { StepDispatcher } from '../step-dispatcher';
import { ConditionEvaluator } from '../condition-evaluator';
import { RetryPolicy } from '../retry-policy';
import { WorkflowStateRepository } from '../workflow-state.repository';
import { AuditLogService } from '../../../../core/audit/services/audit-log.service';
import type { ActionDispatcherPort, NotificationQueuePort } from '../workflow-executor.types';
import { WorkflowExecutionError } from '../workflow-executor.types';
import type { WorkflowStep } from '../../validator/workflow-validator.types';

class MockActionDispatcher implements ActionDispatcherPort {
  private handler: jest.Mock = jest.fn().mockResolvedValue({ success: true });
  private callLog: Array<{ moduleId: string; actionId: string }> = [];

  async executeAction(
    tenantId: string,
    moduleId: string,
    actionId: string,
    payload: Record<string, unknown>,
    opts: { clientMutationId: string; userId: string },
  ): Promise<Record<string, unknown>> {
    this.callLog.push({ moduleId, actionId });
    return this.handler(tenantId, moduleId, actionId, payload, opts);
  }

  setHandler(fn: jest.Mock) {
    this.handler = fn;
  }

  getCallLog() {
    return this.callLog;
  }

  reset() {
    this.callLog = [];
    this.handler = jest.fn().mockResolvedValue({ success: true });
  }
}

class MockNotificationQueue implements NotificationQueuePort {
  private published: Array<{ template: string; tenantId: string }> = [];

  async publish(params: {
    tenantId: string;
    recipientUserId?: string;
    template: string;
    params: Record<string, unknown>;
  }): Promise<void> {
    this.published.push({ template: params.template, tenantId: params.tenantId });
  }

  getPublished() {
    return this.published;
  }

  reset() {
    this.published = [];
  }
}

class TestableWorkflowExecutorService extends WorkflowExecutorService {
  private workflowSteps: WorkflowStep[] = [];

  setWorkflowSteps(steps: WorkflowStep[]) {
    this.workflowSteps = steps;
  }

  protected override async loadWorkflow(
    tenantId: string,
    workflowId: string,
  ): Promise<WorkflowStep[]> {
    void tenantId;
    void workflowId;
    return this.workflowSteps;
  }
}

describe('WorkflowExecutorService', () => {
  let service: TestableWorkflowExecutorService;
  let actionDispatcher: MockActionDispatcher;
  let notificationQueue: MockNotificationQueue;
  let stateRepo: jest.Mocked<WorkflowStateRepository>;
  let auditLog: jest.Mocked<AuditLogService>;

  const makeLinearDag = (): WorkflowStep[] => [
    { id: 'A', type: 'action', action: 'action_a' },
    { id: 'B', type: 'action', action: 'action_b', dependsOn: ['A'] },
    { id: 'C', type: 'action', action: 'action_c', dependsOn: ['B'] },
  ];

  const makeParallelDag = (): WorkflowStep[] => [
    { id: 'A', type: 'action', action: 'action_a' },
    { id: 'B', type: 'action', action: 'action_b', dependsOn: ['A'] },
    { id: 'C', type: 'action', action: 'action_c', dependsOn: ['A'] },
    { id: 'D', type: 'action', action: 'action_d', dependsOn: ['A'] },
    { id: 'E', type: 'action', action: 'action_e', dependsOn: ['B', 'C', 'D'] },
  ];

  beforeEach(() => {
    actionDispatcher = new MockActionDispatcher();
    notificationQueue = new MockNotificationQueue();
    stateRepo = {
      create: jest.fn().mockResolvedValue({ id: 'run-1' }),
      update: jest.fn().mockResolvedValue({ id: 'run-1' }),
      findByRunId: jest.fn(),
      findByEntityAndWorkflow: jest.fn(),
    } as any;
    auditLog = {
      log: jest.fn().mockResolvedValue(undefined),
    } as any;

    const validator = new WorkflowValidatorService();
    const conditionEvaluator = new ConditionEvaluator();
    const retryPolicy = new RetryPolicy([0]);
    const dispatcher = new StepDispatcher(
      conditionEvaluator,
      actionDispatcher,
      notificationQueue,
      retryPolicy,
    );

    service = new TestableWorkflowExecutorService(
      validator,
      stateRepo,
      dispatcher,
      auditLog,
      conditionEvaluator,
    );
  });

  describe('AC-21: Linear workflow 3 actions', () => {
    it('executes A → B → C in order and returns completed', async () => {
      service.setWorkflowSteps(makeLinearDag());

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'linear-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('completed');
      expect(result.history).toHaveLength(3);
      expect(result.history.map((h) => h.stepId)).toEqual(['A', 'B', 'C']);
      expect(result.history.every((h) => h.status === 'success')).toBe(true);

      const callLog = actionDispatcher.getCallLog();
      expect(callLog.map((c) => c.actionId)).toEqual(['action_a', 'action_b', 'action_c']);
    });
  });

  describe('AC-22: Parallel branches', () => {
    it('executes B, C, D in parallel after A, then E', async () => {
      service.setWorkflowSteps(makeParallelDag());

      const startTimestamps: Record<string, number> = {};
      actionDispatcher.setHandler(
        jest.fn().mockImplementation(async (_t, _m, actionId) => {
          startTimestamps[actionId] = Date.now();
          await new Promise((r) => setTimeout(r, 20));
          return { success: true, actionId };
        }),
      );

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'parallel-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('completed');

      const bTime = startTimestamps['action_b'];
      const cTime = startTimestamps['action_c'];
      const dTime = startTimestamps['action_d'];
      const overlap = Math.abs(bTime - cTime) < 50 && Math.abs(bTime - dTime) < 50;
      expect(overlap).toBe(true);

      const eHistory = result.history.find((h) => h.stepId === 'E');
      expect(eHistory?.status).toBe('success');
    });
  });

  describe('AC-23: Condition false → skipped', () => {
    it('skips step B when condition montant > 500000 is false', async () => {
      const steps: WorkflowStep[] = [
        { id: 'A', type: 'action', action: 'action_a' },
        {
          id: 'B',
          type: 'action',
          action: 'big_action',
          dependsOn: ['A'],
          condition: { field: 'montant', op: '>', value: 500000 },
        },
        { id: 'C', type: 'action', action: 'action_c', dependsOn: ['B'] },
      ];
      service.setWorkflowSteps(steps);

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'condition-wf',
        triggeredBy: 'user-1',
        initialContext: { montant: 100000 },
      });

      expect(result.finalState).toBe('completed');
      const stepB = result.history.find((h) => h.stepId === 'B');
      expect(stepB?.status).toBe('skipped');

      const stepC = result.history.find((h) => h.stepId === 'C');
      expect(stepC?.status).toBe('success');
    });
  });

  describe('AC-24: Retry on transient error', () => {
    it('retries 3 times on 503 then succeeds', async () => {
      service.setWorkflowSteps(makeLinearDag());
      const retryPolicy = new RetryPolicy([5, 10, 20]);

      let callCount = 0;
      actionDispatcher.setHandler(
        jest.fn().mockImplementation(async () => {
          callCount++;
          if (callCount < 3) {
            const err = new Error('service unavailable');
            (err as any).status = 503;
            throw err;
          }
          return { success: true };
        }),
      );

      service = new TestableWorkflowExecutorService(
        new WorkflowValidatorService(),
        stateRepo,
        new StepDispatcher(
          new ConditionEvaluator(),
          actionDispatcher,
          notificationQueue,
          retryPolicy,
        ),
        auditLog,
        new ConditionEvaluator(),
      );
      service.setWorkflowSteps(makeLinearDag());

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'retry-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('completed');
      const stepA = result.history.find((h) => h.stepId === 'A');
      expect(stepA?.attempts).toBe(3);
    });
  });

  describe('AC-25: Business error not retried', () => {
    it('fails immediately on 4xx error with attempts: 1', async () => {
      const steps: WorkflowStep[] = [
        { id: 'A', type: 'action', action: 'action_a' },
        { id: 'B', type: 'action', action: 'action_b', dependsOn: ['A'] },
        { id: 'C', type: 'action', action: 'action_c', dependsOn: ['B'] },
      ];
      service.setWorkflowSteps(steps);

      actionDispatcher.setHandler(
        jest.fn().mockImplementation(async (_t, _m, actionId) => {
          if (actionId === 'action_b') {
            const err = new Error('unprocessable');
            (err as any).status = 422;
            throw err;
          }
          return { success: true };
        }),
      );

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'biz-error-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('failed');
      expect(result.error).toBeDefined();
      expect(result.error!.stepId).toBe('B');

      const stepB = result.history.find((h) => h.stepId === 'B');
      expect(stepB?.status).toBe('failed');
      expect(stepB?.attempts).toBe(1);
    });
  });

  describe('AC-26: Approval pause', () => {
    it('returns awaiting_approval when approval step is reached', async () => {
      const steps: WorkflowStep[] = [
        { id: 'reconciliation', type: 'action', action: 'compute_diff' },
        { id: 'validation_manager', type: 'approval', dependsOn: ['reconciliation'] },
        { id: 'cloture_confirmee', type: 'notification', dependsOn: ['validation_manager'] },
      ];
      service.setWorkflowSteps(steps);

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'approval-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('awaiting_approval');
      expect(
        result.history.some((h) => h.stepId === 'reconciliation' && h.status === 'success'),
      ).toBe(true);
      const approvalRecord = result.history.find((h) => h.stepId === 'validation_manager');
      expect(approvalRecord).toBeDefined();
      expect(approvalRecord!.status).toBe('awaiting_approval');
      expect(approvalRecord!.completedAt).toBeUndefined();

      expect(stateRepo.update).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          currentState: expect.stringContaining('awaiting_approval'),
        }),
      );
    });
  });

  describe('AC-09: Condition type step with true/false branches', () => {
    it('marks false branch steps as skipped when condition is true', async () => {
      const steps: WorkflowStep[] = [
        { id: 'start', type: 'action', action: 'start' },
        {
          id: 'check',
          type: 'condition',
          dependsOn: ['start'],
          condition: { field: 'montant', op: '>', value: 500000 },
          next: { true: 'high_path', false: 'low_path' },
        },
        { id: 'high_path', type: 'action', action: 'big_order', dependsOn: ['check'] },
        { id: 'low_path', type: 'action', action: 'small_order', dependsOn: ['check'] },
      ];
      service.setWorkflowSteps(steps);

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'branch-wf',
        triggeredBy: 'user-1',
        initialContext: { montant: 600000 },
      });

      expect(result.finalState).toBe('completed');
      const lowPath = result.history.find((h) => h.stepId === 'low_path');
      expect(lowPath?.status).toBe('skipped');
    });
  });

  describe('Invalid DAG', () => {
    it('throws WorkflowInvalidError for cyclic DAG', async () => {
      const steps: WorkflowStep[] = [
        { id: 'A', type: 'action', action: 'a', dependsOn: ['B'] },
        { id: 'B', type: 'action', action: 'b', dependsOn: ['A'] },
      ];
      service.setWorkflowSteps(steps);

      await expect(
        service.run({
          tenantId: 'tenant-1',
          workflowId: 'cycle-wf',
          triggeredBy: 'user-1',
          initialContext: {},
        }),
      ).rejects.toThrow();
    });
  });

  describe('Unsupported step type at dispatch level', () => {
    it('results in failed workflow when dispatcher encounters unknown type', async () => {
      const steps: WorkflowStep[] = [{ id: 'A', type: 'action', action: 'a' }];
      service.setWorkflowSteps(steps);

      const originalDispatch = (service as any).dispatcher.dispatch.bind(
        (service as any).dispatcher,
      );
      jest
        .spyOn((service as any).dispatcher, 'dispatch')
        .mockImplementation(async (step: any, ctx: any) => {
          if (step.id === 'A') {
            throw new WorkflowExecutionError('UNSUPPORTED_STEP_TYPE', {
              stepId: 'A',
              stepType: 'unknown',
            });
          }
          return originalDispatch(step, ctx);
        });

      const result = await service.run({
        tenantId: 'tenant-1',
        workflowId: 'bad-type-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      });

      expect(result.finalState).toBe('failed');
      expect(result.error).toBeDefined();
      expect(result.error!.code).toBe('UNSUPPORTED_STEP_TYPE');
    });
  });
});
