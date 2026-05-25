# STORY-V14-009 : @nestjs/swagger global + annotations @ApiHeader/@ApiBearerAuth tous controllers

**Epic :** EPIC-V14-005 — DX & Documentation
**Priorité :** Must Have
**Story Points :** 3
**Status :** defined
**Sprint :** v14-4 (2026-07-07 → 2026-07-20)
**Dépendances :** V14-005 (restructure NestJS)

---

## User Story

> **En tant que** dev Scalario (Phase 1) et futur intégrateur certifié (Phase 3),
> **je veux** une documentation Swagger générée automatiquement, accessible sur `/api/docs`, qui couvre tous les endpoints + headers obligatoires (`X-Tenant-ID`, `Authorization: Bearer`),
> **so that** Phase 1 = outil interne de debug pour Scalario Labs, Phase 3 = documentation publique pour intégrateurs.

---

## Description

### Background

J'avais différé Swagger (W3 deferred) dans STORY-032 + STORY-036 + STORY-042 v13. v14 §19.3 dit explicitement : "Swagger documente automatiquement l'API Scalario. En Phase 1, c'est l'outil interne de Scalario Labs. En Phase 3, c'est la documentation publique pour les intégrateurs."

### Scope

**In scope :**
- Installation `@nestjs/swagger` + `swagger-ui-express`
- Setup global dans `main.ts` : `SwaggerModule.setup('api/docs', ...)`
- Annotations sur tous les controllers existants : `@ApiTags`, `@ApiBearerAuth`, `@ApiHeader` (X-Tenant-ID, X-Client-Mutation-Id), `@ApiOperation`, `@ApiResponse`
- DTOs annotés : `@ApiProperty` sur tous les Zod schemas exposés
- Route `/api/docs` accessible en dev local, protégée en prod (basic auth Phase 1, public Phase 3)

**Out of scope :**
- Swagger public exposé sur api.scalario.app → Phase 3 (V14-036)
- Auto-génération depuis Zod via `nestjs-zod` — déféré (pour l'instant duplication acceptable Phase 1)

---

## Acceptance Criteria

### Setup

- [ ] **AC-01** — `pnpm add @nestjs/swagger swagger-ui-express` installé.
- [ ] **AC-02** — `main.ts` configure Swagger : `DocumentBuilder().setTitle('Scalario API').setVersion('1.0').addBearerAuth().addApiKey({ type:'apiKey', name:'X-Tenant-ID', in:'header' }).build()`.
- [ ] **AC-03** — `/api/docs` accessible en dev (NODE_ENV !== 'production').
- [ ] **AC-04** — En prod : protégé par basic auth (env var `SWAGGER_USER` + `SWAGGER_PASS`).

### Annotations controllers (tous existants après V14-005)

- [ ] **AC-05** — `BduiController`, `ActionDispatcher` controllers, `WorkflowController`, `SyncController`, `IdempotencyInterceptor` (info), `TenantsController`, `AuditController`, `PaymentController` annotés.
- [ ] **AC-06** — Chaque controller : `@ApiTags('<group>')` + `@ApiBearerAuth()`.
- [ ] **AC-07** — Endpoints `POST` action/sync : `@ApiHeader({ name: 'X-Client-Mutation-Id', required: true, schema: { format: 'uuid' } })`.
- [ ] **AC-08** — Endpoints multi-tenant : `@ApiHeader({ name: 'X-Tenant-ID', required: true })` (ou inféré du JWT — documenté).

### DTOs

- [ ] **AC-09** — Au minimum 20 DTOs critiques annotés avec `@ApiProperty` (login, action body, vente, perte, arrivage, workflow start/transition, conflict resolve, idempotency, etc.).
- [ ] **AC-10** — Enums Zod (`payment_method`, `status`, `cause`) exposés via `@ApiProperty({ enum: [...] })`.

### Tests

- [ ] **AC-11** — Test E2E : `GET /api/docs` retourne 200 + HTML Swagger UI.
- [ ] **AC-12** — Test E2E : `GET /api/docs-json` retourne 200 + JSON OpenAPI 3.0 valide.

---

## Technical Notes

### Snippet `main.ts`

```typescript
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api/v1', { exclude: ['health', 'api/docs', 'api/docs-json'] });

  const config = new DocumentBuilder()
    .setTitle('Scalario API')
    .setDescription('SaaS ERP IA-Driven pour PME africaines')
    .setVersion('1.0.0')
    .addBearerAuth()
    .addApiKey({ type: 'apiKey', name: 'X-Tenant-ID', in: 'header' }, 'tenant')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(3000);
}
```

### Edge cases

- Endpoints `@Public()` (auth login) : pas de `@ApiBearerAuth()`, juste body
- Routes file upload : `@ApiConsumes('multipart/form-data')` + `@ApiBody({ schema: ... })`
- Endpoints qui retournent un stream SSE : `@ApiProduces('text/event-stream')` (Phase 2)

---

## Dependencies

- **Prérequis :** V14-005 (restructure NestJS — pour avoir tous les controllers organisés)
- **Stories bloquées :** V14-019 (Forge bénéficie de la doc Swagger), V14-036 (Swagger public Phase 3)

---

## Definition of Done

- [ ] @nestjs/swagger installé + configuré
- [ ] /api/docs accessible en dev, protégé en prod
- [ ] ≥ 8 controllers annotés + ≥ 20 DTOs annotés
- [ ] 2 tests E2E (UI + JSON)
- [ ] sprint-status.yaml V14-009 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Setup + main.ts config + auth prod | 0.5 |
| Annotations 8+ controllers | 1.0 |
| Annotations 20+ DTOs | 1.0 |
| Tests E2E | 0.25 |
| Docs `docs/swagger-usage.md` | 0.25 |
| **Total** | **3** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
