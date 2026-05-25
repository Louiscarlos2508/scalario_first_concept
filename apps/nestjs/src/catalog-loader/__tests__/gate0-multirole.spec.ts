import { loadDomainTemplate } from '../templates.loader';
import { CatalogueValidatorService } from '../services/catalogue-validator.service';
import { WorkflowValidatorService } from '../../engines/workflow/validator/workflow-validator.service';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

/**
 * STORY-043 — Gate 0 multi-role validation (AC-10 / AC-11 / AC-17 / AC-19).
 *
 * Proves the contract: a single `retail_fresh_produce.json` template
 * serves 3 distinct roles with 3 distinct dashboard layouts +
 * permissions, AND the same template is portable to a second tenant
 * (CI locale) without modification.
 *
 * This stays at the catalogue level (no live DB) — the network paths
 * are exercised by individual story tests (STORY-032 dispatcher,
 * STORY-036 idempotency, STORY-040 modules). The Gate-0 contract here
 * is that the template + modules + workflow tie together coherently.
 */

const MODULE_IDS = [
  'module_dashboard_owner',
  'module_dashboard_manager',
  'module_dashboard_commercial',
  'module_ventes',
  'module_pertes',
  'module_stock',
] as const;

function resolveCatalogPath(rel: string): string {
  const candidates = [
    resolve(process.cwd(), 'catalog', rel),
    resolve(process.cwd(), '..', '..', 'catalog', rel),
  ];
  for (const p of candidates) {
    try {
      readFileSync(p, 'utf8');
      return p;
    } catch {
      /* try next */
    }
  }
  throw new Error(`Catalog file not found: ${rel}`);
}

describe('STORY-043 — Gate 0 multi-role validation', () => {
  const validator = new CatalogueValidatorService(new WorkflowValidatorService());

  describe('AC-10 — 3 roles → 3 distinct dashboards + 3 distinct nav menus', () => {
    it('OWNER / MANAGER / COMMERCIAL get distinct dashboard_module_id', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const dashboards = new Map<string, string>();
      for (const role of tpl.roles) {
        dashboards.set(role.id, role.dashboard_module_id);
      }
      expect(dashboards.get('OWNER')).toBe('module_dashboard_owner');
      expect(dashboards.get('MANAGER')).toBe('module_dashboard_manager');
      expect(dashboards.get('COMMERCIAL')).toBe('module_dashboard_commercial');
      // All three are different.
      expect(new Set(dashboards.values()).size).toBe(3);
    });

    it('navigation_per_role yields 3 distinct landing screens', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const landings = Object.values(tpl.navigation_per_role).map(
        (n) => n.landing_screen_id,
      );
      expect(new Set(landings).size).toBe(3);
    });

    it('each role has a non-empty bottom_nav list capped at 5', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      for (const [role, nav] of Object.entries(tpl.navigation_per_role)) {
        expect(nav.bottom_nav.length).toBeGreaterThan(0);
        expect(nav.bottom_nav.length).toBeLessThanOrEqual(5);
        expect(role).toMatch(/^(OWNER|MANAGER|COMMERCIAL)$/);
      }
    });
  });

  describe('AC-11 — cross-RBAC permissions (no role can do everything)', () => {
    it('COMMERCIAL cannot read the owner dashboard nor validate clôtures', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const com = tpl.roles.find((r) => r.id === 'COMMERCIAL')!;
      expect(com.permissions.some((p) => p.startsWith('module_dashboard_owner'))).toBe(
        false,
      );
      expect(com.permissions.some((p) => p.includes('cloture_caisse.validate'))).toBe(
        false,
      );
    });

    it('MANAGER cannot read owner dashboard nor write to ventes', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const mgr = tpl.roles.find((r) => r.id === 'MANAGER')!;
      expect(mgr.permissions.some((p) => p.startsWith('module_dashboard_owner'))).toBe(
        false,
      );
      expect(mgr.permissions.some((p) => p.startsWith('module_ventes.write'))).toBe(
        false,
      );
    });

    it('OWNER has read.all on the financial modules', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const own = tpl.roles.find((r) => r.id === 'OWNER')!;
      expect(own.permissions).toEqual(
        expect.arrayContaining([
          'module_ventes.read.all',
          'module_pertes.read.all',
          'module_stock.read.all',
        ]),
      );
    });
  });

  describe('AC-04 — 4 Gate 0 functions are covered by the catalogue', () => {
    it('F1 Dashboard owner — module_dashboard_owner declares KPIs + Chart + DataTable', () => {
      const owner = JSON.parse(
        readFileSync(resolveCatalogPath('_archive_v13/modules/module_dashboard_owner.json'), 'utf8'),
      );
      const screen = owner.screens[0];
      expect(screen.zones.kpis.length).toBeGreaterThanOrEqual(4);
      expect(screen.zones.main.find((c: { type: string }) => c.type === 'LineChart')).toBeDefined();
      expect(screen.zones.main.find((c: { type: string }) => c.type === 'DataTable')).toBeDefined();
    });

    it('F2 Arrivage validation — module_stock declares arrivages_validation_form', () => {
      const stock = JSON.parse(
        readFileSync(resolveCatalogPath('_archive_v13/modules/module_stock.json'), 'utf8'),
      );
      const screens = (stock.screens as Array<{ screen: string }>).map((s) => s.screen);
      expect(screens).toContain('arrivages_validation_form');
      expect(stock.actions.validate_arrivage).toBeDefined();
    });

    it('F3 Déclaration perte — module_pertes declares perte_create + 5 causes', () => {
      const pertes = JSON.parse(
        readFileSync(resolveCatalogPath('_archive_v13/modules/module_pertes.json'), 'utf8'),
      );
      const screens = (pertes.screens as Array<{ screen: string }>).map((s) => s.screen);
      expect(screens).toContain('perte_create');
      const cause = (pertes.entities[0].fields as Array<{ name: string; values?: string[] }>).find(
        (f) => f.name === 'cause',
      );
      expect(cause?.values).toHaveLength(5);
    });

    it('F4 Clôture caisse — wf_cloture_caisse workflow has 5 FSM states', () => {
      const wf = JSON.parse(
        readFileSync(resolveCatalogPath('modules/operations/cloture_caisse.json'), 'utf8'),
      );
      expect(Object.keys(wf.states)).toHaveLength(5);
      expect(wf.initial_state).toBe('saisie_fond_restant');
    });
  });

  describe('AC-17 — template portability (same JSON, 2nd tenant fr-CI)', () => {
    it('the domain template carries NO Burkina/BF/Ouagadougou outside tenant_defaults.timezone', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      const serialized = JSON.stringify(tpl);
      // Ouagadougou must appear exactly once: in tenant_defaults.timezone.
      const ougMatches = serialized.match(/Africa\/Ouagadougou/g) ?? [];
      expect(ougMatches.length).toBe(1);
      // No "Burkina" anywhere (this is a portable template).
      expect(serialized).not.toMatch(/Burkina/i);
    });

    it('tenant_defaults has the 3 Global Scale knobs (currency, locale, timezone)', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.tenant_defaults.currency).toBe('XOF');
      expect(tpl.tenant_defaults.locale).toBe('fr-BF');
      expect(tpl.tenant_defaults.timezone).toBe('Africa/Ouagadougou');
      // For a second tenant in CI, only the override changes — no template edits.
    });

    it('payment_methods_enabled is in tenant_defaults (not hardcoded in modules)', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.tenant_defaults.payment_methods_enabled).toEqual([
        'cash',
        'mobile_money',
        'credit',
      ]);
      // The modules don't list providers; resolved from tenant config (STORY-042).
      const ventes = JSON.parse(
        readFileSync(resolveCatalogPath('_archive_v13/modules/module_ventes.json'), 'utf8'),
      );
      const venteRaw = readFileSync(
        resolveCatalogPath('_archive_v13/modules/module_ventes.json'),
        'utf8',
      );
      // payment_method enum is the only enumeration; no provider literal.
      expect(venteRaw).not.toMatch(/['"]wave['"]/);
      expect(venteRaw).not.toMatch(/['"]orange_money['"]/);
      void ventes;
    });
  });

  describe('AC-19 — sector-first checklist (12 points)', () => {
    it('1. datasets: 6 modules declared in template match modules[] files on disk', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      for (const mod of tpl.modules) {
        const path = resolveCatalogPath(`_archive_v13/modules/${mod.module_id}.json`);
        expect(path).toBeTruthy();
      }
    });

    it('2. locale: tenant_defaults.locale matches IETF BCP-47', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.tenant_defaults.locale).toMatch(/^[a-z]{2}-[A-Z]{2}$/);
    });

    it('3. devise: currency is ISO 4217', () => {
      const tpl = loadDomainTemplate('retail_fresh_produce');
      expect(tpl.tenant_defaults.currency).toMatch(/^[A-Z]{3}$/);
    });

    it('4-12. integrity: each module passes ModuleConfig Zod + DAG validator', () => {
      for (const moduleId of MODULE_IDS) {
        const result = validator.validateFile(
          resolveCatalogPath(`_archive_v13/modules/${moduleId}.json`),
          'module',
        );
        if (!result.valid) {
          const summary =
            result.errors?.map((e) => `[${e.path}] ${e.message}`).join('; ') ??
            result.parseError;
          throw new Error(`${moduleId} validation failed: ${summary}`);
        }
        expect(result.valid).toBe(true);
      }
    });
  });

  describe('AC-01/AC-19 — no business logic / no business literals anywhere', () => {
    it('the template + 6 modules + workflow contain NO mention of FCFA / Wave / Burkina', () => {
      const files = [
        '_archive_v13/domains/retail_fresh_produce.json',
        ...MODULE_IDS.map((id) => `_archive_v13/modules/${id}.json`),
        'modules/operations/cloture_caisse.json',
      ];
      for (const f of files) {
        const raw = readFileSync(resolveCatalogPath(f), 'utf8');
        expect(raw).not.toMatch(/FCFA/i);
        expect(raw).not.toMatch(/Burkina/i);
        expect(raw).not.toMatch(/\bWave\b/);
        expect(raw).not.toMatch(/Orange Money/i);
      }
    });

    it('no module hardcodes XOF (currency_source: tenant.config.currency)', () => {
      for (const moduleId of MODULE_IDS) {
        const raw = readFileSync(resolveCatalogPath(`_archive_v13/modules/${moduleId}.json`), 'utf8');
        expect(raw).not.toMatch(/"XOF"/);
      }
    });
  });
});
