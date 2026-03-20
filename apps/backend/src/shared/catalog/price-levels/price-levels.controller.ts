import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { PriceLevelsService } from './price-levels.service';
import { RequiresModule } from '../../../kernel/modules/module.decorator';
import { Roles } from '../../../kernel/rbac/roles.decorator';

@Controller('catalog')
@RequiresModule('catalog')
export class PriceLevelsController {
  constructor(private readonly priceLevelsService: PriceLevelsService) {}

  @Post('items/:id/price-levels')
  @Roles('owner', 'manager')
  async createPriceLevel(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
    @Body() body: any,
  ) {
    return this.priceLevelsService.createPriceLevel(catalogItemId, tenantId, body);
  }

  @Get('items/:id/price-levels')
  async getPriceLevels(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.priceLevelsService.getPriceLevels(catalogItemId, tenantId);
  }

  @Patch('items/:id/price-levels/:priceLevelId')
  @Roles('owner', 'manager')
  async updatePriceLevel(
    @Param('id') catalogItemId: string,
    @Param('priceLevelId') priceLevelId: string,
    @Query('tenantId') tenantId: string,
    @Body() body: any,
  ) {
    return this.priceLevelsService.updatePriceLevel(catalogItemId, priceLevelId, tenantId, body);
  }

  @Delete('items/:id/price-levels/:priceLevelId')
  @Roles('owner', 'manager')
  async deletePriceLevel(
    @Param('id') catalogItemId: string,
    @Param('priceLevelId') priceLevelId: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.priceLevelsService.deletePriceLevel(catalogItemId, priceLevelId, tenantId);
  }
}
