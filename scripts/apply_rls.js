const { Client } = require('pg');

const connectionString = "postgresql://postgres:postgres@127.0.0.1:54322/postgres";

const sql = `
-- Create Products table count
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category TEXT,
  stock_quantity DECIMAL(10, 2) DEFAULT 0 NOT NULL,
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  total_amount DECIMAL(10, 2) NOT NULL,
  items_json JSONB NOT NULL,
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid errors on re-run
DROP POLICY IF EXISTS "Users can view organization products" ON products;
DROP POLICY IF EXISTS "Users can view organization orders" ON orders;
DROP POLICY IF EXISTS "Users can insert organization orders" ON orders;

-- Products: Users can view products of their organization
CREATE POLICY "Users can view organization products"
ON products FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);

-- Orders: Users can view and create orders for their organization
CREATE POLICY "Users can view organization orders"
ON orders FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);

CREATE POLICY "Users can insert organization orders"
ON orders FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM organization_members WHERE organization_id = tenant_id
  )
);
`;

async function applySQL() {
  const client = new Client({
    connectionString: connectionString,
  });

  try {
    await client.connect();
    console.log('Connected to PostgreSQL');
    await client.query(sql);
    console.log('Tables created and RLS policies applied successfully');
  } catch (err) {
    console.error('Error applying SQL:', err);
  } finally {
    await client.end();
  }
}

applySQL();
