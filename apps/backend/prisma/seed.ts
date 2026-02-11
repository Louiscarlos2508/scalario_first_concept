import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import "dotenv/config";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
    // Create a tenant first
    let tenant = await prisma.tenant.findFirst();

    if (!tenant) {
        tenant = await prisma.tenant.create({
            data: {
                name: 'Test Store',
            },
        });
        console.log('Created tenant:', tenant.id);
    } else {
        console.log('Using existing tenant:', tenant.id);
    }

    // Create some products
    const products = [
        { name: 'Coca Cola', price: 500, categoryName: 'Drinks', stockQuantity: 100 },
        { name: 'Sandwich', price: 1500, categoryName: 'Food', stockQuantity: 50 },
        { name: 'Perrier', price: 800, categoryName: 'Drinks', stockQuantity: 30 },
    ];

    for (const pData of products) {
        // Find or create category
        let category = await prisma.category.findFirst({
            where: { name: pData.categoryName, tenantId: tenant.id }
        });

        if (!category) {
            category = await prisma.category.create({
                data: { name: pData.categoryName, tenantId: tenant.id }
            });
        }

        const existing = await prisma.product.findFirst({
            where: { name: pData.name, tenantId: tenant.id }
        });

        if (!existing) {
            const product = await prisma.product.create({
                data: {
                    name: pData.name,
                    price: pData.price,
                    stockQuantity: pData.stockQuantity,
                    tenantId: tenant.id,
                    categoryId: category.id,
                },
            });
            console.log('Created product:', product.name);
        } else {
            console.log('Product already exists:', pData.name);
        }
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
