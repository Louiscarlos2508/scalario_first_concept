const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const tenantId = 'd0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a';

    console.log(`Linking all users to tenant ${tenantId}...`);

    // Link all users from auth.users to the organization_members table
    // We use raw SQL because we excluded 'auth' from the Prisma schema
    const result = await prisma.$executeRawUnsafe(`
    INSERT INTO organization_members (id, organization_id, user_id, role, created_at)
    SELECT gen_random_uuid(), '${tenantId}', id, 'cashier', now()
    FROM auth.users
    ON CONFLICT (organization_id, user_id) DO NOTHING;
  `);

    console.log(`Updated ${result} rows.`);

    const members = await prisma.organizationMember.findMany();
    console.log('Current members:', members);
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
