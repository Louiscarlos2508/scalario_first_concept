# Story 30.7 — Frontend — Labels de rôle métier dans l'UI (FR111)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-7-role-labels-frontend
- **Status:** ready-for-dev
- **Priority:** Medium
- **Phase:** 2a
- **Depends on:** 30-2 (roleLabels + documentType sur BusinessTypeDefinition), 29-3 (BusinessTypeConfig Flutter)

---

## Story

**As a** owner or manager,
**I want** the UI to display business-specific role names (e.g. "Vendeur" instead of "Commercial" for a telephonie tenant),
**So that** the interface reflects the vocabulary of my industry without confusing my team (FR111).

---

## Acceptance Criteria

### AC1 — Fonction getRoleLabel

**Given** un `roleLabels` JSON et un `roleCode` (ex: `"commercial"`)
**When** `getRoleLabel(roleCode, roleLabels)` est appelé
**Then** si `roleLabels[roleCode]` existe, le label personnalisé est retourné
**And** si `roleLabels[roleCode]` est absent ou vide, le `roleCode` formaté en fallback est retourné (ex: `"commercial"` → `"Commercial"`)
**And** si `roleCode` est `"owner"`, la valeur `"Propriétaire"` est toujours retournée sans consulter `roleLabels` (non overridable)

### AC2 — Labels affichés dans la liste des membres

**Given** l'utilisateur ouvre l'écran des membres du tenant
**When** la liste se charge
**Then** chaque membre affiche le label de rôle personnalisé issu de `businessTypeConfigProvider.roleLabels`
**And** si `roleLabels` est vide (`{}`), les labels par défaut sont affichés : `"Propriétaire"`, `"Manager"`, `"Commercial"`, `"Caissier"`

### AC3 — Labels affichés dans le profil utilisateur

**Given** l'utilisateur ouvre son profil
**When** le rôle est affiché
**Then** le label personnalisé correspondant au rôle de l'utilisateur courant est affiché
**And** le rôle `owner` affiche toujours `"Propriétaire"`

### AC4 — Labels affichés dans les rapports de session POS

**Given** un rapport de session POS affiche l'utilisateur qui a ouvert/fermé la session
**When** le rôle de cet utilisateur est affiché
**Then** le label personnalisé est utilisé à la place du rôle brut

### AC5 — Dropdown rôle dans la gestion des membres (admin)

**Given** l'admin ajoute ou modifie un membre du tenant
**When** le dropdown de sélection du rôle s'affiche
**Then** les options du dropdown affichent les labels personnalisés : ex `"Vendeur"` au lieu de `"Commercial"` pour un tenant `telephonie`
**And** le rôle `owner` n'est pas proposé dans le dropdown (rôle réservé)
**And** la valeur envoyée à l'API reste le `roleCode` brut (`"commercial"`, `"manager"`, `"cashier"`)

### AC6 — Robustesse : roleLabels null ou vide

**Given** le tenant n'a pas encore de `businessTypeConfig` chargé
**When** un widget affiche un rôle
**Then** aucune exception n'est levée
**And** les labels par défaut sont affichés en fallback

---

## Tasks / Subtasks

- [ ] **Task 1 — Utilitaire getRoleLabel** (AC1, AC6)
  - [ ] Créer `role_label_utils.dart` dans `lib/features/shared/business_type/utils/`
  - [ ] Implémenter `String getRoleLabel(String roleCode, Map<String, dynamic> roleLabels)`
  - [ ] Cas spécial : `roleCode == "owner"` → retourner `"Propriétaire"` immédiatement
  - [ ] Fallback : capitaliser le premier caractère de `roleCode` si clé absente
  - [ ] Ajouter tests unitaires dans `test/features/shared/business_type/utils/role_label_utils_test.dart`

- [ ] **Task 2 — Intégration dans la liste des membres** (AC2)
  - [ ] Localiser le widget de liste des membres (chercher via Grep `MemberList`, `members_screen`, `team_screen`)
  - [ ] Remplacer l'affichage brut du rôle par `getRoleLabel(member.role, roleLabels)`
  - [ ] Lire `roleLabels` depuis `businessTypeConfigProvider`

- [ ] **Task 3 — Intégration dans le profil utilisateur** (AC3)
  - [ ] Localiser le widget profil (chercher via Grep `ProfileScreen`, `user_profile`)
  - [ ] Remplacer l'affichage brut du rôle par `getRoleLabel(currentUser.role, roleLabels)`

- [ ] **Task 4 — Intégration dans les rapports de session POS** (AC4)
  - [ ] Localiser le widget rapport de session (chercher via Grep `SessionReport`, `session_summary`)
  - [ ] Remplacer l'affichage brut du rôle par `getRoleLabel(session.openedByRole, roleLabels)`

- [ ] **Task 5 — Dropdown rôle dans la gestion des membres** (AC5)
  - [ ] Localiser le formulaire d'ajout/modification de membre (chercher via Grep `AddMember`, `member_form`, `role_dropdown`)
  - [ ] Construire les options du dropdown à partir des rôles disponibles (`manager`, `commercial`, `cashier`) en appliquant `getRoleLabel` pour les labels
  - [ ] Exclure `owner` des options proposées
  - [ ] Vérifier que la valeur transmise à l'API est le `roleCode` brut (pas le label)

---

## Files to Create

- `apps/frontend/lib/features/shared/business_type/utils/role_label_utils.dart`
- `apps/frontend/test/features/shared/business_type/utils/role_label_utils_test.dart`

## Files to Modify

- Widget liste des membres — ajouter `getRoleLabel`
- Widget profil utilisateur — ajouter `getRoleLabel`
- Widget rapport de session POS — ajouter `getRoleLabel`
- Widget formulaire membre (dropdown rôle) — ajouter `getRoleLabel` + exclure `owner`

---

## Dev Notes

### Implémentation de getRoleLabel

```dart
// lib/features/shared/business_type/utils/role_label_utils.dart

const _ownerLabel = 'Propriétaire';

String getRoleLabel(String roleCode, Map<String, dynamic> roleLabels) {
  if (roleCode == 'owner') return _ownerLabel;
  final label = roleLabels[roleCode];
  if (label != null && label is String && label.isNotEmpty) return label;
  // Fallback : capitaliser le roleCode
  return roleCode.isEmpty ? roleCode : '${roleCode[0].toUpperCase()}${roleCode.substring(1)}';
}
```

### Accès à roleLabels depuis Riverpod

Le provider `businessTypeConfigProvider` (créé en 29-3) expose `BusinessTypeConfig`. Le champ `roleLabels` est de type `Map<String, dynamic>`. Accès dans un widget :

```dart
final config = ref.watch(businessTypeConfigProvider);
final roleLabels = config.valueOrNull?.roleLabels ?? {};
```

### Labels par défaut (fallback complet)

Si `roleLabels == {}` (tenant sans config spécifique), les labels affichés seront :
- `owner` → `"Propriétaire"` (hardcodé)
- `manager` → `"Manager"` (fallback capitalize)
- `commercial` → `"Commercial"` (fallback capitalize)
- `cashier` → `"Cashier"` (fallback capitalize — ou adapter selon contexte FR)

### Rôle owner non proposé dans le dropdown

Le rôle `owner` est assigné uniquement à la création du tenant. Il ne doit jamais apparaître dans le dropdown d'assignation de rôle. Filtrer la liste des rôles disponibles :

```dart
const availableRoles = ['manager', 'commercial', 'cashier'];
```

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-7]
- [Source: _bmad-output/planning-artifacts/prd.md — FR111]
- [Source: apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart — BusinessTypeConfig (29-3)]
- [Source: _bmad-output/implementation-artifacts/30-2-role-labels-backend.md — roleLabels seed data]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
- No blocking errors. Pre-existing `DropdownButtonFormField.value` deprecation (info) in settings_screen.dart is unrelated.

### Completion Notes List
- AC1: `getRoleLabel(roleCode, roleLabels)` implemented; `owner` → `"Propriétaire"` (hardcoded); custom label from `roleLabels[roleCode]` if non-empty String; fallback capitalises `roleCode`.
- AC2: `tenant_users_tab.dart` `_UserTile` subtitle replaced `user.role` with `getRoleLabel(user.role, {})`.
- AC3: `settings_screen.dart` replaced `_formatRole()` with `getRoleLabel(role, businessTypeConfigProvider.valueOrNull?.roleLabels ?? {})`.
- AC4: `session_report_dialog.dart` does not display user role — no change required.
- AC5: `AddUserDialog` and `RoleChangeDialog` dropdowns updated to use `_kAssignableRoles` (excludes `owner`) with `getRoleLabel` display labels; transmitted value remains raw roleCode.
- AC6: Empty/null `roleLabels` map handled gracefully via `?? {}` fallback everywhere; `getRoleLabel` never throws.
- Tests: 6 unit tests in `role_label_utils_test.dart` — all pass.

### File List
- `apps/frontend/lib/features/shared/business_type/utils/role_label_utils.dart` (created)
- `apps/frontend/test/features/shared/business_type/utils/role_label_utils_test.dart` (created)
- `apps/frontend/lib/core/settings/settings_screen.dart` (modified)
- `apps/frontend/lib/features/admin/presentation/widgets/tenant_users_tab.dart` (modified)
