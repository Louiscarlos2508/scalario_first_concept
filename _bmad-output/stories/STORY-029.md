# STORY-029 : DAG Validator — Kahn's Algorithm

**Epic :** EPIC-005 — Workflow DAG Engine
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-024 (Zod Validator + pipeline de validation templates)

---

## User Story

> **En tant que** système Scalario,
> **je veux** valider qu'un workflow déclaré en JSON est un DAG bien formé (acyclique, connexe, sans étape inaccessible) avant tout déploiement et avant chaque exécution,
> **so that** un workflow cassé soit refusé au moment du déploiement (CI + admin) et jamais activé en production — aucune boucle infinie, aucune étape morte, aucun nœud orphelin.

---

## Description

### Background

EPIC-005 livre le moteur qui exécute n'importe quel workflow métier (clôture caisse, validation arrivage, validation commande) **sans coder une ligne de logique métier dans le backend**. Tout est déclaré en JSON dans le catalogue tenant.

La règle non-négociable de Scalario : **aucune logique métier dans le moteur**. Le moteur valide la structure (cette story), exécute les étapes (STORY-030), gère les transitions d'état (STORY-031) et s'intègre au ModuleEngine (STORY-032). Si le JSON est cassé, c'est l'intégrateur qui le corrige — le moteur ne devine pas.

Cette story est la fondation de l'EPIC : **un workflow non validé ne s'exécute jamais**. La validation est :
- **Au build / CI** : tout JSON ajouté au catalogue passe `validateWorkflow()`.
- **Au déploiement tenant** : `POST /admin/templates/validate` rejette les workflows invalides.
- **Au runtime, juste avant exécution** : ceinture + bretelles — si une config a été pushée hors pipeline, l'exécuteur (STORY-030) refuse de démarrer.

### Scope

**In scope :**

- Module NestJS `backend/nestjs/src/workflow/` avec sous-dossier `validator/`.
- Service `WorkflowValidatorService` exposant `validateDAG(steps: WorkflowStep[]): ValidationResult`.
- Algorithme Kahn (tri topologique) implémenté en TypeScript pur, zéro dépendance externe (pas de `graphlib`).
- Détection de **cycle** (Kahn termine avec des nœuds restants ⇒ cycle) avec extraction des nœuds en cycle.
- Détection d'**étapes orphelines** (référencées dans `dependsOn` mais inexistantes) et d'**étapes inaccessibles** (jamais atteignables depuis un point d'entrée).
- Détection des **points d'entrée** (étapes sans `dependsOn`) et des **étapes terminales** (sans successeur).
- Intégration au pipeline `POST /admin/templates/validate` (STORY-024) : la validation Zod passe ⇒ on enchaîne sur la validation DAG pour chaque workflow contenu dans le template.
- Intégration au pipeline CI (`.github/workflows/validate-catalogue.yml`) — la validation DAG tourne pour chaque template du catalogue à chaque PR.
- Messages d'erreur lisibles par un intégrateur non-dev (FR — `"Workflow 'cloture_caisse' : étape 'reconciliation' référence une étape inexistante 'foo'"`).
- Tests unitaires Jest avec ≥ 95% coverage sur `validator/`.

**Out of scope (autres stories) :**

- Exécution effective du workflow → STORY-030.
- State Machine XState pour transitions d'états → STORY-031.
- Glue ModuleEngine ↔ WorkflowExecutor → STORY-032.
- Visualisation graphique du DAG (Mermaid render dans l'admin) → backlog post-Gate 0.
- Validation des `condition` / `params` de chaque step (couvert par Zod via STORY-023/024).

### Pipeline de validation (où la story s'insère)

1. **CI** : intégrateur ouvre une PR ajoutant `catalog/domains/retail_fresh_produce.json`.
2. GitHub Actions (`validate-catalogue.yml`) : Zod schema (STORY-024) ⇒ structure JSON OK ⇒ **`WorkflowValidatorService.validateDAG()`** sur chaque workflow ⇒ vert.
3. **Admin runtime** : `POST /api/v1/admin/templates/validate` enchaîne Zod + DAG ⇒ retourne `{ valid: true | false, errors: [...] }`.
4. **Provisioning tenant** : `CatalogueService.loadTemplate(tenant_id, template_path)` re-valide le DAG avant insertion en DB.
5. **Runtime exécution** (STORY-030) : avant `WorkflowExecutor.run()`, la dernière barrière appelle `validateDAG()` sur le snapshot config tenant.

---

## Acceptance Criteria

### Algorithme Kahn

- [ ] AC-01 — `WorkflowValidatorService.validateDAG(steps: WorkflowStep[]): ValidationResult` implémenté en TypeScript pur dans `backend/nestjs/src/workflow/validator/workflow-validator.service.ts`. Aucune dépendance graphe externe.
- [ ] AC-02 — L'algorithme construit la map d'in-degrees, collecte les nœuds à in-degree 0, les retire un par un en décrémentant les in-degrees des successeurs (Kahn classique).
- [ ] AC-03 — Si tous les nœuds sont retirés ⇒ DAG valide, retourne `{ valid: true, sortedSteps: string[] }` avec l'ordre topologique.
- [ ] AC-04 — Si des nœuds restent en fin d'algorithme ⇒ cycle détecté ⇒ retourne `{ valid: false, errors: [{ code: 'WF_CYCLE', cyclicSteps: string[] }] }` avec la liste exhaustive des étapes impliquées dans un (ou plusieurs) cycle(s).

### Détection de défauts structurels

- [ ] AC-05 — **Étape orpheline** (`dependsOn` référence une `id` inexistante dans `steps`) ⇒ erreur `WF_UNKNOWN_DEPENDENCY` avec `step_id` et `missing_dependency_id`.
- [ ] AC-06 — **Étape inaccessible** (aucun chemin depuis un point d'entrée ⇒ in-degree > 0 mais pas de prédécesseur valide) ⇒ erreur `WF_UNREACHABLE` avec `step_id`. Cas typique : faute de frappe dans `dependsOn` qui rompt la chaîne.
- [ ] AC-07 — **Aucun point d'entrée** (toutes les étapes ont `dependsOn` non vide) ⇒ erreur bloquante `WF_NO_ENTRY_POINT`.
- [ ] AC-08 — **IDs dupliquées** (deux steps avec la même `id`) ⇒ erreur `WF_DUPLICATE_ID` avec l'`id` fautive (premier check avant Kahn).
- [ ] AC-09 — **Self-loop** (une step se dépend d'elle-même, `dependsOn` contient son propre `id`) ⇒ erreur `WF_SELF_LOOP` avec `step_id` (cas particulier de cycle, message dédié).

### Contrat & Types

- [ ] AC-10 — Type `WorkflowStep` réutilise / étend le contrat partagé de `packages/shared-contracts` :

  ```typescript
  interface WorkflowStep {
    id: string;
    type: 'action' | 'condition' | 'notification' | 'approval';
    dependsOn?: string[];     // [] ou absent ⇒ point d'entrée
    next?: string | ConditionalNext;
    action?: string;
    params?: Record<string, unknown>;
    condition?: { field: string; op: '>' | '<' | '==' | '!='; value: unknown };
  }
  ```

- [ ] AC-11 — Type `ValidationResult` :

  ```typescript
  type ValidationResult =
    | { valid: true; sortedSteps: string[]; entryPoints: string[]; terminalSteps: string[] }
    | { valid: false; errors: WorkflowValidationError[] };

  interface WorkflowValidationError {
    code: 'WF_CYCLE' | 'WF_UNKNOWN_DEPENDENCY' | 'WF_UNREACHABLE'
        | 'WF_NO_ENTRY_POINT' | 'WF_DUPLICATE_ID' | 'WF_SELF_LOOP';
    message: string;        // FR, lisible intégrateur
    stepId?: string;
    cyclicSteps?: string[];
    missingDependencyId?: string;
    workflowId: string;     // resolu par l'appelant
  }
  ```

### Intégration pipeline

- [ ] AC-12 — `POST /api/v1/admin/templates/validate` (STORY-024) chaîne : Zod ⇒ `WorkflowValidatorService.validateDAG()` pour chaque workflow contenu dans le template ⇒ retourne agrégat `{ valid, errors[] }` avec `workflow_id` qualifié.
- [ ] AC-13 — `CatalogueService.loadTemplate()` rejette le template (transaction rollback) si un workflow n'est pas un DAG valide. Aucune ligne `screen_configs` / `workflow_states` n'est insérée.
- [ ] AC-14 — Étape CI dans `.github/workflows/validate-catalogue.yml` qui exécute la validation DAG sur **tous** les workflows présents dans `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`. Échec ⇒ PR bloquée.
- [ ] AC-15 — Hook runtime dans `WorkflowExecutor` (STORY-030) — la story-30 appellera `validateDAG()` avant `run()` ; cette story-29 expose le service et garantit que l'appel est < 5ms p95 sur un workflow de 20 étapes.

### Performance

- [ ] AC-16 — Benchmark Jest : un workflow de 20 étapes ⇒ `validateDAG()` < 5ms p95 sur CI runner standard. Un workflow de 100 étapes ⇒ < 20ms p95.
- [ ] AC-17 — Pas d'allocation excessive : algorithme en `O(V + E)` (tri topologique linéaire), `Map<string, number>` pour in-degrees, `Set<string>` pour visited. Pas de récursion (stack-safe pour gros workflows).

### Tests

- [ ] AC-18 — Tests unitaires `workflow-validator.service.spec.ts` couvrent les cas suivants (chacun ⇒ test dédié, **pas** un seul gros test) :
  - DAG linéaire valide (`A → B → C`) ⇒ `valid: true`, ordre `[A, B, C]`.
  - DAG branche parallèle (`A → B`, `A → C`, `B → D`, `C → D`) ⇒ `valid: true`, D dernier.
  - Cycle simple (`A → B → A`) ⇒ `WF_CYCLE` avec `cyclicSteps: ['A', 'B']`.
  - Cycle complexe (`A → B → C → D → B`) ⇒ `WF_CYCLE` avec `cyclicSteps: ['B', 'C', 'D']` (A hors cycle).
  - Self-loop (`A → A`) ⇒ `WF_SELF_LOOP`.
  - Dépendance inexistante (`A → ZZ`) ⇒ `WF_UNKNOWN_DEPENDENCY` avec `missingDependencyId: 'ZZ'`.
  - Étape inaccessible (composant déconnecté `A → B` + `X → Y` sans lien) ⇒ pas une erreur en soi (deux DAGs valides). Si une seule étape sans entrée et sans connexion ⇒ `WF_UNREACHABLE`.
  - IDs dupliquées (`[{id: 'A'}, {id: 'A'}]`) ⇒ `WF_DUPLICATE_ID`.
  - Aucun point d'entrée (`A → B → A` + tout a `dependsOn`) ⇒ `WF_NO_ENTRY_POINT` (avant Kahn) ou `WF_CYCLE` (selon l'ordre des checks — choisir et documenter).
  - **Workflow réel** : `workflow_cloture_caisse` du PRD (`saisie_fond_restant → reconciliation → validation_manager → cloture_confirmee`) ⇒ valide, ordre attendu.
- [ ] AC-19 — Coverage `validator/` ≥ 95%. Branches couvertes ≥ 90%.
- [ ] AC-20 — Test E2E `templates-validate.e2e-spec.ts` : `POST /admin/templates/validate` avec un template embarquant un workflow circulaire ⇒ HTTP 422 + body `{ valid: false, errors: [{ code: 'WF_CYCLE', ... }] }`.

---

## Technical Notes

### Composants concernés

- **Nouveau module NestJS :** `backend/nestjs/src/workflow/` (créé par cette story, base pour STORY-030/031/032).
- **Sous-dossier validator :** `backend/nestjs/src/workflow/validator/`.
- **Touche :** `backend/nestjs/src/catalogue/` (intégration validation pipeline) — ajout d'un appel chaîné, pas de refactor.
- **Touche :** `.github/workflows/validate-catalogue.yml` — ajout d'une étape.

### Structure de fichiers (cible)

```
backend/nestjs/src/workflow/
├── workflow.module.ts                       # NestJS Module (exporte WorkflowValidatorService)
├── validator/
│   ├── workflow-validator.service.ts        # validateDAG() — Kahn's algorithm
│   ├── workflow-validator.types.ts          # ValidationResult, WorkflowValidationError
│   ├── kahn.ts                              # algorithme pur (testable isolé)
│   └── __tests__/
│       ├── workflow-validator.service.spec.ts
│       └── kahn.spec.ts
└── __fixtures__/
    ├── valid-cloture-caisse.ts              # fixture workflow cloture caisse
    ├── cycle-simple.ts
    ├── cycle-complex.ts
    └── orphan-dependency.ts
```

### Implémentation Kahn (référence)

```typescript
// kahn.ts — algorithme pur, pas de dépendance NestJS
export interface KahnResult {
  ok: boolean;
  sorted: string[];          // ordre topologique si ok
  remaining: string[];       // nœuds en cycle si !ok
}

export function kahnTopologicalSort(
  nodes: string[],
  edges: ReadonlyArray<readonly [string, string]>, // [from, to]
): KahnResult {
  const inDegree = new Map<string, number>(nodes.map((n) => [n, 0]));
  const adj = new Map<string, string[]>(nodes.map((n) => [n, []]));

  for (const [from, to] of edges) {
    adj.get(from)!.push(to);
    inDegree.set(to, (inDegree.get(to) ?? 0) + 1);
  }

  const queue: string[] = [];
  for (const [n, deg] of inDegree) if (deg === 0) queue.push(n);

  const sorted: string[] = [];
  while (queue.length > 0) {
    const n = queue.shift()!;
    sorted.push(n);
    for (const next of adj.get(n) ?? []) {
      const d = (inDegree.get(next) ?? 0) - 1;
      inDegree.set(next, d);
      if (d === 0) queue.push(next);
    }
  }

  if (sorted.length === nodes.length) {
    return { ok: true, sorted, remaining: [] };
  }
  const remaining = [...inDegree.entries()]
    .filter(([, d]) => d > 0)
    .map(([n]) => n);
  return { ok: false, sorted: [], remaining };
}
```

### Service NestJS (référence)

```typescript
@Injectable()
export class WorkflowValidatorService {
  validateDAG(workflowId: string, steps: WorkflowStep[]): ValidationResult {
    const errors: WorkflowValidationError[] = [];

    // 1. Duplicates
    const ids = new Set<string>();
    for (const s of steps) {
      if (ids.has(s.id)) {
        errors.push({ code: 'WF_DUPLICATE_ID', stepId: s.id, workflowId,
          message: `Workflow '${workflowId}' : étape '${s.id}' déclarée plusieurs fois.` });
      }
      ids.add(s.id);
    }

    // 2. Unknown dependencies + self-loops
    for (const s of steps) {
      for (const dep of s.dependsOn ?? []) {
        if (dep === s.id) {
          errors.push({ code: 'WF_SELF_LOOP', stepId: s.id, workflowId,
            message: `Workflow '${workflowId}' : étape '${s.id}' se dépend d'elle-même.` });
        } else if (!ids.has(dep)) {
          errors.push({ code: 'WF_UNKNOWN_DEPENDENCY', stepId: s.id,
            missingDependencyId: dep, workflowId,
            message: `Workflow '${workflowId}' : étape '${s.id}' dépend de '${dep}' qui n'existe pas.` });
        }
      }
    }

    if (errors.length > 0) return { valid: false, errors };

    // 3. Kahn
    const nodes = steps.map((s) => s.id);
    const edges = steps.flatMap((s) =>
      (s.dependsOn ?? []).map((d) => [d, s.id] as const));
    const result = kahnTopologicalSort(nodes, edges);

    if (!result.ok) {
      return { valid: false, errors: [{
        code: 'WF_CYCLE', cyclicSteps: result.remaining, workflowId,
        message: `Workflow '${workflowId}' : cycle détecté impliquant [${result.remaining.join(', ')}].`
      }]};
    }

    const entryPoints = steps.filter((s) => !s.dependsOn?.length).map((s) => s.id);
    if (entryPoints.length === 0) {
      return { valid: false, errors: [{
        code: 'WF_NO_ENTRY_POINT', workflowId,
        message: `Workflow '${workflowId}' : aucun point d'entrée (toutes les étapes ont des dépendances).`
      }]};
    }

    const terminalSteps = nodes.filter((n) =>
      !edges.some(([from]) => from === n));

    return { valid: true, sortedSteps: result.sorted, entryPoints, terminalSteps };
  }
}
```

### Fixture clôture caisse (référence)

```typescript
export const clotureCaisseFixture: WorkflowStep[] = [
  { id: 'saisie_fond_restant', type: 'action',       action: 'open_form_fond' },
  { id: 'reconciliation',      type: 'action',       dependsOn: ['saisie_fond_restant'], action: 'compute_diff' },
  { id: 'validation_manager',  type: 'approval',     dependsOn: ['reconciliation'] },
  { id: 'cloture_confirmee',   type: 'notification', dependsOn: ['validation_manager'], action: 'notify_owner' },
];
```

### Edge cases

- **Workflow vide (`steps: []`)** : valide ? Décision : **non**, retourne `WF_NO_ENTRY_POINT`. Un workflow déclaré doit avoir au moins une étape — sinon l'intégrateur ne devrait pas le déclarer.
- **Plusieurs composants connexes (deux DAGs disjoints dans le même workflow)** : autorisé ? Décision : **oui** (cas légitime — workflow avec branches indépendantes lancées en parallèle, jointes plus tard ou non). Pas d'erreur tant que chaque composant a un point d'entrée.
- **Step sans `next` ni `dependsOn` descendant** : c'est un terminal step, OK. Pas une erreur.
- **`ConditionalNext` (next dynamique selon condition)** : n'impacte pas le DAG (les targets de `ConditionalNext` doivent toutes être déclarées dans `steps`, vérifié comme pour `dependsOn`). À couvrir par AC-05 généralisé : « toute référence d'`id` inconnue déclenche `WF_UNKNOWN_DEPENDENCY` ».

### Spec source — résolution conflit PRD ↔ DS

Pas de conflit ici. Le PRD (FR-018) et l'architecture (Composant 7) s'alignent : Kahn pour validation, XState pour exécution. Cette story implémente uniquement la moitié validation — XState arrive STORY-031.

**Détail à noter :** le PRD STORY-029 mentionne `dependsOn` et `next`. L'architecture mentionne `next`. **Décision pour cette story : `dependsOn` est la source primaire** (plus naturelle pour Kahn — graphe implicite par dépendances). `next` reste utilisable pour exécution (STORY-030) mais le DAG est dérivé de `dependsOn` ici. Documenter dans le code que `next: string` génère implicitement un edge `current → next` (pour rétrocompatibilité des workflows simples linéaires).

### Sécurité

- Pas d'entrée utilisateur directe — la validation est appelée sur des workflows déjà passés par Zod (STORY-024) qui rejette les tailles excessives. Pas de risque DoS via JSON géant.
- Pas de logs des contenus métier — uniquement les `id` des steps et codes d'erreur. Pas de PII possible (les workflows sont des structures techniques).
- Le service est interne (pas d'endpoint direct exposé) — seul `POST /admin/templates/validate` (déjà gardé par RBAC ADMIN dans STORY-024) le déclenche.

---

## Dependencies

**Prérequis :**

- STORY-013 (Monorepo + NestJS) — module NestJS opérationnel.
- STORY-023 (JSON Schema BDUI v1.0.0) — type `WorkflowStep` figé.
- STORY-024 (Zod Validator + `POST /admin/templates/validate`) — pipeline d'orchestration que cette story enrichit.

**Stories bloquées par celle-ci :**

- STORY-030 (Workflow Executor) — exécution suppose un DAG validé.
- STORY-031 (XState State Machine) — la FSM est générée après validation DAG.
- STORY-032 (Integration Workflow ↔ ModuleEngine) — indirect via 030/031.
- STORY-041 (Workflow DAG Clôture Caisse) — utilise cette validation pour son AC `DAG validé — 0 cycle`.

**Externes :**

- Aucune librairie externe pour Kahn — implémentation TypeScript interne.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-029-dag-validator`.
- [ ] `npm run lint` (ESLint NestJS) passe sans warning sur `backend/nestjs/src/workflow/`.
- [ ] `npm run test workflow` vert avec ≥ 95% coverage sur `src/workflow/validator/`.
- [ ] Test E2E `templates-validate.e2e-spec.ts` vert (validation DAG via API admin).
- [ ] Étape CI `validate-catalogue.yml` ajoutée et verte sur la branche.
- [ ] Fixture `clotureCaisseFixture` validée — sera réutilisée par STORY-030/031/041.
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-029 status `completed`, completed_points sprint 3 += 5. (Hors scope de cette story d'écriture — fait à l'implémentation.)

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Setup module NestJS `workflow/` + `WorkflowModule` + DI | 0.5 | Boilerplate NestJS standard. |
| `kahn.ts` algorithme pur + tests isolés | 1 | Cœur algorithmique, doit être stack-safe et `O(V+E)`. |
| `WorkflowValidatorService` (orchestration : duplicates → unknown deps → Kahn → entry points) | 1 | Logique d'agrégation des erreurs avec messages FR. |
| Types `ValidationResult` / `WorkflowValidationError` + alignement avec `shared-contracts` | 0.5 | Petit mais critique — impacte 030/031/032. |
| Intégration `POST /admin/templates/validate` chaîné après Zod | 0.5 | Glue dans `catalogue.service.ts`. |
| Étape CI `validate-catalogue.yml` | 0.5 | YAML + script Node qui parcourt `catalog/`. |
| Tests unitaires (10+ cas) + fixtures + benchmark perf | 1 | Le filet — tous les patterns d'erreur listés AC-18. |
| **Total** | **5** | Fibonacci 5 — moderate avec algorithmique non triviale. |

**Rationale :** Kahn est un algorithme bien connu mais sa correction (cycle vs non-cycle, détection des nœuds en cycle, gestion des composants connexes multiples) demande des tests soignés. La taxonomie des erreurs (`WF_CYCLE`, `WF_UNKNOWN_DEPENDENCY`, `WF_UNREACHABLE`, `WF_NO_ENTRY_POINT`, `WF_DUPLICATE_ID`, `WF_SELF_LOOP`) est ce qui rend le système actionnable pour l'intégrateur — sous-estimer ce travail = renvoyer `false` sans contexte, ce qui force le débuggage manuel à chaque template cassé.

---

## Notes additionnelles

- **Conflit PRD ↔ DS :** néant pour cette story. Pas de surface UI exposée.
- **Convention erreur** : tous les codes d'erreur préfixés `WF_*` — cohérent avec les codes ABAC (`ABAC_*`) et RBAC (`RBAC_*`) des autres stories sécurité.
- **i18n** : les messages d'erreur sont écrits en FR car la cible Phase 1 est UEMOA (BF + intégrateurs locaux). Une indirection `i18n_key` peut être ajoutée plus tard sans casser le contrat (les codes restent stables).
- **Pas de logique métier dans le moteur** : cette story respecte la règle — elle ne sait pas qu'un workflow s'appelle `cloture_caisse`, ne valide aucun champ business, ne lit aucune table métier. Elle valide uniquement la topologie d'un graphe abstrait. Les fixtures cloture caisse sont pour les tests, pas pour la logique du service.
- **Visualisation DAG (Mermaid)** : non couvert ici. À envisager dans un futur outil admin (`/admin/templates/:id/visualize` qui génère un diagramme Mermaid depuis l'ordre Kahn) — backlog post-Gate 0.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
