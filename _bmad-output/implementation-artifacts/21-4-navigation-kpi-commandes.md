# Story 21.4 — Navigation hub inventaire + KPI "Commandes en attente"

## Metadata

- **Epic:** Epic 21 — Commandes fournisseurs + réception liée
- **Story ID:** 21-4-navigation-kpi-commandes
- **Status:** done
- **Priority:** Medium
- **Depends on:** 21-2, 21-3 (écrans commandes disponibles)

---

## Story

**As a** manager or owner,
**I want** purchase orders accessible from the inventory hub and visible as a dashboard KPI,
**So that** pending deliveries are never missed (FR79).

---

## Acceptance Criteria

### AC1 — Onglet "Commandes" dans le hub inventaire

**Given** l'utilisateur ouvre le hub inventaire (`InventoryScreen`)
**When** les onglets s'affichent
**Then** un onglet "Commandes" est ajouté aux onglets existants (Réceptions · Transferts · Pertes · Inventaire)
**And** l'onglet "Commandes" charge `PurchaseOrdersScreen`
**And** si des commandes sont en statut `confirmed` ou `partially_received`, un badge numérique rouge apparaît sur l'onglet

### AC2 — KPI dashboard "Commandes en attente"

**Given** le dashboard backoffice (`DashboardScreen`) est chargé
**When** la section KPI s'affiche
**Then** une card "Commandes en attente" affiche le nombre de POs avec `status IN ('confirmed', 'partially_received')`
**And** tapper la card navigue vers `InventoryScreen` avec l'onglet "Commandes" sélectionné et filtre "Confirmé" actif
**And** si le count = 0, la card affiche "0" sans masquer la card (visibilité permanente)

### AC3 — Endpoint KPI backend

**Given** `GET /api/v1/purchase-orders/stats` est appelé
**When** le backend répond
**Then** la réponse inclut `{ pendingCount: number }` — count des POs `confirmed` + `partially_received` pour le tenant
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

### AC4 — Refresh automatique

**Given** le dashboard est visible
**When** une réception est enregistrée (Story 21-3 AC4)
**Then** le provider du KPI est invalidé et le count se met à jour automatiquement

---

## Tasks/Subtasks

- [ ] **Task 1 : Backend — endpoint stats**
  - [ ] Ajouter `GET /purchase-orders/stats` dans `purchase-orders.controller.ts`
  - [ ] Retourner `{ pendingCount }` depuis le service

- [ ] **Task 2 : Frontend — onglet "Commandes" dans InventoryScreen**
  - [ ] Ajouter onglet "Commandes" dans `inventory_screen.dart`
  - [ ] Charger `PurchaseOrdersScreen` dans l'onglet
  - [ ] Badge rouge sur l'onglet si `pendingCount > 0`
  - [ ] Masquer l'onglet pour le rôle `commercial`

- [ ] **Task 3 : Frontend — KPI card dashboard**
  - [ ] Créer `purchaseOrdersStatsProvider` (FutureProvider appelant `/stats`)
  - [ ] Ajouter card "Commandes en attente" dans `DashboardScreen`
  - [ ] Navigation tap → `InventoryScreen` onglet Commandes avec filtre "Confirmé"

- [ ] **Task 4 : Provider stats**
  - [ ] Créer `purchase_orders_stats_provider.dart`
  - [ ] Invalidation après `receivePurchaseOrder()` réussi

---

## Files to Create

- `apps/frontend/lib/features/shared/purchase_orders/presentation/providers/purchase_orders_stats_provider.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/inventory/presentation/screens/inventory_screen.dart` — ajouter onglet Commandes
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — ajouter KPI card
- `apps/backend/src/shared/purchase-orders/purchase-orders.controller.ts` — endpoint stats

## Dev Notes

- Le badge sur l'onglet utilise le même provider que le KPI dashboard (source unique de vérité)
- Rôle requis pour accès commandes : owner ou manager — le commercial ne voit pas l'onglet "Commandes"
