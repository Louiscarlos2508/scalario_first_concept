import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { VariantsService } from './variants.service';
import { RequiresModule } from '../../../kernel/modules/module.decorator';
import { Roles } from '../../../kernel/rbac/roles.decorator';

@Controller('catalog')
@RequiresModule('catalog')
export class VariantsController {
  constructor(private readonly variantsService: VariantsService) {}

  @Post('items/:id/variants')
  @Roles('owner', 'manager')
  async createVariant(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
    @Body() body: any,
  ) {
    return this.variantsService.createVariant(catalogItemId, tenantId, body);
  }

  @Get('items/:id/variants')
  async getVariants(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.variantsService.getVariants(catalogItemId, tenantId);
  }

  @Patch('items/:id/variants/:variantId')
  @Roles('owner', 'manager')
  async updateVariant(
    @Param('id') catalogItemId: string,
    @Param('variantId') variantId: string,
    @Query('tenantId') tenantId: string,
    @Body() body: any,
  ) {
    return this.variantsService.updateVariant(catalogItemId, variantId, tenantId, body);
  }

  @Delete('items/:id/variants/:variantId')
  @Roles('owner', 'manager')
  async deleteVariant(
    @Param('id') catalogItemId: string,
    @Param('variantId') variantId: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.variantsService.deleteVariant(catalogItemId, variantId, tenantId);
  }
}
