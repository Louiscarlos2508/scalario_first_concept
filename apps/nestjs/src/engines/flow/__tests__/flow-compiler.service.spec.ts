import { FlowCompilerService } from '../flow-compiler.service';
import type { AstNode } from '../../shared/engine-core';

describe('FlowCompilerService', () => {
  let compiler: FlowCompilerService;

  beforeEach(() => {
    compiler = new FlowCompilerService();
  });

  describe('compile', () => {
    it('compiles a minimal flow', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Test', triggerType: 'manual' },
        { id: 's1', type: 'end' },
      ];

      const result = compiler.compile(ast);
      expect(result.id).toBe('f1');
      expect(result.name).toBe('Test');
      expect(result.trigger.type).toBe('manual');
      expect(result.steps).toHaveLength(1);
      expect(result.steps[0].id).toBe('s1');
    });

    it('compiles a condition step correctly', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Test' },
        { id: 's1', type: 'condition', expression: '/data/amount > 1000', then: ['s2'], else: ['s3'] },
        { id: 's2', type: 'end' },
        { id: 's3', type: 'end' },
      ];

      const result = compiler.compile(ast);
      const conditionStep = result.steps.find((s) => s.id === 's1');
      expect(conditionStep).toBeDefined();
      expect(conditionStep!.type).toBe('condition');
      expect(conditionStep!.config.expression).toBe('/data/amount > 1000');

      const adj = result.adjacency.get('s1');
      expect(adj).toBeDefined();
      expect(adj!.onSuccess).toEqual(['s2']);
      expect(adj!.onFailure).toEqual(['s3']);
    });

    it('compiles an approval step correctly', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Approval Test' },
        { id: 's1', type: 'approval', role: 'dg', message: 'Please approve', on_approved: ['s2'], on_rejected: ['s3'] },
        { id: 's2', type: 'end' },
        { id: 's3', type: 'end' },
      ];

      const result = compiler.compile(ast);
      const step = result.steps.find((s) => s.id === 's1');
      expect(step!.config.role).toBe('dg');
      expect(step!.config.message).toBe('Please approve');

      const adj = result.adjacency.get('s1');
      expect(adj!.onSuccess).toEqual(['s2']);
      expect(adj!.onFailure).toEqual(['s3']);
    });

    it('compiles a delay step', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Delay' },
        { id: 's1', type: 'delay', duration: 300 },
        { id: 's2', type: 'end' },
      ];

      const result = compiler.compile(ast);
      const step = result.steps.find((s) => s.id === 's1');
      expect(step!.config.duration).toBe(300);
    });

    it('compiles a notify step', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Notify' },
        { id: 's1', type: 'notify', channel: 'email', to: 'user@test.com', template: 'welcome' },
      ];

      const result = compiler.compile(ast);
      const step = result.steps.find((s) => s.id === 's1');
      expect(step!.config.channel).toBe('email');
      expect(step!.config.to).toBe('user@test.com');
      expect(step!.config.template).toBe('welcome');
    });

    it('compiles an assign step', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Assign' },
        { id: 's1', type: 'assign', target: '/data/status', value: 'approved', value_type: 'literal' },
      ];

      const result = compiler.compile(ast);
      const step = result.steps.find((s) => s.id === 's1');
      expect(step!.config.target).toBe('/data/status');
      expect(step!.config.value).toBe('approved');
      expect(step!.config.valueType).toBe('literal');
    });

    it('compiles a webhook step', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Webhook' },
        { id: 's1', type: 'webhook', url: 'https://api.example.com/hook', method: 'POST' },
      ];

      const result = compiler.compile(ast);
      const step = result.steps.find((s) => s.id === 's1');
      expect(step!.config.url).toBe('https://api.example.com/hook');
      expect(step!.config.method).toBe('POST');
    });

    it('handles empty steps array', () => {
      const ast: AstNode[] = [];
      const result = compiler.compile(ast);
      expect(result.steps).toHaveLength(0);
    });

    it('generates a fallback flowId when missing', () => {
      const ast: AstNode[] = [
        { id: 's1', type: 'end' },
      ];

      const result = compiler.compile(ast);
      expect(result.id).toContain('flow_');
    });

    it('does not fail on unknown step types', () => {
      const ast: AstNode[] = [
        { id: 'meta', type: 'flow_meta', flowId: 'f1', name: 'Unknown' },
        { id: 's1', type: 'unknown_type' as any },
      ];

      expect(() => compiler.compile(ast)).not.toThrow();
    });
  });
});
