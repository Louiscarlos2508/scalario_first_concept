# Story 26.3 — Prescription Required (FR94)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-3-prescription-required
- **Status:** done
- **Priority:** Medium
- **Depends on:** Epic 2 (CatalogItem), Epic 4 (Transactions)

---

## Story

**As a** pharmacist or regulated-goods retailer,
**I want** certain articles to require a prescription number and prescriber name before checkout,
**So that** I can comply with regulatory requirements and audit prescription-linked sales (FR94).

---

## Acceptance Criteria

### AC1 — Champ requiresPrescription sur CatalogItem

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `requiresPrescription Boolean @default(false) @map("requires_prescription")` est présent sur `catalog_items`
**And** la valeur par défaut est `false` — aucun article existant n'est impacté

### AC2 — Saisie ordonnance obligatoire au POS avant checkout

**Given** un ou plusieurs articles dans le panier POS ont `requiresPrescription = true`
**When** le caissier appuie sur "Valider" dans `CartPanel`
**Then** une `AlertDialog` s'ouvre avec deux champs obligatoires :
  - "Numéro d'ordonnance" (texte libre, ex: "ORD-2026-00123")
  - "Nom du prescripteur" (texte libre, ex: "Dr. Ouédraogo")
**And** le bouton de confirmation est désactivé tant que l'un des deux champs est vide
**And** si l'utilisateur annule, le checkout est annulé (panier reste inchangé)
**And** les valeurs saisies sont stockées dans `CartState.prescriptionData` (nouveau champ)

### AC3 — Enregistrement sur la transaction

**Given** la transaction est finalisée avec des données d'ordonnance
**When** `POST /api/v1/transactions` est appelé
**Then** les champs `prescriptionNumber` et `prescriberName` sont stockés dans le champ `metadata` JSON de la transaction
  - Format : `{ "prescription": { "number": "ORD-…", "prescriber": "Dr. …" } }`
**And** `GET /api/v1/transactions/:id` retourne ces champs dans la réponse (`metadata.prescription`)
**And** si aucun article ne requiert d'ordonnance, `metadata.prescription` est absent

### AC4 — Recherche par numéro d'ordonnance dans l'historique

**Given** l'owner accède à l'historique des transactions (ReportsScreen ou StockHistoryScreen)
**When** il saisit un numéro d'ordonnance dans la barre de recherche
**Then** `GET /api/v1/transactions?prescriptionNumber=ORD-…` filtre les transactions ayant ce numéro dans `metadata.prescription.number`

### AC5 — Toggle requiresPrescription dans ProductFormDialog

**Given** l'owner édite un article dans `ProductFormDialog`
**When** il active "Requiert une ordonnance"
**Then** `requiresPrescription` est mis à `true` via `PATCH /api/v1/catalog/:id`
**And** un texte informatif s'affiche : "Le caissier devra saisir un numéro d'ordonnance à chaque vente"

### AC6 — Les articles sans requiresPrescription ne sont pas affectés

**Given** le panier ne contient que des articles avec `requiresPrescription = false`
**When** le caissier valide le panier
**Then** aucun dialog d'ordonnance n'est affiché — le checkout procède normalement

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration requiresPrescription** (AC1)
  - [ ] Ajouter `requiresPrescription Boolean @default(false) @map("requires_prescription")` sur `CatalogItem`
  - [ ] Générer la migration SQL

- [ ] **Task 2 — Endpoint transactions avec filtre prescription** (AC3 + AC4)
  - [ ] Vérifier que le champ `metadata Json?` existe sur le modèle `Transaction` dans schema.prisma — sinon l'ajouter
  - [ ] Dans `TransactionsService.createTransaction()`, si `prescriptionData` est dans le DTO, stocker dans `metadata.prescription`
  - [ ] Dans `TransactionsService.listTransactions()`, ajouter filtre `?prescriptionNumber=` via `WHERE metadata->'prescription'->>'number' ILIKE '%query%'` (raw query ou jsonPath Prisma)

- [ ] **Task 3 — DTO CreateTransaction** (AC3)
  - [ ] Ajouter `prescriptionNumber?: string` et `prescriberName?: string` à `CreateTransactionDto`

- [ ] **Task 4 — PrescriptionInputDialog Flutter** (AC2)
  - [ ] Créer `prescription_input_dialog.dart` :
    - `showPrescriptionDialog(BuildContext context) → Future<PrescriptionData?>`
    - `PrescriptionData { String number, String prescriberName }`
    - Deux `TextFormField` obligatoires
  - [ ] Ajouter `PrescriptionData? prescriptionData` sur `CartState`
  - [ ] Dans `CartPanel`, avant checkout, vérifier si `items.any((i) => i.product.requiresPrescription == true)` → ouvrir dialog
  - [ ] Inclure `prescriptionData` dans le payload de transaction

- [ ] **Task 5 — Toggle dans ProductFormDialog** (AC5)
  - [ ] Ajouter `SwitchListTile` "Requiert une ordonnance"
  - [ ] Envoyer `PATCH /api/v1/catalog/:id` avec `{ requiresPrescription: true/false }`

- [ ] **Task 6 — Filtre ordonnance dans l'historique** (AC4)
  - [ ] Modifier la page historique/rapports pour accepter un filtre `prescriptionNumber`
  - [ ] Ajouter champ de recherche dans `StockHistoryScreen` ou `ReportsScreen`

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_requires_prescription/migration.sql`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/prescription_input_dialog.dart`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `requiresPrescription` sur `CatalogItem`, vérifier `metadata` sur `Transaction`
- `apps/backend/src/shared/transactions/transactions.service.ts` — stocker prescription dans metadata + filtre
- `apps/backend/src/shared/transactions/dto/create-transaction.dto.ts` — `prescriptionNumber`, `prescriberName`
- `apps/frontend/lib/features/retail/pos/presentation/state/cart_state.dart` — `prescriptionData` sur `CartState`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — déclencher PrescriptionInputDialog
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle requiresPrescription
- `apps/frontend/lib/features/shared/reports/presentation/screens/reports_screen.dart` ou historique — filtre ordonnance

---

## Dev Notes

### Stockage des données ordonnance

- Les données d'ordonnance sont stockées dans le champ `metadata Json?` de la `Transaction` — pas de table dédiée
- Prisma supporte `JsonValue` avec accès via `Prisma.JsonObject` — utiliser `metadata` existant ou l'ajouter si absent
- Pour le filtre Prisma sur JSON : utiliser `{ path: ["prescription", "number"], string_contains: query }` (Prisma JsonFilter)

### Dialogue POS

- Le dialog est déclenché **une seule fois** même si plusieurs articles requiresPrescription sont dans le panier
- L'ordonnance s'applique à l'ensemble du panier, pas par article
- Pattern similaire à `serial_input_dialog.dart` (story 26-1) — réutiliser la structure

### Sécurité & Conformité

- Cette fonctionnalité est **optionnelle par tenant** — `requiresPrescription = false` par défaut
- Pas d'intégration avec un registre national d'ordonnances pour cette phase
- Le numéro d'ordonnance est une chaîne libre — validation de format laissée à l'appréciation du tenant

### CartState Extension

- `CartState` reçoit `PrescriptionData? prescriptionData` (classe simple Dart, non Isar)
- `PrescriptionData` = `{ String number, String prescriberName }` — immutable, passé dans `copyWith()`

### References

- [Source: docs/architecture-scalario-2026-03-08.md — CatalogItem.requiresPrescription]
- [Source: _bmad-output/planning-artifacts/prd.md — FR94]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-3]
- [Source: apps/frontend/lib/features/retail/pos/presentation/state/cart_state.dart — CartState pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
