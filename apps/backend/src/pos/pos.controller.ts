import { Controller, Get, Post, Body, UseGuards, Query, Param, Delete } from '@nestjs/common';
import { PosService } from './pos.service';
// import { AuthGuard } from '../core/guards/auth/auth.guard';

@Controller('pos')
export class PosController {
    constructor(private readonly posService: PosService) { }

    @Get('products')
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

    @Post('orders')
    async syncOrder(@Body() orderData: any) {
        return this.posService.syncOrder(orderData);
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

    @Get('stats')
    async getStats(
        @Query('start') start?: string,
        @Query('end') end?: string,
        @Query('tenantId') tenantId?: string
    ) {
        return this.posService.getSalesStats(start, end, tenantId);
    }

    @Get('stock-movements')
    async getStockMovements(
        @Query('start') start?: string,
        @Query('end') end?: string,
        @Query('tenantId') tenantId?: string
    ) {
        return this.posService.getStockMovements(start, end, tenantId);
    }

    @Get('reports/sales')
    async getSalesReport(
        @Query('start') start?: string,
        @Query('end') end?: string,
        @Query('tenantId') tenantId?: string
    ) {
        return this.posService.getSalesReport(start, end, tenantId);
    }

    @Post('heartbeat')
    async heartbeat(@Body() data: any) {
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

    @Get('categories')
    async getCategories(@Query('tenantId') tenantId: string) {
        return this.posService.getCategories(tenantId);
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
    async getCustomers(@Query('tenantId') tenantId: string) {
        return this.posService.getCustomers(tenantId);
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
