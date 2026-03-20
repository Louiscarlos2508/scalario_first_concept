import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { BillingEventsService } from './billing-events.service';
import { CreateBillingEventDto } from './dto/create-billing-event.dto';
import { UpdateBillingDto } from './dto/update-billing.dto';

@Controller('admin/tenants')
@UseGuards(SuperAdminGuard)
export class BillingEventsController {
  constructor(private readonly billingEventsService: BillingEventsService) {}

  @Get(':id/billing')
  getHistory(@Param('id') id: string) {
    return this.billingEventsService.getHistory(id);
  }

  @Post(':id/billing/events')
  recordEvent(@Param('id') id: string, @Body() dto: CreateBillingEventDto) {
    return this.billingEventsService.recordEvent(id, dto);
  }

  @Patch(':id/billing')
  updateBilling(@Param('id') id: string, @Body() dto: UpdateBillingDto) {
    return this.billingEventsService.updateBilling(id, dto);
  }
}
