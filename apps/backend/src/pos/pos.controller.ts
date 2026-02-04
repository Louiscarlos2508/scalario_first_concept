import { Controller, Get, Post, Body } from '@nestjs/common';

@Controller('pos')
export class PosController {

    @Get('products')
    getProducts() {
        // Mock products for sync test
        return [
            {
                remoteId: 'uuid-1',
                name: 'Coca Cola (Synced)',
                price: 500,
                category: 'Drinks',
                stockQuantity: 100,
            },
            {
                remoteId: 'uuid-2',
                name: 'Sandwich (Synced)',
                price: 1500,
                category: 'Food',
                stockQuantity: 50,
            },
        ];
    }

    @Post('orders')
    syncOrder(@Body() orderData: any) {
        console.log('Received Order Sync:', orderData);
        return { status: 'synced', id: orderData.uuid };
    }
}
