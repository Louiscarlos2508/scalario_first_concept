const { Client } = require('pg');

const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@127.0.0.1:54322/postgres'
});

const sql = `
-- 1. Create pos_sessions table
CREATE TABLE IF NOT EXISTS pos_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  opening_balance DECIMAL(10, 2) NOT NULL,
  closing_balance DECIMAL(10, 2),
  status TEXT NOT NULL DEFAULT 'OPEN',
  user_id UUID NOT NULL,
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  opened_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  closed_at TIMESTAMPTZ
);

-- 2. Update orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES pos_sessions(id);

-- 3. Enable RLS
ALTER TABLE pos_sessions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for pos_sessions
DROP POLICY IF EXISTS "Users can view organization sessions" ON pos_sessions;
DROP POLICY IF EXISTS "Users can insert organization sessions" ON pos_sessions;
DROP POLICY IF EXISTS "Users can update organization sessions" ON pos_sessions;

CREATE POLICY "Users can view organization sessions"
ON pos_sessions FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);

CREATE POLICY "Users can insert organization sessions"
ON pos_sessions FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);

CREATE POLICY "Users can update organization sessions"
ON pos_sessions FOR UPDATE
USING (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);
`;

async function apply() {
    try {
        await client.connect();
        console.log('Connected to database');
        await client.query(sql);
        console.log('Schema updates and RLS applied successfully');
    } catch (err) {
        console.error('Error applying schema updates:', err);
    } finally {
        await client.end();
    }
}

apply();
