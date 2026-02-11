const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Setting all organization members to role: admin...');
    const result = await prisma.organizationMember.updateMany({
        data: { role: 'admin' },
    });
    console.log(`Successfully updated ${result.count} users.`);

    const all = await prisma.organizationMember.findMany();
    console.log('Current Database State:', JSON.stringify(all, null, 2));
}

main()
    .catch((e) => {
        console.error('Error updating roles:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
