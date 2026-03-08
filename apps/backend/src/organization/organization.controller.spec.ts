import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationController } from './organization.controller';
import { OrganizationService } from './organization.service';
import { AuthGuard } from '../kernel/auth/auth.guard';

describe('OrganizationController', () => {
  let controller: OrganizationController;

  const mockOrganizationService = {
    createOrganization: jest.fn().mockImplementation((name, userId) => {
      return Promise.resolve({ id: '1', name, members: [{ userId, role: 'owner' }] });
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrganizationController],
      providers: [
        {
          provide: OrganizationService,
          useValue: mockOrganizationService,
        },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<OrganizationController>(OrganizationController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
