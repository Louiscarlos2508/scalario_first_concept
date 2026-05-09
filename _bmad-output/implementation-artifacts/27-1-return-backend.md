# Story 27.1 — Backend ReturnRecord + endpoints POST/GET + stock réintégré (FR98)

## Metadata

- **Epic:** Epic 27 — Retours Articles & Réservations
- **Story ID:** 27-1-return-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a — bloquant pour tout retail
- **Depends on:** Epic 5 (InventoryService.recordMovement), Epic 4 (Transactions), Epic 1 (TenantGuard, JwtAuthGuard)

---

## Story

**As a** backend developer,
**I want** a `ReturnRecord` model, REST endpoints to create and query returns, automatic stock reinstatement, and tenant return-policy enforcement,
**So that** the POS can process article returns with full audit trail and configurable business rules (FR98).

---

## Acceptance Criteria

### AC1 — Migration Prisma ReturnRecord

**Given** le fichier `schema.prisma` est mis à jour
**When** la migration est appliquée
**Then** la table `return_records` existe dans le schéma `shared` avec les colonnes : `id`, `transaction_id`, `catalog_item_id`, `variant_id` (nullable), `quantity`, `reason` (nullable), `resolution`, `approved_by` (nullable), `tenant_id`, `created_by`, `created_at`
**And** les index `(tenant_id, transaction_id)` sont présents
**And** `@@map("return_records")` et `@@schema("shared")` sont appliqués

### AC2 — Champs politique retour sur Tenant

**Given** la migration est appliquée
**When** on inspecte la table `tenants`
**Then** les colonnes suivantes sont présentes :
- `return_policy_days` (int nullable, default 30)
- `return_requires_reason` (bool, default true)
- `return_requires_approval` (bool, default false)

### AC3 — POST /api/v1/returns — création retour

**Given** un commercial authentifié envoie `POST /api/v1/returns` avec `{ transactionId, catalogItemId, quantity, reason?, resolution }`
**When** la transaction originale existe et appartient au même tenant
**And** la date de la transaction est dans la fenêtre `returnPolicyDays` du tenant
**And** `reason` est fourni si `returnRequiresReason = true`
**Then** un `ReturnRecord` est créé en base avec `createdBy = userId`
**And** un `StockMovement` de type `RETURN` est créé pour réintégrer la quantité dans le stock
**And** la réponse est `201 Created` avec le `ReturnRecord` complet

### AC4 — Validation politique retour

**Given** un commercial envoie `POST /api/v1/returns`

**When** la date de vente originale dépasse `returnPolicyDays` du tenant
**Then** le backend répond `400 Bad Request` : `"La période de retour autorisée est expirée"`

**When** `returnRequiresReason = true` et `reason` est absent ou vide
**Then** le backend répond `400 Bad Request` : `"Un motif est obligatoire pour les retours"`

**When** `returnRequiresApproval = true` et `approvedBy` est absent
**Then** le backend répond `403 Forbidden` : `"L'approbation d'un manager est requise"`

### AC5 — GET /api/v1/returns — liste des retours

**Given** un manager ou owner authentifié appelle `GET /api/v1/returns`
**When** la requête est valide
**Then** la réponse est `200 OK` avec la liste paginée des `ReturnRecord` du tenant
**And** le filtre optionnel `?transactionId=:id` retourne uniquement les retours de cette transaction
**And** le filtre `?page=1&limit=20` fonctionne

### AC6 — Isolation tenant

**Given** un utilisateur appelle `GET /api/v1/returns` ou `POST /api/v1/returns`
**When** la requête est traitée
**Then** seuls les enregistrements du tenant de l'utilisateur sont accessibles ou créés
**And** toute tentative d'accès à un `transactionId` d'un autre tenant retourne `404 Not Found`

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma** (AC1, AC2)
  - [ ] Ajouter le modèle `ReturnRecord` complet dans `schema.prisma` (schéma `shared`)
  - [ ] Ajouter les 3 champs `returnPolicy*` sur le modèle `Tenant` (schéma `kernel`)
  - [ ] Générer et valider la migration SQL
  - [ ] Vérifier que `@@schema("shared")` est bien appliqué sur `ReturnRecord`

- [ ] **Task 2 — ReturnsModule backend** (AC3, AC5, AC6)
  - [ ] Créer `returns.service.ts`
    - `createReturn(tenantId, userId, dto)` — valide politique, crée ReturnRecord + StockMovement RETURN
    - `listReturns(tenantId, filters)` — retourne paginé, filtre par transactionId
    - `getReturnsSummaryForSession(tenantId, openedAt, closedAt)` — utilisé en story 27-3
  - [ ] Créer `returns.controller.ts`
    - `POST /returns` — `@UseGuards(JwtAuthGuard, TenantGuard)`
    - `GET /returns` — `@UseGuards(JwtAuthGuard, TenantGuard)` + filtre `?transactionId`
  - [ ] Créer `create-return.dto.ts` avec validation class-validator :
    - `transactionId: string @IsUUID()`
    - `catalogItemId: string @IsUUID()`
    - `variantId?: string @IsOptional() @IsUUID()`
    - `quantity: number @IsPositive()`
    - `reason?: string @IsOptional() @IsString()`
    - `resolution: string @IsIn(['cash_refund', 'credit_note', 'exchange'])`
    - `approvedBy?: string @IsOptional() @IsUUID()`
  - [ ] Enregistrer `ReturnsModule` dans `AppModule`

- [ ] **Task 3 — Validation politique retour dans ReturnsService** (AC4)
  - [ ] Charger le `Tenant` courant pour lire `returnPolicyDays`, `returnRequiresReason`, `returnRequiresApproval`
  - [ ] Vérifier `transaction.createdAt + returnPolicyDays >= now()` → sinon `BadRequestException`
  - [ ] Vérifier `reason` présent si `returnRequiresReason` → sinon `BadRequestException`
  - [ ] Vérifier `approvedBy` présent si `returnRequiresApproval` → sinon `ForbiddenException`

- [ ] **Task 4 — Réintégration stock via InventoryService** (AC3)
  - [ ] Appeler `inventoryService.recordMovement({ type: 'RETURN', catalogItemId, quantity, tenantId, createdBy })`
  - [ ] Vérifier que le type `RETURN` est accepté dans `StockMovementType` enum — l'ajouter si absent
  - [ ] S'assurer que `InventoryService.recordMovement` est `public` (pas `private`)

- [ ] **Task 5 — Tests unitaires ReturnsService** (toutes AC)
  - [ ] Test : création retour dans délai → `201` + StockMovement créé
  - [ ] Test : retour hors délai → `400`
  - [ ] Test : motif manquant quand obligatoire → `400`
  - [ ] Test : approbation manquante quand requise → `403`
  - [ ] Test : isolation tenant — transactionId d'un autre tenant → `404`

---

## Files to Create

- `apps/backend/prisma/migrations/20260319100000_add_return_records/migration.sql`
- `apps/backend/src/shared/returns/returns.module.ts`
- `apps/backend/src/shared/returns/returns.controller.ts`
- `apps/backend/src/shared/returns/returns.service.ts`
- `apps/backend/src/shared/returns/dto/create-return.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `ReturnRecord` (shared) + champs `returnPolicy*` sur `Tenant` (kernel)
- `apps/backend/src/app.module.ts` — importer `ReturnsModule`
- `apps/backend/src/shared/inventory/inventory.service.ts` — exposer `recordMovement` public + type `RETURN`

---

## Dev Notes

### Architecture Reference

- `ReturnRecord` est défini dans `docs/architecture-scalario-2026-03-08.md` v1.3 (shared schema)
- Les 3 champs `returnPolicy*` sont définis sur le modèle `Tenant` (kernel schema)
- Pattern module de référence : `apps/backend/src/shared/promotions/` ou `apps/backend/src/shared/returns/` (à créer sur le même modèle)
- `StockMovementType` enum : vérifier `apps/backend/src/shared/inventory/` pour la liste actuelle des types

### Offline Consideration

- Les retours sont **online-only** : la recherche de transaction originale requiert une connexion
- Aucune persistence Isar côté frontend pour les retours
- Le `StockMovement RETURN` est créé directement en base, sans passer par l'outbox offline

### Resolution Values

- `cash_refund` : remboursement en espèces au client — impacte le cash théorique du Z-report
- `credit_note` : avoir crédité sur `Contact.creditBalance` — TODO loggé (implémenté en FR99/story 27-4)
- `exchange` : échange article — pas de mouvement financier, uniquement stock réintégré

### Project Structure

- Backend module : `apps/backend/src/shared/returns/`
- Le module est dans `shared/` (pas `retail/`) car les retours sont cross-vertical à terme
- Préfixe route : `/api/v1/returns`

### References

- [Source: docs/architecture-scalario-2026-03-08.md v1.3 — ReturnRecord model + Tenant returnPolicy fields]
- [Source: _bmad-output/planning-artifacts/prd.md — FR98]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 27-1]
- [Source: apps/backend/src/shared/promotions/ — module pattern reference]
- [Source: apps/backend/src/shared/inventory/inventory.service.ts — recordMovement pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
