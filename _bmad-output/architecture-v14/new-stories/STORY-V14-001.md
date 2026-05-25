# STORY V14-001 — Migration nomenclature Scalario (script semi-automatique)

**Phase :** 1 — Fondations
**Bloc :** Tooling / refactor
**Story Points :** 2
**Status :** defined
**Created :** 2026-05-25
**Dépendances :** aucune

---

## User Story

> **En tant que** dev Scalario,
> **je veux** un script qui renomme tous les symboles BDUIEngine → Canvas, ModuleEngine → Flow, etc. en gardant l'historique git lisible,
> **so that** la transition v13 → v14 ne génère pas de drift de nomenclature entre le code et la documentation.

---

## Mapping de renommage

### Côté Flutter (`apps/flutter/`)

| Avant (v13) | Après (v14) |
|---|---|
| `BDUIEngine` | `ScalarioCanvas` (renderer) + `ScalarioFlow` (orchestrateur) |
| `ComponentRegistry` | `ScalarioCanvasRegistry` |
| `RuleEvaluator` | `ScalarioCanvasRule` |
| `LayoutResolver` | `ScalarioCanvasLayout` |
| `lib/core/bdui/` | `lib/core/canvas/` (UI) + `lib/core/flow/` (orchestration) |
| `lib/core/offline/sync/` | `lib/core/vault/sync/` |
| `lib/core/offline/dao/` | `lib/core/vault/dao/` |
| `SyncQueueWorker` | `ScalarioSyncWorker` |
| `ConflictResolver` | `ScalarioSyncConflictResolver` |
| `lib/features/sync/` | `lib/features/sync_status_bar/` (composant DS) |

### Côté NestJS (`apps/nestjs/src/`)

| Avant (v13) | Après (v14) |
|---|---|
| `module-engine/` | `engines/action/` (Scalario Flow) |
| `workflow/` | `engines/workflow/` (sous Scalario Flow) |
| `bdui/` | `bdui/` (reste — sert le JSON UI) |
| `cache/` | `core/cache/` |
| `auth/` | `core/auth/` |
| `security/` | `core/rbac/` + `core/abac/` |
| `audit/` | `core/audit/` |
| `payment/` | (à supprimer Phase 2 — migré dans Flutter Scalario Sense) |
| `catalogue/` | `catalog-loader/` |

### Côté infra

- `docker-compose.yml` : ajouter `fastapi:` service (V14-014)
- `catalog/` : nouvelle structure (V14-006)

---

## Acceptance Criteria

- [ ] AC-01 — Script `scripts/migrate-v13-to-v14.sh` qui :
  - Exécute `git mv` (préserve l'historique git, pas `mv` brut)
  - Renomme les imports avec `find . -name "*.ts" -exec sed -i ...`
  - Lance `flutter analyze` + `pnpm typecheck` après chaque batch
  - Rollback automatique si erreurs > 0
- [ ] AC-02 — Run du script en local : 0 erreur typecheck + 0 erreur lint après migration.
- [ ] AC-03 — Tous les tests existants passent après renommage (628 NestJS + 808 Flutter).
- [ ] AC-04 — Document `_bmad-output/architecture-v14/migration-log.md` listant chaque renommage avec son commit SHA.
- [ ] AC-05 — Mémoire `feedback_scalario_nomenclature_v14.md` créée avec les règles de naming.

---

## Notes techniques

- **Ne pas tout migrer en un commit** — split par bloc (Canvas, Flow, Vault, Sync, Shield, Watch) pour des commits reviewables.
- **Préserver les chemins d'import dans les tests** — utiliser jest moduleNameMapper si nécessaire.
- **Conservation des noms `ScreenConfig`, `ComponentConfig`, `RuleConfig`** : ces noms restent — ce sont des contrats JSON, pas des engines.

---

## Definition of Done

- [ ] Script committé sur `main`
- [ ] Migration appliquée, tests verts
- [ ] Memory + docs à jour
- [ ] PR review Carlos
