/**
 * Superadmin seed — crée le compte admin plateforme Scalario
 *
 * Run : npm run seed:superadmin
 *
 * Ce script est idempotent : il peut être relancé sans risque.
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

const ADMIN_EMAIL    = 'admin@scalario.com';
const ADMIN_PASSWORD = 'Scalario2026!';
const PLATFORM_TENANT_NAME = 'Scalario Platform';
async function main() {
  console.log('\n🚀 Seeding superadmin account...\n');

  // ── 1. Role superadmin ────────────────────────────────────────────────────
  console.log('1. Upserting role superadmin (platform)...');
  const role = await prisma.role.upsert({
    where: { name_vertical: { name: 'superadmin', vertical: 'platform' } },
    update: {},
    create: { name: 'superadmin', vertical: 'platform' },
  });
  console.log(`   ✓ Role id: ${role.id}`);

  // ── 2. Tenant "Scalario Platform" ─────────────────────────────────────────
  console.log('2. Upserting tenant "Scalario Platform"...');
  let tenant = await prisma.tenant.findFirst({
    where: { name: PLATFORM_TENANT_NAME },
  });
  if (!tenant) {
    tenant = await prisma.tenant.create({
      data: {
        name: PLATFORM_TENANT_NAME,
        currency: 'XOF',
        orgMode: 'standalone',
        status: 'active',
      },
    });
    console.log(`   ✓ Tenant created: ${tenant.id}`);
  } else {
    console.log(`   ↩ Tenant exists: ${tenant.id}`);
  }

  // ── 3. Supabase Auth user ─────────────────────────────────────────────────
  console.log(`3. Checking Supabase Auth for ${ADMIN_EMAIL}...`);
  let userId: string;

  const { data: listData, error: listError } =
    await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });

  if (listError) {
    throw new Error(`listUsers failed: ${listError.message}`);
  }

  const existingUser = listData.users.find((u) => u.email === ADMIN_EMAIL);

  if (existingUser) {
    userId = existingUser.id;
    await supabase.auth.admin.updateUserById(userId, { password: ADMIN_PASSWORD });
    console.log(`   ↩ User exists: ${userId} — password updated`);
  } else {
    const { data, error } = await supabase.auth.admin.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      email_confirm: true,
    });
    if (error || !data.user) {
      throw new Error(error?.message ?? 'createUser failed');
    }
    userId = data.user.id;
    console.log(`   ✓ User created: ${userId}`);
  }

  // ── 4. OrganizationMember ─────────────────────────────────────────────────
  console.log('4. Upserting OrganizationMember (userId → tenant, role superadmin)...');
  const existing = await prisma.organizationMember.findFirst({
    where: { userId, organizationId: tenant.id },
  });
  if (!existing) {
    await prisma.organizationMember.create({
      data: {
        organizationId: tenant.id,
        userId,
        roleId: role.id,
      },
    });
    console.log('   ✓ Member created');
  } else {
    console.log(`   ↩ Member exists: ${existing.id}`);
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  console.log('\n── Summary ──────────────────────────────────────────');
  console.log(`  tenant:   ${tenant.name} (${tenant.id})`);
  console.log(`  userId:   ${userId}`);
  console.log(`  email:    ${ADMIN_EMAIL}`);
  console.log(`  password: ${ADMIN_PASSWORD}`);
  console.log('─────────────────────────────────────────────────────');
  console.log('\n✅ Done — connecte-toi avec admin@scalario.com / Scalario2026!\n');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
