import { Test, TestingModule } from '@nestjs/testing';
import { AuditLogService } from './audit-log.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AuditLogService', () => {
  let service: AuditLogService;

  const mockPrismaService = {
    auditLog: {
      create: jest.fn(),
    },
  };

  const validTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';
  const validUserId   = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const validEntityId = 'b2c3d4e5-f6a7-7890-abcd-ef1234567890';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuditLogService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AuditLogService>(AuditLogService);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('log', () => {
    it('should create a CREATE audit entry with null before converted to undefined', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'CREATE',
        entity: 'Tenant',
        entityId: validEntityId,
        before: null,
        after: { name: 'Test Store' },
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: {
          tenantId: validTenantId,
          userId: validUserId,
          action: 'CREATE',
          entity: 'Tenant',
          entityId: validEntityId,
          before: undefined,
          after: { name: 'Test Store' },
        },
      });
    });

    it('should create a DELETE audit entry with null after converted to undefined', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'DELETE',
        entity: 'OrganizationMember',
        entityId: validEntityId,
        before: { userId: 'some-user' },
        after: null,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          action: 'DELETE',
          before: { userId: 'some-user' },
          after: undefined,
        }),
      });
    });

    it('should create an UPDATE audit entry with both before and after', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'UPDATE',
        entity: 'Product',
        entityId: validEntityId,
        before: { price: 1000 },
        after: { price: 1200 },
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          action: 'UPDATE',
          before: { price: 1000 },
          after: { price: 1200 },
        }),
      });
    });

    it('should convert null userId to undefined for Prisma optional field', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: null,
        action: 'CREATE',
        entity: 'SystemEvent',
        entityId: validEntityId,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: undefined,
        }),
      });
    });

    it('should pass tenantId, entity, entityId through to Prisma', async () => {
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.log({
        tenantId: validTenantId,
        userId: validUserId,
        action: 'CREATE',
        entity: 'OrganizationMember',
        entityId: validEntityId,
      });

      expect(mockPrismaService.auditLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            tenantId: validTenantId,
            entity: 'OrganizationMember',
            entityId: validEntityId,
          }),
        }),
      );
    });
  });
});
