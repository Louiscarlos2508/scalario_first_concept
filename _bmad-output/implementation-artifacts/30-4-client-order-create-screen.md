# Story 30.4 — Frontend — Formulaire de création de commande client (FR107)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-4-client-order-create-screen
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 30-1 (POST /client-orders), 30-3 (ClientOrderRepository + models)

---

## Story

**As a** commercial or manager,
**I want** to create a client order by selecting a customer, adding product lines with quantities and prices, and optionally recording a deposit amount and notes,
**So that** I can register a client's order from both the backoffice and the POS before preparing it (FR107).

---

## Acceptance Criteria

### AC1 — Accès au formulaire depuis backoffice et POS

**Given** l'utilisateur est dans l'écran Commandes du backoffice
**When** il tape sur le bouton "+" ou "Nouvelle commande"
**Then** `ClientOrderFormScreen` s'ouvre en navigation push
**Given** l'utilisateur est dans le POS
**When** il accède au menu secondaire ou à un bouton contextuel dans la topbar
**Then** le même écran `ClientOrderFormScreen` s'ouvre

### AC2 — Sélection client obligatoire

**Given** le formulaire est ouvert
**When** l'utilisateur tape dans le champ "Client"
**Then** un autocomplete affiche les contacts du tenant (réutiliser `ContactAutocomplete` existant)
**And** le client sélectionné est affiché avec son nom
**When** le formulaire est soumis sans client sélectionné
**Then** un message de validation "Veuillez sélectionner un client" est affiché

### AC3 — Ajout et gestion de lignes produit

**Given** le formulaire est ouvert
**When** l'utilisateur appuie sur "Ajouter un article"
**Then** une nouvelle ligne apparaît avec : sélecteur article (autocomplete `ProductAutocomplete`), champ quantité, champ prix unitaire
**When** l'article sélectionné a des variantes
**Then** un dropdown de sélection de variante apparaît sur cette ligne
**And** le prix unitaire est pré-rempli depuis le prix catalogue de l'article (ou de la variante sélectionnée)
**When** l'utilisateur tape sur l'icône supprimer d'une ligne
**Then** la ligne est retirée du formulaire
**And** si c'est la dernière ligne et le formulaire est soumis, un message "Au moins un article est requis" s'affiche

### AC4 — Calcul du total en temps réel

**Given** des lignes sont ajoutées ou modifiées
**When** une quantité ou un prix unitaire change
**Then** le montant total est recalculé et affiché en bas du formulaire (somme de quantity × unitPrice par ligne)
**And** le montant est formaté en devise du tenant (ex: "15 000 FCFA")

### AC5 — Champs optionnels

**Given** le formulaire est affiché
**When** l'utilisateur remplit les champs optionnels
**Then** il peut saisir :
- Une date souhaitée (DatePicker, label "Date souhaitée")
- Un acompte reçu (champ décimal, label "Acompte reçu")
- Des notes libres (TextField multi-lignes, label "Notes")

### AC6 — Validation et soumission

**Given** le formulaire est correctement rempli (client + au moins une ligne valide)
**When** l'utilisateur appuie sur "Créer la commande"
**Then** `POST /api/v1/client-orders` est appelé
**And** un indicateur de chargement est affiché pendant l'appel
**And** en cas de succès, la navigation pousse vers `ClientOrderDetailScreen` pour la commande créée
**And** en cas d'erreur API, un message d'erreur s'affiche (SnackBar) sans fermer le formulaire

### AC7 — Validation des lignes

**Given** l'utilisateur a rempli des lignes
**When** une quantité est ≤ 0 ou absente
**Then** le formulaire marque le champ en erreur : "La quantité doit être supérieure à 0"
**When** un prix unitaire est ≤ 0 ou absent
**Then** le formulaire marque le champ en erreur : "Le prix doit être supérieur à 0"

---

## Tasks / Subtasks

- [ ] **Task 1 — Widget ClientOrderLineFormWidget** (AC3, AC7)
  - [ ] Créer `client_order_line_form_widget.dart` — widget stateful gérant une ligne de commande
  - [ ] Intégrer `ProductAutocomplete` pour la sélection article
  - [ ] Afficher dropdown variante si l'article a des variantes (`CatalogItem.hasVariants`)
  - [ ] Pre-remplir le prix depuis le catalogue au choix de l'article/variante
  - [ ] Champ quantité (décimal) et champ prix unitaire (décimal) avec validation
  - [ ] Bouton supprimer ligne

- [ ] **Task 2 — Écran ClientOrderFormScreen** (AC1–AC7)
  - [ ] Créer `client_order_form_screen.dart` — `ConsumerStatefulWidget`
  - [ ] Section client : `ContactAutocomplete` (réutiliser existant)
  - [ ] Section lignes : liste dynamique de `ClientOrderLineFormWidget` + bouton "Ajouter un article"
  - [ ] Section options : date souhaitée (DatePicker), acompte (TextField décimal), notes (TextField multi-lignes)
  - [ ] Pied de formulaire : montant total calculé + bouton "Créer la commande"
  - [ ] Appel `clientOrderRepository.createOrder(dto)` à la soumission
  - [ ] Navigation vers `ClientOrderDetailScreen` après succès

- [ ] **Task 3 — Méthode createOrder dans ClientOrderRepository** (AC6)
  - [ ] Ajouter `createOrder(CreateClientOrderDto dto)` dans `client_order_repository.dart` → `POST /api/v1/client-orders`
  - [ ] `CreateClientOrderDto` : `customerId`, `lines`, `depositAmount?`, `notes?`, `desiredDeliveryDate?`

- [ ] **Task 4 — Accès depuis le POS** (AC1)
  - [ ] Localiser `PosScreen` ou la topbar du POS
  - [ ] Ajouter un bouton secondaire "Commande client" (icône `assignment` ou `add_shopping_cart`)
  - [ ] Le bouton navigue vers `ClientOrderFormScreen`

---

## Files to Create

- `apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_form_screen.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_line_form_widget.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart` — ajouter méthode `createOrder`
- `apps/frontend/lib/features/pos/presentation/screens/pos_screen.dart` — ajouter bouton "Commande client"

---

## Dev Notes

### Formulaire en écran dédié, pas dialog

Le formulaire peut contenir plusieurs lignes et des champs optionnels — un `AlertDialog` serait trop limité. `ClientOrderFormScreen` est un écran full-screen avec son propre `Scaffold`.

### Réutiliser ProductAutocomplete et ContactAutocomplete

Ces widgets existent déjà dans le backoffice. Utiliser les mêmes providers et patterns. Si le widget `ProductAutocomplete` est dans `lib/features/shared/catalog/`, l'importer directement.

### Liste dynamique de lignes

```dart
// Dans _ClientOrderFormScreenState
List<ClientOrderLineFormController> _lines = [];

void _addLine() => setState(() => _lines.add(ClientOrderLineFormController()));
void _removeLine(int index) => setState(() => _lines.removeAt(index));
```

### Calcul total réactif

Écouter les changements sur les contrôleurs de chaque ligne pour recalculer le total. Utiliser `ValueNotifier` ou recalculer dans `build()` directement à partir des valeurs courantes des controllers.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-4]
- [Source: _bmad-output/planning-artifacts/prd.md — FR107]
- [Source: apps/frontend/lib/features/shared/catalog/ — ProductAutocomplete existant]
- [Source: apps/frontend/lib/features/shared/contacts/ — ContactAutocomplete existant]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
N/A — flutter analyze: 2 info-level issues only (pre-existing unnecessary_underscores in pos_screen; DropdownButtonFormField.value deprecation info — non-blocking)

### Completion Notes List
- Added createOrder() to ClientOrderRepository (POST /client-orders)
- ClientOrderLineFormWidget: ProductAutocomplete + variant dropdown + qty/price fields + delete button
- ClientOrderFormScreen: _CustomerAutocomplete (inline Riverpod autocomplete via searchRemoteCustomers), dynamic lines list, optional fields (date, deposit, notes), total + submit
- FAB in ClientOrdersScreen navigates to ClientOrderFormScreen
- POS AppBar: "Commande client" button (assignment_add icon) navigates to ClientOrderFormScreen when session open

### File List
- apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart (modified — createOrder added)
- apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_line_form_widget.dart
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_form_screen.dart
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_orders_screen.dart (modified — FAB navigates to form)
- apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart (modified — Commande client button)
