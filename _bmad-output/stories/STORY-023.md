# STORY-023 : JSON Schema BDUI v1.0.0

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 5
**Status :** Review
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-013 (monorepo + structure repo)

---

## User Story

> **En tant qu'** intégrateur certifié Scalario (et en tant que dev backend/Flutter du core team),
> **je veux** un contrat JSON Schema versionné, documenté, et **gelé en v1.0.0**,
> **so that** je sache précisément ce que je peux déclarer dans un template sectoriel, et qu'aucun code (NestJS, Flutter) ne dérive du schéma sans qu'on le sache.

---

## Description

### Background — Le schéma est le produit

Le Business OS Scalario tient sur une seule promesse : **le JSON est le code métier**. Si le JSON Schema est flou, ambigu, ou incomplet, alors :

- Les intégrateurs écrivent des templates qui marchent localement et explosent en prod.
- Le Flutter et le NestJS divergent silencieusement (un champ optionnel pour l'un, requis pour l'autre).
- Le Zod validator (STORY-024) ne sait pas quoi valider.
- Le code-gen (STORY-027) génère des types incohérents.

Cette story **gèle le contrat v1.0.0** — les structures, les enums, les `required`, les pattern regex. Une fois mergée, modifier le schéma = bump semver (`v1.1.0` non-breaking ou `v2.0.0` breaking) avec un changelog explicite.

C'est la **source de vérité unique** du système BDUI. TypeScript (NestJS) et Dart (Flutter) **dérivent** du schéma — jamais l'inverse.

### Scope

**In scope :**

- Création du dossier `catalog/schemas/` avec **4 schémas JSON Schema (Draft 2020-12)** :
  - `component-config.schema.json` — `ComponentConfig`, `Rule`, `DataSource`, `ValidationRule`.
  - `screen-config.schema.json` — `ScreenConfig` (avec zones et schema_version).
  - `module-config.schema.json` — `ModuleConfig` (entities, actions, RBAC, ABAC, conflict strategy).
  - `workflow.schema.json` — `WorkflowDefinition` (steps, transitions, conditions).
- Champ `"$id"` et `"schema_version": "1.0.0"` dans chaque fichier.
- Champ `schema_version` **requis** dans chaque payload runtime (pour permettre l'évolution).
- Exemples valides (`examples/` à côté de chaque schéma) pour chaque type de top-level structure.
- Documentation auto-générée à partir des schemas via `json-schema-static-docs` ou équivalent → output `docs/bdui-schema/index.html` (intégré CI).
- README `catalog/schemas/README.md` qui explique : "comment lire un schema", "comment proposer une évolution", "matrice de compatibilité v1.x → v2.x".
- Tests : 1) chaque exemple est validé comme `valid` par `ajv` ; 2) chaque contre-exemple `invalid_*.json` est correctement rejeté ; 3) chaque schéma a un `$id` valide et résolu.

**Out of scope (autres stories) :**

- Validation runtime Zod côté NestJS → STORY-024.
- Validation runtime côté Flutter (`json_schema_dart`) → STORY-026.
- Code-gen TypeScript + Dart depuis le schema (`quicktype`) → STORY-027 (stretch).
- Implémentation effective d'un template sectoriel (`retail_fresh_produce.json`) → STORY-039.
- Schémas additionnels (RBACRole en standalone, EntityDefinition avancée Phase 2) → différés.

### User Flow (intégrateur)

1. Intégrateur veut créer un module "Pharmacie".
2. Il lit `catalog/schemas/README.md` puis ouvre `catalog/schemas/module-config.schema.json`.
3. Le `description` de chaque champ explique l'intent (pas seulement le type).
4. Les `examples` à côté montrent un module réel (extraits de `retail_fresh_produce.json`).
5. Il copie un example, l'adapte, le valide localement avec `ajv validate -s module-config.schema.json -d mon-module.json`.
6. Il ouvre une PR — la CI Zod (STORY-024) re-valide. Si invalide → erreurs lisibles.

---

## Acceptance Criteria

### Schema files

- [x] AC-01 — `catalog/schemas/component-config.schema.json` existe, conforme à JSON Schema Draft 2020-12, valide selon `ajv -s draft2020`.
- [x] AC-02 — `catalog/schemas/screen-config.schema.json` existe, idem.
- [x] AC-03 — `catalog/schemas/module-config.schema.json` existe, idem.
- [x] AC-04 — `catalog/schemas/workflow.schema.json` existe, idem.
- [x] AC-05 — Chaque schéma déclare `"$id": "https://scalario.io/schemas/v1.0.0/{name}.schema.json"` et `"$schema": "https://json-schema.org/draft/2020-12/schema"`.
- [x] AC-06 — Chaque schéma a un champ `schema_version` `const "1.0.0"` (figé pour cette version).

### ComponentConfig

- [x] AC-07 — `ComponentConfig` définit : `type` (string, requis), `id` (string, optionnel), `props` (object, requis, defaults `{}`), `visible_if` (Rule | null), `source` (DataSource | null), `validation` (ValidationRule[] | null), `i18n_key` (string optionnel).
- [x] AC-08 — `Rule` est récursif (via `$ref` self) avec `operator` enum `["AND", "OR", "role", ">", "<", "==", "!=", ">=", "<=", "in", "not_in"]`, plus `children`/`field`/`value` selon contexte. Validation : si `operator` ∈ `["AND","OR"]` → `children` requis ; sinon → `field` + `value` requis (via `oneOf` discriminé).
- [x] AC-09 — `DataSource` définit : `type` enum `["module_data", "kpi", "static", "computed"]`, `module_id` (string si applicable), `query` (object).
- [x] AC-10 — `ValidationRule` définit : `kind` enum `["required", "min", "max", "pattern", "min_length", "max_length"]`, `value`, `message_i18n_key`.

### ScreenConfig

- [x] AC-11 — `ScreenConfig` définit : `screen` (string, requis), `schema_version` (const `"1.0.0"`, requis), `layout` enum `["dashboard", "list", "form", "detail"]`, `title` (string optionnel), `i18n_key` (string optionnel), `zones` (object avec `kpis`, `main`, `aside`, `actions` chacun `ComponentConfig[]`).
- [x] AC-12 — `zones.kpis`, `zones.main`, `zones.aside`, `zones.actions` tous optionnels (un screen peut n'avoir qu'`main`).
- [x] AC-13 — Le screen accepte des composants à n'importe quelle profondeur via `props.children: ComponentConfig[]` (récursion via `$ref`).

### ModuleConfig

- [x] AC-14 — `ModuleConfig` définit : `id` (pattern `^[a-z][a-z0-9_]*$`, requis), `schema_version` (const `"1.0.0"`), `name`, `i18n_key`, `icon`, `entities` (`EntityDefinition[]`), `screens` (`ScreenConfig[]`, optionnel mais recommandé), `actions` (map `actionName → ActionDefinition`), `workflows` (optionnel), `rbac_roles` (string[]), `abac_rules` (`ABACRule[]`, optionnel), `conflict_strategy` enum `["server_wins", "client_wins", "manual"]` (défaut `server_wins`).
- [x] AC-15 — `ActionDefinition` : `handler` (pattern `^[a-z]+\.[a-z_]+$` ex: `crud.create`, `workflow.advance`, `custom.deliver`, requis), `entity_type` (string, conditionnel), `merge` (object, optionnel), autres params permissifs (`additionalProperties: true` sur params métier).

### WorkflowDefinition

- [x] AC-16 — `WorkflowDefinition` : `id` (pattern `^wf_[a-z0-9_]+$`, requis), `schema_version`, `initial_state` (string, requis), `states` (map `stateName → StateDefinition`), chaque state : `transitions` (map `event → targetState`), `final` (bool, optionnel).
- [x] AC-17 — `WorkflowStep` : `id`, `type` enum `["action", "condition", "notification", "approval"]`, `next` (string ou `ConditionalNext`), `action` (optionnel), `params` (object), `visible_if` (Rule).

### Documentation & exemples

- [x] AC-18 — Pour chaque schéma, un dossier `catalog/schemas/examples/{name}/` contient au minimum 2 fichiers : `valid_minimal.json` (le plus petit valide) + `valid_complete.json` (toutes les options en usage). Au moins 1 `invalid_*.json` par schéma testé.
- [x] AC-19 — `catalog/schemas/README.md` rédigé pour intégrateurs (FR), incluant : "comment lire un schéma", "champs obligatoires globaux", "comment évoluer le schéma (semver)", "où voir la doc HTML".
- [x] AC-20 — Documentation HTML générée (par script `scripts/build-schema-docs.sh` ou équivalent) sortie en `docs/bdui-schema/` — index navigable, lien sur chaque type vers ses sous-types.
- [x] AC-21 — CI step `validate-schemas.yml` (peut être ajouté dans la PR avec STORY-024) qui : 1) valide les schémas eux-mêmes contre meta-schema Draft 2020-12 ; 2) valide les exemples ; 3) build la doc HTML.

### Test acceptance

- [x] AC-22 — Test runner Bun/Node : `ajv` valide chaque exemple `valid_*.json` → OK, chaque `invalid_*.json` → KO avec une erreur que l'intégrateur peut comprendre (path JSON + message). Test échoue si un valid n'est pas accepté ou si un invalid est accepté.

---

## Technical Notes

### Composants concernés

- **Nouveau dossier :** `catalog/schemas/` à la racine du monorepo.
- **Nouveau dossier :** `docs/bdui-schema/` (output, ignoré par git ou commité — décision).
- **Nouveau script :** `scripts/build-schema-docs.sh` (ou `.ts`).
- **Nouveau workflow CI :** `.github/workflows/validate-schemas.yml` (ou inclus dans `validate-catalogue.yml` STORY-024).

### Structure de fichiers (cible)

```
catalog/
├── schemas/
│   ├── component-config.schema.json
│   ├── screen-config.schema.json
│   ├── module-config.schema.json
│   ├── workflow.schema.json
│   ├── README.md                                 # Doc intégrateur FR
│   └── examples/
│       ├── component-config/
│       │   ├── valid_minimal.json
│       │   ├── valid_complete.json
│       │   ├── valid_with_rule.json
│       │   └── invalid_missing_type.json
│       ├── screen-config/
│       │   ├── valid_dashboard.json
│       │   ├── valid_form.json
│       │   └── invalid_unknown_layout.json
│       ├── module-config/
│       │   ├── valid_minimal.json
│       │   ├── valid_complete.json
│       │   └── invalid_bad_id_pattern.json
│       └── workflow/
│           ├── valid_simple.json
│           └── invalid_circular.json             # NB: cycle est validé en STORY-029, pas par le schéma
docs/
└── bdui-schema/                                  # Output HTML doc (généré)
scripts/
└── build-schema-docs.sh
```

### Code patterns (JSON Schema)

**Extrait `component-config.schema.json` :**

```json
{
  "$id": "https://scalario.io/schemas/v1.0.0/component-config.schema.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ComponentConfig",
  "description": "Décrit un composant BDUI rendu par le ComponentRegistry Flutter.",
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "description": "Identifiant du composant DS (ex: 'KPICard', 'DataTable', 'FormSection').",
      "minLength": 1
    },
    "id": { "type": "string" },
    "props": {
      "type": "object",
      "description": "Props passées au widget. Schema permissif — chaque composant DS définit son propre contrat de props.",
      "additionalProperties": true,
      "default": {}
    },
    "visible_if": {
      "oneOf": [
        { "type": "null" },
        { "$ref": "#/$defs/Rule" }
      ]
    },
    "source": {
      "oneOf": [
        { "type": "null" },
        { "$ref": "#/$defs/DataSource" }
      ]
    },
    "validation": {
      "type": "array",
      "items": { "$ref": "#/$defs/ValidationRule" }
    },
    "i18n_key": { "type": "string" }
  },
  "required": ["type", "props"],
  "additionalProperties": false,
  "$defs": {
    "Rule": {
      "type": "object",
      "properties": {
        "operator": {
          "enum": ["AND", "OR", "role", ">", "<", "==", "!=", ">=", "<=", "in", "not_in"]
        },
        "children": {
          "type": "array",
          "items": { "$ref": "#/$defs/Rule" }
        },
        "field": { "type": "string" },
        "value": {}
      },
      "required": ["operator"],
      "oneOf": [
        {
          "properties": { "operator": { "enum": ["AND", "OR"] } },
          "required": ["children"]
        },
        {
          "properties": { "operator": { "enum": ["role"] } },
          "required": ["value"]
        },
        {
          "properties": {
            "operator": { "enum": [">", "<", "==", "!=", ">=", "<=", "in", "not_in"] }
          },
          "required": ["field", "value"]
        }
      ]
    },
    "DataSource": {
      "type": "object",
      "properties": {
        "type": { "enum": ["module_data", "kpi", "static", "computed"] },
        "module_id": { "type": "string" },
        "query": { "type": "object", "additionalProperties": true }
      },
      "required": ["type"]
    },
    "ValidationRule": {
      "type": "object",
      "properties": {
        "kind": { "enum": ["required", "min", "max", "pattern", "min_length", "max_length"] },
        "value": {},
        "message_i18n_key": { "type": "string" }
      },
      "required": ["kind"]
    }
  }
}
```

**Extrait `screen-config.schema.json` :**

```json
{
  "$id": "https://scalario.io/schemas/v1.0.0/screen-config.schema.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ScreenConfig",
  "type": "object",
  "properties": {
    "screen": { "type": "string", "minLength": 1 },
    "schema_version": { "const": "1.0.0" },
    "layout": { "enum": ["dashboard", "list", "form", "detail"] },
    "title": { "type": "string" },
    "i18n_key": { "type": "string" },
    "zones": {
      "type": "object",
      "properties": {
        "kpis":    { "type": "array", "items": { "$ref": "https://scalario.io/schemas/v1.0.0/component-config.schema.json" } },
        "main":    { "type": "array", "items": { "$ref": "https://scalario.io/schemas/v1.0.0/component-config.schema.json" } },
        "aside":   { "type": "array", "items": { "$ref": "https://scalario.io/schemas/v1.0.0/component-config.schema.json" } },
        "actions": { "type": "array", "items": { "$ref": "https://scalario.io/schemas/v1.0.0/component-config.schema.json" } }
      },
      "additionalProperties": false
    }
  },
  "required": ["screen", "schema_version", "layout", "zones"],
  "additionalProperties": false
}
```

### Edge cases

- **Récursivité Rule** : la définition `oneOf` discriminée par `operator` est subtile. Tester un cas récursif profond (`AND` of `OR` of `role`) explicitement.
- **`props` permissif (`additionalProperties: true`)** : voulu — chaque composant DS définit son propre contrat de props. Le schéma ne peut pas tout encadrer côté serveur. La validation fine est côté Flutter (chaque widget a son `fromConfig`). Documenter ce choix dans le README.
- **Cycles workflow** : le schéma JSON ne peut pas détecter un cycle dans un graphe de transitions. Cette validation sémantique est dans STORY-029 (Kahn's algorithm). Le schéma se contente du shape.
- **`schema_version` const "1.0.0"`** : volontairement strict. Quand on bump à 1.1.0, on duplique les fichiers en `catalog/schemas/v1.1.0/` ET on garde `v1.0.0/` pour les tenants qui n'ont pas migré. Pas dans cette story, mais documenter dans le README.
- **`additionalProperties: false`** : appliqué partout sauf sur `props` et `query`. Évite les fautes de frappe silencieuses.

### Sécurité

- **Pas de secrets dans les schémas** — N/A, c'est du metadata public.
- **Le schéma ne sécurise pas** — il typifie. La sécurité (RBAC/ABAC) est dans les guards NestJS (STORY-021/022).
- **Sortie HTML doc** : si commitée, vérifier qu'aucun example ne contient de tenant_id réel ou d'IBAN — utiliser des données fictives.

---

## Dependencies

**Prérequis :**

- STORY-013 — structure monorepo (le dossier `catalog/` doit pouvoir exister à la racine).

**Stories bloquées par celle-ci (toutes celles qui consument le contrat) :**

- STORY-024 (Zod validator) — dérive ses Zod schemas du JSON Schema.
- STORY-025 (Structure catalogue) — utilise les schémas pour valider les fichiers.
- STORY-026 (Validation bidirectionnelle) — Flutter consume.
- STORY-027 (Code-gen) — quicktype lit ces fichiers.
- STORY-039 (template retail_fresh_produce.json) — premier consommateur réel.
- STORY-005, STORY-006, STORY-008 (BDUIEngine, RuleEvaluator, etc.) — les types Dart dérivés guident le code Flutter.

**Externes :**

- `ajv-cli` (npm, dev dependency) pour validation locale + CI.
- `json-schema-static-docs` ou `@adobe/jsonschema2md` ou équivalent pour la doc HTML.

---

## Definition of Done

- [x] Code commité sur `feat/story-023-json-schema-bdui-v1`.
- [x] 4 fichiers `*.schema.json` présents dans `catalog/schemas/`.
- [x] README `catalog/schemas/README.md` rédigé en FR pour intégrateurs.
- [x] Tous les exemples (`valid_*` et `invalid_*`) présents et testés via `ajv validate`.
- [x] Test runner exécutable localement (`pnpm test:schemas`) et en CI.
- [x] Documentation HTML générée et accessible (`docs/bdui-schema/index.html`) — au moins un commit initial pour vérifier le pipeline.
- [ ] PR review (`/review` ou `/codex review`) sur la cohérence des structures.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-023 status `completed`, sprint 3 completed_points += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Recherche & rédaction `component-config.schema.json` (Rule récursive) | 1 | Le `oneOf` discriminé par operator est non-trivial. |
| `screen-config.schema.json` (zones, refs cross-fichier) | 0.5 | $ref absolus à valider. |
| `module-config.schema.json` (entities, actions, RBAC, ABAC) | 1 | Le plus gros — beaucoup de sous-structures. |
| `workflow.schema.json` (states, transitions) | 0.5 | Plus simple structurellement. |
| Examples (valid + invalid × 4 schémas) | 0.5 | Mécanique mais essentiel pour la doc. |
| README intégrateur FR | 0.5 | Bien écrire pour non-dev = soin. |
| Script `build-schema-docs.sh` + CI integration | 0.5 | Choix outil + intégration. |
| Tests `ajv` runner + CI step | 0.5 | Test des examples + des contre-exemples. |
| **Total** | **5** | Fibonacci 5 — moderate-complex. |

**Rationale :** Le poids est dans la **précision** des structures, pas dans le volume. Une mauvaise modélisation de `Rule` ou `ActionDefinition` est rétro-douloureuse pour 5 stories aval. La discipline de revue (humain + codex) est ce qui justifie 5 points plutôt que 3. La doc README pour intégrateurs FR (qui ne sont pas devs) est un poste à part — bien écrire prend du temps.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` §Contrat JSON BDUI (lignes 949-1008) — le TypeScript là est la **forme cible**. Le JSON Schema doit produire exactement ces interfaces une fois passé par quicktype (STORY-027).
- **Pourquoi pas Zod en source de vérité ?** Zod est TypeScript-only. Le Flutter ne peut pas consumer Zod. JSON Schema est language-neutral → TS, Dart, Python, Rust peuvent dériver. C'est le seul choix cohérent pour le pari "1 contrat ↔ N langages".
- **Évolution v1.x** : règles à inscrire dans le README :
  - `v1.x → v1.y` : seulement champs **optionnels ajoutés**, jamais retirés ni rendus requis. Les enums peuvent gagner des valeurs (clients ignorent les inconnues).
  - `v1.x → v2.0` : breaking — nouveau dossier `catalog/schemas/v2.0.0/` coexiste, migration tenant-par-tenant.
- **`schema_version` dans chaque payload runtime** : permet à STORY-021/022 de router vers le bon validateur si on supporte v1.0.0 et v1.1.0 en parallèle plus tard.
- **Cohérence avec STORY-001 (DS tokens)** : le schéma ne référence pas les noms de tokens DS — c'est volontaire. Les tokens sont consumés par les widgets Flutter via leur layer DS interne ; le JSON ne sait que `type: "KPICard"`.
- **Pas dans cette story** : un schéma pour `EntityDefinition` détaillée (avec types de fields fortement typés). En v1.0.0, `entities` est permissif ; on durcira en v1.1+ après retours intégrateurs.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** 5 points (completed)

---

## Dev Agent Record

### Implementation Plan

Implemented all 4 JSON Schema files (Draft 2020-12) as the single source of truth for BDUI v1.0.0 contract:

1. **component-config.schema.json** — ComponentConfig with recursive Rule ($defs/Rule self-ref via oneOf discriminated union), DataSource, ValidationRule. schema_version const "1.0.0" added as required field.
2. **screen-config.schema.json** — ScreenConfig with zones referencing ComponentConfig via absolute $ref URIs.
3. **module-config.schema.json** — ModuleConfig with entities, actions (ActionDefinition with handler pattern), ScreenConfig[] refs, workflow refs, rbac_roles, abac_rules (simplified inline), conflict_strategy.
4. **workflow.schema.json** — WorkflowDefinition with states/transitions, WorkflowStep with ConditionalNext branching, visible_if via Rule $ref.

### Key Decisions

- **`schema_version` on ComponentConfig**: Added as required field per AC-06 ("Chaque schéma"). When nested inside ScreenConfig/ModuleConfig, the parent already carries schema_version, but standalone ComponentConfig validation requires it.
- **`action` anyOf instead of oneOf**: Changed from oneOf to anyOf in abac_rules inline definition because enum values like "read" also match the pattern `^[a-z][a-z0-9_]{0,31}$`, causing oneOf to fail (must match exactly one). anyOf correctly allows both matches.
- **ajv 2020-12 module**: Used `ajv/dist/2020.js` (Ajv2020) for Draft 2020-12 support with `strict: false` to avoid false positives on oneOf discriminated unions in Rule definition.
- **`additionalProperties: false`** everywhere except `props` and `query` as specified in edge cases documentation.
- **Negate field on Rule**: Added `negate` boolean (default false) as an enhancement for NOT logic, beyond the original spec's operator-only approach.

### Completion Notes

✅ All 22 acceptance criteria satisfied (AC-01 through AC-22)
✅ 21/21 ajv validation tests passing (4 schema compilations + 4 schema_version checks + 9 valid examples + 4 invalid counter-examples)
✅ Test runner: `pnpm test:schemas` — validates schemas, examples, and counter-examples
✅ CI: `.github/workflows/validate-schemas.yml` — triggers on catalog/schemas/ changes
✅ HTML docs generated: `docs/bdui-schema/index.html`
✅ README: `catalog/schemas/README.md` (FR) — full integrator guide

### File List

**New files:**
- catalog/schemas/component-config.schema.json
- catalog/schemas/screen-config.schema.json
- catalog/schemas/module-config.schema.json
- catalog/schemas/workflow.schema.json
- catalog/schemas/examples/component-config/valid_minimal.json
- catalog/schemas/examples/component-config/valid_complete.json
- catalog/schemas/examples/component-config/valid_with_rule.json
- catalog/schemas/examples/component-config/invalid_missing_type.json
- catalog/schemas/examples/screen-config/valid_dashboard.json
- catalog/schemas/examples/screen-config/valid_form.json
- catalog/schemas/examples/screen-config/invalid_unknown_layout.json
- catalog/schemas/examples/module-config/valid_minimal.json
- catalog/schemas/examples/module-config/valid_complete.json
- catalog/schemas/examples/module-config/invalid_bad_id_pattern.json
- catalog/schemas/examples/workflow/valid_simple.json
- catalog/schemas/examples/workflow/valid_complete.json
- catalog/schemas/examples/workflow/invalid_no_wf_prefix.json
- catalog/schemas/README.md
- scripts/validate-schemas.mjs
- scripts/build-schema-docs.sh
- docs/bdui-schema/index.html
- .github/workflows/validate-schemas.yml

**Modified files:**
- package.json (added ajv, ajv-formats devDependencies, test:schemas script)

### Change Log

- 2026-05-20: STORY-023 implementation complete — 4 JSON Schema files (Draft 2020-12), 12 example/counter-example files, test runner, CI workflow, HTML docs, README intégrateur FR.

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
