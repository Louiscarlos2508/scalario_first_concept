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
  // Retail vertical — POS, sessions sont des sous-fonctionnalités de retail
  { code: 'retail',            name: 'Point de Vente (POS)',     type: 'vertical', dependencies: ['catalog', 'inventory', 'transactions', 'clients'] },
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

// No "free" plan — billingStatus:'trial' gives STANDARD access for 30 days
const PLANS = [
  {
    code: 'standard',
    name: 'Standard',
    monthlyPrice: 15000,
    maxUsers: 3,
    includedModules: ['catalog', 'clients', 'inventory', 'transactions', 'expenses', 'reports', 'retail'],
    suggestedInstallationFee: 25000,
    suggestedTrainingFee: 10000,
  },
  {
    code: 'premium',
    name: 'Premium',
    monthlyPrice: 25000,
    maxUsers: 999,
    includedModules: [
      'catalog', 'clients', 'inventory', 'transactions', 'expenses', 'reports',
      'variants', 'pricing', 'promotions', 'purchase_orders', 'internal_requests',
      'batches', 'client_orders', 'retail',
    ],
    suggestedInstallationFee: 50000,
    suggestedTrainingFee: 20000,
  },
  {
    // Enterprise: Carlos activates modules manually per contract
    code: 'enterprise',
    name: 'Enterprise',
    monthlyPrice: 0,
    maxUsers: 999,
    includedModules: [] as string[],
    suggestedInstallationFee: null,
    suggestedTrainingFee: null,
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

  // Remove obsolete 'free' plan if it still exists
  const removed = await (prisma as any).planDefinition.deleteMany({
    where: { code: { notIn: PLANS.map((p) => p.code) } },
  });
  if (removed.count > 0) {
    console.log(`  ✓ Removed ${removed.count} obsolete plan(s) (e.g. "free")`);
  }
}

// ── Retail business types — Phase 2a ─────────────────────────────────────────
// Exactly 14 types. vertical: "retail" on all.
// Non-retail verticals (artisan, restaurant, services) are Phase 3+.
const BUSINESS_TYPES = [
  {
    code: 'generaliste',
    name: 'Généraliste',
    description: 'Commerce de détail généraliste, vente de tout type de produit physique',
    defaultFlags: {},
    visibleSections: [] as string[],
    suggestedCategories: ['Alimentation', 'Électronique', 'Habillement', 'Maison', 'Loisirs'] as string[],
    documentType: 'receipt',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'expenses'], commercial: ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'store',
    vertical: 'retail',
  },
  {
    code: 'epicerie',
    name: 'Épicerie & Alimentation',
    description: 'Vente de produits alimentaires, gestion des dates d\'expiration et de la fraîcheur',
    defaultFlags: { expiryDays: 30 },
    visibleSections: ['expiry'] as string[],
    suggestedCategories: ['Fruits & Légumes', 'Épices', 'Céréales', 'Boissons', 'Produits laitiers', 'Conserves'] as string[],
    documentType: 'receipt',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice'], manager: ['backoffice_restricted', 'expenses'], commercial: ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'local_grocery_store',
    vertical: 'retail',
  },
  {
    code: 'telephonie',
    name: 'Téléphonie & Accessoires',
    description: 'Vente de téléphones, accessoires et cartes SIM avec suivi IMEI et garantie',
    defaultFlags: { hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 },
    visibleSections: ['variants', 'serial', 'warranty'] as string[],
    suggestedCategories: ['Smartphones', 'Accessoires', 'Cartes SIM', 'Recharge', 'Réparation'] as string[],
    documentType: 'receipt',
    roleLabels: { commercial: 'Vendeur', manager: 'Responsable boutique', cashier: 'Caissier' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted'], commercial: ['pos', 'daily_sales'], cashier: ['pos'] },
    icon: 'phone_android',
    vertical: 'retail',
  },
  {
    code: 'textile',
    name: 'Textile & Prêt-à-porter',
    description: 'Vente de vêtements et tissus avec variantes taille/couleur',
    defaultFlags: { hasVariants: true },
    visibleSections: ['variants'] as string[],
    suggestedCategories: ['Hauts', 'Bas', 'Robes', 'Chaussures', 'Accessoires', 'Tissu'] as string[],
    documentType: 'receipt',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'stock_view'], commercial: ['pos', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'checkroom',
    vertical: 'retail',
  },
  {
    code: 'pharmacie',
    name: 'Pharmacie & Parapharmacie',
    description: 'Vente de médicaments et produits parapharmaceutiques avec gestion ordonnances et lots',
    defaultFlags: { expiryDays: 365, requiresPrescription: false },
    visibleSections: ['expiry', 'prescription'] as string[],
    suggestedCategories: ['Médicaments', 'Parapharmacie', 'Matériel médical', 'Vitamines'] as string[],
    documentType: 'receipt',
    roleLabels: { commercial: 'Préparateur', manager: 'Pharmacien gérant' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'clients_view'], commercial: ['pos', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'local_pharmacy',
    vertical: 'retail',
  },
  {
    code: 'quincaillerie',
    name: 'Quincaillerie & Matériaux',
    description: 'Vente de matériaux de construction, outillage et quincaillerie avec vente au poids',
    defaultFlags: { hasVariants: true, unitType: 'weight' },
    visibleSections: ['variants', 'weight'] as string[],
    suggestedCategories: ['Peinture', 'Plomberie', 'Électricité', 'Outillage', 'Ciment', 'Fer'] as string[],
    documentType: 'delivery_note',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'stock_view', 'expenses'], commercial: ['pos', 'losses', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'hardware',
    vertical: 'retail',
  },
  {
    code: 'electromenager',
    name: 'Électroménager & Appareils',
    description: 'Vente d\'appareils électroménagers et électroniques avec numéro de série et garantie',
    defaultFlags: { trackSerialNumbers: true, warrantyMonths: 12, hasVariants: true },
    visibleSections: ['serial', 'warranty', 'variants'] as string[],
    suggestedCategories: ['Réfrigérateurs', 'Téléviseurs', 'Climatiseurs', 'Cuisinières', 'Petits appareils'] as string[],
    documentType: 'invoice',
    roleLabels: { commercial: 'Vendeur', manager: 'Responsable technique' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted'], commercial: ['pos', 'daily_sales'], cashier: ['pos'] },
    icon: 'kitchen',
    vertical: 'retail',
  },
  {
    code: 'cave_vin',
    name: 'Cave à Vin & Boissons',
    description: 'Vente de vins, champagnes et spiritueux avec millésime et gestion de cave',
    defaultFlags: { hasVariants: true },
    visibleSections: ['variants'] as string[],
    suggestedCategories: ['Vins rouges', 'Vins blancs', 'Rosés', 'Champagnes', 'Spiritueux', 'Bières artisanales'] as string[],
    documentType: 'receipt',
    roleLabels: { commercial: 'Caviste', manager: 'Gérant cave' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'stock_view'], commercial: ['pos', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'wine_bar',
    vertical: 'retail',
  },
  {
    code: 'bijouterie',
    name: 'Bijouterie & Joaillerie',
    description: 'Vente de bijoux, or au gramme et articles de joaillerie avec prix dynamique',
    defaultFlags: { hasVariants: true, dynamicPricing: true },
    visibleSections: ['variants', 'dynamic_pricing'] as string[],
    suggestedCategories: ['Or', 'Argent', 'Bagues', 'Colliers', 'Bracelets', 'Montres'] as string[],
    documentType: 'receipt',
    roleLabels: { commercial: 'Joaillier', manager: 'Responsable bijouterie' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted'], commercial: ['pos', 'daily_sales'], cashier: ['pos'] },
    icon: 'diamond',
    vertical: 'retail',
  },
  {
    code: 'depot_vente',
    name: 'Dépôt-Vente & Occasion',
    description: 'Vente d\'articles uniques d\'occasion déposés par des tiers',
    defaultFlags: { uniqueArticles: true },
    visibleSections: ['unique'] as string[],
    suggestedCategories: ['Vêtements occasion', 'Électronique occasion', 'Meubles', 'Livres', 'Montres occasion'] as string[],
    documentType: 'receipt',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted'], commercial: ['pos', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'recycling',
    vertical: 'retail',
  },
  {
    code: 'boulangerie',
    name: 'Boulangerie & Pâtisserie',
    description: 'Vente de pain, viennoiseries et pâtisseries avec gestion fraîcheur quotidienne',
    defaultFlags: { expiryDays: 3 },
    visibleSections: ['expiry'] as string[],
    suggestedCategories: ['Pain', 'Viennoiseries', 'Gâteaux', 'Sandwichs', 'Boissons'] as string[],
    documentType: 'receipt',
    roleLabels: {},
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'expenses'], commercial: ['pos', 'losses', 'daily_sales'], cashier: ['pos'] },
    icon: 'bakery_dining',
    vertical: 'retail',
  },
  {
    code: 'station_service',
    name: 'Station Service',
    description: 'Vente de carburant au litre et produits pétroliers avec compteur pompe',
    defaultFlags: { unitType: 'volume' },
    visibleSections: ['weight'] as string[],
    suggestedCategories: ['Essence', 'Diesel', 'Huiles moteur', 'Lubrifiants', 'Accessoires auto'] as string[],
    documentType: 'receipt',
    roleLabels: { commercial: 'Pompiste', manager: 'Chef de station' },
    roleScreenAccess: { owner: ['backoffice'], manager: ['backoffice_restricted', 'stock_view', 'expenses'], commercial: ['pos', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'local_gas_station',
    vertical: 'retail',
  },
  {
    code: 'grossiste',
    name: 'Commerce de Gros',
    description: 'Vente en gros avec multi-tarifs selon le volume et la fidélité client',
    defaultFlags: { hasVariants: true, unitType: 'weight' },
    visibleSections: ['variants', 'weight'] as string[],
    suggestedCategories: ['Alimentaire', 'Cosmétique', 'Textile', 'Quincaillerie', 'Électronique'] as string[],
    documentType: 'delivery_note',
    roleLabels: { commercial: 'Commercial', manager: 'Responsable dépôt', cashier: 'Opérateur' },
    roleScreenAccess: { owner: ['backoffice'], manager: ['backoffice_restricted', 'clients_view', 'expenses'], commercial: ['pos', 'client_orders', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'warehouse',
    vertical: 'retail',
  },
  {
    code: 'distribution',
    name: 'Commerce de Distribution',
    description: 'Vente en gros avec livraison clients et bons de livraison',
    defaultFlags: { hasVariants: true },
    visibleSections: ['variants'] as string[],
    suggestedCategories: ['Alimentaire', 'Boissons', 'Hygiène', 'Nettoyage', 'Épicerie fine'] as string[],
    documentType: 'delivery_note',
    roleLabels: { commercial: 'Commercial terrain', manager: 'Directeur dépôt', cashier: 'Opérateur' },
    roleScreenAccess: { owner: ['backoffice'], manager: ['backoffice_restricted', 'stock_view', 'expenses'], commercial: ['pos', 'client_orders', 'deliveries', 'stock_view', 'daily_sales'], cashier: ['pos'] },
    icon: 'local_shipping',
    vertical: 'retail',
  },
  {
    code: 'cafe_restaurant',
    name: 'Café & Restauration Rapide',
    description: 'Vente de plats préparés, boissons, snacks au comptoir',
    defaultFlags: { expiryDays: 1, unitType: 'piece' },
    visibleSections: ['expiry', 'freshness'] as string[],
    suggestedCategories: ['Plats du jour', 'Sandwichs', 'Boissons chaudes', 'Boissons fraîches', 'Snacks', 'Desserts'] as string[],
    documentType: 'receipt',
    roleLabels: { owner: 'Gérant', manager: 'Chef cuisinier', commercial: 'Serveur', cashier: 'Caissier' },
    roleScreenAccess: { owner: ['backoffice', 'pos'], manager: ['backoffice_restricted', 'expenses'], commercial: ['pos', 'losses', 'daily_sales'], cashier: ['pos'] },
    icon: 'restaurant',
    vertical: 'retail',
  },
];

async function seedBusinessTypes() {
  console.log('Seeding business type definitions...');
  for (const bt of BUSINESS_TYPES) {
    const data = {
      name: bt.name,
      description: bt.description,
      defaultFlags: bt.defaultFlags,
      visibleSections: bt.visibleSections,
      suggestedCategories: bt.suggestedCategories,
      documentType: bt.documentType,
      roleLabels: bt.roleLabels,
      roleScreenAccess: bt.roleScreenAccess,
      icon: bt.icon,
      vertical: bt.vertical,
      isActive: true,
    };
    await (prisma as any).businessTypeDefinition.upsert({
      where: { code: bt.code },
      update: data,
      create: { code: bt.code, ...data },
    });
  }
  console.log(`  ✓ ${BUSINESS_TYPES.length} business type definitions seeded`);

  // Remove types that are no longer in the retail list (non-retail verticals removed)
  const validCodes = BUSINESS_TYPES.map((bt) => bt.code);
  const removed = await (prisma as any).businessTypeDefinition.deleteMany({
    where: { code: { notIn: validCodes } },
  });
  if (removed.count > 0) {
    console.log(`  ✓ Removed ${removed.count} non-retail business type(s)`);
  }
}

async function main() {
  // Seed RBAC first (roles needed before member creation)
  await seedRbac();

  // Seed Module Registry (module catalog for feature gating)
  await seedModules();

  // Seed billing plan definitions
  await seedPlans();

  // Seed business type definitions
  await seedBusinessTypes();

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
