import { DataSource } from 'typeorm';
import { randomUUID } from 'node:crypto';

/**
 * STORY-017 — RLS intrusion tests.
 *
 * These tests need TWO real PostgreSQL roles (`scalario_admin` to seed
 * fixtures, `scalario_app` to issue the queries Layer 5 must filter), so
 * they're skipped unless the CI environment provides:
 *
 *   - DATABASE_URL_ADMIN  — superuser, used to seed.
 *   - DATABASE_URL        — scalario_app (NOBYPASSRLS), used to assert.
 *
 * Locally you can run them with:
 *   DATABASE_URL_ADMIN=postgres://scalario:...@localhost:5432/scalario_test \
 *   DATABASE_URL=postgres://scalario_app:...@localhost:5432/scalario_test \
 *   pnpm --filter @scalario/nestjs test rls-intrusion
 *
 * In `pnpm test` without those vars, the suite is skipped so unit tests
 * stay fast and DB-free.
 */

const ADMIN_URL = process.env.DATABASE_URL_ADMIN;
const APP_URL = process.env.DATABASE_URL;
const RLS_E2E_ENABLED = !!ADMIN_URL && !!APP_URL && ADMIN_URL !== APP_URL;

const d = RLS_E2E_ENABLED ? describe : describe.skip;

d('RLS — intrusion (Layer 5)', () => {
  let adminDS: DataSource;
  let appDS: DataSource;
  let tenantA: string;
  let tenantB: string;

  beforeAll(async () => {
    adminDS = new DataSource({ type: 'postgres', url: ADMIN_URL });
    await adminDS.initialize();
    appDS = new DataSource({ type: 'postgres', url: APP_URL, extra: { max: 2 } });
    await appDS.initialize();

    // Seed: two tenants + 5 users each. Bypass RLS via admin role.
    tenantA = randomUUID();
    tenantB = randomUUID();
    await adminDS.query(
      `INSERT INTO tenants (id, name, slug) VALUES ($1, 'Acme A', $2), ($3, 'Acme B', $4)
       ON CONFLICT (id) DO NOTHING`,
      [tenantA, `rls-a-${tenantA.slice(0, 6)}`, tenantB, `rls-b-${tenantB.slice(0, 6)}`],
    );
    for (let i = 0; i < 5; i++) {
      await adminDS.query(
        `INSERT INTO users (tenant_id, email, password_hash) VALUES ($1, $2, 'x'), ($3, $4, 'x')`,
        [tenantA, `a${i}-${randomUUID()}@x.test`, tenantB, `b${i}-${randomUUID()}@x.test`],
      );
    }
  });

  afterAll(async () => {
    if (adminDS?.isInitialized) {
      await adminDS.query(`DELETE FROM users WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
      await adminDS.query(`DELETE FROM tenants WHERE id IN ($1, $2)`, [tenantA, tenantB]);
      await adminDS.destroy();
    }
    if (appDS?.isInitialized) await appDS.destroy();
  });

  it('AC-11/T1 — returns 0 rows when app.current_tenant_id is unset (fail-closed)', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await qr.query(`RESET app.current_tenant_id`).catch(() => undefined);
      const rows = await qr.query(
        `SELECT count(*)::int AS c FROM users WHERE tenant_id IN ($1, $2)`,
        [tenantA, tenantB],
      );
      expect(rows[0].c).toBe(0);
    } finally {
      await qr.release();
    }
  });

  it('AC-11/T2 — returns only tenant-A rows when app.current_tenant_id = A', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await qr.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [tenantA]);
      const rows = await qr.query(
        `SELECT count(*)::int AS c FROM users WHERE tenant_id IN ($1, $2)`,
        [tenantA, tenantB],
      );
      expect(rows[0].c).toBe(5);
    } finally {
      await qr.query(`RESET app.current_tenant_id`).catch(() => undefined);
      await qr.release();
    }
  });

  it('AC-11/T3 — switches cleanly to tenant-B mid-session', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await qr.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [tenantA]);
      let rows = await qr.query(
        `SELECT count(*)::int AS c FROM users WHERE tenant_id IN ($1, $2)`,
        [tenantA, tenantB],
      );
      expect(rows[0].c).toBe(5);

      await qr.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [tenantB]);
      rows = await qr.query(`SELECT count(*)::int AS c FROM users WHERE tenant_id IN ($1, $2)`, [
        tenantA,
        tenantB,
      ]);
      expect(rows[0].c).toBe(5);
    } finally {
      await qr.query(`RESET app.current_tenant_id`).catch(() => undefined);
      await qr.release();
    }
  });

  it('AC-11/T4 — random tenant_id reveals no rows', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await qr.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [randomUUID()]);
      const rows = await qr.query(`SELECT count(*)::int AS c FROM users`);
      expect(rows[0].c).toBe(0);
    } finally {
      await qr.release();
    }
  });

  it('AC-11/T5 — scalario_app cannot turn RLS off', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await expect(qr.query(`SET row_security = OFF`)).rejects.toThrow(
        /permission denied|insufficient privilege/i,
      );
    } finally {
      await qr.release();
    }
  });

  it('AC-11/T6 — scalario_app cannot ALTER table to disable RLS', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await expect(qr.query(`ALTER TABLE users DISABLE ROW LEVEL SECURITY`)).rejects.toThrow(
        /must be owner|permission denied/i,
      );
    } finally {
      await qr.release();
    }
  });

  it('AC-12 — WITH CHECK rejects cross-tenant INSERT', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    try {
      await qr.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [tenantA]);
      await expect(
        qr.query(`INSERT INTO users (tenant_id, email, password_hash) VALUES ($1, $2, 'x')`, [
          tenantB,
          `attacker-${randomUUID()}@x.test`,
        ]),
      ).rejects.toThrow(/row-level security/i);
    } finally {
      await qr.query(`RESET app.current_tenant_id`).catch(() => undefined);
      await qr.release();
    }
  });
});
