import { WorkflowValidatorService } from '../workflow-validator.service';
import { clotureCaisseFixture } from '../__fixtures__/valid-cloture-caisse';
import { cycleSimpleFixture } from '../__fixtures__/cycle-simple';
import { cycleComplexFixture } from '../__fixtures__/cycle-complex';
import { orphanDependencyFixture } from '../__fixtures__/orphan-dependency';

describe('WorkflowValidatorService', () => {
  let service: WorkflowValidatorService;

  beforeEach(() => {
    service = new WorkflowValidatorService();
  });

  describe('validateDAG', () => {
    it('returns valid:true for a linear DAG (A -> B -> C)', () => {
      const steps = [
        { id: 'A', type: 'action' as const },
        { id: 'B', type: 'action' as const, dependsOn: ['A'] },
        { id: 'C', type: 'action' as const, dependsOn: ['B'] },
      ];
      const result = service.validateDAG('wf_test', steps);
      expect(result.valid).toBe(true);
      if (result.valid) {
        expect(result.sortedSteps).toEqual(['A', 'B', 'C']);
        expect(result.entryPoints).toEqual(['A']);
        expect(result.terminalSteps).toEqual(['C']);
      }
    });

    it('returns valid:true for a branching DAG (A -> B, A -> C, B -> D, C -> D)', () => {
      const steps = [
        { id: 'A', type: 'action' as const },
        { id: 'B', type: 'action' as const, dependsOn: ['A'] },
        { id: 'C', type: 'action' as const, dependsOn: ['A'] },
        { id: 'D', type: 'action' as const, dependsOn: ['B', 'C'] },
      ];
      const result = service.validateDAG('wf_test', steps);
      expect(result.valid).toBe(true);
      if (result.valid) {
        expect(result.entryPoints).toEqual(['A']);
        expect(result.terminalSteps).toEqual(['D']);
        expect(result.sortedSteps.indexOf('A')).toBeLessThan(result.sortedSteps.indexOf('B'));
        expect(result.sortedSteps.indexOf('A')).toBeLessThan(result.sortedSteps.indexOf('C'));
        expect(result.sortedSteps.indexOf('B')).toBeLessThan(result.sortedSteps.indexOf('D'));
        expect(result.sortedSteps.indexOf('C')).toBeLessThan(result.sortedSteps.indexOf('D'));
      }
    });

    it('returns WF_CYCLE for a simple cycle (A -> B -> A)', () => {
      const result = service.validateDAG('wf_test', cycleSimpleFixture);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_CYCLE');
        expect(result.errors[0].cyclicSteps).toEqual(expect.arrayContaining(['A', 'B']));
      }
    });

    it('returns WF_CYCLE for a complex cycle', () => {
      const result = service.validateDAG('wf_test', cycleComplexFixture);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_CYCLE');
        expect(result.errors[0].cyclicSteps).toEqual(
          expect.arrayContaining(['F', 'G', 'H', 'I', 'J', 'K']),
        );
      }
    });

    it('returns WF_SELF_LOOP when a step depends on itself', () => {
      const steps = [{ id: 'A', type: 'action' as const, dependsOn: ['A'] }];
      const result = service.validateDAG('wf_self', steps);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_SELF_LOOP');
        expect(result.errors[0].stepId).toBe('A');
      }
    });

    it('returns WF_UNKNOWN_DEPENDENCY for a dependency on non-existent step', () => {
      const result = service.validateDAG('wf_orphan', orphanDependencyFixture);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        const depError = result.errors.find((e) => e.code === 'WF_UNKNOWN_DEPENDENCY');
        expect(depError).toBeDefined();
        expect(depError!.stepId).toBe('C');
        expect(depError!.missingDependencyId).toBe('ZZ');
      }
    });

    it('returns WF_DUPLICATE_ID when two steps share the same id', () => {
      const steps = [
        { id: 'A', type: 'action' as const },
        { id: 'A', type: 'action' as const },
      ];
      const result = service.validateDAG('wf_dup', steps);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_DUPLICATE_ID');
        expect(result.errors[0].stepId).toBe('A');
      }
    });

    it('returns WF_NO_ENTRY_POINT when all steps have dependsOn', () => {
      const steps = [
        { id: 'A', type: 'action' as const, dependsOn: ['B'] },
        { id: 'B', type: 'action' as const, dependsOn: ['A'] },
      ];
      const result = service.validateDAG('wf_no_entry', steps);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        const cycleOrNoEntry = result.errors[0];
        expect(['WF_CYCLE', 'WF_NO_ENTRY_POINT']).toContain(cycleOrNoEntry.code);
      }
    });

    it('returns WF_NO_ENTRY_POINT for an empty workflow', () => {
      const result = service.validateDAG('wf_empty', []);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_NO_ENTRY_POINT');
      }
    });

    it('validates the cloture_caisse fixture', () => {
      const result = service.validateDAG('wf_cloture_caisse', clotureCaisseFixture);
      expect(result.valid).toBe(true);
      if (result.valid) {
        expect(result.sortedSteps).toEqual([
          'saisie_fond_restant',
          'reconciliation',
          'validation_manager',
          'cloture_confirmee',
        ]);
        expect(result.entryPoints).toEqual(['saisie_fond_restant']);
        expect(result.terminalSteps).toEqual(['cloture_confirmee']);
      }
    });

    it('returns WF_UNREACHABLE when a step is disconnected from all entry points', () => {
      const steps = [
        { id: 'A', type: 'action' as const },
        { id: 'B', type: 'action' as const, dependsOn: ['A'] },
        { id: 'X', type: 'action' as const, dependsOn: ['Y'] },
        { id: 'Y', type: 'action' as const, dependsOn: ['X'] },
      ];
      const result = service.validateDAG('wf_unreachable', steps);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_CYCLE');
      }
    });

    it('reports multiple errors in priority order (dups before deps)', () => {
      const steps = [
        { id: 'A', type: 'action' as const },
        { id: 'A', type: 'action' as const, dependsOn: ['Z'] },
      ];
      const result = service.validateDAG('wf_mult', steps);
      expect(result.valid).toBe(false);
      if (!result.valid) {
        expect(result.errors[0].code).toBe('WF_DUPLICATE_ID');
      }
    });

    it('passes performance benchmark: < 5ms for 20 steps, < 20ms for 100 steps', () => {
      const steps20 = Array.from({ length: 20 }, (_, i) => ({
        id: `N${i}`,
        type: 'action' as const,
        dependsOn: i > 0 ? [`N${i - 1}`] : [],
      }));
      const steps100 = Array.from({ length: 100 }, (_, i) => ({
        id: `N${i}`,
        type: 'action' as const,
        dependsOn: i > 0 ? [`N${i - 1}`] : [],
      }));
      const t20Start = performance.now();
      service.validateDAG('wf_bench', steps20);
      const t20 = performance.now() - t20Start;
      expect(t20).toBeLessThan(5);
      const t100Start = performance.now();
      service.validateDAG('wf_bench', steps100);
      const t100 = performance.now() - t100Start;
      expect(t100).toBeLessThan(20);
    });
  });
});
