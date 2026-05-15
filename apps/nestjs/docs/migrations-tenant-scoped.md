# Migrations tenant-scoped — checklist

STORY-017 a installé Layer 5 (PostgreSQL RLS). Toute nouvelle table qui
stocke des données appartenant à un tenant doit suivre la checklist
ci-dessous, sans quoi la table sera lisible cross-tenant (et CI échouera
sur le test d'intrusion correspondant).

## 1. Étendre `TenantScopedEntity`

```ts
@Entity({ name: 'orders' })
export class Order extends TenantScopedEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;
  // …
}
```

`TenantScopedEntity` ajoute `tenant_id UUID NOT NULL` + index.

## 2. Ajouter la colonne `tenant_id` dans la migration SQL

```sql
CREATE TABLE orders (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  -- …
);
```

`REFERENCES tenants(id) ON DELETE CASCADE` garantit qu'un tenant désactivé
purge ses données.

## 3. Composite index `(tenant_id, …)`

```sql
CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status);
```

Sans cet index le planner fait un Seq Scan et l'overhead RLS dépasse 5 %
(cf. AC-15 STORY-017).

## 4. `ENABLE ROW LEVEL SECURITY` + `FORCE`

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;
```

`FORCE` empêche le owner (`scalario_admin`) de bypasser implicitement la
policy — seul le flag `BYPASSRLS` au niveau rôle peut court-circuiter.

## 5. Policy `<table>_tenant_isolation` (USING + WITH CHECK)

```sql
CREATE POLICY orders_tenant_isolation ON orders
  USING      (tenant_id = current_setting('app.current_tenant_id', true)::uuid)
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
```

`USING` filtre les lectures. `WITH CHECK` empêche l'INSERT/UPDATE
cross-tenant.

## 6. Test d'intrusion

Ajouter un cas dans `apps/nestjs/src/security/__tests__/rls-intrusion.e2e.spec.ts` :

- Connect `scalario_app` sans `SET` → 0 row.
- Connect `scalario_app` avec `SET app.current_tenant_id = '<A>'` → seuls les rows tenant A.
- `INSERT` avec `tenant_id = '<B>'` quand GUC = A → erreur RLS.

## Cas particulier : `audit_logs`

Insert-only. Pas d'UPDATE/DELETE — `REVOKE UPDATE, DELETE … FROM PUBLIC`.

## Cas particulier : tables sans `tenant_id` (`tenants`, métadonnées plateforme)

Pas de policy. La table reste visible au rôle applicatif — c'est
intentionnel. Documenter dans la migration *pourquoi* la table n'est pas
tenant-scoped.

## `withRlsBypass` — règles d'usage

Le helper `RlsBypassService.withBypass` est l'unique voie sanctionnée
pour lire/écrire cross-tenant. Whitelist runtime + audit log
systématique :

1. `TenantsService.provision` — création initiale d'un tenant.
2. `AuthService.superAdminLogin` — opérateur plateforme.
3. `CleanupService.purge` — job cron de purge cross-tenant.

Ajouter un 4ᵉ call site nécessite : (a) modifier `ALLOWED_CALLERS`, (b)
review sécurité explicite dans la PR, (c) entrée dans
`_bmad-output/security/rls-bypass-callers.md`.

## Rollback d'urgence

`scripts/rollback-rls.sql` — désactive RLS sur toutes les tables. Usage
strictement contrôlé (cf. en-tête du script).
