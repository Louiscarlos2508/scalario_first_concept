import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationController } from './organization.controller';
import { OrganizationService } from './organization.service';
import { AuthGuard } from '../kernel/auth/auth.guard';
import { RolesGuard } from '../kernel/rbac/roles.guard';

describe('OrganizationController', () => {
  let controller: OrganizationController;

  const mockOrganizationService = {
    createOrganization: jest.fn().mockResolvedValue({ id: 'tenant-1', name: 'Test Org' }),
    addMember: jest.fn().mockResolvedValue({ id: 'member-1' }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrganizationController],
      providers: [
        { provide: OrganizationService, useValue: mockOrganizationService },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<OrganizationController>(OrganizationController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('should call createOrganization with name and userId', async () => {
      const mockUser = { id: 'user-1' };
      const result = await controller.create('Test Org', mockUser);

      expect(mockOrganizationService.createOrganization).toHaveBeenCalledWith('Test Org', 'user-1');
      expect(result).toEqual({ id: 'tenant-1', name: 'Test Org' });
    });
  });

  describe('addMember', () => {
    it('should call addMember with tenantId, userId and role', async () => {
      const result = await controller.addMember('ignored-param', 'user-2', 'manager', 'tenant-1');

      expect(mockOrganizationService.addMember).toHaveBeenCalledWith('tenant-1', 'user-2', 'manager');
      expect(result).toEqual({ id: 'member-1' });
    });
  });
});
