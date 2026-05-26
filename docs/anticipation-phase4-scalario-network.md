# anticipation-phase4-scalario-network.md

**Story**: STORY-V14-013
**Date**: 2026-05-25
**Status**: Anticipation — no Phase 1-3 impact

## Pourquoi cette anticipation

Le PRD v14 §26b.4 identifie trois colonnes a ajouter des Phase 1 pour
eviter un rebuild de la DB en Phase 4 (Scalario Network B2B). Le cout
en Phase 1 est zero (valeurs desactivees par defaut, pas de routes
exposees). Le gain en Phase 4 est enorme (0 migration, 0 downtime).

## Colonnes ajoutees

| Colonne | Type | Default | Usage Phase 4 |
|---|---|---|---|
| `handle` | TEXT UNIQUE (partial, NULL ignored) | NULL | Identifiant reseau `@blandine-shop` (stocke sans `@`) |
| `network_public` | BOOLEAN | FALSE | Visibilite sur le marketplace inter-tenant |
| `network_profile` | JSONB | `{}` | Metadata publique (description, logo, categories, certifications) |

## Index

- `CREATE UNIQUE INDEX idx_tenants_handle ON tenants(handle) WHERE handle IS NOT NULL`
- Index partiel — les tenants sans handle (Phase 1-3 normal) ne consomment pas d'index.

## tenant.config.network

Ajoute au provisioning :

```json
{
  "roles": ["OWNER"],
  "network": {
    "public": false,
    "expose_modules": [],
    "allow_inbound_orders": false,
    "allow_inbound_payments": false
  }
}
```

## API

### PATCH /api/v1/tenants/:slug/handle

```json
// Request (OWNER or SUPER_ADMIN)
{ "handle": "nouveau-handle" }

// Response 200
{ "handle": "nouveau-handle" }

// Error 400 — format invalide
{ "message": "handle must match ^[a-z0-9-]{3,32}$" }

// Error 409 — deja pris
{ "message": "Handle already taken by another tenant", "handle": "blandine-shop" }
```

### POST /api/v1/tenants/provision (etendu)

Le champ `handle` est optionnel. Si absent, genere automatiquement depuis `name`.
Si fourni, valide l'unicite.

## GenerateHandle

Algorithme :
1. `slugify(name)` — normalize NFKD, lowercase, tronque a 30 chars
2. Si le handle est libre → retourne
3. Sinon, ajoute `-2`, `-3`… jusqu'a trouver un libre (max 100 essais)

## Ce qu'il restera a faire en Phase 4

- [ ] Route `GET /network/tenants` (catalogue public)
- [ ] Route `POST /network/orders` (commande inter-tenant)
- [ ] Route `POST /network/payments` (paiement inter-tenant)
- [ ] KYC entreprises + verification
- [ ] Notation + contrats numeriques
- [ ] UI marketplace Flutter

## Fichiers impactes

| Fichier | Action |
|---|---|
| `migrations/1700000000009-add-tenant-handle-network.ts` | New |
| `src/core/auth/entities/tenant.entity.ts` | Modified (+3 columns) |
| `src/tenants/dto/provision.dto.ts` | Modified (+handle field) |
| `src/tenants/dto/update-handle.dto.ts` | New |
| `src/tenants/handle-generator.ts` | New |
| `src/tenants/tenants-provision.controller.ts` | Modified (handle + network defaults) |
| `src/tenants/tenants-handle.controller.ts` | New |
| `src/tenants/tenants.module.ts` | Modified (+HandleController) |
| `src/core/audit/constants.ts` | Modified (+TENANT_HANDLE_UPDATED) |
