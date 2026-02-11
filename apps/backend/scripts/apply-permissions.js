const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const fs = require('fs');

async function main() {
    const sql = fs.readFileSync('scripts/fix-permissions.sql', 'utf8');
    console.log('Applying permissions...');
    // executeRawUnsafe only supports one statement at a time in some versions or drivers
    // So we split by semicolon
    const statements = sql.split(';').filter(s => s.trim() !== '');
    for (const statement of statements) {
        console.log(`Executing: ${statement.trim()}`);
        await prisma.$executeRawUnsafe(statement);
    }
    console.log('Permissions applied successfully.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
