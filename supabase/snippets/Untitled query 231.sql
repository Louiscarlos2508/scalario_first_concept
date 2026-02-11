-- On nettoie les anciennes règles
DROP POLICY IF EXISTS "Users can view organization members" ON organization_members;
DROP POLICY IF EXISTS "Users can view their own membership" ON organization_members;
DROP POLICY IF EXISTS "Users can view their own tenants" ON tenants;

-- Nouvelle règle simple (Sans récursion)
CREATE POLICY "Users can view own membership" ON organization_members FOR SELECT USING (auth.uid() = user_id);

-- Règle pour les magasins (Utilise la fonction de sécurité)
CREATE POLICY "Users can view their own tenants" ON tenants FOR SELECT USING (is_member_of(id));

-- S'assurer d'avoir un magasin et un lien
INSERT INTO tenants (id, name) VALUES ('d0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a', 'Default Store') ON CONFLICT DO NOTHING;
INSERT INTO organization_members (organization_id, user_id, role) VALUES ('d0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a', 'bc194d06-2335-4418-a35e-8b19b4b612ed', 'owner') ON CONFLICT DO NOTHING;