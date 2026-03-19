# Story 19.5 — Frontend : Formulaire Création Tenant + Gestion Modules & Users

## Metadata

- **Epic:** Epic 19 — Admin Backoffice — Gestion Plateforme
- **Story ID:** 19-5-admin-frontend-tenant-crud
- **Status:** review
- **Priority:** High
- **Depends on:** 19-4 (AdminShell en place), 19-1, 19-2, 19-3 (endpoints disponibles)

---

## Story

**As a** superadmin,
**I want** forms to create a new client and manage their modules and users,
**So that** onboarding is a guided flow with no SQL required.

---

## Context

Cette story implémente le flux complet d'onboarding client :
1. Formulaire "Nouveau client" → `POST /admin/tenants`
2. Détail tenant avec 3 onglets : Infos, Modules, Users
3. Onglet Modules : toggle switch par module
4. Onglet Users : liste + ajout + modification rôle + désactivation

### Endpoints consommés

- `POST /admin/tenants` — création (Story 19-1)
- `GET /admin/tenants/:tenantId/modules` — statut modules (Story 19-2)
- `POST /admin/tenants/:tenantId/modules/:code/activate` — activer (Story 19-2)
- `POST /admin/tenants/:tenantId/modules/:code/deactivate` — désactiver (Story 19-2)
- `GET /admin/tenants/:tenantId/users` — liste users (Story 19-3)
- `POST /admin/tenants/:tenantId/users` — créer user (Story 19-3)
- `PATCH /admin/tenants/:tenantId/users/:userId` — changer rôle (Story 19-3)
- `DELETE /admin/tenants/:tenantId/users/:userId` — désactiver (Story 19-3)

---

## Acceptance Criteria

### AC1 — NewTenantForm

Déclenché par le FAB "Nouveau client" dans `AdminTenantsScreen`.

Champs du formulaire :
- **Nom boutique** (TextFormField, required, max 100 chars)
- **Email owner** (TextFormField, required, format email validé)
- **Mot de passe owner** (TextFormField, obscureText, required, min 8 chars, avec icône show/hide)
- **Devise** (DropdownButtonFormField) : options XOF (défaut), EUR, USD, MAD
- **Timezone** (DropdownButtonFormField) : options Africa/Abidjan (défaut), Africa/Dakar, Africa/Lagos, Europe/Paris
- **Type métier** (Radio — lecture seule, "Retail" pré-sélectionné, grisé — seul choix MVP)

Validation locale :
- Nom vide → "Le nom est obligatoire"
- Email invalide → "Email invalide"
- Mot de passe < 8 chars → "Au moins 8 caractères requis"

Submit → `POST /admin/tenants` :
- **Succès (201)** : snackbar vert "Client [nom] créé avec succès", formulaire fermé, `adminTenantsProvider.refresh()` pour recharger la liste
- **Erreur 422 email existant** : snackbar rouge "Cet email est déjà utilisé"
- **Erreur réseau** : snackbar rouge "Erreur de connexion — réessayez"
- Bouton Submit affiche `CircularProgressIndicator` pendant la requête (désactivé pour éviter double-soumission)

### AC2 — TenantDetailScreen

Déclenché par tap sur une Card tenant dans `AdminTenantsScreen`.

En-tête :
- Nom du tenant (titleLarge)
- Badge statut (même couleurs que la liste)
- Devise et timezone (bodySmall, texte secondaire)

3 onglets via `DefaultTabController` :
- **Infos** — recap des infos (nom, email owner, devise, timezone, date création, modules count)
- **Modules** — `TenantModulesTab` (AC3)
- **Users** — `TenantUsersTab` (AC4)

### AC3 — TenantModulesTab

Charge `GET /admin/tenants/:tenantId/modules` via `tenantModulesProvider(tenantId)`.

Chaque module est affiché comme une `ListTile` avec :
- **Leading** : icône selon le type (`shared` = `extension`, `vertical` = `store`)
- **Title** : nom du module
- **Subtitle** : type badge + dépendances (ex: "Dépend de : catalog, inventory")
- **Trailing** : `Switch` — `value` = `status == 'active'`

Comportement du Switch :
- Toggle ON → `POST .../activate`
  - Succès → `status` passe à `active`, Switch reste ON
  - Erreur 422 MISSING_DEPENDENCY → Switch revient OFF, snackbar "Activez d'abord : [missing modules]"
- Toggle OFF → `POST .../deactivate`
  - Succès → `status` passe à `inactive`, Switch reste OFF
  - Erreur 422 HAS_DEPENDENTS → Switch revient ON, snackbar "Désactivez d'abord : [dependent modules]"
- Pendant la requête : Switch désactivé (non-interactif), indicateur de chargement

### AC4 — TenantUsersTab

Charge `GET /admin/tenants/:tenantId/users` via `tenantUsersProvider(tenantId)`.

Liste des users : `ListTile` avec :
- **Leading** : avatar avec initiale de l'email
- **Title** : email
- **Subtitle** : "Rôle : [owner/manager/cashier] • Dernière connexion : [date ou Jamais]"
- **Trailing** : `IconButton(Icons.more_vert)` → bottom sheet avec options

Bottom sheet options :
- "Changer le rôle" → `RoleChangeDialog` (DropdownButton : owner/manager/cashier) → `PATCH .../users/:userId`
- "Désactiver l'accès" → `AlertDialog` "Confirmer la désactivation de [email] ?" → `DELETE .../users/:userId`

Bouton "+" (AppBar action) → `AddUserDialog` :
- Email (required, format email)
- Mot de passe (required, min 8 chars)
- Rôle (DropdownButton : owner/manager/cashier, défaut manager)
- Submit → `POST .../users`
  - Succès : dialog fermé, liste rafraîchie, snackbar "Utilisateur ajouté"
  - Erreur 422 EMAIL_ALREADY_EXISTS : snackbar "Cet email est déjà utilisé"

### AC5 — Tests widget

- `NewTenantForm` : champs vides → validation → messages d'erreur affichés
- Submit valide → `adminApiService.createTenant()` appelé avec les bons paramètres
- Erreur 422 → snackbar rouge avec message approprié
- `TenantModulesTab` : switch toggle ON → `activateModule()` appelé ; erreur 422 → toggle revert + snackbar
- `TenantUsersTab` : bouton "+" → dialog affiché ; submit → `createUser()` appelé
- Delete user → confirmation dialog → `removeUser()` appelé si confirmé

---

## Tasks/Subtasks

- [x] **Task 1 : NewTenantForm**
  - [x] Créer `lib/features/admin/presentation/screens/new_tenant_form.dart`
  - [x] Validation locale avec `GlobalKey<FormState>`
  - [x] Submit → `AdminApiService.createTenant(dto)` → gestion succès/erreur
  - [x] Désactivation du bouton pendant la requête

- [x] **Task 2 : TenantDetailScreen**
  - [x] Créer `lib/features/admin/presentation/screens/tenant_detail_screen.dart`
  - [x] `DefaultTabController` avec 3 onglets
  - [x] En-tête avec nom, badge statut, infos secondaires

- [x] **Task 3 : TenantModulesTab**
  - [x] Créer `lib/features/admin/presentation/widgets/tenant_modules_tab.dart`
  - [x] `tenantModulesProvider(tenantId)` — FutureProvider
  - [x] Switch avec `_toggling` set + revert via `ref.invalidate()` sur erreur

- [x] **Task 4 : TenantUsersTab + dialogs**
  - [x] Créer `lib/features/admin/presentation/widgets/tenant_users_tab.dart`
  - [x] `tenantUsersProvider(tenantId)` — FutureProvider
  - [x] `AddUserDialog` widget
  - [x] `RoleChangeDialog` widget
  - [x] Bottom sheet avec options More

- [x] **Task 5 : AdminApiService (extension)**
  - [x] Ajouter dans `admin_api_service.dart` :
    - `createTenant(dto)` → POST /admin/tenants
    - `getTenantModules(tenantId)` → GET /admin/tenants/:id/modules
    - `activateModule(tenantId, code)` → POST .../activate
    - `deactivateModule(tenantId, code)` → POST .../deactivate
    - `getTenantUsers(tenantId)` → GET /admin/tenants/:id/users
    - `createTenantUser(tenantId, dto)` → POST .../users
    - `updateUserRole(tenantId, userId, role)` → PATCH .../users/:userId
    - `removeUser(tenantId, userId)` → DELETE .../users/:userId

- [x] **Task 6 : Models**
  - [x] `TenantModuleStatus` — code, name, type, status, activatedAt
  - [x] `TenantUser` — userId, email, role, createdAt, lastSignInAt
  - [x] `CreateTenantDto` — name, ownerEmail, ownerPassword, currency, timezone

- [x] **Task 7 : Tests widget**
  - [x] Tests `NewTenantForm`
  - [x] Tests `TenantModulesTab`
  - [x] Tests `TenantUsersTab`

---

## Dev Notes

- `tenantModulesProvider(tenantId)` doit être un `FutureProvider.family<List<TenantModuleStatus>, String>`
- Pour le revert du Switch sur erreur : utiliser un état local `bool _isToggling` + `ValueNotifier` ou Riverpod `StateProvider`
- `AddUserDialog` et `RoleChangeDialog` peuvent être des `StatefulWidget` simples avec `showDialog()`
- Pas de cache Isar pour l'admin — `ref.invalidate(tenantModulesProvider(tenantId))` après chaque mutation (prefer `invalidate` over `refresh` to avoid lint warning)
- `Supabase.instance` access wrapped in try/catch in `_token` getter — prevents `StateError` in test environments where Supabase is not initialized
- `DropdownButtonFormField.initialValue` used instead of deprecated `value` (Flutter 3.32+)
- `TenantModulesTab` has no `Scaffold` — designed to be embedded in `TenantDetailScreen`'s `TabBarView`; test wrapper must include a `Scaffold` for `Material` context

---

## Dev Agent Record

**Agent:** Claude Sonnet 4.6
**Completed:** 2026-03-17
**Tests:** 9 new widget tests added, all passing (163 total — 1 pre-existing failure in catalog_screen_test.dart unrelated to this story)

### Implementation Notes

- `_token` getter is defensive: `try { return Supabase.instance.client.auth.currentSession?.accessToken ?? ''; } catch (_) { return ''; }` — prevents test-environment crash
- Switch revert: uses `Set<String> _toggling` to show `CircularProgressIndicator` during API call; `ref.invalidate()` restores provider state on error
- `nonNulls.join()` used in module subtitle to handle nullable `depText` cleanly
- Bottom-sheet navigation captured before `await` to avoid `BuildContext` across async gap lint warning

### File List

**New files:**

- `apps/frontend/lib/features/admin/data/models/tenant_module_status.dart`
- `apps/frontend/lib/features/admin/data/models/tenant_user.dart`
- `apps/frontend/lib/features/admin/data/models/create_tenant_dto.dart`
- `apps/frontend/lib/features/admin/presentation/screens/new_tenant_form.dart`
- `apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart`
- `apps/frontend/lib/features/admin/presentation/widgets/tenant_modules_tab.dart`
- `apps/frontend/lib/features/admin/presentation/widgets/tenant_users_tab.dart`
- `apps/frontend/test/admin_crud_test.dart`

**Modified files:**

- `apps/frontend/lib/features/admin/data/services/admin_api_service.dart` — added `AdminApiException` + 8 API methods
- `apps/frontend/lib/features/admin/presentation/providers/admin_providers.dart` — added `tenantModulesProvider` + `tenantUsersProvider` family providers
- `apps/frontend/lib/features/admin/presentation/screens/admin_tenants_screen.dart` — wired FAB → `NewTenantForm`, card tap → `TenantDetailScreen`

### Change Log

| File | Change |
| ---- | ------ |
| `admin_api_service.dart` | Added `AdminApiException`, `createTenant`, `getTenantModules`, `activateModule`, `deactivateModule`, `getTenantUsers`, `createTenantUser`, `updateUserRole`, `removeUser` |
| `admin_providers.dart` | Added `_token()` top-level function, `tenantModulesProvider`, `tenantUsersProvider` |
| `admin_tenants_screen.dart` | Added navigation imports and wired FAB + card tap |
| `new_tenant_form.dart` | New — full form with validation, submit, error handling |
| `tenant_detail_screen.dart` | New — 3-tab detail screen |
| `tenant_modules_tab.dart` | New — module list with toggle switches |
| `tenant_users_tab.dart` | New — user list with add/role-change/remove dialogs |
| `admin_crud_test.dart` | New — 9 widget tests covering AC1, AC3, AC4 |
