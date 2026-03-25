import { Body, Controller, Get, Param, Post, Query, Req } from '@nestjs/common';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';
import { InternalRequestsService } from './internal-requests.service';

@Controller('internal-requests')
@RequiresModule('inventory')
export class InternalRequestsController {
  constructor(private readonly service: InternalRequestsService) {}

  // POST /internal-requests — Commercial / Manager / Owner crée une demande
  @Post()
  @Roles('commercial', 'manager', 'owner')
  async create(@Body() body: any, @Req() req: any) {
    const tenantId = req.tenantId as string;
    const requestedBy = req.user?.sub as string;
    return this.service.create({
      catalogItemId: body.catalogItemId,
      quantity: body.quantity,
      urgency: body.urgency ?? 'normal',
      tenantId,
      requestedBy,
    });
  }

  // GET /internal-requests — Liste (filtre par status, urgency)
  @Get()
  @Roles('commercial', 'manager', 'owner')
  async list(@Query() query: any, @Req() req: any) {
    const tenantId = req.tenantId as string;
    return this.service.list({
      tenantId,
      status: query.status,
      urgency: query.urgency,
    });
  }

  // GET /internal-requests/:id
  @Get(':id')
  @Roles('commercial', 'manager', 'owner')
  async getOne(@Param('id') id: string, @Req() req: any) {
    const tenantId = req.tenantId as string;
    return this.service.getOne(id, tenantId);
  }

  // POST /internal-requests/:id/prepare — Manager prépare
  @Post(':id/prepare')
  @Roles('manager', 'owner')
  async prepare(@Param('id') id: string, @Req() req: any) {
    const tenantId = req.tenantId as string;
    const preparedBy = req.user?.sub as string;
    return this.service.prepare(id, tenantId, preparedBy);
  }

  // POST /internal-requests/:id/approve — Owner approuve (peut modifier la quantité)
  @Post(':id/approve')
  @Roles('owner')
  async approve(
    @Param('id') id: string,
    @Body() body: { quantity?: number },
    @Req() req: any,
  ) {
    const tenantId = req.tenantId as string;
    const approvedBy = req.user?.sub as string;
    return this.service.approve(id, tenantId, approvedBy, body.quantity);
  }

  // POST /internal-requests/:id/reject — Manager ou Owner rejette
  @Post(':id/reject')
  @Roles('manager', 'owner')
  async reject(
    @Param('id') id: string,
    @Body() body: { reason: string },
    @Req() req: any,
  ) {
    const tenantId = req.tenantId as string;
    return this.service.reject(id, tenantId, body.reason);
  }
}
