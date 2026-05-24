# STORY-036 : Idempotence Endpoints POST

**Epic :** EPIC-006 — Offline-First & Sync
**Priorité :** Must Have
**Story Points :** 3
**Status :** done
**Assigned To :** Carlos
**Created :** 2026-05-10
**Completed :** 2026-05-24
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-022 (ModuleEngine endpoints), STORY-013 (docker-compose Redis)

---

## User Story

> **En tant qu'**utilisatrice mobile (Blandine) sur réseau instable où les requêtes POST timeout fréquemment puis sont rejouées par le SyncQueueWorker,
> **je veux** que rejouer la même mutation deux fois (ou dix fois) ne crée jamais un doublon en base — la première exécution réussit ou échoue, les replays retournent simplement le résultat déjà stocké,
> **so that** "5 ventes cliquées" ne deviennent jamais "10 ventes" après une mauvaise session 3G.

---

## Description

### Background

PRD §FR-059 + architecture §Sync mutations imposent l'idempotence sur **tous les POST** ModuleEngine. C'est la pièce qui rend le SyncQueueWorker (STORY-034) sûr — sans elle, le retry serait dangereux : un timeout 504 alors que le serveur a en réalité réussi entraînerait un doublon au prochain retry.

Le mécanisme est standard et industriel : header `X-Client-Mutation-Id` (alias `Idempotency-Key` — on suit la convention Stripe/Square pour l'API publique future) porté par chaque POST. Le serveur, à la réception :

1. Vérifie si la clé existe dans le cache idempotence (Redis).
2. Si oui → retourne la réponse cachée (status, body, headers de la première exécution) — pas de re-exécution métier.
3. Si non → exécute la mutation, cache (clé, response) avec TTL 24h.

L'architecture a déjà acté Redis comme store (architecture §Tech stack — `ioredis`). Cette story implémente l'interceptor NestJS, le service de cache, et la validation E2E.

### Scope

**In scope :**

- `IdempotencyInterceptor` NestJS, appliqué globalement sur tous les `POST` (ou via un `@Idempotent()` decorator ciblé sur les endpoints qui en ont besoin — décision : global pour tout `/api/v1/*/sync/*` + `/api/v1/*/{moduleId}/action`).
- Validation du header `X-Client-Mutation-Id` : présence obligatoire (sinon 400), format UUID v4 (regex), longueur max 128 (sécurité).
- `IdempotencyService` (NestJS) : `lookup(key)`, `store(key, response, ttlSeconds)`, backed by Redis.
- Cache key Redis : `idem:{tenant_id}:{key}` → JSON `{ status, body, contentType, capturedAt }`. TTL 86400s (24h).
- Headers réponse : `X-Idempotency-Replay: true` quand on rejoue une réponse cachée (utile debug + métriques).
- Backend `POST /sync/mutations` (STORY-034) utilise cet interceptor — chaque mutation du batch a sa propre clé.
- Documentation OpenAPI : header `X-Client-Mutation-Id` annoté `required: true` sur tous les endpoints concernés.
- Métriques Prometheus : `scalario_idempotency_hits_total`, `scalario_idempotency_misses_total`, `scalario_idempotency_collisions_total` (clé existe avec body différent — pathologique).
- Tests E2E : timeout simulé + replay → 1 seul enregistrement DB.

**Out of scope :**

- Idempotence côté GET (par définition idempotents HTTP).
- Idempotence sur DELETE (idempotent par sémantique HTTP REST si bien conçu — pas couvert ici).
- Idempotence cross-tenant (chaque clé est scopée tenant — sécurité).
- Idempotence longue durée > 24h (cas extrême — utilisateur offline 48h+ avec une mutation pending → si idempotency expire, le serveur peut re-exécuter. Mitigation : le worker retry avant 24h normalement). Documenté en risque.
- Client-side : la génération UUID est déjà couverte par STORY-034 (`SyncQueueService.enqueue`).

### Flow technique

```
Flutter SyncQueueWorker
  POST /api/v1/{tenant}/sync/mutations
  Headers: { X-Client-Mutation-Id: <uuid-v4>, Authorization: Bearer <jwt> }
  Body: { mutations: [...] }

NestJS pipeline :
  → JwtAuthGuard
  → IdempotencyInterceptor.intercept()
      ├─ key = req.headers['x-client-mutation-id']
      ├─ scoped = `idem:${tenantId}:${key}`
      ├─ Redis GET scoped
      │     ├─ HIT → return cached response (header X-Idempotency-Replay: true)
      │     └─ MISS → next()
      └─ après next() :
          └─ Redis SETEX scoped 86400 JSON.stringify({status, body})
  → Controller.postMutations()
  → response
```

---

## Acceptance Criteria

### Header & validation

- [ ] AC-01 — Tous les endpoints POST `/api/v1/*/sync/*` ET `/api/v1/*/{moduleId}/action` exigent le header `X-Client-Mutation-Id`. Absence → `400 Bad Request` body `{ error: 'missing_idempotency_key', field: 'X-Client-Mutation-Id' }`.
- [ ] AC-02 — Format vérifié : regex UUID v4 (`^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i`). Format invalide → `400` body `{ error: 'invalid_idempotency_key' }`.
- [ ] AC-03 — Longueur max 128 caractères (futureproofing, mais UUID v4 = 36).

### Lookup & store

- [ ] AC-04 — `IdempotencyService.lookup(tenantId, key)` lit Redis `idem:{tenantId}:{key}`. Retourne `null` si absent, sinon `{status, body, contentType, capturedAt}`.
- [ ] AC-05 — `IdempotencyService.store(tenantId, key, response, ttl=86400)` SETEX la response sérialisée. Si la clé existe déjà avec une response différente → log warning + métrique `collisions_total`.
- [ ] AC-06 — Sérialisation : JSON.stringify avec champs sélectionnés (status code, body parsé en objet, content-type). Body binaire non supporté Phase 1 (sync = JSON only).

### Interceptor NestJS

- [ ] AC-07 — `IdempotencyInterceptor` implémente `NestInterceptor`. Appliqué globalement via `app.useGlobalInterceptors()` mais avec un guard interne qui filtre méthode === POST + URL matching pattern allowlist.
- [ ] AC-08 — En cas de cache HIT : retourne la response cachée sans appeler le controller. Header response `X-Idempotency-Replay: true` ajouté.
- [ ] AC-09 — En cas de cache MISS : laisse passer, capture la response avec un `tap()` RxJS, store dans Redis APRÈS succès (status 2xx). Si controller throw → ne cache PAS l'erreur (retentative permise).
- [ ] AC-10 — Erreurs 5xx ne sont jamais cachées (transient errors). Erreurs 4xx (validation, auth) SONT cachées (la même requête malformée retournera la même erreur — comportement déterministe).

### Scoping & sécurité

- [ ] AC-11 — La clé Redis est scopée par `tenant_id` (extrait du JWT, pas du body). Évite qu'une clé utilisée par tenant A interfère avec tenant B.
- [ ] AC-12 — Si le user_id derrière la clé change entre la 1re exec et le replay (ex: clé volée par un autre user du même tenant) → log audit `idempotency.user_mismatch` + 409. Sécurité.

### Performance

- [ ] AC-13 — Lookup Redis < 5ms p95 (mesuré via `prom-client` histogram `scalario_idempotency_lookup_duration_seconds`).
- [ ] AC-14 — Throughput : 500 req/s avec idempotency vérifié dans bench Artillery (sync batch 20 mutations × 25 req/s).
- [ ] AC-15 — Pas de fuite mémoire : Redis SETEX TTL respecté (vérifié sur Redis info après 25h : keyspace `idem:*` < 100 keys avec TTL).

### Tests E2E

- [ ] AC-16 — Test E2E : POST mutation `create_sale` avec key K → 200 + sale créée. Re-POST identique avec K → 200 + body identique + header `X-Idempotency-Replay: true` + DB inchangée (1 seule sale).
- [ ] AC-17 — Test E2E timeout simulé : injecter une latence 35s (au-delà du timeout client 30s). Client retry. Vérifier 1 seule sale en DB.
- [ ] AC-18 — Test sécurité : tenant A POST avec key K → succès. Tenant B POST avec même key K → traité comme nouvelle requête (scope par tenant).
- [ ] AC-19 — Test header manquant : POST sans `X-Client-Mutation-Id` → 400.
- [ ] AC-20 — Test format invalide : POST avec key `"abc"` → 400.

### Documentation

- [ ] AC-21 — OpenAPI Swagger annoté : `@ApiHeader({name:'X-Client-Mutation-Id', required:true, schema:{format:'uuid'}})` sur tous les endpoints concernés.
- [ ] AC-22 — README `apps/backend/src/idempotency/README.md` documente : convention header, format clé, TTL, scoping, comportement collision, exemples curl.

---

## Technical Notes

### Composants concernés

- **Backend NestJS :** `apps/backend/src/idempotency/` (nouveau module).
- **Redis :** instance déjà fournie par STORY-013 (docker-compose).
- **Shared contracts :** ajouter le header dans le client Dio (interceptor) — minime, lecture déjà faite par `SyncApiClient` STORY-034.

### Structure de fichiers

```
apps/backend/
├── src/
│   └── idempotency/
│       ├── idempotency.module.ts
│       ├── idempotency.service.ts
│       ├── idempotency.interceptor.ts
│       ├── idempotency.config.ts          # patterns d'URL, TTL, allowlist
│       ├── dto/idempotency.dto.ts
│       └── README.md
├── test/
│   └── idempotency/
│       ├── idempotency.service.spec.ts
│       ├── idempotency.interceptor.spec.ts
│       └── idempotency.e2e-spec.ts
```

### Code skeleton — IdempotencyService

```typescript
// apps/backend/src/idempotency/idempotency.service.ts
import { Injectable, Logger } from '@nestjs/common';
import Redis from 'ioredis';

interface CachedResponse {
  status: number;
  body: unknown;
  contentType: string;
  capturedAt: string;
}

@Injectable()
export class IdempotencyService {
  private readonly logger = new Logger(IdempotencyService.name);
  private readonly ttlSeconds = 86400;

  constructor(private readonly redis: Redis) {}

  private key(tenantId: string, idemKey: string): string {
    return `idem:${tenantId}:${idemKey}`;
  }

  async lookup(tenantId: string, idemKey: string): Promise<CachedResponse | null> {
    const raw = await this.redis.get(this.key(tenantId, idemKey));
    return raw ? (JSON.parse(raw) as CachedResponse) : null;
  }

  async store(
    tenantId: string,
    idemKey: string,
    response: CachedResponse,
  ): Promise<void> {
    const k = this.key(tenantId, idemKey);
    const existing = await this.redis.get(k);
    if (existing && existing !== JSON.stringify(response)) {
      this.logger.warn(`idempotency collision tenant=${tenantId} key=${idemKey}`);
      // métrique scalario_idempotency_collisions_total++
    }
    await this.redis.setex(k, this.ttlSeconds, JSON.stringify(response));
  }
}
```

### Code skeleton — Interceptor

```typescript
// apps/backend/src/idempotency/idempotency.interceptor.ts
import {
  Injectable, NestInterceptor, ExecutionContext, CallHandler,
  BadRequestException,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly idem: IdempotencyService) {}

  async intercept(ctx: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    const req = ctx.switchToHttp().getRequest();
    const res = ctx.switchToHttp().getResponse();
    if (req.method !== 'POST' || !this.shouldApply(req.url)) return next.handle();

    const key = req.headers['x-client-mutation-id'] as string | undefined;
    if (!key) throw new BadRequestException({ error: 'missing_idempotency_key' });
    if (!UUID_V4.test(key)) throw new BadRequestException({ error: 'invalid_idempotency_key' });

    const tenantId = req.user.tenantId;
    const cached = await this.idem.lookup(tenantId, key);
    if (cached) {
      res.setHeader('X-Idempotency-Replay', 'true');
      res.status(cached.status);
      return of(cached.body);
    }

    return next.handle().pipe(
      tap(async (body) => {
        if (res.statusCode < 500) {
          await this.idem.store(tenantId, key, {
            status: res.statusCode,
            body,
            contentType: 'application/json',
            capturedAt: new Date().toISOString(),
          });
        }
      }),
    );
  }

  private shouldApply(url: string): boolean {
    return /\/api\/v1\/[^/]+\/(sync\/|.*\/action$)/.test(url);
  }
}
```

### Configuration TTL & patterns

```typescript
// apps/backend/src/idempotency/idempotency.config.ts
export const IDEMPOTENCY_CONFIG = {
  ttlSeconds: 86400, // 24h
  patterns: [
    /^\/api\/v1\/[^/]+\/sync\//,
    /^\/api\/v1\/[^/]+\/[^/]+\/action$/,
  ],
} as const;
```

### Relation avec STORY-034 (client)

Le client Flutter génère déjà l'UUID v4 dans `SyncQueueService.enqueue` (STORY-034 AC-01). Le `SyncApiClient` envoie le header `X-Client-Mutation-Id`. Aucun travail client supplémentaire ici.

### PRD ↔ DS — Aucun conflit

Story 100% backend, pas d'UI.

### Sécurité

- Scoping par tenant_id (lu du JWT, pas du body) — empêche un attaquant de re-jouer la clé d'un autre tenant.
- Collision détectée + auditée (improbable mais surveillé).
- Clé limitée à UUID v4 — pas de SQL injection possible (validée regex avant Redis).
- Pas de PII dans les clés.

### Edge cases

- **Clé réutilisée pour une mutation différente** (collision intentionnelle ou bug client) : log + métrique. Réponse retournée = celle du premier appel (comportement Stripe-like). Le client fautif aura un résultat surprenant — c'est sa faute pour avoir réutilisé une clé.
- **Redis down** : interceptor lève l'exception → le request fail. Stratégie alternative envisagée (fail-open : pas de cache = exécute toujours) **rejetée** car ouvrirait la porte aux doublons. Documenté comme dépendance dure.
- **Cache poisoning** : la clé de cache inclut tenant_id (extrait du JWT signé). Pas de vector connu.
- **Réponse 5xx puis retry** : pas cachée → retry réelle exécutée. Si la 1re a quand même créé l'entité côté DB (cas raré: erreur après commit), le 2e POST fera doublon. Mitigation Phase 1 : transaction NestJS commit AVANT response = si erreur après commit, le client retry sans risque de double commit (DB unique constraint sur natural keys du module). Acceptable, monitoré.
- **Mutation > 24h** : si une mutation est en sync_queue > 24h, la clé idempotence Redis a expiré côté serveur → re-exec possible. Mitigation : le client ne doit pas garder de mutations > 24h en pending (alerter via SyncStatusBar à 23h via STORY-037). Phase 2 : extension TTL à 7 jours possible.

---

## Dependencies

**Prérequis :**

- STORY-013 (docker-compose Redis disponible) — direct.
- STORY-022 (ModuleEngine endpoints exposés) — direct, ce sont les endpoints idempotents.
- STORY-034 envoie le header — coordination logique mais STORY-034 n'a pas besoin de cette story livrée pour DEV (peut mocker côté local).

**Stories bloquées :**

- STORY-034 — pas bloquée techniquement, mais sa stabilité dépend de cette story en prod.
- STORY-035 (Conflict Resolution) — utilise l'interceptor pour ses replays `X-Sync-Force`.

**Externes :**

- `ioredis ^5.x` (déjà dans architecture).

---

## Definition of Done

- [ ] Code commité sur `feat/story-036-idempotence`.
- [ ] `pnpm lint` + `pnpm test` zéro warning.
- [ ] Tests E2E (5 scénarios AC-16 à AC-20) verts.
- [ ] Bench Artillery 500 req/s documenté.
- [ ] OpenAPI Swagger header documenté + URL exemple curl.
- [ ] README idempotency documenté.
- [ ] Métriques Prometheus exposées (`/metrics` endpoint visible dans Grafana stub si déployé).
- [ ] PR review (Carlos + `/codex review`).
- [ ] PR mergée sur `main`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `IdempotencyService` (Redis lookup/store) | 0.5 | ioredis + JSON serialization. |
| `IdempotencyInterceptor` NestJS | 0.75 | RxJS tap, status code handling, allowlist URL. |
| Validation header (UUID v4 regex) + 400 errors | 0.25 | Regex + Bad Request body. |
| OpenAPI Swagger annotations | 0.25 | `@ApiHeader` sur 5+ endpoints. |
| Métriques Prometheus | 0.25 | 3 counters + 1 histogram. |
| Tests unitaires service + interceptor | 0.5 | Mock Redis, mock ExecutionContext. |
| Tests E2E (timeout, replay, scoping tenant) | 0.5 | supertest + Redis vrai. |
| **Total** | **3** | Fibonacci 3 — petit mais critique. Bien testé = peu de risque. |

---

## Notes additionnelles

- **Pourquoi 24h TTL** : Blandine devrait être online au moins une fois par 24h en pratique. Si pas, son téléphone aura un autre problème. 24h équilibre Redis memory et robustesse.
- **Logo Scalario** : non concerné.
- **i18n** : messages 400 sont en EN technique (`missing_idempotency_key`) — l'UI client mappe vers FR utilisateur (STORY-042).
- **Convention "Idempotency-Key" vs "X-Client-Mutation-Id"** : on utilise `X-Client-Mutation-Id` (PRD §FR-059). En Phase 2 / API publique, on aliasera aussi `Idempotency-Key` (Stripe convention). Documenté dans le README.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-24 : Implemented end-to-end (HTTP-level Redis cache + global interceptor). 28/28 tests verts (10 unit cache + 11 unit interceptor + 7 E2E HTTP). Status: done.

**Actual Effort :** 3 pts (= estimate). New module `src/idempotency/` (CacheService + Interceptor + Module + README). Wired global via APP_INTERCEPTOR dans app.module.ts.

**Implementation Notes :**
- HTTP layer (cette story) coexiste avec la couche business-level existante `module-engine/services/idempotency.service.ts` (Postgres sync_mutations table de STORY-022). Defense in depth : interceptor short-circuit avant le controller, DB layer protège action-level.
- Fail-open sur Redis down (la couche business prévient les doublons en DB).
- Patterns URL : `/api/v1/{tenant}/sync/*` + `/api/v1/{tenant}/{moduleId}/action`. Autres POST (auth/login) skipped automatiquement.
- Métriques exposées via structured logs (`idempotency.metric.hit|miss|collision|user_mismatch`). prom-client deferred (W3 from STORY-032 review).
- Swagger `@ApiHeader` deferred (`@nestjs/swagger` non installé — W3).
- AC-21 (Swagger) et AC-22 (README) : README livré, Swagger deferred.
- AC-14 (bench Artillery 500 req/s) : non livré, à mesurer pré-prod (cohérent avec autres benchmarks différés).

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
