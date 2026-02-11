INSERT INTO organization_members (organization_id, user_id, role)
SELECT id, 'bc194d06-2335-4418-a35e-8b19b4b612ed', 'owner'
FROM tenants
LIMIT 1
ON CONFLICT DO NOTHING;