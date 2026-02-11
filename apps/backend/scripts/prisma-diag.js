const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- Organization Members ---');
    const members = await prisma.organizationMember.findMany();
    console.log(JSON.stringify(members, null, 2));

    console.log('\n--- Tenants ---');
    const tenants = await prisma.tenant.findMany();
    console.log(JSON.stringify(tenants, null, 2));
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
