import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as fs from 'fs';
import * as path from 'path';
import { SduiService } from './sdui.service';

jest.mock('fs');

const mockFs = fs as jest.Mocked<typeof fs>;

const RETAIL_POS_LAYOUT = {
  version: '1',
  business_type: 'retail',
  screen: 'pos',
  layout: { type: 'split_view' },
};

const RETAIL_DASHBOARD_LAYOUT = {
  version: '1',
  business_type: 'retail',
  screen: 'dashboard',
  layout: { type: 'dashboard_scroll' },
};

describe('SduiService', () => {
  let service: SduiService;

  beforeEach(async () => {
    jest.clearAllMocks();

    // Mock fs.existsSync → true
    mockFs.existsSync.mockReturnValue(true);

    // Mock fs.readdirSync → two layout files
    (mockFs.readdirSync as jest.Mock).mockReturnValue([
      'retail.pos.json',
      'retail.dashboard.json',
    ]);

    // Mock fs.readFileSync per filename
    mockFs.readFileSync.mockImplementation((filePath: fs.PathOrFileDescriptor) => {
      const name = path.basename(filePath as string);
      if (name === 'retail.pos.json')
        return JSON.stringify(RETAIL_POS_LAYOUT) as unknown as Buffer;
      if (name === 'retail.dashboard.json')
        return JSON.stringify(RETAIL_DASHBOARD_LAYOUT) as unknown as Buffer;
      return '{}' as unknown as Buffer;
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [SduiService],
    }).compile();

    service = module.get<SduiService>(SduiService);
    service.onModuleInit();
  });

  // ── onModuleInit ───────────────────────────────────────────────────────────

  describe('onModuleInit', () => {
    it('loads all .json files into the layout map (AC4)', () => {
      // Both layouts should be accessible without throwing
      expect(() => service.getLayout('retail', 'pos')).not.toThrow();
      expect(() => service.getLayout('retail', 'dashboard')).not.toThrow();
    });

    it('skips loading when layouts directory does not exist (AC4)', () => {
      mockFs.existsSync.mockReturnValue(false);

      const freshService = new SduiService();
      freshService.onModuleInit(); // should not throw

      expect(() => freshService.getLayout('retail', 'pos')).toThrow(
        NotFoundException,
      );
    });
  });

  // ── getLayout ──────────────────────────────────────────────────────────────

  describe('getLayout', () => {
    it('returns retail.pos layout for businessType=retail screen=pos (AC1)', () => {
      const layout = service.getLayout('retail', 'pos');
      expect(layout).toEqual(RETAIL_POS_LAYOUT);
    });

    it('returns retail.dashboard layout for businessType=retail screen=dashboard (AC3)', () => {
      const layout = service.getLayout('retail', 'dashboard');
      expect(layout).toEqual(RETAIL_DASHBOARD_LAYOUT);
    });

    it('throws NotFoundException for unknown businessType.screen combination (AC5)', () => {
      expect(() => service.getLayout('pharmacy', 'pos')).toThrow(
        new NotFoundException('Layout introuvable pour ce type de commerce'),
      );
    });

    it('throws NotFoundException for known businessType but unknown screen (AC5)', () => {
      expect(() => service.getLayout('retail', 'inventory')).toThrow(
        NotFoundException,
      );
    });
  });
});
