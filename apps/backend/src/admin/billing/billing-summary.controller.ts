import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { BillingEventsService } from './billing-events.service';

@Controller('admin/billing')
@UseGuards(SuperAdminGuard)
export class BillingSummaryController {
  constructor(private readonly billingEventsService: BillingEventsService) {}

  @Get('summary')
  getSummary() {
    return this.billingEventsService.getBillingSummary();
  }

  @Get('events')
  listEvents(
    @Query('tenantId') tenantId?: string,
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.billingEventsService.listAllEvents({ tenantId, type, status, from, to });
  }

  @Patch('events/:id')
  updateEventStatus(@Param('id') id: string, @Body() body: { status: string }) {
    return this.billingEventsService.updateEventStatus(id, body.status);
  }

  @Post('generate-invoice/:tenantId')
  generateInvoice(@Param('tenantId') tenantId: string) {
    return this.billingEventsService.generateInvoiceData(tenantId);
  }

  @Post('generate-receipt/:eventId')
  generateReceipt(
    @Param('eventId') eventId: string,
    @Body() body: { paymentMethod: string; paymentRef?: string; paymentDate?: string },
  ) {
    return this.billingEventsService.generateReceiptData(eventId, body);
  }
}
