import { ContextWindowService } from '../context-window.service';
import { PromptBuilderService } from '../prompt-builder.service';
import { LlmFallbackService } from '../llm-fallback.service';
import { MindEngineService } from '../mind-engine.service';

describe('MindEngineService', () => {
  let service: MindEngineService;
  let contextWindow: ContextWindowService;
  let llm: LlmFallbackService;

  beforeEach(() => {
    contextWindow = new ContextWindowService();
    const promptBuilder = new PromptBuilderService();
    llm = new LlmFallbackService();
    service = new MindEngineService(contextWindow, promptBuilder, llm);
  });

  describe('generate', () => {
    it('returns a response for UI engine', async () => {
      const result = await service.generate({
        surfaceId: 'test-surface',
        intent: 'Show sales dashboard',
        engine: 'ui',
      });

      expect(result.surfaceId).toBe('test-surface');
      expect(result.text).toBeDefined();
      expect(typeof result.text).toBe('string');
      expect(result.model).toBeDefined();
      expect(result.engine).toBe('ui');
    });

    it('returns a response for Flow engine', async () => {
      const result = await service.generate({
        surfaceId: 'test-flow',
        intent: 'Validate orders over 1M',
        engine: 'flow',
      });

      expect(result.surfaceId).toBe('test-flow');
      expect(result.text).toBeDefined();
      expect(result.engine).toBe('flow');
    });

    it('handles degraded mode when LLM returns degraded', async () => {
      jest.spyOn(llm, 'complete').mockResolvedValue({
        text: '',
        model: 'degraded',
        degraded: true,
      });

      const result = await service.generate({
        surfaceId: 'surface-1',
        intent: 'Anything',
      });

      expect(result.degraded).toBe(true);
      expect(result.model).toBe('degraded');
    });

    it('preserves context across multiple calls', async () => {
      await service.generate({
        surfaceId: 'ctx-test',
        intent: 'First request',
      });

      await service.generate({
        surfaceId: 'ctx-test',
        intent: 'Second request',
      });

      const store = contextWindow.getOrCreateStore('ctx-test');
      expect(store.messages.length).toBeGreaterThanOrEqual(2);
    });

    it('uses custom temperature', async () => {
      const result = await service.generate({
        surfaceId: 'temp-test',
        intent: 'Test',
        temperature: 0.9,
      });

      expect(result.surfaceId).toBe('temp-test');
    });

    it('handles maxRetries parameter', async () => {
      const result = await service.generate({
        surfaceId: 'retry-test',
        intent: 'Test',
        maxRetries: 1,
      });

      expect(result.retries).toBeLessThanOrEqual(1);
    });
  });

  describe('UI output validation', () => {
    it('rejects empty response', () => {
      const result = (service as any).validateOutput('', 'ui');
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('rejects non-JSON response', () => {
      const result = (service as any).validateOutput('not json', 'ui');
      expect(result.valid).toBe(false);
    });

    it('rejects response missing version', () => {
      const result = (service as any).validateOutput('{}', 'ui');
      expect(result.valid).toBe(false);
    });

    it('accepts valid A2UI with createSurface', () => {
      const valid = JSON.stringify({
        version: 'v0.9',
        createSurface: { surfaceId: 's1', catalogId: 'scalario-v1' },
      });
      const result = (service as any).validateOutput(valid, 'ui');
      expect(result.valid).toBe(true);
    });

    it('accepts valid A2UI with updateComponents + root', () => {
      const valid = JSON.stringify({
        version: 'v0.9',
        updateComponents: {
          surfaceId: 's1',
          components: [
            { id: 'root', component: 'Column', children: ['child1'] },
            { id: 'child1', component: 'Text', text: 'Hello' },
          ],
        },
      });
      const result = (service as any).validateOutput(valid, 'ui');
      expect(result.valid).toBe(true);
    });

    it('rejects updateComponents with duplicate IDs', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        updateComponents: {
          surfaceId: 's1',
          components: [
            { id: 'root', component: 'Column' },
            { id: 'root', component: 'Text' },
          ],
        },
      });
      const result = (service as any).validateOutput(invalid, 'ui');
      expect(result.valid).toBe(false);
      expect(result.errors.some((e: string) => e.includes('Duplicate'))).toBe(true);
    });

    it('rejects updateComponents with missing component type', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        updateComponents: {
          surfaceId: 's1',
          components: [{ id: 'root' }],
        },
      });
      const result = (service as any).validateOutput(invalid, 'ui');
      expect(result.valid).toBe(false);
    });
  });

  describe('Flow AST validation', () => {
    it('rejects empty response', () => {
      const result = (service as any).validateOutput('', 'flow');
      expect(result.valid).toBe(false);
    });

    it('rejects non-JSON response', () => {
      const result = (service as any).validateOutput('not json', 'flow');
      expect(result.valid).toBe(false);
    });

    it('rejects missing engine field', () => {
      const result = (service as any).validateOutput('{"version":"v0.9"}', 'flow');
      expect(result.valid).toBe(false);
    });

    it('accepts valid Flow AST', () => {
      const valid = JSON.stringify({
        version: 'v0.9',
        engine: 'flow',
        flow: {
          id: 'flow-1',
          name: 'Test Flow',
          trigger: { type: 'manual' },
          steps: [
            { id: 'meta', type: 'flow_meta', flowId: 'flow-1', name: 'Test' },
            { id: 's1', type: 'condition', expression: '/data/amount > 1000', then: ['s2'], else: [] },
            { id: 's2', type: 'end' },
          ],
        },
      });
      const result = (service as any).validateOutput(valid, 'flow');
      expect(result.valid).toBe(true);
    });

    it('rejects flow with invalid step type', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        engine: 'flow',
        flow: {
          id: 'flow-1',
          name: 'Bad',
          trigger: { type: 'manual' },
          steps: [{ id: 's1', type: 'invalid_type' }],
        },
      });
      const result = (service as any).validateOutput(invalid, 'flow');
      expect(result.valid).toBe(false);
    });

    it('rejects flow missing flow_meta step', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        engine: 'flow',
        flow: {
          id: 'flow-1',
          name: 'No Meta',
          trigger: { type: 'manual' },
          steps: [{ id: 's1', type: 'condition', expression: 'true', then: [], else: [] }],
        },
      });
      const result = (service as any).validateOutput(invalid, 'flow');
      expect(result.valid).toBe(false);
    });

    it('rejects condition without expression', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        engine: 'flow',
        flow: {
          id: 'flow-1',
          name: 'Bad Condition',
          trigger: { type: 'manual' },
          steps: [
            { id: 'meta', type: 'flow_meta', flowId: 'flow-1', name: 'Test' },
            { id: 's1', type: 'condition' },
          ],
        },
      });
      const result = (service as any).validateOutput(invalid, 'flow');
      expect(result.valid).toBe(false);
    });

    it('rejects approval without role', () => {
      const invalid = JSON.stringify({
        version: 'v0.9',
        engine: 'flow',
        flow: {
          id: 'flow-1',
          name: 'No Role',
          trigger: { type: 'manual' },
          steps: [
            { id: 'meta', type: 'flow_meta', flowId: 'flow-1', name: 'Test' },
            { id: 's1', type: 'approval' },
          ],
        },
      });
      const result = (service as any).validateOutput(invalid, 'flow');
      expect(result.valid).toBe(false);
    });
  });
});
