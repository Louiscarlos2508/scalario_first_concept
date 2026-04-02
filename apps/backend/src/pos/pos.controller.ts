import { Controller, Get, Post, Body, UseGuards, Query, Param, Delete, Res, UseInterceptors } from '@nestjs/common';
import type { Response } from 'express';
import { PosService } from './pos.service';
import { RequiresModule } from '../kernel/modules/module.decorator';
import { SyncHeadersInterceptor } from '../kernel/interceptors/sync-headers.interceptor';
import { POS_SCHEMA_VERSION } from './sync.constants';

@Controller('pos')
@RequiresModule('retail')
export class PosController {
    constructor(
        private readonly posService: PosService,
    ) { }

    /**
     * GET /pos/products
     * Ajoute X-Sync-Timestamp via SyncHeadersInterceptor (Fix 2 Flutter).
     */
    @Get('products')
    @UseInterceptors(SyncHeadersInterceptor)
    async getProducts(
        @Query('q') query?: string,
        @Query('page') page: string = '1',
        @Query('limit') limit: string = '50',
        @Query('tenantId') tenantId?: string,
        @Query('since') since?: string
    ) {
        return this.posService.getProducts({
            query,
            page: parseInt(page),
            limit: parseInt(limit),
            tenantId,
            since
        });
    }

    @Delete('products/:id')
    async deleteProduct(@Param('id') id: string) {
        return this.posService.deleteProduct(id);
    }

    @Post('products/sync')
    async syncProduct(@Body() productData: any) {
        return this.posService.syncProduct(productData);
    }

    @Post('products/adjust-stock')
    async adjustStock(@Body() adjustment: any) {
        return this.posService.adjustStock(
            adjustment.productId,
            adjustment.quantity,
            adjustment.type,
            adjustment.reason
        );
    }

    /**
     * POST /pos/heartbeat
     * Retourne X-Schema-Version dans le header de réponse (Fix 5 Flutter).
     * Le client compare ce numéro avec sa version locale : si divergence,
     * il force un re-provisioning complet au lieu de parser des données
     * potentiellement incompatibles.
     */
    @Post('heartbeat')
    async heartbeat(
        @Body() data: any,
        @Res({ passthrough: true }) res: Response,
    ) {
        res.setHeader('X-Schema-Version', POS_SCHEMA_VERSION.toString());
        return this.posService.heartbeat(data);
    }

    @Get('stock-across-branches')
    async getStockAcrossBranches(@Query('barcode') barcode: string, @Query('userId') userId: string) {
        return this.posService.getStockAcrossBranches(barcode, userId);
    }

    @Get('terminals')
    async getTerminals(@Query('tenantId') tenantId?: string) {
        return this.posService.getTerminals(tenantId);
    }

    /**
     * GET /pos/categories
     * Ajoute X-Sync-Timestamp via SyncHeadersInterceptor (Fix 2 Flutter).
     */
    @Get('categories')
    @UseInterceptors(SyncHeadersInterceptor)
    async getCategories(@Query('tenantId') tenantId: string, @Query('since') since?: string) {
        return this.posService.getCategories(tenantId, since);
    }

    @Post('categories')
    async createCategory(@Body() data: any) {
        return this.posService.createCategory(data);
    }

    @Delete('categories/:id')
    async deleteCategory(@Param('id') id: string) {
        return this.posService.deleteCategory(id);
    }

    // --- Customer Management ---

    @Get('customers')
    async getCustomers(@Query('tenantId') tenantId: string, @Query('since') since?: string) {
        return this.posService.getCustomers(tenantId, undefined, since);
    }

    @Get('customers/search')
    async searchCustomers(@Query('tenantId') tenantId: string, @Query('q') query: string) {
        return this.posService.getCustomers(tenantId, query);
    }

    @Post('customers')
    async createCustomer(@Body() data: any) {
        return this.posService.createCustomer(data);
    }

    @Post('customers/:id/settle')
    async settleDebt(@Param('id') id: string, @Body('amount') amount: number) {
        return this.posService.settleDebt(id, amount);
    }
}
