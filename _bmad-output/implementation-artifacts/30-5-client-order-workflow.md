# Story 30.5 — Frontend + Backend — Flux de statuts, livraison et génération document (FR107, FR108, FR109)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-5-client-order-workflow
- **Status:** ready-for-dev
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 30-1 (backend CRUD + confirm/cancel), 30-2 (documentType), 30-3 (ClientOrderRepository + models)

---

## Story

**As a** commercial or manager,
**I want** to move a client order through its lifecycle — prepare, mark ready, deliver with partial quantities — and have the correct delivery document generated based on my business type,
**So that** each step is traceable and the delivery document reflects my industry's standard (FR107, FR108, FR109).

---

## Acceptance Criteria

### AC1 — Endpoints de transition statut (backend)

**Given** les endpoints de transition sont implémentés
**When** ils sont appelés sur une commande au bon statut
**Then** :
- `POST /api/v1/client-orders/:id/prepare` : `confirmed → in-progress`
- `POST /api/v1/client-orders/:id/mark-ready` : `in-progress → ready`
- `POST /api/v1/client-orders/:id/deliver` : `ready → delivered` (voir AC2)
- `POST /api/v1/client-orders/:id/invoice` : `delivered → invoiced`
- `POST /api/v1/client-orders/:id/pay` : `invoiced → paid` ou `partially_paid`
**When** une transition invalide est tentée (ex: deliver depuis draft)
**Then** la réponse est `422 Unprocessable Entity` avec le message explicite : `"Transition invalide : [status actuel] → deliver"`

### AC2 — Livraison avec quantités et génération de transaction (backend)

**Given** un manager appelle `POST /api/v1/client-orders/:id/deliver` avec `{ lines: [{lineId, deliveredQty}], paymentMethod? }`
**When** la requête est valide
**Then** chaque `ClientOrderLine` est mis à jour avec sa `deliveredQty`
**And** une `Transaction` est créée (type SALE) avec les lignes livrées et le montant total livré
**And** pour chaque ligne : le `StockMovement RESERVATION` est consommé (mouvement `SALE` pour `deliveredQty`) ; le reliquat est libéré (mouvement `RESERVATION_RELEASE` si `deliveredQty < quantity`)
**And** le statut de la commande passe à `delivered`
**And** `deliveredBy` et `deliveredAt` sont renseignés

### AC3 — Écran de détail commande (frontend)

**Given** l'utilisateur navigue vers une commande
**When** `ClientOrderDetailScreen` se charge
**Then** il affiche :
- En-tête : numéro, statut coloré, client, date création
- Lignes : article, variante, qté commandée, qté livrée, prix unitaire, sous-total
- Pied : total commande, acompte versé, notes
- Boutons d'action correspondant au statut courant

### AC4 — Boutons d'action dans l'écran de détail

**Given** l'écran de détail affiche une commande
**When** le statut est `confirmed`
**Then** un bouton "Préparer" est visible (appelle `POST /:id/prepare`)
**When** le statut est `in-progress`
**Then** un bouton "Marquer prête" est visible (appelle `POST /:id/mark-ready`)
**When** le statut est `ready`
**Then** un bouton "Livrer" est visible (navigue vers `ClientOrderDeliverScreen`)
**When** le statut est `delivered`
**Then** un bouton "Facturer" est visible (appelle `POST /:id/invoice`)
**When** le statut est `invoiced`
**Then** un bouton "Encaisser" est visible (navigue vers un dialog de paiement)
**And** après chaque action réussie, la commande est rechargée pour afficher le nouveau statut

### AC5 — Écran de livraison avec saisie des quantités livrées

**Given** l'utilisateur tape "Livrer" sur une commande `ready`
**When** `ClientOrderDeliverScreen` s'ouvre
**Then** chaque ligne est affichée avec : nom article, quantité commandée, champ "Qté livrée" pré-rempli avec la quantité commandée
**And** l'utilisateur peut modifier la quantité livrée pour une livraison partielle (0 ≤ deliveredQty ≤ quantity)
**And** un récapitulatif du montant total livré est affiché en temps réel
**When** l'utilisateur confirme
**Then** `POST /api/v1/client-orders/:id/deliver` est appelé avec les quantités saisies
**And** après succès, navigation vers l'écran de détail mis à jour

### AC6 — Génération du document de livraison (frontend)

**Given** la livraison est confirmée avec succès
**When** `businessTypeConfig.documentType` est `"receipt"`
**Then** un résumé de commande standard est affiché (ticket de caisse simplifié)
**When** `documentType` est `"delivery_note"`
**Then** un bon de livraison est affiché : numéro commande, client, date, lignes livrées avec quantités, mention "Signature du livreur / du client"
**When** `documentType` est `"invoice"`
**Then** une facture simplifiée est affichée avec les lignes, montant total, et coordonnées du tenant

### AC7 — Transitions invalides retournent 422

**Given** un endpoint de transition est appelé
**When** le statut courant ne permet pas cette transition
**Then** la réponse backend est `422 Unprocessable Entity`
**And** le frontend affiche un SnackBar avec le message d'erreur de l'API

---

## Tasks / Subtasks

- [ ] **Task 1 — Endpoints de transition backend** (AC1, AC2, AC7)
  - [ ] Ajouter dans `client-order.controller.ts` : `POST /:id/prepare`, `/:id/mark-ready`, `/:id/deliver`, `/:id/invoice`, `/:id/pay`
  - [ ] Dans `client-order.service.ts` : implémenter `prepareOrder`, `markReady`, `deliverOrder`, `invoiceOrder`, `payOrder`
  - [ ] Valider la transition autorisée avant chaque action — retourner 422 si invalide
  - [ ] Pour `deliverOrder` : mettre à jour `deliveredQty` par ligne, créer `Transaction`, gérer `StockMovement RESERVATION_RELEASE`
  - [ ] Mettre à jour `deliveredBy` (userId courant) et `deliveredAt` à la livraison

- [ ] **Task 2 — Méthodes repository Flutter** (AC4, AC5)
  - [ ] Ajouter dans `client_order_repository.dart` :
    - `prepareOrder(String id)`
    - `markReady(String id)`
    - `deliverOrder(String id, List<DeliverLineDto> lines)`
    - `invoiceOrder(String id)`
    - `payOrder(String id, {required double amount, required String paymentMethod})`
  - [ ] `DeliverLineDto` : `lineId`, `deliveredQty`

- [ ] **Task 3 — Écran ClientOrderDetailScreen** (AC3, AC4)
  - [ ] Créer `client_order_detail_screen.dart`
  - [ ] Charger la commande via `GET /api/v1/client-orders/:id` (provider dédié ou `FutureProvider.family`)
  - [ ] Afficher les sections : en-tête, lignes, pied, boutons d'action
  - [ ] Chaque bouton d'action appelle la méthode repository correspondante puis invalide le provider pour recharger

- [ ] **Task 4 — Écran ClientOrderDeliverScreen** (AC5)
  - [ ] Créer `client_order_deliver_screen.dart`
  - [ ] Afficher les lignes avec champs `deliveredQty` éditables (pré-remplis avec `quantity`)
  - [ ] Calcul total livré en temps réel
  - [ ] Bouton "Confirmer la livraison" → appelle `deliverOrder` → navigation retour vers détail

- [ ] **Task 5 — Widget document de livraison** (AC6)
  - [ ] Créer `client_order_document_widget.dart`
  - [ ] Afficher conditionnellement selon `businessTypeConfigProvider.documentType`
  - [ ] Trois modes : `receipt` (résumé simple), `delivery_note` (bon de livraison avec signature), `invoice` (facture simplifiée)
  - [ ] Affiché après confirmation de livraison (dialog ou bottom sheet)

---

## Files to Create

- `apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_detail_screen.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_deliver_screen.dart`
- `apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_document_widget.dart`

## Files to Modify

- `apps/backend/src/shared/client-orders/client-order.controller.ts` — ajouter les 5 endpoints de transition
- `apps/backend/src/shared/client-orders/client-order.service.ts` — implémenter les transitions et la logique de livraison
- `apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart` — ajouter méthodes de transition

---

## Dev Notes

### Matrice des transitions autorisées

```
draft       → confirmed (via /confirm — story 30-1)
draft       → cancelled (via /cancel — story 30-1)
confirmed   → in-progress (via /prepare)
confirmed   → cancelled (via /cancel — story 30-1)
in-progress → ready (via /mark-ready)
ready       → delivered (via /deliver)
delivered   → invoiced (via /invoice)
invoiced    → paid (via /pay)
invoiced    → partially_paid (via /pay si montant partiel)
```

### Logique de livraison (service NestJS)

```typescript
async deliverOrder(id: string, tenantId: string, userId: string, lines: DeliverLineDto[]) {
  const order = await this.prisma.clientOrder.findFirst({ where: { id, tenantId }, include: { lines: true } });
  if (order.status !== 'ready') throw new UnprocessableEntityException('...');

  await this.prisma.$transaction(async (tx) => {
    // 1. Mettre à jour deliveredQty sur chaque ligne
    for (const { lineId, deliveredQty } of lines) {
      await tx.clientOrderLine.update({ where: { id: lineId }, data: { deliveredQty } });
    }
    // 2. Créer la Transaction (type SALE)
    // 3. Mouvements de stock : SALE pour deliveredQty, RESERVATION_RELEASE pour reliquat
    // 4. Mettre à jour le statut de la commande
    await tx.clientOrder.update({ where: { id }, data: { status: 'delivered', deliveredBy: userId, deliveredAt: new Date() } });
  });
}
```

### Document de livraison côté Flutter (MVP)

Pour le MVP, le document est affiché dans un `BottomSheet` ou un dialog — pas de génération PDF côté serveur. Le widget affiche simplement les informations formatées. Une future story peut ajouter l'export PDF.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-5]
- [Source: _bmad-output/planning-artifacts/prd.md — FR107, FR108, FR109]
- [Source: docs/architecture-scalario-2026-03-08.md — Section 4.2.13 ClientOrdersService]
- [Source: apps/backend/src/shared/client-orders/ — module créé en Story 30-1]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
N/A — tsc errors are pre-existing (Prisma client not regenerated, requires running DB); 13/13 tests pass (mocked)

### Completion Notes List
- Backend: prepareOrder (confirmed→in-progress), markReady (in-progress→ready), deliverOrder (ready→delivered + SALE movement + RESERVATION_RELEASE reliquat + Transaction), invoiceOrder, payOrder — all with 422 on invalid transition
- Flutter repository: getOrder, markReady, deliverOrder, invoiceOrder, payOrder methods added
- Provider: clientOrderDetailProvider (FutureProvider.family<ClientOrder, String>) added
- ClientOrderDetailScreen: header + colored badge + lines + actions per status
- ClientOrderDeliverScreen: line qty inputs pre-filled, total livré calculé, confirms delivery + shows document
- ClientOrderDocumentWidget: 3 modes (receipt / delivery_note / invoice) via businessTypeConfig.documentType
- ClientOrdersScreen.onTap navigates to detail screen

### File List
- apps/backend/src/shared/client-orders/client-orders.service.ts (modified — 5 new transition methods)
- apps/backend/src/shared/client-orders/client-orders.controller.ts (modified — 5 new endpoints + HttpCode)
- apps/frontend/lib/features/shared/client_orders/data/client_order_repository.dart (modified — getOrder, markReady, deliverOrder, invoiceOrder, payOrder)
- apps/frontend/lib/features/shared/client_orders/presentation/providers/client_orders_provider.dart (modified — clientOrderDetailProvider)
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_detail_screen.dart
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_order_deliver_screen.dart
- apps/frontend/lib/features/shared/client_orders/presentation/widgets/client_order_document_widget.dart
- apps/frontend/lib/features/shared/client_orders/presentation/screens/client_orders_screen.dart (modified — onTap navigates to detail)
