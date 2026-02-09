import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { PosService } from './pos.service';
// import { AuthGuard } from '../core/guards/auth/auth.guard';

@Controller('pos')
export class PosController {
    constructor(private readonly posService: PosService) { }

    @Get('products')
    async getProducts() {
        return this.posService.getProducts();
    }

    @Post('orders')
    // @UseGuards(AuthGuard) // Disabled for initial integration testing
    async syncOrder(@Body() orderData: any) {
        console.log('Received Order Sync:', orderData);
        return this.posService.syncOrder(orderData);
    }
}
