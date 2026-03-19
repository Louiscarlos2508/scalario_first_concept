import { Test, TestingModule } from '@nestjs/testing';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockPrisma = {
  role: { findMany: jest.fn() },
  organizationMember: { findMany: jest.fn() },
  notification: {
    createMany: jest.fn(),
    findMany: jest.fn(),
    updateMany: jest.fn(),
    count: jest.fn(),
  },
};

const TENANT = 'tenant-1';
const USER = 'user-1';

describe('NotificationsService', () => {
  let service: NotificationsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();
    service = module.get(NotificationsService);
    jest.clearAllMocks();
  });

  describe('onLowStockDetected()', () => {
    it('creates one notification per eligible user', async () => {
      mockPrisma.role.findMany.mockResolvedValue([{ id: 'role-owner' }]);
      mockPrisma.organizationMember.findMany.mockResolvedValue([
        { userId: 'user-1' },
        { userId: 'user-2' },
      ]);
      mockPrisma.notification.createMany.mockResolvedValue({ count: 2 });

      await service.onLowStockDetected({
        tenantId: TENANT,
        catalogItemId: 'item-1',
        itemName: 'Riz',
        stockQuantity: 3,
        minStockLevel: 10,
      });

      expect(mockPrisma.notification.createMany).toHaveBeenCalledWith({
        data: [
          expect.objectContaining({ userId: 'user-1', title: 'Stock critique' }),
          expect.objectContaining({ userId: 'user-2', title: 'Stock critique' }),
        ],
        skipDuplicates: true,
      });
    });

    it('does nothing when no eligible users found', async () => {
      mockPrisma.role.findMany.mockResolvedValue([{ id: 'role-owner' }]);
      mockPrisma.organizationMember.findMany.mockResolvedValue([]);

      await service.onLowStockDetected({
        tenantId: TENANT,
        catalogItemId: 'item-1',
        itemName: 'Sel',
        stockQuantity: 0,
        minStockLevel: 5,
      });

      expect(mockPrisma.notification.createMany).not.toHaveBeenCalled();
    });

    it('includes itemName and quantities in the notification body', async () => {
      mockPrisma.role.findMany.mockResolvedValue([{ id: 'role-owner' }]);
      mockPrisma.organizationMember.findMany.mockResolvedValue([{ userId: USER }]);
      mockPrisma.notification.createMany.mockResolvedValue({ count: 1 });

      await service.onLowStockDetected({
        tenantId: TENANT,
        catalogItemId: 'item-1',
        itemName: 'Farine',
        stockQuantity: 2,
        minStockLevel: 5,
      });

      const [call] = mockPrisma.notification.createMany.mock.calls;
      const notif = call[0].data[0];
      expect(notif.body).toContain('Farine');
      expect(notif.body).toContain('2');
      expect(notif.body).toContain('5');
      expect(notif.targetId).toBe('item-1');
    });
  });

  describe('getUnreadCount()', () => {
    it('returns count from prisma', async () => {
      mockPrisma.notification.count.mockResolvedValue(7);
      const count = await service.getUnreadCount(USER, TENANT);
      expect(count).toBe(7);
      expect(mockPrisma.notification.count).toHaveBeenCalledWith({
        where: { userId: USER, tenantId: TENANT, isRead: false },
      });
    });
  });

  describe('markAsRead()', () => {
    it('updates notification isRead for the correct user', async () => {
      mockPrisma.notification.updateMany.mockResolvedValue({ count: 1 });
      await service.markAsRead('notif-1', USER);
      expect(mockPrisma.notification.updateMany).toHaveBeenCalledWith({
        where: { id: 'notif-1', userId: USER },
        data: { isRead: true },
      });
    });
  });
});
