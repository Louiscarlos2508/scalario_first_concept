import { Controller, Get, Post, Put, Body, Query, Param } from '@nestjs/common';
import { CustomerService } from './customer.service';

@Controller('pos/customers')
export class CustomerController {
    constructor(private readonly customerService: CustomerService) { }

    @Get()
    async getCustomers(@Query('tenantId') tenantId: string) {
        return this.customerService.getCustomers(tenantId);
    }

    @Post()
    async createCustomer(@Body('tenantId') tenantId: string, @Body('data') data: any) {
        return this.customerService.createCustomer(tenantId, data);
    }

    @Put(':id')
    async updateCustomer(@Param('id') id: string, @Body() data: any) {
        return this.customerService.updateCustomer(id, data);
    }

    @Get('search')
    async searchCustomers(@Query('tenantId') tenantId: string, @Query('q') query: string) {
        return this.customerService.searchCustomers(tenantId, query);
    }

    @Post(':id/settle')
    async settleDebt(@Param('id') id: string, @Body('amount') amount: number) {
        return this.customerService.settleDebt(id, amount);
    }
}
