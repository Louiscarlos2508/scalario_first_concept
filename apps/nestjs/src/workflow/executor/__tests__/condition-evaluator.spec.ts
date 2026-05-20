import { ConditionEvaluator } from '../condition-evaluator';
import type { ExecutionContext, StepCondition } from '../workflow-executor.types';
import { WorkflowExecutionError } from '../workflow-executor.types';

describe('ConditionEvaluator', () => {
  let evaluator: ConditionEvaluator;

  beforeEach(() => {
    evaluator = new ConditionEvaluator();
  });

  const makeCtx = (data: Record<string, unknown>): ExecutionContext => ({
    runId: 'test-run',
    tenantId: 'tenant-1',
    triggeredBy: 'user-1',
    data,
    stepStatus: new Map(),
    stepOutput: new Map(),
    history: [],
  });

  describe('== operator', () => {
    it('returns true when values are loosely equal (string "5" and number 5)', () => {
      const ctx = makeCtx({ amount: 5 });
      expect(evaluator.evaluate({ field: 'amount', op: '==', value: '5' }, ctx)).toBe(true);
    });

    it('returns true when values are strictly equal', () => {
      const ctx = makeCtx({ status: 'active' });
      expect(evaluator.evaluate({ field: 'status', op: '==', value: 'active' }, ctx)).toBe(true);
    });

    it('returns false when values are not equal', () => {
      const ctx = makeCtx({ status: 'inactive' });
      expect(evaluator.evaluate({ field: 'status', op: '==', value: 'active' }, ctx)).toBe(false);
    });
  });

  describe('!= operator', () => {
    it('returns true when values are not equal', () => {
      const ctx = makeCtx({ status: 'inactive' });
      expect(evaluator.evaluate({ field: 'status', op: '!=', value: 'active' }, ctx)).toBe(true);
    });

    it('returns false when values are loosely equal', () => {
      const ctx = makeCtx({ amount: 5 });
      expect(evaluator.evaluate({ field: 'amount', op: '!=', value: '5' }, ctx)).toBe(false);
    });

    it('returns false when values are equal', () => {
      const ctx = makeCtx({ status: 'active' });
      expect(evaluator.evaluate({ field: 'status', op: '!=', value: 'active' }, ctx)).toBe(false);
    });
  });

  describe('> operator', () => {
    it('returns true when left > right', () => {
      const ctx = makeCtx({ montant: 600000 });
      expect(evaluator.evaluate({ field: 'montant', op: '>', value: 500000 }, ctx)).toBe(true);
    });

    it('returns false when left <= right', () => {
      const ctx = makeCtx({ montant: 500000 });
      expect(evaluator.evaluate({ field: 'montant', op: '>', value: 500000 }, ctx)).toBe(false);
    });
  });

  describe('< operator', () => {
    it('returns true when left < right', () => {
      const ctx = makeCtx({ montant: 100000 });
      expect(evaluator.evaluate({ field: 'montant', op: '<', value: 500000 }, ctx)).toBe(true);
    });
  });

  describe('>= operator', () => {
    it('returns true when left equals right', () => {
      const ctx = makeCtx({ montant: 500000 });
      expect(evaluator.evaluate({ field: 'montant', op: '>=', value: 500000 }, ctx)).toBe(true);
    });

    it('returns true when left is greater', () => {
      const ctx = makeCtx({ montant: 600000 });
      expect(evaluator.evaluate({ field: 'montant', op: '>=', value: 500000 }, ctx)).toBe(true);
    });

    it('returns false when left is less', () => {
      const ctx = makeCtx({ montant: 400000 });
      expect(evaluator.evaluate({ field: 'montant', op: '>=', value: 500000 }, ctx)).toBe(false);
    });
  });

  describe('<= operator', () => {
    it('returns true when left equals right', () => {
      const ctx = makeCtx({ montant: 500000 });
      expect(evaluator.evaluate({ field: 'montant', op: '<=', value: 500000 }, ctx)).toBe(true);
    });

    it('returns false when left is greater', () => {
      const ctx = makeCtx({ montant: 600000 });
      expect(evaluator.evaluate({ field: 'montant', op: '<=', value: 500000 }, ctx)).toBe(false);
    });
  });

  describe('NaN protection', () => {
    it('throws WorkflowExecutionError for non-numeric field value', () => {
      const ctx = makeCtx({ name: 'hello' });
      expect(() => evaluator.evaluate({ field: 'name', op: '>', value: 5 }, ctx)).toThrow(
        WorkflowExecutionError,
      );
    });

    it('throws WorkflowExecutionError for non-numeric comparison target', () => {
      const ctx = makeCtx({ montant: 100 });
      expect(() =>
        evaluator.evaluate({ field: 'montant', op: '>', value: 'notanumber' }, ctx),
      ).toThrow(WorkflowExecutionError);
    });
  });

  describe('dot-path resolution', () => {
    it('resolves nested paths', () => {
      const ctx = makeCtx({ entity: { montant: 750000 } });
      expect(evaluator.evaluate({ field: 'entity.montant', op: '>', value: 500000 }, ctx)).toBe(
        true,
      );
    });

    it('returns undefined for missing paths (throws NaN error for >)', () => {
      const ctx = makeCtx({ entity: {} });
      expect(() =>
        evaluator.evaluate({ field: 'entity.montant', op: '>', value: 500000 }, ctx),
      ).toThrow(WorkflowExecutionError);
    });

    it('resolves deeply nested paths', () => {
      const ctx = makeCtx({ context: { user: { role: 'manager' } } });
      expect(
        evaluator.evaluate({ field: 'context.user.role', op: '==', value: 'manager' }, ctx),
      ).toBe(true);
    });
  });

  describe('unsupported operator', () => {
    it('throws WorkflowExecutionError for unknown operator', () => {
      const ctx = makeCtx({ x: 1 });
      expect(() =>
        evaluator.evaluate({ field: 'x', op: '%' as StepCondition['op'], value: 2 }, ctx),
      ).toThrow(WorkflowExecutionError);
    });
  });
});
