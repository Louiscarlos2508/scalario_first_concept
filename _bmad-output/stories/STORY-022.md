# STORY-022 : ModuleEngine — 2 Endpoints Génériques

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 6
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-014 (NestJS bootstrap), STORY-015 (Auth + RBAC), STORY-017 (Multi-tenant RLS), STORY-021 (BDUIService)

---

## User Story

> **En tant que** client Flutter Scalario (ou intégrateur certifié déployant un nouveau template),
> **je veux** que **2 endpoints génériques** servent **100 % des opérations de tous les modules** — ventes, stock, fournisseurs, RH, comptabilité, n'importe quel domaine futur,
> **so that** ajouter un module = écrire un JSON de config dans `catalog/`, **zéro ligne de code backend**, **zéro déploiement**, **zéro migration DB**.

---

## Description

### Background — La règle d'or de Scalario

C'est la story architecturale la plus importante de l'EPIC-004. **Si on échoue ici, Scalario n'est pas Scalario** — c'est juste un autre SaaS vertical avec un peu de config.

Le pari du Business OS : **le backend ne connaît aucun domaine métier**. Pas de controller `SalesController`, pas de service `StockService`, pas de table `produits`. Toute la logique métier vit dans le catalogue JSON. Le backend est un **moteur générique** qui sait :

1. **Lire** des données via une config JSON (`GET /:moduleId/data`).
2. **Exécuter** des actions via une config JSON (`POST /:moduleId/action`).

Si un intégrateur veut ajouter un module "Pharmacie — Gestion ordonnances", il :
1. Crée `catalog/domains/pharmacie.json` (data + actions + workflows).
2. Push sur GitHub → CI valide via Zod (STORY-024).
3. Volume Docker monté (STORY-025) → NestJS lit à chaud.
4. **Le module fonctionne.** Pas de PR backend, pas de redéploiement.

C'est ce qui justifie le pricing intégrateur 60/40 et la promesse "60 jours pour démarrer un secteur".

### Pourquoi 2 endpoints suffisent — articulation architecturale

Toute opération de toute application métier se réduit à :

- **Lecture** : "donne-moi N entités filtrées/triées/paginées + des KPIs/agrégats" → `GET data`.
- **Écriture** : "exécute cette action métier (create/update/delete/custom) avec ce payload" → `POST action`.

Les "custom actions" (`valider_commande`, `valider_inventaire`, `marquer_perte`) ne sont pas des nouveaux endpoints — ce sont des entrées dans le `actions` du JSON module qui résolvent à un handler générique. Le handler peut faire :

- CRUD sur `entities` (table JSONB générique — STORY-017).
- Trigger d'un step de workflow (STORY-029-030).
- Appel d'un side-effect déclaré (notification, audit).

**Ce qui briserait ce principe (à NE JAMAIS faire) :**

- Endpoint `/api/sales/discount` — code domain-spécifique côté serveur. **Interdit.** Le discount = `POST /api/v1/:tenant/pos/action { action: "apply_discount", payload: { … } }` résolu par le ModuleEngine.
- Trigger métier in-code (`if (entity.module === 'pos') { … }`). **Interdit.** Tout le branchement est dans le JSON.
- Migration DB par module. **Interdit.** Tout passe par `entities.data JSONB`.

Si une feature future ne rentre pas dans ces 2 endpoints, la première question est : "Comment l'exprimer dans le JSON ?" — pas "Quel nouveau endpoint créer ?".

### Scope

**In scope :**

- Module NestJS `backend/nestjs/src/module-engine/` complet.
- Endpoint `GET /api/v1/:tenant/:moduleId/data` — lecture générique avec query params (`page`, `limit`, `filters`, `sort`).
- Endpoint `POST /api/v1/:tenant/:moduleId/action` — exécution d'action générique.
- `ModuleResolverService` — charge la config `ModuleConfig` depuis catalogue (cache mémoire + Redis).
- `DataDispatcher` — résout la query depuis `module.entities[*].data_source` config et exécute en JSONB sur `entities` table.
- `ActionDispatcher` — résout l'action depuis `module.actions[*]` config, exécute le handler générique (CRUD + custom).
- Header `X-Client-Mutation-Id` obligatoire sur POST → vérification d'idempotence (table `sync_mutations`, TTL 24h).
- Audit log automatique sur chaque action (insert dans `audit_logs`).
- ABAC layer (CASL) — vérifie l'autorisation avant exécution (STORY-016 fournit la couche, ici on la consomme).
- Réponse format unifié : `{ items, total, kpis?, meta }` pour data ; `{ entity?, result, mutation_id }` pour action.

**Out of scope (autres stories) :**

- Le `WorkflowEngine` (transitions XState) → STORY-029 / STORY-030.
- L'`OfflineSyncEngine` côté Flutter → STORY-035.
- L'`AuditLogService` insert-only (table + RLS) → STORY-019. Cette story le **consomme**.
- Le RBAC layer (Roles guard) → STORY-015. ABAC → STORY-016.
- Schema-per-tenant Phase 2 → hors scope.

### User Flow

**Lecture (Blandine consulte le stock) :**

1. Flutter appelle `GET /api/v1/blandine-fruits/stock/data?page=1&limit=50&filters={"status":"low"}&sort=name:asc`.
2. NestJS — JwtAuthGuard, RbacGuard (rôle a accès à `stock`?), AbacGuard (lignes filtrées par CASL si applicable).
3. `ModuleResolverService` charge `catalog/domains/retail_fresh_produce.json` → extrait `module.id === 'stock'`.
4. `DataDispatcher` lit `module.entities[0].data_source` (ex: `{ entity_type: 'produit', filters_schema: […], kpis: [{name:'low_stock_count', ...}] }`).
5. Construit la requête Postgres : `SELECT data FROM entities WHERE tenant_id = $1 AND entity_type = 'produit' AND data @> '{"status":"low"}' ORDER BY data->>'name' ASC LIMIT 50 OFFSET 0`.
6. Calcule les KPIs déclarés (`low_stock_count = COUNT WHERE quantity < threshold`).
7. Retourne `{ items: [...], total: N, kpis: { low_stock_count: 12 }, meta: { page: 1 } }`.

**Écriture (Blandine valide une livraison) :**

1. Flutter génère `mutation_id = uuid()`.
2. `POST /api/v1/blandine-fruits/stock/action` avec header `X-Client-Mutation-Id: {uuid}`, body `{ action: 'valider_livraison', payload: { livraison_id: 'abc', items: [...] } }`.
3. NestJS vérifie idempotence : `sync_mutations.client_mutation_id === uuid` ? → si déjà succès, retourne le résultat précédent. Si nouveau, insert pending.
4. ABAC : `User can perform 'valider_livraison' on Module(stock) in Context(tenant)` → CASL rule.
5. `ActionDispatcher` charge `module.actions['valider_livraison']` du JSON → résout le `handler: 'crud.update'` ou `handler: 'workflow.advance'` ou `handler: 'custom.deliver'`.
6. Exécute le handler générique → mutate `entities` table.
7. Insert `audit_logs` (action, payload_hash, user_id).
8. Update `sync_mutations.status = 'success'` avec `result`.
9. Retourne `{ entity, result, mutation_id }`.

---

## Acceptance Criteria

### Endpoint GET /data

- [ ] AC-01 — `GET /api/v1/:tenant/:moduleId/data` retourne 200 avec `{ items: Entity[], total: number, kpis?: Record<string, number>, meta: { page, limit } }`.
- [ ] AC-02 — Query params supportés : `page` (défaut 1), `limit` (défaut 50, max 200), `filters` (JSON URL-encoded), `sort` (format `field:asc|desc`).
- [ ] AC-03 — `moduleId` inconnu (pas dans le catalogue) → 404 `{ error: 'Module not found', moduleId }`.
- [ ] AC-04 — `:tenant` slug ne match pas le JWT → 403.
- [ ] AC-05 — Filtres résolus en JSONB Postgres (`data @> '{"status":"low"}'`) — utilise `idx_entities_data_gin`.
- [ ] AC-06 — KPIs calculés à la volée via la définition `module.kpis[*]` du JSON config (ex: `{ name, type: 'count', filter: {...} }`).

### Endpoint POST /action

- [ ] AC-07 — `POST /api/v1/:tenant/:moduleId/action` accepte `{ action: string, payload: object }`. Retourne 200 avec `{ entity?, result, mutation_id }`.
- [ ] AC-08 — Header `X-Client-Mutation-Id: {uuid}` **obligatoire** — manquant → 400.
- [ ] AC-09 — `mutation_id` déjà traité avec succès → retourne le `result` original (200, pas 409). Idempotence vraie.
- [ ] AC-10 — `mutation_id` en cours (`status = 'pending'`) → 409 `{ error: 'Mutation in progress' }`.
- [ ] AC-11 — Action inconnue (`action` pas dans `module.actions`) → 422 `{ error: 'Unknown action', moduleId, action }`.
- [ ] AC-12 — Action ABAC-refusée → 403 (consume STORY-016 CASL).
- [ ] AC-13 — Audit log inséré pour chaque action exécutée (cf STORY-019) — non-bloquant si insert audit échoue (logué mais retourne 200).

### Genericité (le test critique)

- [ ] AC-14 — Test E2E **LE PLUS IMPORTANT** : 3 modules différents (`pos`, `stock`, `fournisseurs`) répondent via les **mêmes 2 endpoints**, avec **0 ligne de code spécifique** à chacun. Les 3 modules sont déclarés uniquement en JSON (catalog).
- [ ] AC-15 — Un nouveau module `test_module` ajouté au catalogue (ex: `catalog/modules/test_demo.json`) → fonctionne immédiatement après reload du fichier (pas de redéploiement). Vérifié dans le test E2E.
- [ ] AC-16 — Recherche manuelle : aucun match `if (moduleId === '…')`, `switch (moduleId)`, ou import nommé d'un module métier dans `src/module-engine/` (vérifié par grep dans CI).

### ABAC + RBAC

- [ ] AC-17 — RBAC : `ModuleConfig.rbac_roles[*]` déclare quels rôles peuvent appeler GET/POST → guard NestJS rejette en amont.
- [ ] AC-18 — ABAC : `ModuleConfig.abac_rules[*]` exposés à CASL — ex: `{ subject: 'COMMERCIAL', action: 'create', resource: 'vente', condition: { user_id: '$current.id' } }`.

### Idempotence + audit

- [ ] AC-19 — Table `sync_mutations` (cf STORY-017) utilisée pour idempotence : insert `pending` au début, update `success|error|conflict` à la fin.
- [ ] AC-20 — TTL nettoyage : un `pg_cron` job (existant ou créé ici) supprime les `sync_mutations` succès > 24h.
- [ ] AC-21 — `audit_logs` rempli avec `action`, `module_id`, `entity_id` (si applicable), `payload_hash` (SHA-256 du payload, **pas le payload**), `user_id`, `tenant_id`.

### Tests

- [ ] AC-22 — Coverage ≥ 85% sur `src/module-engine/` (Jest).

---

## Technical Notes

### Composants concernés

- **Nouveau module NestJS :** `backend/nestjs/src/module-engine/`.
- **Dépendances internes :** `auth/`, `security/` (RBAC + ABAC CASL), `tenants/`, `redis/`, `catalogue/` (loader STORY-025), `audit/` (STORY-019), `entities/` repo générique (STORY-017).

### Structure de fichiers (cible)

```
backend/nestjs/src/module-engine/
├── module-engine.module.ts
├── module-engine.controller.ts          # 2 routes — c'est tout
├── services/
│   ├── module-resolver.service.ts       # Load ModuleConfig from catalogue
│   ├── data-dispatcher.service.ts       # GET /data resolver (JSONB query builder)
│   ├── action-dispatcher.service.ts     # POST /action resolver
│   └── idempotency.service.ts           # client_mutation_id check
├── handlers/                             # Handlers génériques — 1 par "type" d'action
│   ├── crud-create.handler.ts
│   ├── crud-update.handler.ts
│   ├── crud-delete.handler.ts
│   ├── workflow-advance.handler.ts      # Trigger un step workflow (STORY-030)
│   └── handler-registry.ts              # Map { 'crud.create' → CrudCreateHandler, … }
├── dto/
│   ├── get-data.dto.ts                  # Query validation (Zod pipe — STORY-024)
│   └── execute-action.dto.ts
├── interfaces/
│   ├── module-config.interface.ts       # From shared-contracts (or local)
│   └── handler.interface.ts             # interface Handler { execute(ctx): Result }
└── __tests__/
    ├── data-dispatcher.spec.ts
    ├── action-dispatcher.spec.ts
    ├── idempotency.spec.ts
    ├── handler-crud.spec.ts
    └── e2e-3-modules.spec.ts            # LE test critique
```

### Code patterns (TypeScript)

**Controller — la simplicité totale :**

```typescript
@Controller('api/v1/:tenant/:moduleId')
@UseGuards(JwtAuthGuard, RolesGuard, AbacGuard)
export class ModuleEngineController {
  constructor(
    private readonly data: DataDispatcherService,
    private readonly action: ActionDispatcherService,
  ) {}

  @Get('data')
  async getData(
    @Param('tenant') tenantSlug: string,
    @Param('moduleId') moduleId: string,
    @Query() query: GetDataDto,
    @CurrentUser() user: AuthUser,
  ): Promise<DataResponse> {
    return this.data.dispatch({ tenantSlug, moduleId, query, user });
  }

  @Post('action')
  async executeAction(
    @Param('tenant') tenantSlug: string,
    @Param('moduleId') moduleId: string,
    @Headers('x-client-mutation-id') mutationId: string,
    @Body() body: ExecuteActionDto,
    @CurrentUser() user: AuthUser,
  ): Promise<ActionResponse> {
    if (!mutationId) {
      throw new BadRequestException('X-Client-Mutation-Id header required');
    }
    return this.action.dispatch({
      tenantSlug, moduleId, mutationId, body, user,
    });
  }
}
```

**ActionDispatcher — résolution dynamique depuis JSON :**

```typescript
@Injectable()
export class ActionDispatcherService {
  constructor(
    private readonly resolver: ModuleResolverService,
    private readonly registry: HandlerRegistry,
    private readonly idempotency: IdempotencyService,
    private readonly audit: AuditLogService,
  ) {}

  async dispatch(ctx: ActionContext): Promise<ActionResponse> {
    const moduleConfig = await this.resolver.resolve(ctx.tenantSlug, ctx.moduleId);
    const actionDef = moduleConfig.actions?.[ctx.body.action];
    if (!actionDef) {
      throw new UnprocessableEntityException(
        `Unknown action: ${ctx.body.action} for module ${ctx.moduleId}`,
      );
    }

    // Idempotence
    const existing = await this.idempotency.checkAndReserve(ctx.mutationId, ctx);
    if (existing.alreadyDone) return existing.previousResult;

    // Resolve handler générique depuis le JSON (ex: 'crud.create', 'workflow.advance')
    const handler = this.registry.get(actionDef.handler);
    if (!handler) {
      throw new InternalServerErrorException(
        `Handler not registered: ${actionDef.handler}`,
      );
    }

    try {
      const result = await handler.execute({
        tenantId: ctx.user.tenantId,
        userId: ctx.user.id,
        moduleConfig,
        actionDef,
        payload: ctx.body.payload,
      });
      await this.idempotency.markSuccess(ctx.mutationId, result);
      await this.audit.log({
        tenantId: ctx.user.tenantId,
        userId: ctx.user.id,
        action: ctx.body.action,
        moduleId: ctx.moduleId,
        entityId: result.entity?.id,
        payloadHash: hashPayload(ctx.body.payload),
      });
      return { entity: result.entity, result: result.data, mutation_id: ctx.mutationId };
    } catch (err) {
      await this.idempotency.markError(ctx.mutationId, err);
      throw err;
    }
  }
}
```

**Module config JSON (extrait illustratif) :**

```json
{
  "id": "stock",
  "schema_version": "1.0.0",
  "name": "Gestion Stock",
  "i18n_key": "module.stock",
  "icon": "package",
  "entities": [
    {
      "type": "produit",
      "data_source": {
        "kpis": [
          { "name": "low_stock_count", "type": "count", "filter": { "quantity": { "$lt": "$threshold" } } }
        ]
      }
    }
  ],
  "actions": {
    "creer_produit":     { "handler": "crud.create",     "entity_type": "produit" },
    "modifier_produit":  { "handler": "crud.update",     "entity_type": "produit" },
    "valider_livraison": { "handler": "workflow.advance", "workflow_id": "wf_livraison", "transition": "valider" },
    "marquer_perte":     { "handler": "crud.update",     "entity_type": "produit", "merge": { "status": "lost" } }
  },
  "rbac_roles": ["OWNER", "GERANT", "STOCK_MANAGER"],
  "abac_rules": [],
  "conflict_strategy": "server_wins"
}
```

### Edge cases

- **Idempotence sur erreur** : un appel qui a échoué (`status = 'error'`) avec un `mutation_id` peut-il être retenté ? **Non** — pour Phase 1, `error` est terminal (le client doit générer un nouveau `mutation_id`). Plus simple, plus sûr.
- **Concurrent même mutation_id** : le 1er est `pending`, le 2e arrive → 409 immédiat. La table `sync_mutations.client_mutation_id UNIQUE` garantit la sérialisation.
- **Handler manquant pour un `actionDef.handler`** : Zod aurait dû bloquer en CI (STORY-024). Si ça atteint le runtime → 500 Internal Server Error avec log d'alerte. Pas un cas user.
- **`moduleConfig` non trouvé** (pas de fichier dans `catalog/`) : 404 explicite — différent de "action inconnue dans le module" (422).
- **Filtre JSON malicieux** : `filters` est validé par Zod (un schéma générique : map de field → operator → value). Pas d'injection JSONB.
- **N+1 KPIs** : si 5 KPIs déclarés, on n'envoie pas 5 queries — agrégation dans une seule query avec `FILTER` clauses. Important pour perf.

### Sécurité

- **Aucune SQL string concat** — tous les filtres JSONB construits via le query builder paramétré.
- **`payload_hash` audit** = SHA-256 hex tronqué — on n'écrit jamais le payload brut dans `audit_logs.metadata` (RGPD : un payload peut contenir un IBAN).
- **RLS Postgres** (STORY-017) reste actif comme dernière défense — même un bug de filtre tenant ne fuite pas cross-tenant.
- **CSRF** : non applicable (Bearer JWT, pas de cookies).
- **Rate-limit** : à brancher via le throttle global NestJS (STORY-014). Non-objet ici.

---

## Dependencies

**Prérequis :**

- STORY-014 — NestJS bootstrap + ESLint.
- STORY-015 — JWT + RBAC.
- STORY-016 — ABAC CASL (pour AC-12 et AC-18).
- STORY-017 — Multi-tenant RLS + table `entities` JSONB + `sync_mutations`.
- STORY-019 — `AuditLogService` (insert-only).
- STORY-021 — pattern catalogue loader réutilisé.
- STORY-023 — `ModuleConfig` interface depuis JSON Schema.
- STORY-024 — Zod validator (utilisé en pipes).
- STORY-025 — structure `catalog/` filesystem.

**Stories bloquées par celle-ci :**

- STORY-029, STORY-030 (Workflow engine) — branche dans `handler.workflow.advance`.
- STORY-035 (OfflineSync) — appelle ces 2 endpoints en replay.
- STORY-039 (template retail_fresh_produce.json) — son module `pos`, `stock` doivent passer par cet engine.
- STORY-028 (tests coverage moteur) — couvre cette story de tests d'intégration.

**Externes :**

- Postgres ≥ 16 avec extension `pgcrypto` (déjà via STORY-017).
- Redis (déjà via STORY-018).

---

## Definition of Done

- [ ] Code commité sur `feat/story-022-module-engine`.
- [ ] `bun run lint` 0 erreur sur `src/module-engine/`.
- [ ] `bun test src/module-engine --coverage` ≥ 85%.
- [ ] Test E2E "3 modules" passe : `pos`, `stock`, `fournisseurs` répondent via les 2 endpoints sans code spécifique.
- [ ] Test E2E "nouveau module hot-reload" : ajouter un fichier dans `catalog/` rend le module disponible sans redémarrage.
- [ ] CI grep step : aucun match `if.*moduleId.*===|switch.*moduleId` dans `src/module-engine/`.
- [ ] OpenAPI documente `GET /:moduleId/data` et `POST /:moduleId/action` avec exemples.
- [ ] PR review (`/codex review`) — focus sur "ai-je créé du code domain-specific ?".
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-022 status `completed`, sprint 3 completed_points += 6.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `ModuleResolverService` (load + cache + invalidate) | 0.5 | Pattern repris de STORY-021. |
| `DataDispatcher` — query builder JSONB générique avec filters/sort/page/limit | 1.5 | Le JSONB query builder est subtil. KPI agrégation = soin. |
| `ActionDispatcher` — résolution + idempotence + audit + ABAC | 1.5 | Beaucoup de moving parts, transactional. |
| `HandlerRegistry` + 4 handlers génériques (crud.create/update/delete + workflow.advance stub) | 1 | Le stub workflow attend STORY-030, mais l'interface est bouclée ici. |
| Idempotency Service (sync_mutations) | 0.5 | Lock + state transitions. |
| Tests unitaires + E2E "3 modules" + E2E "hot-reload" | 1 | Le test E2E "3 modules" est la preuve de la genericité — non-négociable. |
| **Total** | **6** | Fibonacci 5 → 8, on choisit 6 (entre les deux par décision d'équipe — moitié haute du moderate). |

**Rationale :** Le poids est dans la **subtilité de la genericité**, pas dans le volume de code. Chaque ligne qui semble "naturellement" introduire un branchement par moduleId est une dette architecturale critique. La discipline de revue (humain + codex) coûte autant que l'implémentation. Le test E2E "3 modules" est la garantie qu'on n'a pas triché.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` §Composant 5 (lignes 484-512) + §Endpoints ModuleEngine (lignes 1044-1063). PRD §FR-012 cohérent.
- **L'archi est la SOURCE — le PRD est le contrat client.** Si conflit pendant l'implé, l'archi gagne (et on ouvre une PR PRD).
- **"Comment je sais que je viole la règle d'or ?"** Si la PR contient une nouvelle ligne `case 'pos':` ou `if (entity.module === 'stock')` ou un nouvel endpoint `/api/v1/:tenant/sales/…`, **bloquer la PR**. Le `/codex review` doit être instruit pour flag ces patterns.
- **Évolution Phase 2 :** quand un module crée un bottleneck JSONB (ex: comptabilité avec millions d'écritures), une table dédiée peut **coexister** avec le ModuleEngine. Le handler CRUD du module concerné lit/écrit la table dédiée au lieu de `entities`. Toujours derrière les 2 mêmes endpoints. Pas dans cette story.
- **La conversation entre stories :** STORY-021 (BDUI) et STORY-022 (ModuleEngine) sont les 2 jambes du backend. BDUI sert le **layout** (la forme), ModuleEngine sert les **données** + **actions** (le fond). Le Flutter ne devrait jamais avoir d'autre URL backend que ces 2 (+ auth + sync). Si une 3e émerge → red flag.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-20 : Implemented via `/bmad:dev-story` (20 unit tests, 0 lint/typecheck errors)

**Actual Effort :** 6 points

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
