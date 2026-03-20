import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Query,
  Param,
  Req,
  HttpCode,
} from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { PriceHistoryService } from './price-history/price-history.service';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('catalog')
@RequiresModule('catalog')
export class CatalogController {
  constructor(
    private readonly catalogService: CatalogService,
    private readonly priceHistoryService: PriceHistoryService,
  ) {}

  @Get('categories')
  async getCategories(@Query('tenantId') tenantId: string) {
    return this.catalogService.getCategories(tenantId);
  }

  @Post('categories')
  @Roles('owner')
  async createCategory(@Body() body: any) {
    return this.catalogService.createCategory({
      name: body.name,
      tenantId: body.tenantId,
    });
  }

  @Delete('categories/:id')
  @Roles('owner')
  async deleteCategory(@Param('id') id: string) {
    return this.catalogService.deleteCategory(id);
  }

  @Get('barcode/:barcode')
  async getByBarcode(
    @Param('barcode') barcode: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.catalogService.getByBarcode(barcode, tenantId);
  }

  @Get('items')
  async getItems(
    @Query('tenantId') tenantId?: string,
    @Query('q') query?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '100',
    @Query('since') since?: string,
  ) {
    return this.catalogService.getItems({
      tenantId,
      query,
      page: parseInt(page),
      limit: parseInt(limit),
      since,
    });
  }

  @Post('items/sync')
  @Roles('owner')
  async syncItems(@Body() body: { items: Array<{ id: string; [key: string]: any }> }) {
    return this.catalogService.syncItems(body.items);
  }

  @Post('items')
  @Roles('owner')
  async createItem(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.catalogService.createItem(body, userId);
  }

  @Patch('items/:id')
  @Roles('owner', 'manager')
  async updateItem(
    @Param('id') id: string,
    @Body() body: any,
    @Query('tenantId') tenantId: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? null;
    return this.catalogService.updateItem(id, body, userId, tenantId);
  }

  // AC3 (Story 26-5) — Price history for a catalog item
  @Get('items/:id/price-history')
  async getPriceHistory(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.priceHistoryService.getPriceHistory(tenantId, id);
  }

  @Get('items/:id/children')
  async getChildren(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.catalogService.getChildren(id, tenantId);
  }

  // AC4 (Story 26-6) — Duplicate a catalog item
  @Post('items/:id/duplicate')
  @Roles('owner')
  @HttpCode(201)
  async duplicateItem(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? null;
    return this.catalogService.duplicateCatalogItem(id, tenantId, userId);
  }

  @Delete('items/:id')
  @Roles('owner')
  async deleteItem(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? null;
    return this.catalogService.deleteItem(id, userId, tenantId);
  }
}
