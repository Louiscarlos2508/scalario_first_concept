import { Body, Controller, Get, Param, Patch, Post, Query, Req, HttpCode } from '@nestjs/common';
import { ClientOrdersService } from './client-orders.service';
import { CreateClientOrderDto } from './dto/create-client-order.dto';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('client-orders')
export class ClientOrdersController {
  constructor(private readonly service: ClientOrdersService) {}

  // GET /client-orders/kpis — MUST be before /:id to avoid route conflict
  @Get('kpis')
  @Roles('owner', 'manager')
  async getKpis(@Query('tenantId') tenantId: string) {
    return this.service.getKpis(tenantId);
  }

  // POST /client-orders
  @Post()
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async create(@Body() dto: CreateClientOrderDto, @Req() req: any) {
    const userId = req.user?.sub ?? dto.tenantId; // fallback for test contexts
    return this.service.createOrder(dto.tenantId, userId, dto);
  }

  // GET /client-orders
  @Get()
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async list(
    @Query('tenantId') tenantId: string,
    @Query('status') status?: string,
    @Query('customerId') customerId?: string,
    @Query('customerName') customerName?: string,
    @Query('createdBy') createdBy?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
    @Req() req?: any,
  ) {
    const userId = req?.user?.sub;
    const role = req?.user?.role;
    // Cashier and commercial can only see their own orders
    const restrictedRoles = ['commercial', 'cashier'];
    const effectiveCreatedBy = restrictedRoles.includes(role) ? userId : createdBy;
    return this.service.listOrders({
      tenantId,
      status,
      customerId,
      customerName,
      createdBy: effectiveCreatedBy,
      dateFrom,
      dateTo,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }

  // GET /client-orders/:id
  @Get(':id')
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async getOne(@Param('id') id: string, @Query('tenantId') tenantId: string) {
    return this.service.getOrder(id, tenantId);
  }

  // PATCH /client-orders/:id/details — edit draft header
  @Patch(':id/details')
  @Roles('owner', 'manager')
  async updateDetails(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Body()
    body: { notes?: string | null; depositAmount?: number; desiredDeliveryDate?: string | null },
  ) {
    return this.service.updateDraft(id, tenantId, body);
  }

  // POST /client-orders/:id/confirm
  @Post(':id/confirm')
  @Roles('owner', 'manager')
  async confirm(@Param('id') id: string, @Query('tenantId') tenantId: string, @Req() req: any) {
    const userId = req.user?.sub ?? tenantId;
    return this.service.confirmOrder(id, tenantId, userId);
  }

  // POST /client-orders/:id/cancel
  @Post(':id/cancel')
  @Roles('owner', 'manager')
  async cancel(@Param('id') id: string, @Query('tenantId') tenantId: string, @Req() req: any) {
    const userId = req.user?.sub ?? tenantId;
    return this.service.cancelOrder(id, tenantId, userId);
  }

  // POST /client-orders/:id/prepare
  @Post(':id/prepare')
  @HttpCode(200)
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async prepare(@Param('id') id: string, @Query('tenantId') tenantId: string) {
    return this.service.prepareOrder(id, tenantId);
  }

  // POST /client-orders/:id/mark-ready
  @Post(':id/mark-ready')
  @HttpCode(200)
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async markReady(@Param('id') id: string, @Query('tenantId') tenantId: string) {
    return this.service.markReady(id, tenantId);
  }

  // POST /client-orders/:id/deliver
  @Post(':id/deliver')
  @HttpCode(200)
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async deliver(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Body() body: { lines: Array<{ lineId: string; deliveredQty: number }> },
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? tenantId;
    return this.service.deliverOrder(id, tenantId, userId, body.lines ?? []);
  }

  // POST /client-orders/:id/invoice
  @Post(':id/invoice')
  @HttpCode(200)
  @Roles('owner', 'manager')
  async invoice(@Param('id') id: string, @Query('tenantId') tenantId: string) {
    return this.service.invoiceOrder(id, tenantId);
  }

  // POST /client-orders/:id/pay
  @Post(':id/pay')
  @HttpCode(200)
  @Roles('owner', 'manager')
  async pay(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Body() body: { paymentMethod?: string },
  ) {
    return this.service.payOrder(id, tenantId, body.paymentMethod);
  }
}
