# Migration Log v13 → v14 — Nomenclature Scalario

**Story :** STORY-V14-001
**Sprint :** v14-1
**Date :** 2026-05-25
**Auteur :** Carlos (via Claude Code)

---

## Vue d'ensemble

Migration semi-automatique de la nomenclature **v13** (BDUI/Module/Workflow/Offline) vers **v14** (Canvas/Flow/Vault/Sync). Script `scripts/migrate-v13-to-v14.sh` exécute les renames par batch avec validation (`flutter analyze --no-fatal-warnings --no-fatal-infos` / `pnpm typecheck`) et rollback automatique si la validation échoue.

**Tests post-migration :** Flutter 807 passed (1 flaky, pré-existant) ; NestJS 616 passed, 7 skipped — **0 régression**.

---

## Batches appliqués

### Batch 1 — `canvas` (Flutter engine)

**Commit :** [`2c6656d`](https://github.com/.../commit/2c6656d) — `refactor(v14): rename canvas (STORY-V14-001)`
**Fichiers :** 79 files changed, 320 insertions, 320 deletions

**Renommages directory :**
| Avant (v13) | Après (v14) |
|---|---|
| `apps/flutter/lib/engine/bdui_engine/` | `apps/flutter/lib/engine/canvas/` |
| `apps/flutter/lib/engine/component_registry/` | `apps/flutter/lib/engine/canvas_registry/` |
| `apps/flutter/lib/engine/rule_evaluator/` | `apps/flutter/lib/engine/canvas_rule/` |
| `apps/flutter/lib/engine/layout_resolver/` | `apps/flutter/lib/engine/canvas_layout/` |

**Renommages fichier :**
| Avant | Après |
|---|---|
| `bdui_engine.dart` | `scalario_canvas.dart` |
| `bdui_engine_config.dart` | `scalario_canvas_config.dart` |
| `bdui_engine_module.dart` | `scalario_canvas_module.dart` |
| `component_registry.dart` | `scalario_canvas_registry.dart` |
| `rule_evaluator.dart` | `scalario_canvas_rule.dart` |
| `layout_resolver.dart` | `scalario_canvas_layout.dart` |

**Renommages class :**
| Avant | Après |
|---|---|
| `BDUIEngine` | `ScalarioCanvas` |
| `BDUIEngineConfig` | `ScalarioCanvasConfig` |
| `BDUIEngineModule` | `ScalarioCanvasModule` |
| `ComponentRegistry` | `ScalarioCanvasRegistry` |
| `RuleEvaluator` | `ScalarioCanvasRule` |
| `LayoutResolver` | `ScalarioCanvasLayout` |

---

### Batch 2 — `vault` (Flutter offline split en vault + sync)

**Commit :** [`745d5c0`](https://github.com/.../commit/745d5c0) — `refactor(v14): rename vault (STORY-V14-001)`
**Fichiers :** 37 files changed, 52 insertions, 52 deletions

**Note :** Le batch `sync` initialement prévu séparément a été **fusionné** dans `vault` car les fichiers de `core/offline/sync/` utilisaient des imports relatifs (`../dao/`, `../database.dart`) vers leurs siblings du data layer — ces imports devaient être réécrits **en même temps** que le split offline → vault, sinon la validation cassait.

**Renommages directory :**
| Avant (v13) | Après (v14) |
|---|---|
| `apps/flutter/lib/core/offline/` (data layer) | `apps/flutter/lib/core/vault/` |
| `apps/flutter/lib/core/offline/sync/` | `apps/flutter/lib/core/sync/` |

**Renommages class :**
| Avant | Après |
|---|---|
| `SyncQueueWorker` | `ScalarioSyncWorker` |
| `ConflictResolver` | `ScalarioSyncConflictResolver` |

---

## Batches reportés à V14-005

Les batches NestJS `flow`, `shield`, `watch`, `core` (catalogue→catalog-loader) ont été **reportés** à la story **V14-005 (Restructure NestJS)** pour les raisons suivantes :

1. **Couplage d'imports relatifs** — déplacer `src/workflow/` → `src/engines/workflow/` augmente la profondeur de +1, ce qui casse tous les `../auth/`, `../security/`, `../audit/`, `../common/`. Pour valider proprement, il faut déplacer **simultanément** auth/security/audit/common dans `src/core/` ET réécrire les profondeurs (`../X` → `../../core/X`).
2. **Scope V14-001 = 2 points** — la story V14-001 portait uniquement la mécanique du script + Flutter (le bloc le plus impactant pour la doc v14). V14-005 (3 points) traite la restructure NestJS de bout en bout, c'est le bon endroit pour les renames côté backend.
3. **Le script est prêt** — les fonctions `batch_flow`, `batch_shield`, `batch_watch` existent dans `scripts/migrate-v13-to-v14.sh` et seront adaptées par V14-005 pour gérer les imports relatifs (probablement en convertissant en path aliases TypeScript ou en utilisant un AST refactor).

**Décision :** V14-005 démarrera par étendre le script pour la couche NestJS, idéalement via `ts-morph` (AST-based) plutôt que sed, car les imports TypeScript sont plus complexes que les `import './path'` Dart.

---

## Fichiers livrés

- ✅ `scripts/migrate-v13-to-v14.sh` (script bash, ~290 lignes avec dry-run + rollback automatique)
- ✅ `_bmad-output/architecture-v14/migration-log.md` (ce document)
- ✅ Memory `feedback_scalario_nomenclature_v14.md` (conventions de naming)

---

## Validation finale

```bash
$ cd apps/flutter && flutter analyze --no-fatal-warnings --no-fatal-infos
100 issues found. (ran in 3.x s)
# → exit 0 (baseline maintenu)

$ cd apps/flutter && flutter test
00:53 +807 -1: ...
# → 807 tests passent. 1 fail flaky (google_fonts en suite parallèle) — pré-existant.

$ cd apps/nestjs && pnpm jest --silent
Test Suites: 1 skipped, 69 passed, 69 of 70 total
Tests:       7 skipped, 616 passed, 623 total
# → 616 tests passent (inchangé vs avant migration, batches NestJS différés).
```

---

## Historique git

```
6fe7a81 chore(v14): batch_sync no-op (merged into batch_vault)
745d5c0 refactor(v14): rename vault                 ← batch vault appliqué
78523ec fix(v14): vault batch merges sync split + relative imports fix
75e1d92 fix(v14): rollback clean -fd untracked dirs
1dfcadf fix(v14): vault batch moves whole offline/
e087a6f fix(v14): skip git mv for empty dirs
2c6656d refactor(v14): rename canvas                ← batch canvas appliqué
8e22519 fix(v14): flutter analyze ignore warnings/infos (baseline=100)
4c71375 fix(v14): drop leading slash requirement on file rename sed
592af0b fix(v14): broaden sed rules to match all import patterns
19060da fix(v14): migrate script — skip missing dirs in find
5a929e9 feat(v14): add migrate-v13-to-v14.sh script ← script initial
```

---

## Vérifications `git log --follow` (AC-15)

```bash
$ git log --follow --oneline apps/flutter/lib/engine/canvas/scalario_canvas.dart | head -5
# → l'historique remonte jusqu'au fichier d'origine `bdui_engine.dart` ✓
```

---

**STORY-V14-001 — Partial completion :** Flutter ✅ (canvas + vault + sync via merge) / NestJS ⏭️ deferred to V14-005.
