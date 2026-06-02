# Scalario

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

## Architecture — BDUI v2

```
scalario/
├── apps/
│   ├── flutter/                # BDUI runtime (web/desktop)
│   │   ├── lib/sandbox/        # Sandbox dev — fixtures BDUI
│   │   └── assets/             # Images, icons, fixtures JSON
│   └── nestjs/                 # NestJS API (port 3000)
│       ├── migrations/
│       └── seed/
├── catalog/                    # Catalogue — source de vérité métier
│   └── tenants/
│       └── blandine/
│           ├── module.json     # Modules activés + mapping écran→module
│           ├── navigation.json # Sidebar (groupes, icônes, rôles)
│           ├── rbac.json       # Rôles, permissions, accès écrans + actions
│           ├── theme.json      # Couleurs, typo, devise, locale
│           ├── dialogs/        # Modaux (validation, confirmation…)
│           │   └── {dialogId}/dialog.json + zones/main.json
│           ├── sheets/         # Panneaux latéraux (client_select, product_picker…)
│           │   └── {sheetId}/sheet.json + zones/main.json
│           └── screens/        # 17 écrans BDUI
│               └── {screenId}/
│                   ├── screen.json       # Manifest (layout, zones, $ref)
│                   ├── appbar.json       # Titre, bouton retour, actions
│                   ├── layout/layout.json
│                   ├── rules/rules.json  # RBAC par rôle
│                   ├── data/sources.json # Endpoints API + fixtures
│                   ├── ux/metadata.json  # Layout hints
│                   ├── components/
│                   ├── zones/
│                   ├── capabilities/
│                   ├── states/
│                   └── i18n/
├── docker-compose.yml
└── docker-compose.dev.yml
```

### Structure d'un écran (BDUI v2)

Chaque écran est un dossier avec `screen.json` qui référence ses sous-fichiers via `$ref` :

```json
{
  "screen": "dashboard_owner",
  "schema_version": "2.0.0",
  "layout": { "$ref": "layout/layout.json" },
  "appbar": { "$ref": "appbar.json" },
  "zones": {
    "kpis": [{ "type": "KPICard", "props": { "label": "CA du jour", "value": "342 500" } }],
    "main": [{ "type": "DataTable", "props": { "columns": [...], "rows": [...] } }],
    "aside": [{ "type": "ChartBar", "props": { ... } }],
    "actions": [{ "type": "ActionButton", "props": { "label": "Nouvelle vente" } }]
  },
  "rules": { "$ref": "rules/rules.json" }
}
```

Le `CatalogueLoaderService` résout les `$ref` récursivement.

---

## API

### Authentification

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@blandine.bf","password":"owner123","tenant_slug":"blandine"}'
```

### Navigation (filtrée par rôle JWT)

```bash
TOKEN="<access_token>"
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/navigation
```

Retourne `sidebar.groups[]` avec `label`, `icon`, `screens[].label` — filtré par le rôle de l'utilisateur.

### Layout d'un écran

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/layout/dashboard_owner
```

Retourne le `screen.json` assemblé avec tous les `$ref` résolus, incluant `appbar`, `layout`, `zones`, `rules`.

### Catalogue

```bash
# Thème (couleurs, typo, devise, locale)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/catalogue/theme

# RBAC (rôles, permissions, accès)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/catalogue/rbac

# Dialog
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/catalogue/dialogs/validation_closure

# Sheet
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/blandine/catalogue/sheets/product_picker
```

### Modules (actions + data)

```bash
# Données d'un module
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/blandine/caisse/data?entity=Caisse&page=1&limit=50"

# Action / Workflow
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -H "x-client-mutation-id: uuid" \
  -d '{"action_type":"start_workflow","workflow_id":"workflow_cloture_caisse","entity_id":"..."}' \
  http://localhost:3000/api/v1/blandine/caisse/action
```

---

## Écrans Blandine (17)

| Module | Écrans | Rôles |
|--------|--------|-------|
| Tableau de bord | Accueil (owner), Ma journée (commercial), Opérations (manager) | OWNER / COMMERCIAL / MANAGER |
| Ventes | Point de vente, Retour/Annulation, Vente à crédit | COMMERCIAL, MANAGER |
| Stock | Historique, Inventaire, Réception livraison | OWNER, MANAGER |
| Commandes | Commande fournisseur | OWNER |
| Pertes | Déclaration de perte | MANAGER, COMMERCIAL |
| Rapports | Vue d'ensemble | OWNER |
| Caisse | Ouverture, Clôture | COMMERCIAL / OWNER |
| Configuration | Catalogue produits, Fournisseurs | OWNER |
| Équipe | Gestion équipe | OWNER |

---

## Tests

```bash
# NestJS — 569 tests, 30s
cd apps/nestjs && pnpm test

# Flutter analyze
cd apps/flutter && flutter analyze
```

---

## Sandbox Flutter

```bash
cd apps/flutter && flutter build web --no-tree-shake-icons \
  -t lib/main_web.dart --release --dart-define=APP_MODE=sandbox
cd build/web && python3 -m http.server 8085
```

Sandbox (APP_MODE=sandbox) : dropdown de fixtures, changement de rôle, breakpoints.

Production (APP_MODE=app) : login → sidebar dynamique → rendu BDUI.

---

## CI/CD

`.github/workflows/ci.yml` — push/PR sur `main` :
1. **NestJS** : PostgreSQL + Redis services → `pnpm test` (569 tests)
2. **Flutter** : `flutter analyze`

---

## Troubleshooting

**Port 5432 occupé** : re-mapper `"5433:5432"` dans `docker-compose.yml` et adapter `DATABASE_URL`.

**`.env`** : `cp apps/nestjs/.env.example apps/nestjs/.env` — renseigner `JWT_SECRET` (32 chars), `SCALARIO_APP_DB_PASSWORD` (12 chars).

**Flutter web : ne pas utiliser `flutter run -d web-server`** (DDC hang). Build + Python HTTP server : `flutter build web --release && cd build/web && python3 -m http.server 8085`.

**CanvasKit + SwiftShader (Playwright)** : `MakeGrContext()` échoue sans GPU hardware. Ouvrir dans un vrai navigateur.
