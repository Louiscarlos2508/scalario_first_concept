# Story 29.1 — Backend — BusinessTypeDefinition model, seed 13 types, endpoints (FR104)

## Metadata

- **Epic:** Epic 29 — Types de Business Configurables
- **Story ID:** 29-1-business-type-backend
- **Status:** review
- **Priority:** High
- **Phase:** 2a
- **Depends on:** Epic 2 (Prisma multi-schema kernel), Epic 4 (AdminTenantsService), Epic 9 (SuperAdminGuard)

---

## Story

**As a** superadmin,
**I want** a `BusinessTypeDefinition` model with seed data for 13 business types, two read endpoints listing and fetching types, and a `PATCH /admin/tenants/:id/business-type` endpoint to assign a type to a tenant,
**So that** business types are configurable without deployment and serve as the source of truth for product form defaults and suggested categories (FR104).

---

## Acceptance Criteria

### AC1 — Migration Prisma BusinessTypeDefinition

**Given** le fichier `schema.prisma` est mis à jour avec le modèle `BusinessTypeDefinition`
**When** la migration est appliquée
**Then** la table `business_type_definitions` existe dans le schéma `kernel` avec les colonnes : `id`, `code` (unique), `name`, `description` (nullable), `default_flags` (Json), `visible_sections` (String[]), `suggested_categories` (String[]), `icon` (nullable), `is_active` (default true), `created_at`

### AC2 — Migration Prisma Tenant.businessType

**Given** la migration est appliquée
**When** on inspecte la table `tenants`
**Then** la colonne `business_type` (String, default `"generaliste"`) est présente
**And** aucune contrainte FK stricte sur `business_type` — le code est libre (flexibilité seed)

### AC3 — Seed 13 types

**Given** la commande `prisma db seed` est exécutée
**When** la base est vide ou les types sont absents
**Then** 13 types sont créés par upsert sur `code` :

| code | name | defaultFlags | visibleSections | suggestedCategories |
| :--- | :--- | :--- | :--- | :--- |
| `generaliste` | Généraliste | {} | [] | [] |
| `epicerie` | Épicerie & Alimentation | { expiryDays: 30 } | ["expiry"] | ["Fruits & Légumes", "Épices", "Céréales", "Boissons", "Produits laitiers", "Conserves"] |
| `telephonie` | Téléphonie & Accessoires | { hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 } | ["variants", "serial", "warranty"] | ["Smartphones", "Accessoires", "Cartes SIM", "Recharge", "Réparation"] |
| `textile` | Textile & Habillement | { hasVariants: true } | ["variants"] | ["Hauts", "Bas", "Robes", "Chaussures", "Accessoires", "Tissu"] |
| `pharmacie` | Pharmacie & Parapharmacie | { expiryDays: 365, requiresPrescription: false } | ["expiry", "prescription"] | ["Médicaments", "Parapharmacie", "Matériel médical", "Vitamines"] |
| `quincaillerie` | Quincaillerie & Matériaux | { hasVariants: true, unitType: "weight" } | ["variants", "weight"] | ["Peinture", "Plomberie", "Électricité", "Outillage", "Ciment", "Fer"] |
| `cosmetique` | Cosmétique & Beauté | { hasVariants: true, expiryDays: 730 } | ["variants", "expiry"] | ["Soin visage", "Soin corps", "Cheveux", "Parfums", "Maquillage"] |
| `restaurant` | Restaurant & Restauration rapide | {} | [] | ["Plats", "Boissons", "Entrées", "Desserts", "Menus"] |
| `boulangerie` | Boulangerie & Pâtisserie | { expiryDays: 3 } | ["expiry"] | ["Pain", "Viennoiseries", "Gâteaux", "Sandwichs", "Boissons"] |
| `services` | Services & Prestation | {} | [] | ["Consultation", "Réparation", "Formation", "Livraison", "Autre"] |
| `informatique` | Informatique & Électronique | { trackSerialNumbers: true, warrantyMonths: 12, hasVariants: true } | ["variants", "serial", "warranty"] | ["Ordinateurs", "Téléphones", "Accessoires", "Composants", "Imprimantes", "Réparation"] |
| `vehicules` | Véhicules & Pièces détachées | { trackSerialNumbers: true, warrantyMonths: 6 } | ["serial", "warranty"] | ["Pièces moteur", "Carrosserie", "Pneumatiques", "Électronique auto", "Huiles & Filtres"] |
| `grossiste` | Commerce de gros | { hasVariants: true, unitType: "weight" } | ["variants", "weight"] | ["Alimentaire", "Cosmétique", "Textile", "Quincaillerie", "Électronique"] |

**And** le seed est idempotent (upsert par `code`)

### AC4 — GET /admin/business-types — liste

**Given** un superadmin authentifié appelle `GET /api/v1/admin/business-types`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste de tous les `BusinessTypeDefinition` actifs triés par `name` ASC
**And** les types inactifs (`isActive = false`) sont exclus

### AC5 — GET /admin/business-types/:code — détail

**Given** un superadmin appelle `GET /api/v1/admin/business-types/:code`
**When** le code existe
**Then** la réponse est `200 OK` avec le `BusinessTypeDefinition` complet incluant `defaultFlags`, `visibleSections` et `suggestedCategories`
**When** le code n'existe pas
**Then** la réponse est `404 Not Found` : `"Type de business introuvable : :code"`

### AC6 — PATCH /admin/tenants/:id/business-type — assignation

**Given** un superadmin envoie `PATCH /api/v1/admin/tenants/:id/business-type` avec `{ businessType: "telephonie" }`
**When** le tenant existe et le code correspond à un type actif
**Then** `tenant.businessType` est mis à jour et le tenant mis à jour est retourné en `200 OK`
**When** le code n'existe pas dans `business_type_definitions`
**Then** la réponse est `404 Not Found` : `"Type de business inconnu : :code"`
**And** le `businessType` du tenant n'est pas modifié

---

## Tasks / Subtasks

- [x] **Task 1 — Migration Prisma** (AC1, AC2)
  - [x] Ajouter le modèle `BusinessTypeDefinition` dans `schema.prisma` (schéma `kernel`)
  - [x] Ajouter `businessType String @default("generaliste") @map("business_type")` sur le modèle `Tenant`
  - [x] Générer la migration via `prisma db push` (shadow DB avait une erreur P3006 pre-existing sur migration catalogItem) + migration SQL créée manuellement
  - [x] Vérifier le fichier SQL dans `apps/backend/prisma/migrations/20260320040000_add_business_type_definitions/migration.sql`

- [x] **Task 2 — Seed 13 types** (AC3)
  - [x] Ajouter `seedBusinessTypes()` dans `apps/backend/prisma/seed.ts` après `seedPlans()`
  - [x] Utiliser `prisma.businessTypeDefinition.upsert({ where: { code }, ... })` pour chaque type
  - [x] Vérifié idempotent : 2 exécutions consécutives → 13 types, pas de doublons

- [x] **Task 3 — BusinessTypeModule NestJS** (AC4, AC5, AC6)
  - [x] Créer `apps/backend/src/admin/business-type/business-type.module.ts` (pattern admin/ comme BillingModule — exporté pour injection dans AdminTenantsService)
  - [x] Créer `apps/backend/src/admin/business-type/business-type.service.ts` : `listActive()`, `getDefinition(code)`, `assignToTenant(id, code)`, `seedCategories()` stub
  - [x] Créer `apps/backend/src/admin/business-type/business-type.controller.ts` : GET admin/business-types, GET admin/business-types/:code, PATCH admin/tenants/:id/business-type
  - [x] Créer `apps/backend/src/admin/business-type/dto/assign-business-type.dto.ts`
  - [x] Enregistrer `BusinessTypeModule` dans `apps/backend/src/admin/admin.module.ts`

- [x] **Task 4 — PATCH endpoint sur AdminTenantsController** (AC6)
  - [x] Exposé directement dans `BusinessTypeController` pour cohérence du module

---

## Files to Create

- `apps/backend/prisma/migrations/20260320040000_add_business_type_definitions/migration.sql`
- `apps/backend/src/kernel/business-type/business-type.module.ts`
- `apps/backend/src/kernel/business-type/business-type.controller.ts`
- `apps/backend/src/kernel/business-type/business-type.service.ts`
- `apps/backend/src/kernel/business-type/dto/assign-business-type.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `BusinessTypeDefinition` + champ `businessType` sur `Tenant`
- `apps/backend/prisma/seed.ts` — seed 13 types
- `apps/backend/src/app.module.ts` — importer `BusinessTypeModule`

---

## Dev Notes

### Emplacement du module

Le module vit dans `apps/backend/src/kernel/business-type/` (pattern kernel), même si des endpoints admin y sont exposés. C'est cohérent avec `apps/backend/src/kernel/billing/` qui contient aussi des guards et services exposés via des routes admin.

### Multi-schema Prisma

`BusinessTypeDefinition` doit être dans `@@schema("kernel")`. Vérifier que `schema.prisma` a `schemas = ["kernel", "shared", "public"]` dans le bloc `datasource`. Le champ `businessType` sur `Tenant` est dans le schéma `public` (table `tenants`).

### Pas de FK sur businessType

`Tenant.businessType` est un `String` libre sans `@relation` vers `BusinessTypeDefinition`. Cela permet de créer des tenants avec des types personnalisés futurs sans migration bloquante. La validation se fait au niveau service (AC6 : vérifier existence dans `business_type_definitions` avant de sauvegarder).

### defaultFlags : objet Json libre

Ne pas typer rigidement via un DTO strict. Côté API, retourner le Json tel quel. Côté Flutter, désérialiser en `Map<String, dynamic>`. Les clés attendues par le `ProductFormDialog` (Story 29-3) sont : `hasVariants`, `trackSerialNumbers`, `warrantyMonths`, `expiryDays`, `requiresPrescription`, `unitType`.

### Seed idempotent

```typescript
await prisma.businessTypeDefinition.upsert({
  where: { code: 'telephonie' },
  update: { name: 'Téléphonie & Accessoires', defaultFlags: {...}, ... },
  create: { code: 'telephonie', name: 'Téléphonie & Accessoires', defaultFlags: {...}, ... },
});
```

### CreateTenantDto — champ businessType

`AdminTenantsService.CreateTenantDto` (ligne 14 de `admin-tenants.service.ts`) devra accepter un champ optionnel `businessType?: string` (ajouté en Story 29-4 ou dans cette story). Cette story crée les endpoints et le module ; l'intégration avec `createTenant()` est en Story 29-4.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 29-1]
- [Source: _bmad-output/planning-artifacts/prd.md — FR104]
- [Source: apps/backend/src/admin/tenants/admin-tenants.service.ts — CreateTenantDto pattern]
- [Source: apps/backend/src/kernel/billing/billing.guard.ts — pattern kernel module]
- [Source: apps/backend/src/admin/tenants/admin-tenants.controller.ts — SuperAdminGuard pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Module placed in `src/admin/business-type/` (matches BillingModule pattern, not kernel/ as story spec suggested — codebase pattern takes precedence)
- `prisma db push` used instead of `migrate dev` due to pre-existing P3006 shadow DB error on unrelated migration; migration SQL created manually
- 8 unit tests for `BusinessTypeService` covering AC4, AC5, AC6 — all passing
- Pre-existing failures: `retail-session.controller.spec.ts` and `purchase-orders.service.spec.ts` (confirmed by git stash verification)
- `seedCategories()` is a stub — fully implemented in Story 29-4

### File List

- `apps/backend/prisma/schema.prisma` (modified)
- `apps/backend/prisma/seed.ts` (modified)
- `apps/backend/prisma/migrations/20260320040000_add_business_type_definitions/migration.sql` (created)
- `apps/backend/src/admin/business-type/business-type.module.ts` (created)
- `apps/backend/src/admin/business-type/business-type.service.ts` (created)
- `apps/backend/src/admin/business-type/business-type.controller.ts` (created)
- `apps/backend/src/admin/business-type/dto/assign-business-type.dto.ts` (created)
- `apps/backend/src/admin/business-type/business-type.service.spec.ts` (created)
- `apps/backend/src/admin/admin.module.ts` (modified)
