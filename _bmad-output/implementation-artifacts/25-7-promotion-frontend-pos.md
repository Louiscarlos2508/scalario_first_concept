# Story 25.7 — Frontend : PromotionsScreen (backoffice) + application auto au POS + prix barré reçu

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-7-promotion-frontend-pos
- **Status:** done
- **Priority:** High
- **Depends on:** 25-6 (endpoints promotions disponibles)

---

## Story

**As a** owner or cashier,
**I want** to manage promotions from the backoffice and see them automatically applied at the POS with struck-through prices on the receipt,
**So that** promotional pricing is transparent and requires zero cashier intervention (FR91).

---

## Acceptance Criteria

### AC1 — PromotionsScreen dans le backoffice

**Given** l'owner navigue vers la section promotions du backoffice
**When** `PromotionsScreen` se charge
**Then** une liste des promotions est affichée avec : nom/type, article/catégorie cible, dates, statut (badge vert/gris)
**And** un bouton "Nouvelle promotion" ouvre `CreatePromotionSheet`
**And** des filtres permettent de voir : Actives, Planifiées, Expirées

### AC2 — Formulaire création promotion

**Given** l'owner ouvre `CreatePromotionSheet`
**When** il sélectionne le type "Remise %"
**Then** les champs apparaissent : article ou catégorie (autocomplete), pourcentage de remise, date début, date fin
**And** pour "Offre quantitative" : champs buyN, getM, article offert (optionnel)
**And** pour "Prix barré" : champ prix original (pré-rempli depuis l'article), nouveau prix
**And** un aperçu en temps réel montre l'effet sur le prix (ex: "5 000 F → 4 000 F (-20%)")

### AC3 — Application automatique au POS

**Given** une promotion active couvre un article
**When** cet article est ajouté au panier POS
**Then** la promotion est appliquée automatiquement — sans action du caissier
**And** la ligne panier affiche : prix original barré (strikethrough) + prix après remise en vert
**And** un badge "PROMO" apparaît sur la ligne

### AC4 — Offre quantitative BUY_N_GET_M

**Given** une promotion "3 achetés = 1 offert" est active
**When** le caissier ajoute 3 exemplaires de l'article au panier
**Then** une ligne supplémentaire "Article offert (×1)" est ajoutée automatiquement avec prix 0 F
**And** si le caissier ajoute un 4ème exemplaire, la ligne offerte reste à ×1 (pas de cumul partiel)
**And** si le caissier ajoute 6 exemplaires, ×2 articles sont offerts

### AC5 — Reçu avec prix barré

**Given** une transaction avec promotion est finalisée
**When** le reçu s'affiche ou est imprimé
**Then** chaque ligne remisée affiche : nom, prix original (barré), prix payé, et le label de la promotion
**And** le total du reçu reflète les prix après remise
**And** le montant total d'économies est affiché en bas du reçu (ex: "Vous avez économisé 1 500 F")

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle Promotion Dart**
  - [ ] Créer `apps/frontend/lib/features/shared/promotions/data/models/promotion.dart`
  - [ ] Champs : `id, type, scope, scopeId, value Map<String, dynamic>, startDate, endDate, status, conflictRule`
  - [ ] `fromJson()` + `toJson()`

- [ ] **Task 2 : PromotionsRepository**
  - [ ] Créer `promotions_repository.dart`
  - [ ] `listPromotions({status?})`, `createPromotion(dto)`, `updatePromotion()`, `deletePromotion()`
  - [ ] `getActivePromotions(catalogItemId)` → `GET /promotions/active?catalogItemId=:id`

- [ ] **Task 3 : PromotionsScreen**
  - [ ] Créer `promotions_screen.dart`
  - [ ] Liste avec filtres Actives/Planifiées/Expirées
  - [ ] FAB "Nouvelle promotion" → `CreatePromotionSheet`
  - [ ] Badge statut coloré

- [ ] **Task 4 : CreatePromotionSheet**
  - [ ] Dropdown type : Remise % / Offre quantitative / Prix barré
  - [ ] Champs dynamiques selon type
  - [ ] Aperçu temps réel
  - [ ] Autocomplete article/catégorie cible

- [ ] **Task 5 : Application auto au POS — CartNotifier**
  - [ ] Sync locale des promotions actives dans Isar (pour offline)
  - [ ] Dans `addProduct()` : vérifier si une promotion couvre l'article, appliquer le discount
  - [ ] Ligne `CartItem` enrichie avec `appliedPromotion`, `originalPrice`, `discountedPrice`

- [ ] **Task 6 : CartPanel — prix barré + badge PROMO**
  - [ ] Afficher prix barré (TextStyle strikethrough) + prix remisé en vert
  - [ ] Badge "PROMO" sur la ligne
  - [ ] Ligne "Article offert" non modifiable (type `freeItem`)

- [ ] **Task 7 : ReceiptDialog — prix barré + total économies**
  - [ ] Ligne remisée : prix original barré + prix payé + label promo
  - [ ] Total économies en bas : "Vous avez économisé X F"

- [ ] **Task 8 : Navigation backoffice**
  - [ ] Lien vers `PromotionsScreen` depuis `DashboardShell`

---

## Files to Create

- `apps/frontend/lib/features/shared/promotions/presentation/screens/promotions_screen.dart`
- `apps/frontend/lib/features/shared/promotions/presentation/widgets/create_promotion_sheet.dart`
- `apps/frontend/lib/features/shared/promotions/data/models/promotion.dart`
- `apps/frontend/lib/features/shared/promotions/data/repositories/promotions_repository.dart`

## Files to Modify

- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — appliquer promotions localement
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — prix barré + badge PROMO
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — prix barré + total économies
- `apps/frontend/lib/features/retail/backoffice/presentation/widgets/dashboard_shell.dart` — lien PromotionsScreen

## Dev Notes

- Les promotions sont synchronisées localement (Isar) pour fonctionner offline — la promotion engine est dupliquée côté client
- La ligne "article offert" dans le panier est de type `CartLineType.freeItem` — non modifiable par le caissier
