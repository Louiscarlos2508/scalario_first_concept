# Story 17.2 — Frontend : Écran Dépenses + formulaire de saisie

## Metadata
- **Epic:** Epic 17 — Dépenses & Bénéfice
- **Story ID:** 17-2-expenses-frontend
- **Status:** todo
- **Priority:** High
- **Depends on:** 17-1

---

## Story

**As a** manager/owner,
**I want** a dedicated "Dépenses" screen in the backoffice with an add form,
**So that** I can log expenses without leaving the app.

---

## Acceptance Criteria

1. **Liste des dépenses** :
   - Charge `GET /retail/expenses?tenantId=&from=&to=` via `expensesProvider`
   - Affiche label, montant (FCFA), catégorie, date
   - Si vide : message "Aucune dépense enregistrée"

2. **Formulaire d'ajout** (FAB "+") :
   - Label (texte, obligatoire)
   - Montant (numérique, obligatoire)
   - Catégorie (dropdown : `Loyer` / `Salaire` / `Électricité` / `Autre`)
   - Date (date picker, défaut = aujourd'hui)
   - Notes (texte, optionnel)
   - Submit → `POST /retail/expenses` → snackbar "Dépense enregistrée" + refresh liste

3. **Suppression** :
   - Swipe ou bouton "Supprimer" sur une ligne
   - `DELETE /retail/expenses/:id` → snackbar "Dépense supprimée" + refresh liste

4. **Gestion d'erreurs** :
   - Erreur réseau → snackbar rouge avec message d'erreur
   - Loading indicator pendant les appels

---

## Structure fichiers

```
lib/features/retail/expenses/
  data/
    models/expense.dart                   ← modèle Dart (fromJson/toJson)
    repositories/expense_repository.dart  ← create / list / delete
  presentation/
    providers/expense_providers.dart      ← expensesProvider (FutureProvider)
    screens/expenses_screen.dart          ← liste + FAB
    widgets/expense_form.dart             ← formulaire ajout
    widgets/expense_list_tile.dart        ← ligne liste
```

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle `Expense`**
  - [ ] `lib/features/retail/expenses/data/models/expense.dart`
  - [ ] `fromJson()` / `toJson()` (catégories comme String)

- [ ] **Task 2 : `ExpenseRepository`**
  - [ ] `create(Expense)` → POST
  - [ ] `list({required String tenantId, DateTime? from, DateTime? to})` → GET
  - [ ] `delete(String id)` → DELETE

- [ ] **Task 3 : Providers Riverpod**
  - [ ] `expensesProvider` — FutureProvider<List<Expense>>
  - [ ] Paramétré par la période active (réutiliser le filtre existant du dashboard)

- [ ] **Task 4 : `ExpensesScreen`**
  - [ ] ListView des `ExpenseListTile`
  - [ ] Empty state
  - [ ] FAB "+" ouvre `ExpenseForm` en bottom sheet / dialog

- [ ] **Task 5 : `ExpenseForm`**
  - [ ] Tous les champs + validation locale
  - [ ] Submit appelle `expenseRepository.create()` + `ref.invalidate(expensesProvider)`

- [ ] **Task 6 : Tests**
  - [ ] Widget test : formulaire présent, champs Label/Montant obligatoires
  - [ ] Submit valide → `ExpenseRepository.create()` appelé avec les bons params
  - [ ] Erreur réseau → snackbar rouge affiché
