# Story 21.2 — Frontend : Écran liste commandes + formulaire création

## Metadata

- **Epic:** Epic 21 — Commandes fournisseurs + réception liée
- **Story ID:** 21-2-purchase-order-frontend
- **Status:** done
- **Priority:** High
- **Depends on:** 21-1 (endpoints backend disponibles)

---

## Story

**As a** manager (Moussa),
**I want** a screen to list purchase orders and create new ones,
**So that** I can document expected supplier deliveries (FR79).

---

## Acceptance Criteria

### AC1 — Écran liste commandes

**Given** l'utilisateur navigue vers l'onglet "Commandes" (hub inventaire)
**When** `PurchaseOrdersScreen` se charge
**Then** il appelle `GET /api/v1/purchase-orders` et affiche une liste de cards
**And** chaque card affiche : nom fournisseur, date prévue, statut (chip coloré), nombre d'articles
**And** un filtre par statut (chips en haut : Tous · Brouillon · Confirmé · Partiel · Reçu · Annulé) est présent
**And** si la liste est vide → message "Aucune commande" + bouton "Créer la première commande"

### AC2 — Chips statut colorés

| Statut | Couleur chip |
|:---|:---|
| draft | gris |
| confirmed | bleu |
| partially_received | orange |
| received | vert |
| cancelled | rouge |

### AC3 — Formulaire création commande

**Given** le FAB "+" est tapé
**When** `CreatePurchaseOrderSheet` s'ouvre (bottom sheet plein écran)
**Then** le formulaire contient :
- Sélection fournisseur : autocomplete filtré sur `contactType = 'supplier'`
- Champ date de livraison prévue (optionnel) — `DatePicker`
- Champ notes (optionnel, multiline)
- Section "Articles commandés" : liste de lignes, chaque ligne = produit (autocomplete) + quantité (numérique)
- Bouton "Ajouter un article" pour ajouter une ligne
- Bouton "Supprimer" (icône poubelle) sur chaque ligne
- Bouton "Créer la commande" (disabled si aucun article ou pas de fournisseur)

### AC4 — Soumission création

**Given** le formulaire est valide et soumis
**When** `POST /api/v1/purchase-orders` est appelé
**Then** en cas de succès : sheet se ferme, liste se rafraîchit, snackbar "Commande créée"
**And** en cas d'erreur : snackbar rouge avec message d'erreur de l'API

### AC5 — Transition statut depuis la liste

**Given** une card de commande en statut `draft` est affichée
**When** l'utilisateur la presse longuement (ou via menu contextuel)
**Then** un menu propose "Confirmer la commande" → appelle `PATCH /api/v1/purchase-orders/:id {status: 'confirmed'}`
**And** la card se met à jour avec le nouveau statut sans rechargement complet

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle PurchaseOrder local**
  - [ ] Créer `purchase_order_local.dart` : `id, supplierId, supplierName, status, expectedDate, notes, lines[], lineCount, tenantId`
  - [ ] `fromJson()` depuis réponse API

- [ ] **Task 2 : Repository**
  - [ ] Créer `purchase_orders_repository.dart`
  - [ ] Méthodes : `listOrders({status?})`, `createOrder(dto)`, `updateStatus(id, status)`, `getStats()`

- [ ] **Task 3 : Provider Riverpod**
  - [ ] `purchaseOrdersProvider` : `FutureProvider<List<PurchaseOrderLocal>>`
  - [ ] `purchaseOrdersFilterProvider` : `StateProvider<String?>` pour le filtre statut

- [ ] **Task 4 : PurchaseOrdersScreen**
  - [ ] Chips filtres en haut (Tous, Brouillon, Confirmé, Partiel, Reçu, Annulé)
  - [ ] Liste cards avec statut chip coloré
  - [ ] FAB "+" ouvre `CreatePurchaseOrderSheet`
  - [ ] État vide avec bouton CTA
  - [ ] Long press → menu "Confirmer la commande"

- [ ] **Task 5 : CreatePurchaseOrderSheet**
  - [ ] Autocomplete fournisseur (`contactType = 'supplier'`)
  - [ ] DatePicker pour `expectedDate`
  - [ ] Liste dynamique de lignes (produit + quantité)
  - [ ] Bouton "Ajouter un article"
  - [ ] Validation + submit → `purchaseOrdersRepository.createOrder()`

---

## Files to Create

- `apps/frontend/lib/features/shared/purchase_orders/data/models/purchase_order_local.dart`
- `apps/frontend/lib/features/shared/purchase_orders/data/repositories/purchase_orders_repository.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/screens/purchase_orders_screen.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart`
