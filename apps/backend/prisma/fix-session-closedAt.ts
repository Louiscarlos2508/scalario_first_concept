/**
 * fix-session-closedAt.ts
 *
 * 1. Patch les sessions existantes sans closedAt (status != OPEN) → closedAt = openedAt + 8h
 * 2. Injecte des sessions de test clôturées sur les 14 derniers jours pour valider l'historique
 *
 * Run : npx ts-node -r tsconfig-paths/register prisma/fix-session-closedAt.ts
 */
import { PrismaClient, Prisma } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const TENANT_ID = 'd0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a';

// Users membres du tenant
const USER_CASHIER  = '055a6f5a-7e42-455d-8cea-9b88e0077407'; // cashier / commercial
const USER_MANAGER  = 'dddbc221-d30c-4ad1-9fc3-478e66b4017e'; // manager
const USER_OWNER    = '69186408-7f9c-4720-a6ee-fdec622887f8'; // owner

function daysAgo(n: number, hour = 8, minute = 0): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(hour, minute, 0, 0);
  return d;
}

const TEST_SESSIONS: Array<{
  userId: string;
  deviceId: string;
  openedAt: Date;
  closedAt: Date;
  openingBalance: number;
  closingBalance: number;
  status: string;
  managerId?: string;
  managerValidatedAt?: Date;
  ownerSignedAt?: Date;
}> = [
  // ── Cette semaine ────────────────────────────────────────────────────────────
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(1, 8, 30),
    closedAt: daysAgo(1, 19, 45),
    openingBalance: 25000,
    closingBalance: 112300,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(1, 20, 10),
    ownerSignedAt: daysAgo(1, 20, 30),
  },
  {
    userId: USER_MANAGER,
    deviceId: 'Terminal-2',
    openedAt: daysAgo(1, 10, 0),
    closedAt: daysAgo(1, 17, 30),
    openingBalance: 15000,
    closingBalance: 76400,
    status: 'PENDING_OWNER',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(1, 18, 0),
  },
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(2, 8, 0),
    closedAt: daysAgo(2, 19, 0),
    openingBalance: 25000,
    closingBalance: 98750,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(2, 19, 30),
    ownerSignedAt: daysAgo(2, 20, 0),
  },
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(3, 8, 15),
    closedAt: daysAgo(3, 18, 45),
    openingBalance: 20000,
    closingBalance: 54200,
    status: 'PENDING_MANAGER',
  },
  {
    userId: USER_MANAGER,
    deviceId: 'Terminal-2',
    openedAt: daysAgo(4, 9, 0),
    closedAt: daysAgo(4, 16, 30),
    openingBalance: 15000,
    closingBalance: 41800,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(4, 17, 0),
    ownerSignedAt: daysAgo(4, 17, 15),
  },
  // ── Semaine dernière ──────────────────────────────────────────────────────────
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(8, 8, 30),
    closedAt: daysAgo(8, 19, 30),
    openingBalance: 25000,
    closingBalance: 91400,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(8, 20, 0),
    ownerSignedAt: daysAgo(8, 20, 15),
  },
  {
    userId: USER_MANAGER,
    deviceId: 'Terminal-2',
    openedAt: daysAgo(8, 10, 30),
    closedAt: daysAgo(8, 18, 0),
    openingBalance: 15000,
    closingBalance: 58600,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(8, 18, 30),
    ownerSignedAt: daysAgo(8, 19, 0),
  },
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(10, 8, 0),
    closedAt: daysAgo(10, 20, 0),
    openingBalance: 25000,
    closingBalance: 134500,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(10, 20, 30),
    ownerSignedAt: daysAgo(10, 21, 0),
  },
  {
    userId: USER_MANAGER,
    deviceId: 'Terminal-2',
    openedAt: daysAgo(11, 9, 0),
    closedAt: daysAgo(11, 16, 45),
    openingBalance: 15000,
    closingBalance: 76200,
    status: 'PENDING_MANAGER',
  },
  // ── Ce mois, plus ancien ──────────────────────────────────────────────────────
  {
    userId: USER_CASHIER,
    deviceId: 'Terminal-1',
    openedAt: daysAgo(14, 8, 30),
    closedAt: daysAgo(14, 19, 0),
    openingBalance: 25000,
    closingBalance: 88300,
    status: 'CLOSED',
    managerId: USER_MANAGER,
    managerValidatedAt: daysAgo(14, 19, 30),
    ownerSignedAt: daysAgo(14, 20, 0),
  },
];

async function main() {
  console.log('── Step 1 : patch sessions sans closedAt ────────────────────────');
  const orphans = await prisma.posSession.findMany({
    where: { closedAt: null, status: { not: 'OPEN' } },
    select: { id: true, openedAt: true, status: true },
  });

  if (orphans.length === 0) {
    console.log('  Aucune session orpheline trouvée.');
  } else {
    for (const s of orphans) {
      const closedAt = new Date(s.openedAt.getTime() + 8 * 60 * 60 * 1000);
      await prisma.posSession.update({
        where: { id: s.id },
        data: { closedAt },
      });
      console.log(`  Patched ${s.id} (${s.status}) → closedAt = ${closedAt.toISOString()}`);
    }
  }

  console.log('\n── Step 2 : injection des sessions de test ──────────────────────');
  let created = 0;
  for (const s of TEST_SESSIONS) {
    const variance = new Prisma.Decimal(s.closingBalance - s.openingBalance);
    const session = await prisma.posSession.create({
      data: {
        tenantId:            TENANT_ID,
        userId:              s.userId,
        deviceId:            s.deviceId,
        openedAt:            s.openedAt,
        closedAt:            s.closedAt,
        openingBalance:      new Prisma.Decimal(s.openingBalance),
        closingBalance:      new Prisma.Decimal(s.closingBalance),
        theoreticalBalance:  new Prisma.Decimal(s.closingBalance),
        variance,
        varianceExplanation: variance.toNumber() === 0 ? null : 'Écart constaté en fermeture',
        status:              s.status,
        managerId:           s.managerId ?? null,
        managerValidatedAt:  s.managerValidatedAt ?? null,
        ownerSignedAt:       s.ownerSignedAt ?? null,
      },
    });
    console.log(`  Created ${session.id} | ${s.deviceId} | ${s.status} | ${s.openedAt.toLocaleDateString('fr-FR')}`);
    created++;
  }

  console.log(`\n✓ ${created} sessions injectées. Relance le backend et vérifie l'historique.`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await pool.end(); });
