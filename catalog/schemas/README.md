# Catalogue des schémas JSON BDUI Scalario

> **Version :** v1.0.0
> **Dernière mise à jour :** 2026-05-20

Ce dossier contient les **schémas JSON Schema (Draft 2020-12)** qui définissent le contrat BDUI de Scalario. Ces schémas sont la **source de vérité unique** : TypeScript (NestJS) et Dart (Flutter) en **dérivent** — jamais l'inverse.

## Comment lire un schéma

Chaque fichier `.schema.json` suit le standard [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/json-schema-core). Voici les concepts clés :

| Terme | Signification |
|-------|--------------|
| `$id` | Identifiant unique du schéma (URL canonique). Utilisé pour les `$ref` cross-fichier. |
| `$schema` | Version du standard JSON Schema utilisée. Toujours `https://json-schema.org/draft/2020-12/schema`. |
| `type` | Type JSON attendu (`object`, `string`, `number`, `array`, etc.). |
| `required` | Liste des champs obligatoires. Si un champ n'est pas dans `required`, il est optionnel. |
| `additionalProperties` | Si `false`, aucun champ hors du schéma n'est accepté. Si `true`, des champs libres sont autorisés. |
| `enum` | Liste de valeurs autorisées. Le champ ne peut prendre qu'une de ces valeurs. |
| `pattern` | Expression régulière que la valeur doit respecter. |
| `const` | Valeur fixe. Ex : `"schema_version": { "const": "1.0.0" }` signifie que seul `"1.0.0"` est accepté. |
| `$ref` | Référence vers un autre schéma ou une définition interne. Permet la récursion et la composition. |
| `$defs` | Définitions réutilisables internes au schéma (comme des "fonctions" dans le schéma). |
| `oneOf` | Le payload doit correspondre à **exactement un** des sous-schémas listés. Utilisé pour les unions discriminées. |
| `default` | Valeur par défaut si le champ est absent. |

## Champs obligatoires globaux

Tous les schémas BDUI partagent ces contraintes :

- **`schema_version`** : champ `const "1.0.0"` — obligatoire dans chaque payload runtime. Permet au BDUIEngine de router vers le bon validateur si plusieurs versions coexistent.
- **`$id`** : URL canonique au format `https://scalario.io/schemas/v1.0.0/<name>.schema.json`.
- **`additionalProperties: false`** : appliqué partout sauf sur `props` (ComponentConfig) et `query` (DataSource). Ce choix évite les fautes de frappe silencieuses.

## Les 4 schémas v1.0.0

| Schéma | Description | Point d'entrée |
|--------|-------------|----------------|
| `component-config` | Composant BDUI unique (widget DS avec visibilité, source de données, validation) | `ComponentConfig` |
| `screen-config` | Écran complet avec zones (kpis, main, aside, actions) | `ScreenConfig` |
| `module-config` | Module complet (entités, écrans, actions, workflows, RBAC, ABAC) | `ModuleConfig` |
| `workflow` | Machine à états finis pour les processus métier | `WorkflowDefinition` |

### Hiérarchie des `$ref`

```
module-config.schema.json
├── $ref → screen-config.schema.json (ScreenConfig[])
├── $ref → workflow.schema.json (workflows)
├── $defs → ActionDefinition
│
screen-config.schema.json
└── $ref → component-config.schema.json (zones.*.items)
    ├── $defs → Rule (récursif)
    ├── $defs → DataSource
    └── $defs → ValidationRule

workflow.schema.json
├── $defs → StateDefinition
├── $defs → WorkflowStep
│   └── $ref → component-config.schema.json#/$defs/Rule (visible_if)
└── $defs → ConditionalNext
    └── $ref → component-config.schema.json#/$defs/Rule (condition)
```

## Comment proposer une évolution du schéma

### Règles de versionning (SemVer)

| Transition | Règle | Exemple |
|------------|-------|---------|
| `v1.0.0 → v1.x.0` (non-breaking) | Ajout de champs **optionnels** uniquement. Jamais de champ retiré ou rendu requis. Les enums peuvent gagner des valeurs (les clients ignorent les inconnues). | Ajout de `icon` optionnel à `ActionDefinition`. |
| `v1.x.0 → v2.0.0` (breaking) | Retrait de champ, champ devenu requis, changement de type, suppression de valeur d'enum. Nouveau dossier `catalog/schemas/v2.0.0/` coexiste avec `v1.0.0/`. | `props` devient un `$ref` au lieu de `additionalProperties: true`. |

### Processus

1. **Créer une branche** `schema/v1.x-description` ou `schema/v2-description`.
2. **Copier** le(s) schéma(s) impactés dans le nouveau dossier de version si breaking.
3. **Modifier** le(s) schéma(s).
4. **Mettre à jour** les exemples `valid_*` et `invalid_*`.
5. **Lancer** `pnpm test:schemas` — tous les tests doivent passer.
6. **Ouvrir une PR** avec le label `schema-change`. Le reviewer vérifie la compatibilité.
7. **Après merge**, le code-gen (STORY-027) est relancé pour produire les nouveaux types.

### Matrice de compatibilité v1.x → v2.x

| Version | Statut | Notes |
|---------|--------|-------|
| v1.0.0 | **Figé** | Version initiale. Aucune modification possible sans bump semver. |
| v1.1.0 | (futur) | Champs optionnels ajoutés. Clients v1.0.0 compatibles. |
| v2.0.0 | (futur) | Breaking changes. Migration tenant-par-tenant. |

## Validation locale

### Prérequis

```bash
pnpm install
```

Les dépendances `ajv-cli` et `ajv-formats` sont installées en tant que devDependencies.

### Valider les schémas eux-mêmes

```bash
pnpm test:schemas
```

Ce script :
1. Valide que chaque `*.schema.json` est conforme au meta-schéma Draft 2020-12.
2. Valide que chaque exemple `valid_*.json` est accepté par son schéma.
3. Valide que chaque contre-exemple `invalid_*.json` est **rejeté** par son schéma, avec un message d'erreur compréhensible (chemin JSON + description).
4. Vérifie que chaque schéma a un `$id` valide et résolu.

### Valider un fichier JSON spécifique

```bash
npx ajv validate -s catalog/schemas/module-config.schema.json -d mon-module.json
```

## Documentation HTML

La documentation HTML est générée à partir des schémas via le script `scripts/build-schema-docs.sh`.

```bash
./scripts/build-schema-docs.sh
```

Le résultat est publié dans `docs/bdui-schema/index.html`. Chaque type est lien vers ses sous-types.

## Où voir la doc HTML

- **Local** : ouvrir `docs/bdui-schema/index.html` dans un navigateur.
- **CI** : la doc est générée par le workflow `validate-schemas.yml` et uploadée comme artifact.

## Notes de design

### Pourquoi `props` est permissif (`additionalProperties: true`) ?

Chaque composant DS (KPICard, DataTable, FormSection, Button...) a son propre contrat de props défini côté Flutter. Le schéma JSON ne peut pas tout encadrer côté serveur — il sert de **contrat structurel**, pas de contrat de props. La validation fine des props est effectuée par chaque widget via sa méthode `fromConfig`.

### Pourquoi `schema_version` est un `const` ?

En v1.0.0, le champ est figé. Quand on bump à v1.1.0, on duplique les fichiers dans `catalog/schemas/v1.1.0/` ET on garde `v1.0.0/` pour les tenants qui n'ont pas migré. Le BDUIEngine peut router vers le bon validateur en fonction de `schema_version`.

### Pourquoi les cycles workflow ne sont pas détectés ?

Le schéma JSON est un contrat **structurel**. Il valide le shape d'un workflow (états, transitions, types). Un cycle dans le graphe de transitions est une erreur **sémantique** détectée par le DAG Validator (STORY-029, algorithme de Kahn). Le schéma se contente de garantir que le shape est correct.

### Cohérence avec les tokens DS (STORY-001)

Le schéma ne référence pas les noms de tokens DS — c'est volontaire. Les tokens sont consommés par les widgets Flutter via leur layer DS interne ; le JSON ne sait que `type: "KPICard"`.

---

**Source :** Architecture Scalario 2026-05-09, §Contrat JSON BDUI
**Stories liées :** STORY-024 (Zod), STORY-025 (Catalogue), STORY-026 (Validation bidirectionnelle), STORY-027 (Code-gen), STORY-029 (DAG Validator)