# STORY-V14-001 : Migration nomenclature Scalario v14 (script semi-automatique)

**Epic :** EPIC-V14-001 — Migration v13→v14
**Priorité :** Must Have (déblocage Sprint v14-1)
**Story Points :** 2
**Status :** defined
**Assigned To :** Carlos
**Created :** 2026-05-25
**Sprint :** v14-1 (2026-05-26 → 2026-06-08)
**Dépendances :** aucune (première story du sprint v14-1)

---

## User Story

> **En tant que** dev Scalario,
> **je veux** un script qui renomme tous les symboles `BDUIEngine → Canvas`, `ModuleEngine → Flow`, etc. en gardant l'historique git lisible,
> **so that** la transition v13 → v14 ne génère pas de drift de nomenclature entre le code (Sprint 1-4) et la documentation v14, et que `git blame` continue de marcher.

---

## Description

### Background

Le pivot v14 (cf `Scalario_Architecture_v14.pdf` + `_bmad-output/architecture-v14/PRD-v14.md`) renomme tous les blocs techniques pour parler sans ambiguïté produit : `BDUIEngine → Scalario Canvas`, `ModuleEngine → Scalario Flow`, `SyncEngine → Scalario Vault + Sync`, etc.

Sans cette migration au début du sprint v14-1, on aurait un drift croissant entre :
- Le code Sprint 1-4 v13 sur `main` (avec `BDUIEngine`, `ModuleEngine`...)
- La doc v14 (qui parle de `Scalario Canvas`, `Scalario Flow`...)
- Les futures stories V14 qui référencent les nouveaux noms

Cette story livre **le script** qui fait la migration, **applique** la migration, et **vérifie** que tous les tests existants passent après renommage.

### Scope

**In scope :**
- Script `scripts/migrate-v13-to-v14.sh` (bash, ~200 lignes)
- Mapping de renommage complet (cf table ci-dessous)
- Migration par batch (1 bloc = 1 commit) pour reviewabilité
- Rollback automatique si tests échouent après un batch
- Document `_bmad-output/architecture-v14/migration-log.md` listant chaque renommage avec son commit SHA
- Memory `feedback_scalario_nomenclature_v14.md` créée avec les règles de naming
- Tests existants 100% verts après migration (~1424 tests sur main aujourd'hui)

**Out of scope :**
- Renommage du contenu des fichiers JSON catalogue (catalog/modules/*.json) — fait par V14-006 (Catalogue v14 restructuré)
- Renommage des story files `STORY-001.md` à `STORY-043.md` — restent comme référence d'audit
- Nouvelle structure NestJS `src/core/ + engines/ + bdui/ + ...` — fait par V14-005
- Suppression du payment module backend — fait par V14-025 (Mobile Money migré dans Scalario Sense)

### User flow

1. Carlos ouvre un terminal sur le repo `main`
2. Lance `bash scripts/migrate-v13-to-v14.sh --dry-run` → output liste des changements prévus
3. Lance `bash scripts/migrate-v13-to-v14.sh --apply` → exécute migration par batch
4. Après chaque batch :
   - Le script applique les `git mv` + `sed` du batch
   - Lance `pnpm typecheck && flutter analyze` côté NestJS + Flutter
   - Si erreurs → `git reset --hard HEAD` + abort
   - Si OK → `git commit` avec message `refactor(v14): rename <bloc>`
5. Fin migration : script affiche le résumé (X batches OK, Y fichiers touchés, Z lignes modifiées)

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
| `lib/core/offline/` | `lib/core/vault/` (data) + `lib/core/sync/` (sync) |
| `lib/core/offline/sync/` | `lib/core/sync/` |
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
| `catalogue/` | `catalog-loader/` |

### Conservés tels quels

- `ScreenConfig`, `ComponentConfig`, `RuleConfig` — contrats JSON
- `TenantConfig`, `EntityRecord` — entities DB
- `IdempotencyService`, `RbacGuard`, `AbacGuard` — services
- Tous les noms de tests (suite existante)

---

## Acceptance Criteria

### Script

- [ ] **AC-01** — Script `scripts/migrate-v13-to-v14.sh` existe et est exécutable (`chmod +x`).
- [ ] **AC-02** — Mode `--dry-run` affiche les renommages prévus sans rien modifier.
- [ ] **AC-03** — Mode `--apply` exécute la migration par batch.
- [ ] **AC-04** — Chaque batch : (a) `git mv` (préserve l'historique git), (b) `sed -i` sur les imports, (c) `pnpm typecheck && flutter analyze`, (d) si fail → `git reset --hard HEAD` + exit 1.
- [ ] **AC-05** — Le script génère 1 commit par batch avec message `refactor(v14): rename <bloc>` (Canvas, Flow, Vault, Sync, Shield, Watch).

### Migration appliquée

- [ ] **AC-06** — Code Flutter renommé : 0 référence `BDUIEngine`, `ComponentRegistry`, `RuleEvaluator`, `LayoutResolver`, `SyncQueueWorker`, `ConflictResolver` (sauf dans archive-v13/ et stories/).
- [ ] **AC-07** — Code NestJS renommé : 0 référence `module-engine/`, `workflow/` directe (sauf migrations DB historiques).
- [ ] **AC-08** — `pnpm typecheck` (NestJS) = 0 erreur.
- [ ] **AC-09** — `flutter analyze` = 0 erreur.
- [ ] **AC-10** — `pnpm jest --runInBand` (NestJS) = tous tests verts (~616 active).
- [ ] **AC-11** — `flutter test` = tous tests verts (~808 active).

### Documentation et memory

- [ ] **AC-12** — Document `_bmad-output/architecture-v14/migration-log.md` créé, listant chaque renommage avec son commit SHA + count de fichiers/lignes touchés.
- [ ] **AC-13** — Memory `feedback_scalario_nomenclature_v14.md` créée avec les règles de naming Scalario (12 engines nommés, conventions PascalCase + namespacing `Scalario*`).
- [ ] **AC-14** — `MEMORY.md` index mis à jour avec lien vers `feedback_scalario_nomenclature_v14.md`.

### Hygiène git

- [ ] **AC-15** — `git log --follow apps/flutter/lib/core/canvas/` retrace l'historique depuis `apps/flutter/lib/core/bdui/` (`git mv` a marché).
- [ ] **AC-16** — Aucun fichier perdu : `git diff --stat <main-pre-migration>..HEAD --name-status | grep -c "^A\|^D" == 0` (uniquement R= renames).

---

## Technical Notes

### Composants concernés

- **Script :** `scripts/migrate-v13-to-v14.sh` (nouveau, bash)
- **Document généré :** `_bmad-output/architecture-v14/migration-log.md` (nouveau)
- **Memory :** `~/.claude/projects/.../memory/feedback_scalario_nomenclature_v14.md`

### Structure du script (bash, ~200 lignes)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Batches de renommage (ordre = ordre d'exécution)
BATCHES=(
  "canvas:apps/flutter/lib/core/bdui→apps/flutter/lib/core/canvas:BDUIEngine→ScalarioCanvas,ComponentRegistry→ScalarioCanvasRegistry,..."
  "flow:apps/nestjs/src/module-engine→apps/nestjs/src/engines/action:..."
  "vault:apps/flutter/lib/core/offline/dao→apps/flutter/lib/core/vault/dao:..."
  "sync:apps/flutter/lib/core/offline/sync→apps/flutter/lib/core/sync:SyncQueueWorker→ScalarioSyncWorker,..."
  "shield:apps/nestjs/src/security→apps/nestjs/src/core/abac:..."
  "watch:apps/nestjs/src/audit→apps/nestjs/src/core/audit:..."
)

apply_batch() {
  local batch_name=$1
  local mv_specs=$2
  local sed_specs=$3

  # git mv
  IFS=',' read -ra MOVES <<< "$mv_specs"
  for move in "${MOVES[@]}"; do
    IFS='→' read -ra parts <<< "$move"
    git mv "${parts[0]}" "${parts[1]}"
  done

  # sed sur imports
  IFS=',' read -ra SUBS <<< "$sed_specs"
  for sub in "${SUBS[@]}"; do
    IFS='→' read -ra parts <<< "$sub"
    find apps -type f \( -name "*.ts" -o -name "*.dart" \) -exec \
      sed -i "s|${parts[0]}|${parts[1]}|g" {} +
  done

  # Validate
  (cd apps/nestjs && pnpm typecheck) || { git reset --hard HEAD; exit 1; }
  (cd apps/flutter && flutter analyze) || { git reset --hard HEAD; exit 1; }

  # Commit
  git add -A
  git commit -m "refactor(v14): rename $batch_name"
}

case "${1:-}" in
  --dry-run) for b in "${BATCHES[@]}"; do echo "Would apply: $b"; done ;;
  --apply)   for b in "${BATCHES[@]}"; do IFS=':' read -ra p <<< "$b"; apply_batch "${p[0]}" "${p[1]}" "${p[2]}"; done ;;
  *) echo "Usage: $0 --dry-run | --apply"; exit 2 ;;
esac
```

### Edge cases

- **Tests E2E qui contiennent des chaînes hardcodées** (ex: `expect(error).toContain('BDUIEngine')`) → mise à jour automatique par sed.
- **Imports relatifs** (`./module-engine/services/...`) → sed catches them via regex globale.
- **Fichiers générés** (`*.g.dart`, Drift schemas) → exclus via `find -not -name "*.g.dart"`.
- **Migrations TypeORM** (`1700000000XXX-*.ts`) → noms de tables/columns SQL restent (la nomenclature DB ≠ nomenclature code).
- **Stories Sprint 1-4** (`_bmad-output/stories/STORY-001-043.md`) → conservées telles quelles (référence d'audit dans STORY-AUDIT-v14.md).

### Sécurité

- Aucune (script local de refactor, pas de surface réseau).

---

## Dependencies

**Prérequis (techniques) :**
- aucune — première story du sprint v14-1.

**Stories bloquées par celle-ci :**
- V14-002 (Schéma BDUI + variant) — pour pouvoir éditer des fichiers nommés `canvas/component-config.zod.ts` au lieu de `bdui/...`
- V14-005 (Restructure NestJS) — la migration ouvre la voie vers la nouvelle structure
- V14-006 (Catalogue v14) — référencé après que la nomenclature soit propre
- V14-003 à V14-013 — toutes les stories du sprint v14-1 et v14-2

**Externes :** aucune.

---

## Definition of Done

- [ ] Script `scripts/migrate-v13-to-v14.sh` committé sur `main`
- [ ] Migration appliquée (~6 commits "refactor(v14): rename <bloc>")
- [ ] `pnpm typecheck` + `flutter analyze` + `pnpm test` + `flutter test` = tous verts
- [ ] `_bmad-output/architecture-v14/migration-log.md` rédigé
- [ ] Memory `feedback_scalario_nomenclature_v14.md` créée
- [ ] `MEMORY.md` index mis à jour
- [ ] PR review : auto-review Carlos
- [ ] Mis à jour `sprint-status.yaml` : V14-001 status `completed`, sprint v14-1 `completed_points += 2`

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Écriture du script bash (avec dry-run + rollback) | 0.75 | ~200 lignes bash, robuste avec set -euo pipefail |
| Mapping de renommage complet (Flutter + NestJS) | 0.5 | ~20 renames, traçage soigneux |
| Application + validation (typecheck + tests) | 0.5 | 6 batches × 5 min de validation = 30 min |
| Documentation migration-log + memory | 0.25 | Léger, mais important pour traçabilité |
| **Total** | **2** | Fibonacci 2 — tooling simple mais critique pour reviewabilité |

**Rationale :** Le risque n'est pas la complexité algorithmique (sed + git mv) mais le **risque de casser des choses subtiles** (imports circulaires, tests qui référencent des chaînes hardcodées). C'est pour ça que :
- Validation après chaque batch (rollback auto si erreur)
- Commits séparés par bloc (reviewabilité, blame git lisible)
- Dry-run d'abord obligatoire

---

## Progress Tracking

**Status History :**
- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
