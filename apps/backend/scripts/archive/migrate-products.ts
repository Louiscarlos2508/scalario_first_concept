/**
 * Migration script: public.products → shared.catalog_items + retail.retail_products
 *
 * Usage:
 *   npx ts-node --project tsconfig.scripts.json scripts/migrate-products.ts [--dry-run]
 *   DATABASE_URL=<clone_url> npx ts-node --project tsconfig.scripts.json scripts/migrate-products.ts
 *
 * Options:
 *   --dry-run   Preview what would be migrated without writing to DB
 */

import { PrismaClient } from '@prisma/client';
import { formatReport, buildMigrationReport, TableCount, FkError } from '../src/migration/migration-utils';

const DRY_RUN = process.argv.includes('--dry-run');
const prisma = new PrismaClient();

async function main() {
  console.log(`\n🚀 Scalario Product Migration (${DRY_RUN ? 'DRY RUN' : 'LIVE'})\n`);

  // ── 1. Load all legacy products ───────────────────────────────────────────

  const products = await prisma.product.findMany({
    where: { isDeleted: false },
  });

  console.log(`Found ${products.length} product(s) in public.products`);

  if (products.length === 0) {
    console.log('Nothing to migrate. Exiting.');
    return;
  }

  if (DRY_RUN) {
    console.log('\n[DRY RUN] Would migrate the following products:');
    for (const p of products) {
      console.log(`  → ${p.id} | ${p.name} | price=${p.price} | stock=${p.stockQuantity} | tenant=${p.tenantId}`);
    }
    console.log(`\n[DRY RUN] Would upsert ${products.length} CatalogItem(s) into shared.catalog_items`);
    console.log(`[DRY RUN] Would upsert ${products.length} RetailProduct(s) into retail.retail_products`);
    console.log('\n[DRY RUN] No changes written to database.');
    return;
  }

  // ── 2. Migrate each product ───────────────────────────────────────────────

  const startMs = Date.now();
  let migratedCount = 0;
  const warnings: string[] = [];

  for (const product of products) {
    if (!product.barcode) {
      warnings.push(`Product ${product.id} (${product.name}) has no barcode — migrated with null barcode`);
    }

    await prisma.$transaction(async (tx) => {
      // Upsert CatalogItem (shared schema) — keyed on id
      await tx.catalogItem.upsert({
        where: { id: product.id },
        create: {
          id: product.id,
          name: product.name,
          price: product.price,
          barcode: product.barcode ?? null,
          itemType: 'physical',
          categoryId: product.categoryId ?? null,
          tenantId: product.tenantId,
          isDeleted: product.isDeleted,
          createdAt: product.createdAt,
        },
        update: {
          name: product.name,
          price: product.price,
          barcode: product.barcode ?? null,
          categoryId: product.categoryId ?? null,
          isDeleted: product.isDeleted,
        },
      });

      // Upsert RetailProduct (retail schema) — keyed on catalogItemId (unique)
      await tx.retailProduct.upsert({
        where: { catalogItemId: product.id },
        create: {
          catalogItemId: product.id,
          stockQuantity: product.stockQuantity,
          minStockLevel: null,
        },
        update: {
          stockQuantity: product.stockQuantity,
        },
      });
    });

    migratedCount++;
  }

  const durationMs = Date.now() - startMs;

  // ── 3. Build and print report ─────────────────────────────────────────────

  const [catalogCount, retailCount] = await Promise.all([
    prisma.catalogItem.count({ where: { tenantId: { in: products.map((p) => p.tenantId) } } }),
    prisma.retailProduct.count(),
  ]);

  const tables: TableCount[] = [
    { table: 'public.products → shared.catalog_items', sourceCount: products.length, destCount: catalogCount },
    { table: 'public.products → retail.retail_products', sourceCount: products.length, destCount: retailCount },
  ];

  const fkErrors: FkError[] = [];
  const report = buildMigrationReport(tables, fkErrors, warnings, durationMs);
  console.log('\n' + formatReport(report));

  if (report.overallStatus === 'OK') {
    console.log(`\n✅ Migration complete — ${migratedCount} product(s) migrated in ${(durationMs / 1000).toFixed(1)}s`);
  } else {
    console.error('\n❌ Migration completed with errors — run validate-migration.ts for full FK check');
    process.exit(1);
  }
}

main()
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
