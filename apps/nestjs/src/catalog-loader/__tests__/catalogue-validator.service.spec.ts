import {
  CatalogueValidatorService,
  type CatalogueType,
} from '../services/catalogue-validator.service';

describe('CatalogueValidatorService', () => {
  let service: CatalogueValidatorService;

  beforeEach(() => {
    service = new CatalogueValidatorService();
  });

  describe('validateContent', () => {
    it('validates a valid domain module config', () => {
      const result = service.validateContent(
        {
          id: 'retail_fresh_produce',
          schema_version: '1.0.0',
          name: 'Retail Fresh Produce',
          entities: [{ name: 'Product', fields: [{ name: 'label', type: 'string' }] }],
        },
        'domain',
      );
      expect(result.valid).toBe(true);
    });

    it('validates a valid screen config', () => {
      const result = service.validateContent(
        {
          screen: 'dashboard',
          schema_version: '1.0.0',
          layout: 'dashboard',
          zones: {},
        },
        'screen',
      );
      expect(result.valid).toBe(true);
    });

    it('validates a valid workflow', () => {
      const result = service.validateContent(
        {
          id: 'wf_checkout',
          schema_version: '1.0.0',
          initial_state: 'draft',
          states: { draft: { transitions: { submit: 'pending' } } },
        },
        'workflow',
      );
      expect(result.valid).toBe(true);
    });

    it('returns errors for invalid content', () => {
      const result = service.validateContent({ bad: 'data' }, 'module');
      expect(result.valid).toBe(false);
      expect(result.errors).toBeDefined();
      expect(result.errors!.length).toBeGreaterThan(0);
    });

    it('returns FR-formatted errors', () => {
      const result = service.validateContent({}, 'module');
      expect(result.valid).toBe(false);
      expect(result.errors).toBeDefined();
      expect(result.errors!.length).toBeGreaterThanOrEqual(1);
      // Verify FR messages are present (not raw Zod English)
      const firstError = result.errors![0];
      expect(firstError.code).toBeDefined();
      expect(firstError.path).toBeDefined();
      expect(typeof firstError.message).toBe('string');
    });

    it('returns error for unknown type', () => {
      const result = service.validateContent({ data: 'test' }, 'unknown' as CatalogueType);
      expect(result.valid).toBe(false);
      expect(result.errors![0].message).toContain('Type inconnu');
    });

    it('module, domain, and fusion all use ModuleConfigZod', () => {
      const content = {
        id: 'test_mod',
        schema_version: '1.0.0',
        name: 'Test',
        entities: [],
      };
      expect(service.validateContent(content, 'domain').valid).toBe(true);
      expect(service.validateContent(content, 'module').valid).toBe(true);
      expect(service.validateContent(content, 'fusion').valid).toBe(true);
    });

    it('reports multiple validation errors', () => {
      const result = service.validateContent({}, 'module');
      expect(result.valid).toBe(false);
      expect(result.errors!.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('inferTypeFromPath', () => {
    it('infers domain type from path', () => {
      expect(service.inferTypeFromPath('/catalog/domains/retail.json')).toBe('domain');
    });

    it('infers module type from path', () => {
      expect(service.inferTypeFromPath('/catalog/modules/inventory.json')).toBe('module');
    });

    it('infers fusion type from path', () => {
      expect(service.inferTypeFromPath('/catalog/fusions/main.json')).toBe('fusion');
    });

    it('infers screen type from path', () => {
      expect(service.inferTypeFromPath('/catalog/screens/dashboard.json')).toBe('screen');
    });

    it('infers workflow type from path', () => {
      expect(service.inferTypeFromPath('/catalog/workflows/checkout.json')).toBe('workflow');
    });

    it('returns null for unknown path', () => {
      expect(service.inferTypeFromPath('/catalog/unknown/file.json')).toBeNull();
    });
  });
});
