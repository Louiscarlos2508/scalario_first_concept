import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { CatalogueValidatorService } from '../services/catalogue-validator.service';
import { WorkflowValidatorService } from '../../engines/workflow/validator/workflow-validator.service';

const MODULE_IDS = [
  'module_dashboard_owner',
  'module_dashboard_manager',
  'module_dashboard_commercial',
  'module_ventes',
  'module_pertes',
  'module_stock',
] as const;

function resolveModulePath(moduleId: string): string {
  const candidates = [
    resolve(process.cwd(), 'catalog', 'modules', `${moduleId}.json`),
    resolve(process.cwd(), '..', '..', 'catalog', 'modules', `${moduleId}.json`),
  ];
  for (const p of candidates) {
    try {
      readFileSync(p, 'utf8');
      return p;
    } catch {
      /* try next */
    }
  }
  throw new Error(`Module not found: ${moduleId}`);
}

function readModule(moduleId: string): { content: unknown; path: string } {
  const path = resolveModulePath(moduleId);
  const raw = readFileSync(path, 'utf8');
  return { content: JSON.parse(raw), path };
}

describe('STORY-040 — Modules Phase 1 (catalog/modules/*.json)', () => {
  const validator = new CatalogueValidatorService(new WorkflowValidatorService());

  describe('AC-01 — all 6 files exist and are valid JSON', () => {
    it.each(MODULE_IDS)('%s parses as JSON', (moduleId) => {
      const { content } = readModule(moduleId);
      expect(content).not.toBeNull();
      expect(typeof content).toBe('object');
    });
  });

  describe('AC-02/AC-03/AC-24 — schema validation via CatalogueValidatorService', () => {
    it.each(MODULE_IDS)('%s passes ModuleConfig Zod (and any DAG)', (moduleId) => {
      const { content, path } = readModule(moduleId);
      const result = validator.validateFile(path, 'module');
      if (!result.valid) {
        // Make the failure verbose for debugging
        const summary =
          result.errors?.map((e) => `[${e.path}] ${e.message}`).join('; ') ??
          result.parseError ??
          JSON.stringify(result.dagErrors);
        throw new Error(`${moduleId} failed validation: ${summary}`);
      }
      expect(result.valid).toBe(true);
      // top-level id matches the file basename per AC-03
      expect((content as { id: string }).id).toBe(moduleId);
    });
  });

  describe('AC-04/AC-07/AC-09 — dashboards have the right zones', () => {
    it('dashboard_owner has 4 KPIs + LineChart + clotures table + Button', () => {
      const { content } = readModule('module_dashboard_owner') as {
        content: { screens: Array<{ zones: Record<string, Array<{ type: string }>> }> };
      };
      const screen = content.screens[0];
      expect(screen.zones.kpis.length).toBe(4);
      expect(screen.zones.main.find((c) => c.type === 'LineChart')).toBeDefined();
      expect(screen.zones.main.find((c) => c.type === 'DataTable')).toBeDefined();
      expect(screen.zones.actions[0].type).toBe('Button');
    });

    it('dashboard_manager has 3 KPIs and arrivages DataTable', () => {
      const { content } = readModule('module_dashboard_manager') as {
        content: {
          screens: Array<{ zones: Record<string, Array<{ type: string; id?: string }>> }>;
        };
      };
      const screen = content.screens[0];
      expect(screen.zones.kpis.length).toBe(3);
      expect(screen.zones.main.find((c) => c.type === 'DataTable')?.id).toBe('table_arrivages');
    });

    it('dashboard_commercial has ProductGrid + Sell CTA', () => {
      const { content } = readModule('module_dashboard_commercial') as {
        content: { screens: Array<{ zones: Record<string, Array<{ type: string }>> }> };
      };
      const screen = content.screens[0];
      expect(screen.zones.main.find((c) => c.type === 'ProductGrid')).toBeDefined();
      const sellBtn = screen.zones.main.find((c) => c.type === 'Button');
      expect(sellBtn).toBeDefined();
    });
  });

  describe('AC-11/AC-13 — module_ventes has Vente entity + idempotent create action', () => {
    it('declares entity Vente with payment_method enum + payment_provider visible_if', () => {
      const { content } = readModule('module_ventes') as {
        content: {
          entities: Array<{ name: string; fields: Array<{ name: string; type: string }> }>;
        };
      };
      const vente = content.entities.find((e) => e.name === 'Vente');
      expect(vente).toBeDefined();
      const fields = vente!.fields;
      expect(fields.find((f) => f.name === 'payment_method')).toMatchObject({ type: 'enum' });
      expect(fields.find((f) => f.name === 'payment_provider')).toBeDefined();
    });

    it('create_vente action is declared idempotent', () => {
      const { content } = readModule('module_ventes') as {
        content: { actions: Record<string, { handler: string; idempotent?: boolean }> };
      };
      expect(content.actions.create_vente).toBeDefined();
      expect(content.actions.create_vente.idempotent).toBe(true);
      expect(content.actions.create_vente.handler).toBe('crud.create');
    });
  });

  describe('AC-15/AC-17/AC-18 — module_pertes', () => {
    it('declares entity Perte with the 5 documented causes', () => {
      const { content } = readModule('module_pertes') as {
        content: {
          entities: Array<{
            name: string;
            fields: Array<{ name: string; values?: string[] }>;
          }>;
        };
      };
      const perte = content.entities[0];
      expect(perte.name).toBe('Perte');
      const cause = perte.fields.find((f) => f.name === 'cause');
      expect(cause?.values).toEqual(['casse', 'peremption', 'vol', 'demarque_inconnue', 'autre']);
    });

    it('uses conflict_strategy "manual"', () => {
      const { content } = readModule('module_pertes') as {
        content: { conflict_strategy: string };
      };
      expect(content.conflict_strategy).toBe('manual');
    });

    it('declares an inline wf_perte_validation workflow', () => {
      const { content } = readModule('module_pertes') as {
        content: { workflows: Record<string, unknown> };
      };
      expect(content.workflows.wf_perte_validation).toBeDefined();
    });
  });

  describe('AC-19/AC-20 — module_stock has 3 entities + fresh-produce fields', () => {
    it('declares Product, Arrivage, SeuilStock', () => {
      const { content } = readModule('module_stock') as {
        content: { entities: Array<{ name: string }> };
      };
      const names = content.entities.map((e) => e.name).sort();
      expect(names).toEqual(['Arrivage', 'Product', 'SeuilStock']);
    });

    it('Product has taux_de_frotte, conversion_vrac_sachet, freshness_indicator', () => {
      const { content } = readModule('module_stock') as {
        content: { entities: Array<{ name: string; fields: Array<{ name: string }> }> };
      };
      const product = content.entities.find((e) => e.name === 'Product')!;
      const fieldNames = product.fields.map((f) => f.name);
      expect(fieldNames).toEqual(
        expect.arrayContaining(['taux_de_frotte', 'conversion_vrac_sachet', 'freshness_indicator']),
      );
    });
  });

  describe('AC-22 — currency fields use tenant.config.currency (no hardcoded XOF in entities)', () => {
    it('module_ventes Vente.total_amount currency_source is dynamic', () => {
      const { content } = readModule('module_ventes') as {
        content: {
          entities: Array<{
            fields: Array<{ name: string; currency_source?: string }>;
          }>;
        };
      };
      const totalAmount = content.entities[0].fields.find((f) => f.name === 'total_amount')!;
      expect(totalAmount.currency_source).toBe('tenant.config.currency');
    });
  });

  describe('AC-29/AC-30 — Global Scale: no hardcoded business values', () => {
    it.each(MODULE_IDS)(
      '%s contains no FCFA / Burkina Faso / Wave / Orange Money / MTN literals',
      (moduleId) => {
        const raw = readFileSync(resolveModulePath(moduleId), 'utf8');
        expect(raw).not.toMatch(/FCFA/i);
        expect(raw).not.toMatch(/Burkina Faso/i);
        expect(raw).not.toMatch(/\bWave\b/);
        expect(raw).not.toMatch(/Orange Money/i);
        expect(raw).not.toMatch(/MTN MoMo/i);
      },
    );

    it.each(MODULE_IDS)(
      '%s contains no hardcoded XOF currency literal (must use tenant.config.currency)',
      (moduleId) => {
        const raw = readFileSync(resolveModulePath(moduleId), 'utf8');
        // "XOF" in the catalog/modules/ files is verboten — currency comes
        // from tenant_defaults (STORY-039) and is resolved at render time.
        expect(raw).not.toMatch(/"XOF"/);
      },
    );
  });

  describe('AC-28 — snapshot of module structure (catch structural regressions)', () => {
    const expected: Record<
      (typeof MODULE_IDS)[number],
      { entities: number; screens: number; actions: number }
    > = {
      module_dashboard_owner: { entities: 0, screens: 1, actions: 0 },
      module_dashboard_manager: { entities: 0, screens: 1, actions: 0 },
      module_dashboard_commercial: { entities: 0, screens: 1, actions: 0 },
      module_ventes: { entities: 1, screens: 3, actions: 3 },
      module_pertes: { entities: 1, screens: 3, actions: 3 },
      module_stock: { entities: 3, screens: 4, actions: 4 },
    };

    it.each(MODULE_IDS)('%s matches the expected counts', (moduleId) => {
      const { content } = readModule(moduleId) as {
        content: {
          entities?: unknown[];
          screens?: unknown[];
          actions?: Record<string, unknown>;
        };
      };
      const exp = expected[moduleId];
      expect(content.entities?.length ?? 0).toBe(exp.entities);
      expect(content.screens?.length ?? 0).toBe(exp.screens);
      expect(Object.keys(content.actions ?? {}).length).toBe(exp.actions);
    });
  });
});
