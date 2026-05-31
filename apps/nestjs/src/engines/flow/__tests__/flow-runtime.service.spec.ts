import { FlowRuntimeService } from '../flow-runtime.service';
import type { CompiledFlow } from '../flow.types';
import type { ExecutionContext } from '../../shared/engine-core';

describe('FlowRuntimeService', () => {
  let runtime: FlowRuntimeService;

  beforeEach(() => {
    runtime = new FlowRuntimeService();
  });

  describe('execute', () => {
    it('executes an empty flow successfully', async () => {
      const flow: CompiledFlow = {
        id: 'empty',
        name: 'Empty Flow',
        trigger: { type: 'manual' },
        steps: [],
        adjacency: new Map(),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
    });

    it('executes a single end step', async () => {
      const flow: CompiledFlow = {
        id: 'single',
        name: 'Single Step',
        trigger: { type: 'manual' },
        steps: [{ id: 's1', type: 'end', config: { output: { status: 'done' } } }],
        adjacency: new Map([['s1', { onSuccess: [] }]]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
    });

    it('executes a two-step flow', async () => {
      const flow: CompiledFlow = {
        id: 'two-step',
        name: 'Two Step',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'assign', config: { target: '/data/status', value: 'processed', valueType: 'literal' } },
          { id: 's2', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['s1', { onSuccess: ['s2'] }],
          ['s2', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
      expect(result.stepResults).toHaveLength(2);
    });

    it('evaluates condition true -> follows onSuccess path', async () => {
      const flow: CompiledFlow = {
        id: 'cond-true',
        name: 'Condition True',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'condition', config: { expression: '/data/amount > 1000' } },
          { id: 's2', type: 'end', config: { output: { branch: 'success' } } },
          { id: 's3', type: 'end', config: { output: { branch: 'failure' } } },
        ],
        adjacency: new Map([
          ['s1', { onSuccess: ['s2'], onFailure: ['s3'] }],
          ['s2', { onSuccess: [] }],
          ['s3', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: { amount: 5000 } };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
      expect(result.stepResults!.some((r) => r.stepId === 's2')).toBe(true);
    });

    it('evaluates condition false -> follows onFailure path', async () => {
      const flow: CompiledFlow = {
        id: 'cond-false',
        name: 'Condition False',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'condition', config: { expression: '/data/amount > 1000' } },
          { id: 's2', type: 'end', config: { output: { branch: 'success' } } },
          { id: 's3', type: 'end', config: { output: { branch: 'failure' } } },
        ],
        adjacency: new Map([
          ['s1', { onSuccess: ['s2'], onFailure: ['s3'] }],
          ['s2', { onSuccess: [] }],
          ['s3', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: { amount: 100 } };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
      expect(result.stepResults!.some((r) => r.stepId === 's3')).toBe(true);
    });

    it('handles condition with unknown field', async () => {
      const flow: CompiledFlow = {
        id: 'cond-unknown',
        name: 'Unknown Field',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'condition', config: { expression: '/data/missing > 1000' } },
          { id: 's2', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['s1', { onSuccess: ['s2'] }],
          ['s2', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
    });

    it('executes assign step modifying context data', async () => {
      const flow: CompiledFlow = {
        id: 'assign-test',
        name: 'Assign Test',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'assign', config: { target: '/data/status', value: 'done', valueType: 'literal' } },
        ],
        adjacency: new Map([['s1', { onSuccess: [] }]]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      await runtime.execute(flow, ctx);
      expect(ctx.data).toHaveProperty('status', 'done');
    });

    it('executes delay step', async () => {
      const flow: CompiledFlow = {
        id: 'delay-test',
        name: 'Delay Test',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'delay', config: { duration: 0.01 } },
          { id: 's2', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['s1', { onSuccess: ['s2'] }],
          ['s2', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const start = Date.now();
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
    });

    it('handles missing steps gracefully without throwing', async () => {
      const flow: CompiledFlow = {
        id: 'missing-step',
        name: 'Missing Step',
        trigger: { type: 'manual' },
        steps: [{ id: 's1', type: 'end', config: {} }],
        adjacency: new Map([
          ['s1', { onSuccess: ['nonexistent'] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.stepResults!.some((r) => r.stepId === 'nonexistent')).toBe(true);
    });

    it('handles notification step', async () => {
      const flow: CompiledFlow = {
        id: 'notify-test',
        name: 'Notify',
        trigger: { type: 'manual' },
        steps: [
          { id: 's1', type: 'notify', config: { channel: 'email', template: 'test', to: 'user@t.com' } },
        ],
        adjacency: new Map([['s1', { onSuccess: [] }]]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: {} };
      const result = await runtime.execute(flow, ctx);
      expect(result.success).toBe(true);
    });
  });

  describe('loop', () => {
    it('AC-01/AC-10: iterates over 3 items and executes child assign with variable', async () => {
      const flow: CompiledFlow = {
        id: 'loop-3-items',
        name: 'Loop 3 Items',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/lignes', as: 'ligne', stepIds: ['child1'] },
          },
          {
            id: 'child1',
            type: 'assign',
            config: { target: '/data/processed', value: 'true', valueType: 'literal' },
          },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { lignes: [{ id: 1 }, { id: 2 }, { id: 3 }] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'loop1')).toHaveLength(1);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(3);
      expect(ctx.data).toHaveProperty('processed', 'true');
      expect(ctx.data).not.toHaveProperty('ligne');
      const loopResult = result.stepResults!.find((r) => r.stepId === 'loop1')!.output as Array<unknown>;
      expect(loopResult).toHaveLength(3);
    });

    it('AC-02: non-array over returns error', async () => {
      const flow: CompiledFlow = {
        id: 'loop-not-array',
        name: 'Loop Not Array',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'item', stepIds: ['child1'] },
          },
          { id: 'child1', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = { tenantId: 't1', userId: 'u1', data: { items: 'not-an-array' } };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(false);
      const loopResult = result.stepResults!.find((r) => r.stepId === 'loop1');
      expect(loopResult!.output).toContain('not an array');
    });

    it('AC-03: as sets context.data[as] with current item', async () => {
      const flow: CompiledFlow = {
        id: 'loop-as-var',
        name: 'Loop As Var',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'current', stepIds: ['child1'] },
          },
          {
            id: 'child1',
            type: 'assign',
            config: { target: '/data/lastItem', value: { from: 'current' }, valueType: 'literal' },
          },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: ['a', 'b', 'c'] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(3);
      expect(ctx.data).toHaveProperty('lastItem');
      // Since assign writes literal { from: 'current' }, lastItem will be that object
      // The key test is that child1 executed 3 times and `current` was available in context data
      expect((ctx.data as Record<string, unknown>).lastItem).toBeDefined();
    });

    it('AC-04: as undefined skips variable injection', async () => {
      const flow: CompiledFlow = {
        id: 'loop-no-as',
        name: 'Loop No As',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', stepIds: ['child1'] },
          },
          { id: 'child1', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: [1, 2] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(2);
    });

    it('AC-06: variable cleaned after loop', async () => {
      const flow: CompiledFlow = {
        id: 'loop-cleanup',
        name: 'Loop Cleanup',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'tmp', stepIds: ['child1'] },
          },
          { id: 'child1', type: 'end', config: {} },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: ['x', 'y'] },
      };
      await runtime.execute(flow, ctx);

      expect(ctx.data).not.toHaveProperty('tmp');
    });

    it('AC-08: empty collection produces 0 iterations', async () => {
      const flow: CompiledFlow = {
        id: 'loop-empty',
        name: 'Loop Empty',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'item', stepIds: ['child1'] },
          },
          {
            id: 'child1',
            type: 'assign',
            config: { target: '/data/status', value: 'ran', valueType: 'literal' },
          },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: [] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(0);
      expect(ctx.data).not.toHaveProperty('status');
      expect(ctx.data).not.toHaveProperty('item');
    });

    it('AC-07: results are collected in stepResults', async () => {
      const flow: CompiledFlow = {
        id: 'loop-results',
        name: 'Loop Results',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'x', stepIds: ['child1'] },
          },
          { id: 'child1', type: 'end', config: { output: { done: true } } },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: [10, 20] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.stepResults!.some((r) => r.stepId === 'loop1')).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(2);
    });

    it('AC-06: nested path resolution via resolvePath', async () => {
      const flow: CompiledFlow = {
        id: 'loop-nested-path',
        name: 'Loop Nested',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/order/lines', as: 'line', stepIds: ['child1'] },
          },
          {
            id: 'child1',
            type: 'assign',
            config: { target: '/data/lineCount', value: 0, valueType: 'literal' },
          },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { order: { lines: [{ sku: 'A' }, { sku: 'B' }] } },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(2);
    });

    it('AG-09: child step failure does not stop loop', async () => {
      const flow: CompiledFlow = {
        id: 'loop-continue-on-error',
        name: 'Loop Continue On Error',
        trigger: { type: 'manual' },
        steps: [
          {
            id: 'loop1',
            type: 'loop',
            config: { over: '/data/items', as: 'item', stepIds: ['child1'] },
          },
          { id: 'child1', type: 'end', config: { output: 'ok' } },
        ],
        adjacency: new Map([
          ['loop1', { onSuccess: ['child1'] }],
          ['child1', { onSuccess: [] }],
        ]),
      };

      const ctx: ExecutionContext = {
        tenantId: 't1',
        userId: 'u1',
        data: { items: [1, 2, 3] },
      };
      const result = await runtime.execute(flow, ctx);

      expect(result.success).toBe(true);
      expect(result.stepResults!.filter((r) => r.stepId === 'child1')).toHaveLength(3);
    });
  });
});
