# STORY-013 : NestJS Setup + Docker Compose 5 services

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** Aucune (story de base de l'epic Backend)

---

## User Story

> **En tant que** dev backend Scalario,
> **je veux** un projet NestJS bootstrappé dans `apps/nestjs/` avec sa structure modulaire complète et un `docker-compose.yml` qui démarre les 5 services (`nestjs`, `postgres`, `redis`, `fastapi` stub, `minio` stub),
> **so that** toute l'équipe peut démarrer l'environnement backend en une seule commande, chaque module métier (auth, bdui, module-engine, workflow, catalogue, tenants, security, sync, audit, ai-relay, realtime, common) a une place définie, et les stories STORY-014 à STORY-020 ont une fondation propre.

---

## Description

### Background

Scalario backend = NestJS principal + FastAPI IA (Phase 2) + PostgreSQL/pgvector + Redis + MinIO. Sans bootstrap commun, chaque story Sprint 2 perdrait du temps à recréer la structure. Cette story matérialise la convention `architecture-scalario-2026-05-09.md` (lines 1642-1660 + Docker Compose lines 242-255) en un projet exécutable.

C'est la fondation absolue du backend — STORY-014 (Auth JWT), STORY-015 (RBAC), STORY-016 (Multi-tenant), STORY-017 (RLS), STORY-018 (Redis), STORY-019 (ABAC CASL), STORY-020 (Audit) construisent toutes leurs modules dans cette structure. Aucune story de l'epic ne peut commencer sans elle.

### Scope

**In scope :**

- Bootstrap NestJS dans `apps/nestjs/` (Nest CLI v10+, TypeScript strict).
- Création des 11 modules vides selon architecture : `auth/`, `bdui/`, `module-engine/`, `workflow/`, `catalogue/`, `tenants/`, `security/`, `sync/`, `audit/`, `ai-relay/`, `realtime/`, `common/`.
- Chaque module suit la convention `module-engine.module.ts` + `*.service.ts` + `*.controller.ts` + `dto/` + `interfaces/` + `__tests__/`.
- `docker-compose.yml` (production) avec 5 services : `nestjs`, `postgres` (image `pgvector/pgvector:pg16`), `redis` (`redis:7-alpine`), `fastapi` (Phase 2 stub — `python:3.12-slim` avec `main.py` health check), `minio` (Phase 2 stub — `minio/minio:latest`).
- `docker-compose.dev.yml` (override) qui ajoute `adminer` (port 8080, dashboard DB).
- Health checks sur les 5 services (HTTP `/health` pour nestjs/fastapi, `pg_isready` pour postgres, `redis-cli ping` pour redis, `mc ready local` pour minio).
- `.env.example` racine + un par app, gitignore strict (jamais de secret committé).
- `apps/nestjs/.env.example` avec `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `FASTAPI_URL`, `MINIO_*`, `NODE_ENV`, `PORT`.
- `pnpm-workspace.yaml` configuré : `apps/*` + `packages/*` (Flutter exclu — pubspec local).
- `package.json` racine avec scripts `dev`, `build`, `lint`, `test`, `docker:up`, `docker:down`.
- ESLint + Prettier + `tsconfig.json` (strict) + `nest-cli.json`.
- TypeORM (ou Prisma — choix figé ici : **TypeORM**) configuré avec migration boilerplate, `DataSource` exposé via `database.module.ts` dans `common/`.
- Endpoint `GET /health` dans `apps/nestjs/src/health/health.controller.ts` (NestJS `@nestjs/terminus`) qui ping postgres + redis.
- README racine "Quickstart en 3 commandes" (clone → `pnpm install` → `docker compose up`).
- CI GitHub Actions `.github/workflows/ci.yml` avec job `nestjs-tests` (lint + jest + build) — matrix avec flutter ajoutable plus tard.

**Out of scope (autres stories) :**

- Implémentation auth JWT → STORY-014.
- Implémentation RBAC Guards → STORY-015.
- Middleware multi-tenant → STORY-016.
- Politiques RLS → STORY-017.
- Configuration Redis cache → STORY-018.
- CASL ABAC → STORY-019.
- Audit Log service → STORY-020.
- BDUIService / ModuleEngine endpoints → EPIC-004 (Sprint 3).

### Runtime Flow (Developer Experience)

1. Dev clone le repo : `git clone scalario && cd scalario`.
2. Dev installe les dépendances : `pnpm install` (root + workspaces).
3. Dev copie `.env.example` → `.env` et ajuste `JWT_SECRET` minimum.
4. Dev lance : `docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d`.
5. 5 services démarrent ; health checks passent en < 60s.
6. Dev ouvre `http://localhost:3000/health` → `{"status":"ok","postgres":"up","redis":"up"}`.
7. Dev ouvre `http://localhost:8080` → Adminer connecté à `postgres:5432`.
8. Dev exécute `pnpm --filter @scalario/nestjs run start:dev` → hot reload NestJS.
9. STORY-014 peut commencer dans `apps/nestjs/src/auth/`.

---

## Acceptance Criteria

### Setup monorepo

- [ ] AC-01 — Structure monorepo créée avec `apps/{nestjs,flutter,fastapi}/`, `packages/{bdui-schema,bdui-types}/` (placeholders), `catalog/{domains,modules,fusions,schemas}/` (placeholders).
- [ ] AC-02 — `pnpm-workspace.yaml` déclare `apps/*` + `packages/*`. `apps/flutter/` exclu (pubspec.yaml local).
- [ ] AC-03 — `package.json` racine avec scripts : `dev`, `build`, `lint`, `test`, `docker:up`, `docker:down`, `typecheck`.

### NestJS bootstrap

- [ ] AC-04 — `apps/nestjs/` créé via `nest new` (NestJS v10+, TypeScript strict mode `"strict": true`).
- [ ] AC-05 — Structure modulaire complète selon architecture line 1645-1657 :
  - `src/auth/` (vide, prêt pour STORY-014)
  - `src/bdui/` (vide, prêt pour EPIC-004)
  - `src/module-engine/` (vide)
  - `src/workflow/` (vide)
  - `src/catalogue/` (vide)
  - `src/tenants/` (vide)
  - `src/security/` (vide, prêt pour STORY-015 / STORY-019)
  - `src/sync/` (vide)
  - `src/audit/` (vide, prêt pour STORY-020)
  - `src/ai-relay/` (vide)
  - `src/realtime/` (vide)
  - `src/common/` (database module, interceptors, pipes, decorators)
  - `src/health/` (health check controller)
  - `src/app.module.ts` qui agrège tous les modules.
- [ ] AC-06 — Chaque dossier de module contient un `<name>.module.ts` exportant un module NestJS vide mais valide (`@Module({})`) + un `__tests__/` vide.
- [ ] AC-07 — `apps/nestjs/.env.example` contient sans valeurs réelles : `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `FASTAPI_URL`, `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `NODE_ENV`, `PORT`.
- [ ] AC-08 — `tsconfig.json` strict + `eslint` + `prettier` configurés. `pnpm lint` passe sans erreur. `pnpm typecheck` passe sans erreur.

### Health endpoint

- [ ] AC-09 — `GET /health` retourne `200 OK` avec `{ status: 'ok', postgres: 'up', redis: 'up', uptime: <number> }` en moins de 100ms quand les 2 dépendances sont up.
- [ ] AC-10 — `GET /health` retourne `503` si postgres OU redis down (vérifié par test d'intégration avec `docker stop`).
- [ ] AC-11 — Endpoint `/health` n'est PAS protégé par auth (c'est intentionnel pour les load balancers et docker healthcheck).

### Docker Compose

- [ ] AC-12 — `docker-compose.yml` racine déclare 5 services : `nestjs`, `postgres`, `redis`, `fastapi`, `minio`.
- [ ] AC-13 — Image PostgreSQL = `pgvector/pgvector:pg16` (extension pgvector requise pour Phase 2 RAG, mais activée dès maintenant pour parité dev/prod). Volume nommé `pgdata`. Variables `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` lues depuis `.env`.
- [ ] AC-14 — Image Redis = `redis:7-alpine`. Mot de passe via `REDIS_PASSWORD` (`requirepass`). Volume `redisdata` pour AOF persistence.
- [ ] AC-15 — Service `fastapi` = stub Phase 2 : Dockerfile `services/fastapi/Dockerfile` minimal (python:3.12-slim + uvicorn + FastAPI + un endpoint `GET /health` retournant `{"status":"phase2-stub"}`). Le service démarre mais n'expose aucune route métier.
- [ ] AC-16 — Service `minio` = stub Phase 2 : image `minio/minio:latest` avec console désactivée Phase 1 (`--console-address ""`), volume `miniodata`. Buckets non provisionnés Phase 1.
- [ ] AC-17 — Health checks définis sur chaque service avec `interval: 10s, timeout: 5s, retries: 5` :
  - `nestjs` : `curl -f http://localhost:3000/health`
  - `fastapi` : `curl -f http://localhost:8000/health`
  - `postgres` : `pg_isready -U $POSTGRES_USER`
  - `redis` : `redis-cli -a $REDIS_PASSWORD ping`
  - `minio` : `curl -f http://localhost:9000/minio/health/live`
- [ ] AC-18 — `nestjs` `depends_on` postgres + redis avec `condition: service_healthy`. `fastapi` `depends_on` postgres + redis sans `service_healthy` (stub).
- [ ] AC-19 — `docker-compose.dev.yml` override ajoute `adminer` (image `adminer:latest`, port 8080, `depends_on: postgres`). Aucune autre divergence dev/prod (parité environnements).

### Database bootstrap

- [ ] AC-20 — TypeORM configuré dans `apps/nestjs/src/common/database.module.ts` : `DataSource` injectable, `synchronize: false` (toujours migrations), pool = 10 connexions.
- [ ] AC-21 — Première migration `1700000000000-init.ts` qui exécute `CREATE EXTENSION IF NOT EXISTS vector;` + `CREATE EXTENSION IF NOT EXISTS pgcrypto;` (UUID gen_random_uuid). Aucune table métier créée dans cette migration — uniquement les extensions.
- [ ] AC-22 — Scripts NPM dans `apps/nestjs/package.json` : `migration:generate`, `migration:run`, `migration:revert`.

### CI

- [ ] AC-23 — `.github/workflows/ci.yml` avec job `nestjs-tests` : `pnpm install` → `pnpm --filter @scalario/nestjs run lint` → `pnpm --filter @scalario/nestjs run test` → `pnpm --filter @scalario/nestjs run build`.
- [ ] AC-24 — CI utilise services postgres + redis (GitHub Actions `services:`) pour les tests d'intégration health check.

### Documentation

- [ ] AC-25 — README racine "Quickstart en 3 commandes" :
  ```
  git clone https://github.com/scalario/scalario.git && cd scalario
  cp .env.example .env && pnpm install
  docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
  ```
  + section troubleshooting (port 5432 occupé, port 3000 occupé, .env manquant).

---

## Technical Notes

### Composants concernés

- **Nouveau projet NestJS :** `apps/nestjs/` (créé par cette story, base pour STORY-014 à STORY-020 et tous les epics backend).
- **Docker Compose :** `docker-compose.yml`, `docker-compose.dev.yml` à la racine.
- **CI :** `.github/workflows/ci.yml`.
- **Stub FastAPI :** `services/fastapi/main.py` minimal, sera étoffé Phase 2 (FR-024+).

### Structure de fichiers (cible)

```
scalario/
├── apps/
│   └── nestjs/
│       ├── src/
│       │   ├── main.ts
│       │   ├── app.module.ts
│       │   ├── auth/
│       │   │   ├── auth.module.ts          # vide pour STORY-014
│       │   │   └── __tests__/
│       │   ├── bdui/
│       │   ├── module-engine/
│       │   ├── workflow/
│       │   ├── catalogue/
│       │   ├── tenants/
│       │   ├── security/
│       │   ├── sync/
│       │   ├── audit/
│       │   ├── ai-relay/
│       │   ├── realtime/
│       │   ├── common/
│       │   │   ├── database.module.ts      # TypeORM DataSource
│       │   │   ├── interceptors/
│       │   │   ├── pipes/
│       │   │   └── decorators/
│       │   └── health/
│       │       ├── health.controller.ts    # @nestjs/terminus
│       │       └── health.module.ts
│       ├── migrations/
│       │   └── 1700000000000-init.ts       # CREATE EXTENSION
│       ├── test/
│       ├── .env.example
│       ├── nest-cli.json
│       ├── tsconfig.json
│       ├── package.json
│       └── Dockerfile
├── services/
│   └── fastapi/
│       ├── main.py                         # FastAPI stub Phase 2
│       ├── Dockerfile
│       └── requirements.txt
├── packages/
│   ├── bdui-schema/                        # placeholder
│   └── bdui-types/                         # placeholder
├── catalog/
│   ├── domains/
│   ├── modules/
│   ├── fusions/
│   └── schemas/
├── docker-compose.yml
├── docker-compose.dev.yml
├── pnpm-workspace.yaml
├── package.json
├── .env.example
├── .gitignore                              # .env, dist, node_modules, pgdata
└── README.md
```

### Pattern Docker Compose (extrait)

```yaml
# docker-compose.yml
version: "3.9"
services:
  nestjs:
    build: ./apps/nestjs
    restart: unless-stopped
    env_file: .env
    ports: ["3000:3000"]
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres:
    image: pgvector/pgvector:pg16
    restart: unless-stopped
    env_file: .env
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}", "--appendonly", "yes"]
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  fastapi:
    build: ./services/fastapi
    restart: unless-stopped
    env_file: .env
    ports: ["8000:8000"]
    depends_on: [postgres, redis]

  minio:
    image: minio/minio:latest
    restart: unless-stopped
    command: server /data --console-address ""
    env_file: .env
    volumes:
      - miniodata:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]

volumes:
  pgdata:
  redisdata:
  miniodata:
```

### Pattern Health Controller

```typescript
// apps/nestjs/src/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';
import { RedisHealthIndicator } from './redis.health';

@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly db: TypeOrmHealthIndicator,
    private readonly redis: RedisHealthIndicator,
  ) {}

  @Get()
  check() {
    return this.health.check([
      () => this.db.pingCheck('postgres'),
      () => this.redis.isHealthy('redis'),
    ]);
  }
}
```

### Pattern Database Module

```typescript
// apps/nestjs/src/common/database.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'postgres',
        url: process.env.DATABASE_URL,
        synchronize: false,             // toujours migrations
        migrationsRun: false,           // exécuté explicitement par script
        migrations: ['dist/migrations/*.js'],
        extra: { max: 10 },             // pool
        autoLoadEntities: true,
      }),
    }),
  ],
})
export class DatabaseModule {}
```

### Edge cases

- **Port conflicts (5432, 6379, 3000, 8000, 9000) :** Dev local peut avoir Postgres natif sur 5432. Documenter dans README : exposer postgres sur `5433:5432` si conflit. Ne PAS le faire par défaut — parité prod = 5432.
- **Secrets dans `.env` :** `.env` est gitignoré ; `.env.example` est committé sans secrets. CI doit pouvoir lire des secrets depuis GitHub Secrets (pas depuis `.env`).
- **Première migration sans tables :** Volontairement vide en termes de schéma métier — STORY-014 à STORY-020 ajoutent leurs propres migrations. Cette story garantit juste que l'extension `vector` et `pgcrypto` sont disponibles.
- **MinIO console désactivée Phase 1 :** Risque exposition console admin si activée par défaut. Phase 2 activera la console derrière auth NestJS.
- **FastAPI stub Phase 2 :** Une équipe pourrait être tentée de coder dedans. Convention : tout PR qui touche `services/fastapi/` hors STORY-013 est rejeté jusqu'à Phase 2 (FR-024).

### Sécurité — première brique

Cette story ne déploie pas de logique de sécurité métier (c'est STORY-014+), mais pose les bases :

- **Secrets gestion :** Aucun secret en dur dans `docker-compose.yml`. Tous via `.env` (gitignored).
- **Réseau Docker :** Par défaut, Docker Compose crée un réseau bridge isolé. Seuls les ports nestjs (3000), fastapi (8000), minio (9000), adminer (8080 dev only) sont exposés sur `localhost`. PostgreSQL et Redis ne sont PAS exposés publiquement (`expose:` sans `ports:` en prod ; en dev, exposés sur 5432/6379 pour Adminer/redis-cli local).
- **Image hardening :** Images officielles uniquement (pas de fork random). `pgvector/pgvector:pg16` est l'image officielle pgvector, vérifiée.
- **Healthcheck = pas auth :** L'endpoint `/health` est public mais ne révèle aucune donnée métier — uniquement statut up/down.

### Threat model (cette couche)

| Menace | Mitigation par cette story |
|---|---|
| Secret committé en clair (JWT_SECRET, DB password) | `.env.example` sans valeurs + `.gitignore` strict + pre-commit hook (Phase ult.) |
| Port DB exposé publiquement | Pas de `ports:` sur postgres/redis en prod (uniquement `expose:`) |
| Image Docker compromise | Images officielles + tags pinned (`pgvector/pgvector:pg16`, pas `:latest`) |
| Health endpoint leakant info | Réponse limitée à status + names — pas de version, pas de stack trace, pas de DSN |
| MinIO console exposée | Désactivée Phase 1 (`--console-address ""`) |
| `synchronize: true` TypeORM en prod | Forcé à `false` au niveau module (revue de code obligatoire) |

### Conflit avec sprint plan ligne 314

Le sprint plan AC liste `apps/{flutter,nestjs,fastapi}/`. **Cohérent.** Aucun conflit.

Le sprint plan ligne 328 mentionne 5 services : `nestjs`, `fastapi`, `postgresql`, `redis`, `minio`. **Cohérent.** Cette story aligne sur l'architecture (line 247-251) avec service `postgres` (alias plus court — TypeORM utilise `postgres` standard) — documenter le nommage dans README.

---

## Dependencies

**Prérequis :** Aucun (story d'amorce de l'epic Backend).

**Stories bloquées par celle-ci :**

- STORY-014 (Auth JWT Multi-tenant) — direct
- STORY-015 (RBAC Guards Dynamiques) — via STORY-014
- STORY-016 (Multi-tenant Isolation) — via STORY-014
- STORY-017 (PostgreSQL RLS) — via STORY-016
- STORY-018 (Redis Sessions + Cache) — direct
- STORY-019 (ABAC CASL) — via STORY-015
- STORY-020 (Audit Log) — via STORY-014, STORY-016
- Indirectement, **toutes** les stories backend de l'EPIC-004, EPIC-005, EPIC-006, EPIC-007.

**Externes :**

- Docker + Docker Compose v2 installés sur la machine dev.
- pnpm v9+ installé.
- Node.js v20+ installé.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-013-nestjs-setup` (ou équivalent).
- [ ] `pnpm install` réussit à la racine sans erreur.
- [ ] `pnpm --filter @scalario/nestjs run lint` passe sans erreur ni warning.
- [ ] `pnpm --filter @scalario/nestjs run typecheck` passe.
- [ ] `pnpm --filter @scalario/nestjs run test` passe (tests minimes — health controller).
- [ ] `pnpm --filter @scalario/nestjs run build` produit `dist/` sans erreur.
- [ ] `docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d` démarre les 6 services (5 + adminer) avec tous les health checks passants en < 60 secondes.
- [ ] `curl http://localhost:3000/health` retourne 200 avec postgres + redis up.
- [ ] `curl http://localhost:8000/health` retourne 200 (stub FastAPI).
- [ ] Adminer accessible sur `http://localhost:8080`, login postgres OK.
- [ ] CI GitHub Actions verte sur la PR.
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-013 status `completed`, completed_points sprint 2 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Bootstrap NestJS (`nest new`) + structure modules + tsconfig strict + eslint/prettier | 0.5 | Boilerplate, mais 11 modules à créer proprement. |
| `docker-compose.yml` 5 services + `docker-compose.dev.yml` adminer + healthchecks | 1.0 | Le plus délicat — health checks fiables, depends_on conditions, volumes nommés. |
| Stubs FastAPI + MinIO (Dockerfile + endpoint health stub Python) | 0.5 | Mini effort mais doit passer le health check Docker. |
| Health controller NestJS (`@nestjs/terminus` + RedisHealthIndicator custom) + tests | 0.5 | Inclut RedisHealthIndicator custom (terminus n'a pas de check Redis natif). |
| TypeORM DataSource module + migration `init.ts` extensions | 0.25 | Simple — `CREATE EXTENSION` × 2. |
| `.env.example` racine + apps + `.gitignore` strict + README Quickstart + CI workflow | 0.25 | Souvent sous-estimé — la doc fait la différence pour l'onboarding. |
| **Total** | **3** | Fibonacci 3 — moderate. Pas de logique métier, mais beaucoup de fichiers et de config infra. |

**Rationale :** L'effort est dans la cohérence et les health checks fiables, pas dans la complexité algorithmique. Sans cette base, chaque story Sprint 2 aurait son propre setup ad-hoc — coût caché 10× supérieur.

---

## Notes additionnelles

- **Pourquoi TypeORM et pas Prisma ?** TypeORM offre un meilleur support PostgreSQL RLS (control fin du `DataSource.query` pour `SET app.current_tenant_id`). Prisma 5.x supporte RLS via `$executeRaw` mais nécessite des workarounds. STORY-017 (RLS) confirmera ce choix avec un test d'intrusion.
- **Pourquoi `pgvector/pgvector:pg16` dès Phase 1 ?** Parité dev/prod. Activer pgvector en Phase 1 coûte 0 (extension désactivée si non utilisée) mais évite une migration disruptive en Phase 2 (RAG, FR-025).
- **Pourquoi pas Nx/Turborepo ?** Sprint plan note (line 335) : overkill solo dev Phase 1. pnpm workspaces suffit. Ajoutable plus tard sans casser la structure.
- **Convention de nommage modules NestJS :** `@scalario/nestjs` au niveau package.json (alias workspace), permet `pnpm --filter @scalario/nestjs run …`.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
