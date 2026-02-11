-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Tenants Table (Organizations)
create table tenants (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Organization Members (Link Auth Users to Tenants)
create table organization_members (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid references tenants(id) not null,
  user_id uuid references auth.users(id) not null,
  role text not null check (role in ('owner', 'admin', 'manager', 'cashier')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(organization_id, user_id)
);

-- SECURITY DEFINER function to bypass RLS recursion on OTHER tables
CREATE OR REPLACE FUNCTION public.is_member_of(org_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Organization Members: Users can always view THEIR OWN membership row (Non-recursive)
DROP POLICY IF EXISTS "Users can view organization members" ON organization_members;
CREATE POLICY "Users can view own membership"
ON organization_members FOR SELECT
USING (auth.uid() = user_id);

-- Tenants: Users can see tenants they are members of (uses function safely)
DROP POLICY IF EXISTS "Users can view their own tenants" ON tenants;
CREATE POLICY "Users can view their own tenants"
ON tenants FOR SELECT
USING (is_member_of(id));
