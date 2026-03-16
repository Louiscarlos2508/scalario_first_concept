/**
 * Validation script: verify migration results — row counts + FK integrity
 *
 * Usage:
 *   npx ts-node --project tsconfig.scripts.json scripts/validate-migration.ts
 *   DATABASE_URL=<clone_url> npx ts-node --project tsconfig.scripts.json scripts/validate-migration.ts
 *
 * Exits with code 0 on OK, 1 on ERRORS.
 */

import { PrismaClient } from '@prisma/client';
import {
  buildMigrationReport,
  validateFkIntegrity,
  formatReport,
  TableCount,
  FkError,
} from '../src/migration/migration-utils';

const prisma = new PrismaClient();

async function main() {
  console.log('\n🔍 Scalario Migration Validator\n');

  const startMs = Date.now();

  // ── 1. Row counts ─────────────────────────────────────────────────────────

  const [productCount, catalogCount, retailProductCount] = await Promise.all([
    prisma.product.count({ where: { isDeleted: false } }),
    prisma.catalogItem.count({ where: { itemType: 'physical' } }),
    prisma.retailProduct.count(),
  ]);

  const tables: TableCount[] = [
    {
      table: 'public.products → shared.catalog_items',
      sourceCount: productCount,
      destCount: catalogCount,
    },
    {
      table: 'public.products → retail.retail_products',
      sourceCount: productCount,
      destCount: retailProductCount,
    },
  ];

  // ── 2. FK integrity checks ────────────────────────────────────────────────

  // Check: every retail_product.catalog_item_id exists in catalog_items
  const orphanRetailProducts = await prisma.$queryRaw<{ count: bigint }[]>`
    SELECT COUNT(*) as count
    FROM retail.retail_products rp
    WHERE NOT EXISTS (
      SELECT 1 FROM shared.catalog_items ci WHERE ci.id = rp.catalog_item_id
    )
  `;

  // Check: every retail_sale.transaction_id exists in transactions
  const orphanRetailSales = await prisma.$queryRaw<{ count: bigint }[]>`
    SELECT COUNT(*) as count
    FROM retail.retail_sales rs
    WHERE NOT EXISTS (
      SELECT 1 FROM shared.transactions t WHERE t.id = rs.transaction_id
    )
  `;

  // Check: every retail_sale.session_id (non-null) exists in pos_sessions
  const orphanSaleSessions = await prisma.$queryRaw<{ count: bigint }[]>`
    SELECT COUNT(*) as count
    FROM retail.retail_sales rs
    WHERE rs.session_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.pos_sessions ps WHERE ps.id = rs.session_id
      )
  `;

  const fkChecks: FkError[] = [
    {
      table: 'retail_products',
      field: 'catalog_item_id',
      orphanCount: Number(orphanRetailProducts[0]?.count ?? 0),
    },
    {
      table: 'retail_sales',
      field: 'transaction_id',
      orphanCount: Number(orphanRetailSales[0]?.count ?? 0),
    },
    {
      table: 'retail_sales',
      field: 'session_id',
      orphanCount: Number(orphanSaleSessions[0]?.count ?? 0),
    },
  ];

  const { errors: fkErrors } = validateFkIntegrity(fkChecks);
  const durationMs = Date.now() - startMs;

  // ── 3. Report ─────────────────────────────────────────────────────────────

  const report = buildMigrationReport(tables, fkErrors, [], durationMs);
  console.log(formatReport(report));

  if (report.overallStatus === 'OK') {
    console.log('\n✅ Validation PASSED — migration is clean, referential integrity verified');
    process.exit(0);
  } else {
    console.error('\n❌ Validation FAILED — see errors above');
    process.exit(1);
  }
}

main()
  .catch((err) => {
    console.error('Validation script failed:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
