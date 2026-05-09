# Story 30.3 — Frontend backoffice — Écran liste des commandes clients (FR107, FR110)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-3-client-order-list-screen
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 30-1 (endpoints CRUD + kpis), 30-2 (roleLabels/documentType — optionnel pour cette story)

---

## Story

**As a** owner or manager,
**I want** a "Commandes" screen in the backoffice with a filterable, color-coded list of client orders and contextual action buttons,
**So that** I can monitor all orders and take quick actions without opening each one (FR107, FR110).

---

## Acceptance Criteria

### AC1 — Navigation backoffice vers l'écran Commandes

**Given** l'utilisateur est dans le backoffice
**When** il consulte la navigation principale
**Then** un item "Commandes" est présent dans le menu (après "Réservations" ou dans la section Ventes)
**And** le tap navigue vers `ClientOrdersScreen`

### AC2 — Liste chargée depuis l'API

**Given** `ClientOrdersScreen` s'ouvre
**When** le provider Riverpod charge les données depuis `GET /api/v1/client-orders`
**Then** la liste des commandes du tenant est affichée sous forme de cards
**And** un indicateur de chargement (`CircularProgressIndicator`) est affiché pendant le fetch
**And** un message "Aucune commande pour le moment" est affiché si la liste est vide
**And** un message d'erreur + bouton "Réessayer" est affiché si le chargement échoue

### AC3 — Filtres statut, client, période

**Given** l'utilisateur voit la liste
**When** il utilise la barre de filtres
**Then** il peut filtrer par statut via chips multi-sélection (Brouillon, Confirmée, En cours, Livrée, Annulée)
**And** par client via un champ texte de recherche
**And** par période via un DateRangePicker (date début / date fin)
**And** chaque changement de filtre déclenche un rechargement de la liste (appel API avec query params)

### AC4 — Card commande — informations affichées

**Given** la liste est chargée
**When** une commande est affichée
**Then** la card montre : numéro de commande (CO-XXXX), nom du client, date de création formatée, montant total calculé (somme des lignes), badge statut coloré

### AC5 — Badge statut coloré

**Given** une commande est affichée
**When** le statut est :
- `draft` → badge gris, label "Brouillon"
- `confirmed` → badge bleu, label "Confirmée"
- `in-progress` ou `ready` → badge orange, label "En préparation" / "Prête"
- `delivered` → badge vert, label "Livrée"
- `invoiced` ou `paid` → badge vert foncé, label "Facturée" / "Payée"
- `cancelled` → badge rouge, label "Annulée"
**Then** la couleur et le label correspondants sont affichés

### AC6 — Boutons d'action contextuels sur la card

**Given** la card affiche une commande
**When** le statut est `draft` et le rôle est owner ou manager
**Then** un bouton "Valider" est visible (appelle `POST /:id/confirm` puis refresh)
**When** le statut est `confirmed`
**Then** un bouton "Préparer" est visible (navigue vers l'écran de workflow ou appelle `POST /:id/prepare`)
**When** le statut est `in-progress` ou `ready`
**Then** un bouton "Livrer" est visible (navigue vers `ClientOrderDeliverScreen`)
**When** le statut est `draft` ou `confirmed` et le rôle est owner ou manager
**Then** un bouton "Annuler" est visible (dialog de confirmation → `POST /:id/cancel`)

### AC7 — Navigation vers le détail

**Given** l'utilisateur tape sur le corps de la card (hors boutons d'action)
**When** la navigation s'effectue
**Then** `ClientOrderDetailScreen` s'ouvre pour la commande sélectionnée

---

## Tasks / Subtasks

- [ ] **Task 1 — Modèle Dart ClientOrder** (AC2, AC4)
  - [ ] Créer `client_order.dart` avec les champs : `id`, `orderNumber`, `tenantId`, `customerId`, `customerName` (dénormalisé si disponible), `status`, `depositAmount`, `notes`, `createdAt`, `deliveredAt`, `lines` (`List<ClientOrderLine>`)
  - [ ] Créer `client_order_line.dart` : `id`, `clientOrderId`, `catalogItemId`, `variantId`, `quantity`, `unitPrice`, `deliveredQty`
  - [ ] Ajouter méthodes `fromJson` et `totalAmount` (calculé)

- [ ] **Task 2 — Repository** (AC2, AC3)
  - [ ] Créer `client_order_repository.dart`
  - [ ] Méthode `getOrders({String? status, String? customerId, DateTime? dateFrom, DateTime? dateTo})` → `GET /api/v1/client-orders`
  - [ ] Méthode `confirmOrder(String id)` → `POST /api/v1/client-orders/:id/confirm`
  - [ ] Méthode `cancelOrder(String id)` → `POST /api/v1/client-orders/:id/cancel`
  - [ ] Méthode `prepareOrder(String id)` → `POST /api/v1/client-orders/:id/prepare`

- [ ] **Task 3 — Provider Riverpod** (AC2, AC3)
  - [ ] Créer `client_orders_provider.dart` — `family` provider prenant un `ClientOrdersFilter` en paramètre
  - [ ] `ClientOrdersFilter` : `status`, `customerId`, `dateFrom`, `dateTo`
  - [ ] Le provider appelle `ClientOrderRepository.getOrders()` et expose `AsyncValue<List<ClientOrder>>`

- [ ] **Task 4 — Widget ClientOrderCard** (AC4, AC5, AC6)
  - [ ] Créer `client_order_card.dart` : affiche numéro, client, date, montant, badge statut
  - [ ] Badge statut coloré selon mapping défini en AC5
  - [ ] Boutons d'action conditionnels selon statut et rôle (utiliser `currentUserProvider` pour le rôle)
  - [ ] Callback `onAction` pour découpler la logique d'action du widget

- [ ] **Task 5 — Écran ClientOrdersScreen** (AC1–AC7)
  - [ ] Créer `client_orders_screen.dart`
  - [ ] AppBar avec titre "Commandes" et bouton "+" pour créer une nouvelle commande
  - [ ] Barre de filtres (chips statut + recherche client + date range)
  - [ ] `ListView.builder` avec `ClientOrderCard`
  - [ ] Gestion états loading / empty / error

- [ ] **Task 6 — Navigation backoffice** (AC1)
  - [ ] Ajouter item "Commandes" dans le widget de navigation backoffice existant
  - [ ] Route vers `ClientOrdersScreen`

---

## Files to Create

- `apps/frontend/lib/features/shared/client_orders/domain/models/client_order.dart`
- `apps/frontend/lib/features/shared/client_orders/domain/models/client_order_line.dart`
- `apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/providers/client_orders_provider.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_card.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/screens/client_orders_screen.dart`

## Files to Modify

- Navigation backoffice widget (localiser via Grep `BackofficeNav` ou `navigationItems`) — ajouter item "Commandes"

---

## Dev Notes

### Structure des dossiers

```
lib/features/shared/client_orders/
  domain/models/
    client_order.dart
    client_order_line.dart
  data/
    client_order_repository.dart
  presentation/
    providers/
      client_orders_provider.dart
    screens/
      client_orders_screen.dart        ← cette story
      client_order_detail_screen.dart  ← story 30-5
      client_order_form_screen.dart    ← story 30-4
      client_order_deliver_screen.dart ← story 30-5
    widgets/
      client_order_card.dart
      client_order_document_widget.dart ← story 30-5
```

### totalAmount calculé côté Flutter

```dart
double get totalAmount => lines.fold(0.0, (sum, l) => sum + l.quantity * l.unitPrice);
```

### Rôle pour les boutons d'action

Utiliser le même provider que les autres écrans backoffice (ex: `currentUserProvider` ou `authStateProvider`) pour vérifier si l'utilisateur est `owner` ou `manager` avant d'afficher les boutons "Valider" et "Annuler".

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-3]
- [Source: _bmad-output/planning-artifacts/prd.md — FR107, FR110]
- [Source: apps/backend/src/shared/client-orders/ — endpoints implémentés en Story 30-1]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
N/A — no regressions, flutter analyze passes clean

### Completion Notes List
- ClientOrder + ClientOrderLine domain models with fromJson + totalAmount getter
- ClientOrderRepository: getOrders (with filters), confirmOrder, cancelOrder, prepareOrder
- ClientOrdersProvider: FutureProvider.family<List<ClientOrder>, ClientOrdersFilter> with proper == / hashCode
- ClientOrderCard: colored status badge, contextual action buttons per role + status
- ClientOrdersScreen: status chips, client search, date range picker, loading/empty/error states
- Navigation: "Commandes" item added to dashboard_screen.dart _allNavScreens (moduleCode: 'retail')
- flutter analyze: no issues

### File List
- apps/frontend/lib/features/shared/client_orders/domain/models/client_order_line.dart
- apps/frontend/lib/features/shared/client_orders/domain/models/client_order.dart
- apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart
- apps/frontend/lib/features/shared/client_orders/presentation/providers/client_orders_provider.dart
- apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_card.dart
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_orders_screen.dart
- apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart (modified — Commandes nav item)
