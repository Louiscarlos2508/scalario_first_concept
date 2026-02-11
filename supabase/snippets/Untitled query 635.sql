-- 1. On crée une fonction qui bypass la boucle infinie
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

-- 2. On applique la fonction aux règles de sécurité
DROP POLICY IF EXISTS "Users can view organization members" ON organization_members;
CREATE POLICY "Users can view organization members"
ON organization_members FOR SELECT
USING (is_member_of(organization_id));

DROP POLICY IF EXISTS "Users can view their own tenants" ON tenants;
CREATE POLICY "Users can view their own tenants"
ON tenants FOR SELECT
USING (is_member_of(id));

-- 3. On s'assure d'avoir notre propre membership (au cas où)
INSERT INTO public.organization_members (organization_id, user_id, role)
SELECT id, 'bc194d06-2335-4418-a35e-8b19b4b612ed', 'owner'
FROM tenants
LIMIT 1
ON CONFLICT DO NOTHING;