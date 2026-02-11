const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- ALL AUTH USERS ---');
    const users = await prisma.$queryRawUnsafe('SELECT id, email FROM auth.users');
    console.log(JSON.stringify(users, null, 2));

    console.log('\n--- ALL ORGANIZATION MEMBERS ---');
    const members = await prisma.organizationMember.findMany();
    console.log(JSON.stringify(members, null, 2));
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
