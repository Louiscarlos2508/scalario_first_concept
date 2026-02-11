const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const members = await prisma.organizationMember.findMany();
    console.log('Current Org Members:', JSON.stringify(members, null, 2));
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
