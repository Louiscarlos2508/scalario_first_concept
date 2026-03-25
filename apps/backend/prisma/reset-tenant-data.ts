/**
 * Reset + re-seed catalogue Épicerie
 * businessType: epicerie
 *
 * CONFIGURATION REQUISE :
 *   1. Renseigner TENANT_ID ci-dessous :
 *      SELECT id FROM kernel.tenants WHERE "business_type" = 'epicerie';
 *   2. S'assurer que DATABASE_URL est défini dans .env
 *
 * Run : npm run db:reset-tenant  (depuis apps/backend/)
 *   ou : npx ts-node -r tsconfig-paths/register prisma/reset-tenant-data.ts
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

// Blandine Test — businessType: epicerie
// SELECT id FROM kernel.tenants WHERE "business_type" = 'epicerie';
const TENANT_ID = 'd0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a';

// ── Catégories (suggestedCategories epicerie) ─────────────────────────────

const CAT_FRUITS    = 'a0000002-0000-0000-0000-000000000001';
const CAT_EPICES    = 'a0000002-0000-0000-0000-000000000002';
const CAT_CEREALES  = 'a0000002-0000-0000-0000-000000000003';
const CAT_BOISSONS  = 'a0000002-0000-0000-0000-000000000004';
const CAT_LAITIERS  = 'a0000002-0000-0000-0000-000000000005';
const CAT_CONSERVES = 'a0000002-0000-0000-0000-000000000006';

const CATEGORIES = [
  { id: CAT_FRUITS,    name: 'Fruits & Légumes'   },
  { id: CAT_EPICES,    name: 'Épices'              },
  { id: CAT_CEREALES,  name: 'Céréales'            },
  { id: CAT_BOISSONS,  name: 'Boissons'            },
  { id: CAT_LAITIERS,  name: 'Produits laitiers'   },
  { id: CAT_CONSERVES, name: 'Conserves'           },
];

// ── Articles (30 articles épicerie) ──────────────────────────────────────

type ArticleData = {
  id: string;
  name: string;
  price: number;
  barcode?: string;
  categoryId: string;
  stock: number;
  minStock: number;
};

const CATALOG_ITEMS: ArticleData[] = [
  // ── Fruits & Légumes (6) ──────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000001', name: 'Tomates fraîches 1kg',     price:   600, categoryId: CAT_FRUITS,    stock: 40, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000002', name: 'Oignons 1kg',              price:   500, categoryId: CAT_FRUITS,    stock: 60, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000003', name: 'Pommes de terre 1kg',      price:   700, categoryId: CAT_FRUITS,    stock: 50, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000004', name: 'Bananes plantain (régime)',price:  1500, categoryId: CAT_FRUITS,    stock: 20, minStock:  5 },
  { id: 'b0000002-0000-0000-0000-000000000005', name: 'Carottes 500g',            price:   400, categoryId: CAT_FRUITS,    stock:  3, minStock: 10 }, // STOCK BAS
  { id: 'b0000002-0000-0000-0000-000000000006', name: 'Gombo séché 100g',         price:   350, categoryId: CAT_FRUITS,    stock: 80, minStock: 15 },

  // ── Épices (5) ────────────────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000010', name: 'Piment séché 100g',        price:   300, categoryId: CAT_EPICES,    stock:  80, minStock: 20 },
  { id: 'b0000002-0000-0000-0000-000000000011', name: 'Poivre noir moulu 50g',    price:   400, categoryId: CAT_EPICES,    stock:  45, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000012', name: 'Cumin 50g',                price:   350, categoryId: CAT_EPICES,    stock:  30, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000013', name: 'Bouillon cube Maggi x10',  price:   150, categoryId: CAT_EPICES,    stock: 200, minStock: 50 },
  { id: 'b0000002-0000-0000-0000-000000000014', name: 'Sel fin 1kg',              price:   200, categoryId: CAT_EPICES,    stock: 150, minStock: 30 },

  // ── Céréales (6) ─────────────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000020', name: 'Riz parfumé 25kg',         price: 12500, categoryId: CAT_CEREALES,  stock: 30, minStock:  5 },
  { id: 'b0000002-0000-0000-0000-000000000021', name: 'Riz brisé 5kg',            price:  2800, categoryId: CAT_CEREALES,  stock: 50, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000022', name: 'Mil 5kg',                  price:  1800, categoryId: CAT_CEREALES,  stock: 25, minStock:  5 },
  { id: 'b0000002-0000-0000-0000-000000000023', name: 'Maïs moulu 2kg',           price:  1000, categoryId: CAT_CEREALES,  stock: 40, minStock:  8 },
  { id: 'b0000002-0000-0000-0000-000000000024', name: 'Farine de blé 1kg',        price:   600, categoryId: CAT_CEREALES,  stock: 60, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000025', name: 'Semoule de mil 500g',      price:   450, categoryId: CAT_CEREALES,  stock:  0, minStock: 10 }, // RUPTURE

  // ── Boissons (5) ─────────────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000030', name: 'Eau minérale 1,5L',        price:   300, categoryId: CAT_BOISSONS,  stock: 200, minStock: 48 },
  { id: 'b0000002-0000-0000-0000-000000000031', name: 'Jus de bissap 1L',         price:   700, categoryId: CAT_BOISSONS,  stock:  48, minStock: 12 },
  { id: 'b0000002-0000-0000-0000-000000000032', name: 'Coca-Cola 33cl',           price:   500, categoryId: CAT_BOISSONS,  stock:  96, minStock: 24 },
  { id: 'b0000002-0000-0000-0000-000000000033', name: 'Lait concentré sucré 397g',price:  1100, categoryId: CAT_BOISSONS,  stock:  60, minStock: 15 },
  { id: 'b0000002-0000-0000-0000-000000000034', name: 'Thé Lipton x25',           price:   800, categoryId: CAT_BOISSONS,  stock:   4, minStock: 10 }, // STOCK BAS

  // ── Produits laitiers (4) ─────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000040', name: 'Lait en poudre 400g',      price:  2500, categoryId: CAT_LAITIERS,  stock: 35, minStock:  8 },
  { id: 'b0000002-0000-0000-0000-000000000041', name: 'Yaourt nature 500g',       price:   800, categoryId: CAT_LAITIERS,  stock: 20, minStock:  5 },
  { id: 'b0000002-0000-0000-0000-000000000042', name: 'Beurre de karité 200g',    price:   900, categoryId: CAT_LAITIERS,  stock: 15, minStock:  5 },
  { id: 'b0000002-0000-0000-0000-000000000043', name: 'Fromage fondu x8',         price:  1200, categoryId: CAT_LAITIERS,  stock:  2, minStock:  5 }, // STOCK BAS

  // ── Conserves (4) ─────────────────────────────────────────────────────
  { id: 'b0000002-0000-0000-0000-000000000050', name: 'Tomates concentrées 400g', price:   500, categoryId: CAT_CONSERVES, stock: 75, minStock: 15 },
  { id: 'b0000002-0000-0000-0000-000000000051', name: "Sardines à l'huile 125g",  price:   700, categoryId: CAT_CONSERVES, stock: 60, minStock: 12 },
  { id: 'b0000002-0000-0000-0000-000000000052', name: 'Haricots rouges 400g',     price:   550, categoryId: CAT_CONSERVES, stock: 45, minStock: 10 },
  { id: 'b0000002-0000-0000-0000-000000000053', name: 'Maïs en conserve 400g',    price:   600, categoryId: CAT_CONSERVES, stock: 30, minStock:  8 },
];

// ── Contacts ──────────────────────────────────────────────────────────────

const CONTACTS = [
  { id: 'd0000002-0000-0000-0000-000000000001', name: 'Aminata Diallo',    phone: '+22670000001', contactType: 'customer', balance:    0 },
  { id: 'd0000002-0000-0000-0000-000000000002', name: 'Oumar Traoré',      phone: '+22670000002', contactType: 'customer', balance: 2500 },
  { id: 'd0000002-0000-0000-0000-000000000003', name: 'Fatoumata Konaté',  phone: '+22670000003', contactType: 'customer', balance:    0 },
  { id: 'd0000002-0000-0000-0000-000000000004', name: 'Moussa Coulibaly',  phone: '+22670000004', contactType: 'customer', balance: 1200 },
  { id: 'd0000002-0000-0000-0000-000000000005', name: 'Bintou Sawadogo',   phone: '+22670000005', contactType: 'customer', balance: 5000 },
  { id: 'd0000002-0000-0000-0000-000000000006', name: 'SOPROFA Grossiste', phone: '+22620000001', contactType: 'supplier', balance:    0 },
];

// ── Clean (ordre FK strict) ───────────────────────────────────────────────

async function cleanTransactionalData() {
  console.log('🧹 Nettoyage...');

  const inv = await prisma.inventoryMovement.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${inv.count} mouvements de stock supprimés`);

  // RetailSale avant Transaction et PosSession (FK transactionId, sessionId)
  const rs = await prisma.retailSale
    .deleteMany({ where: { transaction: { tenantId: TENANT_ID } } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${rs.count} ventes retail supprimées`);

  const txn = await prisma.transaction.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${txn.count} transactions supprimées`);

  const pos = await prisma.posSession.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${pos.count} sessions POS supprimées`);

  const exp = await prisma.expense
    .deleteMany({ where: { tenantId: TENANT_ID } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${exp.count} dépenses supprimées`);

  // ClientOrderLine avant ClientOrder
  const col = await prisma.clientOrderLine
    .deleteMany({ where: { clientOrder: { tenantId: TENANT_ID } } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${col.count} lignes commande client supprimées`);

  const co = await prisma.clientOrder
    .deleteMany({ where: { tenantId: TENANT_ID } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${co.count} commandes client supprimées`);

  // PurchaseOrderLine avant PurchaseOrder, avant Contact (FK supplierId)
  const pol = await prisma.purchaseOrderLine
    .deleteMany({ where: { purchaseOrder: { tenantId: TENANT_ID } } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${pol.count} lignes commande fournisseur supprimées`);

  const po = await prisma.purchaseOrder
    .deleteMany({ where: { tenantId: TENANT_ID } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${po.count} commandes fournisseur supprimées`);

  const con = await prisma.contact.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${con.count} contacts supprimés`);

  // Enfants de CatalogItem avant CatalogItem
  const ret = await prisma.returnRecord
    .deleteMany({ where: { tenantId: TENANT_ID } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${ret.count} retours supprimés`);

  const pv = await prisma.productVariant
    .deleteMany({ where: { tenantId: TENANT_ID } })
    .catch(() => ({ count: 0 }));
  console.log(`   ✓ ${pv.count} variantes supprimées`);

  const rp = await prisma.retailProduct.deleteMany({
    where: { catalogItem: { tenantId: TENANT_ID } },
  });
  console.log(`   ✓ ${rp.count} retail products supprimés`);

  const items = await prisma.catalogItem.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${items.count} articles supprimés`);

  const cats = await prisma.category.deleteMany({ where: { tenantId: TENANT_ID } });
  console.log(`   ✓ ${cats.count} catégories supprimées`);
}

// ── Seed ──────────────────────────────────────────────────────────────────

async function seedData() {
  console.log('\n🌱 Re-seed épicerie...');

  // Catégories
  for (const cat of CATEGORIES) {
    await prisma.category.upsert({
      where: { id: cat.id },
      update: { name: cat.name },
      create: { id: cat.id, name: cat.name, tenantId: TENANT_ID },
    });
  }
  console.log(`   ✓ ${CATEGORIES.length} catégories (suggestedCategories épicerie)`);

  // Articles + stocks
  for (const item of CATALOG_ITEMS) {
    await prisma.catalogItem.upsert({
      where: { id: item.id },
      update: { name: item.name, price: item.price },
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
      where: { catalogItemId: item.id },
      update: { stockQuantity: item.stock, minStockLevel: item.minStock },
      create: {
        id: item.id.replace('b0000002', 'e0000002'),
        catalogItemId: item.id,
        stockQuantity: item.stock,
        minStockLevel: item.minStock,
      },
    });
  }
  console.log(`   ✓ ${CATALOG_ITEMS.length} articles`);

  // Contacts
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
}

// ── Main ──────────────────────────────────────────────────────────────────

async function main() {
  const tenant = await prisma.tenant.findUnique({ where: { id: TENANT_ID } });
  if (!tenant) {
    console.error('❌ Tenant introuvable. Vérifier TENANT_ID.');
    process.exit(1);
  }
  if (tenant.businessType !== 'epicerie') {
    console.warn(`⚠️  businessType = ${tenant.businessType} (attendu: epicerie)`);
  }
  console.log(`\n🏪 ${tenant.name} — businessType: ${tenant.businessType}`);
  console.log('⚠️  Données transactionnelles supprimées. Users conservés.\n');

  await cleanTransactionalData();
  await seedData();

  const lowStock = CATALOG_ITEMS.filter(i => i.stock > 0 && i.stock < i.minStock);
  const outOfStock = CATALOG_ITEMS.filter(i => i.stock === 0);
  const sessionCount = await prisma.posSession.count({ where: { tenantId: TENANT_ID } });

  console.log('\n📊 Résumé :');
  if (lowStock.length > 0) {
    console.log(`   Stock bas  : ${lowStock.map(i => `${i.name} (${i.stock})`).join(', ')}`);
  }
  if (outOfStock.length > 0) {
    console.log(`   Rupture    : ${outOfStock.map(i => `${i.name} (${i.stock})`).join(', ')}`);
  }
  console.log(`   Sessions   : ${sessionCount} — POS prêt à ouvrir`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
