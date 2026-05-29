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
});
