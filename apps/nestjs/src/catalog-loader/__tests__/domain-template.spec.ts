import { DomainTemplateSchema } from '../dto/domain-template.dto';
import { loadDomainTemplate, loadTemplateRoles } from '../templates.loader';

describe('DomainTemplate — retail_fresh_produce', () => {
  describe('schema validation (AC-14, AC-15)', () => {
    it('loads the live catalog/domains/retail_fresh_produce.json with 0 errors', () => {
      // STORY-039 AC-16: loader returns a typed DomainTemplate with the 3 expected roles.
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.domain_id).toBe('retail_fresh_produce');
      expect(tpl.schema_version).toBe('1.0.0');
      expect(tpl.roles).toHaveLength(3);
      expect(tpl.roles.map((r) => r.id).sort()).toEqual(['COMMERCIAL', 'MANAGER', 'OWNER']);
    });

    it('AC-02 — metadata is well-formed', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.sector).toBe('retail');
      expect(tpl.subsector).toBe('fresh_produce');
      expect(tpl.min_users).toBeGreaterThan(0);
      expect(tpl.max_users).toBeGreaterThanOrEqual(tpl.min_users);
    });

    it('AC-03 — tenant_defaults are Global Scale (XOF/fr-BF/Ouagadougou)', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.tenant_defaults.currency).toBe('XOF');
      expect(tpl.tenant_defaults.locale).toBe('fr-BF');
      expect(tpl.tenant_defaults.timezone).toBe('Africa/Ouagadougou');
      expect(tpl.tenant_defaults.payment_methods_enabled).toContain('cash');
      expect(tpl.tenant_defaults.payment_methods_enabled).toContain('mobile_money');
    });

    it('AC-05 — OWNER permissions cover dashboard + ventes + pertes + stock + cloture', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const owner = tpl.roles.find((r) => r.id === 'OWNER')!;
      expect(owner.permissions).toEqual(
        expect.arrayContaining([
          'module_dashboard_owner.read.all',
          'module_ventes.read.all',
          'module_pertes.read.all',
          'module_stock.read.all',
          'module_cloture_caisse.validate.all',
        ]),
      );
      expect(owner.dashboard_module_id).toBe('module_dashboard_owner');
    });

    it('AC-06 — MANAGER has stock validate but NOT dashboard_owner access', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const mgr = tpl.roles.find((r) => r.id === 'MANAGER')!;
      expect(mgr.permissions).toEqual(
        expect.arrayContaining([
          'module_stock.validate.all',
          'module_pertes.validate.all',
          'module_cloture_caisse.validate.all',
        ]),
      );
      expect(mgr.permissions.some((p) => p.startsWith('module_dashboard_owner'))).toBe(false);
    });

    it('AC-07 — COMMERCIAL is .own-scoped and has no arrivages/dashboard_owner access', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const com = tpl.roles.find((r) => r.id === 'COMMERCIAL')!;
      expect(com.permissions.every((p) => p.endsWith('.own'))).toBe(true);
      expect(com.permissions.some((p) => p.startsWith('module_dashboard_owner'))).toBe(false);
    });

    it('AC-09 — modules[] declares 6 entries with phase: 1', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.modules).toHaveLength(6);
      expect(tpl.modules.every((m) => m.phase === 1 && m.enabled)).toBe(true);
      const ids = tpl.modules.map((m) => m.module_id).sort();
      expect(ids).toEqual([
        'module_dashboard_commercial',
        'module_dashboard_manager',
        'module_dashboard_owner',
        'module_pertes',
        'module_stock',
        'module_ventes',
      ]);
    });

    it('AC-11/AC-12 — navigation_per_role landing matches role dashboards', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.navigation_per_role.OWNER.landing_screen_id).toBe('dashboard_owner');
      expect(tpl.navigation_per_role.MANAGER.landing_screen_id).toBe('dashboard_manager');
      expect(tpl.navigation_per_role.COMMERCIAL.landing_screen_id).toBe('dashboard_commercial');
    });

    it('AC-13 — dashboard_layouts_per_role has one entry per role', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.dashboard_layouts_per_role).toHaveLength(3);
      const roles = tpl.dashboard_layouts_per_role.map((d) => d.role).sort();
      expect(roles).toEqual(['COMMERCIAL', 'MANAGER', 'OWNER']);
    });

    it('AC-15 — missing schema_version → validation fails with readable message', () => {
      const minimal: any = {
        domain_id: 'test',
        name: 'test',
        i18n_key: 'k',
        sector: 'retail',
        description: 'd',
        version: '1.0.0',
        min_users: 1,
        max_users: 1,
        tenant_defaults: {
          currency: 'XOF',
          locale: 'fr-BF',
          timezone: 'Africa/Ouagadougou',
          fiscal_year_start: '01-01',
          tax_mode: 'configurable',
          payment_methods_enabled: ['cash'],
        },
        roles: [],
        modules: [],
        navigation_per_role: {},
        dashboard_layouts_per_role: [],
      };
      const result = DomainTemplateSchema.safeParse(minimal);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some((i) => i.path.includes('schema_version'))).toBe(true);
      }
    });

    it('AC-15 — missing roles field → validation fails', () => {
      const result = DomainTemplateSchema.safeParse({
        schema_version: '1.0.0',
        domain_id: 'x',
      });
      expect(result.success).toBe(false);
    });

    it('cross-check: nav_modules referencing undeclared modules → rejected', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      // Inject a bad nav_module reference
      const broken = {
        ...tpl,
        roles: tpl.roles.map((r) =>
          r.id === 'OWNER' ? { ...r, nav_modules: [...r.nav_modules, 'module_nonexistent'] } : r,
        ),
      };
      const result = DomainTemplateSchema.safeParse(broken);
      expect(result.success).toBe(false);
    });

    it('cross-check: navigation_per_role with extra key → rejected', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const broken = {
        ...tpl,
        navigation_per_role: {
          ...tpl.navigation_per_role,
          EXTRANEOUS: {
            landing_screen_id: 'x',
            bottom_nav: ['module_ventes'],
          },
        },
      };
      const result = DomainTemplateSchema.safeParse(broken);
      expect(result.success).toBe(false);
    });
  });

  describe('STORY-015 legacy compat (loadTemplateRoles)', () => {
    it('extracts role ids from the new shape (objects with .id)', () => {
      // retail_fresh_produce.json now uses the STORY-039 object shape.
      const roles = loadTemplateRoles('retail_fresh_produce');
      expect(roles.sort()).toEqual(['COMMERCIAL', 'MANAGER', 'OWNER']);
    });
  });

  describe('AC-19 — Global Scale: no hardcoded business values outside tenant_defaults', () => {
    it('strings "FCFA", "Burkina Faso", "Wave" do not appear in the template', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const serialized = JSON.stringify(tpl);
      expect(serialized).not.toMatch(/FCFA/i);
      expect(serialized).not.toMatch(/Burkina Faso/i);
      expect(serialized).not.toMatch(/\bWave\b/i);
    });

    it('"Africa/Ouagadougou" appears ONLY inside tenant_defaults.timezone', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const serialized = JSON.stringify(tpl);
      const matches = serialized.match(/Africa\/Ouagadougou/g) ?? [];
      expect(matches.length).toBe(1);
      expect(tpl.tenant_defaults.timezone).toBe('Africa/Ouagadougou');
    });
  });
});
