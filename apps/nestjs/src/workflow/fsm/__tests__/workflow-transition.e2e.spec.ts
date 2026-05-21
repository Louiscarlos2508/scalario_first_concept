import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { WorkflowController } from '../../workflow.controller';
import { WorkflowFsmService } from '../workflow-fsm.service';
import { FsmBuilder } from '../fsm-builder';
import { FsmValidator } from '../fsm-validator';
import { WorkflowDefinitionResolver } from '../workflow-definition.resolver';
import { WorkflowStateRepository } from '../../executor/workflow-state.repository';
import { AuditLogService } from '../../../audit/services/audit-log.service';
import type { WorkflowFsmDef } from '../workflow-fsm.types';
import { JwtAuthGuard } from '../../../auth/guards/jwt-auth.guard';
import { RbacGuard } from '../../../security/guards/rbac.guard';
import { AbacGuard } from '../../../security/abac/guards/abac.guard';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

const clotureCaisseFsmDef: WorkflowFsmDef = {
  id: 'workflow_cloture_caisse',
  initial: 'saisie_fond_restant',
  states: {
    saisie_fond_restant: {
      on: { VALIDER: 'reconciliation' },
    },
    reconciliation: {
      on: {
        CONFIRMER: 'validation_manager',
        RETOUR: 'saisie_fond_restant',
      },
    },
    validation_manager: {
      on: {
        APPROUVER: 'cloture_confirmee',
        REJETER: 'reconciliation',
      },
    },
    cloture_confirmee: {
      type: 'final',
    },
  },
};

describe('Workflow Transition E2E (in-memory)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  let jwtService: JwtService;
  let stateStore: Map<string, any>;

  beforeAll(async () => {
    process.env.JWT_SECRET = JWT_SECRET;
    stateStore = new Map();

    const mockAuditLog = {
      log: jest.fn().mockResolvedValue(undefined),
      flush: jest.fn().mockResolvedValue(0),
    };

    const mockWorkflowDefResolver = {
      resolveWorkflowId: jest.fn((moduleId: string) => `workflow_${moduleId}`),
      loadFsmDef: jest.fn().mockReturnValue(clotureCaisseFsmDef),
    };

    const mockStateRepo = createMockStateRepo(stateStore);

    const moduleRef = await Test.createTestingModule({
      providers: [
        FsmBuilder,
        FsmValidator,
        WorkflowFsmService,
        { provide: WorkflowStateRepository, useValue: mockStateRepo },
        { provide: AuditLogService, useValue: mockAuditLog },
        { provide: WorkflowDefinitionResolver, useValue: mockWorkflowDefResolver },
      ],
      controllers: [WorkflowController],
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
    app.setGlobalPrefix('api/v1', { exclude: ['health'] });
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
      tenant_id: 'acme',
      roles: ['OWNER'],
      department_id: null,
      jti: `jti-${Math.random().toString(36).slice(2)}`,
      ...overrides,
    });
  }

  function seedState(
    overrides: Partial<{
      id: string;
      tenant_id: string;
      entity_id: string;
      workflow_id: string;
      current_state: string;
      history: any[];
    }> = {},
  ) {
    stateStore.clear();
    const entity: any = {
      id: overrides.id ?? 'run-1',
      tenant_id: overrides.tenant_id ?? 'acme',
      entity_id: overrides.entity_id ?? 'entity-1',
      workflow_id: overrides.workflow_id ?? 'workflow_caisse',
      current_state: overrides.current_state ?? 'saisie_fond_restant',
      history: overrides.history ?? [],
      triggered_by: 'user-1',
    };
    stateStore.set(entity.id, entity);
    return entity;
  }

  describe('POST :tenant/:moduleId/entities/:id/workflow/transition', () => {
    beforeEach(() => {
      seedState();
    });

    it('AC-09 — legal transition returns 200 with next state', async () => {
      const token = await makeToken();

      const res = await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'VALIDER' })
        .expect(200);

      expect(res.body.currentState).toBe('reconciliation');
      expect(res.body.previousState).toBe('saisie_fond_restant');
      expect(res.body.isTerminal).toBe(false);
      expect(res.body.availableTransitions).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ event: 'CONFIRMER' }),
          expect.objectContaining({ event: 'RETOUR' }),
        ]),
      );
    });

    it('AC-10 — illegal transition returns 409 with WORKFLOW_TRANSITION_DENIED', async () => {
      const token = await makeToken();

      const res = await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'APPROUVER' })
        .expect(409);

      expect(res.body.error).toBe('WORKFLOW_TRANSITION_DENIED');
      expect(res.body.current_state).toBe('saisie_fond_restant');
      expect(res.body.available_transitions).toEqual(
        expect.arrayContaining([expect.objectContaining({ event: 'VALIDER' })]),
      );
    });

    it('AC-17 — full cloture caisse scenario: 4 transitions OK, 2 rejected', async () => {
      const token = await makeToken();

      await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'VALIDER' })
        .expect(200)
        .expect((res: any) => {
          expect(res.body.currentState).toBe('reconciliation');
        });

      await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'APPROUVER' })
        .expect(409);

      await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'CONFIRMER' })
        .expect(200)
        .expect((res: any) => {
          expect(res.body.currentState).toBe('validation_manager');
        });

      await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'APPROUVER' })
        .expect(200)
        .expect((res: any) => {
          expect(res.body.currentState).toBe('cloture_confirmee');
          expect(res.body.isTerminal).toBe(true);
        });

      await request(server)
        .post('/api/v1/acme/caisse/entities/entity-1/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'REJETER' })
        .expect(409);
    });

    it('returns 404 when workflow not started for entity', async () => {
      const token = await makeToken();

      await request(server)
        .post('/api/v1/acme/caisse/entities/nonexistent/workflow/transition')
        .set('Authorization', `Bearer ${token}`)
        .send({ event: 'VALIDER' })
        .expect(404);
    });
  });

  describe('GET :tenant/:moduleId/entities/:id/workflow', () => {
    beforeEach(() => {
      seedState({
        id: 'run-2',
        entity_id: 'entity-2',
        current_state: 'reconciliation',
        history: [
          {
            from: 'saisie_fond_restant',
            event: 'VALIDER',
            to: 'reconciliation',
            timestamp: new Date().toISOString(),
            triggered_by: 'user-1',
          },
        ],
      });
    });

    it('AC-11 — returns current state, transitions, history, is_terminal', async () => {
      const token = await makeToken();

      const res = await request(server)
        .get('/api/v1/acme/caisse/entities/entity-2/workflow')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body.current_state).toBe('reconciliation');
      expect(res.body.is_terminal).toBe(false);
      expect(res.body.available_transitions).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ event: 'CONFIRMER' }),
          expect.objectContaining({ event: 'RETOUR' }),
        ]),
      );
      expect(res.body.history).toHaveLength(1);
      expect(res.body.history[0].event).toBe('VALIDER');
    });

    it('returns 404 when no workflow started', async () => {
      const token = await makeToken();

      await request(server)
        .get('/api/v1/acme/caisse/entities/nonexistent/workflow')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });
});

function createMockStateRepo(store: Map<string, any>) {
  return {
    findByEntityWorkflow: jest.fn(async (entityId: string, workflowId: string) => {
      for (const [, v] of store) {
        if (v.entity_id === entityId && v.workflow_id === workflowId) return v;
      }
      return null;
    }),
    findByEntityAndWorkflow: jest.fn(
      async (tenantId: string, entityId: string, workflowId: string) => {
        for (const [, v] of store) {
          if (v.tenant_id === tenantId && v.entity_id === entityId && v.workflow_id === workflowId)
            return v;
        }
        return null;
      },
    ),
    findByRunId: jest.fn(async (runId: string) => store.get(runId) ?? null),
    transactionWithLock: jest.fn(
      async <T>(entityId: string, workflowId: string, fn: (row: any) => Promise<T>): Promise<T> => {
        for (const [, v] of store) {
          if (v.entity_id === entityId && v.workflow_id === workflowId) return fn(v);
        }
        throw new Error('Not found');
      },
    ),
    update: jest.fn(async (id: string, input: { currentState: string; history: any[] }) => {
      const entry = store.get(id);
      if (entry) {
        entry.current_state = input.currentState;
        entry.history = input.history;
      }
      return entry;
    }),
    create: jest.fn(async (input: any) => {
      const entity: any = {
        id: input.runId,
        tenant_id: input.tenantId,
        entity_id: input.entityId ?? null,
        workflow_id: input.workflowId,
        current_state: input.currentState,
        history: input.history ?? [],
        triggered_by: input.triggeredBy ?? null,
      };
      store.set(entity.id, entity);
      return entity;
    }),
  };
}
