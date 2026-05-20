import { WorkflowExecutorService } from '../workflow-executor.service';
import { WorkflowValidatorService } from '../../validator/workflow-validator.service';
import { StepDispatcher } from '../step-dispatcher';
import { ConditionEvaluator } from '../condition-evaluator';
import { RetryPolicy } from '../retry-policy';
import type { ActionDispatcherPort, NotificationQueuePort } from '../workflow-executor.types';
import type { WorkflowStep } from '../../validator/workflow-validator.types';

class MockActionDispatcher implements ActionDispatcherPort {
  private calls: Array<{ moduleId: string; actionId: string; mutationId: string }> = [];
  private handler: (
    tenantId: string,
    moduleId: string,
    actionId: string,
    payload: Record<string, unknown>,
    opts: { clientMutationId: string; userId: string },
  ) => Promise<Record<string, unknown>> = async () => ({ success: true });

  async executeAction(
    tenantId: string,
    moduleId: string,
    actionId: string,
    payload: Record<string, unknown>,
    opts: { clientMutationId: string; userId: string },
  ): Promise<Record<string, unknown>> {
    this.calls.push({
      moduleId,
      actionId,
      mutationId: opts.clientMutationId,
    });
    return this.handler(tenantId, moduleId, actionId, payload, opts);
  }

  setHandler(
    fn: (
      tenantId: string,
      moduleId: string,
      actionId: string,
      payload: Record<string, unknown>,
      opts: { clientMutationId: string; userId: string },
    ) => Promise<Record<string, unknown>>,
  ) {
    this.handler = fn;
  }

  getCalls() {
    return [...this.calls];
  }

  reset() {
    this.calls = [];
    this.handler = async () => ({ success: true });
  }
}

class MockNotificationQueue implements NotificationQueuePort {
  private published: Array<{
    tenantId: string;
    template: string;
    recipientUserId?: string;
  }> = [];

  async publish(params: {
    tenantId: string;
    recipientUserId?: string;
    template: string;
    params: Record<string, unknown>;
  }): Promise<void> {
    this.published.push({
      tenantId: params.tenantId,
      template: params.template,
      recipientUserId: params.recipientUserId,
    });
  }

  getPublished() {
    return [...this.published];
  }
}

class TestableExecutorService extends WorkflowExecutorService {
  private steps: WorkflowStep[] = [];

  setWorkflowSteps(steps: WorkflowStep[]) {
    this.steps = steps;
  }

  protected override async loadWorkflow(
    tenantId: string,
    workflowId: string,
  ): Promise<WorkflowStep[]> {
    void tenantId;
    void workflowId;
    return this.steps;
  }
}

describe('Workflow Executor E2E – Clôture Caisse', () => {
  let service: TestableExecutorService;
  let actionDispatcher: MockActionDispatcher;
  let notificationQueue: MockNotificationQueue;
  let stateRepoCreate: jest.Mock;
  let stateRepoUpdate: jest.Mock;
  let auditLogEntries: Array<{ action: string; metadata: Record<string, unknown> }>;

  const clotureCaisseWithParams: WorkflowStep[] = [
    {
      id: 'saisie_fond_restant',
      type: 'action',
      action: 'open_form_fond',
      params: { moduleId: 'caisse', payload: { form: 'fond_restant' } },
    },
    {
      id: 'reconciliation',
      type: 'action',
      action: 'compute_diff',
      dependsOn: ['saisie_fond_restant'],
      params: { moduleId: 'caisse', payload: { operation: 'diff' } },
    },
    {
      id: 'validation_manager',
      type: 'approval',
      dependsOn: ['reconciliation'],
    },
    {
      id: 'cloture_confirmee',
      type: 'notification',
      dependsOn: ['validation_manager'],
      action: 'notify_owner',
      params: {
        moduleId: 'caisse',
        template: 'cloture_complete',
        recipientUserId: 'user-manager-1',
      },
    },
  ];

  beforeEach(() => {
    actionDispatcher = new MockActionDispatcher();
    notificationQueue = new MockNotificationQueue();

    stateRepoCreate = jest.fn().mockResolvedValue({ id: 'run-e2e' });
    stateRepoUpdate = jest.fn().mockResolvedValue({ id: 'run-e2e' });
    auditLogEntries = [];

    auditLogEntries = [];
    const mockAuditLog = {
      log: jest.fn().mockImplementation(async (entry: any) => {
        auditLogEntries.push({ action: entry.action, metadata: entry.metadata });
      }),
    };

    const conditionEvaluator = new ConditionEvaluator();
    const retryPolicy = new RetryPolicy([0]);
    const dispatcher = new StepDispatcher(
      conditionEvaluator,
      actionDispatcher,
      notificationQueue,
      retryPolicy,
    );

    const mockStateRepo = {
      create: stateRepoCreate,
      update: stateRepoUpdate,
      findByRunId: jest.fn(),
      findByEntityAndWorkflow: jest.fn(),
    } as any;

    service = new TestableExecutorService(
      new WorkflowValidatorService(),
      mockStateRepo,
      dispatcher,
      mockAuditLog as any,
      conditionEvaluator,
    );
  });

  it('AC-27: executes clôture caisse workflow end-to-end with approval pause', async () => {
    service.setWorkflowSteps(clotureCaisseWithParams);

    const result = await service.run({
      tenantId: 'tenant-retail',
      workflowId: 'cloture_caisse',
      entityId: 'entity-caisse-1',
      triggeredBy: 'user-1',
      initialContext: { montant: 500000 },
    });

    expect(result.finalState).toBe('awaiting_approval');
    expect(result.runId).toBeDefined();
    expect(result.workflowId).toBe('cloture_caisse');

    const saisieRecord = result.history.find((h) => h.stepId === 'saisie_fond_restant');
    expect(saisieRecord).toBeDefined();
    expect(saisieRecord!.status).toBe('success');

    const reconRecord = result.history.find((h) => h.stepId === 'reconciliation');
    expect(reconRecord).toBeDefined();
    expect(reconRecord!.status).toBe('success');

    const validationRecord = result.history.find((h) => h.stepId === 'validation_manager');
    expect(validationRecord).toBeDefined();
    expect(validationRecord!.status).toBe('awaiting_approval');
    expect(validationRecord!.completedAt).toBeUndefined();

    const actionCalls = actionDispatcher.getCalls();
    expect(actionCalls).toHaveLength(2);

    expect(actionCalls[0].actionId).toBe('open_form_fond');
    expect(actionCalls[0].mutationId).toMatch(/^[0-9a-f-]+:saisie_fond_restant$/);

    expect(actionCalls[1].actionId).toBe('compute_diff');
    expect(actionCalls[1].mutationId).toMatch(/^[0-9a-f-]+:reconciliation$/);

    const published = notificationQueue.getPublished();
    expect(published).toHaveLength(0);

    expect(stateRepoCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 'tenant-retail',
        workflowId: 'cloture_caisse',
        currentState: 'running',
      }),
    );

    expect(stateRepoUpdate).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        currentState: expect.stringContaining('awaiting_approval'),
      }),
    );

    const stepCompletedAudits = auditLogEntries.filter(
      (e) => e.action === 'workflow.step.completed',
    );
    expect(stepCompletedAudits.length).toBeGreaterThanOrEqual(2);

    const stepAuditsIds = stepCompletedAudits.map((e) => e.metadata.stepId);
    expect(stepAuditsIds).toContain('saisie_fond_restant');
    expect(stepAuditsIds).toContain('reconciliation');

    for (const audit of stepCompletedAudits) {
      expect(audit.metadata).toHaveProperty('runId');
      expect(audit.metadata).toHaveProperty('durationMs');
      expect(audit.metadata.runId).toBe(result.runId);
    }
  });

  it('executes linear workflow to completion', async () => {
    const linearWf: WorkflowStep[] = [
      { id: 'A', type: 'action', action: 'a', params: { moduleId: 'mod1' } },
      { id: 'B', type: 'action', action: 'b', dependsOn: ['A'], params: { moduleId: 'mod1' } },
      { id: 'C', type: 'action', action: 'c', dependsOn: ['B'], params: { moduleId: 'mod1' } },
    ];
    service.setWorkflowSteps(linearWf);

    const result = await service.run({
      tenantId: 'tenant-1',
      workflowId: 'linear-wf',
      triggeredBy: 'user-1',
      initialContext: {},
    });

    expect(result.finalState).toBe('completed');
    expect(result.history).toHaveLength(3);
    expect(result.history.every((h) => h.status === 'success')).toBe(true);

    const calls = actionDispatcher.getCalls();
    expect(calls.map((c) => c.actionId)).toEqual(['a', 'b', 'c']);

    const completedAudits = auditLogEntries.filter((e) => e.action === 'workflow.step.completed');
    expect(completedAudits).toHaveLength(3);
  });

  it('rejects invalid DAG at runtime', async () => {
    const cyclicWf: WorkflowStep[] = [
      { id: 'A', type: 'action', action: 'a', dependsOn: ['B'] },
      { id: 'B', type: 'action', action: 'b', dependsOn: ['A'] },
    ];
    service.setWorkflowSteps(cyclicWf);

    await expect(
      service.run({
        tenantId: 'tenant-1',
        workflowId: 'cyclic-wf',
        triggeredBy: 'user-1',
        initialContext: {},
      }),
    ).rejects.toThrow(/invalid/i);
  });
});
