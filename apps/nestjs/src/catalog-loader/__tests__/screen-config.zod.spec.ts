import { ScreenConfigZod } from '../validators/index';
import validDashboard from '../../../../../catalog/schemas/examples/screen-config/valid_dashboard.json';
import validForm from '../../../../../catalog/schemas/examples/screen-config/valid_form.json';

describe('ScreenConfigZod', () => {
  describe('valid inputs', () => {
    it('accepts valid dashboard screen', () => {
      const result = ScreenConfigZod.safeParse(validDashboard);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.screen).toBe('dashboard');
        expect(result.data.layout).toBe('dashboard');
        expect(result.data.schema_version).toBe('1.0.0');
      }
    });

    it('accepts valid form screen', () => {
      const result = ScreenConfigZod.safeParse(validForm);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.screen).toBe('product_form');
        expect(result.data.layout).toBe('form');
      }
    });

    it('accepts screen with only kpis zone', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'kpis_only',
        schema_version: '1.0.0',
        layout: 'dashboard',
        zones: {
          kpis: [
            {
              schema_version: '1.0.0',
              type: 'KPICard',
              props: { metric: 'sales' },
            },
          ],
        },
      });
      expect(result.success).toBe(true);
    });

    it('accepts screen with empty zones', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'empty',
        schema_version: '1.0.0',
        layout: 'list',
        zones: {},
      });
      expect(result.success).toBe(true);
    });
  });

  describe('invalid inputs', () => {
    it('rejects invalid layout enum', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'bad_screen',
        schema_version: '1.0.0',
        layout: 'unknown_layout',
        zones: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing screen', () => {
      const result = ScreenConfigZod.safeParse({
        schema_version: '1.0.0',
        layout: 'dashboard',
        zones: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing layout', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'test',
        schema_version: '1.0.0',
        zones: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing zones', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'test',
        schema_version: '1.0.0',
        layout: 'dashboard',
      });
      expect(result.success).toBe(false);
    });

    it('rejects additional properties', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'test',
        schema_version: '1.0.0',
        layout: 'dashboard',
        zones: {},
        unknown_prop: true,
      });
      expect(result.success).toBe(false);
    });

    it('accepts component without schema_version (optional)', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'test',
        schema_version: '1.0.0',
        layout: 'dashboard',
        zones: {
          main: [{ type: 'Button' }],
        },
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid zone keys', () => {
      const result = ScreenConfigZod.safeParse({
        screen: 'test',
        schema_version: '1.0.0',
        layout: 'dashboard',
        zones: {
          unknown_zone: [],
        },
      });
      expect(result.success).toBe(false);
    });
  });
});
