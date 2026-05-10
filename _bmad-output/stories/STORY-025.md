# STORY-025 : Structure Catalogue + README Intégrateur

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 2
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-013 (monorepo structure), STORY-024 (Zod validator + CI workflow)

---

## User Story

> **En tant qu'** intégrateur certifié Scalario (un partenaire qui touche 60 % du MRR du tenant qu'il gère),
> **je veux** une structure catalogue claire, documentée à la racine du repo, et un README qui me guide pas-à-pas pour créer un nouveau template sectoriel,
> **so that** je puisse livrer un nouveau secteur en moins de 60 jours **sans toucher au code des apps**, en pull-requesting un dossier `catalog/`.

---

## Description

### Background — Le catalogue **est** le produit

Le modèle économique Scalario repose sur un partenariat 60/40 avec des intégrateurs certifiés (40 % MRR pour Scalario, 60 % pour l'intégrateur — réf. décisions stratégiques 2026-05-09). Ces intégrateurs sont des indépendants ou agences en UEMOA qui :

- Connaissent leur secteur (retail fresh produce, pharmacie de quartier, BTP, transport).
- **Ne sont pas des développeurs Flutter ni NestJS.**
- Doivent pouvoir livrer un template fonctionnel en un sprint (10-15 jours).

Si l'expérience d'onboarding intégrateur c'est "lis 6000 lignes d'archi puis fork le repo", le modèle ne décolle pas. Cette story est **la porte d'entrée** du catalogue — la qualité du README et de la structure détermine si un intégrateur livre en 10 jours ou abandonne en 3.

Le catalogue est aussi le **seul artefact que l'intégrateur produit**. Pas de code, pas de DB migration, pas de redéploiement. Une PR sur le dossier `catalog/`. CI verte → le module fonctionne.

### Scope

**In scope :**

- Création du dossier `catalog/` à la **racine du monorepo** (pas dans `apps/`, pas dans `backend/`).
- Sous-dossiers : `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`, `catalog/schemas/` (ce dernier vient de STORY-023 — on ne le re-crée pas, on le référence).
- Fichier placeholder `catalog/domains/retail_fresh_produce.json` — squelette minimal valide (implémentation pleine = STORY-039).
- `catalog/README.md` — **document central** : "Comment créer un nouveau template sectoriel" en français, lisible par un intégrateur non-dev.
- `catalog/CONTRIBUTING.md` — règles de PR : nommage, validation locale, processus de review.
- Configuration Docker : volume `catalog/` monté dans le container NestJS (modification de `docker-compose.yml`) — pas de copie dans l'image, hot-reload activé.
- Référence dans le `README.md` racine du monorepo : section "Catalogue — point d'entrée intégrateurs" avec lien.
- Sample CLI `scripts/scaffold-domain.sh` (ou `.ts`) — un script `scalario scaffold domain ma_pharmacie` qui crée la structure de base.
- Lien vers la doc HTML BDUI (générée par STORY-023) pour les schémas.

**Out of scope (autres stories) :**

- L'implémentation effective du template `retail_fresh_produce.json` complet (90 % du contenu réel) → STORY-039.
- Le validator Zod et le workflow CI `validate-catalogue.yml` → STORY-024 (cette story le **référence** dans le README et le `CONTRIBUTING.md`).
- Le CMS web pour intégrateurs (UI de création visuelle) → Phase 2 / Phase 3.
- Le marketplace de templates → Phase 3 (FR-044).

### User Flow (intégrateur)

1. Intégrateur (ex: une agence à Abidjan spécialisée pharmacie) reçoit l'accès Git au repo Scalario.
2. Il clone, ouvre `catalog/README.md`.
3. Lit la "Checklist en 5 étapes pour créer un domaine".
4. Étape 1 : `bash scripts/scaffold-domain.sh pharmacie_quartier` → crée `catalog/domains/pharmacie_quartier.json` à partir d'un template de base.
5. Étape 2 : il édite le JSON (nom, modules actifs, screens, RBAC roles).
6. Étape 3 : valide localement `bun run validate-catalogue` → erreurs lisibles s'il y en a.
7. Étape 4 : commit + PR sur GitHub.
8. Étape 5 : CI valide automatiquement, review Scalario team, merge.
9. Au prochain redéploiement (ou hot-reload via volume monté), le tenant pharmacie peut être provisionné avec ce domaine.

---

## Acceptance Criteria

### Structure catalogue

- [ ] AC-01 — `catalog/` existe à la **racine du monorepo** — vérifiable par `ls catalog/` depuis la racine.
- [ ] AC-02 — Sous-dossiers présents : `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`, `catalog/schemas/` (le dernier de STORY-023).
- [ ] AC-03 — Chaque sous-dossier a un `.gitkeep` (ou un fichier minimum) pour être versionné même vide.
- [ ] AC-04 — Fichier placeholder `catalog/domains/retail_fresh_produce.json` présent, **valide** contre `module-config.schema.json` (minimum: `id`, `schema_version`, `name`, `i18n_key`, `icon`, `entities: []`, `rbac_roles: []`).
- [ ] AC-05 — Aucun fichier `catalog/` n'est dans `.gitignore` — tout est versionné.

### README intégrateur

- [ ] AC-06 — `catalog/README.md` existe, rédigé en **français**, structuré avec sections numérotées :
  1. "Qu'est-ce que le catalogue ?" (1 paragraphe, métaphore claire)
  2. "Anatomie d'un template" (schéma visuel ASCII ou diagramme)
  3. "Checklist en 5 étapes pour créer un domaine"
  4. "Validation locale & PR"
  5. "FAQ" (≥ 5 questions concrètes)
- [ ] AC-07 — La "Checklist en 5 étapes" est numérotée, chaque étape a une commande copy-paste exécutable.
- [ ] AC-08 — Le README ne suppose **aucune** connaissance de TypeScript, Dart, NestJS ou Flutter — uniquement git + JSON + ligne de commande basique.
- [ ] AC-09 — Liens absolus vers : `catalog/schemas/README.md` (STORY-023), doc HTML générée, `CONTRIBUTING.md`, exemples d'autres domaines.
- [ ] AC-10 — Section "FAQ" répond explicitement à : "Puis-je modifier le code Flutter/NestJS ?" (réponse: non, uniquement le catalogue), "Comment ajouter un module à un domaine existant ?", "Que faire si Zod me retourne une erreur ?", "Combien de temps prend une PR review ?", "Comment tester localement avant la PR ?".

### Contributing & process

- [ ] AC-11 — `catalog/CONTRIBUTING.md` rédigé : nommage des fichiers (`snake_case.json`), branches (`feat/catalog/<domain_id>`), commit messages (`feat(catalog): add domain <id>`), processus PR (1 reviewer Scalario obligatoire).
- [ ] AC-12 — Lien vers le workflow CI `validate-catalogue.yml` (STORY-024) avec explication "ce qui est validé automatiquement".

### Configuration Docker (volume monté)

- [ ] AC-13 — `docker-compose.yml` (et `docker-compose.dev.yml`) montent `./catalog:/app/catalog:ro` dans le container `nestjs`.
- [ ] AC-14 — `CATALOG_ROOT=/app/catalog` exposé via env var pour `CatalogueLoaderService` (STORY-024).
- [ ] AC-15 — Modification d'un fichier `catalog/` côté host → propagation immédiate dans le container (testé via `docker compose exec nestjs ls /app/catalog/domains/`).
- [ ] AC-16 — Documenté dans le README racine et `catalog/README.md` : "Pour ajouter un domaine en prod, déposer le fichier dans `/srv/scalario/catalog/`, le service le lit au prochain démarrage" (Phase 1) ou hot-reload (cf STORY-021 cache invalidation).

### Scaffold script

- [ ] AC-17 — `scripts/scaffold-domain.sh DOMAIN_ID` crée :
  - `catalog/domains/{DOMAIN_ID}.json` à partir d'un template embedded.
  - Imprime sur stdout les prochaines étapes (édition + validation).
- [ ] AC-18 — Le script refuse si le fichier existe déjà (pas d'écrasement silencieux), et valide que `DOMAIN_ID` match `^[a-z][a-z0-9_]*$`.
- [ ] AC-19 — Test : exécuter `bash scripts/scaffold-domain.sh test_demo` → fichier valide selon STORY-023, passe Zod (STORY-024).

### Référence dans README racine

- [ ] AC-20 — Le `README.md` racine du monorepo a une section "Catalogue (intégrateurs)" avec lien direct vers `catalog/README.md` et un teaser "ajouter un secteur = JSON, pas de code".
- [ ] AC-21 — Cette section est visible dans le top 30 lignes du README — on ne l'enterre pas en bas de page.

### Tests

- [ ] AC-22 — Test smoke : `cat catalog/domains/retail_fresh_produce.json | bun scripts/validate-catalogue.ts --stdin --type=module` → exit 0 (fichier valide). Si Zod n'est pas encore mergé (STORY-024), placeholder du test à activer post-merge.

---

## Technical Notes

### Composants concernés

- **Nouveau dossier :** `catalog/` racine du monorepo.
- **Nouveau script :** `scripts/scaffold-domain.sh`.
- **Modifs :** `docker-compose.yml`, `docker-compose.dev.yml`, `README.md` racine.

### Structure de fichiers (cible)

```
catalog/                                       # RACINE du monorepo
├── README.md                                  # 🎯 Le doc central pour intégrateurs (FR)
├── CONTRIBUTING.md                            # Règles de PR
├── domains/
│   ├── .gitkeep
│   └── retail_fresh_produce.json              # Placeholder valide (squelette)
├── modules/
│   └── .gitkeep
├── fusions/
│   └── .gitkeep
└── schemas/                                   # Vient de STORY-023
    ├── component-config.schema.json
    ├── screen-config.schema.json
    ├── module-config.schema.json
    ├── workflow.schema.json
    └── README.md

scripts/
└── scaffold-domain.sh                         # Helper CLI

docker-compose.yml                             # + volume catalog/
docker-compose.dev.yml                         # + volume catalog/
README.md                                      # Section "Catalogue intégrateurs"
```

### Code patterns

**`catalog/README.md` (extrait — début) :**

```markdown
# Catalogue Scalario — Guide Intégrateur

## 1. Qu'est-ce que le catalogue ?

Le catalogue est le **produit** de Scalario. C'est un dossier de fichiers JSON qui décrivent
des secteurs d'activité (retail, pharmacie, BTP, transport...). Le backend et l'app mobile
ne contiennent **aucun code métier** — ils lisent ce dossier et rendent l'expérience
correspondante.

> Métaphore : Scalario est un orchestre. Le catalogue est la partition. Sans partition,
> les musiciens (le code) ne savent pas quoi jouer.

Cela veut dire que pour ajouter un nouveau secteur (ou un nouveau module dans un secteur
existant), vous **n'écrivez aucune ligne de TypeScript ni de Dart**. Vous écrivez du JSON.

## 2. Anatomie d'un template

Un template sectoriel (un "domaine") est un fichier JSON dans `catalog/domains/` :

```
catalog/
├── domains/                # Templates par secteur (ex: pharmacie_quartier.json)
├── modules/                # Modules réutilisables (ex: pos.json, stock.json)
├── fusions/                # Combinaisons multi-domaines (ex: pharmacie + retail)
└── schemas/                # JSON Schemas (le contrat — ne pas modifier)
```

## 3. Checklist en 5 étapes — Créer un nouveau domaine

### Étape 1 — Scaffold

```bash
bash scripts/scaffold-domain.sh pharmacie_quartier
```

Cela crée `catalog/domains/pharmacie_quartier.json` avec le squelette minimum.

### Étape 2 — Éditer le JSON

Ouvrez `catalog/domains/pharmacie_quartier.json` et remplissez :
- `id` (déjà rempli)
- `name` (ex: "Pharmacie de quartier")
- `entities` (liste des choses qu'on stocke — ex: ordonnance, medicament)
- `actions` (les opérations possibles — ex: enregistrer_ordonnance)
- `rbac_roles` (qui peut faire quoi — ex: ["PHARMACIEN", "PREPARATEUR"])

Référez-vous à `catalog/schemas/README.md` pour la liste exacte des champs.

### Étape 3 — Valider localement

```bash
bun run validate-catalogue
```

S'il y a des erreurs, elles seront affichées ligne par ligne en français.

### Étape 4 — Commit & PR

```bash
git checkout -b feat/catalog/pharmacie_quartier
git add catalog/domains/pharmacie_quartier.json
git commit -m "feat(catalog): add pharmacie_quartier domain"
git push origin feat/catalog/pharmacie_quartier
```

Ouvrez la PR sur GitHub. La CI re-valide automatiquement.

### Étape 5 — Review & merge

Un membre de l'équipe Scalario passe en review (≤ 48h). Une fois mergé, le domaine
est disponible pour provisionner un nouveau tenant.

## 4. Validation locale & FAQ

### Comment tester avec un vrai tenant ?

[...]

### Que faire si Zod m'affiche "must follow pattern 'domaine.action'" ?

Cela veut dire qu'un de vos `actions[*].handler` n'est pas au bon format.
Le format est : `domaine.action`, par exemple `crud.create`, `workflow.advance`.
Voir [liste des handlers disponibles](./schemas/README.md#handlers).

### Puis-je modifier le code Flutter ou NestJS ?

**Non.** Si votre besoin nécessite un changement de code, c'est un changement plateforme
qui passe par un sprint produit Scalario. Le catalogue ne couvre que les domaines
exprimables dans le schema.
```

**`catalog/domains/retail_fresh_produce.json` (placeholder squelette) :**

```json
{
  "id": "retail_fresh_produce",
  "schema_version": "1.0.0",
  "name": "Commerce de produits frais",
  "i18n_key": "domain.retail_fresh_produce",
  "icon": "leaf",
  "entities": [],
  "actions": {},
  "rbac_roles": ["OWNER", "GERANT", "COMMERCIAL"],
  "abac_rules": [],
  "conflict_strategy": "server_wins"
}
```

**`scripts/scaffold-domain.sh` (extrait) :**

```bash
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
echo "  2. bun run validate-catalogue"
echo "  3. git checkout -b feat/catalog/${DOMAIN_ID}"
echo "  4. git commit + PR"
```

**`docker-compose.yml` (extrait modifié) :**

```yaml
services:
  nestjs:
    # ...
    environment:
      - CATALOG_ROOT=/app/catalog
    volumes:
      - ./catalog:/app/catalog:ro
```

### Edge cases

- **Volume monté en read-only (`:ro`)** : le NestJS ne peut pas écrire dans `catalog/` même par bug. Limite la surface d'attaque (un upload qui s'échappe ne peut pas écraser un fichier).
- **Hot-reload vs cache Redis** : modifier un fichier `catalog/` ne flushe pas le cache Redis tout seul. STORY-021 a un endpoint admin pour invalider, ou on attend le TTL 5min. Documenter.
- **Permissions filesystem** : le user du container NestJS doit pouvoir lire `/app/catalog/`. Vérifier dans le Dockerfile (`USER node` ou similaire) — chmod 644 sur les fichiers, 755 sur les dossiers.
- **Encodage** : tous les JSON en UTF-8 sans BOM. Documenter dans `CONTRIBUTING.md`. `.editorconfig` racine pour enforce.
- **Trailing newline** : exigé par convention. Lint git si besoin.

### Sécurité

- **Pas de secrets dans `catalog/`** — un fichier de domaine décrit la structure métier, pas les credentials. Documenter dans `CONTRIBUTING.md` ("ne jamais committer un email réel, un IBAN, un password").
- **PII** : si un example contient un nom propre ou un téléphone, c'est un leak. Convention : utiliser `Jeanne Test`, `+226 00 00 00 00`.
- **Fichier malicieux** (gros JSON, deeply nested) : Zod (STORY-024) limite via `body limit` côté API, et le bootstrap loader fail-fast en CI. La PR review humaine reste la dernière barrière.

---

## Dependencies

**Prérequis :**

- STORY-013 — monorepo structure (la racine doit exister).
- STORY-024 — Zod validator + workflow CI référencé (mais cette story peut être mergée avant, en plaçant juste les TODO de référence).

**Stories bloquées par celle-ci :**

- STORY-021 (BDUIService) — utilise `CATALOG_ROOT` env + le filesystem layout.
- STORY-022 (ModuleEngine) — idem.
- STORY-039 (template retail_fresh_produce.json) — c'est le premier "vrai" template qui consume cette structure.
- STORY-040 (provisioning tenant) — dépend du fait que les domaines existent dans `catalog/`.

**Externes :**

- `git`, `bash` (déjà supposés).
- Documentation publique : à terme, le README sera publié sur `https://docs.scalario.io/catalog/` — non bloquant pour cette story.

---

## Definition of Done

- [ ] Code commité sur `feat/story-025-catalog-structure`.
- [ ] `catalog/README.md`, `catalog/CONTRIBUTING.md`, `catalog/domains/retail_fresh_produce.json` présents.
- [ ] `scripts/scaffold-domain.sh` exécutable + testé manuellement (`bash scripts/scaffold-domain.sh test_demo` → fichier créé valide).
- [ ] `docker-compose.yml` + `docker-compose.dev.yml` montent le volume `./catalog:/app/catalog:ro`.
- [ ] `README.md` racine a la section "Catalogue intégrateurs" dans les 30 premières lignes.
- [ ] Test manuel d'onboarding : un tiers (Carlos en mode "intégrateur") suit le README sans aide → arrive à créer un fichier valide en < 10 min.
- [ ] Lecture de relecture par 1 personne non-dev (si possible — sinon par Codex en mode UX review) → feedback intégré.
- [ ] PR review (`/codex review` orienté DX intégrateur).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-025 status `completed`, sprint 3 completed_points += 2.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Création structure `catalog/` + .gitkeep + placeholder `retail_fresh_produce.json` | 0.25 | Mécanique. |
| Modifs `docker-compose*.yml` (volume + env) | 0.25 | 2 lignes par fichier. |
| `scripts/scaffold-domain.sh` + tests manuels | 0.25 | Bash propre, validation regex. |
| `catalog/README.md` rédaction FR (5 sections, 5 FAQ) | 0.75 | **Le poste principal** — bien écrire pour non-dev = soin. |
| `catalog/CONTRIBUTING.md` | 0.25 | Standard. |
| Section README racine + liens croisés | 0.25 | Trouver le bon emplacement. |
| **Total** | **2** | Fibonacci 2 — light. |

**Rationale :** Les 2 points sont presque entièrement dans la **qualité éditoriale FR** du README. Si on bâcle, l'expérience intégrateur est cassée et le modèle 60/40 ne décolle pas. Si on soigne, on gagne 30+ jours d'onboarding cumulés sur les 5-10 premiers intégrateurs.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` lignes 1670-1684 (structure `catalog/`) + lignes 1264-1275 (Maintenabilité §guide intégrateur). PRD §FR-021.
- **Le README est un produit** — il sera publié sur `docs.scalario.io/catalog` (Phase 2). Mettre la qualité d'un README open-source à fort traffic.
- **Tone FR** : direct, accueillant, sans jargon. Comme si on parlait à un dev backend Java de 5 ans qui apprend le JSON declarative — il a les compétences logiques mais pas le vocabulaire BDUI.
- **Internationalisation** : Phase 1 = FR uniquement (les intégrateurs cible UEMOA sont francophones). Phase 2 = traduction EN pour expansion.
- **Gouvernance des PR catalog** : pour Phase 1, une seule personne valide (Carlos). Phase 2, un comité de 2 mainteneurs + intégrateur senior. Documenter cette transition dans `CONTRIBUTING.md`.
- **Conflit potentiel avec PRD §FR-021** : le PRD ne précise pas explicitement le sous-dossier `fusions/`. **L'archi prime** (cf `architecture-scalario-2026-05-09.md` ligne 1674). Inclure les 4 sous-dossiers et documenter `fusions/` comme "réservé Phase 2 (combinaisons multi-domaines)".
- **CMS visuel pour intégrateurs** (Phase 2-3) : si jamais un Figma-like pour configurer les modules visuellement émerge, il génèrera **les mêmes fichiers JSON** dans `catalog/`. Le contrat est invariant.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
