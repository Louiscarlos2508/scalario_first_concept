#!/usr/bin/env bash
# Sync JSON Schema files from catalog/schemas/ to Flutter assets/bdui-schemas/
# Usage: bash scripts/sync-schemas-to-flutter.sh
# 
# Options:
#   --dry-run    Print what would be copied without copying
#   --check      Exit with code 1 if schemas are out of sync (for CI)
#
# Part of STORY-026 Validation Bidirectionnelle JSON Runtime.
# Le contrat est partagé — Zod (NestJS) ET json_schema (Flutter) dérivent
# des mêmes fichiers *.schema.json. Si vous voyez une divergence, c'est un bug.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="$PROJECT_ROOT/catalog/schemas"
TARGET_DIR="$PROJECT_ROOT/apps/flutter/assets/bdui-schemas"
SCHEMA_PATTERN="*.schema.json"
README_SOURCE="$SOURCE_DIR/README.md"
README_TARGET="$TARGET_DIR/README.md"

mkdir -p "$TARGET_DIR"

dry_run=false
check_mode=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --check) check_mode=true ;;
  esac
done

if $dry_run; then
  echo "[DRY-RUN] Would copy $SCHEMA_PATTERN from $SOURCE_DIR to $TARGET_DIR"
  for f in "$SOURCE_DIR"/$SCHEMA_PATTERN; do
    base="$(basename "$f")"
    echo "  → cp $f $TARGET_DIR/$base"
  done
  if [ -f "$README_SOURCE" ]; then
    echo "  → cp $README_SOURCE $README_TARGET"
  fi
  exit 0
fi

if $check_mode; then
  any_diff=false
  for f in "$SOURCE_DIR"/$SCHEMA_PATTERN; do
    base="$(basename "$f")"
    if [ ! -f "$TARGET_DIR/$base" ]; then
      echo "[CHECK] MISSING: $TARGET_DIR/$base"
      any_diff=true
    elif ! diff -q "$f" "$TARGET_DIR/$base" > /dev/null 2>&1; then
      echo "[CHECK] DIFFERS: $base"
      any_diff=true
    fi
  done
  if $any_diff; then
    echo "[CHECK] Schemas are out of sync."
    exit 1
  fi
  echo "[CHECK] All schemas are in sync."
  exit 0
fi

echo "Syncing $SCHEMA_PATTERN from $SOURCE_DIR → $TARGET_DIR"
cp "$SOURCE_DIR"/$SCHEMA_PATTERN "$TARGET_DIR/"
if [ -f "$README_SOURCE" ]; then
  cp "$README_SOURCE" "$TARGET_DIR/"
fi
echo "Done. $(ls "$TARGET_DIR"/*.schema.json 2>/dev/null | wc -l) schema(s) synced."
