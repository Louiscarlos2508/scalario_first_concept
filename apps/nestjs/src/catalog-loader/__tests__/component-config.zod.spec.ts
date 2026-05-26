import { ComponentConfigZod, ActionStepZod, RuleZod, DataSourceZod, ValidationRuleZod } from '../validators/index';
import { z } from 'zod';
import validComplete from '../../../../../catalog/schemas/examples/component-config/valid_complete.json';
import validMinimal from '../../../../../catalog/schemas/examples/component-config/valid_minimal.json';
import validWithRule from '../../../../../catalog/schemas/examples/component-config/valid_with_rule.json';
import validVariantDefault from '../../../../../catalog/schemas/examples/component-config/valid_with_variant_default.json';
import validVariantAuto from '../../../../../catalog/schemas/examples/component-config/valid_with_variant_auto.json';
import validWithActions from '../../../../../catalog/schemas/examples/component-config/valid_with_actions.json';
import validWithChildren from '../../../../../catalog/schemas/examples/component-config/valid_with_children_nested.json';
import invalidVariantNumber from '../../../../../catalog/schemas/examples/component-config/invalid_variant_number.json';
import invalidActionsShape from '../../../../../catalog/schemas/examples/component-config/invalid_actions_wrong_shape.json';

describe('ComponentConfigZod', () => {
  describe('valid inputs', () => {
    it('accepts valid complete component', () => {
      const result = ComponentConfigZod.safeParse(validComplete);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.schema_version).toBe('1.0.0');
        expect(result.data.type).toBe('DataTable');
        expect(result.data.id).toBe('products-table');
        expect(result.data.source?.type).toBe('module_data');
        expect(result.data.validation).toHaveLength(2);
      }
    });

    it('accepts valid minimal component (only required fields)', () => {
      const result = ComponentConfigZod.safeParse(validMinimal);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.schema_version).toBe('1.0.0');
        expect(result.data.type).toBe('KPICard');
        expect(result.data.props).toEqual({});
      }
    });

    it('accepts component with role-based visibility rule', () => {
      const result = ComponentConfigZod.safeParse(validWithRule);
      expect(result.success).toBe(true);
    });

    it('accepts component with null visible_if', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: { label: 'OK' },
        visible_if: null,
        source: null,
      });
      expect(result.success).toBe(true);
    });

    it('defaults props to empty object', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.props).toEqual({});
      }
    });

    it('defaults validation to empty array', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: {},
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.validation).toEqual([]);
      }
    });

    // --- v1.1.0 new features (AC-01 → AC-05) ---

    it('AC-01: accepts v1.1.0 with variant default', () => {
      const result = ComponentConfigZod.safeParse(validVariantDefault);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.schema_version).toBe('1.1.0');
        expect(result.data.type).toBe('KPICard');
        expect(result.data.variant).toBe('default');
      }
    });

    it('AC-02: accepts v1.1.0 with variant auto', () => {
      const result = ComponentConfigZod.safeParse(validVariantAuto);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.variant).toBe('auto');
      }
    });

    it('AC-03: accepts v1.1.0 with actions pipeline', () => {
      const result = ComponentConfigZod.safeParse(validWithActions);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.actions).toHaveLength(2);
        expect(result.data.actions![0].registry).toBe('vault');
        expect(result.data.actions![0].fn).toBe('save_entity');
        expect(result.data.actions![1].registry).toBe('canvas');
        expect(result.data.actions![1].fn).toBe('navigate');
      }
    });

    it('AC-04: accepts v1.1.0 with nested children composition', () => {
      const result = ComponentConfigZod.safeParse(validWithChildren);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.children).toHaveLength(2);
        const row = result.data.children![0];
        expect(row.type).toBe('Row');
        expect(row.children).toHaveLength(2);
        expect(row.children![0].type).toBe('KPICard');
        expect(row.children![0].variant).toBe('compact');
      }
    });

    // --- Backward compat (AC-09) ---

    it('AC-09: v1.0.0 without variant injects default', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: { label: 'Click' },
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.variant).toBe('default');
      }
    });

    it('AC-09: v1.0.0 valid_complete gets variant default injected', () => {
      const result = ComponentConfigZod.safeParse(validComplete);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.variant).toBe('default');
      }
    });

    // --- Actions edge cases ---

    it('accepts ActionStep with optional fields', () => {
      const result = ActionStepZod.safeParse({
        registry: 'calc',
        fn: 'multiply',
      });
      expect(result.success).toBe(true);
    });

    it('accepts ActionStep with full fields', () => {
      const result = ActionStepZod.safeParse({
        registry: 'vault',
        fn: 'save_entity',
        inputs: { entity: 'Vente' },
        output: 'result',
        on_error: { network: 'notify', validation: 'fail' },
      });
      expect(result.success).toBe(true);
    });

    // --- Children depth guard ---

    it('rejects children exceeding max depth of 5', () => {
      function deepNest(depth: number): any {
        const config = {
          schema_version: '1.1.0',
          type: 'Section',
          props: {},
        };
        if (depth > 1) {
          (config as any).children = [deepNest(depth - 1)];
        }
        return config;
      }
      const result = ComponentConfigZod.safeParse(deepNest(7));
      expect(result.success).toBe(false);
    });
  });

  describe('invalid inputs', () => {
    it('rejects missing type', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        props: {},
      });
      expect(result.success).toBe(false);
      if (!result.success) {
        const paths = result.error.issues.map((i: z.ZodIssue) => i.path.join('.'));
        expect(paths).toContain('type');
      }
    });

    it('rejects wrong schema_version', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '2.0.0',
        type: 'Button',
        props: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects additional properties on strict schema', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: {},
        unknown_field: 'not allowed',
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty type string', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: '',
        props: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid visible_if', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: {},
        visible_if: 'not_a_rule',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid source type', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: {},
        source: { type: 'invalid_type' },
      });
      expect(result.success).toBe(false);
    });

    it('rejects additional properties on source (strict)', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.0.0',
        type: 'Button',
        props: {},
        source: { type: 'static', extra_field: 'nope' },
      });
      expect(result.success).toBe(false);
    });

    // --- v1.1.0 invalid cases (AC-05) ---

    it('AC-05: rejects variant as number', () => {
      const result = ComponentConfigZod.safeParse(invalidVariantNumber);
      expect(result.success).toBe(false);
    });

    it('AC-05: rejects actions with wrong shape (invalid registry + empty fn)', () => {
      const result = ComponentConfigZod.safeParse(invalidActionsShape);
      expect(result.success).toBe(false);
    });

    it('rejects variant as empty string', () => {
      const result = ComponentConfigZod.safeParse({
        schema_version: '1.1.0',
        type: 'Button',
        variant: '',
        props: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects ActionStep with unknown registry', () => {
      const result = ActionStepZod.safeParse({
        registry: 'unknown',
        fn: 'test',
      });
      expect(result.success).toBe(false);
    });

    it('rejects ActionStep with empty fn', () => {
      const result = ActionStepZod.safeParse({
        registry: 'canvas',
        fn: '',
      });
      expect(result.success).toBe(false);
    });
  });
});

describe('RuleZod', () => {
  describe('logical operators', () => {
    it('accepts AND rule with children', () => {
      const result = RuleZod.safeParse({
        operator: 'AND',
        children: [
          { operator: 'role', value: 'MANAGER' },
          { operator: '==', field: 'order.status', value: 'active' },
        ],
      });
      expect(result.success).toBe(true);
    });

    it('accepts OR rule with children', () => {
      const result = RuleZod.safeParse({
        operator: 'OR',
        children: [{ operator: 'role', value: ['MANAGER', 'COMMERCIAL'] }],
      });
      expect(result.success).toBe(true);
    });

    it('accepts nested rules 3 levels deep', () => {
      const result = RuleZod.safeParse({
        operator: 'AND',
        children: [
          {
            operator: 'OR',
            children: [
              { operator: 'role', value: 'OWNER' },
              {
                operator: 'AND',
                children: [{ operator: 'role', value: 'MANAGER' }],
              },
            ],
          },
        ],
      });
      expect(result.success).toBe(true);
    });

    it('rejects AND with empty children', () => {
      const result = RuleZod.safeParse({
        operator: 'AND',
        children: [],
      });
      expect(result.success).toBe(false);
    });

    it('rejects AND without children', () => {
      const result = RuleZod.safeParse({
        operator: 'AND',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('role operator', () => {
    it('accepts role with string value', () => {
      const result = RuleZod.safeParse({
        operator: 'role',
        value: 'MANAGER',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.value).toEqual(['MANAGER']);
      }
    });

    it('accepts role with array value', () => {
      const result = RuleZod.safeParse({
        operator: 'role',
        value: ['MANAGER', 'COMMERCIAL'],
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.value).toEqual(['MANAGER', 'COMMERCIAL']);
      }
    });

    it('rejects role without value', () => {
      const result = RuleZod.safeParse({
        operator: 'role',
      });
      expect(result.success).toBe(false);
    });

    it('rejects role with empty array', () => {
      const result = RuleZod.safeParse({
        operator: 'role',
        value: [],
      });
      expect(result.success).toBe(false);
    });
  });

  describe('comparison operators', () => {
    it('accepts == operator', () => {
      const result = RuleZod.safeParse({
        operator: '==',
        field: 'order.total',
        value: 500,
      });
      expect(result.success).toBe(true);
    });

    it('accepts != operator', () => {
      const result = RuleZod.safeParse({
        operator: '!=',
        field: 'status',
        value: 'draft',
      });
      expect(result.success).toBe(true);
    });

    it('accepts > operator with negate option', () => {
      const result = RuleZod.safeParse({
        operator: '>',
        field: 'amount',
        value: 100,
        negate: true,
      });
      expect(result.success).toBe(true);
    });

    it('accepts in operator', () => {
      const result = RuleZod.safeParse({
        operator: 'in',
        field: 'category',
        value: ['fruits', 'vegetables'],
      });
      expect(result.success).toBe(true);
    });

    it('rejects comparison without field', () => {
      const result = RuleZod.safeParse({
        operator: '>',
        value: 100,
      });
      expect(result.success).toBe(false);
    });

    it('rejects comparison with empty field', () => {
      const result = RuleZod.safeParse({
        operator: '>',
        field: '',
        value: 100,
      });
      expect(result.success).toBe(false);
    });
  });
});

describe('DataSourceZod', () => {
  it('accepts module_data source', () => {
    const result = DataSourceZod.safeParse({
      type: 'module_data',
      module_id: 'retail_fresh_produce',
      query: { entity: 'Product' },
    });
    expect(result.success).toBe(true);
  });

  it('accepts kpi source', () => {
    const result = DataSourceZod.safeParse({
      type: 'kpi',
      module_id: 'retail_fresh_produce',
    });
    expect(result.success).toBe(true);
  });

  it('accepts static source', () => {
    const result = DataSourceZod.safeParse({ type: 'static' });
    expect(result.success).toBe(true);
  });

  it('accepts computed source', () => {
    const result = DataSourceZod.safeParse({ type: 'computed' });
    expect(result.success).toBe(true);
  });

  it('rejects invalid type', () => {
    const result = DataSourceZod.safeParse({ type: 'unknown' });
    expect(result.success).toBe(false);
  });

  it('rejects additional properties', () => {
    const result = DataSourceZod.safeParse({
      type: 'static',
      unknown: 'field',
    });
    expect(result.success).toBe(false);
  });

  it('rejects missing type', () => {
    const result = DataSourceZod.safeParse({ module_id: 'test' });
    expect(result.success).toBe(false);
  });
});

describe('ValidationRuleZod', () => {
  it('accepts required rule', () => {
    const result = ValidationRuleZod.safeParse({ kind: 'required' });
    expect(result.success).toBe(true);
  });

  it('accepts min rule with value', () => {
    const result = ValidationRuleZod.safeParse({ kind: 'min', value: 0 });
    expect(result.success).toBe(true);
  });

  it('accepts pattern rule with message', () => {
    const result = ValidationRuleZod.safeParse({
      kind: 'pattern',
      value: '^[A-Z]',
      message_i18n_key: 'validation.pattern',
    });
    expect(result.success).toBe(true);
  });

  it('rejects invalid kind', () => {
    const result = ValidationRuleZod.safeParse({ kind: 'invalid' });
    expect(result.success).toBe(false);
  });

  it('rejects additional properties', () => {
    const result = ValidationRuleZod.safeParse({ kind: 'required', extra: true });
    expect(result.success).toBe(false);
  });

  it('rejects missing kind', () => {
    const result = ValidationRuleZod.safeParse({ value: 42 });
    expect(result.success).toBe(false);
  });
});
