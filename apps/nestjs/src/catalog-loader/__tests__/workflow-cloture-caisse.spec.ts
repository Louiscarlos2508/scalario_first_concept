import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { transition } from 'xstate';
import { CatalogueValidatorService } from '../services/catalogue-validator.service';
import { WorkflowValidatorService } from '../../engines/workflow/validator/workflow-validator.service';
import { FsmBuilder } from '../../engines/workflow/fsm/fsm-builder';
import { FsmValidator } from '../../engines/workflow/fsm/fsm-validator';
import type { WorkflowFsmDef } from '../../engines/workflow/fsm/workflow-fsm.types';

const WF_ID = 'wf_cloture_caisse';

/**
 * On-disk catalogue JSON shape (per workflow.zod.ts in catalogue/).
 * The runtime XState builder (workflow-fsm.types.ts) uses a different
 * shape (`initial` + `on` + `type: 'final'`). This is a known schema
 * mismatch between the catalogue contract and the FSM internal type;
 * the WorkflowDefinitionResolver casts blindly today. Until that's
 * unified, the test contains the adapter explicitly.
 */
interface CatalogueWorkflowJson {
  id: string;
  schema_version: '1.0.0';
  initial_state: string;
  states: Record<
    string,
    {
      transitions?: Record<string, string>;
      final?: boolean;
      on_enter?: string[];
      on_exit?: string[];
    }
  >;
  steps?: Record<string, unknown>;
}

function resolveWorkflowPath(): string {
  const candidates = [
    resolve(process.cwd(), 'catalog', 'workflows', `${WF_ID}.json`),
    resolve(process.cwd(), '..', '..', 'catalog', 'workflows', `${WF_ID}.json`),
  ];
  for (const p of candidates) {
    try {
      readFileSync(p, 'utf8');
      return p;
    } catch {
      /* try next */
    }
  }
  throw new Error(`Workflow not found: ${WF_ID}`);
}

function loadWorkflow(): CatalogueWorkflowJson {
  return JSON.parse(readFileSync(resolveWorkflowPath(), 'utf8')) as CatalogueWorkflowJson;
}

/**
 * Adapter: convert the on-disk catalogue shape to the runtime FsmBuilder
 * shape. To be moved into WorkflowDefinitionResolver as a follow-up
 * cleanup once the schema unification is scheduled.
 */
function toFsmDef(wf: CatalogueWorkflowJson): WorkflowFsmDef {
  const states: WorkflowFsmDef['states'] = {};
  for (const [name, def] of Object.entries(wf.states)) {
    states[name] = {
      ...(def.transitions ? { on: def.transitions } : {}),
      ...(def.final ? { type: 'final' as const } : {}),
    };
  }
  return { id: wf.id, initial: wf.initial_state, states };
}

describe('STORY-041 — workflow_cloture_caisse', () => {
  const validator = new CatalogueValidatorService(new WorkflowValidatorService());
  const fsmBuilder = new FsmBuilder();
  const fsmValidator = new FsmValidator();

  describe('AC-01/AC-02 — workflow JSON metadata', () => {
    it('parses + has correct id, schema_version, initial_state', () => {
      const wf = loadWorkflow();
      expect(wf.id).toBe(WF_ID);
      expect(wf.schema_version).toBe('1.0.0');
      expect(wf.initial_state).toBe('saisie_fond_restant');
    });

    it('validates via CatalogueValidatorService as type=workflow', () => {
      const result = validator.validateFile(resolveWorkflowPath(), 'workflow');
      if (!result.valid) {
        const summary =
          result.errors?.map((e) => `[${e.path}] ${e.message}`).join('; ') ?? result.parseError;
        throw new Error(`workflow failed validation: ${summary}`);
      }
      expect(result.valid).toBe(true);
    });
  });

  describe('AC-03 — 5 FSM states declared', () => {
    it('has the 5 named states', () => {
      const wf = loadWorkflow();
      const stateNames = Object.keys(wf.states).sort();
      expect(stateNames).toEqual([
        'cloture_confirmee',
        'litige',
        'reconciliation_auto',
        'saisie_fond_restant',
        'validation_manager',
      ]);
    });

    it('cloture_confirmee + litige are final', () => {
      const wf = loadWorkflow();
      expect(wf.states.cloture_confirmee.final).toBe(true);
      expect(wf.states.litige.final).toBe(true);
    });

    it('non-final states have transitions defined', () => {
      const wf = loadWorkflow();
      expect(wf.states.saisie_fond_restant.transitions).toBeDefined();
      expect(wf.states.reconciliation_auto.transitions).toBeDefined();
      expect(wf.states.validation_manager.transitions).toBeDefined();
    });
  });

  describe('AC-13 — legal transitions matrix', () => {
    it('saisie_fond_restant --SUBMIT--> reconciliation_auto', () => {
      const wf = loadWorkflow();
      expect(wf.states.saisie_fond_restant.transitions?.SUBMIT).toBe('reconciliation_auto');
    });

    it('reconciliation_auto --AUTO_PASS--> cloture_confirmee', () => {
      const wf = loadWorkflow();
      expect(wf.states.reconciliation_auto.transitions?.AUTO_PASS).toBe('cloture_confirmee');
    });

    it('reconciliation_auto --AUTO_REQUIRE_VALIDATION--> validation_manager', () => {
      const wf = loadWorkflow();
      expect(wf.states.reconciliation_auto.transitions?.AUTO_REQUIRE_VALIDATION).toBe(
        'validation_manager',
      );
    });

    it('validation_manager --VALIDATE--> cloture_confirmee', () => {
      const wf = loadWorkflow();
      expect(wf.states.validation_manager.transitions?.VALIDATE).toBe('cloture_confirmee');
    });

    it('validation_manager --REQUEST_CORRECTION--> saisie_fond_restant', () => {
      const wf = loadWorkflow();
      expect(wf.states.validation_manager.transitions?.REQUEST_CORRECTION).toBe(
        'saisie_fond_restant',
      );
    });

    it('validation_manager --REJECT--> litige', () => {
      const wf = loadWorkflow();
      expect(wf.states.validation_manager.transitions?.REJECT).toBe('litige');
    });
  });

  describe('AC-12 — XState FSM builds from JSON (via adapter)', () => {
    it('FsmBuilder.build() produces a machine with 5 states', () => {
      const wf = loadWorkflow();
      const machine = fsmBuilder.build(toFsmDef(wf));
      expect(machine).toBeDefined();
      const machineStateNodes = Object.keys(
        (machine as { states: Record<string, unknown> }).states,
      );
      expect(machineStateNodes.sort()).toEqual([
        'cloture_confirmee',
        'litige',
        'reconciliation_auto',
        'saisie_fond_restant',
        'validation_manager',
      ]);
    });

    it('initial state of the built machine is saisie_fond_restant', () => {
      const wf = loadWorkflow();
      const machine = fsmBuilder.build(toFsmDef(wf));
      const initialSnapshot = machine.resolveState({
        value: wf.initial_state,
      } as Parameters<typeof machine.resolveState>[0]);
      expect(initialSnapshot.value).toBe('saisie_fond_restant');
    });
  });

  describe('AC-14 — illegal transitions rejected by FSM', () => {
    it('cloture_confirmee --SUBMIT--> nothing (terminal state)', () => {
      const wf = loadWorkflow();
      const machine = fsmBuilder.build(toFsmDef(wf));
      const terminal = machine.resolveState({
        value: 'cloture_confirmee',
      } as Parameters<typeof machine.resolveState>[0]);

      const [nextSnapshot] = transition(machine, terminal, { type: 'SUBMIT' });
      // Terminal states ignore events — value stays the same.
      expect(nextSnapshot.value).toBe('cloture_confirmee');
    });

    it('saisie_fond_restant --VALIDATE--> nothing (event not in transitions)', () => {
      const wf = loadWorkflow();
      const machine = fsmBuilder.build(toFsmDef(wf));
      const initial = machine.resolveState({
        value: 'saisie_fond_restant',
      } as Parameters<typeof machine.resolveState>[0]);

      const [nextSnapshot] = transition(machine, initial, { type: 'VALIDATE' });
      expect(nextSnapshot.value).toBe('saisie_fond_restant');
    });
  });

  describe('AC-09/AC-10/AC-11 — FSM structural validation', () => {
    it('FsmValidator passes on the live workflow file', () => {
      const wf = loadWorkflow();
      const result = fsmValidator.validate(toFsmDef(wf));
      if (!result.valid) {
        throw new Error(
          `FSM validation failed: ${result.errors.map((e) => `[${e.code}] ${e.message}`).join('; ')}`,
        );
      }
      expect(result.valid).toBe(true);
    });

    it('AC-10 negative — removing cloture_confirmee makes validation_manager.VALIDATE point to missing state', () => {
      const wf = loadWorkflow();
      const def = toFsmDef(wf);
      delete (def.states as Record<string, unknown>).cloture_confirmee;
      const result = fsmValidator.validate(def);
      expect(result.valid).toBe(false);
    });

    it('AC-11 — FsmValidator returns deterministic result shape on stripped final flag', () => {
      const wf = loadWorkflow();
      const def = toFsmDef(wf);
      // Drop the `type: 'final'` marker on litige to simulate a non-terminal
      // sink. The validator must return a result object (not throw) so the
      // catalogue CI step can report consistently.
      delete (def.states.litige as Record<string, unknown>).type;
      const result = fsmValidator.validate(def);
      expect(typeof result.valid).toBe('boolean');
      expect(Array.isArray(result.errors)).toBe(true);
    });
  });

  describe('AC-25/AC-26/AC-27 — Global Scale + i18n hygiene', () => {
    it('the workflow JSON does not hardcode XOF / FCFA / Wave', () => {
      const raw = readFileSync(resolveWorkflowPath(), 'utf8');
      expect(raw).not.toMatch(/XOF/);
      expect(raw).not.toMatch(/FCFA/i);
      expect(raw).not.toMatch(/\bWave\b/);
      expect(raw).not.toMatch(/Orange Money/i);
    });

    it('the cloture_auto_threshold reference uses tenant.config namespace', () => {
      const raw = readFileSync(resolveWorkflowPath(), 'utf8');
      // Either as a JSON value reference (string) or a steps.next.rules condition.
      expect(raw).toContain('tenant.config.cloture_auto_threshold');
    });
  });
});
