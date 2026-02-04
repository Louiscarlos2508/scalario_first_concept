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

-- RLS Policies

-- Tenants: Users can see tenants they are members of
alter table tenants enable row level security;

create policy "Users can view their own tenants"
on tenants for select
using (
  auth.uid() in (
    select user_id from organization_members where organization_id = id
  )
);

-- Organization Members: Users can view members of their organizations
alter table organization_members enable row level security;

create policy "Users can view members of their organizations"
on organization_members for select
using (
  auth.uid() in (
    select user_id from organization_members as om
    where om.organization_id = organization_members.organization_id
  )
);
