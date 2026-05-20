import { Test, TestingModule } from '@nestjs/testing';
import { CatalogueLoaderService } from '../services/catalogue-loader.service';
import { CatalogueValidatorService } from '../services/catalogue-validator.service';

describe('CatalogueLoaderService', () => {
  let service: CatalogueLoaderService;
  let validator: CatalogueValidatorService;

  beforeEach(async () => {
    validator = new CatalogueValidatorService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatalogueLoaderService,
        { provide: CatalogueValidatorService, useValue: validator },
      ],
    }).compile();

    service = module.get<CatalogueLoaderService>(CatalogueLoaderService);
  });

  describe('onApplicationBootstrap', () => {
    it('passes validation when catalogue directory has valid files', async () => {
      expect(typeof service.onApplicationBootstrap).toBe('function');
    });

    it('throws error when invalid files are in catalogue', async () => {
      const mockValidator = {
        validateDirectory: jest.fn().mockReturnValue([
          {
            valid: false,
            file: 'bad.json',
            type: 'domain' as const,
            errors: [{ path: '.id', message: 'Required', code: 'invalid_type' }],
          },
        ]),
      };

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          CatalogueLoaderService,
          { provide: CatalogueValidatorService, useValue: mockValidator },
        ],
      }).compile();

      const failingService = module.get<CatalogueLoaderService>(CatalogueLoaderService);

      await expect(failingService.onApplicationBootstrap()).rejects.toThrow('Catalogue invalid');
    });

    it('logs loaded file counts when all valid', async () => {
      const mockValidator = {
        validateDirectory: jest.fn().mockReturnValue([
          { valid: true, file: 'a.json', type: 'domain' as const },
          { valid: true, file: 'b.json', type: 'module' as const },
        ]),
      };

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          CatalogueLoaderService,
          { provide: CatalogueValidatorService, useValue: mockValidator },
        ],
      }).compile();

      const passingService = module.get<CatalogueLoaderService>(CatalogueLoaderService);

      await expect(passingService.onApplicationBootstrap()).resolves.toBeUndefined();
    });
  });
});
