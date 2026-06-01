# Scalario

![CI](https://github.com/your-org/scalario/actions/workflows/ci.yml/badge.svg)

**Instant Business OS** — BDUI Engine + Templates JSON. Lance un ERP/CRM/Catalogue complet en moins d'une heure pour un commerce africain via configuration JSON, sans regénération native.

Monorepo : Flutter (apps/flutter), NestJS (apps/nestjs), PostgreSQL + pgvector, Redis.

---

## Quickstart

```bash
git clone https://github.com/scalario/scalario.git && cd scalario
cp apps/nestjs/.env.example apps/nestjs/.env
pnpm install
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
cd apps/nestjs && npx tsc -p tsconfig.json --outDir dist && node dist/main.js
```

### Seed tenant Blandine

```bash
cd apps/nestjs
docker exec scalario-postgres psql -U scalario_admin -d scalario -c "
INSERT INTO tenants (name, slug, is_active, config)
VALUES ('Blandine Épicerie Fine', 'blandine', true, '{\"roles\":[\"OWNER\",\"MANAGER\",\"COMMERCIAL\"]}');
"
HASH=$(node -e "const bcrypt = require('bcrypt'); bcrypt.hash('owner123', 12).then(h => console.log(h))")
docker exec scalario-postgres psql -U scalario_admin -d scalario -c "
INSERT INTO users (tenant_id, email, password_hash, roles, is_active)
SELECT id, 'owner@blandine.bf', '$HASH', '[\"OWNER\"]', true FROM tenants WHERE slug = 'blandine';
INSERT INTO users (tenant_id, email, password_hash, roles, is_active)
SELECT id, 'commercial@blandine.bf', '$HASH', '[\"COMMERCIAL\"]', true FROM tenants WHERE slug = 'blandine';
"
```

Login: `owner@blandine.bf` / `owner123` | `commercial@blandine.bf` / `commercial123`

Prérequis : Node 20+, pnpm 9+, Docker + Docker Compose v2.

---

## Architecture v14 — BDUI Zones

```
scalario/
├── apps/
│   ├── flutter/              # BDUI runtime (web/desktop)
│   │   ├── lib/sandbox/      # Sandbox dev — 19 fixtures BDUI
│   │   └── assets/sandbox/   # Fixtures JSON (8 Blandine + 11 modules)
│   └── nestjs/               # NestJS API (port 3000)
│       ├── migrations/       # 11 migrations TypeORM
│       └── seed/             # Seed scripts
├── catalog/                  # Catalogue — source de vérité métier
│   ├── modules/              # 8 modules (ventes, stock, pertes…)
│   │   └── */screens/        # Écrans BDUI par module
│   ├── tenants/              # Screens spécifiques par tenant
│   │   └── blandine/screens/ # 8 écrans Blandine (zones format)
│   └── domains/              # Legacy v13 — backward compat tests
├── docker-compose.yml
└── docker-compose.dev.yml
```

### BDUI Zones Format

Chaque écran est un JSON qui décrit sa structure via `layout` + `zones` :

```json
{
  "screen": "dashboard_owner",
  "schema_version": "1.0.0",
  "layout": "dashboard",
  "zones": {
    "kpis": [{ "type": "KPICard", "props": { "label": "CA du jour", "value": "342 500" } }],
    "main": [{ "type": "DataTable", "props": { "columns": [...], "rows": [...] } }],
    "aside": [{ "type": "ChartBar", "props": { ... } }],
    "actions": [{ "type": "ActionButton", "props": { "label": "Nouvelle vente" } }]
  }
}
```

Pas de champ `root` — le Flutter canvas ignore `root` et ne lit que `zones`.

---

## Catalogue — Modules disponibles (8)

| Module | ID | Entités | Écrans |
|--------|----|---------|--------|
| Ventes | `ventes` | Sale, SaleItem | pos, sale_list |
| Stock | `stock` | Product, StockMovement | stock_list, product_history, inventory_count, delivery_form |
| Pertes | `pertes` | Loss | loss_form, loss_list |
| Caisse | `caisse` | CashSession | sessions |
| Commandes | `commandes` | Supplier, PurchaseOrder | — |
| Équipe | `equipe` | Employee | — |
| Rapports | `rapports` | — | daily_report |
| Alertes | `alertes` | AlertRule | alert_detail |

---

## Tests

```bash
# NestJS — 753 tests, 30s
cd apps/nestjs && pnpm test

# Flutter analyze
cd apps/flutter && flutter analyze
```

---

## Sandbox Flutter — Tester les écrans sans backend

```bash
cd apps/flutter && flutter run -d web-server --web-port 8082 -t lib/main_web.dart
```

Ouvre http://localhost:8082 — dropdown pour sélectionner parmi 19 fixtures BDUI, changement de rôle (OWNER/MANAGER/COMMERCIAL), breakpoints responsive.

---

## API — Login + Layout

```bash
# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@blandine.bf","password":"owner123","tenant_slug":"blandine"}'

# Récupérer un écran BDUI (authentifié)
TOKEN="<access_token>"
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/api/v1/blandine/layout/dashboard_owner"
```

---

## CI/CD

`.github/workflows/ci.yml` — push/PR sur `main` :
1. **NestJS** : PostgreSQL + Redis services → `pnpm test` (753 tests)
2. **Flutter** : `flutter analyze` (dépend du job NestJS)

---

## Troubleshooting

**Port 5432 occupé** : re-mapper `"5433:5432"` dans `docker-compose.yml` et adapter `DATABASE_URL`.

**`.env`** : `cp apps/nestjs/.env.example apps/nestjs/.env` — renseigner `JWT_SECRET` (32 chars), `SCALARIO_APP_DB_PASSWORD` (12 chars).

**Flutter web splash bloqué** : attendre 8s (fallback auto-hide) ou rafraîchir la page.

**753 tests → 1 fail** : vérifier que `ScreenConfigZod` accepte `schema_version` optionnel sur les composants.

---
