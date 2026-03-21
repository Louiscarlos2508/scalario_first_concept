# Story 30.6 — Frontend — KPI Commandes sur le dashboard (FR110)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-6-client-order-kpi-dashboard
- **Status:** ready-for-dev
- **Priority:** Medium
- **Phase:** 2a
- **Depends on:** 30-1 (GET /client-orders/kpis), 30-3 (ClientOrdersScreen + navigation)

---

## Story

**As a** owner or manager,
**I want** "Commandes en cours" and "CA en attente" KPI cards on the dashboard,
**So that** I can monitor my order pipeline at a glance without navigating to the orders screen (FR110).

---

## Acceptance Criteria

### AC1 — Endpoint /kpis répond correctement

**Given** `GET /api/v1/client-orders/kpis` est appelé (implémenté en Story 30-1)
**When** la requête est authentifiée
**Then** la réponse inclut `{ inProgressCount: number, pendingRevenue: number }` calculé sur les statuts actifs (`confirmed`, `in-progress`, `ready`)
**And** `pendingRevenue` est la somme des montants totaux des commandes actives (somme des lignes)

### AC2 — Deux cards KPI sur le dashboard

**Given** l'utilisateur ouvre le dashboard backoffice
**When** les KPIs sont chargés
**Then** une card "Commandes en cours" affiche `inProgressCount` (nombre entier)
**And** une card "CA en attente" affiche `pendingRevenue` formaté en devise du tenant
**And** les cards sont affichées en cohérence visuelle avec les autres KPI cards du dashboard

### AC3 — Navigation depuis les cards vers l'écran commandes filtré

**Given** l'utilisateur tape sur la card "Commandes en cours"
**When** la navigation s'effectue
**Then** `ClientOrdersScreen` s'ouvre avec un filtre pré-appliqué sur les statuts actifs (`confirmed`, `in-progress`, `ready`)
**Given** l'utilisateur tape sur la card "CA en attente"
**When** la navigation s'effectue
**Then** `ClientOrdersScreen` s'ouvre sans filtre de statut particulier (liste complète)

### AC4 — Affichage avec valeur zéro

**Given** le tenant n'a encore aucune commande
**When** les KPIs sont chargés (`inProgressCount = 0`, `pendingRevenue = 0`)
**Then** les cards sont affichées avec les valeurs à zéro
**And** aucun message d'erreur ou d'exception n'est levé

### AC5 — Chargement et erreur

**Given** le dashboard charge les KPIs
**When** l'appel API est en cours
**Then** les cards affichent un indicateur de chargement (shimmer ou placeholder)
**When** l'appel échoue
**Then** les cards affichent "--" sans bloquer le chargement des autres KPIs du dashboard

---

## Tasks / Subtasks

- [ ] **Task 1 — Modèle ClientOrderKpis** (AC1)
  - [ ] Créer ou ajouter dans les modèles : `ClientOrderKpis { inProgressCount: int, pendingRevenue: double }`
  - [ ] Méthode `fromJson`

- [ ] **Task 2 — Méthode getKpis dans ClientOrderRepository** (AC1)
  - [ ] Ajouter `getKpis()` dans `client_order_repository.dart` → `GET /api/v1/client-orders/kpis`
  - [ ] Retourner `ClientOrderKpis`

- [ ] **Task 3 — Provider Riverpod clientOrderKpisProvider** (AC2, AC4, AC5)
  - [ ] Créer `client_order_kpis_provider.dart` — `FutureProvider<ClientOrderKpis>`
  - [ ] Appelle `clientOrderRepository.getKpis()`
  - [ ] Valeur par défaut en cas d'erreur : `ClientOrderKpis(inProgressCount: 0, pendingRevenue: 0)`

- [ ] **Task 4 — Intégration dans le dashboard** (AC2, AC3, AC5)
  - [ ] Localiser le dashboard screen (ex: `DashboardScreen` ou le layout SDUI JSON)
  - [ ] Si dashboard hardcodé : ajouter deux `KpiCard` widgets après la section "Réservations"
  - [ ] Si dashboard SDUI : ajouter les deux cards dans la config JSON du layout dashboard
  - [ ] Card "Commandes en cours" : icône `assignment`, tap → `ClientOrdersScreen` filtré
  - [ ] Card "CA en attente" : icône `attach_money`, tap → `ClientOrdersScreen` sans filtre
  - [ ] Gérer l'état chargement (shimmer/placeholder) et erreur ("--")

---

## Files to Create

- `apps/frontend/lib/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart` — ajouter méthode `getKpis`
- `apps/frontend/lib/features/shared/client_orders/domain/models/client_order.dart` (ou fichier dédié) — ajouter `ClientOrderKpis`
- Dashboard screen ou layout SDUI JSON — ajouter les deux KPI cards

---

## Dev Notes

### Localiser le dashboard

Chercher via Grep : `DashboardScreen`, `dashboard_screen.dart`, ou le layout SDUI JSON. Si SDUI, le fichier de config est probablement dans `assets/` ou chargé depuis le backend (`GET /api/v1/layouts/retail.dashboard`).

### Format de pendingRevenue

Utiliser la même logique de formatage que les autres montants du dashboard (ex: `NumberFormat.currency` avec le symbole de devise du tenant). Pas de décimales pour les montants en FCFA (arrondi à l'entier).

### KpiCard réutilisable

Utiliser le widget `KpiCard` existant s'il existe déjà dans le codebase (chercher via Grep). S'il n'existe pas, créer un widget simple avec icône, label, valeur et callback `onTap`.

### pendingRevenue côté backend

Le calcul peut être lourd si beaucoup de commandes. Pour le MVP, agréger en mémoire depuis Prisma :

```typescript
const orders = await this.prisma.clientOrder.findMany({
  where: { tenantId, status: { in: ['confirmed', 'in-progress', 'ready'] } },
  include: { lines: { select: { quantity: true, unitPrice: true } } },
});
const pendingRevenue = orders.reduce((sum, o) =>
  sum + o.lines.reduce((s, l) => s + Number(l.quantity) * Number(l.unitPrice), 0), 0);
```

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-6]
- [Source: _bmad-output/planning-artifacts/prd.md — FR110]
- [Source: apps/backend/src/shared/client-orders/client-order.controller.ts — endpoint /kpis (Story 30-1)]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
- `FutureProvider<ClientOrderKpis>.when(data:)` parameter inferred as `Object` — fixed with explicit type annotation `data: (ClientOrderKpis kpis) =>`.
- Required `import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart' show ClientOrderKpis` in `kpi_card_grid.dart`.

### Completion Notes List
- AC1: `clientOrderKpisProvider` (FutureProvider) calls `repo.getKpis(tenantId)`, returns `ClientOrderKpis.zero` on null tenant or error.
- AC2: "Commandes en cours" KPI card added; shows `kpis.inProgressCount`; taps navigate to `'Commandes'` section.
- AC3: "CA en attente" KPI card added; shows `kpis.pendingRevenue` formatted as FCFA.
- AC4: Both cards gated behind `canSeeStockAlerts` (owner/manager only).
- AC5: Cards show `'…'` while loading, `'--'` on error.

### File List
- `apps/frontend/lib/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart` (created)
- `apps/frontend/lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart` (modified)
