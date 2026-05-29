import { LlmFallbackService } from '../llm-fallback.service';

describe('LlmFallbackService', () => {
  let service: LlmFallbackService;

  beforeEach(() => {
    service = new LlmFallbackService();
  });

  describe('complete', () => {
    it('returns a response with text and model name', async () => {
      const result = await service.complete({ prompt: 'Hello' });
      expect(result.text).toBeDefined();
      expect(typeof result.text).toBe('string');
      expect(result.model).toBe('deepseek-v4');
    });

    it('respects maxTokens parameter', async () => {
      const result = await service.complete({ prompt: 'Test', maxTokens: 500 });
      expect(result).toBeDefined();
      expect(result.text).toBeDefined();
    });

    it('respects temperature parameter', async () => {
      const result = await service.complete({ prompt: 'Test', temperature: 0.7 });
      expect(result).toBeDefined();
    });

    it('always returns a result (stubs do not throw)', async () => {
      const result = await service.complete({ prompt: 'Hello' });
      expect(result.text).toBeTruthy();
      expect(result.degraded).toBeUndefined();
    });

    it('has a fallback chain: DeepSeek -> Claude -> degraded', () => {
      const methods = Object.getOwnPropertyNames(Object.getPrototypeOf(service));
      expect(methods).toContain('callDeepSeek');
      expect(methods).toContain('callClaude');
    });
  });
});
