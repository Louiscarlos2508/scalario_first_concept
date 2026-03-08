import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PosService {
    constructor(private prisma: PrismaService) { }

    async getProducts(params: { query?: string, page?: number, limit?: number, tenantId?: string, since?: string } = {}) {
        const { query, page = 1, limit = 50, tenantId, since } = params;
        const skip = (page - 1) * limit;

        const where: any = {};
        if (tenantId) where.tenantId = tenantId;

        if (since) {
            // When querying since a specific time, include soft-deleted items
            // so the frontend can recognize and remove them (tombstoning).
            where.updatedAt = { gte: new Date(since) };
        } else {
            // Normal query: exclude deleted items
            where.isDeleted = false;
        }

        if (query) {
            where.OR = [
                { name: { contains: query, mode: 'insensitive' } },
                { barcode: { contains: query, mode: 'insensitive' } },
            ];
        }

        const [items, total] = await Promise.all([
            this.prisma.product.findMany({
                where,
                orderBy: { name: 'asc' },
                skip,
                take: limit,
            }),
            this.prisma.product.count({ where }),
        ]);

        return {
            items,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }

    async deleteProduct(id: string) {
        return this.prisma.product.update({
            where: { id },
            data: { isDeleted: true },
        });
    }

    async syncOrder(orderData: any) {
        try {
            let tenantId = orderData.tenantId;

            // Verify provided tenantId
            if (tenantId) {
                const tenantExists = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
                if (!tenantExists) tenantId = null;
            }

            if (!tenantId) {
                const tenant = await this.prisma.tenant.findFirst();
                if (!tenant) {
                    const newTenant = await this.prisma.tenant.create({
                        data: { name: 'Automated Tenant' },
                    });
                    tenantId = newTenant.id;
                } else {
                    tenantId = tenant.id;
                }
            }

            // 1. Check if order already exists to ensure idempotency
            const existingOrder = await this.prisma.order.findUnique({
                where: { id: orderData.uuid },
            });

            // Check if session exists before trying to connect
            let sessionExists = false;
            if (orderData.sessionId) {
                const session = await this.prisma.posSession.findUnique({
                    where: { id: orderData.sessionId }
                });
                sessionExists = !!session;
            }

            // Check customer existence
            let validCustomerId: string | undefined = undefined;
            if (orderData.customer_id) {
                const customer = await this.prisma.customer.findUnique({ where: { id: orderData.customer_id } });
                if (customer) validCustomerId = customer.id;
            }

            const order = await this.prisma.order.upsert({
                where: { id: orderData.uuid },
                update: {
                    totalAmount: orderData.totalAmount,
                    itemsJson: orderData.items || [],
                    paymentMethod: orderData.paymentMethod,
                    paymentSplits: orderData.payment_splits,
                    session: sessionExists ? { connect: { id: orderData.sessionId } } : undefined,
                },
                create: {
                    id: orderData.uuid,
                    totalAmount: orderData.totalAmount,
                    itemsJson: orderData.items || [],
                    paymentMethod: orderData.paymentMethod,
                    paymentSplits: orderData.payment_splits,
                    session: sessionExists ? { connect: { id: orderData.sessionId } } : undefined,
                    customer: validCustomerId ? { connect: { id: validCustomerId } } : undefined,
                    tenant: { connect: { id: tenantId } },
                },
            });
            // Handle Credit Payment: Update customer balance ONLY if it's a new order or balance changed (simplified to new order for MVP)
            if (!existingOrder) {
                if (orderData.paymentMethod === 'CREDIT' && orderData.customer_id && validCustomerId) {
                    await this.prisma.customer.update({
                        where: { id: orderData.customer_id },
                        data: {
                            balance: {
                                increment: orderData.totalAmount,
                            },
                        },
                    });
                } else if (orderData.paymentMethod === 'SPLIT' && orderData.payment_splits && orderData.customer_id && validCustomerId) {
                    // If it's a split and one of the splits is CREDIT
                    const splits = typeof orderData.payment_splits === 'string'
                        ? JSON.parse(orderData.payment_splits)
                        : orderData.payment_splits;

                    if (splits['CREDIT']) {
                        await this.prisma.customer.update({
                            where: { id: orderData.customer_id },
                            data: {
                                balance: {
                                    increment: splits['CREDIT'],
                                },
                            },
                        });
                    }
                }
            }

            return order;
        } catch (error: any) {
            console.error('POS Sync Error Internal:', error);
            throw error; // Let NestJS handle the 500 now that we've logged it
        }
    }

    async syncProduct(productData: any) {
        try {
            let tenantId = productData.tenantId;
            if (!tenantId) {
                const tenant = await this.prisma.tenant.findFirst();
                tenantId = tenant?.id;
            }

            // Handle Category look up or create
            let categoryId: string | null = null;
            if (productData.category && tenantId) {
                const category = await this.prisma.category.upsert({
                    where: { id: productData.category_id || require('crypto').randomUUID() }, // Use provided ID if available, else name lookup would be better but for now let's use name as fallback
                    update: {},
                    create: {
                        name: productData.category,
                        tenantId: tenantId,
                    }
                });
                categoryId = category.id;
            }

            // Generate UUID if not provided (for new products)
            const remoteId = productData.remoteId || (global as any).crypto?.randomUUID?.() || require('crypto').randomUUID();

            return this.prisma.product.upsert({
                where: { id: remoteId },
                update: {
                    name: productData.name,
                    price: productData.price,
                    category: categoryId ? { connect: { id: categoryId } } : { disconnect: true },
                    barcode: productData.barcode,
                    stockQuantity: productData.stockQuantity,
                },
                create: {
                    id: remoteId,
                    name: productData.name,
                    price: productData.price,
                    category: categoryId ? { connect: { id: categoryId } } : undefined,
                    barcode: productData.barcode,
                    stockQuantity: productData.stockQuantity,
                    tenant: { connect: { id: tenantId } },
                },
            });
        } catch (error) {
            console.error('Product Sync Error:', error);
            throw error;
        }
    }

    async adjustStock(productId: string, quantity: number, type: string, reason: string) {
        return this.prisma.$transaction(async (tx) => {
            const product = await tx.product.findUnique({
                where: { id: productId },
            });

            if (!product) {
                throw new Error('Product not found');
            }

            // Update product stock
            const updatedProduct = await tx.product.update({
                where: { id: productId },
                data: {
                    stockQuantity: {
                        increment: quantity,
                    },
                },
            });

            // Log movement
            await tx.stockMovement.create({
                data: {
                    productId,
                    quantity,
                    type,
                    reason,
                    tenantId: product.tenantId,
                },
            });

            return updatedProduct;
        });
    }

    async getSalesStats(startDate?: string, endDate?: string, tenantId?: string) {
        try {
            const start = startDate ? new Date(startDate) : new Date();
            if (!startDate) start.setDate(start.getDate() - 7);

            const end = endDate ? new Date(endDate) : new Date();

            // Use direct filtering if tenantId is provided
            const rawStats = await this.prisma.$queryRaw`
                SELECT 
                    date_trunc('day', created_at) as day,
                    CAST(sum(total_amount) AS DOUBLE PRECISION) as revenue,
                    CAST(count(id) AS INTEGER) as "orderCount"
                FROM orders
                WHERE created_at >= ${start} AND created_at <= ${end}
                AND (${tenantId}::uuid IS NULL OR tenant_id = ${tenantId}::uuid)
                GROUP BY day
                ORDER BY day ASC
            `;

            return rawStats;
        } catch (error) {
            console.error('Error in getSalesStats:', error);
            throw error;
        }
    }

    async heartbeat(data: any) {
        const deviceId = data.deviceId || 'unknown';
        let tenantId = data.tenantId;

        // Fallback tenant if not provided
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

    async getStockMovements(startDate?: string, endDate?: string, tenantId?: string) {
        const where: any = {};
        if (tenantId) where.tenantId = tenantId;
        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate) where.createdAt.gte = new Date(startDate);
            if (endDate) where.createdAt.lte = new Date(endDate);
        }

        return this.prisma.stockMovement.findMany({
            where,
            include: {
                product: {
                    select: { name: true }
                }
            },
            orderBy: { createdAt: 'desc' },
            take: 100, // Limit to recent 100
        });
    }

    async getSalesReport(startDate?: string, endDate?: string, tenantId?: string) {
        try {
            const start = startDate ? new Date(startDate) : new Date(0);
            const end = endDate ? new Date(endDate) : new Date();

            const where: any = {
                createdAt: {
                    gte: start,
                    lte: end,
                },
            };
            if (tenantId) where.tenantId = tenantId;

            const orders = await this.prisma.order.findMany({
                where,
            });

            const productSales: Record<string, { name: string, quantity: number, revenue: number }> = {};
            const paymentMethodStats: Record<string, number> = {};

            orders.forEach(order => {
                // Aggregate Payment Methods
                const method = order.paymentMethod || 'UNKNOWN';
                if (!paymentMethodStats[method]) paymentMethodStats[method] = 0;
                paymentMethodStats[method] += Number(order.totalAmount);

                // Aggregate Products
                const items = order.itemsJson as any[];
                if (Array.isArray(items)) {
                    items.forEach(item => {
                        const pid = item.productId || item.name || 'UNKNOWN';
                        if (!productSales[pid]) {
                            productSales[pid] = {
                                name: item.name,
                                quantity: 0,
                                revenue: 0,
                            };
                        }
                        productSales[pid].quantity += Number(item.quantity);
                        productSales[pid].revenue += Number(item.quantity) * Number(item.price);
                    });
                }
            });

            return {
                productSales: Object.values(productSales),
                paymentMethodStats: Object.entries(paymentMethodStats).map(([name, value]) => ({ name, value })),
            };
        } catch (error) {
            console.error('Error in getSalesReport:', error);
            throw error;
        }
    }

    async getStockAcrossBranches(barcode: string, userId: string) {
        // 1. Get all tenants the user belongs to
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId },
            select: { organizationId: true },
        });

        const tenantIds = memberships.map(m => m.organizationId);

        // 2. Find products with this barcode in those tenants
        return this.prisma.product.findMany({
            where: {
                barcode,
                tenantId: { in: tenantIds },
            },
            select: {
                id: true,
                name: true,
                stockQuantity: true,
                tenant: {
                    select: {
                        id: true,
                        name: true,
                    },
                },
            },
        });
    }

    async getTerminals(tenantId?: string) {
        return this.prisma.terminalStatus.findMany({
            where: tenantId ? { tenantId } : {},
            orderBy: { lastSeen: 'desc' },
        });
    }

    async getCategories(tenantId: string) {
        return this.prisma.category.findMany({
            where: { tenantId },
            orderBy: { name: 'asc' },
        });
    }

    async createCategory(data: any) {
        return this.prisma.category.create({
            data: {
                name: data.name,
                tenantId: data.tenantId,
            },
        });
    }

    async deleteCategory(id: string) {
        return this.prisma.category.delete({
            where: { id },
        });
    }

    // --- Customer Management ---

    async getCustomers(tenantId?: string, query?: string) {
        const where: any = {};
        if (tenantId) where.tenantId = tenantId;
        if (query) {
            where.OR = [
                { name: { contains: query, mode: 'insensitive' } },
                { phone: { contains: query, mode: 'insensitive' } },
                { email: { contains: query, mode: 'insensitive' } },
            ];
        }

        return this.prisma.customer.findMany({
            where,
            orderBy: { name: 'asc' },
        });
    }

    async createCustomer(data: any) {
        return this.prisma.customer.create({
            data: {
                name: data.name,
                phone: data.phone,
                email: data.email,
                address: data.address,
                tenantId: data.tenantId,
            },
        });
    }

    async settleDebt(customerId: string, amount: number) {
        return this.prisma.customer.update({
            where: { id: customerId },
            data: {
                balance: {
                    decrement: amount,
                },
            },
        });
    }
}
