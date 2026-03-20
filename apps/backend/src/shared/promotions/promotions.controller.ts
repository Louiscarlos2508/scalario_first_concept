import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('promotions')
export class PromotionsController {
  constructor(private readonly promotionsService: PromotionsService) {}

  @Post()
  @Roles('owner', 'manager')
  async createPromotion(@Body() body: any, @Query('tenantId') tenantId: string) {
    return this.promotionsService.createPromotion(tenantId, body);
  }

  @Get()
  async listPromotions(
    @Query('tenantId') tenantId: string,
    @Query('status') status?: string,
    @Query('type') type?: string,
  ) {
    return this.promotionsService.listPromotions(tenantId, { status, type });
  }

  @Get('active')
  async getActiveForItem(
    @Query('tenantId') tenantId: string,
    @Query('catalogItemId') catalogItemId: string,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.promotionsService.getActivePromotionsForItem(tenantId, catalogItemId, categoryId);
  }

  @Patch(':id')
  @Roles('owner', 'manager')
  async updatePromotion(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Body() body: any,
  ) {
    return this.promotionsService.updatePromotion(id, tenantId, body);
  }

  @Delete(':id')
  @Roles('owner', 'manager')
  async deletePromotion(@Param('id') id: string, @Query('tenantId') tenantId: string) {
    return this.promotionsService.deletePromotion(id, tenantId);
  }
}
