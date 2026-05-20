# Scalario

**Instant Business OS** — BDUI Engine + Templates JSON. Lance un ERP/CRM/Catalogue complet en moins d'une heure pour un commerce africain via configuration JSON, sans regénération native.

Monorepo : Flutter (apps/flutter), NestJS (apps/nestjs), FastAPI Phase 2 (services/fastapi), PostgreSQL + pgvector, Redis, MinIO.

---

## Catalogue (intégrateurs)

Vous êtes partenaire intégrateur Scalario ? Vous voulez ajouter un secteur d'activité (pharmacie, BTP, transport) ? **Vous n'avez pas besoin de coder** — juste de créer un fichier JSON.

👉 Lisez [`catalog/README.md`](./catalog/README.md) — c'est votre point d'entrée. En 5 étapes et moins de 60 jours, vous livrez un template sectoriel complet, sans toucher au code Flutter ni NestJS.

> Ajouter un secteur = du JSON, pas du code.

---

## Quickstart en 3 commandes

```bash
git clone https://github.com/scalario/scalario.git && cd scalario
cp .env.example .env && pnpm install
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Puis :

- NestJS API : http://localhost:3000/health
- FastAPI stub : http://localhost:8000/health
- Adminer (dev DB UI) : http://localhost:8080 (Server `postgres`, User/Password depuis `.env`)
- MinIO (S3 stub) : http://localhost:9000

Prérequis : Node 20+, pnpm 9+, Docker + Docker Compose v2.

---

## Structure

```
scalario/
├── apps/
│   ├── flutter/         # Flutter app (BDUI runtime)
│   └── nestjs/          # NestJS backend (API + BDUI server)
├── services/
│   └── fastapi/         # FastAPI Phase 2 stub (IA/RAG)
├── packages/
│   ├── bdui-schema/     # JSON Schema BDUI (placeholder)
│   └── bdui-types/      # TypeScript types BDUI (placeholder)
├── catalog/             # Templates verticaux JSON
│   ├── domains/
│   ├── modules/
│   ├── fusions/
│   └── schemas/
├── docker-compose.yml
├── docker-compose.dev.yml
└── pnpm-workspace.yaml
```

---

## Scripts racine

| Script | Description |
|---|---|
| `pnpm dev` | Démarre NestJS en hot-reload |
| `pnpm build` | Build de tous les packages |
| `pnpm lint` | ESLint sur tous les packages |
| `pnpm test` | Jest sur tous les packages |
| `pnpm typecheck` | TypeScript en mode `noEmit` |
| `pnpm docker:up` | Démarre la stack Docker (dev) |
| `pnpm docker:down` | Stoppe la stack Docker |

---

## Troubleshooting

**Port 5432 déjà occupé (PostgreSQL natif local)** : commenter `ports:` sur `postgres` dans `docker-compose.yml` (le service reste accessible aux autres containers via le réseau Docker), ou re-mapper `"5433:5432"` et adapter `DATABASE_URL` côté client externe.

**Port 3000 occupé** : changer `PORT` dans `.env` et le mapping `ports:` du service `nestjs`.

**`.env` manquant** : `cp .env.example .env` puis renseigner au minimum `JWT_SECRET`, `JWT_REFRESH_SECRET` (32 chars min), `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `MINIO_ROOT_PASSWORD`.

**Health check NestJS échoue** : vérifier que postgres et redis sont `healthy` (`docker compose ps`), puis `docker compose logs nestjs`.

---

## Architecture

Voir `_bmad-output/architecture-scalario-2026-05-09.md` (architecture complète) et `_bmad-output/sprint-plan-scalario-2026-05-09.md` (sprint plan).
