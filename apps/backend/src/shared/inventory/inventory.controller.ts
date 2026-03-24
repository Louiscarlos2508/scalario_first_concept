import { Controller, Delete, Get, Param, Post, Body, Query, Req } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('inventory')
@RequiresModule('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  // POST /inventory/movements — Owner + Manager only (DELIVERY, TRANSFER_OUT, LOSS, ADJUSTMENT)
  @Post('movements')
  @Roles('owner', 'manager')
  async createMovement(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    if (body.type === 'TRANSFER_OUT') {
      return this.inventoryService.createTransferOut({ ...body, userId });
    }
    return this.inventoryService.createMovement({ ...body, userId });
  }

  // POST /inventory/movements/confirm — Owner + Manager + Commercial (TRANSFER_IN confirmation)
  @Post('movements/confirm')
  @Roles('owner', 'manager', 'commercial')
  async confirmTransferIn(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.inventoryService.confirmTransferIn({ ...body, userId });
  }

  // POST /inventory/adjust — Owner + Manager (partial inventory count)
  @Post('adjust')
  @Roles('owner', 'manager')
  async adjustInventory(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.inventoryService.adjustInventory({ ...body, userId });
  }

  // GET /inventory/stock — all authenticated
  @Get('stock')
  async getStock(
    @Query('catalogItemId') catalogItemId: string,
    @Query('tenantId') tenantId: string,
  ) {
    const currentStock = await this.inventoryService.getCurrentStock(catalogItemId, tenantId);
    return {
      catalogItemId,
      tenantId,
      currentStock,
      computedAt: new Date().toISOString(),
    };
  }

  // DELETE /inventory/transfers/:referenceId — Owner + Manager only (cancel a pending TRANSFER_OUT)
  @Delete('transfers/:referenceId')
  @Roles('owner', 'manager')
  async cancelTransfer(
    @Param('referenceId') referenceId: string,
    @Query('tenantId') tenantId: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? null;
    await this.inventoryService.cancelTransfer(referenceId, tenantId, userId);
    return { success: true };
  }

  @Get('movements')
  async getMovements(
    @Query('tenantId') tenantId?: string,
    @Query('since') since?: string,
    @Query('referenceId') referenceId?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '100',
  ) {
    return this.inventoryService.getMovements({
      tenantId,
      since,
      referenceId,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }
}
