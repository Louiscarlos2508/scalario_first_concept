import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

@Injectable()
export class ContactsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly eventBus: EventBusService,
  ) {}

  async createContact(
    data: {
      name: string;
      phone?: string;
      email?: string;
      address?: string;
      tenantId: string;
      contactType?: string;
    },
    userId: string | null,
  ) {
    const newContact = await this.prisma.contact.create({
      data: {
        name: data.name,
        phone: data.phone,
        email: data.email,
        address: data.address,
        tenantId: data.tenantId,
        contactType: data.contactType ?? 'customer',
      },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId,
      action: 'CREATE',
      entity: 'Contact',
      entityId: newContact.id,
      before: null,
      after: { name: newContact.name, contactType: newContact.contactType, tenantId: newContact.tenantId },
    });

    return newContact;
  }

  async getContacts(params: {
    tenantId?: string;
    since?: string;
    page?: number;
    limit?: number;
  }) {
    const { tenantId, since, page = 1, limit = 100 } = params;
    const skip = (page - 1) * limit;

    const where: any = since
      ? { updatedAt: { gt: new Date(since) } }
      : { isDeleted: false };

    if (tenantId) where.tenantId = tenantId;

    const serverTime = new Date().toISOString();

    const [items, total] = await Promise.all([
      this.prisma.contact.findMany({
        where,
        orderBy: { updatedAt: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.contact.count({ where }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        hasMore: skip + items.length < total,
        serverTime,
      },
    };
  }

  async searchContacts(tenantId: string, query: string) {
    return this.prisma.contact.findMany({
      where: {
        tenantId,
        isDeleted: false,
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { phone: { contains: query, mode: 'insensitive' } },
        ],
      },
      take: 20,
    });
  }

  async getContactById(id: string) {
    return this.prisma.contact.findUnique({ where: { id } });
  }

  async updateBalance(contactId: string, amount: number) {
    const contact = await this.prisma.contact.update({
      where: { id: contactId },
      data: { balance: { increment: amount } },
    });

    this.eventBus.publish('contact.balance_updated', {
      contactId,
      newBalance: contact.balance,
      delta: amount,
      tenantId: contact.tenantId,
    });

    return contact;
  }

  async settleDebt(
    contactId: string,
    amount: number,
    userId: string | null,
    tenantId: string | null,
  ) {
    const before = await this.prisma.contact.findUnique({ where: { id: contactId } });
    const after = await this.prisma.contact.update({
      where: { id: contactId },
      data: { balance: { decrement: amount } },
    });

    if (tenantId) {
      await this.auditLog.log({
        tenantId,
        userId,
        action: 'UPDATE',
        entity: 'Contact',
        entityId: contactId,
        before: { balance: before?.balance },
        after: { balance: after.balance },
      });
    }

    return after;
  }
}
