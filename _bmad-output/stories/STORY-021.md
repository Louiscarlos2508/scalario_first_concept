# STORY-021 : BDUIService NestJS

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 5
**Status :** review
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-014 (NestJS bootstrap), STORY-015 (JWT Auth + RBAC), STORY-018 (Redis cache infra), STORY-023 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant que** client Flutter Scalario,
> **je veux** récupérer le `ScreenConfig` JSON d'un écran filtré par mon rôle et mon tenant,
> **so that** le backend ne m'envoie jamais des composants que je ne suis pas autorisé à voir, et que le premier rendu d'un écran soit disponible en moins de 20 ms après cache chaud.

---

## Description

### Background

Le BDUIEngine Flutter (STORY-005) ne sait rien : il rend ce qu'on lui donne. Le BDUIService est l'unique source qui détermine ce qu'il reçoit. Si ce service envoie un composant `KPICard CA Total` à un COMMERCIAL, alors le commercial le verra — peu importe combien de `visible_if` sont déclarés ailleurs. La sécurité du Business OS commence ici.

Trois exigences se croisent :

1. **RBAC strict** — pré-filtrer les composants sensibles (CA, marges, rapports d'admin) avant l'envoi. Pas de filtrage côté Flutter sur des données déjà transmises.
2. **Performance offline-first** — Blandine ouvre `/ventes` cinquante fois par jour. Le second `GET` doit être quasi-instantané (cache Redis < 20 ms).
3. **Multi-tenant** — chaque tenant a sa propre version du même `screen_id`. La clé de cache et la clé d'invalidation doivent être tenant-aware.

Cette story implémente la résolution `{tenant, screen, role} → ScreenConfig` filtré, avec cache Redis et invalidation automatique sur changement de config tenant.

### Scope

**In scope :**

- Module NestJS `backend/nestjs/src/bdui/` complet (module + service + controller + DTO + guards si nécessaire).
- Endpoint `GET /api/v1/:tenant/layout/:screenId` — retourne `ScreenConfig` filtré par rôle.
- Endpoint `GET /api/v1/:tenant/layout/:screenId/bulk?screens=…` — bulk pour le premier chargement de l'app.
- Chargement depuis le filesystem `catalog/` (lecture des `screen-config` du tenant courant) ET/OU depuis la table `screen_configs` PostgreSQL (override tenant).
- Cache Redis avec clé `bdui:{tenant_id}:{screen_id}:{role_hash}`, TTL 5 min.
- Invalidation cache : pub/sub Redis sur événement `tenant.config.updated` → flush des clés du tenant.
- Filtrage RBAC pré-envoi : retirer chaque `ComponentConfig` dont `visible_if.role` ne contient pas un des rôles du JWT — pas de masquage côté Flutter.
- Logs structurés (cache hit/miss, latence, tenant_id, screen_id, role).
- Tests unitaires service + tests intégration controller (supertest).

**Out of scope (autres stories) :**

- Le `RuleEvaluator` complet (operators `AND/OR/>/</==`) → STORY-006 (Flutter) + cohérence avec STORY-024 (Zod côté NestJS pour `Rule`).
- Le `ModuleEngine` 2 endpoints génériques → STORY-022.
- La résolution de `DataSource` (KPICard, DataTable values) → fait par `ModuleEngine`, pas par BDUIService.
- L'OpenAPI auto-générée → couverte par STORY-014 (config Swagger globale).

### User Flow

1. App Flutter démarre, JWT stocké, tenant connu.
2. Premier chargement → `GET /api/v1/scalario-acme/layout/dashboard?bulk=dashboard,ventes,stock` (1 round-trip).
3. NestJS : JwtAuthGuard extrait `tenant_id`, `user_id`, `roles[]`.
4. BDUIService construit la clé Redis `bdui:scalario-acme:dashboard:{role_hash}`.
5. Cache MISS → charge le `ScreenConfig` brut depuis `catalog/` (filesystem) ou table `screen_configs` (DB override).
6. Filtrage RBAC : pour chaque `ComponentConfig` dans `zones.kpis|main|aside|actions`, vérifier `visible_if.role` ∈ roles JWT. Sinon, retirer du payload.
7. Stocker le résultat filtré dans Redis (TTL 5 min).
8. Retourner JSON filtré → BDUIEngine Flutter rend.
9. Navigation suivante vers `/ventes` → cache HIT → < 20 ms.
10. OWNER met à jour le tenant config via `PATCH /api/v1/tenants/:id/config` (autre story) → événement `tenant.config.updated` publié → BDUIService écoute → flush `bdui:{tenant_id}:*`.

---

## Acceptance Criteria

### Endpoint principal

- [ ] AC-01 — `GET /api/v1/:tenant/layout/:screenId` retourne un `ScreenConfig` (objet conforme à STORY-023) filtré par rôle, status 200.
- [ ] AC-02 — Sans JWT → 401. JWT valide mais `tenant` ne match pas le `tenant_id` du JWT → 403. `screenId` inconnu → 404.
- [ ] AC-03 — Le payload retourné inclut `schema_version` (depuis le fichier source) et `screen` (id de l'écran).
- [ ] AC-04 — `GET /api/v1/:tenant/layout/:screenId/bulk?screens=s1,s2,s3` retourne `{ s1: ScreenConfig, s2: ScreenConfig, s3: ScreenConfig }` — n+1 layouts en 1 appel. Plafond 10 screens par appel (validation DTO).

### Performance & cache

- [ ] AC-05 — Premier appel (cache MISS) : latence < 100 ms p95 sur dataset de référence (5 tenants, 20 screens, 50 composants/screen).
- [ ] AC-06 — Appel suivant (cache HIT) : latence < 20 ms p95.
- [ ] AC-07 — Clé Redis : `bdui:{tenant_id}:{screen_id}:{role_hash}` où `role_hash` = `sha256(roles.sort().join(','))` — déterministe, court, isolant les variantes par rôle.
- [ ] AC-08 — TTL Redis 300 s (5 min) — configurable via `BDUI_CACHE_TTL_SECONDS` env var.
- [ ] AC-09 — Métriques exposées via interceptor : `bdui.cache.hit`, `bdui.cache.miss`, `bdui.latency_ms` taggés `tenant_id`, `screen_id`.

### Filtrage RBAC pré-envoi

- [ ] AC-10 — Si un `ComponentConfig` a `visible_if = { operator: "role", value: ["OWNER"] }`, alors un appel avec rôle `COMMERCIAL` ne reçoit PAS ce composant dans le payload (champ supprimé, pas mis à `null` ni masqué).
- [ ] AC-11 — Filtrage récursif sur `zones.kpis`, `zones.main`, `zones.aside`, `zones.actions` ET sur les composants imbriqués (ex: `Section > children[]`).
- [ ] AC-12 — Test E2E : OWNER et COMMERCIAL appellent le même `screenId=dashboard` → reçoivent des payloads différents (OWNER voit `KPICard CA Total`, COMMERCIAL non).
- [ ] AC-13 — Si un composant n'a pas de `visible_if` → toujours visible (défaut sécuritaire = inclus).
- [ ] AC-14 — Si tous les composants d'une zone sont filtrés → la zone reste présente mais vide (`zones.aside: []`) — le BDUIEngine gère le rendu vide.

### Invalidation cache

- [ ] AC-15 — Subscription Redis pub/sub sur le canal `tenant.config.updated` — sur réception d'un message `{ tenant_id }`, flush toutes les clés `bdui:{tenant_id}:*` (via SCAN + DEL, pas KEYS).
- [ ] AC-16 — Si `screen_configs.updated_at` change pour un screen donné → invalidation ciblée `bdui:{tenant_id}:{screen_id}:*`.
- [ ] AC-17 — Test : modifier la config tenant via `PATCH /tenants/:id/config` → l'appel suivant `GET layout` charge la nouvelle version (cache MISS forcé).

### Sources de config

- [ ] AC-18 — Stratégie de résolution : 1) chercher d'abord `screen_configs` PostgreSQL pour `(tenant_id, screen_id)` ; 2) sinon, fallback sur le fichier `catalog/domains/{tenant.domain}.json` filesystem ; 3) sinon, 404.
- [ ] AC-19 — Le fichier filesystem est monté en volume Docker (cf STORY-025) — pas de copie dans l'image.
- [ ] AC-20 — Hot-reload : modifier un fichier dans `catalog/` ne nécessite pas un redémarrage NestJS (re-lecture à chaque cache MISS).

### Tests

- [ ] AC-21 — Tests unitaires service ≥ 90% : filtrage RBAC, construction clé cache, fallback filesystem→DB.
- [ ] AC-22 — Tests intégration controller (supertest) : 200 OK happy path, 401, 403, 404, bulk, cache hit/miss observable via mock Redis.

---

## Technical Notes

### Composants concernés

- **Nouveau module NestJS :** `backend/nestjs/src/bdui/`.
- **Dépendances internes :** `auth/` (JwtAuthGuard, RolesDecorator), `tenants/` (TenantContextService), `redis/` (RedisService — STORY-018), `catalogue/` (FilesystemLoader — STORY-025).

### Structure de fichiers (cible)

```
backend/nestjs/src/bdui/
├── bdui.module.ts
├── bdui.service.ts                     # Logique principale
├── bdui.controller.ts                  # Endpoints
├── dto/
│   ├── get-layout.dto.ts               # Path params
│   └── get-bulk-layouts.dto.ts         # ?screens=… validation
├── interfaces/
│   ├── screen-config.interface.ts      # Importé depuis shared-contracts (STORY-027 stretch, sinon local)
│   └── role-filter.interface.ts
├── filters/
│   └── rbac-component-filter.ts        # Filtrage récursif visible_if.role
├── cache/
│   ├── bdui-cache.service.ts           # Wrapper Redis avec hash key + invalidation
│   └── tenant-config-events.listener.ts # Pub/sub Redis
└── __tests__/
    ├── bdui.service.spec.ts
    ├── bdui.controller.spec.ts
    └── rbac-component-filter.spec.ts
```

### Code patterns (TypeScript)

**Service principal :**

```typescript
@Injectable()
export class BduiService {
  constructor(
    private readonly cache: BduiCacheService,
    private readonly catalogueLoader: CatalogueLoaderService,
    private readonly screenConfigRepo: ScreenConfigRepository,
    private readonly filter: RbacComponentFilter,
  ) {}

  async getLayout(
    tenantId: string,
    screenId: string,
    roles: string[],
  ): Promise<ScreenConfig> {
    const cacheKey = this.cache.buildKey(tenantId, screenId, roles);
    const cached = await this.cache.get<ScreenConfig>(cacheKey);
    if (cached) return cached;

    // 1) DB override, 2) filesystem fallback
    const raw =
      (await this.screenConfigRepo.findByTenantAndScreen(tenantId, screenId)) ??
      (await this.catalogueLoader.loadScreenConfig(tenantId, screenId));

    if (!raw) throw new NotFoundException(`Screen ${screenId} not found`);

    const filtered = this.filter.apply(raw, roles);
    await this.cache.set(cacheKey, filtered);
    return filtered;
  }
}
```

**Filtrage RBAC récursif :**

```typescript
@Injectable()
export class RbacComponentFilter {
  apply(config: ScreenConfig, roles: string[]): ScreenConfig {
    return {
      ...config,
      zones: {
        kpis: this.filterZone(config.zones.kpis, roles),
        main: this.filterZone(config.zones.main, roles),
        aside: this.filterZone(config.zones.aside, roles),
        actions: this.filterZone(config.zones.actions, roles),
      },
    };
  }

  private filterZone(
    components: ComponentConfig[] | undefined,
    roles: string[],
  ): ComponentConfig[] {
    if (!components) return [];
    return components
      .filter((c) => this.isVisibleForRoles(c, roles))
      .map((c) => this.recurseChildren(c, roles));
  }

  private isVisibleForRoles(c: ComponentConfig, roles: string[]): boolean {
    if (!c.visible_if) return true;
    if (c.visible_if.operator === 'role') {
      const allowed = (c.visible_if.value as string[]) ?? [];
      return roles.some((r) => allowed.includes(r));
    }
    // Pour les autres operators (AND/OR/>/</==), on conserve par défaut —
    // ils dépendent du contexte runtime (data) que le serveur n'a pas.
    // Le RuleEvaluator Flutter (STORY-006) finalisera côté client.
    return true;
  }

  private recurseChildren(
    c: ComponentConfig,
    roles: string[],
  ): ComponentConfig {
    const children = (c.props?.children as ComponentConfig[] | undefined) ?? null;
    if (!children) return c;
    return {
      ...c,
      props: { ...c.props, children: this.filterZone(children, roles) },
    };
  }
}
```

**Cache key avec hash de rôles :**

```typescript
buildKey(tenantId: string, screenId: string, roles: string[]): string {
  const roleHash = createHash('sha256')
    .update([...roles].sort().join(','))
    .digest('hex')
    .slice(0, 12);
  return `bdui:${tenantId}:${screenId}:${roleHash}`;
}
```

### Edge cases

- **Rôle multi-rôle (OWNER + ADMIN) :** le `role_hash` est calculé sur `sort().join(',')` — donc `[OWNER, ADMIN]` et `[ADMIN, OWNER]` produisent la même clé. Garantit qu'on ne pollue pas le cache avec des permutations.
- **Bulk size DOS :** le DTO `GetBulkLayoutsDto` plafonne `screens.length ≤ 10` — un attaquant ne peut pas demander 10 000 screens en un appel.
- **Race condition invalidation :** un `PATCH config` arrive pendant qu'un `GET` est en cours de calcul. Ordre : flush Redis → insert DB. Le `GET` peut servir l'ancienne version pendant ~quelques ms — accepté pour Phase 1 (eventual consistency 5min max via TTL).
- **Composant sans `id` :** filtrage par référence d'objet. Pas de problème.
- **`visible_if` invalide (mauvais shape) :** Zod (STORY-024) bloque ces JSONs en CI. Si ça atteint le runtime malgré tout, le filtre par défaut `return true` — fail-open ? Non, **fail-closed** : si `operator === 'role'` et `value` n'est pas un `string[]`, on retire le composant. À documenter.

### Sécurité

- **Jamais de filtrage côté Flutter** sur des données reçues. Le Flutter ne sait pas ce qu'il ne reçoit pas.
- **Le payload audit** (logs) ne contient pas les `props` complets — uniquement `screen_id`, `tenant_id`, `role_count`, `component_count_before/after_filter`. Pas de fuite indirecte de la config.
- **JWT obligatoire** sur tous les endpoints — défaut NestJS via global `JwtAuthGuard`.
- **Cross-tenant :** `:tenant` dans l'URL DOIT match le `tenant_id` extrait du JWT — sinon 403, jamais 404 (qui leak l'existence).

---

## Dependencies

**Prérequis :**

- STORY-014 — NestJS bootstrap, monorepo, ESLint, structure projet.
- STORY-015 — JwtAuthGuard, extraction `roles[]` depuis claims.
- STORY-018 — `RedisService` injectable, pub/sub configuré.
- STORY-023 — `ScreenConfig` interface depuis JSON Schema v1.0.0.

**Stories bloquées par celle-ci :**

- STORY-022 (ModuleEngine) — partage le pattern de cache + RBAC.
- STORY-026 (Validation bidirectionnelle) — Flutter consume ce JSON.
- STORY-039 (Template retail_fresh_produce.json) — le BDUIService doit servir ces écrans.

**Externes :**

- Aucune dépendance externe nouvelle (Redis et NestJS déjà en place).

---

## Definition of Done

- [ ] Code commité sur `feat/story-021-bdui-service`.
- [ ] `bun run lint` (ESLint) 0 erreur dans `backend/nestjs/src/bdui/`.
- [ ] `bun test backend/nestjs/src/bdui --coverage` ≥ 90% sur le module.
- [ ] Tests intégration (supertest) passent : 200, 401, 403, 404, bulk happy path.
- [ ] Bench manuel : 1 cache MISS + 100 cache HITs → p95 HIT < 20 ms (mesuré localement).
- [ ] Documentation OpenAPI auto-générée visible sur `/api/docs` pour les 2 endpoints.
- [ ] PR review (`/codex review` + auto-review Carlos).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-021 status `completed`, sprint 3 completed_points += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Module NestJS skeleton (module + controller + DTO + tests boilerplate) | 0.5 | Generator NestJS + lint setup. |
| `BduiService` happy path + DB+filesystem fallback | 1 | Branching logic propre. |
| `RbacComponentFilter` récursif (zones + children) | 1 | Logique fine, beaucoup de cas limites. |
| `BduiCacheService` Redis (set/get/key/TTL) | 0.5 | Wrap RedisService existant. |
| Invalidation pub/sub `tenant.config.updated` (SCAN + DEL) | 0.5 | Attention au pattern KEYS interdit en prod. |
| Endpoint bulk (`/bulk?screens=…`) avec validation plafond | 0.25 | DTO + service.findMany. |
| Tests unitaires (≥ 90% coverage) | 0.75 | Filtrage RBAC = forêt de cas. |
| Tests intégration supertest | 0.5 | 200/401/403/404/bulk. |
| **Total** | **5** | Fibonacci 5 — moderate-complex. |

**Rationale :** Le filtrage RBAC récursif et l'invalidation pub/sub pèsent autant que le reste. Le cache key (avec role_hash) est subtil — sortir un `bug` de cache cross-rôle serait critique. 5 points reflète la sensibilité sécuritaire et la dette si raté.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` §Composant 6 (lignes 515-540) — autoritaire. Le PRD §FR-011 décrit l'intent ; l'archi décrit l'implémentation.
- **Pourquoi pas de `visible_if` data-aware côté backend :** le serveur ne connaît pas le `current_user.cart` ou le contexte runtime du widget. Évaluer `operator: '>'` côté backend nécessiterait de hydrater toutes les sources de données → coût excessif. Le contrat est clair : RBAC strict côté backend, le reste côté Flutter (STORY-006).
- **Conventions logs :** chaque appel produit une ligne `bdui.layout.served` avec `tenant_id`, `screen_id`, `role_count`, `cache=hit|miss`, `duration_ms`, `components_filtered_out`. Standard Pino JSON.
- **Plus tard (post-Gate 0) :** précompilation des layouts filtrés au déploiement (build-time) → cache "warm" dès le démarrage. Pas dans cette story.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
