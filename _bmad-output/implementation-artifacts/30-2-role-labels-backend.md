# Story 30.2 — Backend — roleLabels + documentType sur BusinessTypeDefinition, migration, seed 14 types (FR109, FR111)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-2-role-labels-backend
- **Status:** review
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 29-1 (BusinessTypeDefinition model + seed 13 types)

---

## Story

**As a** superadmin,
**I want** `roleLabels` (JSON) and `documentType` (String) fields on `BusinessTypeDefinition`, the seed updated for all 14 types including the new "distribution" type, and these fields returned by the existing GET endpoints,
**So that** the UI can display business-specific role names and determine the correct delivery document type (FR109, FR111).

---

## Acceptance Criteria

### AC1 — Migration additive roleLabels + documentType

**Given** le fichier `schema.prisma` est mis à jour avec `roleLabels Json @default("{}")` et `documentType String @default("receipt")` sur `BusinessTypeDefinition`
**When** la migration est appliquée
**Then** les colonnes `role_labels` (jsonb, défaut `{}`) et `document_type` (text, défaut `'receipt'`) existent dans `business_type_definitions`
**And** toutes les lignes existantes reçoivent les valeurs par défaut sans erreur de migration

### AC2 — Seed mis à jour pour 14 types avec documentType

**Given** la commande `prisma db seed` est exécutée
**When** les 14 types sont traités par upsert sur `code`
**Then** chaque type a le `documentType` approprié :

| code | documentType |
| :--- | :--- |
| `generaliste` | `receipt` |
| `epicerie` | `receipt` |
| `telephonie` | `receipt` |
| `textile` | `receipt` |
| `pharmacie` | `receipt` |
| `quincaillerie` | `delivery_note` |
| `cosmetique` | `receipt` |
| `restaurant` | `receipt` |
| `boulangerie` | `receipt` |
| `services` | `invoice` |
| `informatique` | `invoice` |
| `vehicules` | `invoice` |
| `grossiste` | `delivery_note` |
| `distribution` | `delivery_note` |

### AC3 — Seed avec roleLabels par type

**Given** le seed est exécuté
**When** les types sont upsertés
**Then** les types avec des rôles spécifiques ont des `roleLabels` appropriés :
- `telephonie` : `{"commercial": "Vendeur", "manager": "Responsable boutique", "cashier": "Caissier"}`
- `distribution` : `{"commercial": "Commercial terrain", "manager": "Directeur dépôt", "cashier": "Opérateur"}`
- `grossiste` : `{"commercial": "Commercial", "manager": "Responsable dépôt", "cashier": "Opérateur"}`
- `services` : `{"commercial": "Prestataire", "manager": "Responsable", "cashier": "Accueil"}`
- `informatique` : `{"commercial": "Technicien-vendeur", "manager": "Responsable technique"}`
- `pharmacie` : `{"commercial": "Préparateur", "manager": "Pharmacien gérant"}`
- Les autres types gardent `roleLabels = {}`
**And** le seed est idempotent (upsert par `code`)

### AC4 — Type "distribution" créé comme 14ème type

**Given** le seed est exécuté
**When** le type `distribution` n'existe pas encore
**Then** il est créé avec :
- `name` : `"Commerce de distribution"`
- `description` : `"Vente en gros, livraison clients, bons de livraison"`
- `defaultFlags` : `{ "hasVariants": true }`
- `visibleSections` : `["variants"]`
- `suggestedCategories` : `["Alimentaire", "Boissons", "Hygiène", "Nettoyage", "Épicerie fine"]`
- `documentType` : `"delivery_note"`
- `icon` : `"local_shipping"`
- `isActive` : `true`

### AC5 — Endpoints retournent les nouveaux champs

**Given** un appel à `GET /api/v1/admin/business-types/:code`
**When** la requête est valide
**Then** la réponse inclut `roleLabels` et `documentType` dans le payload
**Given** un appel à `GET /api/v1/business-type/config` (tenant-scoped, créé en 29-3)
**When** la requête est valide
**Then** `roleLabels` et `documentType` sont également présents dans la réponse

---

## Tasks / Subtasks

- [x] **Task 1 — Migration Prisma** (AC1)
  - [x] Ajouter `roleLabels Json @default("{}") @map("role_labels")` sur `BusinessTypeDefinition` dans `schema.prisma`
  - [x] Ajouter `documentType String @default("receipt") @map("document_type")` sur `BusinessTypeDefinition`
  - [x] Générer la migration SQL et vérifier qu'elle est non-destructive

- [x] **Task 2 — Seed mis à jour** (AC2, AC3, AC4)
  - [x] Mettre à jour les 13 types existants dans `seed.ts` : ajouter `documentType` et `roleLabels` à chaque type via upsert
  - [x] Ajouter l'entrée `distribution` comme 14ème type
  - [x] Vérifier que le seed est idempotent (upsert by `code`)

- [x] **Task 3 — Vérifier que les endpoints exposent les nouveaux champs** (AC5)
  - [x] Contrôleur `GET /admin/business-types/:code` : vérifier que la réponse inclut `roleLabels` et `documentType` (pas de mapping explicite = automatique via Prisma)
  - [x] Contrôleur `GET /business-type/config` : même vérification
  - [x] Si un DTO de réponse filtre les champs, l'étendre

- [x] **Task 4 — Vérifier BusinessTypeConfig Flutter** (AC5)
  - [x] Lire `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart` (créé en 29-3)
  - [x] Vérifier que `BusinessTypeConfig` mappe `roleLabels` (Map<String, dynamic>) et `documentType` (String)
  - [x] Ajouter les champs si absents avec valeurs par défaut (`roleLabels: {}`, `documentType: 'receipt'`)

- [x] **Task 5 — Tests** (AC1–AC5)
  - [x] Test seed : vérifier que le type `distribution` est créé et que `roleLabels`/`documentType` sont bien initialisés
  - [x] Test endpoint : vérifier que `GET /admin/business-types/distribution` retourne les nouveaux champs

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_role_labels_document_type/migration.sql`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — ajouter `roleLabels`, `documentType` sur `BusinessTypeDefinition`
- `apps/backend/prisma/seed.ts` — mettre à jour les 13 types + ajouter `distribution`
- `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart` — ajouter `roleLabels`, `documentType` dans `BusinessTypeConfig` si absents

---

## Dev Notes

### Migration non-destructive

Les champs `roleLabels` et `documentType` ont des valeurs par défaut (`{}` et `'receipt'`) — aucune donnée existante n'est perdue. La migration peut être appliquée en production sans downtime.

### documentType — 3 valeurs acceptées

- `"receipt"` : ticket de caisse (défaut — convient pour toute vente au détail directe)
- `"delivery_note"` : bon de livraison (grossiste, distribution, quincaillerie)
- `"invoice"` : facture (services, informatique, véhicules — transactions B2B avec TVA éventuelle)

### roleLabels — le champ "owner" est ignoré par l'UI

La clé `owner` peut être présente dans `roleLabels` côté seed (cohérence), mais le frontend ne l'utilise jamais — le propriétaire affiche toujours "Propriétaire". Cela évite une divergence entre le seed et le comportement attendu.

### Ordre dans seed.ts

Ajouter `distribution` après `grossiste` (ordre alphabétique non requis, mais cohérence sectorielle recommandée). Le upsert guarantit l'idempotence : exécuter deux fois ne crée pas de doublon.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-2]
- [Source: _bmad-output/planning-artifacts/prd.md — FR109, FR111]
- [Source: docs/architecture-scalario-2026-03-08.md — Section 4.1.7 Business Type Module, BusinessTypeDefinition Prisma model]
- [Source: apps/backend/src/admin/business-type/business-type.service.ts — service existant (29-1)]
- [Source: apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart — repository Flutter (29-3)]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
N/A — no regressions, all pre-existing tests still pass

### Completion Notes List
- Added roleLabels (Json) and documentType (String) fields to BusinessTypeDefinition via additive migration (safe for production)
- Updated seed.ts: all 13 types have documentType + roleLabels; distribution added as 14th type
- Endpoints return new fields automatically (Prisma pass-through, no DTO filtering)
- Flutter BusinessTypeConfig updated with roleLabels + documentType fields + fallback defaults
- 10/10 tests pass (business-type service spec extended with new field coverage)

### File List
- apps/backend/prisma/migrations/20260320060000_add_role_labels_document_type/migration.sql
- apps/backend/prisma/schema.prisma (modified — roleLabels, documentType on BusinessTypeDefinition)
- apps/backend/prisma/seed.ts (modified — 13 types updated, distribution added)
- apps/backend/src/admin/business-type/business-type.service.spec.ts (modified — added roleLabels/documentType/distribution tests)
- apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart (modified — roleLabels + documentType fields)
