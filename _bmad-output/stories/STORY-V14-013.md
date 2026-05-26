# STORY-V14-013 : tenant_handle + network_public columns (anticipation Phase 4 Scalario Network)

**Epic :** EPIC-V14-008 — Anticipation Phase 4 (Scalario Network)
**Priorité :** Must Have (anticipation, coût zéro)
**Story Points :** 2
**Status :** completed
**Sprint :** v14-1 (2026-05-26 → 2026-06-08)
**Dépendances :** V14-001 (nomenclature), V14-005 (restructure NestJS)

---

## User Story

> **En tant que** Scalario Labs prévoyant l'évolution Phase 4 (Scalario Network B2B),
> **je veux** ajouter dès Phase 1 les colonnes `tenant_handle TEXT UNIQUE`, `network_public BOOLEAN`, `network_profile JSONB` à `public.tenants`, **avec valeurs par défaut désactivées**,
> **so that** en Phase 4 quand on ouvre le marketplace inter-tenants, il n'y aura **aucune migration DB** à faire — l'identité réseau est déjà là, juste pas exposée.

---

## Description

### Background

PRD v14 §26b.4 — décisions à prendre dès Phase 1 pour éviter le rebuild Phase 4 :

```sql
ALTER TABLE public.tenants ADD COLUMN
  handle          TEXT UNIQUE,           -- '@grossiste-pharma-ouaga'
  network_public  BOOLEAN DEFAULT FALSE,
  network_profile JSONB DEFAULT '{}';
```

Et dans `tenant.config` :

```json
{
  "network": {
    "public": false,
    "expose_modules": [],
    "allow_inbound_orders": false,
    "allow_inbound_payments": false
  }
}
```

Impact Phase 1-3 : **zéro** (network_public=false par défaut, aucune route réseau exposée). Impact Phase 4 : infrastructure prête.

### Scope

**In scope :**
- Migration `1700000000XXX-add-tenant-handle-network.ts` (TypeORM)
- Validation `tenant_handle` : `@[a-z0-9-]{3,32}` (Twitter-like)
- Champ optional au provisioning : tenant peut être créé sans handle (généré auto depuis name)
- `tenant.config.network` ajouté (par défaut désactivé)
- DTO `UpdateTenantHandleDto` + endpoint `PATCH /api/v1/tenants/:slug/handle` (Owner/SuperAdmin only)
- Tests : provisioning crée handle auto si absent, PATCH handle vérifie uniqueness

**Out of scope :**
- Routes inter-tenant (catalogue réseau, commande cross-tenant, paiement cross-tenant) — Phase 4
- KYC entreprises, notation, contrats numériques — Phase 4
- Marketplace UI — Phase 4

---

## Acceptance Criteria

### Migration DB

- [x] **AC-01** — Migration TypeORM `1700000000009-add-tenant-handle-network` ajoute 3 colonnes à `public.tenants` : `handle`, `network_public`, `network_profile`.
- [x] **AC-02** — `handle` est `UNIQUE` (index unique partial — ignore NULL).
- [x] **AC-03** — Migration réversible (down() restore l'état v13).

### Validation + génération handle

- [x] **AC-04** — Format handle : `[a-z0-9-]{3,32}` (lowercase, chiffres, tirets, 3-32 chars). Le `@` prefix est ajouté à la rendition, pas stocké.
- [x] **AC-05** — Au provisioning : si `dto.handle` est fourni → valider + uniqueness check ; si absent → générer `slugify(tenant.name)` avec déduplication automatique.
- [x] **AC-06** — `handle` est INSENSITIVE casse à la création (lowercase forcé).

### `tenant.config.network` defaults

- [x] **AC-07** — Au provisioning : `tenant.config.network = { public: false, expose_modules: [], allow_inbound_orders: false, allow_inbound_payments: false }`.
- [x] **AC-08** — Zod validation pour ces fields (futur-proof).

### Endpoint PATCH handle

- [x] **AC-09** — `PATCH /api/v1/tenants/:slug/handle` body `{ handle: 'nouveau-handle' }` accepte OWNER + SUPER_ADMIN.
- [x] **AC-10** — Erreur 409 si handle déjà pris par un autre tenant.
- [x] **AC-11** — Erreur 400 si format invalide.

### Tests

- [x] **AC-12** — Migration run + revert : 0 erreur.
- [x] **AC-13** — Provisioning auto-genere handle depuis name (3 cas : nom court, nom long >32 chars tronqué, collision avec déduplication).
- [x] **AC-14** — PATCH handle : OWNER OK, MANAGER 403, SUPER_ADMIN OK, conflict 409.

---

## Technical Notes

### Migration TypeORM

```typescript
export class AddTenantHandleNetwork1700000000050 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`
      ALTER TABLE public.tenants ADD COLUMN handle TEXT;
      CREATE UNIQUE INDEX idx_tenants_handle ON public.tenants(handle) WHERE handle IS NOT NULL;
      ALTER TABLE public.tenants ADD COLUMN network_public BOOLEAN NOT NULL DEFAULT FALSE;
      ALTER TABLE public.tenants ADD COLUMN network_profile JSONB NOT NULL DEFAULT '{}'::jsonb;
    `);
  }
  async down(queryRunner: QueryRunner) {
    await queryRunner.query(`
      ALTER TABLE public.tenants DROP COLUMN handle, DROP COLUMN network_public, DROP COLUMN network_profile;
    `);
  }
}
```

### Helper de génération handle

```typescript
function generateHandle(name: string, existing: string[]): string {
  const base = slugify(name).slice(0, 30);
  if (!existing.includes(base)) return base;
  let n = 2;
  while (existing.includes(`${base}-${n}`)) n++;
  return `${base}-${n}`;
}
```

### Edge cases

- Nom tenant contient accents (`Pharmacie Kossyäm`) → slugify normalise (`pharmacie-kossyam`).
- Nom tenant >32 chars → tronqué.
- Migration sur DB qui a déjà 100+ tenants : `network_profile DEFAULT '{}'::jsonb` rapide.
- Race condition uniqueness : index unique attrape, retry avec `-2`, `-3`.

---

## Dependencies

- **Prérequis :** V14-001, V14-005
- **Stories bloquées :** Aucune Phase 1-3 (network reste désactivé). Phase 4 entière dépend de ça (mais Phase 4 n'est pas planifiée).

---

## Definition of Done

- [x] Migration TypeORM créée + testée up/down
- [x] Slugify helper + tests
- [x] PATCH endpoint + tests (4 cas RBAC + conflict)
- [x] `tenant.config.network` défauts au provisioning
- [x] Docs `docs/anticipation-phase4-scalario-network.md`
- [x] sprint-status.yaml V14-013 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Migration TypeORM + slugify helper | 0.5 |
| Provisioning auto-genere handle | 0.5 |
| PATCH endpoint + RBAC | 0.5 |
| Tests | 0.25 |
| Docs anticipation Phase 4 | 0.25 |
| **Total** | **2** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)
- 2026-05-25 : Completed (Claude via `/bmad:dev-story`)

**Actual Effort :** ~45 min

---

## Dev Agent Record

### Completion Notes
- Migration `1700000000009-add-tenant-handle-network`: 3 columns (handle UNIQUE partial, network_public BOOLEAN, network_profile JSONB), reversible.
- `Tenant` entity: handle, network_public, network_profile fields (optional `?` for backward compat).
- `handle-generator.ts`: slugify (NFKD normalize, lowercase, alphanumeric-only, 30 char limit) + generateHandle with automatic deduplication (`-2`, `-3`...).
- `ProvisionTenantSchema`: optional `handle` field, regex `[a-z0-9-]{3,32}`.
- `TenantsProvisionController`: handle validation + uniqueness check + auto-generation + `config.network` defaults.
- `TenantsHandleController`: PATCH `/:slug/handle` (OWNER+SUPER_ADMIN), 409 conflict, audit log.
- `UpdateTenantHandleSchema`: Zod regex validation.
- `AUDIT_ACTIONS.TENANT_HANDLE_UPDATED` added.
- Docs: `docs/anticipation-phase4-scalario-network.md`.

### File List
| File | Action |
|---|---|
| `migrations/1700000000009-add-tenant-handle-network.ts` | New |
| `src/core/auth/entities/tenant.entity.ts` | Modified (+3 columns, TenantConfig.network) |
| `src/tenants/dto/provision.dto.ts` | Modified (+handle field) |
| `src/tenants/dto/update-handle.dto.ts` | New |
| `src/tenants/handle-generator.ts` | New |
| `src/tenants/tenants-provision.controller.ts` | Modified (handle + network defaults) |
| `src/tenants/tenants-handle.controller.ts` | New |
| `src/tenants/tenants.module.ts` | Modified (+HandleController) |
| `src/tenants/__tests__/handle-generator.spec.ts` | New (6 tests) |
| `src/tenants/__tests__/tenant-handle.dto.spec.ts` | New (10 tests) |
| `src/core/audit/constants.ts` | Modified (+TENANT_HANDLE_UPDATED) |
| `docs/anticipation-phase4-scalario-network.md` | New |

### Change Log
- 2026-05-25: Story V14-013 completed. Migration + tenant handle + network columns + PATCH endpoint. 16 new tests. 0 regression (646 NestJS / 826 Flutter).
