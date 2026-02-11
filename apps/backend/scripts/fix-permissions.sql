-- Grant USAGE on schema public to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant SELECT on all tables in public to anon and authenticated roles
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- Ensure future tables also have these permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon, authenticated;

-- Specifically for organization_members if needed
GRANT ALL ON TABLE public.organization_members TO postgres, anon, authenticated;
GRANT ALL ON TABLE public.tenants TO postgres, anon, authenticated;
GRANT ALL ON TABLE public.products TO postgres, anon, authenticated;
GRANT ALL ON TABLE public.orders TO postgres, anon, authenticated;
GRANT ALL ON TABLE public.pos_sessions TO postgres, anon, authenticated;
