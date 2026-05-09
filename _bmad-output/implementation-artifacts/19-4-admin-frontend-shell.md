# Story 19.4 — Frontend : Admin Shell avec Navigation

## Metadata

- **Epic:** Epic 19 — Admin Backoffice — Gestion Plateforme
- **Story ID:** 19-4-admin-frontend-shell
- **Status:** review
- **Priority:** High
- **Depends on:** 19-1, 19-2, 19-3 (endpoints backend disponibles), Epic 15 (DashboardShell pattern)

---

## Story

**As a** superadmin,
**I want** a dedicated admin dashboard to appear when I log in,
**So that** I can manage the platform without seeing the retail POS interface.

---

## Context

### Routing actuel dans main.dart

```dart
data: (profile) {
  if (profile?.role == 'cashier') {
    return const PosScreen();
  }
  return const DashboardScreen();
},
```

Le `superadmin` tombe actuellement dans `DashboardScreen()` — il voit le backoffice retail.
Cette story ajoute la branche `superadmin` pour rediriger vers `AdminDashboard`.

### Pattern de navigation existant

`DashboardShell` (Epic 15) utilise `NavigationRail` sur tablet (≥ 1024px) et `NavigationBar` sur mobile.
`AdminDashboard` reproduit ce même pattern avec 3 destinations : Tenants / Modules / Monitoring.

### Rôle superadmin

Dans `OrganizationMember`, le superadmin a `role.name = 'superadmin'` et `role.vertical = 'system'` (ou un vertical dédié).
Dans `UserProfile`, le champ `role` sera `'superadmin'`.

Fichier `UserProfile` : `apps/frontend/lib/core/auth/user_profile.dart` (à vérifier — peut nécessiter d'ajouter 'superadmin' comme valeur valide).

---

## Acceptance Criteria

### AC1 — Routing dans main.dart

```dart
data: (profile) {
  if (profile?.role == 'superadmin') {
    return const AdminDashboard();
  }
  if (profile?.role == 'cashier') {
    return const PosScreen();
  }
  return const DashboardScreen();
},
```

- La branche `superadmin` est vérifiée **avant** `cashier`
- Les autres rôles (owner, manager, cashier) ne voient jamais `AdminDashboard`
- `AdminDashboard` est importé depuis `features/admin/presentation/screens/admin_dashboard.dart`

### AC2 — AdminDashboard avec NavigationRail/BottomNav

**Sur tablet (width ≥ 1024px — `kMedium`) :**
- `NavigationRail` à gauche avec 3 destinations :
  - Index 0 : icône `business`, label "Tenants"
  - Index 1 : icône `extension`, label "Modules"
  - Index 2 : icône `monitor_heart`, label "Monitoring"
- Corps à droite : `AdminTenantsScreen`, `AdminModulesScreen`, ou `AdminMonitoringScreen` selon l'index

**Sur mobile/medium (width < 1024px) :**
- `NavigationBar` (bottom) avec les mêmes 3 destinations
- Corps au-dessus : même switching

Utiliser `LayoutBuilder` et `kMedium = 1024.0` depuis `app_breakpoints.dart`.

### AC3 — AdminTenantsScreen (onglet Tenants)

L'écran "Tenants" affiche la liste des tenants depuis `GET /admin/tenants`.

Chaque tenant apparaît comme une `Card` avec :
- **Nom** (titleMedium)
- **Badge statut** : chip colorée — `active` = vert `#4CAF50`, `suspended` = orange `#FF9800`, `archived` = gris `#9E9E9E`
- **Membres** : texte secondaire "X membres"
- **Modules actifs** : chips horizontales (ex: "catalog", "retail")
- Tap sur la card → navigation vers `TenantDetailScreen` (Story 19.5)

FAB en bas à droite : icône `add`, label "Nouveau client" → navigation vers `NewTenantForm` (Story 19.5)

`FutureProvider` `adminTenantsProvider` watché par l'écran ; affiche `CircularProgressIndicator` pendant le chargement et message d'erreur si offline.

### AC4 — Comportement offline

Quand le device est offline et qu'un provider de l'admin essaie de fetcher :
- Afficher un `Banner` non-bloquant en haut de l'écran : "Connexion requise pour l'administration"
- Pas de crash — juste l'état d'erreur du provider
- Aucune donnée admin n'est mise en cache local (pas d'Isar pour admin)

### AC5 — Tests widget

- `main.dart` : `profile.role == 'superadmin'` → `AdminDashboard` rendu (widget test)
- `profile.role == 'cashier'` → `PosScreen` inchangé
- `profile.role == 'owner'` → `DashboardScreen` inchangé
- `AdminDashboard` sur width 600 → `NavigationBar` rendu
- `AdminDashboard` sur width 1200 → `NavigationRail` rendu

---

## Tasks/Subtasks

- [x] **Task 1 : AdminDashboard widget**
  - [x] Créer `lib/features/admin/presentation/screens/admin_dashboard.dart`
  - [x] `LayoutBuilder` avec `kMedium` breakpoint
  - [x] `NavigationRail` (tablet) + `NavigationBar` (mobile) avec 3 destinations
  - [x] State management : `_selectedIndex` via `StatefulWidget`

- [x] **Task 2 : AdminTenantsScreen**
  - [x] Créer `lib/features/admin/presentation/screens/admin_tenants_screen.dart`
  - [x] Liste de tenants depuis `adminTenantsProvider`
  - [x] Card avec nom, badge statut, membres count, modules chips
  - [x] FAB "Nouveau client"

- [x] **Task 3 : AdminProviders**
  - [x] Créer `lib/features/admin/presentation/providers/admin_providers.dart`
  - [x] `adminTenantsProvider` — `FutureProvider<List<TenantSummary>>`
  - [x] `TenantSummary` model (id, name, status, currency, membersCount, activeModules)
  - [x] `AdminApiService` — HTTP GET `/admin/tenants` avec auth header

- [x] **Task 4 : Routing main.dart**
  - [x] Modifier `lib/main.dart` — ajouter branche `superadmin` avant `cashier`
  - [x] Import `AdminDashboard`

- [x] **Task 5 : Placeholders screens**
  - [x] Créer `lib/features/admin/presentation/screens/admin_modules_screen.dart` — placeholder
  - [x] Créer `lib/features/admin/presentation/screens/admin_monitoring_screen.dart` — placeholder

- [x] **Task 6 : Tests widget**
  - [x] Test routing `main.dart` selon `profile.role` (3 tests)
  - [x] Test responsive `AdminDashboard` (NavigationRail vs NavigationBar + destinations)

---

## Dev Notes

- `UserProfile` : vérifier `lib/core/auth/user_profile.dart` — s'assurer que `'superadmin'` est géré (pas bloqué par un enum ou une validation)
- `AdminApiService` doit inclure le JWT Bearer token (même pattern que les autres services HTTP)
- Ne pas utiliser Isar pour le cache admin — `FutureProvider` avec refresh manuel suffit
- Le placeholder `AdminModulesScreen` peut être un `Scaffold` simple avec `Center(child: Text('Modules — bientôt disponible'))` pour débloquer les tests de navigation

---

## Dev Agent Record

### Implementation Plan

- `AdminDashboard` — `StatefulWidget` avec `LayoutBuilder` + `kMedium = 1024px` ; `NavigationRail` (≥ 1024px) + `NavigationBar` (< 1024px) ; `IndexedStack` pour préserver l'état des 3 screens
- `AdminTenantsScreen` — `ConsumerWidget` qui watch `adminTenantsProvider` ; `MaterialBanner` en erreur (offline) ; `Card` avec `_StatusChip` colorée + `Wrap` pour les modules ; FAB "Nouveau client"
- `AdminApiService` — pattern identique à `SduiService` : `http.Client` injectable, `ApiConstants.headers(token: token)` sans `x-tenant-id`
- `adminTenantsProvider` — `FutureProvider` qui lit `Supabase.instance.client.auth.currentSession?.accessToken`
- `main.dart` — branche `superadmin` ajoutée AVANT `cashier` (guard order critique)
- Tests : `ProviderScope` overrides de `userProfileProvider` + `adminTenantsProvider` ; `setSurfaceSize` pour les breakpoints responsive

### Completion Notes

- ✅ 6 nouveaux tests widget, tous verts
- ✅ 155/155 tests Flutter totaux (1 échec pre-existing dans catalog_screen_test.dart — non causé par cette story)
- ✅ `superadmin` routing : 3 tests (superadmin→AdminDashboard, cashier→PosScreen path, owner→DashboardScreen path)
- ✅ `AdminDashboard` responsive : 3 tests (width 600→NavigationBar, width 1200→NavigationRail, 3 destinations présentes)
- ✅ `UserProfile.role` fonctionne via getter `memberships.first.role` — `'superadmin'` géré sans modification
- ✅ `supabase_flutter` conflict résolu via `hide Provider` (même pattern que `auth_state.dart`)

---

## File List

### New Files

- `apps/frontend/lib/features/admin/presentation/screens/admin_dashboard.dart`
- `apps/frontend/lib/features/admin/presentation/screens/admin_tenants_screen.dart`
- `apps/frontend/lib/features/admin/presentation/screens/admin_modules_screen.dart`
- `apps/frontend/lib/features/admin/presentation/screens/admin_monitoring_screen.dart`
- `apps/frontend/lib/features/admin/presentation/providers/admin_providers.dart`
- `apps/frontend/lib/features/admin/data/services/admin_api_service.dart`
- `apps/frontend/lib/features/admin/data/models/tenant_summary.dart`
- `apps/frontend/test/admin_routing_test.dart`
- `apps/frontend/test/admin_dashboard_test.dart`

### Modified Files

- `apps/frontend/lib/main.dart` — ajout branche `superadmin` + import `AdminDashboard`

---

## Change Log

- 2026-03-17 — Story 19-4 implémentée : AdminDashboard (NavigationRail/NavigationBar responsive), AdminTenantsScreen (cards + FAB), AdminProviders (FutureProvider + AdminApiService + TenantSummary), routing main.dart superadmin branch, placeholders modules/monitoring. 6 tests widget.

---

## Files structure

```
lib/features/admin/
  presentation/
    screens/
      admin_dashboard.dart
      admin_tenants_screen.dart
      admin_modules_screen.dart      ← placeholder
      admin_monitoring_screen.dart   ← placeholder
    providers/
      admin_providers.dart
  data/
    services/
      admin_api_service.dart
    models/
      tenant_summary.dart
```
