import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CatalogService } from '../shared/catalog/catalog.service';
import { ContactsService } from '../shared/contacts/contacts.service';
import { InventoryService } from '../shared/inventory/inventory.service';
import { randomUUID } from 'crypto';

@Injectable()
export class PosService {
    constructor(
        private prisma: PrismaService,
        private catalogService: CatalogService,
        private contactsService: ContactsService,
        private inventoryService: InventoryService,
    ) { }

    async getProducts(params: { query?: string, page?: number, limit?: number, tenantId?: string, since?: string } = {}) {
        const { query, page = 1, limit = 50, tenantId, since } = params;
        const skip = (page - 1) * limit;

        const where: any = {};
        if (tenantId) where.tenantId = tenantId;

        if (since) {
            where.updatedAt = { gte: new Date(since) };
        } else {
            where.isDeleted = false;
        }

        if (query) {
            where.OR = [
                { name: { contains: query, mode: 'insensitive' } },
                { barcode: { contains: query, mode: 'insensitive' } },
            ];
        }

        const [items, total] = await Promise.all([
            this.prisma.catalogItem.findMany({
                where,
                include: { retailProduct: { select: { stockQuantity: true, minStockLevel: true } } },
                orderBy: { name: 'asc' },
                skip,
                take: limit,
            }),
            this.prisma.catalogItem.count({ where }),
        ]);

        return {
            items: items.map((item) => ({
                id: item.id,
                name: item.name,
                price: item.price,
                barcode: item.barcode,
                categoryId: item.categoryId,
                tenantId: item.tenantId,
                isDeleted: item.isDeleted,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt,
                stockQuantity: item.retailProduct?.stockQuantity ?? 0,
            })),
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }

    async deleteProduct(id: string) {
        return this.prisma.catalogItem.update({
            where: { id },
            data: { isDeleted: true },
        });
    }

    async syncProduct(productData: any) {
        try {
            let tenantId = productData.tenantId;
            if (!tenantId) {
                const tenant = await this.prisma.tenant.findFirst();
                tenantId = tenant?.id;
            }

            let categoryId: string | null = null;
            if (productData.category && tenantId) {
                const category = await this.prisma.category.upsert({
                    where: { id: productData.category_id || randomUUID() },
                    update: {},
                    create: {
                        name: productData.category,
                        tenantId: tenantId,
                    }
                });
                categoryId = category.id;
            }

            const remoteId = productData.remoteId || randomUUID();

            const catalogItem = await this.prisma.catalogItem.upsert({
                where: { id: remoteId },
                update: {
                    name: productData.name,
                    price: productData.price,
                    category: categoryId ? { connect: { id: categoryId } } : { disconnect: true },
                    barcode: productData.barcode,
                },
                create: {
                    id: remoteId,
                    name: productData.name,
                    price: productData.price,
                    itemType: 'physical',
                    category: categoryId ? { connect: { id: categoryId } } : undefined,
                    barcode: productData.barcode,
                    tenantId: tenantId,
                },
            });

            await this.prisma.retailProduct.upsert({
                where: { catalogItemId: remoteId },
                update: { stockQuantity: productData.stockQuantity ?? 0 },
                create: {
                    catalogItemId: remoteId,
                    stockQuantity: productData.stockQuantity ?? 0,
                },
            });

            return catalogItem;
        } catch (error) {
            console.error('Product Sync Error:', error);
            throw error;
        }
    }

    async adjustStock(productId: string, quantity: number, type: string, reason: string) {
        const item = await this.prisma.catalogItem.findUnique({ where: { id: productId } });
        if (!item) throw new Error('Product not found');

        return this.inventoryService.createMovement({
            catalogItemId: productId,
            quantity: Math.abs(quantity),
            type,
            reason,
            tenantId: item.tenantId,
        });
    }

    async heartbeat(data: any) {
        const deviceId = data.deviceId || 'unknown';
        let tenantId = data.tenantId;

        if (!tenantId) {
            const tenant = await this.prisma.tenant.findFirst();
            tenantId = tenant?.id;
        }

        if (tenantId) {
            await this.prisma.terminalStatus.upsert({
                where: { deviceId },
                update: {
                    status: 'ONLINE',
                    lastSeen: new Date(),
                    tenantId: tenantId,
                },
                create: {
                    deviceId,
                    status: 'ONLINE',
                    lastSeen: new Date(),
                    tenantId: tenantId,
                },
            });
        }

        console.log(`[Heartbeat] Terminal ${deviceId} updated at ${new Date().toISOString()}`);
        return { status: 'ok', timestamp: new Date() };
    }

    async getStockAcrossBranches(barcode: string, userId: string) {
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId },
            select: { organizationId: true },
        });

        const tenantIds = memberships.map(m => m.organizationId);

        return this.prisma.catalogItem.findMany({
            where: {
                barcode,
                tenantId: { in: tenantIds },
                isDeleted: false,
            },
            select: {
                id: true,
                name: true,
                tenantId: true,
                retailProduct: { select: { stockQuantity: true } },
            },
        });
    }

    async getTerminals(tenantId?: string) {
        return this.prisma.terminalStatus.findMany({
            where: tenantId ? { tenantId } : {},
            orderBy: { lastSeen: 'desc' },
        });
    }

    async getCategories(tenantId: string, since?: string) {
        return this.catalogService.getCategories(tenantId, since);
    }

    async createCategory(data: any) {
        return this.catalogService.createCategory(data);
    }

    async deleteCategory(id: string) {
        return this.catalogService.deleteCategory(id);
    }

    // --- Customer Management (proxied to ContactsService) ---

    async getCustomers(tenantId?: string, query?: string, since?: string) {
        if (query) {
            return this.contactsService.searchContacts(tenantId ?? '', query);
        }
        const result = await this.contactsService.getContacts({ tenantId, since });
        return result.items;
    }

    async createCustomer(data: any) {
        return this.contactsService.createContact(data, null);
    }

    async settleDebt(customerId: string, amount: number) {
        return this.contactsService.settleDebt(customerId, amount, null, null);
    }
}
