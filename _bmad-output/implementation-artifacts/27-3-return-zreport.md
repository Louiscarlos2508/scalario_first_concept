# Story 27.3 — Z-report — Distinction ventes brutes vs retours (FR98)

## Metadata

- **Epic:** Epic 27 — Retours Articles & Réservations
- **Story ID:** 27-3-return-zreport
- **Status:** ready-for-dev
- **Priority:** Medium
- **Phase:** 2a
- **Depends on:** 27-1-return-backend (ReturnsService.getReturnsSummaryForSession), Epic 6 (PosSession, Z-report existant)

---

## Story

**As a** manager or owner,
**I want** the session Z-report to show gross sales, returns, and net sales as separate lines,
**So that** I can reconcile cash accurately and track return volume per session (FR98).

---

## Acceptance Criteria

### AC1 — Données retours dans le Z-report backend

**Given** une session POS est clôturée et a des retours enregistrés pendant la session
**When** `GET /api/v1/sessions/:id/zreport` est appelé
**Then** la réponse inclut les champs supplémentaires :
```json
{
  "grossSales": { "count": N, "amount": X },
  "returns":    { "count": M, "amount": Y },
  "netSales":   { "amount": X - Y },
  "cashTheoretical": "float_ouverture + ventes_cash - remboursements_cash"
}
```
**And** `returns.amount` est la somme des `quantity * unitPrice` des `ReturnRecord` dont `created_at` est dans la plage `[session.openedAt, session.closedAt]` et `tenant_id` correspond

### AC2 — Zéro retour dans la session

**Given** une session n'a aucun retour (`ReturnRecord` dans sa plage horaire)
**When** le Z-report est demandé
**Then** `returns` est présent avec `{ count: 0, amount: 0 }` — pas de champ absent, pas d'erreur
**And** `netSales.amount == grossSales.amount`

### AC3 — Affichage Z-report frontend — session avec retours

**Given** le Z-report est affiché (dialogue de clôture de session ou écran rapport)
**When** `returns.count > 0`
**Then** trois lignes distinctes s'affichent dans cet ordre :
1. "Ventes brutes : X FCFA (N transactions)" — couleur texte standard
2. "Retours : − Y FCFA (M retours)" — couleur `Colors.red`
3. "Ventes nettes : Z FCFA" — `FontWeight.bold`

### AC4 — Affichage Z-report frontend — session sans retours

**Given** le Z-report est affiché
**When** `returns.count == 0`
**Then** seule la ligne "Ventes nettes : Z FCFA" s'affiche — identique à ce qui existait avant cette story
**And** aucune ligne "Retours : − 0 FCFA" n'est affichée (éviter le bruit visuel)

### AC5 — Cohérence cash théorique

**Given** le Z-report calcule le montant cash théorique attendu
**When** des retours de type `cash_refund` ont été effectués pendant la session
**Then** le cash théorique est : `float_ouverture + total_ventes_cash - total_remboursements_cash`
**And** la variance affichée (cash compté − cash théorique) reste mathématiquement correcte
**And** les retours de type `credit_note` ou `exchange` n'impactent pas le cash théorique

---

## Tasks / Subtasks

- [ ] **Task 1 — ReturnsService.getReturnsSummaryForSession** (AC1, AC2, AC5)
  - [ ] Ajouter la méthode dans `returns.service.ts` :
    ```typescript
    async getReturnsSummaryForSession(
      tenantId: string,
      openedAt: Date,
      closedAt: Date,
    ): Promise<{ count: number; amount: Decimal; cashRefundAmount: Decimal }>
    ```
  - [ ] Query Prisma : `findMany` sur `ReturnRecord` où `tenantId = tenantId` et `createdAt >= openedAt` et `createdAt <= closedAt`
  - [ ] Calculer `amount` = somme des montants (nécessite de rejoindre la transaction ou stocker le montant sur `ReturnRecord` — voir note dev)
  - [ ] Calculer `cashRefundAmount` = sous-ensemble avec `resolution = 'cash_refund'`
  - [ ] Retourner `{ count: 0, amount: 0, cashRefundAmount: 0 }` si aucun retour

- [ ] **Task 2 — Intégration dans le Z-report existant** (AC1, AC5)
  - [ ] Localiser la méthode qui construit le Z-report (probablement `retail-orchestration.service.ts` ou `pos-session.service.ts`)
  - [ ] Appeler `returnsService.getReturnsSummaryForSession(tenantId, session.openedAt, session.closedAt)`
  - [ ] Calculer `grossSales` = total existant (inchangé)
  - [ ] Calculer `netSales.amount = grossSales.amount - returns.amount`
  - [ ] Ajuster `cashTheoretical` : soustraire `cashRefundAmount` du calcul existant
  - [ ] Injecter `ReturnsService` dans le service Z-report via le constructeur NestJS

- [ ] **Task 3 — Affichage frontend — section retours dans le Z-report** (AC3, AC4)
  - [ ] Localiser le widget/écran qui affiche le Z-report (probablement `receipt_dialog.dart` ou un `SessionReportScreen`)
  - [ ] Ajouter la logique conditionnelle : afficher les 3 lignes si `returns.count > 0`, sinon afficher uniquement "Ventes nettes"
  - [ ] Styler la ligne "Retours" en rouge avec préfixe "− "
  - [ ] Styler la ligne "Ventes nettes" en `FontWeight.bold`
  - [ ] Mettre à jour le modèle de données Flutter pour inclure `returns` et `netSales` dans la réponse Z-report désérialisée

- [ ] **Task 4 — Tests** (toutes AC)
  - [ ] Backend : test unitaire `getReturnsSummaryForSession` avec retours dans/hors plage
  - [ ] Backend : test que `cashTheoretical` exclut les retours `credit_note` et `exchange`
  - [ ] Backend : test session sans retours → `returns: { count: 0, amount: 0 }`

---

## Files to Create

*(aucun nouveau fichier — modifications uniquement)*

## Files to Modify

- `apps/backend/src/shared/returns/returns.service.ts` — ajouter `getReturnsSummaryForSession()`
- `apps/backend/src/retail/retail-orchestration.service.ts` — intégrer `returnsSummary` dans le Z-report et ajuster `cashTheoretical`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — afficher les 3 lignes conditionnellement (ou le fichier équivalent Z-report)

---

## Dev Notes

### Montant du retour

- Le modèle `ReturnRecord` ne stocke pas directement le montant unitaire — il stocke `quantity` et `catalogItemId`
- Pour calculer le montant d'un retour, deux options :
  1. Rejoindre la `Transaction` originale pour lire le `unitPrice` de la ligne correspondante (plus précis)
  2. Ajouter un champ `unitPrice Decimal` sur `ReturnRecord` au moment de la création (plus simple, recommandé)
- **Recommandé** : ajouter `unitPrice` sur le DTO de création de retour (story 27-1) et le persister sur `ReturnRecord`. Si 27-1 est déjà merged sans ce champ, faire une micro-migration dans cette story.

### Jointure par plage de dates

- La jointure se fait via `ReturnRecord.createdAt` dans la plage `[session.openedAt, session.closedAt]`
- Les retours ne sont **pas** liés à une session via FK — intentionnel (un retour peut être fait entre deux sessions)
- La plage temporelle est la seule façon de les rattacher à une session

### Cash théorique

- Seuls les retours `resolution = 'cash_refund'` impactent le cash théorique
- `credit_note` : le crédit va sur le compte client, pas en espèces
- `exchange` : pas de flux monétaire, uniquement mouvement stock

### Architecture Reference

- Le Z-report existant est dans `apps/backend/src/retail/retail-orchestration.service.ts` (ou similaire) — lire le code avant de modifier
- Frontend Z-report : localiser via `receipt_dialog.dart` ou chercher `zreport` / `Z-Report` dans le codebase

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR98]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 27-3]
- [Source: apps/backend/src/retail/retail-orchestration.service.ts — Z-report existant]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart — affichage rapport]
- [Source: 27-1-return-backend.md — ReturnsService pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
