# Story 22.3 — Frontend : Écran alertes + KPI dashboard "Stock critique"

## Metadata

- **Epic:** Epic 22 — Alertes stock bas + notifications
- **Story ID:** 22-3-ecran-alertes-kpi
- **Status:** done
- **Priority:** High
- **Depends on:** 22-1 (endpoint `/stock-alerts` disponible), 22-2 (badge catalogue)

---

## Story

**As a** manager or owner,
**I want** a dedicated low-stock alerts screen and a persistent dashboard KPI,
**So that** I can act quickly on replenishment decisions without scanning the full catalog (FR82).

---

## Acceptance Criteria

### AC1 — KPI "Stock critique" sur le dashboard

**Given** le dashboard backoffice (`DashboardScreen`) est chargé
**When** la section KPI s'affiche
**Then** une card "Stock critique" affiche le nombre d'articles sous seuil (`criticalCount` de `GET /api/v1/stock-alerts/count`)
**And** si criticalCount > 0, la card est colorée en orange/rouge (couleur d'alerte)
**And** si criticalCount = 0, la card affiche "0 — Tout va bien" en vert
**And** tapper la card navigue vers `StockAlertsScreen`

### AC2 — Écran StockAlertsScreen

**Given** l'utilisateur navigue vers `StockAlertsScreen`
**When** l'écran se charge
**Then** une liste d'articles sous seuil est affichée, triée par déficit décroissant
**And** chaque item affiche : nom de l'article, stock actuel, seuil configuré, et déficit en rouge
**And** un bouton "Réapprovisionner" sur chaque item navigue vers `CreatePurchaseOrderSheet` pré-rempli avec l'article
**And** si aucune alerte, l'écran affiche un état vide "Aucun stock critique"

### AC3 — Refresh automatique

**Given** l'écran alertes est visible
**When** un mouvement de stock est synchronisé (post-vente, post-perte)
**Then** le provider est invalidé et la liste se rafraîchit automatiquement
**And** si un article repasse au-dessus de son seuil, il disparaît de la liste

### AC4 — Accès rôle

**Given** un utilisateur avec le rôle `commercial` accède au dashboard
**When** le dashboard s'affiche
**Then** la card KPI "Stock critique" est masquée (visible uniquement pour `owner` et `manager`)

---

## Tasks/Subtasks

- [ ] **Task 1 : StockAlertsRepository**
  - [ ] `getAlerts({limit, offset})` → `GET /api/v1/stock-alerts`
  - [ ] `getCount()` → `GET /api/v1/stock-alerts/count`

- [ ] **Task 2 : Provider Riverpod**
  - [ ] `stockAlertsProvider` : `AutoDisposeFutureProvider<List<StockAlertDto>>`
  - [ ] `stockAlertCountProvider` : `AutoDisposeFutureProvider<int>`

- [ ] **Task 3 : StockAlertsScreen**
  - [ ] Liste triée par déficit décroissant
  - [ ] Chaque item : nom article, stock actuel, seuil, déficit en rouge
  - [ ] Bouton "Réapprovisionner" → navigation vers `CreatePurchaseOrderSheet` (Epic 21)
  - [ ] État vide "Aucun stock critique"
  - [ ] Pull-to-refresh

- [ ] **Task 4 : KPI card dans DashboardScreen**
  - [ ] `stockAlertCountProvider` pour le count
  - [ ] Card colorée orange/rouge si criticalCount > 0, vert si = 0
  - [ ] Masquer pour rôle commercial
  - [ ] Navigation tap → `StockAlertsScreen`

---

## Files to Create

- `apps/frontend/lib/features/shared/stock_alerts/presentation/screens/stock_alerts_screen.dart`
- `apps/frontend/lib/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart`
- `apps/frontend/lib/features/shared/stock_alerts/data/repositories/stock_alerts_repository.dart`

## Files to Modify

- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — KPI "Stock critique"

## Dev Notes

- `StockAlertsScreen` dans `apps/frontend/lib/features/shared/stock_alerts/presentation/screens/`
- Provider : `stockAlertsProvider` (Riverpod AutoDisposeFutureProvider)
- Le bouton "Réapprovisionner" nécessite Epic 21 complété (navigation vers CreatePurchaseOrderSheet)
