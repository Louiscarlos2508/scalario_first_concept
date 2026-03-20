# Story 27.4 — Backend — Reservation model + endpoints acompte + completion (FR99)

## Metadata

- **Epic:** Epic 27 — Retours Articles & Réservations
- **Story ID:** 27-4-reservation-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2b
- **Depends on:** Epic 3 (Contact, creditBalance), Epic 4 (Transactions), Epic 5 (InventoryService), Epic 1 (TenantGuard)

---

## Story

**As a** backend developer,
**I want** a `Reservation` model with REST endpoints to create, complete, and cancel reservations with partial deposit logic,
**So that** the POS can offer deposit-based reservations with full lifecycle management (FR99).

---

## Acceptance Criteria

### AC1 — Migration Prisma Reservation

**Given** le fichier `schema.prisma` est mis à jour
**When** la migration est appliquée
**Then** la table `reservations` existe dans le schéma `shared` avec les colonnes :
- `id` (uuid, PK)
- `customer_id` (uuid, FK vers contacts)
- `items_json` (jsonb)
- `total_amount` (Decimal 10,2)
- `deposit_amount` (Decimal 10,2)
- `remaining_amount` (Decimal 10,2)
- `status` (varchar, default `'pending'`)
- `deposit_transaction_id` (uuid nullable)
- `completion_transaction_id` (uuid nullable)
- `tenant_id` (uuid)
- `created_by` (uuid)
- `created_at` (timestamptz, default now())
- `completed_at` (timestamptz nullable)

**And** les index `(tenant_id, status)` et `(customer_id)` sont présents
**And** `@@map("reservations")` et `@@schema("shared")` sont appliqués

### AC2 — POST /api/v1/reservations — création avec acompte

**Given** un commercial authentifié envoie `POST /api/v1/reservations` avec `{ customerId, items: [...], totalAmount, depositAmount }`
**When** `depositAmount >= 10 %` et `<= 50 %` de `totalAmount`
**Then** une `Reservation` est créée avec `status = "pending"`, `remainingAmount = totalAmount - depositAmount`
**And** une `Transaction` de type `"reservation_deposit"` est créée pour l'acompte encaissé
**And** `depositTransactionId` pointe vers cette transaction
**And** la réponse est `201 Created` avec la réservation complète

**When** `depositAmount < 10 %` ou `> 50 %` de `totalAmount`
**Then** le backend répond `400 Bad Request` : `"L'acompte doit être compris entre 10 % et 50 % du total"`

**When** `customerId` n'existe pas dans le tenant
**Then** le backend répond `404 Not Found` : `"Client introuvable"`

### AC3 — PATCH /api/v1/reservations/:id/complete — finalisation paiement

**Given** une réservation est en statut `pending` et appartient au tenant courant
**When** un commercial envoie `PATCH /api/v1/reservations/:id/complete` avec `{ paymentMethod, amount }`
**And** `amount >= reservations.remainingAmount`
**Then** `status` passe à `"completed"` et `completedAt` est renseigné
**And** une `Transaction` de type `"reservation_completion"` est créée
**And** `completionTransactionId` est mis à jour
**And** le stock des articles (`items_json`) est décrémenté via `InventoryService.recordMovement({ type: 'SALE' })`
**And** la réponse est `200 OK` avec la réservation mise à jour

**When** la réservation est déjà `completed` ou `cancelled`
**Then** le backend répond `400 Bad Request` : `"Cette réservation ne peut plus être modifiée"`

**When** `amount < remainingAmount`
**Then** le backend répond `400 Bad Request` : `"Le montant est insuffisant pour solder la réservation"`

### AC4 — PATCH /api/v1/reservations/:id/cancel — annulation

**Given** une réservation est en statut `pending`
**When** un owner ou manager envoie `PATCH /api/v1/reservations/:id/cancel` avec `{ depositResolution: "credit_note" | "cash_refund" }`
**Then** `status` passe à `"cancelled"`

**And** si `depositResolution = "credit_note"` :
- `Contact.creditBalance` du client est incrémenté de `depositAmount`

**And** si `depositResolution = "cash_refund"` :
- Une `Transaction` de type `"reservation_refund"` est créée pour trace d'audit

**And** la réponse est `200 OK` avec la réservation mise à jour

**When** un `commercial` tente d'annuler (pas owner/manager)
**Then** le backend répond `403 Forbidden`

### AC5 — GET /api/v1/reservations — liste paginée

**Given** un manager ou owner appelle `GET /api/v1/reservations`
**When** la requête est valide
**Then** la réponse retourne les réservations paginées du tenant (`?page=1&limit=20`)
**And** le filtre `?status=pending|completed|cancelled` fonctionne
**And** le filtre `?customerId=:id` retourne les réservations d'un client spécifique

### AC6 — GET /api/v1/reservations/kpi — KPI dashboard

**Given** un owner ou manager appelle `GET /api/v1/reservations/kpi`
**When** la requête est valide
**Then** la réponse retourne :
```json
{ "pendingCount": N, "totalDepositAmount": X }
```
**Where** `pendingCount` est le nombre de réservations `pending` du tenant
**And** `totalDepositAmount` est la somme des `deposit_amount` des réservations `pending`

### AC7 — Isolation tenant

**Given** un utilisateur appelle n'importe quel endpoint `/reservations`
**When** la requête est traitée
**Then** seules les réservations du tenant de l'utilisateur sont accessibles ou modifiées

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma** (AC1)
  - [ ] Ajouter le modèle `Reservation` complet dans `schema.prisma` (schéma `shared`)
  - [ ] Vérifier si `Contact` a un champ `creditBalance Decimal @default(0)` — l'ajouter si absent (micro-migration incluse)
  - [ ] Générer et valider la migration SQL
  - [ ] Vérifier `@@schema("shared")`, `@@map("reservations")`, les deux index

- [ ] **Task 2 — DTOs** (AC2, AC3, AC4)
  - [ ] `create-reservation.dto.ts` :
    - `customerId: string @IsUUID()`
    - `items: ReservationItemDto[] @IsArray() @ValidateNested()`
    - `totalAmount: number @IsPositive()`
    - `depositAmount: number @IsPositive()`
    - `paymentMethod: string @IsString()`
  - [ ] `ReservationItemDto` : `catalogItemId`, `variantId?`, `quantity`, `unitPrice`
  - [ ] `complete-reservation.dto.ts` : `paymentMethod: string`, `amount: number`
  - [ ] `cancel-reservation.dto.ts` : `depositResolution: 'credit_note' | 'cash_refund'` `@IsIn([...])`

- [ ] **Task 3 — ReservationsService** (AC2, AC3, AC4, AC5, AC6)
  - [ ] `createReservation(tenantId, userId, dto)` :
    - Valider `customerId` existe dans le tenant
    - Valider `10% <= depositAmount <= 50% of totalAmount`
    - Créer `Reservation` + `Transaction("reservation_deposit")`
  - [ ] `completeReservation(tenantId, id, dto)` :
    - Vérifier status `pending`, valider `amount >= remainingAmount`
    - Créer `Transaction("reservation_completion")`
    - Décrémenter stock via `InventoryService.recordMovement` pour chaque item de `items_json`
    - Mettre à jour `status = "completed"`, `completedAt = now()`
  - [ ] `cancelReservation(tenantId, userId, id, dto)` :
    - Vérifier status `pending`
    - Si `credit_note` : `Contact.creditBalance += depositAmount`
    - Si `cash_refund` : créer `Transaction("reservation_refund")`
    - Mettre à jour `status = "cancelled"`
  - [ ] `listReservations(tenantId, filters)` — paginé, filtre status + customerId
  - [ ] `getKpi(tenantId)` — `pendingCount` + `totalDepositAmount`

- [ ] **Task 4 — ReservationsController** (AC2–AC6)
  - [ ] `POST /reservations` — `@UseGuards(JwtAuthGuard, TenantGuard)` — roles: tous
  - [ ] `GET /reservations` — roles: manager, owner
  - [ ] `GET /reservations/kpi` — roles: manager, owner (placer avant `/:id` pour éviter conflit de route)
  - [ ] `PATCH /reservations/:id/complete` — roles: tous
  - [ ] `PATCH /reservations/:id/cancel` — roles: manager, owner (`@Roles('manager', 'owner')`)

- [ ] **Task 5 — ReservationsModule + enregistrement**
  - [ ] Créer `reservations.module.ts` avec imports `PrismaModule`, `InventoryModule`
  - [ ] Ajouter `ReservationsModule` dans `AppModule`

- [ ] **Task 6 — Tests unitaires** (toutes AC)
  - [ ] Test création avec acompte valide → `201`
  - [ ] Test acompte < 10% ou > 50% → `400`
  - [ ] Test completion avec montant suffisant → stock décrémenté
  - [ ] Test completion sur réservation cancelled → `400`
  - [ ] Test annulation credit_note → `Contact.creditBalance` incrémenté
  - [ ] Test annulation par un commercial → `403`
  - [ ] Test KPI → `pendingCount` et `totalDepositAmount` corrects

---

## Files to Create

- `apps/backend/prisma/migrations/20260319110000_add_reservations/migration.sql`
- `apps/backend/src/shared/reservations/reservations.module.ts`
- `apps/backend/src/shared/reservations/reservations.controller.ts`
- `apps/backend/src/shared/reservations/reservations.service.ts`
- `apps/backend/src/shared/reservations/dto/create-reservation.dto.ts`
- `apps/backend/src/shared/reservations/dto/complete-reservation.dto.ts`
- `apps/backend/src/shared/reservations/dto/cancel-reservation.dto.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `Reservation` (shared) + `creditBalance` sur `Contact` si absent
- `apps/backend/src/app.module.ts` — importer `ReservationsModule`
- `apps/backend/src/shared/inventory/inventory.service.ts` — s'assurer que `recordMovement` est public

---

## Dev Notes

### items_json Format

```json
[
  {
    "catalogItemId": "uuid",
    "variantId": "uuid | null",
    "quantity": 2,
    "unitPrice": 15000
  }
]
```
- Stocker le `unitPrice` au moment de la réservation pour éviter les dérives de prix si `dynamicPricing` est actif sur l'article
- Le stock est décrémenté **à la completion**, pas à la création de la réservation

### Contact.creditBalance

- Si ce champ n'existe pas sur `Contact`, l'ajouter dans la migration de cette story : `creditBalance Decimal @default(0) @db.Decimal(12, 2) @map("credit_balance")`
- Cette valeur est distincte du `creditBalance` lié aux ventes à crédit (FR39) — vérifier qu'il ne s'agit pas du même champ avant d'en créer un nouveau

### Transaction Types

- Les nouveaux types `reservation_deposit`, `reservation_completion`, `reservation_refund` s'ajoutent au champ `type` du modèle `Transaction` existant
- Vérifier si `type` est un `enum Prisma` ou un `String` libre — adapter en conséquence
- Si c'est un enum, ajouter les 3 nouvelles valeurs dans la migration

### Route Ordering

- `GET /reservations/kpi` **doit** être déclaré avant `GET /reservations/:id` dans le controller pour éviter que NestJS interprète `"kpi"` comme un UUID

### Offline Consideration

- Les réservations sont **online-only** — pas d'outbox, pas d'Isar
- Le décrémentement stock à la completion est synchrone côté backend

### References

- [Source: docs/architecture-scalario-2026-03-08.md v1.3 — Reservation model]
- [Source: _bmad-output/planning-artifacts/prd.md — FR99]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 27-4]
- [Source: apps/backend/src/shared/returns/ — module pattern (story 27-1)]
- [Source: apps/backend/src/shared/inventory/inventory.service.ts — recordMovement]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
