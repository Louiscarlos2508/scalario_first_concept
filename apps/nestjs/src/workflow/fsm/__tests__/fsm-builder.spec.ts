import { FsmBuilder } from '../fsm-builder';
import type { WorkflowFsmDef } from '../workflow-fsm.types';

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

const minimalFsmDef: WorkflowFsmDef = {
  id: 'minimal',
  initial: 'start',
  states: {
    start: {
      on: { GO: 'end' },
    },
    end: {
      type: 'final',
    },
  },
};

describe('FsmBuilder', () => {
  let builder: FsmBuilder;

  beforeEach(() => {
    builder = new FsmBuilder();
  });

  describe('build', () => {
    it('AC-01 — generates a valid XState machine from JSON definition', () => {
      const machine = builder.build(minimalFsmDef);
      expect(machine).toBeDefined();
      expect(machine.id).toBe('minimal');
    });

    it('AC-03 — machine is deterministic: resolveState returns correct value for initial state', () => {
      const machine = builder.build(clotureCaisseFsmDef);
      const resolved = machine.resolveState({ value: 'saisie_fond_restant' } as any);
      expect(resolved.value).toBe('saisie_fond_restant');
    });

    it('returns a machine with the correct initial state', () => {
      const machine = builder.build(clotureCaisseFsmDef);
      expect(machine.id).toBe('workflow_cloture_caisse');
      const resolved = machine.resolveState({ value: 'saisie_fond_restant' } as any);
      expect(resolved.value).toBe('saisie_fond_restant');
    });

    it('handles states with no "on" transitions', () => {
      const def: WorkflowFsmDef = {
        id: 'no_transitions',
        initial: 'idle',
        states: {
          idle: {},
          final: { type: 'final' },
        },
      };
      const machine = builder.build(def);
      expect(machine).toBeDefined();
      const resolved = machine.resolveState({ value: 'idle' } as any);
      expect(resolved.value).toBe('idle');
    });

    it('handles states with meta data', () => {
      const def: WorkflowFsmDef = {
        id: 'with_meta',
        initial: 'step1',
        states: {
          step1: {
            meta: { i18n_key: 'step.one', ui_step_id: 'ui-1' },
            on: { NEXT: 'step2' },
          },
          step2: {
            type: 'final',
            meta: { i18n_key: 'step.two' },
          },
        },
      };
      const machine = builder.build(def);
      expect(machine).toBeDefined();
      const resolved = machine.resolveState({ value: 'step1' } as any);
      expect(resolved.value).toBe('step1');
    });

    it('transitions correctly with string targets', () => {
      const machine = builder.build(clotureCaisseFsmDef);
      const resolved = machine.resolveState({ value: 'saisie_fond_restant' } as any);
      const transitions = machine.getTransitionData(resolved, { type: 'VALIDER' } as any);
      expect(transitions.length).toBeGreaterThan(0);
    });
  });
});
