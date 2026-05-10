# STORY-027 : Code-gen Contrat Partagé

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have *(STRETCH — Sprint 4)*
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-023 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant que** dev solo Carlos sur Scalario (NestJS et Flutter en parallèle),
> **je veux** que les types TypeScript et les classes Dart soient **auto-générés** depuis les fichiers `catalog/schemas/*.json`,
> **so that** une désynchronisation silencieuse entre backend et frontend soit **structurellement impossible** — la compilation échoue dès qu'un type est utilisé incorrectement.

---

## Description

### Background — Le rêve : une seule source, deux langages

Sans génération automatique, on a 3 endroits à maintenir manuellement :

1. JSON Schema (`catalog/schemas/*.json`) — STORY-023.
2. Types TypeScript dans NestJS (utilisés par services + Zod).
3. Classes Dart dans Flutter (`fromJson` / `toJson` partout).

À 4 schémas × 2 langages × 50 champs total ≈ 400 lignes de boilerplate. Plus important : un **drift silencieux** est inévitable. Quelqu'un ajoute `ModuleConfig.tags?: string[]` au schéma, oublie de propager côté Dart, le Flutter le drop, le backend l'envoie — bug de production tranquille.

La solution : `quicktype` lit le JSON Schema, génère TS et Dart en CI. Les types sont **dérivés**, jamais écrits à la main. Toute modif du schéma déclenche une regen ; toute désync fait échouer la compilation.

### Pourquoi STRETCH ? (et pourquoi quand même la faire)

C'est marqué stretch parce que :

- Phase 1, on peut survivre avec types maintenus à la main (4 schémas, périmètre fini).
- La **valeur** monte exponentiellement quand on ajoute des modules / des intégrateurs externes / des révisions de schéma.
- Faisable techniquement en 3 points si quicktype "marche du premier coup".

Choix opérationnel : **livrer en sprint 4 si Sprint 3 finit en avance**, sinon différer post-Gate 0. Ne pas bloquer le Gate 0 dessus.

### Scope

**In scope :**

- Création du package `packages/shared-contracts/` avec sous-dossiers `typescript/` et `dart/`.
- Script `scripts/generate-types.sh` (ou `.ts` Bun) qui :
  1. Lit chaque fichier `catalog/schemas/*.schema.json`.
  2. Exécute `quicktype` ou outil équivalent → génère `packages/shared-contracts/typescript/*.ts` et `packages/shared-contracts/dart/*.dart`.
  3. Émet un header de fichier `// AUTO-GENERATED — DO NOT EDIT. Run scripts/generate-types.sh.`
- Configuration `quicktype` (CLI) : nom des classes, options TS (`--src-lang schema --lang typescript --no-runtime-typecheck`), options Dart (`--lang dart --use-freezed` ou équivalent — à valider).
- Intégration NestJS : `backend/nestjs/src/...` import `@scalario/shared-contracts/typescript` (path alias TS).
- Intégration Flutter : `apps/flutter/pubspec.yaml` réfère le path `../../packages/shared-contracts/dart/` ou copie embedded.
- Workflow CI step `generate-types` dans `validate-catalogue.yml` (cf STORY-024) qui :
  - Re-génère les types sur chaque PR touchant `catalog/schemas/*.json`.
  - **Compare** avec les fichiers commités. Si diff → CI rouge `"types out of sync — run scripts/generate-types.sh"`.
- Tests : `nestjs build` + `flutter analyze` doivent passer après une modification triviale du schéma + regeneration. Pas de test métier dans cette story — c'est un pipeline.

**Out of scope (autres stories) :**

- Migrer le code existant pour qu'il utilise les types générés à la place des types maintenus à la main → tâche de refactoring qui peut suivre, pas dans cette story.
- Génération depuis un format autre que JSON Schema (TypeScript-first, OpenAPI, etc.) — pas pertinent.
- Génération de code de validation (Zod, json_schema runtime) — STORY-024 et STORY-026 gèrent.
- Documentation auto-générée — STORY-023.

### User Flow (dev)

1. Carlos modifie `catalog/schemas/module-config.schema.json` — ajoute un champ `tags?: string[]`.
2. En local : `bash scripts/generate-types.sh` → met à jour `shared-contracts/typescript/module-config.ts` et `shared-contracts/dart/module_config.dart`.
3. Commit + push : la PR inclut le diff schémas + le diff fichiers générés.
4. CI : re-run `generate-types.sh` puis `git diff --exit-code packages/shared-contracts/` → si non-zéro, échec avec message clair.
5. NestJS et Flutter qui utilisent le type `ModuleConfig` peuvent maintenant accéder à `.tags` sans cast.
6. Si Carlos modifie un type côté code mais pas le schéma → la prochaine `generate-types.sh` overwrite ses changements ; CI le rappelle.

---

## Acceptance Criteria

### Setup tooling

- [ ] AC-01 — Package `packages/shared-contracts/` créé avec `package.json` (TS sub-pkg) et structure Dart pub-compatible.
- [ ] AC-02 — `quicktype` (npm) installé en dev dependency racine — version pinned (ex: `^23.x`).
- [ ] AC-03 — `scripts/generate-types.sh` exécutable, idempotent (re-runs identiques produisent les mêmes fichiers).
- [ ] AC-04 — Header `// AUTO-GENERATED — DO NOT EDIT. Run scripts/generate-types.sh.` présent en tête de **chaque fichier généré**.

### Génération TypeScript

- [ ] AC-05 — Pour chaque `catalog/schemas/*.schema.json`, un fichier `packages/shared-contracts/typescript/{name}.ts` est généré contenant les `interface` ou `type` correspondants.
- [ ] AC-06 — Les noms d'interface matchent ceux de l'archi (`ComponentConfig`, `ScreenConfig`, `ModuleConfig`, `Rule`, `WorkflowDefinition`, `ActionDefinition`).
- [ ] AC-07 — `packages/shared-contracts/typescript/index.ts` re-exporte tout (`export * from './module-config'; ...`).
- [ ] AC-08 — `tsc --noEmit packages/shared-contracts/typescript/` passe sans erreur.

### Génération Dart

- [ ] AC-09 — Pour chaque `catalog/schemas/*.schema.json`, un fichier `packages/shared-contracts/dart/{name_snake}.dart` est généré.
- [ ] AC-10 — Les classes incluent `fromJson(Map<String, dynamic>)` et `toJson()` — soit via `json_serializable` + `build_runner`, soit via le code généré directement par quicktype.
- [ ] AC-11 — `dart analyze packages/shared-contracts/dart/` passe sans erreur.
- [ ] AC-12 — Les types union JSON Schema (`oneOf`) sont mappés en classes scellées Dart 3 (`sealed`) ou en hiérarchies abstraites — vérifié sur `Rule` (le cas non-trivial).

### Intégration NestJS

- [ ] AC-13 — `backend/nestjs/tsconfig.json` a un path alias `@scalario/shared-contracts → ../../packages/shared-contracts/typescript`.
- [ ] AC-14 — Au moins **un fichier NestJS existant** (idéalement dans `module-engine/` ou `bdui/`) consume `import { ModuleConfig } from '@scalario/shared-contracts'` — preuve de wiring fonctionnel.
- [ ] AC-15 — `bun build` ou `bun tsc` du backend passe.

### Intégration Flutter

- [ ] AC-16 — `apps/flutter/pubspec.yaml` référence le path Dart : `shared_contracts: { path: ../../packages/shared-contracts/dart }`.
- [ ] AC-17 — Au moins **un fichier Flutter existant** consume `import 'package:shared_contracts/screen_config.dart'` (ou équivalent) — preuve de wiring.
- [ ] AC-18 — `flutter analyze` passe.

### CI sync check

- [ ] AC-19 — `.github/workflows/validate-catalogue.yml` (existant, STORY-024) ajoute un step `generate-types` :
  ```yaml
  - run: bash scripts/generate-types.sh
  - run: git diff --exit-code packages/shared-contracts/
  ```
  Si diff → CI rouge avec message `"types out of sync — run scripts/generate-types.sh and commit"`.
- [ ] AC-20 — Test du happy path : modifier `catalog/schemas/module-config.schema.json` (ajout d'un champ optionnel) → script regen → commit → CI verte.
- [ ] AC-21 — Test du sad path : modifier le schéma sans regen → CI rouge avec message clair.

### Documentation

- [ ] AC-22 — `packages/shared-contracts/README.md` rédigé : "ce package est généré, ne PAS éditer manuellement, voir scripts/generate-types.sh". Mentionné aussi dans `catalog/schemas/README.md`.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `packages/shared-contracts/`.
- **Nouveau script :** `scripts/generate-types.sh`.
- **Modifs :** `backend/nestjs/tsconfig.json`, `apps/flutter/pubspec.yaml`, `.github/workflows/validate-catalogue.yml`, root `package.json` (devDep `quicktype`).

### Structure de fichiers (cible)

```
packages/
└── shared-contracts/
    ├── README.md                                # AVERTISSEMENT auto-generated
    ├── package.json                              # Pour TS sub-pkg
    ├── typescript/
    │   ├── component-config.ts                   # AUTO-GENERATED
    │   ├── screen-config.ts                      # AUTO-GENERATED
    │   ├── module-config.ts                      # AUTO-GENERATED
    │   ├── workflow.ts                           # AUTO-GENERATED
    │   └── index.ts                              # AUTO-GENERATED (barrel)
    └── dart/
        ├── pubspec.yaml                          # Pour pub local
        ├── lib/
        │   ├── component_config.dart             # AUTO-GENERATED
        │   ├── screen_config.dart                # AUTO-GENERATED
        │   ├── module_config.dart                # AUTO-GENERATED
        │   ├── workflow.dart                     # AUTO-GENERATED
        │   └── shared_contracts.dart             # AUTO-GENERATED (barrel)

scripts/
└── generate-types.sh

.github/workflows/
└── validate-catalogue.yml                        # + step generate-types
```

### Code patterns

**`scripts/generate-types.sh` :**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCHEMAS_DIR="catalog/schemas"
TS_OUT="packages/shared-contracts/typescript"
DART_OUT="packages/shared-contracts/dart/lib"

mkdir -p "$TS_OUT" "$DART_OUT"

GENERATE_HEADER_TS="// AUTO-GENERATED — DO NOT EDIT. Run scripts/generate-types.sh.\n// Source: catalog/schemas/"
GENERATE_HEADER_DART="// AUTO-GENERATED — DO NOT EDIT. Run scripts/generate-types.sh.\n// Source: catalog/schemas/"

for schema in "$SCHEMAS_DIR"/*.schema.json; do
  name=$(basename "$schema" .schema.json)            # ex: module-config
  ts_name="${name}.ts"
  dart_name="${name//-/_}.dart"                       # snake_case for Dart
  class_name=$(echo "$name" | awk -F'-' '{for(i=1;i<=NF;i++) printf toupper(substr($i,1,1)) substr($i,2)}')

  # TypeScript
  echo "Generating TypeScript: $ts_name"
  echo -e "${GENERATE_HEADER_TS}${name}.schema.json\n" > "$TS_OUT/$ts_name"
  npx quicktype \
    --src "$schema" --src-lang schema \
    --lang typescript \
    --top-level "$class_name" \
    --no-runtime-typecheck \
    --just-types \
    >> "$TS_OUT/$ts_name"

  # Dart
  echo "Generating Dart: $dart_name"
  echo -e "${GENERATE_HEADER_DART}${name}.schema.json\n" > "$DART_OUT/$dart_name"
  npx quicktype \
    --src "$schema" --src-lang schema \
    --lang dart \
    --top-level "$class_name" \
    --null-safety \
    >> "$DART_OUT/$dart_name"
done

# Generate barrels
{
  echo "$GENERATE_HEADER_TS"
  for f in "$TS_OUT"/*.ts; do
    [[ "$(basename "$f")" == "index.ts" ]] && continue
    echo "export * from './$(basename "$f" .ts)';"
  done
} > "$TS_OUT/index.ts"

{
  echo "$GENERATE_HEADER_DART"
  echo "library shared_contracts;"
  for f in "$DART_OUT"/*.dart; do
    [[ "$(basename "$f")" == "shared_contracts.dart" ]] && continue
    echo "export '$(basename "$f")';"
  done
} > "$DART_OUT/shared_contracts.dart"

echo "✅ Types generated. Run 'git diff packages/shared-contracts/' to inspect."
```

**Workflow CI step (extrait `validate-catalogue.yml`) :**

```yaml
- name: Generate types
  run: bash scripts/generate-types.sh

- name: Check types in sync
  run: |
    if ! git diff --exit-code packages/shared-contracts/; then
      echo "::error::Types out of sync. Run 'bash scripts/generate-types.sh' and commit."
      exit 1
    fi
```

### Edge cases

- **`oneOf` discriminé (Rule)** : quicktype génère soit des unions TypeScript propres, soit des classes scellées Dart. Tester explicitement — si l'output est moche, alternatives :
  - Forker quicktype avec un template custom.
  - Post-processing avec un script de polish.
  - Accepter la output et écrire des helpers à côté (non-générés mais minimal).
- **`additionalProperties: true` sur `props`** : quicktype les mappe en `Map<String, dynamic>` Dart / `Record<string, unknown>` TS. OK.
- **Récursivité (Rule)** : peut générer des forward refs. TS supporte trivialement, Dart aussi. Vérifier.
- **Naming collision** : si deux schémas définissent un type avec le même nom (ex: `Action` dans `module-config` et `workflow`), quicktype renomme avec suffixe — vérifier que les imports tiennent. Sinon, top-level différents.
- **`schema_version: const "1.0.0"`** : quicktype peut générer `'1.0.0' | undefined`. OK.
- **Outils alternatifs si quicktype foire** : `json-schema-to-typescript` (TS only), `json_serializable` (Dart only avec hand-written classes). Plus de surface, mais fallback documentable.

### Sécurité

- **Pas de secrets dans les schémas** (déjà couvert STORY-023).
- **Files générés signés** : un commiter qui édite manuellement un fichier généré est immédiatement visible — header + CI sync check le surfacent.
- **Pas de code exécutable dans la génération** — `quicktype` lit un JSON et écrit un fichier. Pas de templating Turing-complete.
- **Supply chain** : `quicktype` est largement utilisé (300k+ downloads/sem), maintenu, OSS. Pin version pour éviter surprise upstream.

---

## Dependencies

**Prérequis :**

- STORY-023 — JSON Schema BDUI v1.0.0 (sources de la génération).
- STORY-024 — workflow CI `validate-catalogue.yml` (où s'insère le step).

**Stories bloquées par celle-ci :**

- Aucune **bloquée**. Toutes les stories Phase 1 peuvent vivre sans (avec types manuels). Mais après merge, les stories aval peuvent **consommer** les types générés au lieu d'en maintenir des copies (refactor opportuniste).

**Externes :**

- `quicktype` (npm). Voir [quicktype.io](https://quicktype.io/).
- Optionnel : `json_serializable` + `build_runner` (Dart) si on veut des `fromJson` super-typés au-delà de quicktype default.

---

## Definition of Done

- [ ] Code commité sur `feat/story-027-codegen-shared-contracts`.
- [ ] `scripts/generate-types.sh` exécutable, produit des fichiers identiques à 2 runs successifs (idempotent).
- [ ] TypeScript : `tsc --noEmit packages/shared-contracts/typescript/` passe.
- [ ] Dart : `dart analyze packages/shared-contracts/dart/lib/` passe.
- [ ] Au moins 1 fichier NestJS et 1 fichier Flutter consument un type généré (preuve de wiring).
- [ ] Workflow CI `validate-catalogue.yml` modifié, testé via une PR de drift volontaire (CI rouge attendue).
- [ ] `packages/shared-contracts/README.md` rédigé (avertissement auto-generated).
- [ ] PR review (`/codex review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-027 status `completed`, sprint 4 completed_points += 3 (ou marquée `deferred` si stretch non livré).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Setup `packages/shared-contracts/` (structure + manifests) | 0.25 | Boilerplate. |
| `scripts/generate-types.sh` (Bash + quicktype incantation) | 0.75 | Itérer sur les flags quicktype jusqu'à output propre. |
| Validation output (Rule récursive surtout) + post-process si nécessaire | 0.75 | Le risque principal est ici — si quicktype génère mal `oneOf`, on improvise. |
| Wiring NestJS path alias + import sample | 0.25 | tsconfig + un import. |
| Wiring Flutter path dependency + import sample | 0.25 | pubspec + un import. |
| CI workflow update + test du sync check | 0.5 | Le sad-path test est important. |
| README + docs croisés | 0.25 | Concis. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** Le gros de l'incertitude est la **qualité de l'output quicktype** sur `Rule` (récursive, discriminée). Si ça marche du premier coup, on est en avance. Sinon, on passe 1 jour à tweaker — d'où les 3 points (pas 2). Stretch parce que **non bloquant** : sans, on maintient à la main, c'est inconfortable mais survivable Phase 1.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` lignes 267 (`quicktype`), 951-953 (commentaire "GÉNÉRÉ par quicktype"), 1681-1684 (structure `packages/shared-contracts/`), 1760 ("quicktype → TypeScript + Dart types"). PRD §FR-054.
- **Pourquoi quicktype et pas alternative langue-spécifique ?** Quicktype génère **deux langages depuis une source** — c'est exactement le besoin. Alternatives :
  - `json-schema-to-typescript` : TS only, rate les Dart.
  - `openapi-generator` : OpenAPI-first, pas JSON Schema-pure.
  - Hand-writing : impossible long terme.
  - Quicktype est l'outil standard pour ce use case.
- **Plan B si quicktype foire** :
  - Générer TS via `json-schema-to-typescript`.
  - Générer Dart via `quicktype` ou un script custom + `json_serializable`.
  - Plus lourd, mais découplable.
- **Évolution** : à terme, on peut aussi générer des **handlers Zod** depuis JSON Schema (via `json-schema-to-zod`) → unifier STORY-024 + STORY-027. Pas dans cette story.
- **Si stretch non-livré** : la dette est gérable manuellement Phase 1 — 4 schémas × 2 langages = 8 fichiers à maintenir. La discipline de PR review (chaque modif schéma → check des 2 fichiers types) suffit pour 5-10 itérations. Au-delà, devenir prioritaire post-Gate 0.
- **Cohérence avec STORY-026** : le validator runtime Flutter (json_schema package) reste utile même avec types Dart générés — il valide les payloads incomplets/cassés au runtime, alors que les types donnent juste un contrat compile-time. Les deux coexistent.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
