/**
 * Retail seed — boutique ouest-africaine
 * Tenant : Demo Store (d0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a)
 *
 * Run : npx ts-node -r tsconfig-paths/register prisma/seed-retail.ts
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const TENANT_ID = 'd0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a';

// ── Categories ───────────────────────────────────────────────────────────────

const CATEGORIES = [
  { id: 'a0000001-0000-0000-0000-000000000001', name: 'Boissons' },
  { id: 'a0000001-0000-0000-0000-000000000002', name: 'Alimentaire' },
  { id: 'a0000001-0000-0000-0000-000000000003', name: 'Hygiène' },
  { id: 'a0000001-0000-0000-0000-000000000004', name: 'Légumes & Épices' },
];

// ── Catalog items ─────────────────────────────────────────────────────────────

const CATALOG_ITEMS: Array<{
  id: string;
  name: string;
  price: number;
  barcode?: string;
  categoryId: string;
  stockQuantity: number;
}> = [
  // Boissons
  {
    id: 'b0000001-0000-0000-0000-000000000001',
    name: 'Coca-Cola 33cl',
    price: 500,
    barcode: '5449000000996',
    categoryId: 'a0000001-0000-0000-0000-000000000001',
    stockQuantity: 120,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000002',
    name: 'Fanta Orange 33cl',
    price: 500,
    barcode: '5449000131676',
    categoryId: 'a0000001-0000-0000-0000-000000000001',
    stockQuantity: 96,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000003',
    name: 'Eau minérale 1,5L',
    price: 300,
    barcode: '3274080005003',
    categoryId: 'a0000001-0000-0000-0000-000000000001',
    stockQuantity: 200,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000004',
    name: 'Jus de bissap 1L',
    price: 700,
    categoryId: 'a0000001-0000-0000-0000-000000000001',
    stockQuantity: 48,
  },
  // Alimentaire
  {
    id: 'b0000001-0000-0000-0000-000000000005',
    name: 'Riz parfumé 25kg',
    price: 12500,
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 30,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000006',
    name: 'Riz brisé 5kg',
    price: 2800,
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 50,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000007',
    name: 'Huile de palme 1L',
    price: 1200,
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 80,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000008',
    name: 'Sucre cristallisé 1kg',
    price: 800,
    barcode: '3017620421006',
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 100,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000009',
    name: 'Lait Nido 400g',
    price: 2500,
    barcode: '7622210449283',
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 40,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000010',
    name: 'Maggi cube x10',
    price: 200,
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 300,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000011',
    name: 'Tomate concentrée 400g',
    price: 600,
    barcode: '3035710006007',
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 85,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000012',
    name: 'Sardines à la tomate 200g',
    price: 650,
    categoryId: 'a0000001-0000-0000-0000-000000000002',
    stockQuantity: 72,
  },
  // Hygiène
  {
    id: 'b0000001-0000-0000-0000-000000000013',
    name: 'Savon OMO 200g',
    price: 350,
    categoryId: 'a0000001-0000-0000-0000-000000000003',
    stockQuantity: 90,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000014',
    name: 'Beurre de karité 500g',
    price: 1500,
    categoryId: 'a0000001-0000-0000-0000-000000000003',
    stockQuantity: 35,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000015',
    name: 'Dentifrice Signal 75ml',
    price: 800,
    barcode: '8714789884324',
    categoryId: 'a0000001-0000-0000-0000-000000000003',
    stockQuantity: 55,
  },
  // Légumes & Épices
  {
    id: 'b0000001-0000-0000-0000-000000000016',
    name: 'Oignons 1kg',
    price: 500,
    categoryId: 'a0000001-0000-0000-0000-000000000004',
    stockQuantity: 60,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000017',
    name: 'Tomates fraîches 1kg',
    price: 600,
    categoryId: 'a0000001-0000-0000-0000-000000000004',
    stockQuantity: 40,
  },
  {
    id: 'b0000001-0000-0000-0000-000000000018',
    name: 'Piment séché 100g',
    price: 300,
    categoryId: 'a0000001-0000-0000-0000-000000000004',
    stockQuantity: 80,
  },
];

// ── Contacts ──────────────────────────────────────────────────────────────────

const CONTACTS = [
  {
    id: 'd0000001-0000-0000-0000-000000000001',
    name: 'Aminata Diallo',
    phone: '+22177000001',
    contactType: 'customer',
    balance: 0,
  },
  {
    id: 'd0000001-0000-0000-0000-000000000002',
    name: 'Oumar Traoré',
    phone: '+22177000002',
    contactType: 'customer',
    balance: 2500,
  },
  {
    id: 'd0000001-0000-0000-0000-000000000003',
    name: 'Fatoumata Konaté',
    phone: '+22177000003',
    contactType: 'customer',
    balance: 0,
  },
  {
    id: 'd0000001-0000-0000-0000-000000000004',
    name: 'Moussa Coulibaly',
    phone: '+22177000004',
    contactType: 'customer',
    balance: 1200,
  },
  {
    id: 'd0000001-0000-0000-0000-000000000005',
    name: 'Distributeur Dakar',
    phone: '+22133000010',
    contactType: 'supplier',
    balance: 0,
  },
];

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\nSeeding retail data for tenant ${TENANT_ID}...\n`);

  // 1. Categories
  console.log('1. Seeding categories...');
  for (const cat of CATEGORIES) {
    await prisma.category.upsert({
      where: { id: cat.id },
      update: { name: cat.name },
      create: { id: cat.id, name: cat.name, tenantId: TENANT_ID },
    });
  }
  console.log(`   ✓ ${CATEGORIES.length} categories`);

  // 2. Catalog items + retail products
  console.log('2. Seeding catalog items + retail products...');
  for (const item of CATALOG_ITEMS) {
    const catalogItem = await prisma.catalogItem.upsert({
      where: { id: item.id },
      update: { name: item.name, price: item.price, barcode: item.barcode ?? null },
      create: {
        id: item.id,
        name: item.name,
        price: item.price,
        barcode: item.barcode ?? null,
        itemType: 'physical',
        categoryId: item.categoryId,
        tenantId: TENANT_ID,
      },
    });

    await prisma.retailProduct.upsert({
      where: { catalogItemId: catalogItem.id },
      update: { stockQuantity: item.stockQuantity },
      create: {
        id: item.id.replace('b0000001', 'e0000001'),
        catalogItemId: catalogItem.id,
        stockQuantity: item.stockQuantity,
        minStockLevel: 5,
      },
    });
  }
  console.log(`   ✓ ${CATALOG_ITEMS.length} catalog items + retail products`);

  // 3. Contacts
  console.log('3. Seeding contacts...');
  for (const c of CONTACTS) {
    await prisma.contact.upsert({
      where: { id: c.id },
      update: { name: c.name, phone: c.phone, balance: c.balance },
      create: {
        id: c.id,
        name: c.name,
        phone: c.phone,
        contactType: c.contactType,
        balance: c.balance,
        tenantId: TENANT_ID,
      },
    });
  }
  console.log(`   ✓ ${CONTACTS.length} contacts`);

  // Summary
  const [cats, items, products, contacts] = await Promise.all([
    prisma.category.count({ where: { tenantId: TENANT_ID } }),
    prisma.catalogItem.count({ where: { tenantId: TENANT_ID } }),
    prisma.retailProduct.count({ where: { catalogItem: { tenantId: TENANT_ID } } }),
    prisma.contact.count({ where: { tenantId: TENANT_ID } }),
  ]);

  console.log('\n── Summary ────────────────────────────────────────');
  console.log(`  categories:      ${cats}`);
  console.log(`  catalog_items:   ${items}`);
  console.log(`  retail_products: ${products}`);
  console.log(`  contacts:        ${contacts}`);
  console.log('───────────────────────────────────────────────────\n');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
