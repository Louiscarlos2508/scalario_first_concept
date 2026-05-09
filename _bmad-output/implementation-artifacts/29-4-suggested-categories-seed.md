# Story 29.4 — Backend + Frontend — Pré-création des catégories suggérées à la création du tenant (FR106)

## Metadata

- **Epic:** Epic 29 — Types de Business Configurables
- **Story ID:** 29-4-suggested-categories-seed
- **Status:** done
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 29-1 (BusinessTypeService.seedCategories stub), 29-2 (businessType dans CreateTenantDto)

---

## Story

**As a** tenant owner,
**I want** to find the suggested categories of my business type already created in my catalog when I first log in,
**So that** I can start adding products immediately without manual category setup (FR106).

---

## Acceptance Criteria

### AC1 — Seed des catégories à la création tenant

**Given** le superadmin crée un tenant avec `businessType = "telephonie"` (suggestedCategories: ["Smartphones", "Accessoires", "Cartes SIM", "Recharge", "Réparation"])
**When** le tenant est créé avec succès
**Then** `BusinessTypeService.seedCategories(tenantId, "telephonie")` est appelé automatiquement dans le flux de création
**And** 5 `CatalogCategory` sont créées dans le schéma `shared` pour ce tenant avec les noms correspondants
**And** chaque catégorie a `tenantId` correct, `isActive = true`

### AC2 — Pas de seed pour le type "generaliste"

**Given** le superadmin crée un tenant avec `businessType = "generaliste"` (suggestedCategories: [])
**When** le tenant est créé
**Then** `BusinessTypeService.seedCategories()` est appelé mais ne crée aucune catégorie (liste vide)
**And** aucune erreur n'est levée

### AC3 — Idempotence du seed de catégories

**Given** `BusinessTypeService.seedCategories(tenantId, code)` est appelé deux fois pour le même tenant
**When** la deuxième exécution se produit (ex: retry après erreur réseau)
**Then** aucune catégorie dupliquée n'est créée (upsert ou skip si `name` + `tenantId` existent déjà)

### AC4 — Propriétaire voit les catégories prêtes à l'emploi

**Given** le propriétaire se connecte pour la première fois après la création du tenant
**When** il navigue vers la gestion des catégories dans le backoffice
**Then** les catégories suggérées de son type de business sont listées et actives
**And** il peut immédiatement assigner ces catégories aux produits qu'il crée

### AC5 — Propriétaire peut renommer une catégorie suggérée

**Given** le propriétaire voit la catégorie "Cartes SIM" dans sa liste
**When** il la renomme en "Forfaits & SIM"
**Then** le nom est mis à jour via `PATCH /api/v1/catalog/categories/:id`
**And** aucune contrainte ne bloque le renommage (les catégories suggérées ne sont pas verrouillées)

### AC6 — Propriétaire peut supprimer une catégorie suggérée

**Given** le propriétaire voit la catégorie "Réparation" dans sa liste
**When** il la supprime (soft delete)
**Then** la catégorie est marquée inactive et disparaît de la liste principale
**And** aucune contrainte ne bloque la suppression

### AC7 — Propriétaire peut ajouter de nouvelles catégories

**Given** le propriétaire a ses catégories suggérées créées
**When** il crée une nouvelle catégorie "Dongles WiFi" via l'interface habituelle
**Then** la nouvelle catégorie est créée normalement via `POST /api/v1/catalog/categories`
**And** elle coexiste avec les catégories suggérées sans distinction visuelle particulière

---

## Tasks / Subtasks

- [ ] **Task 1 — BusinessTypeService.seedCategories() — implémentation complète** (AC1, AC2, AC3)
  - [ ] Implémenter `seedCategories(tenantId: string, code: string)` dans `apps/backend/src/kernel/business-type/business-type.service.ts` (stub créé en 29-1)
  - [ ] Récupérer le `BusinessTypeDefinition` via `getDefinition(code)` ; si non trouvé, logger et retourner silencieusement
  - [ ] Si `suggestedCategories` est vide (ex: `"generaliste"`), retourner immédiatement
  - [ ] Pour chaque catégorie dans `suggestedCategories`, créer une `CatalogCategory` via Prisma avec upsert :
    ```typescript
    await this.prisma.catalogCategory.upsert({
      where: { name_tenantId: { name: categoryName, tenantId } },
      update: {},  // ne rien modifier si existe déjà
      create: {
        name: categoryName,
        tenantId,
        isActive: true,
      },
    });
    ```
  - [ ] Vérifier que l'index unique `name_tenantId` existe sur `CatalogCategory` (sinon utiliser `findFirst` + `create` conditionnel)
  - [ ] Émettre un log structuré après le seed :
    ```typescript
    this.logger.log({ event: 'business_type_categories_seeded', tenantId, businessType: code, count: suggestedCategories.length });
    ```
  - [ ] Injecter `PrismaService` (déjà disponible dans `BusinessTypeModule`)

- [ ] **Task 2 — Intégration dans AdminTenantsService.createTenant()** (AC1, AC2)
  - [ ] Dans `apps/backend/src/admin/tenants/admin-tenants.service.ts`, injecter `BusinessTypeService` dans le constructeur
  - [ ] Ajouter `businessType?: string` dans `CreateTenantDto` (ligne 14) avec valeur par défaut `'generaliste'`
  - [ ] Ajouter `businessType: dto.businessType ?? 'generaliste'` dans le `prisma.tenant.create()` (Step 2, ligne 64)
  - [ ] Après l'étape 4 (activation des modules), dans le même try/catch, appeler `seedCategories` en non-bloquant :
    ```typescript
    // Step 5 — Seed suggested categories for the business type (non-blocking)
    const businessType = dto.businessType ?? 'generaliste';
    this.businessTypeService
      .seedCategories(tenant.id, businessType)
      .catch((err) => this.logger.warn(`seedCategories failed for tenant ${tenant.id}: ${err.message}`));
    ```
  - [ ] **Important :** utiliser `.catch()` (fire-and-forget) — un échec du seed ne doit PAS faire échouer la création du tenant ni déclencher la compensation (rollback)
  - [ ] Importer `BusinessTypeModule` dans `AdminTenantsModule` (ou injecter directement le service)

- [ ] **Task 3 — Vérifier AdminTenantsModule** (AC1)
  - [ ] Localiser `apps/backend/src/admin/tenants/admin-tenants.module.ts`
  - [ ] Ajouter `BusinessTypeModule` dans les imports si pas déjà présent
  - [ ] `BusinessTypeModule` doit exporter `BusinessTypeService` (fait en 29-1)

- [ ] **Task 4 — Vérifier la réponse de createTenant()** (AC1)
  - [ ] La réponse actuelle inclut `modulesActivated` (ligne 120) — ne pas modifier ce retour
  - [ ] Optionnel : ajouter `businessType: tenant.businessType` dans l'objet retourné pour confirmation côté admin

- [ ] **Task 5 — Vérifier le modèle CatalogCategory** (AC1, AC3)
  - [ ] Lire `apps/backend/prisma/schema.prisma` pour vérifier le modèle `CatalogCategory` (schéma `shared`)
  - [ ] Confirmer les champs disponibles : `id`, `name`, `tenantId`, `isActive`
  - [ ] Confirmer si un index unique `@@unique([name, tenantId])` existe (nécessaire pour l'upsert idempotent)
  - [ ] Si l'index unique n'existe pas, créer une migration pour l'ajouter ou utiliser `findFirst` + create conditionnel

- [ ] **Task 6 — Frontend : aucun changement requis** (AC4–AC7)
  - [ ] Les catégories apparaissent automatiquement via `GET /api/v1/catalog/categories` déjà implémenté
  - [ ] Vérifier que l'endpoint existant inclut les catégories créées via seed (pas de filtre `createdBy` restrictif)
  - [ ] Aucun widget ni provider Flutter à créer ou modifier pour cette story

---

## Files to Create

_(aucun fichier à créer — uniquement des modifications)_

## Files to Modify

- `apps/backend/src/kernel/business-type/business-type.service.ts` — implémenter `seedCategories(tenantId, code)` complètement
- `apps/backend/src/admin/tenants/admin-tenants.service.ts` — injecter `BusinessTypeService`, ajouter `businessType` dans DTO et `createTenant()`, appeler `seedCategories` en fire-and-forget
- `apps/backend/src/admin/tenants/admin-tenants.module.ts` — importer `BusinessTypeModule`

---

## Dev Notes

### Point d'intégration : AdminTenantsService, pas OrganizationService

Le flux de création admin (déclenché par l'admin panel Flutter) utilise `AdminTenantsService.createTenant()` dans `apps/backend/src/admin/tenants/admin-tenants.service.ts`. C'est là que `seedCategories` doit être intégré.

`OrganizationService.createOrganization()` dans `apps/backend/src/organization/organization.service.ts` est le flux self-service (signup utilisateur final) — il n'est PAS concerné par cette story. La spec epics.md mentionne `OrganizationService` par erreur.

### Fire-and-forget vs try/catch bloquant

Le seed de catégories est **non-bloquant** intentionnellement. L'échec du seed (ex: DB temporairement indisponible) ne doit pas empêcher la création du tenant. Le superadmin peut relancer manuellement via `PATCH /admin/tenants/:id/business-type` si les catégories sont manquantes. Pattern :

```typescript
// ✅ Correct — fire and forget
this.businessTypeService
  .seedCategories(tenant.id, businessType)
  .catch((err) => this.logger.warn(`seedCategories failed: ${err.message}`));

// ❌ Incorrect — bloquant et peut faire échouer le tenant creation
await this.businessTypeService.seedCategories(tenant.id, businessType);
```

### Idempotence via upsert

Si `CatalogCategory` a un `@@unique([name, tenantId])`, l'upsert Prisma garantit l'idempotence. Si cet index n'existe pas, utiliser :
```typescript
const existing = await this.prisma.catalogCategory.findFirst({
  where: { name: categoryName, tenantId },
});
if (!existing) {
  await this.prisma.catalogCategory.create({ data: { name: categoryName, tenantId, isActive: true } });
}
```

### Logger NestJS dans BusinessTypeService

`BusinessTypeService` doit utiliser `Logger` de NestJS pour les logs structurés :
```typescript
private readonly logger = new Logger(BusinessTypeService.name);
```

### CreateTenantDto — backend vs frontend

La `CreateTenantDto` **backend** (dans `admin-tenants.service.ts`, ligne 14) n'a pas de décorateurs de validation — c'est une classe plain. Ajouter simplement `businessType?: string`. Pas besoin de `@IsOptional()` ou `class-validator` ici (cohérent avec le pattern existant de cette classe).

La `CreateTenantDto` **frontend** (dans `create_tenant_dto.dart`) est modifiée en Story 29-2.

### CatalogCategory — schéma à vérifier

Avant d'implémenter, lire `schema.prisma` pour confirmer :
1. Le schéma de `CatalogCategory` (`@@schema("shared")` ou autre)
2. Les champs disponibles (`createdBy` est-il requis ?)
3. L'existence de l'index unique `[name, tenantId]`

Si `createdBy` est requis (non-nullable sans défaut), utiliser un UUID système ou le `userId` du superadmin (passé en paramètre à `seedCategories`). Dans ce cas, la signature devient `seedCategories(tenantId: string, code: string, createdBy?: string)`.

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 29-4]
- [Source: _bmad-output/planning-artifacts/prd.md — FR106]
- [Source: apps/backend/src/admin/tenants/admin-tenants.service.ts — AdminTenantsService.createTenant() — intégration point confirmé par lecture du code]
- [Source: apps/backend/src/organization/organization.service.ts — OrganizationService (self-service flow, NON concerné)]
- [Source: apps/backend/src/kernel/business-type/business-type.service.ts — méthode seedCategories à compléter (stub de 29-1)]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `Category` model (not `CatalogCategory`) at `@@schema("shared")` — no `isActive` field, no `@@unique([name, tenantId])` → used `findFirst` + conditional `create` for idempotence
- `seedCategories()` fully implemented: loads definition, skips if `suggestedCategories` empty, creates missing categories, logs structured event
- `AdminTenantsService.createTenant()` updated: `businessType` added to DTO + `prisma.tenant.create()`, `seedCategories` called fire-and-forget (`.catch()` logger)
- `BusinessTypeService` injected via `AdminModule` imports (already imports `BusinessTypeModule` which exports the service)
- `admin-tenants.service.spec.ts` updated: mock `BusinessTypeService` added, `tenant.create` mocks updated to include `businessType`
- All 18 tests passing (10 admin-tenants + 8 business-type)

### File List

- `apps/backend/src/admin/business-type/business-type.service.ts` (modified — `seedCategories` fully implemented)
- `apps/backend/src/admin/tenants/admin-tenants.service.ts` (modified — `BusinessTypeService` injected, `businessType` in DTO and `createTenant`)
- `apps/backend/src/admin/tenants/admin-tenants.service.spec.ts` (modified — mock `BusinessTypeService`, updated mock return values)
