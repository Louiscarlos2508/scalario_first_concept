/**
 * fix-rename-contacts-to-clients — renomme le module 'contacts' en 'clients'
 *
 * - Upsert le module 'clients' (code, name, type, dependencies)
 * - Migre les tenant_modules : contacts → clients (sans perte de statut)
 * - Supprime l'ancien module 'contacts'
 * - Met à jour les dépendances des modules qui référençaient 'contacts'
 *
 * Run : npm run fix:rename-contacts
 * Idempotent.
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

// Modules whose dependencies array references 'contacts' → must be updated to 'clients'
const MODULES_WITH_CONTACTS_DEP = [
  { code: 'transactions',    newDeps: ['catalog', 'clients'] },
  { code: 'purchase_orders', newDeps: ['catalog', 'clients', 'inventory'] },
  { code: 'client_orders',   newDeps: ['catalog', 'clients', 'transactions'] },
  { code: 'retail',          newDeps: ['catalog', 'inventory', 'transactions', 'clients'] },
];

async function main() {
  console.log('\n fix-rename-contacts-to-clients\n');

  // 1. Upsert module 'clients'
  console.log('1. Upserting module "clients"...');
  await prisma.module.upsert({
    where: { code: 'clients' },
    update: { name: 'Clients', type: 'shared', dependencies: [] },
    create: { code: 'clients', name: 'Clients', type: 'shared', dependencies: [] },
  });
  console.log('   clients upserted');

  // 2. Migrate tenant_modules: contacts → clients
  console.log('2. Migrating tenant_modules contacts → clients...');
  const contactsMod = await prisma.module.findUnique({ where: { code: 'contacts' } });
  const clientsMod  = await prisma.module.findUnique({ where: { code: 'clients' } });

  if (contactsMod && clientsMod) {
    const contactsTenantModules = await prisma.tenantModule.findMany({
      where: { moduleId: contactsMod.id },
    });
    console.log(`   Found ${contactsTenantModules.length} tenant(s) with contacts module`);

    for (const tm of contactsTenantModules) {
      await prisma.tenantModule.upsert({
        where: { tenantId_moduleId: { tenantId: tm.tenantId, moduleId: clientsMod.id } },
        update: { status: tm.status, activatedAt: tm.activatedAt },
        create: { tenantId: tm.tenantId, moduleId: clientsMod.id, status: tm.status, activatedAt: tm.activatedAt },
      });
      console.log(`   Tenant ${tm.tenantId}: contacts → clients`);
    }

    // Delete old contacts tenant_modules
    const deleted = await prisma.tenantModule.deleteMany({ where: { moduleId: contactsMod.id } });
    if (deleted.count > 0) console.log(`   Deleted ${deleted.count} old contacts tenant_module(s)`);

    // Delete old contacts module
    await prisma.module.delete({ where: { code: 'contacts' } });
    console.log('   Deleted module "contacts"');
  } else if (!contactsMod) {
    console.log('   Module "contacts" not found — already renamed or never existed');
  }

  // 3. Update dependencies arrays on affected modules
  console.log('3. Updating dependencies on affected modules...');
  for (const { code, newDeps } of MODULES_WITH_CONTACTS_DEP) {
    const mod = await prisma.module.findUnique({ where: { code } });
    if (!mod) { console.log(`   Module "${code}" not found — skip`); continue; }
    await prisma.module.update({ where: { code }, data: { dependencies: newDeps } });
    console.log(`   ${code} dependencies updated`);
  }

  // 4. Summary
  const final = await prisma.module.findMany({ orderBy: [{ type: 'asc' }, { code: 'asc' }] });
  console.log('\n── Final modules ────────────────────────────────────');
  for (const m of final) {
    console.log(`  [${m.type.padEnd(8)}] ${m.code.padEnd(20)} ${m.name}`);
  }
  console.log('─────────────────────────────────────────────────────\n');
  console.log('Done\n');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
