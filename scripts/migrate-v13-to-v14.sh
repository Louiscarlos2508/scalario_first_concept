#!/usr/bin/env bash
#
# migrate-v13-to-v14.sh — Migration semi-automatique de la nomenclature Scalario v13 → v14.
#
# STORY-V14-001 (cf `_bmad-output/stories/STORY-V14-001.md`).
#
# Principe :
#   1. Migration par "batch" (1 bloc Scalario = canvas, vault, sync, flow, shield, watch).
#   2. Chaque batch fait : `git mv` + `sed -i` sur imports/symboles + validation (typecheck/analyze) + commit.
#   3. Si validation échoue → `git reset --hard HEAD` (annule le batch) + sortie en erreur.
#
# Usage :
#   bash scripts/migrate-v13-to-v14.sh --dry-run            # liste les opérations, ne modifie rien
#   bash scripts/migrate-v13-to-v14.sh --apply <batch>      # applique UN batch (canvas, vault, sync, flow, shield, watch, all)
#   bash scripts/migrate-v13-to-v14.sh --apply all          # applique tous les batches d'affilée

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────────────────────

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

NESTJS_DIR="apps/nestjs"
FLUTTER_DIR="apps/flutter"

DRY_RUN=0
TARGET_BATCH=""

# Couleurs pour le log
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

log()   { echo -e "${BLUE}[migrate]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
fail()  { echo -e "${RED}[fail]${NC} $*"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

ensure_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    fail "Worktree non-clean — commit ou stash avant de lancer la migration."
  fi
}

dry_run_or_exec() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] $*"
  else
    eval "$@"
  fi
}

# git mv qui crée le dossier parent si besoin ; skip si source absente ou vide pour git
gmv() {
  local src=$1
  local dst=$2
  if [[ ! -e "$src" ]]; then
    warn "skip git mv : $src n'existe pas"
    return 0
  fi
  # Si c'est un répertoire, vérifier qu'il contient au moins un fichier tracké
  if [[ -d "$src" ]] && [[ -z "$(git ls-files "$src" 2>/dev/null)" ]]; then
    warn "skip git mv : $src ne contient aucun fichier tracké (dossier vide ou non-versionné)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] git mv $src $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  git mv "$src" "$dst"
}

# sed -i sur tous les .ts/.dart (hors générés)
sed_inplace() {
  local pattern=$1
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] sed -i -E '$pattern' (sur *.ts + *.dart, hors générés)"
    return 0
  fi
  # Fichiers à traiter : .ts + .dart, hors générés (*.g.dart) et hors node_modules/dist/.dart_tool
  local search_dirs=()
  for d in "$NESTJS_DIR/src" "$NESTJS_DIR/test" "$FLUTTER_DIR/lib" "$FLUTTER_DIR/test"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done
  find "${search_dirs[@]}" \
    -type f \( -name "*.ts" -o -name "*.dart" \) \
    ! -name "*.g.dart" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/.dart_tool/*" \
    -exec sed -i -E "$pattern" {} +
}

validate_nestjs() {
  log "validating NestJS (tsc --noEmit)…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] (cd $NESTJS_DIR && pnpm typecheck)"
    return 0
  fi
  (cd "$NESTJS_DIR" && pnpm typecheck) || return 1
}

validate_flutter() {
  log "validating Flutter (flutter analyze --no-fatal-warnings --no-fatal-infos)…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] (cd $FLUTTER_DIR && flutter analyze --no-fatal-warnings --no-fatal-infos)"
    return 0
  fi
  # Baseline = 100 issues warning/info ; on n'échoue que sur des `error` réels.
  (cd "$FLUTTER_DIR" && flutter analyze --no-fatal-warnings --no-fatal-infos) || return 1
}

commit_batch() {
  local batch=$1
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [DRY-RUN] git commit -m \"refactor(v14): rename $batch\""
    return 0
  fi
  git add -A
  if git diff --cached --quiet; then
    warn "Aucun changement à committer pour batch '$batch'"
    return 0
  fi
  git commit -m "refactor(v14): rename $batch (STORY-V14-001)"
  ok "committed batch $batch — $(git rev-parse --short HEAD)"
}

rollback_batch() {
  local batch=$1
  warn "Rollback batch '$batch' (git reset --hard HEAD)"
  git reset --hard HEAD
  fail "Batch '$batch' a échoué — état restauré."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : canvas (Flutter engine renames)
#
# Avant (v13)                                 → Après (v14)
#   apps/flutter/lib/engine/bdui_engine/      → apps/flutter/lib/engine/canvas/
#   apps/flutter/lib/engine/component_registry/ → apps/flutter/lib/engine/canvas_registry/
#   apps/flutter/lib/engine/rule_evaluator/   → apps/flutter/lib/engine/canvas_rule/
#   apps/flutter/lib/engine/layout_resolver/  → apps/flutter/lib/engine/canvas_layout/
# Classes :
#   BDUIEngine             → ScalarioCanvas
#   ComponentRegistry      → ScalarioCanvasRegistry
#   RuleEvaluator          → ScalarioCanvasRule
#   LayoutResolver         → ScalarioCanvasLayout
# ─────────────────────────────────────────────────────────────────────────────

batch_canvas() {
  log "▶ Batch: canvas (Flutter engine renames)"

  # 1) Directory renames
  gmv "$FLUTTER_DIR/lib/engine/bdui_engine"        "$FLUTTER_DIR/lib/engine/canvas"
  gmv "$FLUTTER_DIR/lib/engine/component_registry" "$FLUTTER_DIR/lib/engine/canvas_registry"
  gmv "$FLUTTER_DIR/lib/engine/rule_evaluator"     "$FLUTTER_DIR/lib/engine/canvas_rule"
  gmv "$FLUTTER_DIR/lib/engine/layout_resolver"    "$FLUTTER_DIR/lib/engine/canvas_layout"

  # 2) File renames inside the new directories
  if [[ "$DRY_RUN" -eq 0 ]]; then
    [[ -f "$FLUTTER_DIR/lib/engine/canvas/bdui_engine.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas/bdui_engine.dart" \
             "$FLUTTER_DIR/lib/engine/canvas/scalario_canvas.dart"
    [[ -f "$FLUTTER_DIR/lib/engine/canvas/bdui_engine_config.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas/bdui_engine_config.dart" \
             "$FLUTTER_DIR/lib/engine/canvas/scalario_canvas_config.dart"
    [[ -f "$FLUTTER_DIR/lib/engine/canvas/bdui_engine_module.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas/bdui_engine_module.dart" \
             "$FLUTTER_DIR/lib/engine/canvas/scalario_canvas_module.dart"
    [[ -f "$FLUTTER_DIR/lib/engine/canvas_registry/component_registry.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas_registry/component_registry.dart" \
             "$FLUTTER_DIR/lib/engine/canvas_registry/scalario_canvas_registry.dart"
    [[ -f "$FLUTTER_DIR/lib/engine/canvas_rule/rule_evaluator.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas_rule/rule_evaluator.dart" \
             "$FLUTTER_DIR/lib/engine/canvas_rule/scalario_canvas_rule.dart"
    [[ -f "$FLUTTER_DIR/lib/engine/canvas_layout/layout_resolver.dart" ]] && \
      git mv "$FLUTTER_DIR/lib/engine/canvas_layout/layout_resolver.dart" \
             "$FLUTTER_DIR/lib/engine/canvas_layout/scalario_canvas_layout.dart"
  else
    echo "  [DRY-RUN] git mv bdui_engine.dart → scalario_canvas.dart (et 5 autres fichiers)"
  fi

  # 3) Update imports (path-based — couvre tous les chemins, absolus 'package:…' comme
  #    relatifs '../X/' '../../engine/X/' 'engine/X/'). Le trailing slash garantit qu'on
  #    matche un segment de path et pas un identifiant.
  sed_inplace "s|bdui_engine/|canvas/|g"
  sed_inplace "s|component_registry/|canvas_registry/|g"
  sed_inplace "s|rule_evaluator/|canvas_rule/|g"
  sed_inplace "s|layout_resolver/|canvas_layout/|g"

  # 4) Update imports (file-based — couvre les imports `'../path/file.dart'` (avec slash)
  #    et les imports `'file.dart'` (co-localisés, sans slash). Le .dart final garantit
  #    qu'on cible des chemins de fichiers, pas des identifiants.
  sed_inplace "s|bdui_engine\.dart|scalario_canvas.dart|g"
  sed_inplace "s|bdui_engine_config\.dart|scalario_canvas_config.dart|g"
  sed_inplace "s|bdui_engine_module\.dart|scalario_canvas_module.dart|g"
  sed_inplace "s|component_registry\.dart|scalario_canvas_registry.dart|g"
  sed_inplace "s|rule_evaluator\.dart|scalario_canvas_rule.dart|g"
  sed_inplace "s|layout_resolver\.dart|scalario_canvas_layout.dart|g"

  # 5) Class renames (word-boundary safe)
  sed_inplace "s/\\bBDUIEngine\\b/ScalarioCanvas/g"
  sed_inplace "s/\\bBDUIEngineConfig\\b/ScalarioCanvasConfig/g"
  sed_inplace "s/\\bBDUIEngineModule\\b/ScalarioCanvasModule/g"
  sed_inplace "s/\\bComponentRegistry\\b/ScalarioCanvasRegistry/g"
  sed_inplace "s/\\bRuleEvaluator\\b/ScalarioCanvasRule/g"
  sed_inplace "s/\\bLayoutResolver\\b/ScalarioCanvasLayout/g"

  # 6) Validate
  if ! validate_flutter; then
    rollback_batch "canvas"
  fi

  # 7) Commit
  commit_batch "canvas"
  ok "Batch canvas terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : vault (Flutter offline/dao → vault/dao)
#
# Avant (v13)                                  → Après (v14)
#   apps/flutter/lib/core/offline/dao/         → apps/flutter/lib/core/vault/dao/
#   apps/flutter/lib/core/offline/tables/      → apps/flutter/lib/core/vault/tables/
#   apps/flutter/lib/core/offline/migrations/  → apps/flutter/lib/core/vault/migrations/
# ─────────────────────────────────────────────────────────────────────────────

batch_vault() {
  log "▶ Batch: vault (Flutter offline → vault data layer)"

  gmv "$FLUTTER_DIR/lib/core/offline/dao"        "$FLUTTER_DIR/lib/core/vault/dao"
  gmv "$FLUTTER_DIR/lib/core/offline/tables"     "$FLUTTER_DIR/lib/core/vault/tables"
  gmv "$FLUTTER_DIR/lib/core/offline/migrations" "$FLUTTER_DIR/lib/core/vault/migrations"

  sed_inplace "s|core/offline/dao/|core/vault/dao/|g"
  sed_inplace "s|core/offline/tables/|core/vault/tables/|g"
  sed_inplace "s|core/offline/migrations/|core/vault/migrations/|g"

  if ! validate_flutter; then
    rollback_batch "vault"
  fi

  commit_batch "vault"
  ok "Batch vault terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : sync (Flutter offline/sync → sync + worker class)
#
#   apps/flutter/lib/core/offline/sync/ → apps/flutter/lib/core/sync/
#   SyncQueueWorker                     → ScalarioSyncWorker
#   ConflictResolver                    → ScalarioSyncConflictResolver
# ─────────────────────────────────────────────────────────────────────────────

batch_sync() {
  log "▶ Batch: sync (Flutter offline/sync → sync)"

  gmv "$FLUTTER_DIR/lib/core/offline/sync" "$FLUTTER_DIR/lib/core/sync"

  sed_inplace "s|core/offline/sync/|core/sync/|g"
  sed_inplace "s/\\bSyncQueueWorker\\b/ScalarioSyncWorker/g"
  sed_inplace "s/\\bConflictResolver\\b/ScalarioSyncConflictResolver/g"

  if ! validate_flutter; then
    rollback_batch "sync"
  fi

  commit_batch "sync"
  ok "Batch sync terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : flow (NestJS module-engine + workflow → engines/)
#
#   apps/nestjs/src/module-engine/ → apps/nestjs/src/engines/action/
#   apps/nestjs/src/workflow/      → apps/nestjs/src/engines/workflow/
# ─────────────────────────────────────────────────────────────────────────────

batch_flow() {
  log "▶ Batch: flow (NestJS module-engine + workflow → engines/)"

  gmv "$NESTJS_DIR/src/module-engine" "$NESTJS_DIR/src/engines/action"
  gmv "$NESTJS_DIR/src/workflow"      "$NESTJS_DIR/src/engines/workflow"

  sed_inplace "s|src/module-engine/|src/engines/action/|g"
  sed_inplace "s|src/workflow/|src/engines/workflow/|g"
  sed_inplace "s|/module-engine/|/engines/action/|g"
  sed_inplace "s|/workflow/|/engines/workflow/|g"
  # imports relatifs (./module-engine/... ou ../module-engine/...)
  sed_inplace "s|(\\.\\.?)/module-engine/|\\1/engines/action/|g"
  sed_inplace "s|(\\.\\.?)/workflow/|\\1/engines/workflow/|g"

  if ! validate_nestjs; then
    rollback_batch "flow"
  fi

  commit_batch "flow"
  ok "Batch flow terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : shield (NestJS security → core/security)
# ─────────────────────────────────────────────────────────────────────────────

batch_shield() {
  log "▶ Batch: shield (NestJS security → core/security)"

  gmv "$NESTJS_DIR/src/security" "$NESTJS_DIR/src/core/security"

  sed_inplace "s|src/security/|src/core/security/|g"
  sed_inplace "s|(\\.\\.?)/security/|\\1/core/security/|g"

  if ! validate_nestjs; then
    rollback_batch "shield"
  fi

  commit_batch "shield"
  ok "Batch shield terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Batch : watch (NestJS audit → core/audit + cache + auth → core/)
# ─────────────────────────────────────────────────────────────────────────────

batch_watch() {
  log "▶ Batch: watch (NestJS audit/cache/auth → core/)"

  gmv "$NESTJS_DIR/src/audit" "$NESTJS_DIR/src/core/audit"
  gmv "$NESTJS_DIR/src/cache" "$NESTJS_DIR/src/core/cache"
  gmv "$NESTJS_DIR/src/auth"  "$NESTJS_DIR/src/core/auth"

  sed_inplace "s|src/audit/|src/core/audit/|g"
  sed_inplace "s|src/cache/|src/core/cache/|g"
  sed_inplace "s|src/auth/|src/core/auth/|g"
  sed_inplace "s|(\\.\\.?)/audit/|\\1/core/audit/|g"
  sed_inplace "s|(\\.\\.?)/cache/|\\1/core/cache/|g"
  sed_inplace "s|(\\.\\.?)/auth/|\\1/core/auth/|g"

  if ! validate_nestjs; then
    rollback_batch "watch"
  fi

  commit_batch "watch"
  ok "Batch watch terminé."
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatcher
# ─────────────────────────────────────────────────────────────────────────────

run_batch() {
  case "$1" in
    canvas) batch_canvas ;;
    vault)  batch_vault ;;
    sync)   batch_sync ;;
    flow)   batch_flow ;;
    shield) batch_shield ;;
    watch)  batch_watch ;;
    all)
      batch_canvas
      batch_vault
      batch_sync
      batch_flow
      batch_shield
      batch_watch
      ;;
    *) fail "Batch inconnu: '$1' (valides: canvas, vault, sync, flow, shield, watch, all)" ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
  cat <<EOF
Usage:
  $0 --dry-run                      # liste les opérations, ne modifie rien
  $0 --dry-run <batch>              # dry-run d'un batch spécifique
  $0 --apply <batch>                # applique un batch (canvas|vault|sync|flow|shield|watch)
  $0 --apply all                    # applique tous les batches

Batches disponibles :
  canvas  — Flutter engine (BDUI → Canvas)
  vault   — Flutter core/offline/{dao,tables,migrations} → core/vault/
  sync    — Flutter core/offline/sync → core/sync (+ SyncQueueWorker → ScalarioSyncWorker)
  flow    — NestJS module-engine + workflow → engines/action + engines/workflow
  shield  — NestJS security → core/security
  watch   — NestJS audit + cache + auth → core/audit + core/cache + core/auth

Cf STORY-V14-001 + _bmad-output/architecture-v14/migration-log.md
EOF
  exit 0
fi

case "$1" in
  --dry-run)
    DRY_RUN=1
    TARGET_BATCH="${2:-all}"
    ;;
  --apply)
    DRY_RUN=0
    TARGET_BATCH="${2:-}"
    [[ -z "$TARGET_BATCH" ]] && fail "Précise quel batch appliquer (canvas|vault|sync|flow|shield|watch|all)"
    ensure_clean_worktree
    ;;
  *)
    fail "Argument inconnu: '$1' (utilise --dry-run ou --apply)"
    ;;
esac

run_batch "$TARGET_BATCH"
ok "Migration terminée pour batch '$TARGET_BATCH'."
