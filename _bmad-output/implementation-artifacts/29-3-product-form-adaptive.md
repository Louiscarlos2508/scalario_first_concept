# Story 29.3 — Frontend backoffice — ProductFormDialog adaptatif selon businessType (FR105)

## Metadata

- **Epic:** Epic 29 — Types de Business Configurables
- **Story ID:** 29-3-product-form-adaptive
- **Status:** done
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 29-1 (endpoint `GET /business-type/config` à ajouter dans BusinessTypeController)

---

## Story

**As a** tenant owner,
**I want** the product creation/edit form to automatically show relevant fields first, pre-fill flag defaults, and hide non-relevant fields behind an "Afficher plus d'options" toggle based on my business type,
**So that** I can create products faster without being overwhelmed by irrelevant options, while keeping full control over every flag (FR105).

---

## Acceptance Criteria

### AC1 — Chargement de la config businessType au démarrage

**Given** le propriétaire ouvre l'application backoffice
**When** la session est établie
**Then** la config du type de business est chargée depuis `GET /api/v1/business-type/config` (endpoint tenant-scoped qui retourne le `BusinessTypeDefinition` correspondant à `Tenant.businessType`)
**And** la config est mise en cache localement (valide pour la durée de la session)

### AC2 — Sections visibles déterminées par visibleSections

**Given** le propriétaire ouvre `ProductFormDialog` pour créer ou éditer un produit
**When** son `businessType` est `"telephonie"` (visibleSections: ["variants", "serial", "warranty"])
**Then** les sections "Variantes", "Numéro de série" et "Garantie" sont affichées par défaut dans le formulaire
**And** les autres sections (ex: "Date de péremption", "Ordonnance") sont masquées par défaut

### AC3 — defaultFlags pré-remplissent les flags produit (création seulement)

**Given** le propriétaire ouvre `ProductFormDialog` pour créer un nouveau produit
**When** son `businessType` est `"telephonie"` (defaultFlags: { hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 })
**Then** le champ `hasVariants` est coché (true) par défaut
**And** le champ `trackSerialNumbers` est coché (true) par défaut
**And** le champ `warrantyMonths` est pré-rempli à `12`
**When** son `businessType` est `"generaliste"` (defaultFlags: {})
**Then** tous les flags sont décochés et tous les champs optionnels sont vides par défaut

### AC4 — Toggle "Afficher plus d'options"

**Given** des sections sont masquées par défaut (non listées dans `visibleSections`)
**When** le propriétaire clique sur "Afficher plus d'options"
**Then** toutes les sections cachées deviennent visibles dans le formulaire
**And** le libellé du bouton devient "Masquer les options avancées"
**When** il clique à nouveau
**Then** les sections non-pertinentes sont à nouveau masquées (sans effacer les valeurs saisies)

### AC5 — Override libre par le propriétaire

**Given** le formulaire est pré-rempli avec les defaults du businessType
**When** le propriétaire décoche `trackSerialNumbers` ou modifie `warrantyMonths`
**Then** la valeur saisie est respectée et sauvegardée telle quelle
**And** aucun message d'avertissement ni blocage n'est affiché — l'override est silencieux et immédiat

### AC6 — Produits existants non affectés

**Given** le propriétaire édite un produit existant dont les flags ont été saisis manuellement
**When** le formulaire se charge
**Then** les valeurs sauvegardées du produit sont affichées (non écrasées par les defaults du businessType)
**And** les defaults du businessType s'appliquent uniquement à la création de nouveaux produits (quand `product == null`)

---

## Tasks / Subtasks

- [ ] **Task 1 — Endpoint backend `GET /business-type/config`** (AC1)
  - [ ] Dans `apps/backend/src/kernel/business-type/business-type.controller.ts`, ajouter :
    ```typescript
    @Get('business-type/config')
    @UseGuards(JwtAuthGuard, TenantGuard)
    async getMyConfig(@Req() req) {
      const tenantId = req.tenantId; // peuplé par TenantGuard
      const tenant = await this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: { businessType: true },
      });
      return this.businessTypeService.getDefinition(tenant?.businessType ?? 'generaliste');
    }
    ```
  - [ ] Ce endpoint n'est PAS sous `admin/` — il est tenant-scoped et protégé par `TenantGuard` seul
  - [ ] Si le `businessType` du tenant ne correspond à aucun type actif, retourner le type `"generaliste"` par défaut (fallback gracieux)

- [ ] **Task 2 — BusinessTypeConfigRepository Flutter** (AC1)
  - [ ] Créer `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart`
    - `Future<BusinessTypeConfig> getMyConfig()` → `GET /api/v1/business-type/config`
    - Modèle `BusinessTypeConfig { code, name, defaultFlags (Map<String, dynamic>), visibleSections (List<String>), suggestedCategories (List<String>) }`
    - Récupérer le token via le pattern standard du projet (Supabase `accessToken`)

- [ ] **Task 3 — businessTypeConfigProvider Riverpod** (AC1)
  - [ ] Créer `apps/frontend/lib/features/shared/business_type/presentation/providers/business_type_config_provider.dart`
    - `businessTypeConfigProvider` → `FutureProvider<BusinessTypeConfig>` (ou `AsyncNotifierProvider`)
    - La config est mise en cache automatiquement par Riverpod (pas d'invalidation prévue sauf déconnexion)
    - Pattern : `ref.watch(businessTypeConfigRepository).getMyConfig()`

- [ ] **Task 4 — ProductFormDialog : adaptation selon visibleSections** (AC2, AC4)
  - [ ] Localiser `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart`
  - [ ] Ajouter `bool _showAdvanced = false;` dans l'état du widget
  - [ ] Implémenter `bool _showSection(String section, List<String> visibleSections)` :
    ```dart
    bool _showSection(String section, List<String> visibleSections) {
      return _showAdvanced || visibleSections.isEmpty || visibleSections.contains(section);
    }
    ```
  - [ ] Entourer chaque section optionnelle (expiry, variants, serial, warranty, prescription, weight) par un `if (_showSection('expiry', config.visibleSections))` guard
  - [ ] Ajouter un bouton toggle sous les champs de base :
    ```dart
    TextButton.icon(
      onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
      icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
      label: Text(_showAdvanced ? 'Masquer les options avancées' : 'Afficher plus d\'options'),
    )
    ```
  - [ ] Le bouton toggle est toujours visible même si `visibleSections` est vide (cas généraliste)

- [ ] **Task 5 — ProductFormDialog : pré-remplissage des defaults (création seulement)** (AC3, AC5, AC6)
  - [ ] Détecter si le formulaire est en mode création (`widget.product == null`)
  - [ ] Si création, initialiser les contrôleurs/valeurs avec `config.defaultFlags` :
    ```dart
    if (widget.product == null) {
      final flags = config.defaultFlags;
      _hasVariants = flags['hasVariants'] as bool? ?? false;
      _trackSerialNumbers = flags['trackSerialNumbers'] as bool? ?? false;
      _warrantyMonths = flags['warrantyMonths'] as int?;
      _expiryDays = flags['expiryDays'] as int?;
    }
    ```
  - [ ] Si édition (`widget.product != null`), conserver les valeurs existantes du produit

- [ ] **Task 6 — Intégration dans ProductFormDialog** (AC1–AC6)
  - [ ] `ProductFormDialog` est un `ConsumerStatefulWidget` (ou y ajouter `ConsumerStatefulWidget`)
  - [ ] Lire `businessTypeConfigProvider` dans `build()` :
    ```dart
    final configAsync = ref.watch(businessTypeConfigProvider);
    ```
  - [ ] Gérer les états loading/error : afficher l'intégralité du formulaire sans adaptation si config non dispo (fallback gracieux)

---

## Files to Create

- `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart`
- `apps/frontend/lib/features/shared/business_type/presentation/providers/business_type_config_provider.dart`

## Files to Modify

- `apps/backend/src/kernel/business-type/business-type.controller.ts` — ajouter `GET /business-type/config` (tenant-scoped)
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — adapter selon `visibleSections` et `defaultFlags`

---

## Dev Notes

### Endpoint tenant-scoped vs admin

`GET /business-type/config` est différent de `GET /admin/business-types`. Il ne requiert pas `SuperAdminGuard` — juste `JwtAuthGuard` + `TenantGuard`. L'utilisateur n'a pas besoin de connaître tous les types, seulement le sien. Le `tenantId` vient du contexte de requête peuplé par `TenantGuard`.

### Fallback gracieux si businessType inconnu

Si le `businessType` d'un tenant (`"retail"` par exemple, type legacy) ne correspond à aucun `BusinessTypeDefinition`, retourner silencieusement le type `"generaliste"` (aucune section masquée, aucun default). Ne jamais lever d'erreur côté client sur la config business type.

### ProductFormDialog — vérifier si ConsumerStatefulWidget

Avant d'implémenter, lire `product_form_dialog.dart` pour vérifier si c'est déjà un `ConsumerStatefulWidget` (Riverpod). Si c'est un `StatefulWidget` standard, le convertir en `ConsumerStatefulWidget` + `ConsumerState`.

### Sections à couvrir

Les sections connues du `ProductFormDialog` à rendre conditionnelles selon `visibleSections` :

| Clé section | Champs associés |
| :--- | :--- |
| `variants` | Variantes (tailles, couleurs) |
| `serial` | Numéros de série (`trackSerialNumbers`) |
| `warranty` | Garantie (`warrantyMonths`) |
| `expiry` | Date de péremption (`expiryDays`) |
| `prescription` | Ordonnance requise (`requiresPrescription`) |
| `weight` | Unité de poids (`unitType`) |

Les champs de base (nom, SKU, prix, stock, catégorie) sont toujours visibles — ne jamais les conditionner.

### Cache de la config

`businessTypeConfigProvider` est un `FutureProvider` — Riverpod le met en cache jusqu'à invalidation. Aucune logique de cache manuelle nécessaire. La config change rarement (seulement si le superadmin modifie le `businessType` du tenant via Story 29-2), donc une invalidation à la reconnexion suffit.

### Test de l'adaptation

Pour tester manuellement : créer un tenant `telephonie`, se connecter en tant que propriétaire, ouvrir un nouveau produit → les sections "Variantes", "Numéro de série", "Garantie" doivent être visibles par défaut, "Date de péremption" masquée. Cliquer sur "Afficher plus d'options" → toutes les sections apparaissent.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 29-3]
- [Source: _bmad-output/planning-artifacts/prd.md — FR105]
- [Source: apps/backend/src/kernel/business-type/business-type.controller.ts — pattern controller (créé en 29-1)]
- [Source: apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart — widget à adapter]
- [Source: apps/backend/src/kernel/billing/billing.guard.ts — pattern TenantGuard + JwtAuthGuard]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `GET /business-type/config` added to `BusinessTypeController` (tenant-scoped, `@Roles('owner', 'manager', 'cashier')`, `@CurrentTenant()`)
- `BusinessTypeService.getMyConfig(tenantId)` added — fallback to 'generaliste' if tenant type unknown or inactive
- `BusinessTypeConfig` model + `BusinessTypeConfigRepository` created in `features/shared/business_type/data/`
- `businessTypeConfigProvider` (FutureProvider) created in `features/shared/business_type/presentation/providers/`
- `ProductFormDialog` already a `ConsumerStatefulWidget` — no conversion needed
- Defaults applied via `ref.listen()` (not `initState`) because the config is async
- `_showSection('variants', visibleSections)` — variants block wrapped at `if (widget.submitToCatalog && ...)` level
- serial, prescription, warranty wrapped individually inside the `if (widget.submitToCatalog)` block
- `dynamic_pricing` and `is_unique` always visible (not in visibleSections spec)
- Pre-existing `value:` → `initialValue:` deprecation on unit type dropdown also fixed
- dart analyzer: 0 errors, 0 warnings on all modified files

### File List

- `apps/backend/src/admin/business-type/business-type.service.ts` (modified — `getMyConfig`)
- `apps/backend/src/admin/business-type/business-type.controller.ts` (modified — `GET /business-type/config`)
- `apps/frontend/lib/features/shared/business_type/data/business_type_config_repository.dart` (created)
- `apps/frontend/lib/features/shared/business_type/presentation/providers/business_type_config_provider.dart` (created)
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` (modified — adaptive form)
