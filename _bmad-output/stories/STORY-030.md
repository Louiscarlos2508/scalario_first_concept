# STORY-030 : Workflow Executor

**Epic :** EPIC-005 — Workflow DAG Engine
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-029 (DAG Validator), STORY-022 (ModuleEngine endpoints — interface stable)

---

## User Story

> **En tant que** système Scalario,
> **je veux** exécuter un workflow déclaré en JSON dans l'ordre topologique d'un DAG validé, avec gestion des conditions, des branches parallèles, de la persistance d'état et des retries sur erreur transitoire,
> **so that** n'importe quel workflow métier (clôture caisse, validation arrivage, validation commande, réapprovisionnement) tourne en production **sans qu'aucune ligne de logique métier ne soit codée dans le backend** — uniquement déclarée.

---

## Description

### Background

STORY-029 garantit qu'un workflow JSON est un DAG bien formé. Cette story livre **l'exécuteur** : prendre un DAG validé + un contexte initial (entité métier, params utilisateur), parcourir les étapes dans l'ordre topologique, évaluer les conditions, déclencher les actions, persister l'état après chaque étape, retry sur échec transitoire.

C'est le coeur opérationnel de l'EPIC-005 — sans lui, aucun workflow ne s'exécute. La règle non-négociable Scalario est portée à son extrême ici : **le moteur ne sait pas ce qu'est une "clôture caisse"**. Il sait orchestrer un graphe d'étapes typées (`action`, `condition`, `notification`, `approval`). Les actions qu'il déclenche sont des appels au ModuleEngine (STORY-022) ou à des services internes (notifications) — il ne connaît jamais le domaine.

Couplage avec les autres stories de l'EPIC :
- **STORY-029** valide le DAG → cette story l'exécute.
- **STORY-031** modélise les états interactifs (workflows multi-étapes avec gates utilisateur, ex: clôture caisse) en XState — l'exécuteur de cette story-30 peut se mettre en pause sur un step `approval` et la FSM XState gère l'état persistant.
- **STORY-032** glue l'API `POST /:moduleId/action` au runner — un appel `start_workflow` lance l'exécuteur de cette story.

### Scope

**In scope :**

- Service NestJS `WorkflowExecutorService` dans `backend/nestjs/src/workflow/executor/`.
- API publique : `run(input: ExecutionInput): Promise<ExecutionResult>`.
- Parcours topologique d'un DAG validé (réutilise `validateDAG()` de STORY-029 pour la barrière runtime).
- Évaluation de la propriété `condition` de chaque step avant exécution :
  ```json
  { "field": "montant", "op": ">", "value": 500000 }
  ```
- Dispatch des 4 types d'étapes :
  - `action` → appel ModuleEngine (`POST /:moduleId/actions/:actionId`) — détaillé STORY-032.
  - `condition` → évalue, choisit la branche `next.true` ou `next.false`.
  - `notification` → publie sur queue notifications (BullMQ — Phase 1 mock console.log + DB log).
  - `approval` → met le workflow en pause, persist state `awaiting_approval`, retourne (STORY-031 prend le relais).
- Persistance d'état dans `workflow_states` (table existante — voir Architecture §Schéma) :
  - `current_state` : id de l'étape courante (ou `completed`, `failed`, `awaiting_approval`).
  - `history` : array JSONB de `{ step_id, started_at, completed_at, status, output? }`.
- Branches parallèles : si plusieurs steps ont leurs dépendances satisfaites simultanément, l'exécuteur les lance avec `Promise.allSettled` (limite concurrence configurable — défaut 4).
- Retry sur erreur transitoire (timeout, 5xx réseau) : 3 tentatives, backoff exponentiel `[200ms, 500ms, 1500ms]`. Erreur métier (4xx) → pas de retry, propagée.
- Idempotence par step : un step `action` envoie un `client_mutation_id` dérivé de `{workflow_run_id}:{step_id}` — ré-exécuter le même step ne dupliquera pas l'action côté ModuleEngine (STORY-036 garantit l'idempotence).
- Audit log : chaque transition d'étape écrit une entrée dans `audit_logs` (action `workflow.step.completed` / `workflow.step.failed`).
- Tests unitaires + intégration (Jest + supertest) ≥ 90% coverage sur `executor/`.
- Test E2E « clôture caisse » : DAG 4 étapes (`saisie_fond_restant → reconciliation → validation_manager → cloture_confirmee`) exécuté de bout en bout avec mocks ModuleEngine.

**Out of scope (autres stories) :**

- State Machine XState pour les workflows interactifs persistants → STORY-031 (s'enclenche sur les steps `approval`).
- Glue avec endpoint `POST /:moduleId/action` action_type `start_workflow` → STORY-032.
- Workflow Clôture Caisse JSON déclaré dans le template → STORY-041 (utilise cet exécuteur).
- Compensation / rollback transactionnel cross-step (saga) → backlog post-Gate 0. Phase 1 = retry simple ; un step échoué après 3 tentatives ⇒ workflow `failed`, état persistant, intervention manuelle admin.
- UI de suivi exécution (dashboard admin) → backlog post-Gate 0.
- Distribution multi-worker (BullMQ pour exécution asynchrone) → Phase 1 = exécution synchrone in-process, BullMQ uniquement pour les notifications. Distribution en Phase 2 si charge le justifie.

### Modèle d'exécution

```
Input : ExecutionInput {
  tenantId, workflowId, entityId, triggeredBy, initialContext
}
       │
       ▼
1. Charger le workflow JSON depuis la config tenant (cache Redis)
2. WorkflowValidatorService.validateDAG()  ← STORY-029, barrière runtime
3. Initialiser ExecutionContext (mémoire) + workflow_states row (DB)
4. Tant qu'il reste des étapes prêtes (in-degree 0 dans le sous-graphe restant) :
     a. Évaluer condition(s) de l'étape
     b. Si condition false → marquer step `skipped`, descendre à ses successeurs
     c. Si condition true → exécuter via dispatcher selon `step.type`
        - action       → callModuleEngine() avec retry
        - notification → publishNotification() (BullMQ, fire-and-forget tracé)
        - approval     → persist `awaiting_approval`, return (resume via STORY-031)
        - condition    → routing branch
     d. Mettre à jour history[] + current_state
5. Tous steps terminaux atteints → workflow_states.current_state = 'completed'
6. Retour : ExecutionResult { runId, finalState, history }
```

---

## Acceptance Criteria

### Service & API

- [ ] AC-01 — `WorkflowExecutorService.run(input)` exposé dans `backend/nestjs/src/workflow/executor/workflow-executor.service.ts`. Type `ExecutionInput` :

  ```typescript
  interface ExecutionInput {
    tenantId: string;
    workflowId: string;
    entityId?: string;          // entité métier liée (commande, caisse, ...)
    triggeredBy: string;        // user_id
    initialContext: Record<string, unknown>;
  }
  ```

- [ ] AC-02 — Type `ExecutionResult` :

  ```typescript
  interface ExecutionResult {
    runId: string;             // UUID
    workflowId: string;
    finalState: 'completed' | 'failed' | 'awaiting_approval';
    history: StepExecution[];
    error?: { stepId: string; code: string; message: string };
  }
  interface StepExecution {
    stepId: string;
    startedAt: string;         // ISO
    completedAt?: string;
    status: 'pending' | 'running' | 'success' | 'skipped' | 'failed';
    output?: unknown;
    attempts: number;
  }
  ```

- [ ] AC-03 — `run()` appelle `WorkflowValidatorService.validateDAG()` (STORY-029) avant tout. Si invalide → throw `WorkflowInvalidError` (jamais exécuter un DAG cassé même si le pipeline déploiement l'a laissé passer).

### Parcours topologique & branches parallèles

- [ ] AC-04 — Étapes exécutées dans un ordre compatible avec le tri topologique de STORY-029. Une étape ne démarre **jamais** avant que toutes ses dépendances ne soient `success` ou `skipped`.
- [ ] AC-05 — Si plusieurs étapes ont leurs dépendances satisfaites simultanément, elles s'exécutent en parallèle avec `Promise.allSettled`, plafond de concurrence par défaut **4** (configurable via env `WORKFLOW_MAX_CONCURRENCY`).
- [ ] AC-06 — Si une étape parallèle échoue après retry, le workflow attend la fin des autres branches en cours puis passe à `failed` (pas de cancellation Phase 1 — documenté).

### Conditions

- [ ] AC-07 — Évaluation de `step.condition` avant exécution. Opérateurs supportés : `>`, `<`, `==`, `!=`, `>=`, `<=`. Champ résolu depuis `ExecutionContext` via dot-path (ex: `entity.montant`, `context.user.role`).
- [ ] AC-08 — Si `condition` retourne `false` → step `skipped`, descendants peuvent quand même s'exécuter (leur `dependsOn` est satisfaite par un skipped, considéré comme "dépendance résolue").
- [ ] AC-09 — Step de type `condition` avec `next: { true: stepIdA, false: stepIdB }` → seule la branche correspondante est marquée éligible ; les steps de l'autre branche sont marqués `skipped` en cascade (les descendants exclusifs de la branche non choisie).

### Dispatch par type

- [ ] AC-10 — `step.type === 'action'` ⇒ appel HTTP interne (ou injection directe ModuleService — décision : injection directe pour Phase 1, plus rapide, pas de loopback réseau) avec `client_mutation_id = '${runId}:${stepId}'` pour idempotence.
- [ ] AC-11 — `step.type === 'notification'` ⇒ publication sur BullMQ queue `notifications` avec payload `{ tenantId, recipientUserId, template, params }`. Phase 1 worker = `console.log` + insert `audit_logs`. La résolution de la cible (recipient) est dans `step.params` du JSON, **pas** codée dans l'exécuteur.
- [ ] AC-12 — `step.type === 'approval'` ⇒ persist `workflow_states.current_state = 'awaiting_approval:${stepId}'`, `history[]` mis à jour, `run()` retourne `finalState: 'awaiting_approval'`. La reprise est gérée par STORY-031 (XState) qui appellera `resume(runId, event)`.
- [ ] AC-13 — `step.type === 'condition'` ⇒ pas d'effet de bord, route vers `next.true` ou `next.false`.
- [ ] AC-14 — Step type inconnu (futur) ⇒ `WorkflowExecutionError` clair (`UNSUPPORTED_STEP_TYPE`) — pas de crash silencieux.

### Persistance & reprise

- [ ] AC-15 — Après chaque transition d'étape, `workflow_states` est mise à jour transactionnellement (TypeORM transaction) : `current_state`, `history` (append), `updated_at`. Rollback DB en cas d'erreur ⇒ état cohérent.
- [ ] AC-16 — Une entrée `audit_logs` est insérée pour chaque step terminé (`workflow.step.completed`) avec `metadata: { runId, stepId, status, durationMs }`. Aucune donnée métier loguée — uniquement les ids.
- [ ] AC-17 — Si l'app redémarre pendant exécution (kill process), un workflow `awaiting_approval` est récupérable : `workflow_states` row existe, STORY-031 fournit le mécanisme de reprise. Cette story-30 garantit que l'état persisté est cohérent avant le retour de `run()`.

### Retry & erreurs

- [ ] AC-18 — Erreur transitoire (timeout, 502/503/504, `ECONNRESET`) ⇒ retry 3 fois avec backoff `[200ms, 500ms, 1500ms]`. Compteur `attempts` incrémenté dans `history[].attempts`.
- [ ] AC-19 — Erreur métier (4xx, `BusinessRuleViolationError`) ⇒ pas de retry, step `failed`, workflow `failed`. `error: { stepId, code, message }` dans le retour.
- [ ] AC-20 — Si après 3 retries le step échoue toujours ⇒ workflow `failed`, état persisté, audit log `workflow.failed`. Pas de compensation cross-step en Phase 1 — l'admin gère manuellement.

### Tests

- [ ] AC-21 — Test unitaire « workflow linéaire 3 actions » : DAG `A → B → C`, mocks ModuleEngine renvoient success ⇒ `finalState: 'completed'`, `history` ordonné, durée < 50ms.
- [ ] AC-22 — Test unitaire « branches parallèles » : DAG `A → [B, C, D] → E`, mocks ⇒ B/C/D lancés en parallèle (vérifié via overlap timestamps), E démarre uniquement après les 3.
- [ ] AC-23 — Test unitaire « condition false skipped » : step B avec `condition: { field: 'montant', op: '>', value: 500000 }`, contexte `montant: 100000` ⇒ B `skipped`, descendants exécutés normalement.
- [ ] AC-24 — Test unitaire « retry transitoire » : mock ModuleEngine échoue 2x avec 503 puis success ⇒ step `success`, `attempts: 3`, durée totale ≥ 700ms.
- [ ] AC-25 — Test unitaire « erreur métier non-retryable » : mock renvoie 422 ⇒ `attempts: 1`, workflow `failed`.
- [ ] AC-26 — Test unitaire « approval pause » : step `approval` ⇒ `finalState: 'awaiting_approval'`, `workflow_states.current_state` persisté, `history` complet jusqu'à ce step inclus (status `running`).
- [ ] AC-27 — Test E2E (`workflow-executor.e2e-spec.ts`) « clôture caisse » : exécute la fixture `clotureCaisseFixture` (4 steps) avec mocks, vérifie l'ordre, l'audit log, l'état DB final.
- [ ] AC-28 — Coverage `executor/` ≥ 90%, branches ≥ 85%.

---

## Technical Notes

### Composants concernés

- **Module NestJS étendu :** `backend/nestjs/src/workflow/` (créé STORY-029).
- **Sous-dossier executor :** `backend/nestjs/src/workflow/executor/`.
- **Touche :** `module-engine.service.ts` (injection pour appels d'action — interface `executeAction(moduleId, actionId, payload, opts)`).
- **Touche :** Table `workflow_states` (lecture/écriture) — schéma déjà défini dans STORY-017 (RLS) et architecture §Schéma.
- **Touche :** `audit-log.service.ts` (STORY-020) — appels d'écriture par step.
- **Touche :** Redis cache pour la résolution `tenant_id + workflow_id → workflow JSON` (TTL 5min, alignement BDUI cache).

### Structure de fichiers (cible)

```
backend/nestjs/src/workflow/
├── executor/
│   ├── workflow-executor.service.ts          # API publique run()
│   ├── workflow-executor.types.ts            # ExecutionInput / Result / Context
│   ├── step-dispatcher.ts                    # Switch par step.type
│   ├── condition-evaluator.ts                # Évalue { field, op, value }
│   ├── retry-policy.ts                       # Backoff exponentiel + classification erreur
│   ├── workflow-state.repository.ts          # Accès DB workflow_states
│   └── __tests__/
│       ├── workflow-executor.service.spec.ts
│       ├── step-dispatcher.spec.ts
│       ├── condition-evaluator.spec.ts
│       └── retry-policy.spec.ts
├── __fixtures__/                              # Réutilisé depuis STORY-029
│   └── valid-cloture-caisse.ts
└── workflow.module.ts                         # Étendu pour exporter Executor
```

### Service NestJS (référence)

```typescript
@Injectable()
export class WorkflowExecutorService {
  constructor(
    private readonly validator: WorkflowValidatorService,
    private readonly moduleEngine: ModuleEngineService,
    private readonly stateRepo: WorkflowStateRepository,
    private readonly notifications: NotificationQueue,
    private readonly auditLog: AuditLogService,
    private readonly retryPolicy: RetryPolicy,
    private readonly logger: Logger,
  ) {}

  async run(input: ExecutionInput): Promise<ExecutionResult> {
    const workflow = await this.loadWorkflow(input.tenantId, input.workflowId);

    const validation = this.validator.validateDAG(input.workflowId, workflow.steps);
    if (!validation.valid) {
      throw new WorkflowInvalidError(input.workflowId, validation.errors);
    }

    const runId = crypto.randomUUID();
    const ctx: ExecutionContext = {
      runId,
      tenantId: input.tenantId,
      entityId: input.entityId,
      triggeredBy: input.triggeredBy,
      data: { ...input.initialContext },
      stepStatus: new Map(),
      stepOutput: new Map(),
    };

    await this.stateRepo.create({
      tenantId: input.tenantId,
      runId,
      workflowId: input.workflowId,
      entityId: input.entityId,
      currentState: 'running',
      history: [],
    });

    try {
      const finalState = await this.executeDag(workflow.steps, validation, ctx);
      await this.stateRepo.update(runId, { currentState: finalState, history: ctx.history });
      return { runId, workflowId: input.workflowId, finalState, history: ctx.history };
    } catch (err) {
      await this.stateRepo.update(runId, { currentState: 'failed', history: ctx.history });
      this.auditLog.log({ action: 'workflow.failed', metadata: { runId, error: err.code } });
      return { runId, workflowId: input.workflowId, finalState: 'failed',
               history: ctx.history, error: this.serializeError(err) };
    }
  }

  // executeDag — boucle Kahn dynamique, lance les ready steps en parallèle (concurrencyLimit)
  // executeStep — switch par step.type, retry policy via this.retryPolicy.execute(...)
  // ... (implémentation détaillée dans le code)
}
```

### Condition Evaluator (référence)

```typescript
export class ConditionEvaluator {
  evaluate(condition: StepCondition, ctx: ExecutionContext): boolean {
    const value = this.resolvePath(condition.field, ctx.data); // dot-path
    switch (condition.op) {
      case '==':  return value === condition.value;
      case '!=':  return value !== condition.value;
      case '>':   return Number(value) > Number(condition.value);
      case '<':   return Number(value) < Number(condition.value);
      case '>=':  return Number(value) >= Number(condition.value);
      case '<=':  return Number(value) <= Number(condition.value);
      default:    throw new WorkflowExecutionError('UNSUPPORTED_OPERATOR', { op: condition.op });
    }
  }
  private resolvePath(path: string, obj: unknown): unknown {
    return path.split('.').reduce<any>((acc, k) => acc?.[k], obj);
  }
}
```

### Retry Policy (référence)

```typescript
export class RetryPolicy {
  private readonly delays = [200, 500, 1500];      // ms
  async execute<T>(fn: () => Promise<T>, opts: { stepId: string }): Promise<T> {
    let lastError: unknown;
    for (let attempt = 0; attempt <= this.delays.length; attempt++) {
      try { return await fn(); }
      catch (err) {
        lastError = err;
        if (!this.isTransient(err) || attempt === this.delays.length) throw err;
        await sleep(this.delays[attempt]);
      }
    }
    throw lastError;
  }
  private isTransient(err: unknown): boolean {
    const e = err as any;
    return e?.code === 'ECONNRESET' || e?.code === 'ETIMEDOUT'
        || (e?.status >= 500 && e?.status <= 599);
  }
}
```

### Edge cases

- **DAG avec composants disjoints** (deux sous-graphes indépendants dans le même workflow) : exécutés en parallèle (chacun a son point d'entrée). Pas un cas d'erreur — STORY-029 l'autorise.
- **Steps orphelins en runtime (config modifiée à chaud)** : barrière `validateDAG()` à chaque `run()` re-valide — un workflow qui passait il y a 5min mais qui a été corrompu sera rejeté (jamais exécuté à moitié).
- **Concurrence DB (deux runs du même workflow sur la même entity simultanément)** : contrainte UNIQUE `(entity_id, workflow_id)` dans `workflow_states` (déjà au schéma). Le 2ème `run()` reçoit `409 Conflict` propagé en `WorkflowAlreadyRunningError`. Documenter — pas de queue Phase 1.
- **Notification fire-and-forget** : si BullMQ est down, l'exécuteur ne bloque pas le workflow ; le notification step est marqué `success` côté workflow (la notif sera retentée par BullMQ ou perdue). Ce trade-off est documenté — Phase 2 améliore avec ack.
- **Step `action` qui mute des données ABAC-restrictées** : c'est ModuleEngine qui applique la sécurité (CASL). L'exécuteur appelle ModuleEngine avec `triggeredBy: userId` — si le user n'a pas le droit, ModuleEngine renvoie 403 → workflow `failed` proprement.

### Spec source — résolution conflit PRD ↔ DS

- **PRD STORY-030** liste 4 actions : `send_notification`, `update_field`, `create_record`, `call_api`. **Décision pour cette story-30** : ces actions ne sont **pas** codées dans le moteur. Elles sont des `step.action` strings résolus en appels ModuleEngine (`update_field` ⇒ `POST /:moduleId/actions/update`). C'est cohérent avec la règle "no business logic in the engine".
- **PRD STORY-030** mentionne `condition: { field, op, value }`. **Aligné** — implémenté tel quel.
- **Architecture §Composant 7** mentionne XState pour les transitions ; STORY-031 le couvre. Cette story-30 reste un exécuteur procédural (pas de FSM globale du workflow) — XState s'applique seulement aux interactions utilisateur en pause/reprise.
- **Pas de surface UI** dans cette story → aucun conflit DS.

### Performance

- Exécution synchrone in-process Phase 1. Cible : workflow 4 steps avec mocks < 100ms p95. Workflow réel (latence ModuleEngine ~80ms par action) : ~400ms p95 acceptable.
- Cache Redis du JSON workflow (clé `workflow:{tenantId}:{workflowId}`, TTL 5min) — évite un round-trip DB par exécution.

### Sécurité

- L'exécuteur s'exécute avec le contexte du `triggeredBy` user (RLS PostgreSQL via `SET app.current_tenant_id`). Tous les appels ModuleEngine héritent du contexte ⇒ ABAC s'applique automatiquement.
- Pas de PII loguée. `audit_logs` ne contient que `runId`, `stepId`, `status`, `durationMs`.
- Pas d'évaluation d'expression dynamique (pas d'`eval`, pas de Function constructor) — `ConditionEvaluator` est un switch fermé sur des opérateurs whitelistés.

---

## Dependencies

**Prérequis :**

- STORY-013 (Monorepo + NestJS).
- STORY-017 (PostgreSQL RLS) — table `workflow_states` avec policy active.
- STORY-020 (Audit Log Service).
- STORY-022 (ModuleEngine endpoints) — interface `executeAction()` stable.
- STORY-029 (DAG Validator) — service injectable.

**Stories bloquées par celle-ci :**

- STORY-031 (XState State Machine) — la FSM se branche sur les pauses `awaiting_approval` produites ici.
- STORY-032 (Integration Workflow ↔ ModuleEngine) — l'endpoint `start_workflow` appelle `WorkflowExecutorService.run()`.
- STORY-041 (Workflow DAG Clôture Caisse) — utilise cet exécuteur pour son fonctionnement réel.

**Externes :**

- Aucune lib runtime nouvelle (BullMQ déjà présent depuis STORY-013).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-030-workflow-executor`.
- [ ] `npm run lint` passe sans warning sur `backend/nestjs/src/workflow/`.
- [ ] `npm run test workflow` vert avec ≥ 90% coverage sur `src/workflow/executor/`.
- [ ] Test E2E `workflow-executor.e2e-spec.ts` vert sur le workflow `clotureCaisseFixture`.
- [ ] `WorkflowExecutorService` exporté correctement depuis `WorkflowModule` et injectable dans d'autres modules (validation : import dans un module test).
- [ ] Aucun appel `eval` / `Function` dans le service (vérifié par lint rule).
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-030 status `completed`, completed_points sprint 3 += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Service skeleton + injection DI + types `ExecutionInput`/`Result`/`Context` | 0.5 | Boilerplate NestJS + alignement contrats. |
| Boucle d'exécution Kahn dynamique (ready set + concurrence parallèle) | 1 | Pas trivial — gérer les dépendances `success`/`skipped`, plafond concurrence, `Promise.allSettled`. |
| Step dispatcher (4 types : action / condition / notification / approval) | 0.75 | Glue mais propre — chaque type bien isolé. |
| `ConditionEvaluator` + tests | 0.5 | Petit composant, mais critique. Tester opérateurs + dot-path edge cases. |
| `RetryPolicy` (classification transient vs business + backoff) | 0.5 | Important — c'est ce qui rend l'exécuteur résilient. |
| `WorkflowStateRepository` (CRUD + transaction) + intégration audit log | 0.5 | Requête DB + transaction TypeORM. |
| Cache Redis du JSON workflow + invalidation | 0.25 | Petit, mais évite N+1 sur exécutions concurrentes. |
| Tests unitaires (8 cas AC-21 à AC-26) + E2E clôture caisse | 1 | Filet critique — beaucoup de scénarios à couvrir. |
| **Total** | **5** | Fibonacci 5 — moderate avec plusieurs sous-systèmes. |

**Rationale :** L'exécuteur est plus simple que XState (story-31) car il est procédural, pas state-machine. Mais il assemble plusieurs préoccupations (concurrence, retry, persistance, audit). Le risque principal est de mal gérer les branches parallèles ou la concurrence DB — c'est pour ça que les tests AC-22 et AC-26 sont obligatoires. La règle "no business logic" garantit que le service reste petit (~300 LOC) et bien testable.

---

## Notes additionnelles

- **Conflit PRD ↔ DS :** N/A (pas de surface UI).
- **PRD précisait "send_notification, update_field, create_record, call_api"** : interprétés comme des string identifiers résolus par ModuleEngine, **pas** comme des handlers codés ici. Documenté dans l'architecture du service.
- **Pourquoi pas BullMQ pour l'exécution complète Phase 1 ?** Synchrone in-process suffit pour 100 tenants × workflows < 10/jour. BullMQ sera nécessaire en Phase 2 quand 1000+ tenants × pic d'exécutions concurrentes. Décision documentée dans l'architecture.
- **Pourquoi pas de saga / compensation Phase 1 ?** Les workflows MVP (clôture caisse, validation arrivage) sont courts (≤ 5 steps) et peu critiques transactionnellement (un step `notify_owner` qui échoue n'a pas besoin de rollback). Phase 2 ajoutera des hooks de compensation déclarés en JSON. Backlog tracé.
- **Pas de logique métier dans le moteur** : aucun nom de champ métier (`montant`, `caisse`, `cloture`) n'apparaît dans le code de l'exécuteur. Uniquement dans les fixtures de test et la doc.
- **Convention idempotence step** : `client_mutation_id = '${runId}:${stepId}'` est stable et ré-jouable — un retry ré-soumet la même clé, ModuleEngine (STORY-036) renvoie le résultat caché. Pas de double mutation possible.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
