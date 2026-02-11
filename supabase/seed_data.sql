-- Create a default tenant
INSERT INTO public.tenants (id, name)
VALUES ('d0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a', 'Demo Store')
ON CONFLICT (id) DO NOTHING;

-- Create a test user in auth.users
-- Password is 'admin123' (hashed using bcrypt)
-- Note: In a real scenario, we should use the Supabase Auth API, but for local dev with no CLI auth command, we inject.
-- However, injecting into auth.users is tricky due to password hashing.
-- A better approach for local dev if CLI is missing is to use the GoTrue API directly via curl.

-- Wait, actually, let's try to just insert the tenant and then guide the user to sign up? 
-- No, the user wants credentials.

-- Let's try to use the `supabase-js` client in a temporary node script to create the user properly.
-- This ensures the password is hashed correctly.
