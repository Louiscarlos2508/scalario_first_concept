import { Body, Controller, Get, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { PurchaseOrdersService } from './purchase-orders.service';
import { CreatePurchaseOrderDto } from './dto/create-purchase-order.dto';
import { ReceivePurchaseOrderDto } from './dto/receive-purchase-order.dto';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('purchase-orders')
export class PurchaseOrdersController {
  constructor(private readonly service: PurchaseOrdersService) {}

  // POST /purchase-orders
  @Post()
  @Roles('owner', 'manager')
  async create(@Body() dto: CreatePurchaseOrderDto, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.service.createPurchaseOrder(dto, userId);
  }

  // GET /purchase-orders/stats
  @Get('stats')
  @Roles('owner', 'manager')
  async getStats(@Query('tenantId') tenantId: string) {
    return this.service.getStats(tenantId);
  }

  // GET /purchase-orders
  @Get()
  @Roles('owner', 'manager')
  async list(
    @Query('tenantId') tenantId?: string,
    @Query('status') status?: string,
    @Query('supplierId') supplierId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
  ) {
    return this.service.listPurchaseOrders({
      tenantId,
      status,
      supplierId,
      from,
      to,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }

  // GET /purchase-orders/:id
  @Get(':id')
  @Roles('owner', 'manager')
  async getOne(@Param('id') id: string, @Query('tenantId') tenantId?: string) {
    return this.service.getPurchaseOrder(id, tenantId);
  }

  // PATCH /purchase-orders/:id
  @Patch(':id')
  @Roles('owner', 'manager')
  async updateStatus(
    @Param('id') id: string,
    @Body() body: { status: string },
    @Query('tenantId') tenantId?: string,
    @Req() req?: any,
  ) {
    const userId = req?.user?.sub ?? null;
    return this.service.updateStatus(id, body.status, tenantId, userId);
  }

  // PATCH /purchase-orders/:id/details — edit draft header (notes, expectedDate)
  @Patch(':id/details')
  @Roles('owner', 'manager')
  async updateDetails(
    @Param('id') id: string,
    @Body() body: { notes?: string | null; expectedDate?: string | null },
    @Query('tenantId') tenantId?: string,
  ) {
    return this.service.updateDraft(id, body, tenantId);
  }

  // POST /purchase-orders/:id/receive
  @Post(':id/receive')
  @Roles('owner', 'manager')
  async receive(
    @Param('id') id: string,
    @Body() dto: ReceivePurchaseOrderDto,
    @Query('tenantId') tenantId?: string,
    @Req() req?: any,
  ) {
    const userId = req?.user?.sub ?? null;
    return this.service.receivePurchaseOrder(id, dto, tenantId, userId);
  }
}
