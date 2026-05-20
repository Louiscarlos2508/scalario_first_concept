import { WorkflowDefinitionZod } from '../validators/index';
import validComplete from '../../../../../catalog/schemas/examples/workflow/valid_complete.json';
import validSimple from '../../../../../catalog/schemas/examples/workflow/valid_simple.json';

describe('WorkflowDefinitionZod', () => {
  describe('valid inputs', () => {
    it('accepts valid complete workflow', () => {
      const result = WorkflowDefinitionZod.safeParse(validComplete);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('wf_order_approval');
        expect(result.data.schema_version).toBe('1.0.0');
        expect(result.data.initial_state).toBe('pending');
        expect(Object.keys(result.data.states)).toContain('pending');
        expect(Object.keys(result.data.states)).toContain('approved');
      }
    });

    it('accepts valid simple workflow', () => {
      const result = WorkflowDefinitionZod.safeParse(validSimple);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('wf_checkout');
        expect(result.data.initial_state).toBe('draft');
      }
    });

    it('accepts workflow with steps', () => {
      const wf = {
        id: 'wf_test',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: { start: { transitions: { go: 'end' } }, end: { final: true } },
        steps: {
          do_thing: {
            id: 'do_thing',
            type: 'action',
            action: 'crud.create',
            next: 'end',
          },
        },
      };
      const result = WorkflowDefinitionZod.safeParse(wf);
      expect(result.success).toBe(true);
    });

    it('accepts workflow with conditional next', () => {
      const wf = {
        id: 'wf_cond',
        schema_version: '1.0.0',
        initial_state: 'pending',
        states: {
          pending: { transitions: { approve: 'approved', reject: 'rejected' } },
          approved: { final: true },
          rejected: { final: true },
        },
        steps: {
          step1: {
            id: 'step1',
            type: 'condition',
            next: {
              rules: [
                { condition: { operator: '==', field: 'amount', value: 100 }, next: 'approved' },
              ],
              default: 'rejected',
            },
          },
        },
      };
      const result = WorkflowDefinitionZod.safeParse(wf);
      expect(result.success).toBe(true);
    });

    it('accepts workflow with on_enter and on_exit', () => {
      const wf = {
        id: 'wf_hooks',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: {
          start: {
            transitions: { go: 'end' },
            on_enter: ['notify_admin'],
            on_exit: ['log_transition'],
          },
          end: { final: true },
        },
      };
      const result = WorkflowDefinitionZod.safeParse(wf);
      expect(result.success).toBe(true);
    });
  });

  describe('invalid inputs', () => {
    it('rejects missing wf_ prefix', () => {
      const result = WorkflowDefinitionZod.safeParse({
        id: 'no_prefix',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: { start: { transitions: { go: 'end' } } },
      });
      expect(result.success).toBe(false);
      if (!result.success) {
        const idError = result.error.issues.find((i) => i.path.includes('id'));
        expect(idError).toBeDefined();
      }
    });

    it('rejects empty states', () => {
      const result = WorkflowDefinitionZod.safeParse({
        id: 'wf_empty',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing id', () => {
      const result = WorkflowDefinitionZod.safeParse({
        schema_version: '1.0.0',
        initial_state: 'start',
        states: { start: { transitions: {} } },
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing initial_state', () => {
      const result = WorkflowDefinitionZod.safeParse({
        id: 'wf_test',
        schema_version: '1.0.0',
        states: { start: { transitions: {} } },
      });
      expect(result.success).toBe(false);
    });

    it('rejects additional properties', () => {
      const result = WorkflowDefinitionZod.safeParse({
        id: 'wf_test',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: { start: { transitions: {} } },
        unknown: true,
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid step type', () => {
      const wf = {
        id: 'wf_test',
        schema_version: '1.0.0',
        initial_state: 'start',
        states: { start: { transitions: {} } },
        steps: {
          bad: { id: 'bad', type: 'invalid_type' },
        },
      };
      const result = WorkflowDefinitionZod.safeParse(wf);
      expect(result.success).toBe(false);
    });
  });
});
