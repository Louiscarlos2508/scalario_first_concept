# Story 29.2 — Admin panel — Dropdown "Type de business" dans NewTenantForm + écran types (FR104)

## Metadata

- **Epic:** Epic 29 — Types de Business Configurables
- **Story ID:** 29-2-admin-panel-business-type
- **Status:** done
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 29-1 (endpoints `GET /admin/business-types`, `PATCH /admin/tenants/:id/business-type`)

---

## Story

**As a** superadmin,
**I want** a business type dropdown in the tenant creation form, the assigned type displayed on the tenant detail screen, and a read-only screen listing all available business types,
**So that** I can configure the business context of each tenant at creation time and consult available types from the admin panel (FR104).

---

## Acceptance Criteria

### AC1 — Dropdown "Type de business" dans NewTenantForm

**Given** le superadmin ouvre le formulaire de création de tenant dans l'admin panel Flutter
**When** il arrive sur le champ "Type de business"
**Then** un `DropdownButtonFormField` affiche la liste des types actifs chargée depuis `GET /api/v1/admin/business-types`
**And** la valeur par défaut est `"generaliste"` (Généraliste)
**And** chaque entrée affiche le nom du type (ex: "Téléphonie & Accessoires")

### AC2 — Soumission du formulaire avec businessType

**Given** le superadmin sélectionne un type (ex: `"telephonie"`) et soumet le formulaire
**When** l'appel `POST /api/v1/admin/tenants` est envoyé
**Then** le body inclut `businessType: "telephonie"`
**And** en cas de succès, un message de confirmation indique que les catégories suggérées ont été créées si `businessType != "generaliste"`

### AC3 — Affichage businessType dans TenantDetailScreen

**Given** le superadmin consulte la fiche d'un tenant existant
**When** le tenant a un `businessType` assigné
**Then** le nom complet du type (ex: "Téléphonie & Accessoires") est affiché dans la section informations générales
**And** un bouton "Modifier" ouvre une boîte de dialogue permettant de changer le type via `PATCH /admin/tenants/:id/business-type`

### AC4 — Changement de type depuis TenantDetailScreen

**Given** le superadmin clique sur "Modifier" dans la section type de business
**When** il sélectionne un nouveau type et confirme
**Then** `PATCH /api/v1/admin/tenants/:id/business-type` est appelé
**And** la fiche se met à jour avec le nouveau type affiché
**And** un message d'avertissement indique que les catégories suggérées du nouveau type ne sont pas recréées automatiquement (la création ne se fait qu'à la création initiale du tenant)

### AC5 — Écran lecture seule "Types de business"

**Given** le superadmin navigue vers la section "Types de business" de l'admin panel
**When** l'écran se charge
**Then** la liste de tous les types actifs est affichée avec : code, nom, nombre de catégories suggérées, icône (si disponible)
**And** en tapant sur un type, un panneau de détail affiche `defaultFlags` et `suggestedCategories` en lecture seule
**And** aucun bouton de modification n'est exposé (édition réservée à une Phase 3 du backoffice admin)

---

## Tasks / Subtasks

- [x] **Task 1 — BusinessTypeRepository Flutter** (AC1, AC3, AC4, AC5)
  - [ ] Créer `apps/frontend/lib/features/admin/business_type/data/business_type_repository.dart`
    - `Future<List<BusinessTypeSummary>> listActive(String token)` → `GET /api/v1/admin/business-types`
    - `Future<BusinessTypeDetail> getByCode(String code, String token)` → `GET /api/v1/admin/business-types/:code`
    - `Future<void> assignToTenant(String tenantId, String code, String token)` → `PATCH /api/v1/admin/tenants/:tenantId/business-type`
  - [ ] Modèles locaux Dart :
    - `BusinessTypeSummary { code, name, suggestedCategoriesCount, icon? }`
    - `BusinessTypeDetail { code, name, defaultFlags, visibleSections, suggestedCategories, icon? }`

- [x] **Task 2 — Riverpod providers** (AC1, AC5)
  - [x] `businessTypesProvider` ajouté dans `admin_providers.dart` — `FutureProvider<List<BusinessTypeSummary>>`, pattern identique à `adminTenantsProvider`

- [x] **Task 3 — NewTenantForm : remplacer le placeholder Retail** (AC1, AC2)
  - [x] `InputDecorator` "Type métier" remplacé par `DropdownButtonFormField` chargé depuis `businessTypesProvider`
  - [x] `String _businessType = 'generaliste'` ajouté dans l'état
  - [x] Loading/error states gérés avec `CircularProgressIndicator` et fallback texte
  - [x] `businessType` inclus dans `CreateTenantDto` soumis
  - [x] SnackBar mentionne les catégories créées si `businessType != 'generaliste'`

- [x] **Task 4 — CreateTenantDto Flutter** (AC2)
  - [x] `final String businessType` ajouté avec défaut `'generaliste'`
  - [x] `'businessType': businessType` dans `toJson()`

- [x] **Task 5 — TenantDetailScreen : section type de business** (AC3, AC4)
  - [x] `_InfosTab` converti en `ConsumerStatefulWidget` pour accéder à `businessTypesProvider`
  - [x] Ligne "Type métier" affiche le nom complet via `businessTypesProvider`
  - [x] Bouton "Modifier" ouvre dialog avec dropdown + avertissement catégories
  - [x] Sur confirmation : `assignBusinessType()` + invalidation `adminTenantsProvider`

- [x] **Task 6 — Écran BusinessTypesScreen** (AC5)
  - [x] `business_types_screen.dart` créé : `ConsumerWidget`, `ListView` + `ListTile`, `showModalBottomSheet` avec chips `defaultFlags` + `suggestedCategories`
  - [x] Ajouté dans `AdminDashboard` nav items + `_screens` (index 3)

- [x] **Task 7 — TenantSummary model : champ businessType** (AC3)
  - [x] `final String businessType` ajouté dans `TenantSummary` avec défaut `'generaliste'` et `fromJson` adapté

---

## Files to Create

- `apps/frontend/lib/features/admin/business_type/data/business_type_repository.dart`
- `apps/frontend/lib/features/admin/business_type/presentation/screens/business_types_screen.dart`
- `apps/frontend/lib/features/admin/business_type/presentation/providers/business_type_providers.dart`

## Files to Modify

- `apps/frontend/lib/features/admin/data/models/create_tenant_dto.dart` — ajouter champ `businessType`
- `apps/frontend/lib/features/admin/presentation/screens/new_tenant_form.dart` — remplacer placeholder Retail par dropdown businessType
- `apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart` — section type + bouton Modifier
- `apps/frontend/lib/features/admin/navigation/admin_navigation.dart` — item "Types de business" (vérifier chemin réel)

---

## Dev Notes

### Remplacement du placeholder Retail dans NewTenantForm

Le widget actuel (lignes 208–224 de `new_tenant_form.dart`) est un `InputDecorator` non-interactif affichant "Retail" en texte grisé. Il doit être **entièrement remplacé** (pas complété) par un `DropdownButtonFormField`. Pattern exact à reproduire depuis le dropdown `_billingStatus` existant (lignes 187–205).

```dart
// Avant (supprimer):
InputDecorator(
  decoration: const InputDecoration(labelText: 'Type métier', ...),
  child: Row(children: [Icon(Icons.radio_button_checked, ...), Text('Retail', ...)]),
),

// Après (remplacer par):
DropdownButtonFormField<String>(
  value: _businessType,
  decoration: const InputDecoration(labelText: 'Type de business', border: OutlineInputBorder()),
  items: businessTypes.map((t) => DropdownMenuItem(value: t.code, child: Text(t.name))).toList(),
  onChanged: (v) => setState(() => _businessType = v ?? _businessType),
),
```

### Chargement asynchrone des business types

Le chargement via `businessTypesProvider` est asynchrone. Utiliser le pattern `when` de Riverpod :
```dart
final typesAsync = ref.watch(businessTypesProvider);
// Dans la liste des children du Form :
typesAsync.when(
  data: (types) => DropdownButtonFormField(...),
  loading: () => const CircularProgressIndicator(),
  error: (_, __) => const Text('Erreur chargement types'),
),
```

### TenantSummary — champ businessType

Vérifier `apps/frontend/lib/features/admin/data/models/tenant_summary.dart` (ou équivalent). Si `businessType` est absent, l'ajouter. Le backend `AdminTenantsService.listTenants()` retourne déjà les champs du tenant ; vérifier si `businessType` est dans le select.

### Navigation admin

Vérifier le chemin réel du fichier de navigation admin. Chercher avec Grep pour `admin_navigation` ou `AdminNavigation` dans `apps/frontend/lib/features/admin/`. L'item "Types de business" doit apparaître après "Plans tarifaires" dans le drawer ou la sidebar.

### Token d'authentification

Pattern établi : récupérer le token via `Supabase.instance.client.auth.currentSession?.accessToken ?? ''`. Déjà utilisé dans `new_tenant_form.dart` (ligne 37). Répliquer dans `BusinessTypeRepository`.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 29-2]
- [Source: _bmad-output/planning-artifacts/prd.md — FR104]
- [Source: apps/frontend/lib/features/admin/presentation/screens/new_tenant_form.dart — pattern _billingStatus dropdown]
- [Source: apps/frontend/lib/features/admin/data/models/create_tenant_dto.dart — modèle DTO]
- [Source: apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart — _InfosTab]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `BusinessTypeSummary` model added to `data/models/` (replaces story spec's separate `data/` folder — co-located with other admin models for consistency)
- `fetchBusinessTypes()` + `assignBusinessType()` added to `AdminApiService`
- `businessTypesProvider` added to `admin_providers.dart` (not a separate file — consistent with existing provider pattern)
- `_InfosTab` converted from `StatelessWidget` → `ConsumerStatefulWidget` to manage dialog state and API calls
- `BusinessTypesScreen` shows list + bottom sheet detail with chips for flags/categories
- `AdminDashboard` now has 4 nav items (Tenants, Modules, Monitoring, Types métier)
- Dart analyzer: 0 errors, 0 warnings in admin feature

### File List

- `apps/frontend/lib/features/admin/data/models/business_type_summary.dart` (created)
- `apps/frontend/lib/features/admin/data/models/tenant_summary.dart` (modified — added `businessType`)
- `apps/frontend/lib/features/admin/data/models/create_tenant_dto.dart` (modified — added `businessType`)
- `apps/frontend/lib/features/admin/data/services/admin_api_service.dart` (modified — `fetchBusinessTypes`, `assignBusinessType`)
- `apps/frontend/lib/features/admin/presentation/providers/admin_providers.dart` (modified — `businessTypesProvider`)
- `apps/frontend/lib/features/admin/presentation/screens/new_tenant_form.dart` (modified — replaced placeholder, businessType dropdown)
- `apps/frontend/lib/features/admin/presentation/screens/tenant_detail_screen.dart` (modified — businessType row + Modifier dialog)
- `apps/frontend/lib/features/admin/presentation/screens/business_types_screen.dart` (created)
- `apps/frontend/lib/features/admin/presentation/screens/admin_dashboard.dart` (modified — Types métier nav item)
