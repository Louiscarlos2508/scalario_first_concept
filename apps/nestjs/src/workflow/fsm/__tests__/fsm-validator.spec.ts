import { FsmValidator } from '../fsm-validator';
import type { WorkflowFsmDef } from '../workflow-fsm.types';
import { Logger } from '@nestjs/common';

const validFsmDef: WorkflowFsmDef = {
  id: 'valid_fsm',
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

describe('FsmValidator', () => {
  let validator: FsmValidator;

  beforeEach(() => {
    Logger.overrideLogger(false);
    validator = new FsmValidator();
  });

  describe('validate', () => {
    it('AC-04 — returns valid:true for a well-formed FSM', () => {
      const result = validator.validate(validFsmDef);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('AC-04 — returns WF_FSM_INVALID when initial does not exist in states', () => {
      const def: WorkflowFsmDef = {
        id: 'bad_initial',
        initial: 'does_not_exist',
        states: {
          only_state: { type: 'final' },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(false);
      expect(result.errors).toHaveLength(2);
      expect(result.errors[0].code).toBe('WF_FSM_INVALID');
      expect(result.errors[0].stepId).toBe('does_not_exist');
    });

    it('AC-04 — returns WF_UNKNOWN_DEPENDENCY when a transition target does not exist', () => {
      const def: WorkflowFsmDef = {
        id: 'bad_target',
        initial: 'start',
        states: {
          start: {
            on: { GO: 'nonexistent' },
          },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(false);
      const depError = result.errors.find((e) => e.code === 'WF_UNKNOWN_DEPENDENCY');
      expect(depError).toBeDefined();
      expect(depError!.target).toBe('nonexistent');
    });

    it('AC-04 — warns (logs) when no final state exists', () => {
      const warnSpy = jest.spyOn(Logger.prototype, 'warn');
      const def: WorkflowFsmDef = {
        id: 'no_final',
        initial: 'start',
        states: {
          start: {},
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(true);
      expect(warnSpy).toHaveBeenCalled();
      warnSpy.mockRestore();
    });

    it('AC-04 — detects unreachable/orphan states', () => {
      const def: WorkflowFsmDef = {
        id: 'orphan_test',
        initial: 'start',
        states: {
          start: {
            on: { GO: 'end' },
          },
          end: {
            type: 'final',
          },
          unreachable: {
            on: { DO: 'end' },
          },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(false);
      const orphanError = result.errors.find((e) => e.stepId === 'unreachable');
      expect(orphanError).toBeDefined();
      expect(orphanError!.code).toBe('WF_FSM_INVALID');
    });

    it('AC-05 — returns WF_FSM_INVALID when missing initial', () => {
      const def: WorkflowFsmDef = {
        id: 'no_initial',
        initial: '',
        states: {
          start: { type: 'final' },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(false);
      expect(result.errors[0].code).toBe('WF_FSM_INVALID');
    });

    it('validates a minimal 2-state FSM correctly', () => {
      const def: WorkflowFsmDef = {
        id: 'minimal',
        initial: 'A',
        states: {
          A: {
            on: { NEXT: 'B' },
          },
          B: {
            type: 'final',
          },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(true);
    });

    it('detects multiple errors in a single definition', () => {
      const def: WorkflowFsmDef = {
        id: 'multi_error',
        initial: 'start',
        states: {
          start: {
            on: {
              GO: 'middle',
              BAD: 'no_exist',
            },
          },
          middle: {
            on: { NEXT: 'also_missing' },
          },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThanOrEqual(2);
    });

    it('accepts states without type:final for workflows that loop back', () => {
      const def: WorkflowFsmDef = {
        id: 'infinite_loop',
        initial: 'step1',
        states: {
          step1: {
            on: { NEXT: 'step2' },
          },
          step2: {
            on: { BACK: 'step1' },
          },
        },
      };
      const result = validator.validate(def);
      expect(result.valid).toBe(true);
    });
  });
});
