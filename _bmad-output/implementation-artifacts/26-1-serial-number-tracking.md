# Story 26.1 — Serial Number Tracking (FR92)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-1-serial-number-tracking
- **Status:** done
- **Priority:** High
- **Depends on:** Epic 2 (CatalogItem), Epic 4 (Transactions), Epic 6 (POS session)

---

## Story

**As a** owner or manager,
**I want** to track serial numbers per unit sold for eligible catalog items,
**So that** I can trace every sold unit back to its serial, customer, and sale date (FR92).

---

## Acceptance Criteria

### AC1 — Migration : trackSerialNumbers + SerialRecord

**Given** le modèle `CatalogItem` existe dans schema.prisma (schema `shared`)
**When** la migration est appliquée
**Then** le champ `trackSerialNumbers Boolean @default(false) @map("track_serial_numbers")` est présent sur `catalog_items`
**And** le modèle `SerialRecord` existe dans le schema `shared` avec :
  - `id String @id @default(uuid()) @db.Uuid`
  - `catalogItemId String @map("catalog_item_id") @db.Uuid`
  - `serial String`
  - `soldAt DateTime? @map("sold_at") @db.Timestamptz(6)`
  - `warrantyUntil DateTime? @map("warranty_until") @db.Timestamptz(6)` (réservé pour story 26-2)
  - `tenantId String @map("tenant_id") @db.Uuid`
  - `createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)`
  - Relation : `catalogItem CatalogItem @relation(fields: [catalogItemId], references: [id])`
**And** un index unique `@@unique([tenantId, serial])` et un index `@@index([catalogItemId])` sont présents
**And** `@@map("serial_records")` et `@@schema("shared")` sont appliqués

### AC2 — Endpoints SerialRecord

**Given** un article a `trackSerialNumbers = true`
**When** `POST /api/v1/catalog/:id/serials` est appelé avec `{ serial: "IMEI-123", soldAt?: "2026-03-19" }`
**Then** un `SerialRecord` est créé lié à l'article et au tenant courant
**And** le serial est unique par tenant — une tentative de doublon retourne `409 Conflict`
**And** `GET /api/v1/catalog/:id/serials` retourne la liste paginée (`?page=1&limit=20`) des SerialRecord de l'article
**And** `GET /api/v1/serials?q=<serial>` permet la recherche cross-articles par numéro de série (recherche partielle `ILIKE`)

### AC3 — Saisie numéro de série au POS avant checkout

**Given** un article dans le panier POS a `trackSerialNumbers = true`
**When** le caissier appuie sur "Valider" dans `CartPanel`
**Then** une `AlertDialog` / `BottomSheet` s'ouvre demandant la saisie du numéro de série
**And** le bouton de confirmation est désactivé tant que le champ est vide
**And** le numéro de série est stocké dans `CartItem.serialNumber` (champ à ajouter sur `CartItem`)
**And** si plusieurs articles du même type sont dans le panier, la saisie est demandée pour chaque unité
**And** la transaction est transmise au backend avec `serialNumbers: [...]` dans le payload

### AC4 — Création SerialRecord côté backend à la vente

**Given** `POST /api/v1/transactions` est appelé avec un payload incluant `items[].serialNumber`
**When** la transaction est finalisée
**Then** pour chaque ligne avec `serialNumber` renseigné, un `SerialRecord` est créé avec `soldAt = now()` et `catalogItemId` de la ligne
**And** en cas d'erreur de doublon (serial déjà vendu), la transaction est rejetée avec `409 Conflict`

### AC5 — Onglet "Séries" sur la fiche article dans le backoffice

**Given** l'owner navigue sur la fiche d'un article avec `trackSerialNumbers = true`
**When** l'onglet "Séries" est ouvert
**Then** la liste des `SerialRecord` est affichée : numéro de série, date de vente, date de garantie (si renseignée)
**And** une barre de recherche permet de filtrer par numéro de série
**And** si l'article a `trackSerialNumbers = false`, l'onglet est masqué

### AC6 — Toggle "Suivi par numéro de série" dans le formulaire article

**Given** l'owner édite ou crée un article dans `ProductFormDialog`
**When** il active le toggle "Suivi par numéro de série"
**Then** `trackSerialNumbers` est mis à `true` via `PATCH /api/v1/catalog/:id`
**And** un texte informatif s'affiche : "Le caissier devra saisir un numéro de série à chaque vente"

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma** (AC1)
  - [ ] Ajouter `trackSerialNumbers Boolean @default(false)` sur `CatalogItem`
  - [ ] Créer modèle `SerialRecord` complet dans `schema.prisma`
  - [ ] Générer et valider la migration SQL

- [ ] **Task 2 — SerialsModule backend** (AC2)
  - [ ] Créer `apps/backend/src/shared/catalog/serials/serials.service.ts`
    - `createSerial(tenantId, catalogItemId, dto)` — vérifie doublon unique, crée le record
    - `listSerials(tenantId, catalogItemId, page, limit)` — retourne paginé
    - `searchSerials(tenantId, query)` — ILIKE sur serial
  - [ ] Créer `apps/backend/src/shared/catalog/serials/serials.controller.ts`
    - `POST /catalog/:id/serials`
    - `GET /catalog/:id/serials`
    - `GET /serials?q=`
  - [ ] Enregistrer `SerialsModule` dans `CatalogModule`

- [ ] **Task 3 — Intégration dans TransactionsService** (AC4)
  - [ ] Modifier `TransactionsCreateDto` pour accepter `items[].serialNumber?: string`
  - [ ] Dans `processTransaction()`, après décrément de stock, créer `SerialRecord` pour chaque ligne avec serial
  - [ ] Gérer `409` si serial déjà existant pour ce tenant

- [ ] **Task 4 — CartItem.serialNumber + saisie POS** (AC3)
  - [ ] Ajouter `String? serialNumber` sur `CartItem` (state)
  - [ ] Ajouter `String? serialNumber` sur `CartItem.copyWith()`
  - [ ] Créer `serial_input_dialog.dart` — dialog avec champ texte obligatoire
  - [ ] Dans `CartPanel` avant `CheckoutController.confirmSale()`, vérifier si des articles requièrent un serial → ouvrir le dialog
  - [ ] Inclure `serialNumbers` dans le payload de la transaction envoyée au backend

- [ ] **Task 5 — Onglet Séries dans le backoffice** (AC5)
  - [ ] Ajouter provider `serialsProvider(catalogItemId)` → `FutureProvider<List<SerialRecord>>`
  - [ ] Créer widget `SerialRecordsTab` avec liste + barre de recherche
  - [ ] Intégrer l'onglet dans la fiche article de `CatalogScreen` (conditionnel sur `trackSerialNumbers`)

- [ ] **Task 6 — Toggle dans ProductFormDialog** (AC6)
  - [ ] Ajouter champ `SwitchListTile` pour `trackSerialNumbers`
  - [ ] Envoyer `PATCH /api/v1/catalog/:id` avec `{ trackSerialNumbers: true/false }`

---

## Files to Create

- `apps/backend/src/shared/catalog/serials/serials.service.ts`
- `apps/backend/src/shared/catalog/serials/serials.controller.ts`
- `apps/backend/src/shared/catalog/serials/serials.module.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_serial_records/migration.sql`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/serial_input_dialog.dart`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/serial_records_tab.dart`
- `apps/frontend/lib/features/shared/catalog/presentation/providers/serials_provider.dart`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `trackSerialNumbers` sur `CatalogItem`, nouveau modèle `SerialRecord`
- `apps/backend/src/shared/catalog/catalog.module.ts` — importer `SerialsModule`
- `apps/backend/src/shared/transactions/transactions.service.ts` — créer `SerialRecord` à la vente
- `apps/backend/src/shared/transactions/dto/create-transaction.dto.ts` — `serialNumber` par ligne
- `apps/frontend/lib/features/retail/pos/presentation/state/cart_state.dart` — `serialNumber` sur `CartItem`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — déclencher dialog avant checkout
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — onglet Séries
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle trackSerialNumbers

---

## Dev Notes

### Architecture Reference

- `SerialRecord` est défini dans `docs/architecture-scalario-2026-03-08.md` v1.2 (section 4 — shared schema)
- `trackSerialNumbers` est un champ `Boolean @default(false)` sur `CatalogItem` — désactivé par défaut
- Index unique `(tenantId, serial)` est critique : garantit qu'un même numéro de série n'est pas utilisé deux fois dans un tenant
- Le backend NestJS suit le pattern module/service/controller habituel — voir `apps/backend/src/shared/promotions/` pour référence

### Offline Consideration

- La saisie du serial est une opération POS synchrone — elle est bloquée jusqu'à saisie
- La création du `SerialRecord` côté backend se fait à la sync de la transaction outbox (si offline)
- Le champ `serialNumber` est stocké dans les metadata de la transaction Isar pour survie offline

### POS Dialog Pattern

- Utiliser `showDialog<String?>` depuis `CartPanel` avant l'appel à `CheckoutController`
- Si le dialog retourne `null` (annulation), ne pas procéder au checkout
- Le dialog est déclenché pour chaque `CartItem` ayant `product.trackSerialNumbers == true`

### Project Structure

- Backend modules: `apps/backend/src/shared/catalog/serials/`
- Frontend: `apps/frontend/lib/features/shared/catalog/`
- Pattern provider Riverpod: `FutureProvider.family<List<SerialRecord>, String>` (par catalogItemId)

### References

- [Source: docs/architecture-scalario-2026-03-08.md — SerialRecord model definition]
- [Source: _bmad-output/planning-artifacts/prd.md — FR92]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-1]
- [Source: apps/backend/src/shared/promotions/ — module pattern reference]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart — checkout trigger pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
