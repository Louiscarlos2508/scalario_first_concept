import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { SduiController } from './sdui.controller';
import { SduiService } from './sdui.service';

const RETAIL_POS_LAYOUT = {
  version: '1',
  business_type: 'retail',
  screen: 'pos',
  layout: { type: 'split_view' },
};

// Minimal mock for express Response
function mockResponse() {
  const headers: Record<string, string> = {};
  let body: unknown;
  return {
    setHeader: jest.fn((key: string, value: string) => {
      headers[key] = value;
    }),
    json: jest.fn((data: unknown) => {
      body = data;
    }),
    _headers: headers,
    _body: () => body,
  };
}

describe('SduiController', () => {
  let controller: SduiController;
  let sduiService: jest.Mocked<SduiService>;

  beforeEach(async () => {
    const mockSduiService = {
      getLayout: jest.fn(),
      onModuleInit: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [SduiController],
      providers: [{ provide: SduiService, useValue: mockSduiService }],
    }).compile();

    controller = module.get<SduiController>(SduiController);
    sduiService = module.get(SduiService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── getLayout ──────────────────────────────────────────────────────────────

  describe('GET /sdui/layout', () => {
    it('returns HTTP 200 with layout JSON for screen=pos (AC1)', () => {
      sduiService.getLayout.mockReturnValue(RETAIL_POS_LAYOUT);
      const res = mockResponse();

      controller.getLayout('pos', 'tenant-uuid', res as never);

      expect(sduiService.getLayout).toHaveBeenCalledWith('retail', 'pos');
      expect(res.json).toHaveBeenCalledWith(RETAIL_POS_LAYOUT);
    });

    it('sets ETag header to MD5 of layout JSON (AC2)', () => {
      sduiService.getLayout.mockReturnValue(RETAIL_POS_LAYOUT);
      const res = mockResponse();

      controller.getLayout('pos', 'tenant-uuid', res as never);

      // ETag must be set and non-empty
      expect(res.setHeader).toHaveBeenCalledWith(
        'ETag',
        expect.stringMatching(/^"[a-f0-9]{32}"$/),
      );
    });

    it('ETag is deterministic for the same layout content (AC2)', () => {
      sduiService.getLayout.mockReturnValue(RETAIL_POS_LAYOUT);
      const res1 = mockResponse();
      const res2 = mockResponse();

      controller.getLayout('pos', 'tenant-uuid', res1 as never);
      controller.getLayout('pos', 'tenant-uuid', res2 as never);

      const etag1 = (res1.setHeader as jest.Mock).mock.calls[0][1];
      const etag2 = (res2.setHeader as jest.Mock).mock.calls[0][1];
      expect(etag1).toBe(etag2);
    });

    it('delegates to SduiService with businessType=retail (AC3)', () => {
      sduiService.getLayout.mockReturnValue(RETAIL_POS_LAYOUT);
      const res = mockResponse();

      controller.getLayout('dashboard', 'any-tenant', res as never);

      expect(sduiService.getLayout).toHaveBeenCalledWith('retail', 'dashboard');
    });

    it('propagates NotFoundException when screen is unknown (AC5)', () => {
      sduiService.getLayout.mockImplementation(() => {
        throw new NotFoundException('Layout introuvable pour ce type de commerce');
      });
      const res = mockResponse();

      expect(() =>
        controller.getLayout('unknown_screen', 'tenant-uuid', res as never),
      ).toThrow(NotFoundException);
    });
  });
});
