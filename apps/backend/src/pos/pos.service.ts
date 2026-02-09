import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PosService {
    constructor(private prisma: PrismaService) { }

    async getProducts() {
        return this.prisma.product.findMany({
            orderBy: { name: 'asc' },
        });
    }

    async syncOrder(orderData: {
        uuid: string;
        totalAmount: number;
        itemNames: string[];
        tenantId?: string;
    }) {
        // For now, we use a default tenant if not provided, or better, we should get it from auth
        // Since we are in MVP mode, we'll try to find any existing tenant or create a dummy one
        let tenantId = orderData.tenantId;

        if (!tenantId) {
            const firstTenant = await this.prisma.tenant.findFirst();
            if (firstTenant) {
                tenantId = firstTenant.id;
            } else {
                const newTenant = await this.prisma.tenant.create({
                    data: { name: 'Default Tenant' },
                });
                tenantId = newTenant.id;
            }
        }

        return this.prisma.order.create({
            data: {
                id: orderData.uuid,
                totalAmount: orderData.totalAmount,
                itemsJson: orderData.itemNames as any, // Store as JSON array
                tenantId: tenantId!,
            },
        });
    }
}
