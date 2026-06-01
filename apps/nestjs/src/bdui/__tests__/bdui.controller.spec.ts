import { BduiController } from '../bdui.controller';
import { BduiService } from '../services/bdui.service';
import { parseBulkScreens } from '../dto/get-bulk-layouts.dto';
import { ForbiddenException } from '@nestjs/common';
import type { ScreenConfig } from '../interfaces';

describe('BduiController', () => {
  let controller: BduiController;
  let bduiService: jest.Mocked<BduiService>;

  const dashboardConfig: ScreenConfig = {
    schema_version: '1.0.0',
    screen: 'dashboard',
    zones: { kpis: [], main: [], aside: [], actions: [] },
  };

  const mockTenantsService = {
    getActiveBySlug: jest.fn(),
  };

  beforeEach(() => {
    bduiService = {
      getLayout: jest.fn(),
      getBulkLayouts: jest.fn(),
    } as unknown as jest.Mocked<BduiService>;

    mockTenantsService.getActiveBySlug.mockReset();
    controller = new BduiController(bduiService, mockTenantsService as any);
  });

  describe('getLayout', () => {
    it('returns layout from service using matching uuid tenant', async () => {
      bduiService.getLayout.mockResolvedValue(dashboardConfig);

      const result = await controller.getLayout(
        { tenant: 'tenant-uuid-123', screenId: 'dashboard' },
        { user_id: 'user1', tenant_id: 'tenant-uuid-123', roles: ['OWNER'], jti: '', iat: 0, department_id: null } as any,
        'tenant-uuid-123',
      );

      expect(result).toEqual(dashboardConfig);
      expect(bduiService.getLayout).toHaveBeenCalledWith('tenant-uuid-123', 'dashboard', ['OWNER']);
    });

    it('resolves slug and delegates to service', async () => {
      bduiService.getLayout.mockResolvedValue(dashboardConfig);
      mockTenantsService.getActiveBySlug.mockResolvedValue('tenant-uuid-456');

      const result = await controller.getLayout(
        { tenant: 'blandine', screenId: 'dashboard_owner' },
        { user_id: 'user1', tenant_id: 'tenant-uuid-456', roles: ['OWNER'], jti: '', iat: 0, department_id: null } as any,
        'tenant-uuid-456',
      );

      expect(result).toEqual(dashboardConfig);
      expect(mockTenantsService.getActiveBySlug).toHaveBeenCalledWith('blandine');
    });

    it('throws ForbiddenException when tenant mismatch', async () => {
      await expect(
        controller.getLayout(
          { tenant: 'other', screenId: 'dashboard' },
          {
            user_id: 'u1',
            tenant_id: 'acme',
            roles: ['OWNER'],
            department_id: null,
            jti: 'x',
            exp: 0,
          },
          'acme',
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('parseBulkScreens (DTO validation)', () => {
    it('throws when screens exceed max 10', () => {
      expect(() =>
        parseBulkScreens(Array.from({ length: 11 }, (_, i) => `s${i}`).join(',')),
      ).toThrow(/maximum 10/i);
    });

    it('throws when screens is empty', () => {
      expect(() => parseBulkScreens('')).toThrow(/at least one/i);
    });

    it('parses valid screens list', () => {
      const result = parseBulkScreens('dashboard,ventes,stock');
      expect(result).toEqual(['dashboard', 'ventes', 'stock']);
    });

    it('trims whitespace from screens', () => {
      const result = parseBulkScreens(' dashboard , ventes ');
      expect(result).toEqual(['dashboard', 'ventes']);
    });
  });

  describe('getBulkLayouts', () => {
    it('returns layout map for matching tenant', async () => {
      bduiService.getBulkLayouts.mockResolvedValue({
        dashboard: dashboardConfig,
        ventes: { ...dashboardConfig, screen: 'ventes' },
      });

      const result = await controller.getBulkLayouts(
        'acme',
        'dashboard,ventes',
        {
          user_id: 'u1',
          tenant_id: 'acme',
          roles: ['OWNER'],
          department_id: null,
          jti: 'x',
          exp: 0,
        },
        'acme',
      );

      expect(Object.keys(result)).toHaveLength(2);
      expect(bduiService.getBulkLayouts).toHaveBeenCalledWith(
        'acme',
        ['dashboard', 'ventes'],
        ['OWNER'],
      );
    });

    it('throws ForbiddenException when tenant mismatch in bulk', async () => {
      await expect(
        controller.getBulkLayouts(
          'other',
          'dashboard',
          {
            user_id: 'u1',
            tenant_id: 'acme',
            roles: ['OWNER'],
            department_id: null,
            jti: 'x',
            exp: 0,
          },
          'acme',
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
