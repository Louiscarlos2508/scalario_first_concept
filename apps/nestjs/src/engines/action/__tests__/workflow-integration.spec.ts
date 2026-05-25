/* eslint-disable @typescript-eslint/no-explicit-any */
import { ActionDispatcherService } from '../services/action-dispatcher.service';
import { ModuleResolverService } from '../services/module-resolver.service';
import { IdempotencyService } from '../services/idempotency.service';
import { HandlerRegistry } from '../handlers/handler-registry';
import { AuditLogService } from '../../../core/audit/services/audit-log.service';
import { WorkflowResponseMapper } from '../workflow-response.mapper';
import type { AuthenticatedUser } from '../../../core/auth/interfaces/jwt-payload.interface';

const UUID = {
  user: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee00000001',
  tenant: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee00000002',
  entity: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee00000003',
  mutation1: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000001',
  mutationDup: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000002',
  mutationBadWf: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000003',
  mutationBadZod: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000004',
  mutationAlready: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000005',
  mutationGlobal: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000006',
  mutationTrans1: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000007',
  mutationCross: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000008',
  mutationNotFound: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000009',
  mutationIllegal: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000a',
  mutationTransDup: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000b',
  mutationNoEntity: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000c',
  mutationStd: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000d',
  mutationUnk: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000e',
  mutationBadType: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee1000000f',
  runId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0001',
  runId2: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0002',
  runId3: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0003',
  runOther: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0004',
  runNoEntity: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0005',
  runNonExistent: '00000000-0000-0000-0000-000000000000',
};

describe('ActionDispatcherService — Workflow Integration', () => {
  let service: ActionDispatcherService;
  let resolver: jest.Mocked<ModuleResolverService>;
  let idempotency: jest.Mocked<IdempotencyService>;
  let audit: jest.Mocked<AuditLogService>;
  let mapper: WorkflowResponseMapper;
  let mockWorkflowExecutor: any;
  let mockWorkflowFsm: any;
  let mockStateRepo: any;

  const mockUser: AuthenticatedUser = {
    user_id: UUID.user,
    tenant_id: UUID.tenant,
    roles: ['OWNER'],
    department_id: null,
    jti: 'jti-1',
    exp: 9999999999,
  };

  const mockModuleConfig = {
    id: 'caisse',
    schema_version: '1.0.0',
    name: 'Caisse',
    entities: [{ name: 'Caisse' }],
    actions: {
      creer_caisse: { handler: 'crud.create', entity_type: 'caisse' },
    },
    workflows: {
      workflow_cloture_caisse: { id: 'workflow_cloture_caisse', initial: 'start', states: {} },
    },
    rbac_roles: ['OWNER', 'MANAGER', 'COMMERCIAL'],
    abac_rules: [],
    conflict_strategy: 'server_wins' as const,
  };

  const execResult = {
    runId: UUID.runId,
    workflowId: 'workflow_cloture_caisse',
    finalState: 'awaiting_approval' as const,
    history: [
      {
        stepId: 'saisie_fond_restant',
        startedAt: '2026-05-20T10:00:00Z',
        completedAt: '2026-05-20T10:00:01Z',
        status: 'success' as const,
        attempts: 1,
      },
      {
        stepId: 'reconciliation',
        startedAt: '2026-05-20T10:00:01Z',
        completedAt: '2026-05-20T10:00:02Z',
        status: 'success' as const,
        attempts: 1,
      },
    ],
  };

  const completedExecResult = {
    runId: UUID.runId2,
    workflowId: 'workflow_cloture_caisse',
    finalState: 'completed' as const,
    history: [
      {
        stepId: 'final_step',
        startedAt: '2026-05-20T10:00:00Z',
        completedAt: '2026-05-20T10:00:01Z',
        status: 'success' as const,
        attempts: 1,
      },
    ],
  };

  const failedExecResult = {
    runId: UUID.runId3,
    workflowId: 'workflow_cloture_caisse',
    finalState: 'failed' as const,
    history: [
      {
        stepId: 'broken_step',
        startedAt: '2026-05-20T10:00:00Z',
        completedAt: '2026-05-20T10:00:01Z',
        status: 'failed' as const,
        attempts: 1,
      },
    ],
    error: { stepId: 'broken_step', code: 'STEP_FAILED', message: 'Boom' },
  };

  const transResult = {
    current_state: 'reconciliation',
    previous_state: 'saisie_fond_restant',
    event: 'VALIDER',
    available_transitions: [
      { event: 'CONFIRMER', target: 'validation_manager' },
      { event: 'RETOUR', target: 'saisie_fond_restant' },
    ],
    is_terminal: false,
    history_length: 1,
  };

  beforeEach(() => {
    mapper = new WorkflowResponseMapper();

    resolver = {
      resolve: jest.fn().mockResolvedValue(mockModuleConfig),
      invalidate: jest.fn(),
    } as any;

    idempotency = {
      checkAndReserve: jest.fn().mockResolvedValue({ alreadyDone: false, previousResult: null }),
      markSuccess: jest.fn().mockResolvedValue(undefined),
      markError: jest.fn().mockResolvedValue(undefined),
    } as any;

    audit = {
      log: jest.fn().mockResolvedValue(undefined),
    } as any;

    mockWorkflowExecutor = {
      run: jest.fn().mockResolvedValue(execResult),
    };

    mockWorkflowFsm = {
      transition: jest.fn().mockResolvedValue(transResult),
      getStatus: jest.fn().mockResolvedValue({
        current_state: 'reconciliation',
        available_transitions: [
          { event: 'CONFIRMER', target: 'validation_manager' },
          { event: 'RETOUR', target: 'saisie_fond_restant' },
        ],
        history: [],
        is_terminal: false,
      }),
    };

    mockStateRepo = {
      findByRunId: jest.fn().mockResolvedValue({
        id: UUID.runId,
        tenant_id: UUID.tenant,
        entity_id: UUID.entity,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'saisie_fond_restant',
        history: [],
      }),
    };

    service = new ActionDispatcherService(
      resolver,
      new HandlerRegistry(),
      idempotency,
      audit,
      mapper,
      mockWorkflowExecutor,
      mockWorkflowFsm,
      mockStateRepo,
    );
  });

  describe('WorkflowActionResponse mapping', () => {
    it('AC-04/AC-17 — maps ExecutionResult (awaiting_approval) to WorkflowActionResponse', () => {
      const result = mapper.fromExecutionResult(execResult);
      expect(result.run_id).toBe(UUID.runId);
      expect(result.workflow_id).toBe('workflow_cloture_caisse');
      expect(result.current_state).toBe('reconciliation');
      expect(result.is_terminal).toBe(false);
      expect(result.final_state).toBe('awaiting_approval');
      expect(result.history_length).toBe(2);
      expect(result.error).toBeUndefined();
    });

    it('AC-06 — maps ExecutionResult (completed) with is_terminal: true', () => {
      const result = mapper.fromExecutionResult(completedExecResult);
      expect(result.is_terminal).toBe(true);
      expect(result.final_state).toBe('completed');
      expect(result.current_state).toBe('final_step');
    });

    it('maps ExecutionResult (failed) with error', () => {
      const result = mapper.fromExecutionResult(failedExecResult);
      expect(result.is_terminal).toBe(true);
      expect(result.final_state).toBe('failed');
      expect(result.error).toEqual({
        step_id: 'broken_step',
        code: 'STEP_FAILED',
        message: 'Boom',
      });
    });

    it('AC-07 — fromExecutionResult uses provided availableTransitions for awaiting_approval', () => {
      const transitions = [
        { event: 'APPROUVER', target: 'cloture_confirmee' },
        { event: 'REJETER', target: 'reconciliation' },
      ];
      const result = mapper.fromExecutionResult(execResult, transitions);
      expect(result.available_transitions).toEqual(transitions);
      expect(result.final_state).toBe('awaiting_approval');
      expect(result.is_terminal).toBe(false);
    });

    it('P9 — fromExecutionResult falls back to finalState when history is empty', () => {
      const emptyHistoryResult = {
        runId: UUID.runId,
        workflowId: 'workflow_cloture_caisse',
        finalState: 'completed' as const,
        history: [],
      };
      const result = mapper.fromExecutionResult(emptyHistoryResult);
      expect(result.current_state).toBe('completed');
      expect(result.is_terminal).toBe(true);
    });

    it('maps TransitionResult to WorkflowActionResponse', () => {
      const result = mapper.fromTransitionResult(
        transResult,
        UUID.runId,
        'workflow_cloture_caisse',
      );
      expect(result.run_id).toBe(UUID.runId);
      expect(result.workflow_id).toBe('workflow_cloture_caisse');
      expect(result.current_state).toBe('reconciliation');
      expect(result.previous_state).toBe('saisie_fond_restant');
      expect(result.available_transitions).toHaveLength(2);
      expect(result.is_terminal).toBe(false);
      expect(result.history_length).toBe(1);
    });
  });

  describe('start_workflow routing', () => {
    it('AC-01/AC-17 — routes action_type: "start_workflow" to WorkflowExecutorService.run()', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutation1,
        body: {
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: UUID.entity,
          client_mutation_id: UUID.mutation1,
          initial_context: {},
        },
        user: mockUser,
      });

      expect(mockWorkflowExecutor.run).toHaveBeenCalledWith({
        tenantId: UUID.tenant,
        workflowId: 'workflow_cloture_caisse',
        entityId: UUID.entity,
        triggeredBy: UUID.user,
        initialContext: {},
        clientMutationId: UUID.mutation1,
      });
      expect(result.run_id).toBe(UUID.runId);
      expect(result.workflow_id).toBe('workflow_cloture_caisse');
      expect(result.current_state).toBe('reconciliation');
      expect(result.final_state).toBe('awaiting_approval');
    });

    it('AC-07 — start_workflow on awaiting_approval queries FSM for available_transitions', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });
      mockWorkflowExecutor.run.mockResolvedValue(execResult); // awaiting_approval

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutation1,
        body: {
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: UUID.entity,
          client_mutation_id: UUID.mutation1,
          initial_context: {},
        },
        user: mockUser,
      });

      expect(mockWorkflowFsm.getStatus).toHaveBeenCalledWith(
        UUID.tenant,
        UUID.entity,
        'workflow_cloture_caisse',
      );
      expect(result.available_transitions).toEqual([
        { event: 'CONFIRMER', target: 'validation_manager' },
        { event: 'RETOUR', target: 'saisie_fond_restant' },
      ]);
    });

    it('AC-02 — workflow_id not in module.workflows returns 400 WORKFLOW_NOT_IN_MODULE', async () => {
      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationBadWf,
          body: {
            action_type: 'start_workflow',
            workflow_id: 'non_existent_workflow',
            entity_id: UUID.entity,
            client_mutation_id: UUID.mutationBadWf,
            initial_context: {},
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: {
          error: 'WORKFLOW_NOT_IN_MODULE',
        },
      });
    });

    it('AC-17 — invalid Zod payload returns 400', async () => {
      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationBadZod,
          body: {
            action_type: 'start_workflow',
            workflow_id: '',
            client_mutation_id: 'not-a-uuid',
          } as any,
          user: mockUser,
        }),
      ).rejects.toMatchObject({ status: 400 });
    });

    it('AC-09 — idempotent start_workflow returns cached result', async () => {
      const cachedResponse = {
        run_id: UUID.runId,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'reconciliation',
        is_terminal: false,
        history_length: 2,
        final_state: 'awaiting_approval',
        available_transitions: [],
      };
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: true,
        previousResult: {
          entity: undefined,
          result: cachedResponse as any,
          mutation_id: UUID.mutationDup,
        },
      });

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutationDup,
        body: {
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: UUID.entity,
          client_mutation_id: UUID.mutationDup,
          initial_context: {},
        },
        user: mockUser,
      });

      expect(result.run_id).toBe(UUID.runId);
      expect(mockWorkflowExecutor.run).not.toHaveBeenCalled();
    });

    it('returns 409 WORKFLOW_ALREADY_RUNNING when workflow is already running', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });

      class AlreadyRunningErr extends Error {
        name = 'WorkflowAlreadyRunningError';
        constructor(
          public workflowId: string,
          public entityId: string,
        ) {
          super(`Workflow '${workflowId}' is already running for entity '${entityId}'`);
        }
      }

      mockWorkflowExecutor.run.mockRejectedValue(
        new AlreadyRunningErr('workflow_cloture_caisse', UUID.entity),
      );

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationAlready,
          body: {
            action_type: 'start_workflow',
            workflow_id: 'workflow_cloture_caisse',
            entity_id: UUID.entity,
            client_mutation_id: UUID.mutationAlready,
            initial_context: {},
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: {
          error: 'WORKFLOW_ALREADY_RUNNING',
        },
      });
    });

    it('start_workflow without entity_id (global workflow) works', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });

      mockWorkflowExecutor.run.mockResolvedValue(completedExecResult);

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutationGlobal,
        body: {
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          client_mutation_id: UUID.mutationGlobal,
          initial_context: {},
        },
        user: mockUser,
      });

      expect(mockWorkflowExecutor.run).toHaveBeenCalledWith(
        expect.objectContaining({ entityId: undefined }),
      );
      expect(result.final_state).toBe('completed');
    });
  });

  describe('transition_workflow routing', () => {
    it('AC-01/AC-17 — routes action_type: "transition_workflow" to WorkflowFsmService.transition()', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutationTrans1,
        body: {
          action_type: 'transition_workflow',
          run_id: UUID.runId,
          event: 'VALIDER',
          params: {},
          client_mutation_id: UUID.mutationTrans1,
        },
        user: mockUser,
      });

      expect(mockWorkflowFsm.transition).toHaveBeenCalledWith({
        tenantId: UUID.tenant,
        moduleId: 'caisse',
        entityId: UUID.entity,
        workflowId: 'workflow_cloture_caisse',
        event: 'VALIDER',
        params: {},
        triggeredBy: UUID.user,
      });
      expect(result.run_id).toBe(UUID.runId);
      expect(result.current_state).toBe('reconciliation');
      expect(result.previous_state).toBe('saisie_fond_restant');
    });

    it('AC-03 — run_id from another module returns 404 (cross-module isolation)', async () => {
      mockStateRepo.findByRunId.mockResolvedValue({
        id: UUID.runId,
        tenant_id: UUID.tenant,
        entity_id: UUID.entity,
        workflow_id: 'workflow_some_other_module',
        current_state: 'saisie_fond_restant',
        history: [],
      });

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationCross,
          body: {
            action_type: 'transition_workflow',
            run_id: UUID.runId,
            event: 'VALIDER',
            params: {},
            client_mutation_id: UUID.mutationCross,
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({ status: 404 });
      // Should not have reserved an idempotency row for a cross-module 4xx
      expect(idempotency.checkAndReserve).not.toHaveBeenCalled();
    });

    it('AC-03/AC-17/P4 — run_id from another tenant returns 404 and does not reserve idempotency', async () => {
      mockStateRepo.findByRunId.mockResolvedValue({
        id: UUID.runOther,
        tenant_id: '00000000-0000-0000-0000-000000000099',
        entity_id: UUID.entity,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'start',
        history: [],
      });

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationCross,
          body: {
            action_type: 'transition_workflow',
            run_id: UUID.runOther,
            event: 'VALIDER',
            params: {},
            client_mutation_id: UUID.mutationCross,
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({ status: 404 });
      // P4: validation 4xx must run BEFORE checkAndReserve to avoid pending row stuck.
      expect(idempotency.checkAndReserve).not.toHaveBeenCalled();
    });

    it('returns 404 when run_id not found', async () => {
      mockStateRepo.findByRunId.mockResolvedValue(null);

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationNotFound,
          body: {
            action_type: 'transition_workflow',
            run_id: UUID.runNonExistent,
            event: 'VALIDER',
            params: {},
            client_mutation_id: UUID.mutationNotFound,
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({ status: 404 });
    });

    it('AC-15/AC-17 — transition denied returns 409 with available_transitions', async () => {
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: false,
        previousResult: null,
      });

      class TransDeniedErr extends Error {
        name = 'WorkflowTransitionDeniedError';
        public currentState = 'saisie_fond_restant';
        public availableTransitions = [{ event: 'VALIDER', target: 'reconciliation' }];
        constructor(event: string, currentState: string) {
          super(`Transition '${event}' non autorisee depuis '${currentState}'.`);
        }
      }

      mockWorkflowFsm.transition.mockRejectedValue(
        new TransDeniedErr('APPROUVER', 'saisie_fond_restant'),
      );

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationIllegal,
          body: {
            action_type: 'transition_workflow',
            run_id: UUID.runId,
            event: 'APPROUVER',
            params: {},
            client_mutation_id: UUID.mutationIllegal,
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: {
          error: 'WORKFLOW_TRANSITION_DENIED',
          available_transitions: [{ event: 'VALIDER', target: 'reconciliation' }],
        },
      });
    });

    it('AC-09 — idempotent transition_workflow returns cached result', async () => {
      const cachedResponse = {
        run_id: UUID.runId,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'reconciliation',
        previous_state: 'saisie_fond_restant',
        available_transitions: [{ event: 'CONFIRMER', target: 'validation_manager' }],
        is_terminal: false,
        history_length: 1,
      };
      idempotency.checkAndReserve.mockResolvedValue({
        alreadyDone: true,
        previousResult: {
          entity: undefined,
          result: cachedResponse as any,
          mutation_id: UUID.mutationTransDup,
        },
      });

      const result: any = await service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'caisse',
        mutationId: UUID.mutationTransDup,
        body: {
          action_type: 'transition_workflow',
          run_id: UUID.runId,
          event: 'VALIDER',
          params: {},
          client_mutation_id: UUID.mutationTransDup,
        },
        user: mockUser,
      });

      expect(result.current_state).toBe('reconciliation');
      expect(mockWorkflowFsm.transition).not.toHaveBeenCalled();
    });

    it('rejects transition on run without entity_id', async () => {
      mockStateRepo.findByRunId.mockResolvedValue({
        id: UUID.runNoEntity,
        tenant_id: UUID.tenant,
        entity_id: null,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'start',
        history: [],
      });

      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationNoEntity,
          body: {
            action_type: 'transition_workflow',
            run_id: UUID.runNoEntity,
            event: 'VALIDER',
            params: {},
            client_mutation_id: UUID.mutationNoEntity,
          },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: { error: 'WORKFLOW_NO_ENTITY' },
      });
    });
  });

  describe('standard action routing (backward compatibility)', () => {
    it('returns 422 for unknown action on standard path', async () => {
      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationUnk,
          body: { action: 'nonexistent', payload: {} },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: { error: 'Unknown action' },
      });
    });

    it('throws BadRequest for unknown action_type', async () => {
      await expect(
        service.dispatch({
          tenantSlug: 'acme',
          moduleId: 'caisse',
          mutationId: UUID.mutationBadType,
          body: { action_type: 'some_unknown_type' as any },
          user: mockUser,
        }),
      ).rejects.toMatchObject({
        response: { error: 'UNKNOWN_ACTION_TYPE' },
      });
    });
  });
});
