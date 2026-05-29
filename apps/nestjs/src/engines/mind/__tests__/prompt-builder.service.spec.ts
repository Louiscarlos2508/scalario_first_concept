import { PromptBuilderService } from '../prompt-builder.service';

describe('PromptBuilderService', () => {
  let service: PromptBuilderService;

  beforeEach(() => {
    service = new PromptBuilderService();
  });

  describe('getSystemPrompt', () => {
    it('returns UI system prompt with component catalog', () => {
      const prompt = service.getSystemPrompt('ui');
      expect(prompt).toContain('Scalario AI');
      expect(prompt).toContain('A2UI v0.9');
      expect(prompt).toContain('createSurface');
      expect(prompt).toContain('updateComponents');
      expect(prompt).toContain('updateDataModel');
    });

    it('returns Flow system prompt with flow catalog', () => {
      const prompt = service.getSystemPrompt('flow');
      expect(prompt).toContain('Scalario AI');
      expect(prompt).toContain('Flow Engine AST');
      expect(prompt).toContain('flow_meta');
      expect(prompt).toContain('condition');
      expect(prompt).toContain('approval');
    });

    it('defaults to UI when no engine specified', () => {
      const prompt = service.getSystemPrompt();
      expect(prompt).toContain('A2UI v0.9');
    });
  });

  describe('buildUserPrompt', () => {
    it('builds from intent only', () => {
      const prompt = service.buildUserPrompt('Show sales dashboard');
      expect(prompt).toContain('Show sales dashboard');
      expect(prompt).not.toContain('## Screen');
      expect(prompt).not.toContain('## Available Data');
    });

    it('includes screen context when provided', () => {
      const prompt = service.buildUserPrompt('Show sales', { screen: 'dashboard' });
      expect(prompt).toContain('## Screen');
      expect(prompt).toContain('dashboard');
    });

    it('includes data context when provided', () => {
      const prompt = service.buildUserPrompt('Analyze', {
        data: { revenue: 50000, orders: 120 },
      });
      expect(prompt).toContain('## Available Data');
      expect(prompt).toContain('revenue');
      expect(prompt).toContain('50000');
    });

    it('includes previous error messages (last 3)', () => {
      const prompt = service.buildUserPrompt('Fix it', {
        previousMessages: [
          'Error 1: invalid JSON',
          'Error 2: missing version',
          'Error 3: no root component',
          'Error 4: extra error',
        ],
      });
      expect(prompt).toContain('## Previous Errors to Fix');
      expect(prompt).toContain('Error 2');
      expect(prompt).toContain('Error 4');
      expect(prompt).not.toContain('Error 1');
    });
  });

  describe('buildFeedbackPrompt', () => {
    it('includes validation errors and previous attempt', () => {
      const prompt = service.buildFeedbackPrompt(
        'Missing version field',
        '{"some":"json"}',
        'ui',
      );
      expect(prompt).toContain('Correction Required');
      expect(prompt).toContain('Missing version field');
      expect(prompt).toContain('{"some":"json"}');
      expect(prompt).toContain('A2UI');
    });

    it('mentions Flow AST for flow engine', () => {
      const prompt = service.buildFeedbackPrompt(
        'Missing flowId',
        '{"engine":"flow"}',
        'flow',
      );
      expect(prompt).toContain('Flow AST');
    });
  });

  describe('catalog loading', () => {
    it('falls back gracefully when catalog files are not found', () => {
      const prompt = service.getSystemPrompt('ui');
      expect(prompt).toBeTruthy();
      expect(prompt.length).toBeGreaterThan(100);
    });
  });
});
