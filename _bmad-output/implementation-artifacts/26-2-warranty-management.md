# Story 26.2 — Warranty Management (FR93)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-2-warranty-management
- **Status:** done
- **Priority:** High
- **Depends on:** Story 26-1 (SerialRecord must exist), Epic 4 (Transactions)

---

## Story

**As a** owner or manager,
**I want** warranty certificates auto-generated at the point of sale for articles with a configured warranty period,
**So that** customers receive a traceable guarantee and can be looked up by warranty number (FR93).

---

## Acceptance Criteria

### AC1 — Champ warrantyMonths sur CatalogItem

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `warrantyMonths Int? @map("warranty_months")` est présent sur `catalog_items`
**And** le champ est nullable — les articles sans garantie configurée ne sont pas affectés
**And** le champ `warrantyUntil DateTime? @map("warranty_until")` est déjà présent sur `SerialRecord` (ajouté en story 26-1)

### AC2 — Calcul automatique de warrantyUntil à la vente

**Given** un article vendu a `warrantyMonths > 0` ET un `SerialRecord` a été créé (story 26-1)
**When** `TransactionsService` finalise la transaction
**Then** `SerialRecord.warrantyUntil` est calculé : `soldAt + warrantyMonths mois` (ajouter les mois via date arithmetic)
**And** la valeur est persistée sur le `SerialRecord` lors de sa création

### AC3 — Numéro de certificat de garantie

**Given** un `SerialRecord` est créé avec `warrantyUntil` renseigné
**When** la transaction est retournée au client
**Then** le backend génère un numéro de certificat : `WAR-<TENANT_CODE>-<SERIAL>-<YYYYMM>`
  - `TENANT_CODE` : 4 premiers caractères du tenantId (ou un code tenant slug si disponible)
  - `SERIAL` : la valeur de `SerialRecord.serial`
  - `YYYYMM` : année et mois de `soldAt`
**And** ce numéro est inclus dans la réponse de `POST /api/v1/transactions` sous `items[].warrantyNumber`
**And** il n'est PAS stocké séparément — il est re-calculé depuis `(serial + soldAt)` à la demande

### AC4 — Section garantie sur le reçu

**Given** la transaction comporte un article avec `warrantyMonths > 0`
**When** le reçu s'affiche dans `ReceiptDialog`
**Then** une section "Garantie" est affichée pour chaque ligne concernée :
  - Nom de l'article
  - Numéro de série (`SerialRecord.serial`)
  - Date de fin de garantie (`warrantyUntil` formatée en `dd/MM/yyyy`)
  - Numéro de certificat (`WAR-…`)
**And** si aucun article n'a de garantie, la section est masquée

### AC5 — Recherche par numéro de garantie

**Given** l'owner cherche un client lié à un article vendu sous garantie
**When** `GET /api/v1/serials?q=<serial>` est appelé (endpoint de story 26-1)
**Then** le `SerialRecord` correspondant est retourné avec `warrantyUntil` et le numéro de certificat re-calculé

### AC6 — Toggle warrantyMonths dans ProductFormDialog

**Given** l'owner édite un article dans `ProductFormDialog`
**When** il active "Durée de garantie" et saisit un nombre de mois (ex: 12)
**Then** `warrantyMonths` est sauvegardé via `PATCH /api/v1/catalog/:id`
**And** la valeur `0` ou champ vide désactive la garantie (warrantyMonths = null)
**And** un texte informatif s'affiche : "Un certificat de garantie sera généré automatiquement à chaque vente"

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration warrantyMonths** (AC1)
  - [ ] Ajouter `warrantyMonths Int? @map("warranty_months")` sur `CatalogItem` dans `schema.prisma`
  - [ ] Générer la migration SQL
  - [ ] Vérifier que `warrantyUntil` est bien sur `SerialRecord` (ajouté en 26-1)

- [ ] **Task 2 — Calcul warrantyUntil dans TransactionsService** (AC2 + AC3)
  - [ ] Dans `createSerialRecord()` (ajouté en story 26-1), si `catalogItem.warrantyMonths > 0` :
    - `warrantyUntil = addMonths(soldAt, warrantyMonths)` — utiliser `date-fns` (`addMonths`)
  - [ ] Inclure dans la réponse transaction `items[].warrantyNumber` calculé

- [ ] **Task 3 — Endpoint GET serial avec warrantyNumber** (AC5)
  - [ ] Dans `SerialsService.searchSerials()`, enrichir la réponse avec `warrantyNumber` calculé si `warrantyUntil != null`

- [ ] **Task 4 — Section garantie dans ReceiptDialog** (AC4)
  - [ ] Modifier `ReceiptDialog` pour afficher une section "Garantie" si au moins un item a `warrantyUntil`
  - [ ] Créer widget `WarrantyReceiptSection` avec les informations garantie par ligne
  - [ ] Le numéro de certificat est calculé client-side depuis `(serial + soldAt)` : `WAR-${tenantCode}-${serial}-${YYYYMM}`

- [ ] **Task 5 — Toggle warrantyMonths dans ProductFormDialog** (AC6)
  - [ ] Ajouter un `SwitchListTile` "Durée de garantie"
  - [ ] Si activé, afficher un `TextFormField` pour saisir le nombre de mois (validé > 0, entier)
  - [ ] Envoyer `PATCH /api/v1/catalog/:id` avec `{ warrantyMonths: N }` ou `{ warrantyMonths: null }`

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_warranty_months/migration.sql`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/warranty_receipt_section.dart`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `warrantyMonths` sur `CatalogItem`
- `apps/backend/src/shared/transactions/transactions.service.ts` — calculer `warrantyUntil`, inclure `warrantyNumber` dans réponse
- `apps/backend/src/shared/catalog/serials/serials.service.ts` — inclure `warrantyNumber` dans recherche
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — section garantie
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — champ warrantyMonths

---

## Dev Notes

### Dependency on Story 26-1

- **Strict prérequis** : `SerialRecord` et le flow de création doivent être opérationnels (story 26-1)
- Ce story ajoute `warrantyUntil` sur `SerialRecord` et `warrantyMonths` sur `CatalogItem`
- Ne pas modifier la structure de `SerialRecord` — le champ `warrantyUntil` est déjà prévu en 26-1

### Date Arithmetic

- Utiliser `date-fns` côté backend (déjà dans les dépendances NestJS habituelles) : `addMonths(new Date(soldAt), warrantyMonths)`
- Côté Flutter, utiliser l'extension `DateTime` standard ou `package:intl` pour le formatage

### Warranty Number Formula

```
WAR-{tenantCode}-{serial}-{YYYYMM}
```
- `tenantCode` : générer depuis `tenantId.substring(0, 4).toUpperCase()` — pas de table séparée
- Cette formule est déterministe : re-calculable sans stockage supplémentaire
- Format final exemple : `WAR-A3F2-IMEI123456-202603`

### ReceiptDialog Pattern

- `ReceiptDialog` reçoit déjà `CartState? cartSnapshot` (ajouté en story 25-7)
- Enrichir `CartItem` avec `warrantyUntil` et `serialNumber` dans le snapshot passé au dialog
- La section garantie n'apparaît que si `cartSnapshot != null && items.any((i) => i.warrantyUntil != null)`

### References

- [Source: docs/architecture-scalario-2026-03-08.md — SerialRecord.warrantyUntil, CatalogItem.warrantyMonths]
- [Source: _bmad-output/planning-artifacts/prd.md — FR93]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-2]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart — cartSnapshot pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
