/**
 * fix-admin-memberships — réassigne les memberships retail de admin@scalario.com
 *
 * Problème : admin@scalario.com avait un membership retail avant la création du
 *            compte superadmin. Ce script crée un nouveau user Supabase pour chaque
 *            tenant retail et y réassigne le membership.
 *
 * Run : npm run fix:admin-memberships
 *
 * Ce script est idempotent.
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const supabase = createClient(
  process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321',
  process.env.SUPABASE_KEY ?? '',
);

const ADMIN_EMAIL = 'admin@scalario.com';
const PLATFORM_TENANT_NAME = 'Scalario Platform';

function toOwnerEmail(tenantName: string): string {
  const slug = tenantName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `owner@${slug}.local`;
}

async function main() {
  console.log('\n🔧 fix-admin-memberships\n');

  // ── 1. Find admin user in Supabase ────────────────────────────────────────
  const { data: listData, error: listError } =
    await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (listError) throw new Error(`listUsers failed: ${listError.message}`);

  const adminUser = listData.users.find((u) => u.email === ADMIN_EMAIL);
  if (!adminUser) {
    console.log(`✗ User ${ADMIN_EMAIL} not found in Supabase — nothing to do`);
    return;
  }
  const adminUserId = adminUser.id;
  console.log(`✓ Admin userId: ${adminUserId}`);

  // ── 2. Find the platform tenant ───────────────────────────────────────────
  const platformTenant = await prisma.tenant.findFirst({
    where: { name: PLATFORM_TENANT_NAME },
  });
  if (!platformTenant) {
    console.warn('⚠ Scalario Platform tenant not found — run seed:superadmin first');
    return;
  }
  console.log(`✓ Platform tenant: ${platformTenant.id}`);

  // ── 3. Find all non-platform memberships for admin user ───────────────────
  const members = await prisma.organizationMember.findMany({
    where: {
      userId: adminUserId,
      organizationId: { not: platformTenant.id },
    },
    include: { tenant: true },
  });

  if (members.length === 0) {
    console.log('✓ No retail memberships found — nothing to fix');
    return;
  }

  console.log(`\n📋 Found ${members.length} retail membership(s) to reassign:\n`);

  // ── 4. For each retail membership, create a new owner user ───────────────
  for (const member of members) {
    const tenantName = member.tenant.name;
    const newEmail = toOwnerEmail(tenantName);

    console.log(`  → Tenant: ${tenantName} (${member.organizationId})`);
    console.log(`    New owner email: ${newEmail}`);

    // Check if new user already exists
    const existing = listData.users.find((u) => u.email === newEmail);
    let newUserId: string;

    if (existing) {
      newUserId = existing.id;
      console.log(`    ↩ User already exists: ${newUserId}`);
    } else {
      const { data, error } = await supabase.auth.admin.createUser({
        email: newEmail,
        password: 'Scalario2026!',
        email_confirm: true,
      });
      if (error || !data.user) {
        throw new Error(`createUser failed for ${newEmail}: ${error?.message}`);
      }
      newUserId = data.user.id;
      console.log(`    ✓ Created user: ${newUserId}`);
    }

    // Check if new user already has membership in this tenant
    const existingNewMember = await prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId: member.organizationId,
          userId: newUserId,
        },
      },
    });

    if (existingNewMember) {
      console.log(`    ↩ New user already has membership — deleting admin's old one`);
      await prisma.organizationMember.delete({
        where: {
          organizationId_userId: {
            organizationId: member.organizationId,
            userId: adminUserId,
          },
        },
      });
    } else {
      // Reassign: update userId on existing membership
      await prisma.organizationMember.update({
        where: {
          organizationId_userId: {
            organizationId: member.organizationId,
            userId: adminUserId,
          },
        },
        data: { userId: newUserId },
      });
      console.log(`    ✓ Membership reassigned to ${newUserId}`);
    }

    console.log(`    ✓ Done — tenant "${tenantName}" now owned by ${newEmail}`);
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  console.log('\n── Summary ─────────────────────────────────────────');
  console.log(`  ${ADMIN_EMAIL} now has ONLY the superadmin membership`);
  for (const m of members) {
    const email = toOwnerEmail(m.tenant.name);
    console.log(`  ${m.tenant.name} → ${email} / Scalario2026!`);
  }
  console.log('────────────────────────────────────────────────────\n');
  console.log('✅ Hot-restart the app and connect with admin@scalario.com\n');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
