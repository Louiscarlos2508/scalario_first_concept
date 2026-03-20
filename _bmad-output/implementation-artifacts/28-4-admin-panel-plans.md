# Story 28.4 — Frontend admin — Dropdown plan, onglet Facturation, badge statut (FR100–FR101)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-4-admin-panel-plans
- **Status:** backlog
- **Priority:** Medium
- **Phase:** 2a
- **Depends on:** 28-1 (GET /admin/plans), 28-3 (GET/POST/PATCH /admin/tenants/:id/billing), Epic 19 (admin frontend shell)

---

## Story

**As a** superadmin,
**I want** the admin panel to show a plan dropdown when creating a tenant, a "Facturation" tab in tenant detail, and a billing status badge in the tenant list,
**So that** I can manage plans and billing without leaving the admin interface (FR100, FR101).

---

## Acceptance Criteria

### AC1 — Dropdown plan dans NewTenantForm

**Given** le superadmin ouvre le formulaire de création de tenant
**When** le formulaire est affiché
**Then** un dropdown "Plan" est présent avec les options chargées depuis `GET /api/v1/admin/plans`
**And** le plan `"free"` est sélectionné par défaut
**And** à la sélection d'un plan, les champs `maxUsers`, `suggestedInstallationFee`, `suggestedTrainingFee` sont pré-remplis (modifiables)

**When** le formulaire est soumis
**Then** les valeurs de `installationFee` et `trainingFee` éventuellement modifiées sont envoyées avec la requête de création

### AC2 — Onglet "Facturation" dans TenantDetailScreen

**Given** le superadmin ouvre le détail d'un tenant
**When** il clique sur l'onglet "Facturation"
**Then** il voit :
- Badge plan actuel (coloré : free=gris, standard=bleu, premium=violet, enterprise=or)
- `billingStatus` avec badge coloré (trial=bleu, active=vert, overdue=orange, suspended=rouge)
- `trialEndsAt` formaté (si trial)
- `billingStartDate` formaté
- Frais d'installation : montant + toggle "Payé" (appelle PATCH billing)
- Frais de formation : montant + toggle "Payé" (appelle PATCH billing)
- Champ notes libre (textarea, sauvegardé au blur)
- Liste des `BillingEvent` triés par date DESC (type, montant, statut, date)
**And** chaque `BillingEvent` avec `status = "pending"` a un bouton "Marquer payé"

### AC3 — "Marquer payé" sur BillingEvent

**Given** le superadmin clique "Marquer payé" sur un événement `pending`
**When** il confirme dans un dialog
**Then** `POST /api/v1/admin/tenants/:id/billing/events` est appelé avec `{ type: event.type, amount: event.amount, paidAt: now(), status: "paid" }`
**And** la liste des événements se rafraîchit
**And** si c'est un événement `subscription`, le badge `billingStatus` passe à `"active"`

### AC4 — Badge billing status dans la liste tenants

**Given** le superadmin est sur l'écran liste des tenants
**When** la liste est chargée
**Then** chaque ligne affiche un badge coloré selon `billingStatus` : trial (bleu), active (vert), overdue (orange), suspended (rouge)
**And** un filtre rapide permet d'afficher uniquement les tenants `overdue` ou `suspended`

### AC5 — Bouton "Réactiver" tenant suspendu

**Given** le superadmin est sur l'onglet Facturation d'un tenant suspendu
**When** il clique "Réactiver"
**Then** un dialog de confirmation s'affiche
**When** il confirme
**Then** `PATCH /api/v1/admin/tenants/:id/billing` est appelé avec `{ billingStatus: "active" }`
**And** le badge se met à jour immédiatement

---

## Tasks / Subtasks

- [ ] **Task 1 — BillingRepository Flutter (admin)** (toutes AC)
  - [ ] Créer `apps/frontend/lib/features/admin/billing/data/repositories/billing_repository.dart`
    - `getPlans()` → `GET /admin/plans`
    - `getTenantBilling(tenantId)` → `GET /admin/tenants/:id/billing`
    - `updateTenantBilling(tenantId, payload)` → `PATCH /admin/tenants/:id/billing`
    - `recordBillingEvent(tenantId, payload)` → `POST /admin/tenants/:id/billing/events`

- [ ] **Task 2 — Providers Riverpod** (toutes AC)
  - [ ] Créer `apps/frontend/lib/features/admin/billing/presentation/providers/billing_providers.dart`
    - `planDefinitionsProvider` : `FutureProvider<List<PlanDefinition>>` — cache, chargé une fois
    - `tenantBillingProvider(tenantId)` : `FutureProvider` — rafraîchi après toute mutation

- [ ] **Task 3 — PlanDropdown widget** (AC1)
  - [ ] Créer `apps/frontend/lib/features/admin/billing/presentation/widgets/plan_dropdown.dart`
    - `DropdownButtonFormField` alimenté par `planDefinitionsProvider`
    - `onChanged` : callback qui pré-remplit `maxUsers`, `installationFee`, `trainingFee` dans le formulaire parent

- [ ] **Task 4 — Intégration dans NewTenantForm** (AC1)
  - [ ] Localiser `apps/frontend/lib/features/admin/presentation/widgets/new_tenant_form.dart`
  - [ ] Ajouter `PlanDropdown` dans le formulaire
  - [ ] Ajouter champs `installationFee` et `trainingFee` (pré-remplis, modifiables)
  - [ ] Inclure ces valeurs dans le payload `POST /admin/tenants`

- [ ] **Task 5 — BillingTab widget** (AC2, AC3, AC5)
  - [ ] Créer `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_tab.dart`
    - Section plan + status + dates
    - Toggles "Payé" pour installation et formation
    - Textarea notes (sauvegarde au `onEditingComplete`)
    - Liste `BillingEventTile`
    - Bouton "Réactiver" si `billingStatus = "suspended"`
  - [ ] Créer `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_event_tile.dart`
    - Affiche type, montant formaté FCFA, statut (badge), date
    - Bouton "Marquer payé" si status = "pending"

- [ ] **Task 6 — Intégration onglet Facturation dans TenantDetailScreen** (AC2)
  - [ ] Localiser `TenantDetailScreen` dans le panel admin
  - [ ] Ajouter un `Tab("Facturation")` et `BillingTab` dans la `TabBarView`

- [ ] **Task 7 — Badge billingStatus dans la liste tenants** (AC4)
  - [ ] Localiser `TenantsListScreen` ou équivalent
  - [ ] Ajouter un `Chip` coloré par `billingStatus` sur chaque ligne
  - [ ] Ajouter un `DropdownButton` de filtre : Tous / Overdue / Suspended

---

## Files to Create

- `apps/frontend/lib/features/admin/billing/data/repositories/billing_repository.dart`
- `apps/frontend/lib/features/admin/billing/presentation/providers/billing_providers.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_tab.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/billing_event_tile.dart`
- `apps/frontend/lib/features/admin/billing/presentation/widgets/plan_dropdown.dart`

## Files to Modify

- `apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart` — onglet "Facturation"
- `apps/frontend/lib/features/admin/presentation/screens/tenants_list_screen.dart` — badge + filtre
- `apps/frontend/lib/features/admin/presentation/widgets/new_tenant_form.dart` — dropdown plan + frais

---

## Dev Notes

### Chemin exact du panel admin

Vérifier dans `apps/frontend/lib/features/admin/` — le panel admin a été créé en Epic 19 (story 19-4). Adapter les chemins si la structure est différente.

### Formatage FCFA

Utiliser le helper existant `formatCFA(amount)` ou équivalent pour afficher les montants en FCFA (ex: "15 000 FCFA"). Vérifier dans `apps/frontend/lib/core/utils/`.

### Badge billingStatus — couleurs

```dart
Color statusColor(String status) => switch (status) {
  'trial'     => Colors.blue.shade300,
  'active'    => Colors.green,
  'overdue'   => Colors.orange,
  'suspended' => Colors.red,
  _           => Colors.grey,
};
```

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR100, FR101]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-4]
- [Source: apps/frontend/lib/features/admin/ — Epic 19 panel admin]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
