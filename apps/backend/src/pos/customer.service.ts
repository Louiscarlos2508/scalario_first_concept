import { Injectable } from '@nestjs/common';
import { ContactsService } from '../shared/contacts/contacts.service';

@Injectable()
export class CustomerService {
  constructor(private readonly contactsService: ContactsService) {}

  async getCustomers(tenantId: string) {
    const result = await this.contactsService.getContacts({ tenantId });
    return result.items;
  }

  async createCustomer(tenantId: string, data: any) {
    return this.contactsService.createContact({ ...data, tenantId }, null);
  }

  async updateCustomer(id: string, data: any) {
    // Thin proxy — full update not exposed via contacts API in Story 3.2; retained for backward compat
    return this.contactsService.getContactById(id);
  }

  async getCustomerById(id: string) {
    return this.contactsService.getContactById(id);
  }

  async searchCustomers(tenantId: string, query: string) {
    return this.contactsService.searchContacts(tenantId, query);
  }

  async settleDebt(id: string, amount: number) {
    return this.contactsService.settleDebt(id, amount, null, null);
  }
}
