import { ModuleConfigZod } from '../validators/index';
import validComplete from '../../../../../catalog/schemas/examples/module-config/valid_complete.json';
import validMinimal from '../../../../../catalog/schemas/examples/module-config/valid_minimal.json';

describe('ModuleConfigZod', () => {
  describe('valid inputs', () => {
    it('accepts valid complete module', () => {
      const result = ModuleConfigZod.safeParse(validComplete);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('retail_fresh_produce');
        expect(result.data.schema_version).toBe('1.0.0');
        expect(result.data.entities).toBeDefined();
        expect(result.data.rbac_roles).toEqual(['OWNER', 'MANAGER', 'COMMERCIAL']);
        expect(result.data.conflict_strategy).toBe('server_wins');
      }
    });

    it('accepts valid minimal module', () => {
      const result = ModuleConfigZod.safeParse(validMinimal);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('retail_fresh_produce');
        expect(result.data.rbac_roles).toEqual([]);
        expect(result.data.conflict_strategy).toBe('server_wins');
      }
    });

    it('accepts module with screens', () => {
      const mod = {
        ...validMinimal,
        screens: [
          {
            screen: 'dashboard',
            schema_version: '1.0.0',
            layout: 'dashboard',
            zones: { main: [{ schema_version: '1.0.0', type: 'KPICard', props: {} }] },
          },
        ],
      };
      const result = ModuleConfigZod.safeParse(mod);
      expect(result.success).toBe(true);
    });

    it('accepts module with workflows', () => {
      const mod = {
        ...validMinimal,
        workflows: {
          wf_checkout: {
            id: 'wf_checkout',
            schema_version: '1.0.0',
            initial_state: 'draft',
            states: { draft: { transitions: { submit: 'pending' } } },
          },
        },
      };
      const result = ModuleConfigZod.safeParse(mod);
      expect(result.success).toBe(true);
    });

    it('accepts module with actions containing handler', () => {
      const mod = {
        ...validMinimal,
        actions: {
          create_product: { handler: 'crud.create', entity_type: 'Product' },
        },
      };
      const result = ModuleConfigZod.safeParse(mod);
      expect(result.success).toBe(true);
    });

    it('accepts abac_rules inline', () => {
      const mod = {
        ...validMinimal,
        abac_rules: [{ action: 'read', subject: 'Product', roles: ['OWNER', 'MANAGER'] }],
      };
      const result = ModuleConfigZod.safeParse(mod);
      expect(result.success).toBe(true);
    });
  });

  describe('invalid inputs', () => {
    it('rejects bad id pattern', () => {
      const result = ModuleConfigZod.safeParse({
        id: 'BAD-ID-FORMAT',
        schema_version: '1.0.0',
        name: 'Module invalide',
        entities: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing id', () => {
      const result = ModuleConfigZod.safeParse({
        schema_version: '1.0.0',
        name: 'Module',
        entities: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing schema_version', () => {
      const result = ModuleConfigZod.safeParse({
        id: 'test_mod',
        name: 'Module',
        entities: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects wrong schema_version', () => {
      const result = ModuleConfigZod.safeParse({
        id: 'test_mod',
        schema_version: '2.0.0',
        name: 'Module',
        entities: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing name', () => {
      const result = ModuleConfigZod.safeParse({
        id: 'test_mod',
        schema_version: '1.0.0',
        entities: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects bad handler pattern in actions', () => {
      const result = ModuleConfigZod.safeParse({
        id: 'test_mod',
        schema_version: '1.0.0',
        name: 'Module',
        entities: [],
        actions: {
          bad_action: { handler: 'BadHandler' },
        },
      });
      expect(result.success).toBe(false);
    });

    it('rejects additional properties on top level', () => {
      const result = ModuleConfigZod.safeParse({
        ...validMinimal,
        unknown_field: true,
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid conflict_strategy', () => {
      const result = ModuleConfigZod.safeParse({
        ...validMinimal,
        conflict_strategy: 'invalid',
      });
      expect(result.success).toBe(false);
    });
  });
});
