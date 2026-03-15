import { Test, TestingModule } from '@nestjs/testing';
import { ContactsService } from './contacts.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

const mockPrisma = {
  contact: {
    create: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
  },
};

const mockAuditLog = {
  log: jest.fn(),
};

const mockEventBus = {
  publish: jest.fn(),
};

describe('ContactsService', () => {
  let service: ContactsService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ContactsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditLogService, useValue: mockAuditLog },
        { provide: EventBusService, useValue: mockEventBus },
      ],
    }).compile();

    service = module.get<ContactsService>(ContactsService);
  });

  // ── createContact ─────────────────────────────────────────────────────────

  describe('createContact', () => {
    it('creates a contact with default contactType=customer', async () => {
      const newContact = { id: 'c-1', name: 'Alice', contactType: 'customer', tenantId: 'tid' };
      mockPrisma.contact.create.mockResolvedValue(newContact);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.createContact({ name: 'Alice', tenantId: 'tid' }, 'user-1');

      expect(mockPrisma.contact.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ name: 'Alice', tenantId: 'tid', contactType: 'customer' }),
      });
      expect(result).toEqual(newContact);
    });

    it('records AuditLog with action=CREATE on contact creation', async () => {
      const newContact = { id: 'c-2', name: 'Bob', contactType: 'customer', tenantId: 'tid' };
      mockPrisma.contact.create.mockResolvedValue(newContact);
      mockAuditLog.log.mockResolvedValue(undefined);

      await service.createContact({ name: 'Bob', tenantId: 'tid' }, 'user-abc');

      expect(mockAuditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId: 'tid',
          userId: 'user-abc',
          action: 'CREATE',
          entity: 'Contact',
          entityId: 'c-2',
        }),
      );
    });
  });

  // ── getContacts ───────────────────────────────────────────────────────────

  describe('getContacts', () => {
    it('excludes soft-deleted when no since provided', async () => {
      mockPrisma.contact.findMany.mockResolvedValue([]);
      mockPrisma.contact.count.mockResolvedValue(0);

      await service.getContacts({ tenantId: 'tid' });

      expect(mockPrisma.contact.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ isDeleted: false, tenantId: 'tid' }),
        }),
      );
    });

    it('uses updatedAt filter and includes soft-deleted when since is provided', async () => {
      mockPrisma.contact.findMany.mockResolvedValue([]);
      mockPrisma.contact.count.mockResolvedValue(0);

      const since = '2026-03-01T00:00:00.000Z';
      await service.getContacts({ tenantId: 'tid', since });

      expect(mockPrisma.contact.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            updatedAt: { gt: new Date(since) },
            tenantId: 'tid',
          }),
        }),
      );
    });

    it('returns meta with serverTime and hasMore', async () => {
      const items = [{ id: 'c-1' }];
      mockPrisma.contact.findMany.mockResolvedValue(items);
      mockPrisma.contact.count.mockResolvedValue(1);

      const result = await service.getContacts({ tenantId: 'tid', page: 1, limit: 100 });

      expect(result.items).toEqual(items);
      expect(result.meta).toEqual(
        expect.objectContaining({ total: 1, page: 1, limit: 100, hasMore: false }),
      );
      expect(result.meta.serverTime).toBeDefined();
    });
  });

  // ── searchContacts ────────────────────────────────────────────────────────

  describe('searchContacts', () => {
    it('searches by name and phone case-insensitively', async () => {
      mockPrisma.contact.findMany.mockResolvedValue([]);

      await service.searchContacts('tid', 'alice');

      expect(mockPrisma.contact.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            tenantId: 'tid',
            isDeleted: false,
            OR: [
              { name: { contains: 'alice', mode: 'insensitive' } },
              { phone: { contains: 'alice', mode: 'insensitive' } },
            ],
          }),
        }),
      );
    });
  });

  // ── updateBalance ─────────────────────────────────────────────────────────

  describe('updateBalance', () => {
    it('increments balance and emits BalanceUpdated event', async () => {
      const updated = { id: 'c-1', balance: 1500, tenantId: 'tid' };
      mockPrisma.contact.update.mockResolvedValue(updated);

      const result = await service.updateBalance('c-1', 1000);

      expect(mockPrisma.contact.update).toHaveBeenCalledWith({
        where: { id: 'c-1' },
        data: { balance: { increment: 1000 } },
      });
      expect(mockEventBus.publish).toHaveBeenCalledWith(
        'contact.balance_updated',
        expect.objectContaining({ contactId: 'c-1', delta: 1000, newBalance: 1500 }),
      );
      expect(result).toEqual(updated);
    });
  });

  // ── settleDebt ────────────────────────────────────────────────────────────

  describe('settleDebt', () => {
    it('decrements balance and records AuditLog with before/after', async () => {
      const before = { id: 'c-1', balance: 1000, tenantId: 'tid' };
      const after = { id: 'c-1', balance: 500, tenantId: 'tid' };
      mockPrisma.contact.findUnique.mockResolvedValue(before);
      mockPrisma.contact.update.mockResolvedValue(after);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.settleDebt('c-1', 500, 'user-x', 'tid');

      expect(mockPrisma.contact.update).toHaveBeenCalledWith({
        where: { id: 'c-1' },
        data: { balance: { decrement: 500 } },
      });
      expect(mockAuditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId: 'tid',
          userId: 'user-x',
          action: 'UPDATE',
          entity: 'Contact',
          entityId: 'c-1',
          before: { balance: before.balance },
          after: { balance: after.balance },
        }),
      );
      expect(result).toEqual(after);
    });

    it('skips AuditLog when tenantId is null', async () => {
      mockPrisma.contact.findUnique.mockResolvedValue({ id: 'c-1', balance: 500 });
      mockPrisma.contact.update.mockResolvedValue({ id: 'c-1', balance: 0 });

      await service.settleDebt('c-1', 500, null, null);

      expect(mockAuditLog.log).not.toHaveBeenCalled();
    });
  });
});
