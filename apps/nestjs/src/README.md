# `src/` — Structure NestJS Scalario v14

**Refactor appliqué par STORY-V14-005 (2026-05-25).**

## Vue d'ensemble

```
src/
├── core/                  Fondations (chargées une fois au boot)
│   ├── auth/              JWT + sessions
│   ├── security/          Scalario Shield — RBAC + ABAC + middleware tenant
│   ├── audit/             Scalario Watch — log de toute action sensible
│   ├── cache/             Redis client, rate limiter, blacklist
│   └── idempotency/       Idempotency-key interceptor + cache
│
├── engines/               Engines NestJS (logique métier dynamique)
│   ├── action/            Scalario Flow — action handlers + dispatcher
│   └── workflow/          Scalario Flow — FSM + executor + validator
│
├── bdui/                  Scalario Canvas backend — génère le JSON UI
│   ├── bdui.service.ts
│   ├── bdui.controller.ts
│   ├── cache/             (intra-bdui — pas le core/cache !)
│   └── ...
│
├── catalog-loader/        Chargeur du catalogue (modules + queries + ux_profiles)
│
├── config-agent/          Scalario Forge backend (Phase 2 — V14-019)
│   └── README.md          placeholder
│
├── ai/                    Pont vers FastAPI/Python LLM (Phase 2 — V14-014)
│   └── README.md          placeholder
│
├── modules/               6 moteurs ERP génériques (Phase 2 — V14-007)
│   └── README.md          placeholder
│
├── common/                Decorators, pipes, filters, interceptors partagés
├── tenants/               Gestion des tenants
├── payment/               Adapters paiement (sera migré vers Scalario Sense Flutter — V14-025)
├── sync/                  Sync controller (sera fusionné dans engines/action/ — V14-026)
├── realtime/              WebSocket gateway
├── health/                Health-check endpoints
├── ai-relay/              Relay pré-v14 (à fusionner avec ai/ en Phase 2)
│
├── app.module.ts          Module root
└── main.ts                Bootstrap
```

## Conventions v14

- **`core/`** : tout ce qui est chargé une fois et utilisé partout (security, audit, auth, cache).
- **`engines/`** : logique métier dynamique pilotée par le catalogue ou par requête (action, workflow, et futur algo/datasource en Phase 2).
- **`bdui/`** : reste séparé — c'est le pont entre le catalogue et le JSON envoyé à Scalario Canvas (Flutter).
- **`catalog-loader/`** : ex-`catalogue/`. Renommé pour clarifier qu'il **charge** le catalogue (lit `catalog/*.json` au boot) sans l'éditer.
- **Phase 2 placeholders** : `config-agent/`, `ai/`, `modules/` sont créés vides avec un README pour pré-réserver leur emplacement et documenter leur futur contenu.

## Mapping v13 → v14

| v13 | v14 | Notes |
|---|---|---|
| `src/auth/` | `src/core/auth/` | + 1 niveau de profondeur |
| `src/security/` | `src/core/security/` | abac/, guards/, middleware/, services/, dto/ tous conservés tels quels à l'intérieur |
| `src/audit/` | `src/core/audit/` | |
| `src/cache/` | `src/core/cache/` | ⚠️ `src/bdui/cache/` reste intra-bdui — pas confondre |
| `src/idempotency/` | `src/core/idempotency/` | |
| `src/module-engine/` | `src/engines/action/` | dispatcher devient ScalarioFlow.action |
| `src/workflow/` | `src/engines/workflow/` | FSM + executor + validator |
| `src/catalogue/` | `src/catalog-loader/` | renommé (même profondeur) |
| `src/bdui/` | `src/bdui/` | inchangé |
| `src/common/` | `src/common/` | inchangé |
| `src/tenants/` | `src/tenants/` | inchangé |
| `src/payment/` | `src/payment/` | sera supprimé en V14-025 (migration vers Scalario Sense Flutter) |
| `src/sync/` | `src/sync/` | sera fusionné dans `engines/action/sync.controller.ts` en V14-026 |
| `src/realtime/`, `src/health/`, `src/ai-relay/` | inchangé | |

## Comment naviguer

- **Une nouvelle feature métier ?** → `engines/action/handlers/` (handler) + config dynamique A2UI
- **Une nouvelle règle d'accès ?** → `core/security/abac/rules/`
- **Un nouvel endpoint utilisateur ?** → `engines/{action,workflow}/X.controller.ts`
- **Un nouveau provider OAuth ?** → `core/auth/strategies/`

## Tests

- Tous les tests passent après la migration v14 (`pnpm jest` → 616 passed, 7 skipped).
- Aucune régression vs baseline pré-V14-005.

## Liens

- Story : `_bmad-output/stories/STORY-V14-005.md`
- PRD v14 §19.1 — Architecture NestJS cible
- Migration log : `_bmad-output/architecture-v14/migration-log.md`
