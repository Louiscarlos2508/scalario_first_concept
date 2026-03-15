import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Req,
} from '@nestjs/common';
import { ContactsService } from './contacts.service';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('contacts')
@RequiresModule('contacts')
export class ContactsController {
  constructor(private readonly contactsService: ContactsService) {}

  @Post()
  @Roles('owner', 'commercial')
  async createContact(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.contactsService.createContact(body, userId);
  }

  @Get()
  async getContacts(
    @Query('tenantId') tenantId?: string,
    @Query('since') since?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '100',
  ) {
    return this.contactsService.getContacts({
      tenantId,
      since,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }

  @Get('search')
  async searchContacts(
    @Query('tenantId') tenantId: string,
    @Query('q') query: string,
  ) {
    return this.contactsService.searchContacts(tenantId, query);
  }

  @Post(':id/settle')
  @Roles('owner', 'commercial')
  async settleDebt(
    @Param('id') id: string,
    @Body() body: { amount: number; tenantId?: string },
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? null;
    return this.contactsService.settleDebt(id, body.amount, userId, body.tenantId ?? null);
  }
}
