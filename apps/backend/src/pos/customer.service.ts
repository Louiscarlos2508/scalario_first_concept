import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CustomerService {
    constructor(private prisma: PrismaService) { }

    async getCustomers(tenantId: string) {
        return this.prisma.customer.findMany({
            where: { tenantId },
            orderBy: { name: 'asc' },
        });
    }

    async createCustomer(tenantId: string, data: any) {
        return this.prisma.customer.create({
            data: {
                ...data,
                tenantId,
            },
        });
    }

    async updateCustomer(id: string, data: any) {
        return this.prisma.customer.update({
            where: { id },
            data,
        });
    }

    async getCustomerById(id: string) {
        return this.prisma.customer.findUnique({
            where: { id },
        });
    }

    async searchCustomers(tenantId: string, query: string) {
        return this.prisma.customer.findMany({
            where: {
                tenantId,
                OR: [
                    { name: { contains: query, mode: 'insensitive' } },
                    { phone: { contains: query, mode: 'insensitive' } },
                ],
            },
            take: 10,
        });
    }

    async settleDebt(id: string, amount: number) {
        return this.prisma.customer.update({
            where: { id },
            data: {
                balance: {
                    decrement: amount,
                },
            },
        });
    }
}
