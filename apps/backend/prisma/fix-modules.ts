/**
 * fix-modules — corrige la table kernel.modules
 *
 * - Supprime les modules obsolètes (pos, reporting, dashboard, connect, enterprise)
 * - Upsert les 4 modules shared + 1 module vertical retail
 * - Migre les tenant_modules : remplace pos → retail
 *
 * Run : npm run fix:modules
 * Idempotent.
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const TARGET_MODULES = [
  { code: 'catalog',           name: 'Catalogue',                type: 'shared',   dependencies: [] },
  { code: 'clients',           name: 'Clients',                  type: 'shared',   dependencies: [] },
  { code: 'inventory',         name: 'Inventaire & Stock',       type: 'shared',   dependencies: ['catalog'] },
  { code: 'transactions',      name: 'Transactions & Ventes',    type: 'shared',   dependencies: ['catalog', 'clients'] },
  { code: 'expenses',          name: 'Dépenses & Charges',       type: 'shared',   dependencies: [] },
  { code: 'reports',           name: 'Rapports & KPI',           type: 'shared',   dependencies: ['transactions'] },
  { code: 'variants',          name: 'Variantes Produit',        type: 'shared',   dependencies: ['catalog'] },
  { code: 'pricing',           name: 'Multi-Tarifs',             type: 'shared',   dependencies: ['catalog'] },
  { code: 'promotions',        name: 'Promotions & Remises',     type: 'shared',   dependencies: ['catalog'] },
  { code: 'purchase_orders',   name: 'Commandes Fournisseurs',   type: 'shared',   dependencies: ['catalog', 'clients', 'inventory'] },
  { code: 'internal_requests', name: 'Demandes Internes',        type: 'shared',   dependencies: ['catalog', 'inventory'] },
  { code: 'batches',           name: 'Lots & Fraîcheur',         type: 'shared',   dependencies: ['catalog', 'inventory'] },
  { code: 'client_orders',     name: 'Commandes Clients',        type: 'shared',   dependencies: ['catalog', 'clients', 'transactions'] },
  { code: 'retail',            name: 'Point de Vente (POS)',     type: 'vertical', dependencies: ['catalog', 'inventory', 'transactions', 'clients'] },
];

const OBSOLETE_CODES = ['pos', 'reporting', 'dashboard', 'connect', 'enterprise', 'contacts'];

async function main() {
  console.log('\n🔧 fix-modules\n');

  // ── 1. Upsert target modules ───────────────────────────────────────────────
  console.log('1. Upserting target modules...');
  for (const mod of TARGET_MODULES) {
    await prisma.module.upsert({
      where: { code: mod.code },
      update: { name: mod.name, type: mod.type, dependencies: mod.dependencies },
      create: mod,
    });
    console.log(`   ✓ ${mod.code} (${mod.type})`);
  }

  // ── 2. Activate expenses + reports for tenants that already have retail ────
  console.log('2. Activating expenses + reports for retail tenants...');
  const retailMod = await prisma.module.findUnique({ where: { code: 'retail' } });
  const expensesMod = await prisma.module.findUnique({ where: { code: 'expenses' } });
  const reportsMod = await prisma.module.findUnique({ where: { code: 'reports' } });

  if (retailMod && expensesMod && reportsMod) {
    const retailTenants = await prisma.tenantModule.findMany({
      where: { moduleId: retailMod.id, status: 'active' },
    });
    for (const tm of retailTenants) {
      for (const mod of [expensesMod, reportsMod]) {
        await prisma.tenantModule.upsert({
          where: { tenantId_moduleId: { tenantId: tm.tenantId, moduleId: mod.id } },
          update: { status: 'active' },
          create: { tenantId: tm.tenantId, moduleId: mod.id, status: 'active', activatedAt: new Date() },
        });
      }
      console.log(`   ✓ Tenant ${tm.tenantId} → expenses + reports activated`);
    }
  }

  // ── 4. Migrate pos tenant_modules → retail ────────────────────────────────
  console.log('4. Migrating pos tenant_modules → retail...');
  const posModule = await prisma.module.findUnique({ where: { code: 'pos' } });
  const retailModule = await prisma.module.findUnique({ where: { code: 'retail' } });

  if (posModule && retailModule) {
    const posTenantModules = await prisma.tenantModule.findMany({
      where: { moduleId: posModule.id },
    });
    console.log(`   Found ${posTenantModules.length} tenant(s) with pos module`);

    for (const tm of posTenantModules) {
      await prisma.tenantModule.upsert({
        where: { tenantId_moduleId: { tenantId: tm.tenantId, moduleId: retailModule.id } },
        update: { status: tm.status, activatedAt: tm.activatedAt },
        create: { tenantId: tm.tenantId, moduleId: retailModule.id, status: tm.status, activatedAt: tm.activatedAt },
      });
      console.log(`   ✓ Tenant ${tm.tenantId} migrated pos → retail`);
    }
  } else {
    console.log('   ↩ No pos module found in DB — skip migration');
  }

  // ── 5. Delete obsolete modules ────────────────────────────────────────────
  console.log('5. Removing obsolete modules...');
  for (const code of OBSOLETE_CODES) {
    const mod = await prisma.module.findUnique({ where: { code } });
    if (!mod) { console.log(`   ↩ ${code} not found`); continue; }

    // Delete tenant_modules first (FK constraint)
    const deleted = await prisma.tenantModule.deleteMany({ where: { moduleId: mod.id } });
    if (deleted.count > 0) console.log(`   ✓ Deleted ${deleted.count} tenant_modules for ${code}`);

    await prisma.module.delete({ where: { code } });
    console.log(`   ✓ Deleted module ${code}`);
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  const final = await prisma.module.findMany({ orderBy: [{ type: 'asc' }, { code: 'asc' }] });
  console.log('\n── Final modules ────────────────────────────────────');
  for (const m of final) {
    console.log(`  [${m.type.padEnd(8)}] ${m.code.padEnd(14)} ${m.name}`);
  }
  console.log('─────────────────────────────────────────────────────\n');
  console.log('✅ Done\n');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
