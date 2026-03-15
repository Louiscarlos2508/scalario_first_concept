/**
 * Rollback script: remove migrated catalog_items and retail_products
 * created by migrate-products.ts (those whose id exists in public.products).
 *
 * Usage:
 *   npx ts-node --project tsconfig.scripts.json scripts/rollback-migration.ts
 *   DATABASE_URL=<clone_url> npx ts-node --project tsconfig.scripts.json scripts/rollback-migration.ts
 *
 * SAFE: Only removes rows whose id matches public.products IDs.
 *       Does NOT touch rows that pre-existed in catalog_items / retail_products.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('\n⏪ Scalario Migration Rollback\n');

  // ── 1. Collect source IDs ──────────────────────────────────────────────────

  const products = await prisma.product.findMany({ select: { id: true } });
  const ids = products.map((p) => p.id);

  if (ids.length === 0) {
    console.log('No rows in public.products — nothing to roll back.');
    return;
  }

  console.log(`Rolling back ${ids.length} product(s) migrated from public.products...`);

  // ── 2. Delete retail_products first (FK child) ────────────────────────────

  const deletedRetail = await prisma.retailProduct.deleteMany({
    where: { catalogItemId: { in: ids } },
  });
  console.log(`  Deleted ${deletedRetail.count} row(s) from retail.retail_products`);

  // ── 3. Delete catalog_items (FK parent) ───────────────────────────────────

  const deletedCatalog = await prisma.catalogItem.deleteMany({
    where: { id: { in: ids } },
  });
  console.log(`  Deleted ${deletedCatalog.count} row(s) from shared.catalog_items`);

  // ── 4. Summary ────────────────────────────────────────────────────────────

  console.log('\nRollback Report:');
  console.log(`  retail.retail_products removed: ${deletedRetail.count}`);
  console.log(`  shared.catalog_items removed: ${deletedCatalog.count}`);
  console.log('\n✅ Rollback complete — public.products rows are intact');
}

main()
  .catch((err) => {
    console.error('Rollback failed:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
