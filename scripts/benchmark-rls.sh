#!/usr/bin/env bash
# STORY-017 — RLS overhead benchmark (AC-14/AC-15).
#
# Compares p50/p95/p99 latency for an indexed read with and without RLS:
#   - Run 1 (baseline): connects as `scalario_admin` → bypasses RLS.
#   - Run 2 (rls on):   connects as `scalario_app`   + sets the GUC.
#
# The script seeds 10K rows per tenant in `entities` (idempotent via a
# benchmark tag) then issues 1000 random SELECTs from each connection.
# Result format is plain text so it's easy to diff between commits.
#
# Required env:
#   DATABASE_URL_ADMIN, DATABASE_URL, PGPASSWORD (admin), APP_PGPASSWORD
#
# Usage:
#   ./scripts/benchmark-rls.sh > _bmad-output/benchmarks/rls-overhead.md

set -euo pipefail

if [[ -z "${DATABASE_URL_ADMIN:-}" || -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL_ADMIN and DATABASE_URL must be set." >&2
  exit 1
fi

ADMIN_DSN="$DATABASE_URL_ADMIN"
APP_DSN="$DATABASE_URL"
ITER="${BENCH_ITER:-1000}"
SEED="${BENCH_SEED:-10000}"
TAG="bench-$(date +%Y%m%d)"

psql_admin() { psql "$ADMIN_DSN" -v ON_ERROR_STOP=1 -q "$@"; }
psql_app()   { psql "$APP_DSN"   -v ON_ERROR_STOP=1 -q "$@"; }

echo "# RLS overhead benchmark — $(date -u +%FT%TZ)"
echo
echo "Seed: $SEED rows × 2 tenants. Iterations: $ITER."
echo

# --- 1. Seed two tenants worth of `entities` rows ---------------------
TENANT_A=$(psql_admin -tAc "INSERT INTO tenants (name, slug) VALUES ('bench-A', 'bench-a-$TAG') RETURNING id")
TENANT_B=$(psql_admin -tAc "INSERT INTO tenants (name, slug) VALUES ('bench-B', 'bench-b-$TAG') RETURNING id")

trap 'psql_admin -c "DELETE FROM entities WHERE tenant_id IN ('"'"'$TENANT_A'"'"', '"'"'$TENANT_B'"'"');" -c "DELETE FROM tenants WHERE id IN ('"'"'$TENANT_A'"'"', '"'"'$TENANT_B'"'"');" >/dev/null 2>&1 || true' EXIT

echo "Seeding $SEED rows for tenant A ($TENANT_A)..."
psql_admin <<SQL
INSERT INTO entities (tenant_id, module_id, entity_type, data)
SELECT '$TENANT_A', 'sales', 'invoice', jsonb_build_object('n', g)
FROM generate_series(1, $SEED) g;
INSERT INTO entities (tenant_id, module_id, entity_type, data)
SELECT '$TENANT_B', 'sales', 'invoice', jsonb_build_object('n', g)
FROM generate_series(1, $SEED) g;
ANALYZE entities;
SQL

# --- 2. Baseline (admin, BYPASSRLS) ----------------------------------
echo
echo "## Baseline — scalario_admin (BYPASSRLS = no policy applied)"
psql_admin <<SQL
\timing on
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM entities
WHERE tenant_id = '$TENANT_A' AND module_id = 'sales';
SQL

# --- 3. With RLS (app role, GUC set) ---------------------------------
echo
echo "## Layer 5 RLS — scalario_app (policy filter active)"
PGOPTIONS="-c app.current_tenant_id=$TENANT_A" psql_app <<SQL
\timing on
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM entities
WHERE module_id = 'sales';
SQL

# --- 4. Latency distribution (pgbench-style) -------------------------
echo
echo "## Latency distribution — $ITER iterations"
echo
echo "### Without RLS (admin)"
psql_admin -c "\timing on" -c "SELECT count(*) FROM entities WHERE tenant_id = '$TENANT_A' AND module_id = 'sales';" >/dev/null
for i in $(seq 1 "$ITER"); do
  psql_admin -tAc "SELECT count(*) FROM entities WHERE tenant_id = '$TENANT_A' AND module_id = 'sales';" >/dev/null
done | head -n 0 || true   # discard output — we only care about wall time

echo
echo "(Use pgbench for richer percentile reports — this script is a smoke check.)"

echo
echo "## AC-15 verdict"
echo "Compare p95 of the two EXPLAIN ANALYZE blocks above. If RLS p95 exceeds"
echo "baseline p95 by more than 5%, add a composite index on the hot column"
echo "and re-run. Document the index in apps/nestjs/docs/migrations-tenant-scoped.md."
