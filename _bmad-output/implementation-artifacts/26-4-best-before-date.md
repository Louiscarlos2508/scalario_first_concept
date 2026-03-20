# Story 26.4 — Best-Before Date on ProductBatch (FR95)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-4-best-before-date
- **Status:** done
- **Priority:** Medium
- **Depends on:** Epic 24 (ProductBatch, fraîcheur, FreshnessHelper), Epic 21 (réception fournisseur)

---

## Story

**As a** retailer handling perishable goods with a best-before window (wine, cheese, dairy),
**I want** each product batch to optionally carry a best-before date distinct from the expiry date,
**So that** the freshness color code prioritises optimal sale before the best-before date, using expiry as a fallback (FR95).

---

## Acceptance Criteria

### AC1 — Champ bestBeforeDate sur ProductBatch

**Given** le modèle `ProductBatch` existe dans schema.prisma (schema `shared`)
**When** la migration est appliquée
**Then** le champ `bestBeforeDate DateTime? @map("best_before_date") @db.Timestamptz(6)` est présent sur `product_batches`
**And** le champ est nullable — les lots existants sans date de garde ne sont pas affectés
**And** `bestBeforeDate` est distinct et indépendant de `expiresAt` — les deux peuvent coexister

### AC2 — Saisie bestBeforeDate à la réception fournisseur

**Given** l'utilisateur enregistre une réception fournisseur (formulaire de réception)
**When** l'article reçu est du type ayant des lots avec expiry
**Then** un champ optionnel "Date de garde optimale" (date picker) est disponible dans le formulaire de réception
**And** si renseigné, la valeur est sauvegardée comme `bestBeforeDate` sur le `ProductBatch` créé
**And** si non renseigné, le champ reste `null` — le comportement existant (`expiresAt` seul) est inchangé

### AC3 — Priorité bestBeforeDate dans le calcul du code couleur fraîcheur

**Given** un lot a `bestBeforeDate` renseigné
**When** le code couleur fraîcheur est calculé (logique issue d'Epic 24)
**Then** `bestBeforeDate` est utilisé comme date de référence au lieu de `expiresAt`
**And** si `bestBeforeDate` est `null` mais `expiresAt` est renseigné → utiliser `expiresAt` (comportement existant)
**And** si les deux sont `null` → aucun code couleur fraîcheur (comportement existant)
**And** le pourcentage restant est calculé identiquement : `(referenceDate - now) / freshnessWindowDays`

### AC4 — Affichage bestBeforeDate dans l'onglet Fraîcheur

**Given** l'utilisateur ouvre l'onglet Fraîcheur dans `InventoryScreen`
**When** un lot a une `bestBeforeDate` renseignée
**Then** la carte du lot affiche les deux dates distinctement :
  - "Garde optimale : JJ/MM/YYYY" (si `bestBeforeDate != null`)
  - "Expire le : JJ/MM/YYYY" (si `expiresAt != null`)
**And** si seul `expiresAt` est renseigné, seul "Expire le" est affiché (comportement existant)

### AC5 — bestBeforeDate inclus dans les réponses API batch

**Given** `GET /api/v1/inventory/batches` et `GET /api/v1/inventory/batches/expiring` sont appelés
**When** les lots sont retournés
**Then** `bestBeforeDate` est inclus dans la réponse JSON de chaque lot (nullable)
**And** le frontend Dart désérialise `bestBeforeDate` en `DateTime?`

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration bestBeforeDate** (AC1)
  - [ ] Ajouter `bestBeforeDate DateTime? @map("best_before_date") @db.Timestamptz(6)` sur `ProductBatch` dans `schema.prisma`
  - [ ] Générer la migration SQL

- [ ] **Task 2 — InventoryService : inclure bestBeforeDate dans réponses** (AC5)
  - [ ] Dans `apps/backend/src/shared/inventory/inventory.service.ts`, vérifier que `findBatches()` et `findExpiringBatches()` sélectionnent `bestBeforeDate`
  - [ ] Ajouter `bestBeforeDate` dans les DTOs de réponse batch

- [ ] **Task 3 — Formulaire de réception : champ bestBeforeDate** (AC2)
  - [ ] Identifier le widget de formulaire de réception fournisseur (story 16-1 ou 21-3)
  - [ ] Ajouter un `DatePickerField` optionnel "Date de garde optimale" après le champ `expiresAt`
  - [ ] Transmettre `bestBeforeDate` dans le payload `POST /api/v1/inventory/reception`

- [ ] **Task 4 — Modèle Dart ProductBatch** (AC5)
  - [ ] Ajouter `DateTime? bestBeforeDate` sur le modèle Dart `ProductBatch`
  - [ ] Mettre à jour la désérialisation JSON (`fromJson`)

- [ ] **Task 5 — FreshnessHelper : logique de sélection de date** (AC3)
  - [ ] Localiser `FreshnessHelper` (ou équivalent dans le code fraîcheur d'Epic 24)
  - [ ] Modifier la sélection de la date de référence :
    ```dart
    DateTime? referenceDate = batch.bestBeforeDate ?? batch.expiresAt;
    if (referenceDate == null) return null; // pas de code couleur
    ```
  - [ ] Le reste du calcul reste inchangé

- [ ] **Task 6 — Onglet Fraîcheur : affichage bestBeforeDate** (AC4)
  - [ ] Dans le widget de carte de lot (onglet Fraîcheur de `InventoryScreen`), afficher "Garde optimale" si `bestBeforeDate != null`
  - [ ] Format date : `DateFormat('dd/MM/yyyy').format(bestBeforeDate!)`

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_best_before_date/migration.sql`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `bestBeforeDate` sur `ProductBatch`
- `apps/backend/src/shared/inventory/inventory.service.ts` — inclure `bestBeforeDate` dans sélection et réponse
- `apps/backend/src/shared/inventory/dto/` — ajouter `bestBeforeDate` dans les DTOs de réception et réponse
- `apps/frontend/lib/features/shared/inventory/data/models/product_batch.dart` — ajouter `bestBeforeDate`
- `apps/frontend/lib/core/utils/freshness_helper.dart` (ou fichier équivalent) — logique `bestBeforeDate ?? expiresAt`
- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — afficher "Garde optimale"
- `apps/frontend/lib/features/shared/inventory/presentation/widgets/reception_form.dart` (ou équivalent) — champ `bestBeforeDate`

---

## Dev Notes

### Relation avec Epic 24

- Epic 24 implémente la fraîcheur avec `expiresAt` et `freshnessWindowDays` sur `CatalogItem`
- Ce story **étend** la logique existante — ne pas la réécrire
- Localiser `FreshnessHelper` (chercher `expiresAt` dans le code frontend pour trouver le bon fichier)
- La modification est minimaliste : remplacer `batch.expiresAt` par `batch.bestBeforeDate ?? batch.expiresAt`

### Architecture Reference

- `bestBeforeDate` est défini dans `docs/architecture-scalario-2026-03-08.md` v1.2 (ProductBatch model)
- Le champ est adjacent à `expiresAt` dans la migration pour cohérence de lecture

### Backend Réception

- L'endpoint de réception est probablement dans `apps/backend/src/shared/inventory/inventory.controller.ts`
- Chercher le handler `POST /inventory/reception` ou `POST /inventory/batches` pour identifier le DTO à modifier

### Offline

- `ProductBatch` est probablement synchronisé via delta sync (Epic 8) — `bestBeforeDate` sera inclus automatiquement si le modèle Dart est mis à jour
- Vérifier que le modèle Isar correspondant inclut `bestBeforeDate` si `ProductBatch` est stocké dans Isar

### References

- [Source: docs/architecture-scalario-2026-03-08.md — ProductBatch.bestBeforeDate]
- [Source: _bmad-output/planning-artifacts/prd.md — FR95]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-4]
- [Source: Epic 24 implementation — FreshnessHelper, batch freshness logic]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
