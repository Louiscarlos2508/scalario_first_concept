# STORY-024 : Zod Validator + API Validation

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-023 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant que** système Scalario (et en tant qu'intégrateur certifié),
> **je veux** qu'un JSON template invalide soit **bloqué avant tout stockage ou tout déploiement**,
> **so that** aucun JSON cassé ne puisse atteindre le moteur de rendu, et que les erreurs reçues soient lisibles par un intégrateur non-dev (path JSON + message FR).

---

## Description

### Background

Le JSON Schema (STORY-023) **définit** ce qui est valide. Le Zod validator **enforce** cette définition à 3 endroits critiques :

1. **CI sur chaque PR** — un fichier `catalog/**/*.json` invalide bloque la PR. Aucun JSON cassé ne peut atteindre `main`.
2. **Au démarrage NestJS** — chargement de tous les fichiers du catalogue ; si un est invalide, le service refuse de démarrer (fail-fast > fail-silently).
3. **À chaque appel API** qui accepte un payload typé (ex: `POST /admin/templates/validate`, body de mutations dans STORY-022) → NestJS pipe Zod rejette avant l'exécution.

Pourquoi Zod et pas Ajv direct ? Zod est TypeScript-natif → meilleure DX pour les devs NestJS, error messages structurés, intégration NestJS pipes triviale. Le **JSON Schema reste la source** ; Zod est dérivé (manuellement Phase 1, généré Phase 2 via `json-schema-to-zod` si besoin).

### Scope

**In scope :**

- Module NestJS `backend/nestjs/src/catalogue/validators/` avec :
  - `component-config.zod.ts` — schéma Zod miroir de `ComponentConfig`.
  - `screen-config.zod.ts` — `ScreenConfig`.
  - `module-config.zod.ts` — `ModuleConfig`.
  - `workflow.zod.ts` — `WorkflowDefinition`.
  - `rule.zod.ts` — `Rule` (récursif via `z.lazy`).
  - `index.ts` — barrel export.
- Endpoint `POST /api/v1/admin/templates/validate` qui accepte `{ content: JSON, type: 'domain'|'module'|'fusion'|'screen'|'workflow' }` et retourne `{ valid: boolean, errors?: ValidationErrorList }`.
- `CatalogueLoaderService` (consommé aussi par STORY-021 et STORY-022) qui charge tous les `catalog/**/*.json` au démarrage et valide avec Zod.
- Custom NestJS pipe `ZodValidationPipe` réutilisable dans les controllers (`@UsePipes(new ZodValidationPipe(ModuleConfigZod))`).
- Formatter d'erreurs lisibles (FR) : `{ path: ".module.actions.creer_produit.handler", message: "Le champ 'handler' doit suivre le pattern 'domaine.action' (ex: 'crud.create')" }`.
- CI workflow `.github/workflows/validate-catalogue.yml` qui exécute `bun run validate-catalogue` (script qui appelle le validator) sur chaque PR touchant `catalog/`.
- Tests unitaires : pour chaque type, ≥ 3 cas valides + ≥ 3 cas invalides avec assertion sur le path et le message.

**Out of scope (autres stories) :**

- Génération automatique des schémas Zod depuis les JSON Schemas → Phase 2 ou STORY-027 stretch (pour Phase 1 on dérive manuellement, en miroir 1-pour-1 avec les `$ref`/structure).
- Validation côté Flutter (`json_schema_dart`) → STORY-026.
- L'utilisation effective des pipes dans `BDUIService`/`ModuleEngine` → consommée dans STORY-021/022 ; cette story **fournit** les schémas et le pipe.

### User Flow

**Intégrateur ouvre une PR :**

1. Il modifie `catalog/domains/retail_fresh_produce.json`.
2. CI démarre `validate-catalogue.yml` → script `bun run scripts/validate-catalogue.ts` parcourt `catalog/**/*.json`.
3. Pour chaque fichier, détermine le type (par sous-dossier : `domains/` → ModuleConfig, `schemas/` → skip, etc.).
4. Parse + Zod validation.
5. Si invalide, affiche en sortie CI : 
   ```
   ❌ catalog/domains/retail_fresh_produce.json
      └─ .actions.creer_produit.handler: doit suivre le pattern 'domaine.action' (ex: 'crud.create'). Reçu: 'creerProduit'.
      └─ .rbac_roles[2]: doit être une string. Reçu: null.
   ```
6. PR bloquée jusqu'à correction.

**Endpoint API live :**

1. Intégrateur teste un template via UI admin (build-time tool ou ad-hoc).
2. `POST /api/v1/admin/templates/validate` body `{ content: {...}, type: 'module' }`.
3. Service Zod-valide → retourne `{ valid: false, errors: [...] }` ou `{ valid: true }`.
4. UI admin affiche les erreurs.

---

## Acceptance Criteria

### Schémas Zod

- [ ] AC-01 — Pour chaque schéma JSON Schema de STORY-023, un fichier `*.zod.ts` correspondant existe avec une exportation `XxxZod: ZodType`.
- [ ] AC-02 — `ComponentConfigZod` couvre tous les champs de `ComponentConfig` avec les mêmes contraintes (required, enums, patterns).
- [ ] AC-03 — `RuleZod` est récursif via `z.lazy(() => RuleZod)` — accepté par Zod, testé sur structures imbriquées 3 niveaux.
- [ ] AC-04 — `RuleZod` discriminé par `operator` : `AND/OR` requièrent `children`, `role` requiert `value: string[]`, comparators requièrent `field` + `value` (via `z.discriminatedUnion` ou `z.union`+`refine`).
- [ ] AC-05 — `ScreenConfigZod`, `ModuleConfigZod`, `WorkflowDefinitionZod` similairement complets.

### Endpoint validate

- [ ] AC-06 — `POST /api/v1/admin/templates/validate` body `{ content: object, type: 'domain'|'module'|'fusion'|'screen'|'workflow' }` accepté.
- [ ] AC-07 — Réponse 200 `{ valid: true }` si OK.
- [ ] AC-08 — Réponse 422 (Unprocessable Entity) `{ valid: false, errors: ValidationErrorList }` si KO. Status 422 cohérent avec STORY-022.
- [ ] AC-09 — Endpoint guarded par `JwtAuthGuard` + rôle `ADMIN_SCALARIO` ou `OWNER` (intégrateurs certifiés).

### Format d'erreurs lisibles

- [ ] AC-10 — Chaque erreur retournée a la structure : `{ path: string (ex: '.actions.creer_produit.handler'), message: string (FR), code: string (ex: 'invalid_pattern'), received?: any }`.
- [ ] AC-11 — Le `path` est un dot-path standard depuis la racine du payload (jamais un index absolu Zod brut comme `[1, 'actions', 'creer_produit']`).
- [ ] AC-12 — Le `message` est en français, sans jargon Zod (pas de `Expected string, received number` brut). Mapping custom des codes Zod vers messages FR.
- [ ] AC-13 — Test : un payload avec 3 erreurs distinctes retourne les 3 erreurs (pas seulement la première).

### Pipe NestJS

- [ ] AC-14 — `ZodValidationPipe<T>` exporté, signature `new ZodValidationPipe(ModuleConfigZod)` puis `@UsePipes(...)` ou `@Body(new ZodValidationPipe(...))`.
- [ ] AC-15 — Le pipe rejette avec `BadRequestException` 400 et la même structure d'erreurs lisibles (pas d'erreur Zod brute exposée au client).
- [ ] AC-16 — Documentation OpenAPI auto reflète les schémas (via decorator `@ApiBody` ou intégration nestjs-zod si pertinent).

### Validation au démarrage NestJS (CatalogueLoaderService)

- [ ] AC-17 — Au démarrage NestJS, `CatalogueLoaderService.onApplicationBootstrap()` parcourt `catalog/domains/`, `catalog/modules/`, `catalog/fusions/` et valide chaque JSON.
- [ ] AC-18 — Si un fichier invalide → log structuré `catalogue.invalid` avec path + erreurs ET le bootstrap échoue (l'app ne démarre pas, status code ≠ 0).
- [ ] AC-19 — Si tous valides → log `catalogue.loaded` avec compte par type.

### CI catalog validation

- [ ] AC-20 — `.github/workflows/validate-catalogue.yml` se déclenche sur PR touchant `catalog/**`.
- [ ] AC-21 — Script `scripts/validate-catalogue.ts` (Bun) parcourt récursivement, valide chaque fichier, sort en erreur (exit 1) si un fichier invalide. Output formaté lisible (couleurs en TTY, plain en CI).

### Tests

- [ ] AC-22 — Tests unitaires Jest ≥ 90% coverage sur `src/catalogue/validators/`. Pour chaque schéma : ≥ 3 cas valides + ≥ 3 cas invalides typés différemment (champ manquant, mauvais type, pattern violé, récursion invalide).

---

## Technical Notes

### Composants concernés

- **Nouveau module NestJS :** `backend/nestjs/src/catalogue/`.
- **Nouveau script :** `scripts/validate-catalogue.ts` (Bun).
- **Nouveau workflow CI :** `.github/workflows/validate-catalogue.yml`.

### Structure de fichiers (cible)

```
backend/nestjs/src/catalogue/
├── catalogue.module.ts
├── catalogue.controller.ts                   # POST /admin/templates/validate
├── services/
│   ├── catalogue-loader.service.ts           # Bootstrap loader + cache
│   └── catalogue-validator.service.ts        # Wrap Zod + format errors
├── validators/
│   ├── index.ts
│   ├── component-config.zod.ts
│   ├── screen-config.zod.ts
│   ├── module-config.zod.ts
│   ├── workflow.zod.ts
│   ├── rule.zod.ts
│   └── action-definition.zod.ts
├── pipes/
│   └── zod-validation.pipe.ts
├── errors/
│   └── validation-error.formatter.ts         # FR messages mapping
├── dto/
│   └── validate-template.dto.ts
└── __tests__/
    ├── component-config.zod.spec.ts
    ├── module-config.zod.spec.ts
    ├── rule.zod.spec.ts
    ├── catalogue-loader.spec.ts
    └── zod-validation.pipe.spec.ts

scripts/
└── validate-catalogue.ts

.github/workflows/
└── validate-catalogue.yml
```

### Code patterns (TypeScript)

**`rule.zod.ts` — récursivité via lazy :**

```typescript
import { z } from 'zod';

const OPERATORS = ['AND', 'OR', 'role', '>', '<', '==', '!=', '>=', '<=', 'in', 'not_in'] as const;

export type Rule = z.infer<typeof RuleZod>;

export const RuleZod: z.ZodType<Rule> = z.lazy(() =>
  z.discriminatedUnion('operator', [
    z.object({
      operator: z.enum(['AND', 'OR']),
      children: z.array(RuleZod).min(1, 'children doit contenir au moins 1 règle'),
    }),
    z.object({
      operator: z.literal('role'),
      value: z.array(z.string()).min(1, 'value doit contenir au moins un rôle'),
    }),
    z.object({
      operator: z.enum(['>', '<', '==', '!=', '>=', '<=', 'in', 'not_in']),
      field: z.string().min(1),
      value: z.unknown(),
    }),
  ]),
);
```

**`zod-validation.pipe.ts` :**

```typescript
@Injectable()
export class ZodValidationPipe<T extends z.ZodTypeAny> implements PipeTransform {
  constructor(
    private readonly schema: T,
    private readonly formatter = new ValidationErrorFormatter(),
  ) {}

  transform(value: unknown): z.infer<T> {
    const result = this.schema.safeParse(value);
    if (!result.success) {
      throw new BadRequestException({
        valid: false,
        errors: this.formatter.format(result.error),
      });
    }
    return result.data;
  }
}
```

**`validation-error.formatter.ts` — mapping FR :**

```typescript
const FR_MESSAGES: Record<string, (issue: z.ZodIssue) => string> = {
  invalid_type: (i) =>
    `doit être de type ${i.expected}. Reçu: ${i.received}.`,
  too_small: (i) =>
    `doit contenir au moins ${(i as any).minimum} ${(i as any).type === 'array' ? 'élément(s)' : 'caractère(s)'}.`,
  too_big: (i) =>
    `doit contenir au plus ${(i as any).maximum} ${(i as any).type === 'array' ? 'élément(s)' : 'caractère(s)'}.`,
  invalid_string: (i) => {
    if ((i as any).validation === 'regex') return `ne respecte pas le format attendu.`;
    return `chaîne invalide.`;
  },
  invalid_enum_value: (i) =>
    `doit être l'une des valeurs : ${(i as any).options?.join(', ')}. Reçu: ${(i as any).received}.`,
  unrecognized_keys: (i) =>
    `clé(s) inconnue(s) : ${(i as any).keys?.join(', ')}.`,
  custom: (i) => i.message,
};

export class ValidationErrorFormatter {
  format(error: z.ZodError): ValidationErrorList {
    return error.issues.map((issue) => ({
      path: '.' + issue.path.join('.'),
      message: (FR_MESSAGES[issue.code] ?? ((i) => i.message))(issue),
      code: issue.code,
      received: 'received' in issue ? (issue as any).received : undefined,
    }));
  }
}
```

**Bootstrap loader :**

```typescript
@Injectable()
export class CatalogueLoaderService implements OnApplicationBootstrap {
  private readonly logger = new Logger(CatalogueLoaderService.name);

  async onApplicationBootstrap(): Promise<void> {
    const root = process.env.CATALOG_ROOT ?? path.resolve('catalog');
    const failures: { file: string; errors: ValidationErrorList }[] = [];
    let loaded = { domains: 0, modules: 0, fusions: 0 };

    for (const [type, dir] of [
      ['module' as const, 'domains'],
      ['module' as const, 'modules'],
      ['module' as const, 'fusions'],
    ]) {
      for (const file of await glob(path.join(root, dir, '**/*.json'))) {
        const content = JSON.parse(await fs.readFile(file, 'utf8'));
        const result = ModuleConfigZod.safeParse(content);
        if (!result.success) {
          failures.push({ file, errors: this.formatter.format(result.error) });
        } else {
          loaded[dir as keyof typeof loaded]++;
        }
      }
    }

    if (failures.length > 0) {
      this.logger.error('catalogue.invalid', { failures });
      throw new Error(`Catalogue invalid: ${failures.length} fichier(s) en erreur. App refuse de démarrer.`);
    }
    this.logger.log('catalogue.loaded', loaded);
  }
}
```

### Edge cases

- **`additionalProperties: false` côté JSON Schema** ↔ `.strict()` côté Zod : les deux doivent matcher. `props` et `query` sont permissifs (`.passthrough()`).
- **`schema_version` const "1.0.0"`** : Zod `z.literal('1.0.0')`. Quand on bumpe, on duplique en `module-config.v1_1_0.zod.ts` ou on accepte plusieurs versions via `z.union([z.literal('1.0.0'), z.literal('1.1.0')])`.
- **Double validation pour un même payload** : un `POST /:moduleId/action` (STORY-022) peut passer par 2 pipes (un sur `body` générique, un downstream sur `payload` spécifique action). Zod composable, OK.
- **Performance bootstrap** : si 100 fichiers `catalog/`, validation séquentielle Zod ≈ 50-200 ms. Acceptable. Pour Phase 2, paralléliser via `Promise.all`.
- **JSON corrompu (parse error)** : capture `try/catch` autour de `JSON.parse` → erreur formatée différente (`{ path: '', message: 'JSON syntaxe invalide à ligne X' }`).

### Sécurité

- **Endpoint validate guarded** — sans guard, un attaquant peut envoyer 100 Mo de JSON et DoSer le validator. JwtAuthGuard + role check + body size limit (1 MB par défaut NestJS, à confirmer).
- **Le payload validé n'est jamais stocké** — endpoint pure validation, lecture seule. Pas de side-effect.
- **Messages d'erreur ne leakent jamais d'info système** — pas de stack trace, pas de path filesystem absolu. Path JSON purement logique.
- **Loader bootstrap fail-fast** — si un fichier `catalog/` est compromis ou cassé, le service refuse de démarrer plutôt que de servir un état partiel. Choix sécurité > disponibilité.

---

## Dependencies

**Prérequis :**

- STORY-023 — JSON Schema BDUI v1.0.0 (le miroir Zod en dérive).
- STORY-014 — NestJS bootstrap (le module catalogue s'y enregistre).

**Stories bloquées par celle-ci :**

- STORY-021 (BDUIService) — utilise `CatalogueLoaderService` et `ZodValidationPipe`.
- STORY-022 (ModuleEngine) — idem ; valide les payloads d'actions via les pipes générées dynamiquement.
- STORY-025 (Structure catalogue + README) — référence le workflow CI catalog-validate.
- STORY-026 (validation bidirectionnelle Flutter) — le contrat doit être identique.
- STORY-029-030 (Workflow engine) — valide les `WorkflowDefinition`.

**Externes :**

- `zod` (npm, déjà prévu dans tech stack — cf archi ligne 184).

---

## Definition of Done

- [ ] Code commité sur `feat/story-024-zod-validator`.
- [ ] `bun run lint` 0 erreur sur `src/catalogue/`.
- [ ] `bun test src/catalogue --coverage` ≥ 90%.
- [ ] Workflow CI `validate-catalogue.yml` opérationnel — testé via une PR avec un JSON volontairement invalide → CI rouge avec message lisible.
- [ ] Endpoint `POST /admin/templates/validate` documenté dans OpenAPI.
- [ ] Exemple d'utilisation du `ZodValidationPipe` dans la PR (sample dans un test ou commentaire).
- [ ] Bootstrap NestJS : test manuel — corrompre un fichier `catalog/` → l'app refuse de démarrer avec log explicite.
- [ ] PR review (`/codex review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-024 status `completed`, sprint 3 completed_points += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Schémas Zod (5 fichiers) miroir 1-pour-1 du JSON Schema | 1 | Mécanique, mais soin sur la récursivité Rule. |
| Endpoint `POST /admin/templates/validate` + DTO | 0.25 | Trivial une fois les schémas prêts. |
| `ZodValidationPipe` réutilisable | 0.25 | Pattern standard NestJS. |
| `ValidationErrorFormatter` FR | 0.5 | Mapping codes Zod → messages FR + tests. |
| `CatalogueLoaderService` bootstrap fail-fast | 0.5 | Glob + parse + validate + log. |
| Script CI `validate-catalogue.ts` + workflow GH Actions | 0.25 | Wrap loader en CLI. |
| Tests unitaires (≥ 90% coverage) | 0.25 | Cas valides + invalides par schéma. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** Le travail est dérivé de STORY-023 — donc déjà cadré. La complexité est dans la **discipline du miroir** et la **qualité des messages FR**. Pas d'inconnues techniques, mais besoin de soin pour ne pas livrer "Zod brut" à des intégrateurs non-devs.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` §Composant 10 (CatalogueService, lignes 642-660) + PRD §FR-014.
- **Pourquoi Zod manuel et pas auto-généré (json-schema-to-zod) ?** Phase 1 : on accepte la duplication contrôlée — ça permet d'ajouter des `refine` custom (validations métier que JSON Schema ne peut exprimer, ex: cohérence entre `ActionDefinition.handler` et `entity_type`). Phase 2 : si la duplication coûte, basculer sur génération automatique. Tracker comme dette tech.
- **Refines métier intéressants à ajouter :**
  - `ModuleConfig.actions[*].handler` ↔ champs requis : si `crud.create`, alors `entity_type` requis. Si `workflow.advance`, alors `workflow_id` + `transition` requis. → `z.refine` custom dans `module-config.zod.ts`.
  - `WorkflowDefinition.initial_state` doit être une clé de `states`. → `refine`.
- **i18n future :** Phase 2 on internationalisera les messages d'erreur (FR par défaut, EN sur demande). Phase 1 = FR only.
- **Limit de payload :** par défaut NestJS `body-parser` accepte ~100 KB. Pour valider un module complet (potentiellement 200+ KB JSON), augmenter à 5 MB max via `app.useBodyParser('json', { limit: '5mb' })`. À configurer dans STORY-014 (si pas déjà fait) ou en étendant ici.
- **Cache des schémas Zod :** les instances `RuleZod`, `ModuleConfigZod` sont des singletons module-scope (Zod compile à la première utilisation). Pas de re-compilation par requête.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
