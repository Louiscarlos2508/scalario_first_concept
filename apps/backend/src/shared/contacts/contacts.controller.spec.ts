import { Test, TestingModule } from '@nestjs/testing';
import { ContactsController } from './contacts.controller';
import { ContactsService } from './contacts.service';

const mockContactsService = {
  createContact: jest.fn(),
  getContacts: jest.fn(),
  searchContacts: jest.fn(),
  settleDebt: jest.fn(),
  getContactById: jest.fn(),
};

describe('ContactsController', () => {
  let controller: ContactsController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ContactsController],
      providers: [{ provide: ContactsService, useValue: mockContactsService }],
    }).compile();

    controller = module.get<ContactsController>(ContactsController);
  });

  describe('createContact', () => {
    it('extracts userId from req.user.sub and calls contactsService.createContact', async () => {
      const body = { name: 'Alice', tenantId: 'tid' };
      const req = { user: { sub: 'user-1' } };
      const created = { id: 'c-1', ...body };
      mockContactsService.createContact.mockResolvedValue(created);

      const result = await controller.createContact(body, req);

      expect(mockContactsService.createContact).toHaveBeenCalledWith(body, 'user-1');
      expect(result).toEqual(created);
    });

    it('passes null userId when req.user is absent', async () => {
      const body = { name: 'Bob', tenantId: 'tid' };
      mockContactsService.createContact.mockResolvedValue({ id: 'c-2', ...body });

      await controller.createContact(body, {});

      expect(mockContactsService.createContact).toHaveBeenCalledWith(body, null);
    });
  });

  describe('getContacts', () => {
    it('calls contactsService.getContacts with parsed params including since', async () => {
      const response = { items: [], meta: { total: 0, page: 1, limit: 100, hasMore: false, serverTime: '' } };
      mockContactsService.getContacts.mockResolvedValue(response);

      const result = await controller.getContacts('tid', '2026-03-01T00:00:00Z', '1', '100');

      expect(mockContactsService.getContacts).toHaveBeenCalledWith({
        tenantId: 'tid',
        since: '2026-03-01T00:00:00Z',
        page: 1,
        limit: 100,
      });
      expect(result).toEqual(response);
    });
  });

  describe('searchContacts', () => {
    it('calls contactsService.searchContacts with tenantId and query', async () => {
      mockContactsService.searchContacts.mockResolvedValue([{ id: 'c-1', name: 'Alice' }]);

      const result = await controller.searchContacts('tid', 'alice');

      expect(mockContactsService.searchContacts).toHaveBeenCalledWith('tid', 'alice');
      expect(result).toEqual([{ id: 'c-1', name: 'Alice' }]);
    });
  });

  describe('settleDebt', () => {
    it('calls contactsService.settleDebt with id, amount, userId, tenantId', async () => {
      const req = { user: { sub: 'user-x' } };
      const body = { amount: 500, tenantId: 'tid' };
      mockContactsService.settleDebt.mockResolvedValue({ id: 'c-1', balance: 500 });

      const result = await controller.settleDebt('c-1', body, req);

      expect(mockContactsService.settleDebt).toHaveBeenCalledWith('c-1', 500, 'user-x', 'tid');
      expect(result).toEqual({ id: 'c-1', balance: 500 });
    });
  });
});
