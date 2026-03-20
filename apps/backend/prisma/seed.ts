import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import "dotenv/config";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

// PRD v5 RBAC Retail permission matrix
const PERMISSIONS = [
  { code: 'reports.view_all',          module: 'reporting',     description: 'Full dashboard & reports access' },
  { code: 'reports.view_location',     module: 'reporting',     description: 'Location-scoped reports access' },
  { code: 'catalog.edit',              module: 'catalog',       description: 'Add and modify catalog items' },
  { code: 'catalog.price_modify',      module: 'catalog',       description: 'Modify item prices (anti-fraud control)' },
  { code: 'supplier_orders.create',    module: 'catalog',       description: 'Create supplier purchase orders' },
  { code: 'users.manage',              module: 'kernel',        description: 'Create and assign user accounts' },
  { code: 'stock.receive_delivery',    module: 'inventory',     description: 'Receive supplier deliveries' },
  { code: 'stock.transfer_create',     module: 'inventory',     description: 'Create stock transfers between locations' },
  { code: 'losses.declare',            module: 'inventory',     description: 'Declare stock losses with reason' },
  { code: 'stock.transfer_confirm',    module: 'inventory',     description: 'Confirm reception of a stock transfer' },
  { code: 'session.open',              module: 'pos',           description: 'Open a POS cash session' },
  { code: 'session.close',             module: 'pos',           description: 'Close a POS cash session' },
  { code: 'sales.process',             module: 'pos',           description: 'Process sales transactions' },
];

// Role → permission codes mapping (PRD v5 Retail matrix)
const ROLE_PERMISSIONS: Record<string, string[]> = {
  owner: [
    'reports.view_all',
    'reports.view_location',
    'catalog.edit',
    'catalog.price_modify',
    'supplier_orders.create',
    'users.manage',
    'losses.declare',
  ],
  manager: [
    'reports.view_location',
    'stock.receive_delivery',
    'stock.transfer_create',
    'losses.declare',
  ],
  commercial: [
    'stock.transfer_confirm',
    'session.open',
    'session.close',
    'sales.process',
    'losses.declare',
  ],
  cashier: [
    'stock.transfer_confirm',
    'session.open',
    'session.close',
    'sales.process',
    'losses.declare',
  ],
  // Phase 3 reserved roles — zero permissions seeded intentionally
  department_admin: [],
  employee: [],
};

async function seedRbac() {
  console.log('Seeding RBAC permissions...');
  for (const perm of PERMISSIONS) {
    await prisma.permission.upsert({
      where: { code: perm.code },
      update: {},
      create: perm,
    });
  }
  console.log(`  ✓ ${PERMISSIONS.length} permissions seeded`);

  console.log('Seeding RBAC roles and role-permission links...');
  for (const [roleName, permCodes] of Object.entries(ROLE_PERMISSIONS)) {
    const role = await prisma.role.upsert({
      where: { name_vertical: { name: roleName, vertical: 'retail' } },
      update: {},
      create: { name: roleName, vertical: 'retail' },
    });

    for (const code of permCodes) {
      const permission = await prisma.permission.findUnique({ where: { code } });
      if (!permission) {
        console.warn(`  ⚠ Permission "${code}" not found — skipping`);
        continue;
      }
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: role.id, permissionId: permission.id } },
        update: {},
        create: { roleId: role.id, permissionId: permission.id },
      });
    }
    console.log(`  ✓ Role "${roleName}" seeded with ${permCodes.length} permissions`);
  }

  // Superadmin role — system vertical, no specific permissions (bypasses all guards)
  await prisma.role.upsert({
    where: { name_vertical: { name: 'superadmin', vertical: 'system' } },
    update: {},
    create: { name: 'superadmin', vertical: 'system' },
  });
  console.log('  ✓ Role "superadmin" (system) seeded');
}

const MODULES = [
  // Shared modules — core ERP capabilities
  { code: 'catalog',      name: 'Catalogue',    type: 'shared',   dependencies: [] },
  { code: 'contacts',     name: 'Contacts',     type: 'shared',   dependencies: [] },
  { code: 'inventory',    name: 'Inventaire',   type: 'shared',   dependencies: ['catalog'] },
  { code: 'transactions', name: 'Transactions', type: 'shared',   dependencies: ['catalog', 'contacts'] },
  { code: 'expenses',     name: 'Dépenses',     type: 'shared',   dependencies: [] },
  { code: 'reports',      name: 'Rapports',     type: 'shared',   dependencies: ['transactions'] },
  // Retail vertical — POS, sessions sont des sous-fonctionnalités de retail
  { code: 'retail',       name: 'Retail',       type: 'vertical', dependencies: ['catalog', 'inventory', 'transactions', 'contacts'] },
];

async function seedModules() {
  console.log('Seeding modules...');
  for (const mod of MODULES) {
    await prisma.module.upsert({
      where: { code: mod.code },
      update: { name: mod.name, type: mod.type, dependencies: mod.dependencies },
      create: mod,
    });
  }
  console.log(`  ✓ ${MODULES.length} modules seeded`);
}

const PLANS = [
  {
    code: 'free',
    name: 'Gratuit',
    monthlyPrice: 0,
    maxUsers: 1,
    includedModules: [] as string[],
    suggestedInstallationFee: null,
    suggestedTrainingFee: null,
  },
  {
    code: 'standard',
    name: 'Standard',
    monthlyPrice: 15000,
    maxUsers: 4,
    includedModules: ['catalog', 'inventory', 'retail'],
    suggestedInstallationFee: 25000,
    suggestedTrainingFee: 10000,
  },
  {
    code: 'premium',
    name: 'Premium',
    monthlyPrice: 30000,
    maxUsers: 10,
    includedModules: ['catalog', 'inventory', 'retail', 'reporting', 'purchase_orders'],
    suggestedInstallationFee: 50000,
    suggestedTrainingFee: 20000,
  },
  {
    code: 'enterprise',
    name: 'Enterprise',
    monthlyPrice: 50000,
    maxUsers: 25,
    includedModules: [
      'catalog', 'inventory', 'retail', 'reporting',
      'purchase_orders', 'variants', 'pricing', 'promotions',
    ],
    suggestedInstallationFee: 100000,
    suggestedTrainingFee: 50000,
  },
];

async function seedPlans() {
  console.log('Seeding plan definitions...');
  for (const plan of PLANS) {
    await (prisma as any).planDefinition.upsert({
      where: { code: plan.code },
      update: {
        name: plan.name,
        monthlyPrice: plan.monthlyPrice,
        maxUsers: plan.maxUsers,
        includedModules: plan.includedModules,
        suggestedInstallationFee: plan.suggestedInstallationFee,
        suggestedTrainingFee: plan.suggestedTrainingFee,
      },
      create: plan,
    });
  }
  console.log(`  ✓ ${PLANS.length} plan definitions seeded`);
}

async function main() {
  // Seed RBAC first (roles needed before member creation)
  await seedRbac();

  // Seed Module Registry (module catalog for feature gating)
  await seedModules();

  // Seed billing plan definitions
  await seedPlans();

  // Create a tenant for development
  let tenant = await prisma.tenant.findFirst();
  if (!tenant) {
    tenant = await prisma.tenant.create({
      data: { name: 'Test Store' },
    });
    console.log('Created tenant:', tenant.id);
  } else {
    console.log('Using existing tenant:', tenant.id);
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
