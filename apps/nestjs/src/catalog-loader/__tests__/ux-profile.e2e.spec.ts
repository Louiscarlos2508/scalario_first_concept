import { UxProfileLoader } from '../loaders/ux-profile-loader';
import { UxProfileValidator, VariantNotAllowedException } from '../validators/ux-profile.validator';

describe('UX Profile Validation (V14-004)', () => {
  let loader: UxProfileLoader;
  let validator: UxProfileValidator;

  beforeAll(() => {
    loader = new UxProfileLoader();
    validator = new UxProfileValidator(loader);
  });

  afterEach(() => {
    loader.clearCache();
  });

  describe('AC-10/AC-11 — variant validation per sector', () => {
    it('AC-10: rejects with-chart KPICard in pharmacie', () => {
      expect(() => {
        validator.assertVariantAllowed('pharmacie', 'KPICard', 'with-chart');
      }).toThrow(VariantNotAllowedException);
    });

    it('AC-11: accepts compact KPICard in pharmacie', () => {
      expect(() => {
        validator.assertVariantAllowed('pharmacie', 'KPICard', 'compact');
      }).not.toThrow();
    });

    it('accepts auto variant always', () => {
      expect(() => {
        validator.assertVariantAllowed('pharmacie', 'KPICard', 'auto');
      }).not.toThrow();
    });

    it('allows KPICard with-chart in commerce_general (inherits _base)', () => {
      expect(() => {
        validator.assertVariantAllowed('commerce_general', 'KPICard', 'with-chart');
      }).not.toThrow();
    });

    it('AC-06: fallback to _base for component not in sector override', () => {
      expect(() => {
        validator.assertVariantAllowed('pharmacie', 'ChartPie', 'donut');
      }).not.toThrow();
    });

    it('rejects unknown variant in any sector', () => {
      expect(() => {
        validator.assertVariantAllowed('pharmacie', 'KPICard', 'super-hero');
      }).toThrow(VariantNotAllowedException);
    });

    it('loads _base profile directly', () => {
      const profile = loader.load('_base');
      expect(profile.components['KPICard']).toBeDefined();
      expect(profile.components['KPICard'].allowed_variants).toContain('with-chart');
    });

    it('loads pharmacie profile with inheritance merge', () => {
      const profile = loader.load('pharmacie');
      expect(profile.components['KPICard'].allowed_variants).not.toContain('with-chart');
      expect(profile.components['KPICard'].allowed_variants).toContain('compact');
      expect(profile.components['ChartPie']).toBeDefined();
    });

    it('loads commerce_general profile with inheritance', () => {
      const profile = loader.load('commerce_general');
      expect(profile.components['KPICard'].allowed_variants).toContain('with-chart');
      expect(profile.components['ChartPie']).toBeDefined();
    });

    it('loads btp profile with sector-specific defaults', () => {
      const profile = loader.load('btp');
      expect(profile.components['KPICard'].default_variant).toBe('hero');
    });

    it('non-existent sector returns _base', () => {
      const profile = loader.load('nonexistent');
      expect(profile.components['KPICard']).toBeDefined();
    });

    it('_inherits reference is set on sector profiles', () => {
      const profile = loader.load('pharmacie');
      expect(profile.$inherits).toBe('_base');
    });
  });
});
