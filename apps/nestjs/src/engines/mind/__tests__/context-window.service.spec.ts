import { ContextWindowService } from '../context-window.service';

describe('ContextWindowService', () => {
  let service: ContextWindowService;

  beforeEach(() => {
    service = new ContextWindowService();
  });

  describe('getOrCreateStore', () => {
    it('creates a new store for unknown surfaceId', () => {
      const store = service.getOrCreateStore('surface-1');
      expect(store.surfaceId).toBe('surface-1');
      expect(store.messages).toEqual([]);
    });

    it('returns existing store for known surfaceId', () => {
      const store1 = service.getOrCreateStore('surface-1');
      store1.messages.push({ role: 'user', content: 'hello' });

      const store2 = service.getOrCreateStore('surface-1');
      expect(store2).toBe(store1);
      expect(store2.messages).toHaveLength(1);
    });
  });

  describe('addMessage', () => {
    it('adds a message and estimates tokens', () => {
      service.addMessage('s1', { role: 'user', content: 'Hello world' });
      const store = service.getOrCreateStore('s1');
      expect(store.messages).toHaveLength(1);
      expect(store.messages[0].tokenCount).toBeGreaterThan(0);
    });
  });

  describe('estimateTokens', () => {
    it('returns 2 for empty string (overhead)', () => {
      expect(service.estimateTokens('')).toBe(2);
    });

    it('estimates ~1 token per 4 chars', () => {
      const tokens = service.estimateTokens('A'.repeat(40));
      expect(tokens).toBeGreaterThanOrEqual(10);
    });

    it('has a reasonable ratio for mixed content', () => {
      const tokens = service.estimateTokens('Bonjour le monde, comment allez-vous aujourd’hui?');
      expect(tokens).toBeGreaterThan(5);
      expect(tokens).toBeLessThan(100);
    });
  });

  describe('prune', () => {
    it('does nothing for empty store', () => {
      expect(() => service.prune('nonexistent')).not.toThrow();
    });

    it('does not prune when under limit', () => {
      service.addMessage('s1', { role: 'user', content: 'Hi' });
      service.prune('s1');
      const store = service.getOrCreateStore('s1');
      expect(store.messages).toHaveLength(1);
    });

    it('summarizes old messages when over limit', () => {
      const longText = 'word '.repeat(3000);
      for (let i = 0; i < 20; i++) {
        service.addMessage('s1', { role: 'user', content: longText });
      }
      service.prune('s1');
      const store = service.getOrCreateStore('s1');
      expect(store.messages.length).toBeLessThan(20);
    });
  });

  describe('buildWindow', () => {
    it('returns system prompt + messages', () => {
      service.addMessage('s1', { role: 'user', content: 'Hello' });
      const window = service.buildWindow('s1', 'System prompt');
      expect(window[0].role).toBe('system');
      expect(window[0].content).toBe('System prompt');
      expect(window.some((m) => m.role === 'user' && m.content === 'Hello')).toBe(true);
    });

    it('never exceeds MAX_TOKENS', () => {
      const hugeText = 'x '.repeat(100000);
      service.addMessage('s1', { role: 'user', content: hugeText });

      const window = service.buildWindow('s1', 'System');
      const totalTokens = window.reduce((sum, m) => sum + (m.tokenCount ?? service.estimateTokens(m.content)), 0);
      expect(totalTokens).toBeLessThanOrEqual(32000);
    });
  });

  describe('toPrompt', () => {
    it('formats messages correctly', () => {
      const prompt = service.toPrompt([
        { role: 'system', content: 'Be helpful' },
        { role: 'user', content: 'Hi' },
      ]);
      expect(prompt).toContain('[System]');
      expect(prompt).toContain('Be helpful');
      expect(prompt).toContain('[User]');
      expect(prompt).toContain('Hi');
    });
  });

  describe('clear', () => {
    it('removes the store', () => {
      service.addMessage('s1', { role: 'user', content: 'Hello' });
      service.clear('s1');
      const store = service.getOrCreateStore('s1');
      expect(store.messages).toHaveLength(0);
    });
  });
});
