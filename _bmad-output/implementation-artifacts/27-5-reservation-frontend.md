# Story 27.5 — Frontend — Écran réservations, formulaire acompte POS, KPI dashboard (FR99)

## Metadata

- **Epic:** Epic 27 — Retours Articles & Réservations
- **Story ID:** 27-5-reservation-frontend
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2b
- **Depends on:** 27-4-reservation-backend (tous endpoints), Epic 8 (ConnectivityService), Epic 7 (DashboardScreen, KpiCardGrid)

---

## Story

**As a** commercial or owner,
**I want** to create a reservation with deposit from the POS, view active reservations from the backoffice, complete or cancel them, and see a live KPI on the dashboard,
**So that** reservation workflows are fully managed without paper or external tools (FR99).

---

## Acceptance Criteria

### AC1 — Bouton "Réservation" dans le POS

**Given** le commercial a des articles dans le panier POS
**When** il appuie sur "Réservation" (bouton alternatif à "Encaisser", placé dans `CartPanel`)
**Then** un dialogue `ReservationDepositDialog` s'ouvre avec :
- Sélecteur client (autocomplete sur `Contact`, champ obligatoire)
- Montant total pré-rempli depuis le total du panier (non modifiable)
- Champ acompte (défaut : 30 % du total, modifiable par le commercial)
- Indicateur temps réel : "Acompte : X FCFA — Solde restant : Y FCFA"
- Bouton "Confirmer la réservation" (activé uniquement si client sélectionné)

**When** le POS est hors ligne
**Then** le bouton "Réservation" est désactivé avec `Tooltip` : "Nécessite une connexion Internet"

### AC2 — Validation acompte côté UI

**Given** le commercial saisit un acompte dans `ReservationDepositDialog`
**When** la valeur saisie est < 10 % ou > 50 % du montant total
**Then** un `errorText` rouge s'affiche sous le champ : "L'acompte doit être entre 10 % et 50 % du total"
**And** le bouton "Confirmer la réservation" est désactivé

**When** la valeur est dans la plage valide
**Then** l'indicateur "Solde restant" se met à jour en temps réel

### AC3 — Confirmation et reçu d'acompte

**Given** le commercial valide la réservation dans `ReservationDepositDialog`
**When** `POST /api/v1/reservations` répond `201 Created`
**Then** le dialogue se ferme
**And** le panier POS est vidé (comme après une vente normale)
**And** un `ReceiptDialog` adapté s'affiche avec :
- En-tête : "RÉSERVATION — ACOMPTE"
- Numéro de réservation
- Nom du client
- Montant total, acompte encaissé, solde restant
**And** un `SnackBar` confirme : "Réservation créée — Solde restant : Y FCFA"

**When** le backend répond avec une erreur
**Then** le message d'erreur s'affiche dans le dialogue (bandeau rouge)
**And** le panier n'est pas vidé

### AC4 — Écran liste des réservations (backoffice)

**Given** le manager ou owner navigue vers "Réservations" dans le menu backoffice
**When** l'écran `ReservationsScreen` s'affiche
**Then** un `TabBar` avec 3 onglets s'affiche : "En cours", "Complétées", "Annulées"

**When** l'onglet "En cours" est actif
**Then** la liste des réservations `pending` s'affiche avec pour chaque réservation :
- Nom du client
- Date de création
- Montant total
- Acompte versé
- Solde restant (mis en évidence)
- Deux boutons : "Compléter" et "Annuler"

**When** un onglet "Complétées" ou "Annulées" est sélectionné
**Then** la liste filtrée correspondante s'affiche (actions désactivées)

### AC5 — Compléter le paiement

**Given** le manager appuie sur "Compléter" d'une réservation `pending`
**When** un dialogue `CompleteReservationDialog` s'affiche
**Then** le solde restant est pré-rempli et non modifiable
**And** un sélecteur de mode de paiement est affiché (cash, mobile money)
**And** le manager confirme

**When** `PATCH /api/v1/reservations/:id/complete` répond `200`
**Then** la réservation disparaît de l'onglet "En cours" et apparaît dans "Complétées"
**And** un `SnackBar` confirme : "Paiement completé — Réservation clôturée"
**And** un reçu final est affiché

### AC6 — Annuler une réservation

**Given** le manager appuie sur "Annuler" d'une réservation `pending`
**When** un `AlertDialog` de confirmation s'affiche avec deux options `RadioListTile` :
- "Rembourser l'acompte en cash"
- "Convertir en avoir client"
**And** le manager sélectionne une option et confirme

**Then** `PATCH /api/v1/reservations/:id/cancel` est appelé avec `depositResolution`
**And** la réservation passe dans l'onglet "Annulées"
**And** un `SnackBar` confirme l'action : "Réservation annulée — [option choisie]"

### AC7 — Solde restant sur la fiche client

**Given** un client a une ou plusieurs réservations `pending`
**When** l'owner ou manager consulte la fiche du contact (écran existant)
**Then** une section "Réservations en cours" s'affiche avec :
- Nombre de réservations pending
- Montant total des soldes restants
- Lien "Voir les réservations" → navigue vers `ReservationsScreen` filtré sur ce client

### AC8 — KPI "Réservations en cours" sur le dashboard

**Given** le dashboard est chargé
**When** `GET /api/v1/reservations/kpi` répond avec `{ pendingCount, totalDepositAmount }`
**Then** une `KpiCard` s'affiche avec :
- Titre : "Réservations en cours"
- Valeur principale : `pendingCount`
- Sous-texte : "Acomptes : X FCFA"
**And** un tap sur la carte navigue vers `ReservationsScreen` filtré sur `pending`

**When** `pendingCount == 0`
**Then** la `KpiCard` s'affiche quand même avec la valeur 0 (pas masquée)

---

## Tasks / Subtasks

- [ ] **Task 1 — ReservationsRepository** (AC3, AC4, AC5, AC6, AC8)
  - [ ] Créer `reservations_repository.dart` avec :
    - `createReservation(dto)` → `Future<Reservation>`
    - `listReservations({ status?, customerId?, page, limit })` → `Future<List<Reservation>>`
    - `completeReservation(id, dto)` → `Future<Reservation>`
    - `cancelReservation(id, dto)` → `Future<Reservation>`
    - `getKpi()` → `Future<ReservationKpi>`
  - [ ] Modèle `Reservation` Dart : `id`, `customerId`, `customerName`, `itemsJson`, `totalAmount`, `depositAmount`, `remainingAmount`, `status`, `createdAt`, `completedAt?`
  - [ ] Modèle `ReservationKpi` Dart : `pendingCount`, `totalDepositAmount`

- [ ] **Task 2 — Providers Riverpod**
  - [ ] `reservationsRepositoryProvider` → singleton dans `pos_providers.dart`
  - [ ] `reservationsListProvider(status)` → `FutureProvider.family<List<Reservation>, String>`
  - [ ] `reservationsKpiProvider` → `FutureProvider<ReservationKpi>`
  - [ ] Invalider les providers après create/complete/cancel via `ref.invalidate(...)`

- [ ] **Task 3 — ReservationDepositDialog** (AC1, AC2, AC3)
  - [ ] Créer `reservation_deposit_dialog.dart` :
    - Autocomplete client (`GET /api/v1/contacts?q=`)
    - Champ acompte avec validation temps réel (10%–50%)
    - Indicateur "Solde restant" recalculé à chaque frappe
    - Bouton "Confirmer" désactivé si client absent ou acompte invalide
    - Loader pendant l'appel API
    - Gestion erreur backend (bandeau rouge)
  - [ ] Après succès : vider le panier via `cartNotifier.clearCart()` + afficher `ReceiptDialog` adapté

- [ ] **Task 4 — Bouton "Réservation" dans CartPanel / PosScreen** (AC1)
  - [ ] Ajouter le bouton dans la zone d'actions du `CartPanel` (à côté de "Encaisser")
  - [ ] Désactiver si offline ou panier vide
  - [ ] `onTap` : `showDialog<void>(builder: (_) => ReservationDepositDialog(...))`

- [ ] **Task 5 — ReservationsScreen** (AC4, AC5, AC6)
  - [ ] Créer `reservations_screen.dart` :
    - `TabController` : "En cours" / "Complétées" / "Annulées"
    - `ListView.builder` par onglet depuis les providers
    - `ReservationTile` avec actions contextuelles
  - [ ] `CompleteReservationDialog` : solde pré-rempli + sélecteur mode paiement
  - [ ] Dialogue annulation : `AlertDialog` avec `RadioListTile`
  - [ ] Navigation backoffice : ajouter "Réservations" dans le menu latéral existant

- [ ] **Task 6 — Fiche client — section réservations** (AC7)
  - [ ] Localiser l'écran de fiche client existant
  - [ ] Ajouter une section conditionnelle "Réservations en cours" si `pendingCount > 0`
  - [ ] Lien vers `ReservationsScreen` avec filtre `customerId`

- [ ] **Task 7 — KPI dashboard** (AC8)
  - [ ] Ajouter `reservationsKpiProvider` dans `DashboardScreen`
  - [ ] Créer ou réutiliser `KpiCard` pour afficher `pendingCount` + sous-texte acomptes
  - [ ] `onTap` : `context.push('/reservations?status=pending')`
  - [ ] Invalider le provider après tout create/complete/cancel pour rafraîchissement automatique

---

## Files to Create

- `apps/frontend/lib/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart`
- `apps/frontend/lib/features/shared/reservations/data/repositories/reservations_repository.dart`
- `apps/frontend/lib/features/shared/reservations/presentation/screens/reservations_screen.dart`
- `apps/frontend/lib/features/shared/reservations/presentation/providers/reservations_provider.dart`

## Files to Modify

- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — bouton "Réservation"
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — zone d'actions
- `apps/frontend/lib/features/retail/pos/presentation/providers/pos_providers.dart` — `reservationsRepositoryProvider`
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — KPI card
- `apps/frontend/lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart` — nouveau type KPI si nécessaire

---

## Dev Notes

### Offline Consideration

- Les réservations sont **online-only** — pas de persistence Isar, pas d'outbox
- Bouton "Réservation" désactivé si `ConnectivityService.isOffline`
- Pattern identique à story 27-2 (retours online-only)

### CartPanel Integration

- Après confirmation de réservation, vider le panier via `ref.read(cartNotifierProvider.notifier).clearCart()`
- Le `ReceiptDialog` adapté "RÉSERVATION — ACOMPTE" peut réutiliser `ReceiptDialog` existant avec un paramètre `type: 'reservation'` ou être un nouveau widget simplifié

### Contact Autocomplete

- Réutiliser le pattern d'autocomplete déjà présent dans `DeliveryForm` ou similaire
- `GET /api/v1/contacts?q=:query&limit=10` — debounce 300ms

### Provider Invalidation

- Après `createReservation` : `ref.invalidate(reservationsKpiProvider)` + `ref.invalidate(reservationsListProvider('pending'))`
- Après `completeReservation` : invalider `pending` + `completed`
- Après `cancelReservation` : invalider `pending` + `cancelled`

### Navigation

- Ajouter la route `/reservations` dans le router Flutter existant
- Le filtre `status` et `customerId` passés en query params ou via le provider Family

### KPI Card

- Vérifier si `KpiCard` ou `KpiCardGrid` supporte déjà un sous-texte configurable — réutiliser si oui
- Ne pas créer un nouveau widget si le pattern existant est adaptable

### Project Structure

- Repository : `apps/frontend/lib/features/shared/reservations/data/repositories/`
- Screens : `apps/frontend/lib/features/shared/reservations/presentation/screens/`
- Providers : `apps/frontend/lib/features/shared/reservations/presentation/providers/`
- Widgets POS : `apps/frontend/lib/features/retail/pos/presentation/widgets/`

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR99]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 27-5]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart — actions panier]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart — reçu pattern]
- [Source: apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart — KPI intégration]
- [Source: apps/frontend/lib/features/shared/reports/presentation/widgets/kpi_card_grid.dart — KPI card pattern]
- [Source: 27-4-reservation-backend.md — endpoints référence]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
