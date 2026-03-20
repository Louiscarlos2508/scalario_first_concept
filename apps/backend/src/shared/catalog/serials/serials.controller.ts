import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { SerialsService } from './serials.service';
import { Roles } from '../../../kernel/rbac/roles.decorator';

@Controller()
export class SerialsController {
  constructor(private readonly serialsService: SerialsService) {}

  /** POST /catalog/:id/serials — create a serial record */
  @Post('catalog/:id/serials')
  @Roles('owner', 'manager')
  async createSerial(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
    @Body() body: { serial: string; soldAt?: string; warrantyUntil?: string },
  ) {
    return this.serialsService.createSerial(tenantId, catalogItemId, body);
  }

  /** GET /catalog/:id/serials — paginated list for an item */
  @Get('catalog/:id/serials')
  async listSerials(
    @Param('id') catalogItemId: string,
    @Query('tenantId') tenantId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.serialsService.listSerials(
      tenantId,
      catalogItemId,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  /** GET /serials?q=... — cross-item search */
  @Get('serials')
  async searchSerials(
    @Query('tenantId') tenantId: string,
    @Query('q') query: string,
  ) {
    return this.serialsService.searchSerials(tenantId, query ?? '');
  }
}
