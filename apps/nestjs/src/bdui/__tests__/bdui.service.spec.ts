import { BduiService } from '../services/bdui.service';
import { BduiLayoutCacheService } from '../cache/bdui-layout-cache.service';
import { ScreenConfigRepository } from '../repositories/screen-config.repository';
import { CatalogueLoaderService } from '../services/catalogue-loader.service';
import { RbacComponentFilter } from '../filters/rbac-component-filter';
import type { ScreenConfig } from '../interfaces';

describe('BduiService', () => {
  let service: BduiService;
  let cacheService: jest.Mocked<BduiLayoutCacheService>;
  let screenConfigRepo: jest.Mocked<ScreenConfigRepository>;
  let catalogueLoader: jest.Mocked<CatalogueLoaderService>;
  let rbacFilter: RbacComponentFilter;

  const dashboardConfig: ScreenConfig = {
    schema_version: '1.0.0',
    screen: 'dashboard',
    zones: {
      kpis: [
        {
          id: 'kpi-ca',
          type: 'KPICard',
          props: { title: 'CA Total', value: 150000 },
          visible_if: { operator: 'role', value: ['OWNER'] },
        },
        {
          id: 'kpi-orders',
          type: 'KPICard',
          props: { title: 'Orders', value: 42 },
        },
      ],
      main: [],
      aside: [],
      actions: [],
    },
  };

  beforeEach(() => {
    cacheService = {
      get: jest.fn(),
      set: jest.fn(),
      invalidate: jest.fn(),
    } as unknown as jest.Mocked<BduiLayoutCacheService>;

    screenConfigRepo = {
      findByTenantAndScreen: jest.fn(),
    } as unknown as jest.Mocked<ScreenConfigRepository>;

    catalogueLoader = {
      loadScreenConfig: jest.fn(),
    } as unknown as jest.Mocked<CatalogueLoaderService>;

    rbacFilter = new RbacComponentFilter();

    service = new BduiService(cacheService, screenConfigRepo, catalogueLoader, rbacFilter);
  });

  describe('getLayout', () => {
    it('returns cached layout on cache HIT', async () => {
      cacheService.get.mockResolvedValue(dashboardConfig);

      const result = await service.getLayout('tenant-A', 'dashboard', ['OWNER']);

      expect(result).toEqual(dashboardConfig);
      expect(cacheService.get).toHaveBeenCalledWith('tenant-A', 'dashboard', ['OWNER']);
      expect(screenConfigRepo.findByTenantAndScreen).not.toHaveBeenCalled();
    });

    it('loads from DB on cache MISS and filters by role', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen.mockResolvedValue({
        ...dashboardConfig,
      });

      const result = await service.getLayout('tenant-A', 'dashboard', ['COMMERCIAL']);

      expect(result.zones.kpis!).toHaveLength(1);
      expect(result.zones.kpis![0].id).toBe('kpi-orders');
      expect(cacheService.set).toHaveBeenCalled();
    });

    it('falls back to filesystem when DB returns null', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen.mockResolvedValue(null);
      catalogueLoader.loadScreenConfig.mockReturnValue(dashboardConfig);

      const result = await service.getLayout('tenant-A', 'dashboard', ['OWNER']);

      expect(result.screen).toBe('dashboard');
      expect(catalogueLoader.loadScreenConfig).toHaveBeenCalledWith('tenant-A', 'dashboard');
      expect(cacheService.set).toHaveBeenCalled();
    });

    it('throws NotFoundException when neither DB nor filesystem has the screen', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen.mockResolvedValue(null);
      catalogueLoader.loadScreenConfig.mockReturnValue(null);

      await expect(service.getLayout('tenant-A', 'nonexistent', ['OWNER'])).rejects.toThrow(
        'Screen "nonexistent" not found',
      );
    });

    it('logs structured fields on cache miss', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen.mockResolvedValue({ ...dashboardConfig });

      await service.getLayout('tenant-A', 'dashboard', ['OWNER']);

      expect(cacheService.set).toHaveBeenCalledWith(
        'tenant-A',
        'dashboard',
        ['OWNER'],
        expect.objectContaining({ screen: 'dashboard' }),
      );
    });
  });

  describe('getBulkLayouts', () => {
    it('returns multiple layouts keyed by screenId', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen
        .mockResolvedValueOnce({ ...dashboardConfig })
        .mockResolvedValueOnce({
          schema_version: '1.0.0',
          screen: 'ventes',
          zones: { kpis: [], main: [], aside: [], actions: [] },
        });

      const result = await service.getBulkLayouts('tenant-A', ['dashboard', 'ventes'], ['OWNER']);

      expect(Object.keys(result)).toHaveLength(2);
      expect(result['dashboard']).toBeDefined();
      expect(result['ventes']).toBeDefined();
    });
  });

  describe('normalization', () => {
    it('fills missing schema_version and screen from screenId', async () => {
      cacheService.get.mockResolvedValue(null);
      screenConfigRepo.findByTenantAndScreen.mockResolvedValue({
        zones: { kpis: [], main: [], aside: [], actions: [] },
      });

      const result = await service.getLayout('t1', 'my-screen', ['OWNER']);

      expect(result.schema_version).toBe('1.0.0');
      expect(result.screen).toBe('my-screen');
    });
  });
});
