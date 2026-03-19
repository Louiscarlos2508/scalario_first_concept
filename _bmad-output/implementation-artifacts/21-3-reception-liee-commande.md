# Story 21.3 — Frontend : Réception liée à une commande

## Metadata

- **Epic:** Epic 21 — Commandes fournisseurs + réception liée
- **Story ID:** 21-3-reception-liee-commande
- **Status:** done
- **Priority:** High
- **Depends on:** 21-1 (endpoint `/receive`), 21-2 (liste commandes)

---

## Story

**As a** manager (Moussa),
**I want** to record a delivery against a purchase order with pre-filled quantities,
**So that** variances are calculated automatically and quality issues are documented (FR80).

---

## Acceptance Criteria

### AC1 — Accès depuis liste

**Given** une commande en statut `confirmed` ou `partially_received` est affichée
**When** l'utilisateur tape dessus
**Then** `PurchaseOrderDetailScreen` s'ouvre avec : fournisseur, date prévue, notes, liste des lignes (article, qté commandée)
**And** un bouton "Réceptionner" est visible si statut ≠ `received` et ≠ `cancelled`

### AC2 — Formulaire réception pré-rempli

**Given** le bouton "Réceptionner" est tapé
**When** `ReceivePurchaseOrderSheet` s'ouvre
**Then** chaque ligne de la commande est affichée avec :
- Nom article
- Quantité commandée (affichée en lecture seule)
- Champ "Quantité reçue" (pré-rempli avec quantité commandée, modifiable)
- Champ "Notes qualité" (optionnel, ex: "produits trop mûrs")

### AC3 — Affichage variance en temps réel

**Given** l'utilisateur modifie la quantité reçue d'une ligne
**When** la valeur change
**Then** la variance s'affiche sous le champ : "+2.5" (vert si positif) ou "-1.0" (orange si négatif)
**And** une variance de 0 n'est pas affichée

### AC4 — Soumission réception

**Given** le formulaire de réception est soumis
**When** `POST /api/v1/purchase-orders/:id/receive` est appelé
**Then** en cas de succès : sheet se ferme, détail commande se rafraîchit avec nouveau statut
**And** snackbar "Réception enregistrée — [n] mouvements de stock créés"
**And** en cas d'erreur : snackbar rouge avec message d'erreur

### AC5 — Réception sans commande (flux hérité préservé)

**Given** l'utilisateur est dans le hub inventaire, onglet "Réceptions"
**When** il crée une réception sans sélectionner de commande fournisseur
**Then** le flux `delivery_form.dart` existant (Epic 16 Story 16.1) fonctionne sans changement
**And** aucune régression sur le flux actuel

### AC6 — Test widget

**Given** `ReceivePurchaseOrderSheet` est rendu avec une commande de 2 lignes
**When** la quantité reçue de la ligne 1 est modifiée à une valeur différente de la quantité commandée
**Then** la variance s'affiche correctement sur cette ligne
**And** les autres lignes restent inchangées

---

## Tasks/Subtasks

- [ ] **Task 1 : PurchaseOrderDetailScreen**
  - [ ] En-tête : fournisseur, statut badge, date prévue, notes
  - [ ] Liste des lignes : article, qté commandée, qté reçue (si déjà réceptionnée)
  - [ ] Bouton "Réceptionner" visible si statut ∉ {received, cancelled}
  - [ ] Ouvre `ReceivePurchaseOrderSheet` au tap

- [ ] **Task 2 : ReceivePurchaseOrderSheet**
  - [ ] `StatefulWidget` avec liste de lignes éditables
  - [ ] Chaque ligne : nom article (lecture seule), qté commandée (lecture seule), champ qté reçue (pré-rempli), notes qualité
  - [ ] Variance calculée en temps réel : `received - expected`
  - [ ] Couleur variance : vert si ≥ 0, orange si < 0
  - [ ] Submit → `purchaseOrdersRepository.receivePurchaseOrder(id, lines)`

- [ ] **Task 3 : Repository — méthode receive**
  - [ ] Ajouter `receivePurchaseOrder(id, lines)` dans `purchase_orders_repository.dart`
  - [ ] POST `/api/v1/purchase-orders/:id/receive`

- [ ] **Task 4 : Test widget**
  - [ ] Créer `apps/frontend/test/features/purchase_orders/receive_sheet_test.dart`
  - [ ] Test : modifier qté ligne 1 → variance affichée ; ligne 2 inchangée

---

## Files to Create

- `apps/frontend/lib/features/shared/purchase_orders/presentation/screens/purchase_order_detail_screen.dart`
- `apps/frontend/lib/features/shared/purchase_orders/presentation/widgets/receive_purchase_order_sheet.dart`
- `apps/frontend/test/features/purchase_orders/receive_sheet_test.dart`
