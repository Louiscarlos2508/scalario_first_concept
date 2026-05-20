#!/usr/bin/env bash
set -euo pipefail

DOMAIN_ID="${1:-}"

if [[ -z "$DOMAIN_ID" ]]; then
  echo "Usage: $0 <domain_id>"
  echo "  domain_id doit matcher: ^[a-z][a-z0-9_]*$"
  exit 1
fi

if ! [[ "$DOMAIN_ID" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "❌ domain_id invalide. Doit matcher ^[a-z][a-z0-9_]*$"
  exit 1
fi

TARGET="catalog/domains/${DOMAIN_ID}.json"
if [[ -f "$TARGET" ]]; then
  echo "❌ ${TARGET} existe déjà — supprimez-le manuellement si voulu."
  exit 1
fi

cat > "$TARGET" <<EOF
{
  "id": "${DOMAIN_ID}",
  "schema_version": "1.0.0",
  "name": "À renseigner",
  "i18n_key": "domain.${DOMAIN_ID}",
  "icon": "package",
  "entities": [],
  "actions": {},
  "rbac_roles": ["OWNER"],
  "abac_rules": [],
  "conflict_strategy": "server_wins"
}
EOF

echo "✅ Créé : ${TARGET}"
echo ""
echo "Prochaines étapes :"
echo "  1. Éditer ${TARGET} — voir catalog/README.md §3"
echo "  2. pnpm validate-catalogue"
echo "  3. git checkout -b feat/catalog/${DOMAIN_ID}"
echo "  4. git commit + PR"
