# Story 27.2 — Frontend POS — Bouton retour, recherche vente originale, choix résolution (FR98)

## Metadata

- **Epic:** Epic 27 — Retours Articles & Réservations
- **Story ID:** 27-2-return-frontend-pos
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a — bloquant pour tout retail
- **Depends on:** 27-1-return-backend (endpoint POST /api/v1/returns), Epic 8 (ConnectivityService)

---

## Story

**As a** commercial (Fatou),
**I want** a "Retour" button in the POS that lets me find the original sale by receipt number or barcode and choose how to resolve the return,
**So that** I can process article returns quickly without leaving the POS screen (FR98).

---

## Acceptance Criteria

### AC1 — Bouton "Retour" dans le POS

**Given** le commercial est sur l'écran POS
**When** il appuie sur le bouton "Retour" (icône `Icons.undo`, placement : barre d'actions du `CartPanel`)
**Then** si le POS est en ligne : une bottom sheet `ReturnSearchSheet` s'ouvre
**And** le champ de recherche par numéro de reçu est focalisé automatiquement (`autofocus: true`)

**When** le POS est hors ligne
**Then** le bouton "Retour" est affiché avec `opacity: 0.4` et un `Tooltip` : "Nécessite une connexion Internet"
**And** un tap affiche un `SnackBar` : "La recherche de reçu nécessite une connexion Internet"

### AC2 — Recherche de la vente originale

**Given** la `ReturnSearchSheet` est ouverte
**When** le commercial saisit un numéro de reçu (ou scanne un code-barres via le champ texte)
**And** appuie sur la touche "Rechercher" ou valide le champ
**Then** `GET /api/v1/transactions?receiptNumber=:value` est appelé

**When** la transaction est trouvée
**Then** la liste des articles de la vente s'affiche : nom, quantité vendue, prix unitaire
**And** chaque article a un `Stepper` de quantité à retourner (défaut : 0, min : 0, max : quantité achetée)
**And** le bouton "Confirmer le retour" est activé uniquement si au moins une quantité > 0

**When** le numéro de reçu n'est pas trouvé
**Then** un message inline s'affiche : "Vente introuvable — vérifiez le numéro de reçu"
**And** le champ est mis en surbrillance d'erreur (`errorText`)

### AC3 — Choix de résolution

**Given** le commercial a sélectionné au moins un article à retourner (quantité > 0)
**When** il appuie sur "Confirmer le retour"
**Then** un dialogue `ReturnResolutionDialog` s'affiche avec trois options sous forme de `RadioListTile` :
- "Remboursement cash" (icône `Icons.payments`)
- "Avoir client — crédité sur le compte" (icône `Icons.account_balance_wallet`)
- "Échange article" (icône `Icons.sync_alt`)

**And** si `returnRequiresReason = true` (lu depuis la config tenant), un champ texte "Motif du retour" est affiché sous les options

### AC4 — Motif obligatoire (si configuré)

**Given** `returnRequiresReason = true` pour le tenant
**When** le commercial appuie sur "Valider" dans `ReturnResolutionDialog`
**And** le champ "Motif du retour" est vide
**Then** un `errorText` rouge s'affiche sous le champ : "Le motif est obligatoire"
**And** la confirmation est bloquée (bouton "Valider" désactivé tant que le motif est vide)

### AC5 — Confirmation et feedback

**Given** le commercial a rempli tous les champs requis dans `ReturnResolutionDialog`
**When** il appuie sur "Valider"
**Then** `POST /api/v1/returns` est appelé pour chaque ligne avec quantité > 0
**And** un indicateur de chargement (`CircularProgressIndicator`) est affiché pendant l'appel

**When** toutes les requêtes répondent avec succès
**Then** la `ReturnSearchSheet` et le `ReturnResolutionDialog` se ferment
**And** un `SnackBar` affiche : "Retour enregistré — [résolution en français]"
**And** le POS revient à l'état initial (panier inchangé — les retours n'affectent pas le panier courant)

**When** le backend répond avec une erreur (400 délai expiré, 400 motif manquant, 403 approbation requise)
**Then** le `ReturnResolutionDialog` reste ouvert
**And** le message d'erreur du backend s'affiche dans un bandeau rouge en haut du dialogue

### AC6 — Mode offline

**Given** le POS perd la connexion après l'ouverture de la `ReturnSearchSheet`
**When** la recherche de reçu est tentée
**Then** l'erreur réseau est interceptée et affichée : "Connexion perdue — impossible de rechercher la vente"
**And** la `ReturnSearchSheet` reste ouverte pour permettre une nouvelle tentative à la reconnexion

---

## Tasks / Subtasks

- [ ] **Task 1 — ReturnsRepository** (AC5)
  - [ ] Créer `returns_repository.dart` avec :
    - `createReturn(CreateReturnDto dto) → Future<ReturnRecord>`
    - `searchTransaction(String receiptNumber) → Future<Transaction?>`
  - [ ] Utiliser `Dio` (ou l'instance HTTP existante) avec intercepteur d'auth JWT
  - [ ] Gérer les erreurs HTTP : `400`, `403`, `404` → propager le message backend

- [ ] **Task 2 — ReturnsRepositoryProvider**
  - [ ] Ajouter `returnsRepositoryProvider` dans `pos_providers.dart`
  - [ ] Injection du `Dio` client existant (pattern identique aux autres providers)

- [ ] **Task 3 — ReturnSearchSheet widget** (AC1, AC2)
  - [ ] Créer `return_search_sheet.dart` :
    - Champ texte receipt number avec `autofocus: true` et bouton recherche
    - État : `initial` | `loading` | `found(transaction)` | `notFound` | `error`
    - Liste articles avec `Stepper` de quantité par ligne
    - Bouton "Confirmer le retour" (activé si `sum(quantities) > 0`)
  - [ ] Ouvrir via `showModalBottomSheet` depuis `PosScreen`

- [ ] **Task 4 — ReturnResolutionDialog widget** (AC3, AC4, AC5)
  - [ ] Créer `return_resolution_dialog.dart` :
    - 3 options `RadioListTile` pour la résolution
    - Champ motif conditionnel (selon config tenant lue depuis un provider)
    - Validation inline motif si requis
    - Bouton "Valider" + loader + affichage erreur backend
    - Appel séquentiel `POST /api/v1/returns` pour chaque ligne sélectionnée

- [ ] **Task 5 — Bouton "Retour" dans PosScreen** (AC1, AC6)
  - [ ] Ajouter bouton dans la barre d'actions du `CartPanel` (ou `PosScreen`)
  - [ ] Lire l'état de connectivité via le provider `ConnectivityService` existant
  - [ ] Appliquer `opacity` + `Tooltip` quand hors ligne
  - [ ] `onTap` : vérifier online → ouvrir `ReturnSearchSheet`

---

## Files to Create

- `apps/frontend/lib/features/retail/pos/presentation/widgets/return_search_sheet.dart`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/return_resolution_dialog.dart`
- `apps/frontend/lib/features/shared/returns/data/repositories/returns_repository.dart`

## Files to Modify

- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — bouton "Retour" dans la barre d'actions
- `apps/frontend/lib/features/retail/pos/presentation/providers/pos_providers.dart` — `returnsRepositoryProvider`

---

## Dev Notes

### Architecture Reference

- `ReturnRecord` backend : `apps/backend/src/shared/returns/` (créé en story 27-1)
- Endpoint de recherche transaction : `GET /api/v1/transactions?receiptNumber=:value` — vérifier que ce filtre existe, sinon l'ajouter dans `transactions.controller.ts`

### Offline Consideration

- Les retours sont **online-only** — explicitement défini dans FR98
- La détection offline utilise le `ConnectivityService` existant (déjà utilisé dans d'autres écrans)
- Pas d'outbox ni de persistence Isar pour les retours

### Resolution Labels (français)

- `cash_refund` → "Remboursement cash"
- `credit_note` → "Avoir client"
- `exchange` → "Échange article"

### Multi-ligne Returns

- Si la vente avait 3 articles et le commercial en retourne 2, faire 2 appels `POST /api/v1/returns` (un par ligne)
- Optionnellement : grouper en une seule requête si le backend supporte un tableau — à valider avec story 27-1

### POS State

- Le retour n'affecte **pas** le panier POS courant
- Le panier reste intact après un retour (le commercial peut continuer à vendre)
- Les retours modifient le stock via le backend, pas via l'état local Flutter

### Project Structure

- Widget POS : `apps/frontend/lib/features/retail/pos/presentation/widgets/`
- Repository : `apps/frontend/lib/features/shared/returns/data/repositories/`
- Pattern repository : identique à `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart`

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR98]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 27-2]
- [Source: apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart — structure POS existante]
- [Source: apps/frontend/lib/features/retail/pos/presentation/providers/pos_providers.dart — pattern providers]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart — barre d'actions panier]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
