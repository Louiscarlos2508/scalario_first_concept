import { WorkflowFsmService } from '../workflow-fsm.service';
import { FsmBuilder } from '../fsm-builder';
import type { WorkflowFsmDef, TransitionInput } from '../workflow-fsm.types';
import { WorkflowTransitionDeniedError, WorkflowNotStartedError } from '../workflow-fsm.types';

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

class MockWorkflowStateRepository {
  private store = new Map<string, any>();
  private idCounter = 0;

  async findByEntityWorkflow(entityId: string, workflowId: string) {
    const key = `${entityId}:${workflowId}`;
    return this.store.get(key) ?? null;
  }

  async findByEntityAndWorkflow(tenantId: string, entityId: string, workflowId: string) {
    const key = `${tenantId}:${entityId}:${workflowId}`;
    return this.store.get(key) ?? null;
  }

  async create(input: any) {
    const id = input.runId ?? `run-${++this.idCounter}`;
    const entity = {
      id,
      tenant_id: input.tenantId,
      entity_id: input.entityId ?? null,
      workflow_id: input.workflowId,
      current_state: input.currentState,
      history: Array.isArray(input.history) ? input.history : [],
      triggered_by: input.triggeredBy ?? null,
    };
    const key = `${input.entityId}:${input.workflowId}`;
    const keyWithTenant = `${input.tenantId}:${input.entityId}:${input.workflowId}`;
    this.store.set(key, entity);
    this.store.set(keyWithTenant, entity);
    return entity;
  }

  async update(id: string, input: { currentState: string; history: any[] }) {
    for (const [k, v] of this.store.entries()) {
      if (v.id === id) {
        this.store.set(k, { ...v, current_state: input.currentState, history: input.history });
      }
    }
    const found = Array.from(this.store.values()).find((v) => v.id === id);
    return found ?? null;
  }

  async transactionWithLock<T>(
    entityId: string,
    workflowId: string,
    fn: (row: any) => Promise<T>,
  ): Promise<T> {
    const key = `${entityId}:${workflowId}`;
    const row = this.store.get(key);
    if (!row) throw new Error('Not found');
    return fn(row);
  }
}

class MockAuditLogService {
  private logged: any[] = [];
  async log(entry: any) {
    this.logged.push(entry);
  }
  getLogged() {
    return this.logged;
  }
  reset() {
    this.logged = [];
  }
}

describe('WorkflowFsmService', () => {
  let service: WorkflowFsmService;
  let fsmBuilder: FsmBuilder;
  let stateRepo: MockWorkflowStateRepository;
  let auditLog: MockAuditLogService;

  const makeTransitionInput = (overrides: Partial<TransitionInput> = {}): TransitionInput => ({
    tenantId: 'tenant-1',
    moduleId: 'caisse',
    entityId: 'entity-1',
    workflowId: 'workflow_cloture_caisse',
    event: 'VALIDER',
    triggeredBy: 'user-1',
    ...overrides,
  });

  beforeEach(async () => {
    fsmBuilder = new FsmBuilder();
    stateRepo = new MockWorkflowStateRepository();
    auditLog = new MockAuditLogService();
    service = new WorkflowFsmService(stateRepo as any, fsmBuilder, auditLog as any);

    await stateRepo.create({
      runId: 'run-1',
      tenantId: 'tenant-1',
      entityId: 'entity-1',
      workflowId: 'workflow_cloture_caisse',
      triggeredBy: 'user-1',
      currentState: 'saisie_fond_restant',
      history: [],
    });
  });

  describe('buildMachine', () => {
    it('AC-01 — generates a valid AnyStateMachine from JSON', () => {
      const machine = service.buildMachine(clotureCaisseFsmDef);
      expect(machine).toBeDefined();
      expect(machine.id).toBe('workflow_cloture_caisse');
    });
  });

  describe('transition', () => {
    it('AC-06 — legal transition: VALIDER from saisie_fond_restant → reconciliation', async () => {
      const result = await service.transition(
        clotureCaisseFsmDef,
        makeTransitionInput({ event: 'VALIDER' }),
      );
      expect(result.currentState).toBe('reconciliation');
      expect(result.previousState).toBe('saisie_fond_restant');
      expect(result.event).toBe('VALIDER');
      expect(result.isTerminal).toBe(false);
      expect(result.availableTransitions.map((t) => t.event)).toEqual(
        expect.arrayContaining(['CONFIRMER', 'RETOUR']),
      );
    });

    it('AC-06 — illegal transition: APPROUVER from saisie_fond_restant → 409', async () => {
      await expect(
        service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'APPROUVER' })),
      ).rejects.toThrow(WorkflowTransitionDeniedError);

      try {
        await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'APPROUVER' }));
      } catch (err) {
        expect(err).toBeInstanceOf(WorkflowTransitionDeniedError);
        expect((err as WorkflowTransitionDeniedError).currentState).toBe('saisie_fond_restant');
        expect((err as WorkflowTransitionDeniedError).availableTransitions).toHaveLength(1);
        expect((err as WorkflowTransitionDeniedError).availableTransitions[0].event).toBe(
          'VALIDER',
        );
      }
    });

    it('AC-07 — transition to final state returns isTerminal:true', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'CONFIRMER' }));
      const result = await service.transition(
        clotureCaisseFsmDef,
        makeTransitionInput({ event: 'APPROUVER' }),
      );
      expect(result.currentState).toBe('cloture_confirmee');
      expect(result.isTerminal).toBe(true);
    });

    it('AC-19 — retransition to same state (RETOUR) is allowed', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      const result = await service.transition(
        clotureCaisseFsmDef,
        makeTransitionInput({ event: 'RETOUR' }),
      );
      expect(result.currentState).toBe('saisie_fond_restant');
      expect(result.previousState).toBe('reconciliation');
    });

    it('AC-19 — event not declared → 409 (XState ignores silently)', async () => {
      await expect(
        service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'UNKNOWN_EVENT' })),
      ).rejects.toThrow(WorkflowTransitionDeniedError);
    });

    it('throws WorkflowNotStartedError when entity has no workflow state', async () => {
      await expect(
        service.transition(clotureCaisseFsmDef, {
          ...makeTransitionInput(),
          entityId: 'nonexistent',
        }),
      ).rejects.toThrow(WorkflowNotStartedError);
    });

    it('AC-06 — history is appended on each transition', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      const row = await stateRepo.findByEntityWorkflow('entity-1', 'workflow_cloture_caisse');
      expect(row.history).toHaveLength(1);
      expect(row.history[0].event).toBe('VALIDER');
    });

    it('AC-06 — availableTransitions include all legal next events', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      const result = await service.transition(
        clotureCaisseFsmDef,
        makeTransitionInput({ event: 'CONFIRMER' }),
      );
      expect(result.availableTransitions.map((t) => t.event)).toEqual(
        expect.arrayContaining(['APPROUVER', 'REJETER']),
      );
    });
  });

  describe('getStatus', () => {
    it('AC-11 — returns status with current_state, available_transitions, history', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));

      const status = await service.getStatus(
        'tenant-1',
        'entity-1',
        'workflow_cloture_caisse',
        clotureCaisseFsmDef,
      );

      expect(status.current_state).toBe('reconciliation');
      expect(status.available_transitions).toHaveLength(2);
      expect(status.history).toHaveLength(1);
      expect(status.is_terminal).toBe(false);
    });

    it('AC-11 — returns 404 for non-started workflow', async () => {
      await expect(
        service.getStatus(
          'tenant-1',
          'nonexistent',
          'workflow_cloture_caisse',
          clotureCaisseFsmDef,
        ),
      ).rejects.toThrow(WorkflowNotStartedError);
    });

    it('AC-07 — is_terminal:true for terminal states', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'CONFIRMER' }));
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'APPROUVER' }));

      const status = await service.getStatus(
        'tenant-1',
        'entity-1',
        'workflow_cloture_caisse',
        clotureCaisseFsmDef,
      );

      expect(status.current_state).toBe('cloture_confirmee');
      expect(status.is_terminal).toBe(true);
    });

    it('returns empty available_transitions for states with no exits', async () => {
      const def: WorkflowFsmDef = {
        id: 'single_state',
        initial: 'only',
        states: {
          only: { type: 'final' },
        },
      };
      await stateRepo.create({
        runId: 'run-2',
        tenantId: 'tenant-1',
        entityId: 'entity-2',
        workflowId: 'single_state',
        triggeredBy: 'user-1',
        currentState: 'only',
        history: [],
      });

      const status = await service.getStatus('tenant-1', 'entity-2', 'single_state', def);

      expect(status.available_transitions).toHaveLength(0);
    });
  });

  describe('audit logging', () => {
    it('logs workflow.transition on legal transition', async () => {
      await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'VALIDER' }));
      const logged = auditLog.getLogged();
      const transitions = logged.filter((l: any) => l.action === 'workflow.transition');
      expect(transitions).toHaveLength(1);
    });

    it('logs workflow.transition_rejected on illegal transition', async () => {
      try {
        await service.transition(clotureCaisseFsmDef, makeTransitionInput({ event: 'APPROUVER' }));
      } catch {
        /* expected */
      }
      const logged = auditLog.getLogged();
      const rejections = logged.filter((l: any) => l.action === 'workflow.transition_rejected');
      expect(rejections).toHaveLength(1);
    });
  });
});
