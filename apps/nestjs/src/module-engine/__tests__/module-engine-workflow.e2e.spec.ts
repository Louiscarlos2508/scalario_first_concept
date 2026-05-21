/* eslint-disable @typescript-eslint/no-explicit-any */
import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { ModuleEngineController } from '../module-engine.controller';
import { ActionDispatcherService } from '../services/action-dispatcher.service';
import { DataDispatcherService } from '../services/data-dispatcher.service';
import { ModuleResolverService } from '../services/module-resolver.service';
import { IdempotencyService } from '../services/idempotency.service';
import { HandlerRegistry } from '../handlers/handler-registry';
import { AuditLogService } from '../../audit/services/audit-log.service';
import { WorkflowResponseMapper } from '../workflow-response.mapper';
import { WorkflowExecutorService } from '../../workflow/executor/workflow-executor.service';
import { WorkflowFsmService } from '../../workflow/fsm/workflow-fsm.service';
import { WorkflowStateRepository } from '../../workflow/executor/workflow-state.repository';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RbacGuard } from '../../security/guards/rbac.guard';
import { AbacGuard } from '../../security/abac/guards/abac.guard';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

const U = {
  tenant: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee00000002',
  entity: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee00000003',
  runId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeee0001',
  mutation1: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000001',
  mutation2: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000002',
  mutation3: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000003',
  mutation4: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000004',
  mutationIdem: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000010',
  mutationBadWf: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000011',
  mutationBadPayload: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000012',
  mutationNonExistent: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000013',
  mutationDuplicate: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000014',
  mutationIllegal: 'aaaaaaaa-bbbb-4ccc-8ddd-eeee10000015',
};

const moduleConfig = {
  id: 'caisse',
  schema_version: '1.0.0',
  name: 'Caisse',
  entities: [{ name: 'Caisse' }],
  actions: {},
  workflows: {
    workflow_cloture_caisse: { id: 'workflow_cloture_caisse', initial: 'start', states: {} },
  },
  rbac_roles: ['OWNER', 'MANAGER', 'COMMERCIAL'],
  abac_rules: [],
  conflict_strategy: 'server_wins' as const,
};

const execResultAwaiting = {
  runId: U.runId,
  workflowId: 'workflow_cloture_caisse',
  finalState: 'awaiting_approval',
  history: [
    {
      stepId: 'saisie_fond_restant',
      startedAt: '2026-05-20T10:00:00Z',
      completedAt: '2026-05-20T10:00:01Z',
      status: 'success',
      attempts: 1,
    },
  ],
};

const successfulTransResult = {
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

const intermediateTransResults: Record<string, any> = {
  VALIDER: successfulTransResult,
  CONFIRMER: {
    current_state: 'validation_manager',
    previous_state: 'reconciliation',
    event: 'CONFIRMER',
    available_transitions: [
      { event: 'APPROUVER', target: 'cloture_confirmee' },
      { event: 'REJETER', target: 'reconciliation' },
    ],
    is_terminal: false,
    history_length: 2,
  },
  APPROUVER: {
    current_state: 'cloture_confirmee',
    previous_state: 'validation_manager',
    event: 'APPROUVER',
    available_transitions: [],
    is_terminal: true,
    history_length: 4,
  },
};

describe('Module Engine — Workflow E2E', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  let jwtService: JwtService;
  let mockAuditLog: any;
  let mockIdempotency: any;
  let mockWorkflowExecutor: any;
  let mockWorkflowFsm: any;
  let mockStateRepo: any;
  let auditCalls: any[];

  beforeAll(async () => {
    process.env.JWT_SECRET = JWT_SECRET;
    auditCalls = [];

    mockAuditLog = {
      log: jest.fn((entry: any) => {
        auditCalls.push(entry);
        return Promise.resolve(undefined);
      }),
      flush: jest.fn().mockResolvedValue(0),
    };

    mockIdempotency = {
      checkAndReserve: jest.fn().mockResolvedValue({ alreadyDone: false, previousResult: null }),
      markSuccess: jest.fn().mockResolvedValue(undefined),
      markError: jest.fn().mockResolvedValue(undefined),
    };

    mockWorkflowExecutor = {
      run: jest.fn().mockResolvedValue(execResultAwaiting),
    };

    mockWorkflowFsm = {
      transition: jest.fn().mockImplementation((input: any) => {
        const res = intermediateTransResults[input.event] ?? successfulTransResult;
        return Promise.resolve(res);
      }),
      getStatus: jest.fn().mockResolvedValue({
        current_state: 'saisie_fond_restant',
        available_transitions: [{ event: 'VALIDER', target: 'reconciliation' }],
        history: [],
        is_terminal: false,
      }),
    };

    mockStateRepo = {
      findByRunId: jest.fn().mockResolvedValue({
        id: U.runId,
        tenant_id: U.tenant,
        entity_id: U.entity,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'saisie_fond_restant',
        history: [],
      }),
    };

    const mockResolver = {
      resolve: jest.fn().mockResolvedValue(moduleConfig),
      invalidate: jest.fn(),
    };

    const mockDataDispatcher = {
      dispatch: jest.fn().mockResolvedValue({ data: [], total: 0, page: 1, limit: 50 }),
    };

    const mapper = new WorkflowResponseMapper();

    const moduleRef = await Test.createTestingModule({
      providers: [
        ActionDispatcherService,
        { provide: ModuleResolverService, useValue: mockResolver },
        { provide: IdempotencyService, useValue: mockIdempotency },
        { provide: AuditLogService, useValue: mockAuditLog },
        { provide: DataDispatcherService, useValue: mockDataDispatcher },
        { provide: WorkflowResponseMapper, useValue: mapper },
        { provide: WorkflowExecutorService, useValue: mockWorkflowExecutor },
        { provide: WorkflowFsmService, useValue: mockWorkflowFsm },
        { provide: WorkflowStateRepository, useValue: mockStateRepo },
        { provide: HandlerRegistry, useValue: { get: () => null, register: () => {} } },
      ],
      controllers: [ModuleEngineController],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: jest.fn(async (ctx: any) => {
          const req = ctx.switchToHttp().getRequest();
          const authHeader = req.headers.authorization;
          if (authHeader?.startsWith('Bearer ')) {
            try {
              const payload = JSON.parse(
                Buffer.from(authHeader.slice(7).split('.')[1], 'base64url').toString(),
              );
              req.user = {
                user_id: payload.sub,
                tenant_id: payload.tenant_id,
                roles: payload.roles ?? [],
                department_id: payload.department_id ?? null,
                jti: payload.jti ?? '',
                exp: 9999999999,
              };
              return true;
            } catch {
              return false;
            }
          }
          return false;
        }),
      })
      .overrideGuard(RbacGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(AbacGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication();
    await app.init();
    server = app.getHttpServer();
    jwtService = new JwtService({ secret: JWT_SECRET });
  });

  afterAll(async () => {
    await app.close();
  });

  function makeToken(overrides: Record<string, unknown> = {}) {
    return jwtService.sign({
      sub: 'user-1',
      tenant_id: U.tenant,
      roles: ['COMMERCIAL'],
      department_id: null,
      jti: `jti-${Math.random().toString(36).slice(2)}`,
      ...overrides,
    });
  }

  beforeEach(() => {
    auditCalls = [];
    mockIdempotency.checkAndReserve.mockReset();
    mockIdempotency.checkAndReserve.mockResolvedValue({ alreadyDone: false, previousResult: null });
    mockIdempotency.markSuccess.mockReset();
    mockIdempotency.markSuccess.mockResolvedValue(undefined);
    mockWorkflowExecutor.run.mockReset();
    mockWorkflowExecutor.run.mockResolvedValue(execResultAwaiting);
    mockWorkflowFsm.transition.mockReset();
    mockWorkflowFsm.transition.mockImplementation((input: any) => {
      const res = intermediateTransResults[input.event] ?? successfulTransResult;
      return Promise.resolve(res);
    });
    mockWorkflowFsm.getStatus.mockReset();
    mockWorkflowFsm.getStatus.mockResolvedValue({
      current_state: 'saisie_fond_restant',
      available_transitions: [{ event: 'VALIDER', target: 'reconciliation' }],
      history: [],
      is_terminal: false,
    });
    mockStateRepo.findByRunId.mockReset();
    mockStateRepo.findByRunId.mockResolvedValue({
      id: U.runId,
      tenant_id: U.tenant,
      entity_id: U.entity,
      workflow_id: 'workflow_cloture_caisse',
      current_state: 'saisie_fond_restant',
      history: [],
    });
  });

  describe('AC-14 — Full cloture caisse scenario', () => {
    it('starts workflow via POST /:tenant/:moduleId/action and completes 4 transitions', async () => {
      // COMMERCIAL drives steps 1-3 (start + VALIDER + CONFIRMER).
      const commercialToken = await makeToken({ roles: ['COMMERCIAL'] });

      const initialMarkSuccessCalls = mockIdempotency.markSuccess.mock.calls.length;

      // Step 1: Start workflow (COMMERCIAL)
      const res1 = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${commercialToken}`)
        .set('x-client-mutation-id', U.mutation1)
        .send({
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: U.entity,
          client_mutation_id: U.mutation1,
          initial_context: {},
        })
        .expect(201);

      expect(res1.body.current_state).toBe('saisie_fond_restant');
      expect(res1.body.workflow_id).toBe('workflow_cloture_caisse');
      expect(res1.body.run_id).toBe(U.runId);
      expect(res1.body.final_state).toBe('awaiting_approval');
      expect(res1.body.is_terminal).toBe(false);

      // Step 2: Transition VALIDER (COMMERCIAL)
      const res2 = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${commercialToken}`)
        .set('x-client-mutation-id', U.mutation2)
        .send({
          action_type: 'transition_workflow',
          run_id: U.runId,
          event: 'VALIDER',
          params: {},
          client_mutation_id: U.mutation2,
        })
        .expect(201);

      expect(res2.body.current_state).toBe('reconciliation');
      expect(res2.body.previous_state).toBe('saisie_fond_restant');

      // Step 3: Transition CONFIRMER (COMMERCIAL)
      const res3 = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${commercialToken}`)
        .set('x-client-mutation-id', U.mutation3)
        .send({
          action_type: 'transition_workflow',
          run_id: U.runId,
          event: 'CONFIRMER',
          params: {},
          client_mutation_id: U.mutation3,
        })
        .expect(201);

      expect(res3.body.current_state).toBe('validation_manager');

      // Step 4: Transition APPROUVER — spec AC-14 step 7 requires Login MANAGER.
      const managerToken = await makeToken({ roles: ['MANAGER'] });
      const res4 = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${managerToken}`)
        .set('x-client-mutation-id', U.mutation4)
        .send({
          action_type: 'transition_workflow',
          run_id: U.runId,
          event: 'APPROUVER',
          params: {},
          client_mutation_id: U.mutation4,
        })
        .expect(201);

      expect(res4.body.current_state).toBe('cloture_confirmee');
      expect(res4.body.is_terminal).toBe(true);

      // P11 — spec says exactly 4 audit entries (1 start + 3 transitions).
      const workflowAuditCalls = auditCalls.filter(
        (c: any) => c.action === 'start_workflow' || c.action === 'transition_workflow',
      );
      expect(workflowAuditCalls.length).toBe(4);

      // P12 — exactly 4 successful idempotency reservations (one per mutation),
      // never replayed.
      expect(mockIdempotency.markSuccess.mock.calls.length).toBe(initialMarkSuccessCalls + 4);
    });
  });

  describe('AC-15 — Illegal transition returns 409', () => {
    it('returns 409 with available_transitions when event is not allowed', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      class TransDeniedErr extends Error {
        name = 'WorkflowTransitionDeniedError';
        public currentState = 'saisie_fond_restant';
        public availableTransitions = [{ event: 'VALIDER', target: 'reconciliation' }];
        constructor() {
          super(`Transition 'APPROUVER' non autorisee depuis 'saisie_fond_restant'.`);
        }
      }

      mockWorkflowFsm.transition.mockReset();
      mockWorkflowFsm.transition.mockRejectedValue(new TransDeniedErr());

      const res = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationIllegal)
        .send({
          action_type: 'transition_workflow',
          run_id: U.runId,
          event: 'APPROUVER',
          params: {},
          client_mutation_id: U.mutationIllegal,
        })
        .expect(409);

      expect(res.body.error).toBe('WORKFLOW_TRANSITION_DENIED');
      expect(res.body.available_transitions).toEqual(
        expect.arrayContaining([expect.objectContaining({ event: 'VALIDER' })]),
      );
    });
  });

  describe('AC-16 — Idempotence start_workflow', () => {
    it('re-playing same start_workflow returns same run_id from cache without re-executing', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      // Successfully start workflow once
      await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationIdem)
        .send({
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: U.entity,
          client_mutation_id: U.mutationIdem,
          initial_context: {},
        })
        .expect(201);

      const firstRunCalls = mockWorkflowExecutor.run.mock.calls.length;
      const firstMarkSuccessCalls = mockIdempotency.markSuccess.mock.calls.length;

      // Simulate the idempotency cache returning the already-done result.
      // The cache wraps the workflow response in `result` (matching IdempotencyService shape).
      const cachedResponse = {
        run_id: U.runId,
        workflow_id: 'workflow_cloture_caisse',
        current_state: 'saisie_fond_restant',
        is_terminal: false,
        history_length: 1,
        final_state: 'awaiting_approval',
        available_transitions: [],
      };
      mockIdempotency.checkAndReserve.mockImplementation(async () => ({
        alreadyDone: true,
        previousResult: {
          entity: undefined,
          result: cachedResponse,
          mutation_id: U.mutationIdem,
        },
      }));

      // Re-play with same mutationId
      const res2 = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationIdem)
        .send({
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: U.entity,
          client_mutation_id: U.mutationIdem,
          initial_context: {},
        })
        .expect(201);

      expect(res2.body.run_id).toBe(U.runId);
      // Same run_id returned, executor NOT called a 2nd time
      expect(mockWorkflowExecutor.run).toHaveBeenCalledTimes(firstRunCalls);
      // P12: no 2nd sync_mutations write (no 2nd markSuccess)
      expect(mockIdempotency.markSuccess).toHaveBeenCalledTimes(firstMarkSuccessCalls);
    });
  });

  describe('Boundary cases', () => {
    it('returns 400 WORKFLOW_NOT_IN_MODULE for unknown workflow_id', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      const res = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationBadWf)
        .send({
          action_type: 'start_workflow',
          workflow_id: 'unknown_workflow',
          entity_id: U.entity,
          client_mutation_id: U.mutationBadWf,
          initial_context: {},
        })
        .expect(400);

      expect(res.body.error).toBe('WORKFLOW_NOT_IN_MODULE');
    });

    it('returns 400 for invalid payload', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      const res = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationBadPayload)
        .send({
          action_type: 'start_workflow',
          workflow_id: '',
        })
        .expect(400);

      expect(res.body.message).toBeDefined();
    });

    it('returns 404 when run_id does not exist', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      mockStateRepo.findByRunId.mockReset();
      mockStateRepo.findByRunId.mockResolvedValue(null);

      const res = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationNonExistent)
        .send({
          action_type: 'transition_workflow',
          run_id: '00000000-0000-0000-0000-000000000000',
          event: 'VALIDER',
          client_mutation_id: U.mutationNonExistent,
        })
        .expect(404);

      expect(res.body.error).toBe('WORKFLOW_RUN_NOT_FOUND');
    });

    it('returns 409 WORKFLOW_ALREADY_RUNNING on duplicate start', async () => {
      const token = await makeToken({ roles: ['COMMERCIAL'] });

      class AlreadyRunningErr extends Error {
        name = 'WorkflowAlreadyRunningError';
        constructor() {
          super(`Workflow already running`);
        }
      }

      mockWorkflowExecutor.run.mockReset();
      mockWorkflowExecutor.run.mockRejectedValue(new AlreadyRunningErr());

      const res = await request(server)
        .post(`/api/v1/${U.tenant}/caisse/action`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-client-mutation-id', U.mutationDuplicate)
        .send({
          action_type: 'start_workflow',
          workflow_id: 'workflow_cloture_caisse',
          entity_id: U.entity,
          client_mutation_id: U.mutationDuplicate,
          initial_context: {},
        })
        .expect(409);

      expect(res.body.error).toBe('WORKFLOW_ALREADY_RUNNING');
    });
  });
});
