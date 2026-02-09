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
        {
            name: 'Coca Cola',
            price: 500,
            category: 'Drinks',
            stockQuantity: 100,
            tenantId: tenant.id,
        },
        {
            name: 'Sandwich',
            price: 1500,
            category: 'Food',
            stockQuantity: 50,
            tenantId: tenant.id,
        },
        {
            name: 'Perrier',
            price: 800,
            category: 'Drinks',
            stockQuantity: 30,
            tenantId: tenant.id,
        },
    ];

    for (const p of products) {
        const existing = await prisma.product.findFirst({
            where: { name: p.name, tenantId: p.tenantId }
        });

        if (!existing) {
            const product = await prisma.product.create({
                data: p,
            });
            console.log('Created product:', product.name);
        } else {
            console.log('Product already exists:', p.name);
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
