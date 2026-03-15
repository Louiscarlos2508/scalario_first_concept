-- Migration: 20260315000000_rbac_roles_permissions
-- Story 1.2: Role-Based Access Control (RBAC)
-- Creates kernel.roles, kernel.permissions, kernel.role_permissions tables.
-- Converts organization_members.role (String) to role_id (UUID FK).

-- Step 1: Create kernel.roles table
CREATE TABLE kernel.roles (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name     TEXT NOT NULL,
  vertical TEXT NOT NULL,
  CONSTRAINT roles_name_vertical_unique UNIQUE (name, vertical)
);

-- Step 2: Create kernel.permissions table
CREATE TABLE kernel.permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT UNIQUE NOT NULL,
  module      TEXT NOT NULL,
  description TEXT NOT NULL
);

-- Step 3: Create kernel.role_permissions join table
CREATE TABLE kernel.role_permissions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id       UUID NOT NULL REFERENCES kernel.roles(id),
  permission_id UUID NOT NULL REFERENCES kernel.permissions(id),
  CONSTRAINT role_permissions_unique UNIQUE (role_id, permission_id)
);

-- Step 4: Seed MVP Retail roles (idempotent via ON CONFLICT DO NOTHING)
INSERT INTO kernel.roles (name, vertical) VALUES
  ('owner',            'retail'),
  ('manager',          'retail'),
  ('commercial',       'retail'),
  ('department_admin', 'retail'),
  ('employee',         'retail')
ON CONFLICT (name, vertical) DO NOTHING;

-- Step 5: Add role_id column (nullable first to allow data migration)
ALTER TABLE kernel.organization_members
  ADD COLUMN role_id UUID REFERENCES kernel.roles(id);

-- Step 6: Backfill role_id from existing string role values
UPDATE kernel.organization_members om
SET role_id = r.id
FROM kernel.roles r
WHERE r.name = om.role
  AND r.vertical = 'retail'
  AND om.role IS NOT NULL;

-- Step 7: Set NOT NULL on role_id (all existing rows must now have a valid FK)
ALTER TABLE kernel.organization_members
  ALTER COLUMN role_id SET NOT NULL;

-- Step 8: Drop the old string role column
ALTER TABLE kernel.organization_members
  DROP COLUMN role;
