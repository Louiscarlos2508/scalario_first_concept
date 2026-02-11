const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- RLS Policies ---');
    const policies = await prisma.$queryRawUnsafe("SELECT * FROM pg_policies WHERE tablename = 'organization_members'");
    console.log(JSON.stringify(policies, null, 2));

    console.log('\n--- Row Level Security Status ---');
    const status = await prisma.$queryRawUnsafe("SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'organization_members'");
    console.log(JSON.stringify(status, null, 2));
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
