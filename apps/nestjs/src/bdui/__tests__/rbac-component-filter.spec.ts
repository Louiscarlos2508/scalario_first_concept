import { RbacComponentFilter } from '../filters/rbac-component-filter';
import type { ScreenConfig, ComponentConfig } from '../interfaces';

describe('RbacComponentFilter', () => {
  let filter: RbacComponentFilter;

  beforeEach(() => {
    filter = new RbacComponentFilter();
  });

  const makeConfig = (zones: Partial<ScreenConfig['zones']>): ScreenConfig => ({
    schema_version: '1.0.0',
    screen: 'dashboard',
    zones: {
      kpis: zones.kpis ?? [],
      main: zones.main ?? [],
      aside: zones.aside ?? [],
      actions: zones.actions ?? [],
    },
  });

  const kpiOwnerOnly: ComponentConfig = {
    id: 'kpi-ca',
    type: 'KPICard',
    props: { title: 'CA Total', value: 150000 },
    visible_if: { operator: 'role', value: ['OWNER'] },
  };

  const kpiPublic: ComponentConfig = {
    id: 'kpi-orders',
    type: 'KPICard',
    props: { title: 'Orders', value: 42 },
  };

  const sectionWithChildren: ComponentConfig = {
    id: 'section-mixed',
    type: 'Section',
    props: {
      title: 'Metrics',
      children: [
        { id: 'child-owner', type: 'KPICard', visible_if: { operator: 'role', value: ['OWNER'] } },
        { id: 'child-public', type: 'KPICard' },
      ],
    },
  };

  describe('AC-10: role-based filtering removes components', () => {
    it('removes a component when role does not match visible_if', () => {
      const config = makeConfig({ kpis: [kpiOwnerOnly] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.kpis!).toHaveLength(0);
    });

    it('keeps a component when role matches visible_if', () => {
      const config = makeConfig({ kpis: [kpiOwnerOnly] });
      const result = filter.apply(config, ['OWNER']);
      expect(result.zones.kpis!).toHaveLength(1);
      expect(result.zones.kpis![0].id).toBe('kpi-ca');
    });

    it('keeps a component when user has multiple roles and one matches', () => {
      const config = makeConfig({ kpis: [kpiOwnerOnly] });
      const result = filter.apply(config, ['COMMERCIAL', 'OWNER']);
      expect(result.zones.kpis!).toHaveLength(1);
    });
  });

  describe('AC-11: recursive filtering on all zones and children', () => {
    it('filters all four zones', () => {
      const config: ScreenConfig = {
        schema_version: '1.0.0',
        screen: 'dashboard',
        zones: {
          kpis: [{ ...kpiOwnerOnly }],
          main: [{ ...kpiOwnerOnly, id: 'main-owner' }],
          aside: [{ ...kpiOwnerOnly, id: 'aside-owner' }],
          actions: [{ ...kpiOwnerOnly, id: 'actions-owner' }],
        },
      };
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.kpis!).toHaveLength(0);
      expect(result.zones.main!).toHaveLength(0);
      expect(result.zones.aside!).toHaveLength(0);
      expect(result.zones.actions!).toHaveLength(0);
    });

    it('recursively filters children inside a Section', () => {
      const config = makeConfig({ main: [sectionWithChildren] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.main!).toHaveLength(1);
      const section = result.zones.main![0];
      const children = section.props!.children as ComponentConfig[];
      expect(children).toHaveLength(1);
      expect(children[0].id).toBe('child-public');
    });
  });

  describe('AC-12: OWNER and COMMERCIAL get different payloads', () => {
    it('OWNER sees KPICard CA Total, COMMERCIAL does not', () => {
      const config = makeConfig({ kpis: [kpiOwnerOnly, kpiPublic] });

      const ownerResult = filter.apply(config, ['OWNER']);
      expect(ownerResult.zones.kpis!).toHaveLength(2);

      const commercialResult = filter.apply(config, ['COMMERCIAL']);
      expect(commercialResult.zones.kpis!).toHaveLength(1);
      expect(commercialResult.zones.kpis![0].id).toBe('kpi-orders');
    });
  });

  describe('AC-13: components without visible_if are always visible', () => {
    it('includes component with no visible_if regardless of roles', () => {
      const config = makeConfig({ kpis: [kpiPublic] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.kpis!).toHaveLength(1);
    });
  });

  describe('AC-14: empty zone when all components filtered', () => {
    it('returns empty array for a zone where everything is filtered out', () => {
      const config = makeConfig({ aside: [kpiOwnerOnly] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.aside!).toEqual([]);
      expect(result.zones).toBeDefined();
    });
  });

  describe('edge cases', () => {
    it('fail-closed: operator "role" with non-array value removes component', () => {
      const badConfig: ComponentConfig = {
        id: 'bad',
        type: 'KPICard',
        visible_if: { operator: 'role', value: 'not-an-array' as unknown as string[] },
      };
      const config = makeConfig({ kpis: [badConfig] });
      const result = filter.apply(config, ['OWNER']);
      expect(result.zones.kpis!).toHaveLength(0);
    });

    it('operators other than "role" default to visible (data-aware, evaluated client-side)', () => {
      const dataAware: ComponentConfig = {
        id: 'data-aware',
        type: 'KPICard',
        visible_if: { operator: '>', value: ['revenue', 1000] },
      };
      const config = makeConfig({ kpis: [dataAware] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.kpis!).toHaveLength(1);
    });

    it('AND/OR operators default to visible', () => {
      const andOp: ComponentConfig = {
        id: 'and-op',
        type: 'KPICard',
        visible_if: { operator: 'AND', value: [{ operator: 'role', value: ['OWNER'] }] },
      };
      const config = makeConfig({ kpis: [andOp] });
      const result = filter.apply(config, ['COMMERCIAL']);
      expect(result.zones.kpis!).toHaveLength(1);
    });

    it('handles undefined zones gracefully', () => {
      const config: ScreenConfig = {
        schema_version: '1.0.0',
        screen: 'test',
        zones: {} as ScreenConfig['zones'],
      };
      const result = filter.apply(config, ['OWNER']);
      expect(result.zones.kpis).toEqual([]);
      expect(result.zones.main).toEqual([]);
    });

    it('preserves non-zone top-level keys in config', () => {
      const config: ScreenConfig = {
        schema_version: '1.0.0',
        screen: 'dashboard',
        zones: { kpis: [kpiPublic], main: [], aside: [], actions: [] },
        custom_field: 'preserved',
      } as ScreenConfig;
      const result = filter.apply(config, ['OWNER']);
      expect((result as Record<string, unknown>).custom_field).toBe('preserved');
    });
  });
});
