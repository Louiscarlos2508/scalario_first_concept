# Story 24.3 — Frontend : Onglet Fraîcheur dans InventoryScreen + action déclasser

## Metadata

- **Epic:** Epic 24 — Fraîcheur + code couleur priorité vente
- **Story ID:** 24-3-onglet-fraicheur
- **Status:** done
- **Priority:** Medium
- **Depends on:** 24-1 (endpoint batches), 24-2 (FreshnessChip)

---

## Story

**As a** manager,
**I want** a dedicated "Fraîcheur" tab in the inventory hub showing all expiring batches, with a declassify action,
**So that** I can proactively manage perishable stock and record natural shrinkage (FR84, FR85).

---

## Acceptance Criteria

### AC1 — Onglet "Fraîcheur" dans InventoryScreen

**Given** l'utilisateur ouvre le hub inventaire (`InventoryScreen`)
**When** les onglets s'affichent
**Then** un onglet "Fraîcheur" est ajouté aux onglets existants
**And** un badge numérique orange/rouge apparaît sur l'onglet si `urgentCount > 0`
**And** l'onglet charge `FreshnessScreen`

### AC2 — FreshnessScreen — liste des lots

**Given** `FreshnessScreen` se charge
**When** les données sont disponibles
**Then** la liste affiche tous les batches actifs avec fraîcheur trackée, triés par `expiresAt` croissant
**And** chaque item affiche : nom de l'article, date d'expiration, jours restants, quantité restante, indicateur couleur
**And** des sections séparent : "Expirés", "Urgents" (rouges non dépassés), "À surveiller" (orange), "OK" (verts)
**And** si aucun batch urgent, l'écran affiche un état vide "Tous vos lots sont frais"

### AC3 — Action "Déclasser" un lot

**Given** l'utilisateur appuie longuement sur un item ou ouvre son menu contextuel
**When** il sélectionne "Déclasser"
**Then** une bottom sheet s'ouvre avec : quantité à déclasser (pré-remplie avec `remainingQty`), motif ("Péremption", "Détérioration qualité", "Variance naturelle")
**And** si le motif = "Variance naturelle" et la quantité ≤ `shrinkageTolerance %`, le formulaire indique "Sera enregistré comme variance naturelle"
**And** à la validation, un mouvement `LOSS` est créé avec le motif sélectionné et le batch est marqué `isDepleted = true`

### AC4 — KPI dashboard "Lots urgents"

**Given** le dashboard backoffice est chargé
**When** la section KPI s'affiche
**Then** une card "Lots urgents" affiche `urgentCount`
**And** si urgentCount > 0, la card est colorée en orange
**And** tapper la card navigue vers `InventoryScreen` avec l'onglet "Fraîcheur" sélectionné

---

## Tasks/Subtasks

- [x] **Task 1 : FreshnessScreen**
  - [x] Créer `apps/frontend/lib/features/shared/freshness/presentation/screens/freshness_screen.dart`
  - [x] Appeler `GET /api/v1/batches/expiring?days=90`
  - [x] Sections : Expirés | Urgents | À surveiller | OK
  - [x] Chaque item avec `FreshnessChip`, nom, date expiration, qté restante
  - [x] État vide "Tous vos lots sont frais"

- [x] **Task 2 : DeclassifySheet**
  - [x] Bottom sheet avec quantité (pré-remplie), dropdown motif
  - [x] Message conditionnel si variance naturelle
  - [x] Submit → `POST /api/v1/inventory/loss` avec motif + marquer batch isDepleted

- [x] **Task 3 : FreshnessProvider**
  - [x] `freshnessProvider` : `FutureProvider<List<BatchDto>>`
  - [x] `urgentCountProvider` : `FutureProvider<int>`

- [x] **Task 4 : InventoryScreen — onglet Fraîcheur**
  - [x] Ajouter onglet "Fraîcheur" dans `inventory_screen.dart`
  - [x] Badge orange si `urgentCount > 0`

- [x] **Task 5 : KPI card dashboard**
  - [x] Card "Lots urgents" dans `DashboardScreen`
  - [x] Navigation tap → `InventoryScreen` onglet Fraîcheur

---

## Files to Create

- `apps/frontend/lib/features/shared/freshness/presentation/screens/freshness_screen.dart`
- `apps/frontend/lib/features/shared/freshness/presentation/widgets/declassify_sheet.dart`
- `apps/frontend/lib/features/shared/freshness/presentation/providers/freshness_provider.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — onglet Fraîcheur
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — KPI "Lots urgents"

## Dev Notes

- Le provider recharge depuis `GET /api/v1/batches/expiring?days=90` (large fenêtre pour tout afficher)
- L'action "Déclasser" réutilise l'endpoint de déclaration de perte existant (`POST /api/v1/inventory/loss`)
