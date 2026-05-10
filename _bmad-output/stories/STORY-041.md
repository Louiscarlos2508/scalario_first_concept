# STORY-041 : Workflow DAG Clôture Caisse — JSON + XState FSM

**Epic :** EPIC-007 — Premier Template `retail_fresh_produce.json` (Gate 0 Blandine)
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-040 (modules ventes + pertes), STORY-029 (DAG validator), STORY-031 (XState FSM generator), STORY-032 (Integration Workflow ↔ ModuleEngine)

---

## User Story

> **En tant que** COMMERCIAL en fin de journée (Aïcha 19h),
> **je veux** suivre un workflow guidé de clôture caisse — saisie fond restant → réconciliation auto → validation MANAGER → clôture confirmée —,
> **so that** la procédure de fin de journée est irréprochable, tracée, et impossible à court-circuiter (pas de "je ferme et basta"). Et **en tant que** MANAGER (Ibrahim), je veux pouvoir valider ou rejeter la clôture en voyant l'écart entre théorique et déclaré, **so that** Blandine peut faire confiance aux chiffres remontés chaque soir.

---

## Description

### Background

La **clôture caisse quotidienne** est la phase 7 du workflow Blandine (sur 8). C'est le **point de friction le plus douloureux** identifié pendant les sessions de découverte :
- Le commercial compte ses billets en vrac et déclare.
- L'écart entre CA théorique (somme des ventes Mobile Money + cash attendu) et fond restant déclaré est souvent flou.
- Sans validation manager, des écarts s'accumulent (vol, erreur, oubli de vente) → Blandine ne sait plus à qui faire confiance.

Le workflow `workflow_cloture_caisse` matérialise cette procédure en un **DAG déclaré en JSON**, validé par le `WorkflowEngine` (STORY-029), exécuté en XState FSM (STORY-031). C'est aussi la **preuve concrète** que les workflows DAG (FR-018) tournent : transition illégale → 409, étapes inaccessibles → refus déploiement.

### Scope

**In scope :**

- **Workflow JSON** `catalog/workflows/workflow_cloture_caisse.json` :
  - 5 étapes : `saisie_fond_restant` → `reconciliation_auto` → (`validation_manager` | `auto_close_si_zero_ecart`) → `cloture_confirmee` ; branche alternative `litige` si écart > seuil et MANAGER rejette.
  - Définition DAG avec `next` conditionnels.
  - Métadonnées : `workflow_id`, `i18n_key`, `applies_to_module: "module_cloture_caisse"`, `triggered_by: ["COMMERCIAL"]`, `version`.
  - Permissions par étape (qui peut exécuter `validation_manager` → MANAGER seul).
  - Notifications (à chaque transition, ex: notif MANAGER quand un commercial soumet sa clôture).
- **Screens BDUI** liés au workflow (déclarés dans le même JSON ou dans `module_cloture_caisse.json` si on en crée un séparé) :
  - `cloture_form` : saisie fond restant (Roboto Mono, FCFA via tenant.config.currency, comparé en live au théorique).
  - `cloture_validation_manager` : MANAGER voit écart, peut valider / rejeter / demander correction.
  - `cloture_confirmee` : écran read-only de confirmation.
- **DAG validation** (STORY-029 consommée) : 0 cycle, 0 étape inaccessible, démarrage clair.
- **XState FSM** (STORY-031 consommée) : transition illégale (`cloture_confirmee` → `saisie_fond_restant`) → erreur 409.
- **Action endpoint** : `POST /api/v1/:tenant/module_cloture_caisse/action` avec `action_type: "start_workflow" | "submit_step" | "validate_step" | "reject_step"`.
- **Test E2E** : COMMERCIAL démarre clôture → MANAGER valide → état final `cloture_confirmee`. Audit log complet.
- **Gestion offline** : un COMMERCIAL peut soumettre sa clôture offline ; la validation MANAGER se fait dès reconnexion. Le workflow état est rejoué à la sync.

**Out of scope :**
- Module `module_cloture_caisse` complet avec entities/screens autonomes — ce workflow vit **dans `catalog/workflows/`** et référence `module_ventes` (lecture théorique) et `module_pertes` (déductions). Pas de table `cloture_caisse` dédiée — l'état est dans `workflow_states`.
- Notification soir Blandine (push notification résumé du jour) → c'est un **autre workflow** post-Gate 0 (Phase 2).
- Audit hebdo / inventaire physique → Phase 2.
- Reconnexion automatique au workflow par un autre user (ex: si Aïcha est malade, Issouf finit sa clôture) → Phase 2.

### User Flow

**Aïcha (COMMERCIAL) 19h :**
1. Ouvre l'app, tab "Caisse" → écran `cloture_landing` montre le bouton "Démarrer clôture".
2. Tap → action `start_workflow` → backend crée `workflow_state` avec `current_step: saisie_fond_restant`.
3. Écran `cloture_form` :
   - Théorique : `12 850 FCFA` (calculé : `sum(module_ventes.cash_today) - sum(module_pertes.cash_impact_today)`).
   - Field : "Fond restant déclaré" (numeric Mono, validation `>= 0`).
   - Aïcha saisit `12 500 FCFA`.
   - Live diff : `-350 FCFA` (en orange si > 1% du théorique, en rouge si > 5%).
   - Field : "Commentaire" optionnel (utile si écart).
4. Tap "Soumettre" → action `submit_step` → transition vers `reconciliation_auto`.
5. `reconciliation_auto` (étape automatique) calcule l'écart : si `|écart| < tenant.config.cloture_auto_threshold` (défaut 0 FCFA, configurable), transition directe `cloture_confirmee`. Sinon → `validation_manager`.
6. Aïcha voit "En attente validation manager".

**Ibrahim (MANAGER) 19h15 :**
1. Notif push : "Clôture caisse Aïcha — écart 350 FCFA".
2. Ouvre `cloture_validation_manager` : voit le détail (théorique, déclaré, écart, commentaire Aïcha).
3. Tap "Valider" → action `validate_step` → transition `cloture_confirmee`. OU tap "Rejeter" → transition `litige`. OU tap "Demander correction" → retour à `saisie_fond_restant` (workflow itère, audit log conserve les versions).
4. Audit log : entrée `workflow_state.history[]` avec timestamps, users, transitions.

**Aïcha 19h17 :**
1. Notif push : "Clôture validée".
2. Workflow état final. La caisse est fermée pour la journée. Impossible de modifier les ventes du jour rétroactivement.

---

## Acceptance Criteria

### Workflow JSON

- [ ] AC-01 — Fichier `catalog/workflows/workflow_cloture_caisse.json` créé, structure conforme `WorkflowDefinition` (STORY-023).
- [ ] AC-02 — Metadata : `workflow_id: "workflow_cloture_caisse"`, `i18n_key: "workflow.cloture_caisse.name"`, `version: "1.0.0"`, `applies_to_module: "module_cloture_caisse"`, `triggered_by_roles: ["COMMERCIAL", "OWNER"]`, `validators_roles: ["MANAGER", "OWNER"]`.
- [ ] AC-03 — 5 steps déclarés : `saisie_fond_restant` (initial), `reconciliation_auto` (system), `validation_manager` (approval), `cloture_confirmee` (final), `litige` (final, terminal négatif).
- [ ] AC-04 — Step `saisie_fond_restant` : type `action`, `executor_role: "COMMERCIAL"`, screen_ref `cloture_form`, next `reconciliation_auto`.
- [ ] AC-05 — Step `reconciliation_auto` : type `condition` (server-side), évalue `|theoretical - declared| <= tenant.config.cloture_auto_threshold`. Si vrai → `cloture_confirmee` ; sinon → `validation_manager`.
- [ ] AC-06 — Step `validation_manager` : type `approval`, `executor_role: "MANAGER"`, screen_ref `cloture_validation_manager`, next : `cloture_confirmee` (validate) | `saisie_fond_restant` (request_correction, retour) | `litige` (reject).
- [ ] AC-07 — Step `cloture_confirmee` : type `final`, no next, audit log final write.
- [ ] AC-08 — Step `litige` : type `final` négatif, no next, déclenche notification OWNER.

### DAG validation

- [ ] AC-09 — Validation DAG via `WorkflowEngine.validateWorkflow()` (STORY-029) : retourne `{ valid: true, sorted: [...] }` — pas de cycle, toutes étapes accessibles, exactement 1 step initial.
- [ ] AC-10 — Test négatif : si on retire le step `cloture_confirmee` du JSON, la validation DAG retourne `valid: false` avec message "step `validation_manager.next.validate` pointe vers une étape inexistante".
- [ ] AC-11 — Test négatif cycle : si on remplace `litige.type: "final"` par `litige.next: "saisie_fond_restant"`, la validation détecte le cycle et refuse.

### XState FSM

- [ ] AC-12 — `WorkflowEngine.generateFSM(workflow_cloture_caisse)` produit une `XState.Machine` avec 5 states.
- [ ] AC-13 — Transitions légales acceptées : `saisie_fond_restant` --SUBMIT--> `reconciliation_auto`, etc. (matrice complète documentée en TechNotes).
- [ ] AC-14 — Transition illégale rejetée : `POST /api/v1/.../action { action_type: "validate_step", from: "cloture_confirmee" }` → 409 `ERR_ILLEGAL_TRANSITION`.
- [ ] AC-15 — Persistence : `workflow_states` table (STORY-029 schema) écrit chaque transition avec `entity_id`, `workflow_id`, `state`, `transitioned_by`, `transitioned_at`, `payload` (JSONB diff).

### API endpoints

- [ ] AC-16 — `POST /api/v1/:tenant/module_cloture_caisse/action` accepte 4 `action_type` : `start_workflow`, `submit_step`, `validate_step`, `reject_step`. Body validé Zod.
- [ ] AC-17 — `GET /api/v1/:tenant/module_cloture_caisse/state?for_date=YYYY-MM-DD&user_id=:id` retourne le state actuel du workflow pour ce user/cette date (utilisé par BDUIEngine pour résoudre quel screen rendre).
- [ ] AC-18 — Idempotence : `start_workflow` 2 fois pour même `(tenant, user, date)` → retourne le même `workflow_state_id`, pas de doublon.
- [ ] AC-19 — RBAC : un COMMERCIAL ne peut pas appeler `validate_step` (403) ; un MANAGER ne peut pas appeler `submit_step` au nom d'un commercial (403).

### Test E2E

- [ ] AC-20 — Test E2E (`services/nestjs/test/e2e/workflow_cloture_caisse.e2e-spec.ts`) :
  1. Seed : 3 ventes du jour (cash 5k + 4k + 3.5k = 12.5k FCFA), 0 perte.
  2. COMMERCIAL `start_workflow` → state `saisie_fond_restant`.
  3. COMMERCIAL `submit_step { declared: 12500 }` → écart 0 → reconciliation auto → `cloture_confirmee`.
  4. Audit log contient 4 entrées.
- [ ] AC-21 — Test E2E "écart" :
  1. Seed : ventes 12.5k, perte 0.
  2. COMMERCIAL `submit_step { declared: 12000 }` → écart 500 → state `validation_manager`.
  3. MANAGER `validate_step` → `cloture_confirmee`.
- [ ] AC-22 — Test E2E "rejet" :
  1. Comme ci-dessus mais MANAGER `reject_step { reason: "écart inexpliqué" }` → state `litige`.
  2. Notif OWNER déclenchée (vérifier mock notif service).

### Offline + sync

- [ ] AC-23 — Test integration Flutter : COMMERCIAL en mode avion → `submit_step` → mutation queue Drift → reconnexion → mutation rejouée → state à jour côté serveur. Aucune perte.
- [ ] AC-24 — Si une transition est rejetée par le serveur (ex: workflow déjà fermé par un autre device), Flutter affiche le conflit dans la conflict queue (server_wins par défaut sur les workflows).

### Hygiène

- [ ] AC-25 — Aucune string visible hardcodée dans le JSON workflow — `i18n_key` partout. Lint vert.
- [ ] AC-26 — `cloture_auto_threshold` est une **config tenant**, pas en dur (`tenant.config.cloture_auto_threshold`, défaut `0` FCFA — strict). Documenté dans `tenant_defaults.cloture_auto_threshold` du `retail_fresh_produce.json`.
- [ ] AC-27 — Seuils orange/rouge live (1% / 5% du théorique) : configurables via `tenant.config.cloture_warning_thresholds`, défauts dans `retail_fresh_produce.json`.

---

## Technical Notes

### Composants concernés

- **Workflow JSON :** `catalog/workflows/workflow_cloture_caisse.json` (nouveau).
- **Screens (déclarés ici, pas dans un module séparé) :** intégrés dans le bloc `screens[]` du workflow JSON :
  - `cloture_form` (form, executor_role COMMERCIAL).
  - `cloture_validation_manager` (form, executor_role MANAGER).
  - `cloture_confirmee` (read-only).
  - `cloture_litige` (read-only, terminal négatif).
- **NestJS :** `services/nestjs/src/workflow-engine/` (consommateur — STORY-029, STORY-031, STORY-032).
- **Flutter :** `apps/flutter/lib/core/bdui/workflow_screen.dart` (consommateur — STORY-007).
- **Tests :** `services/nestjs/test/e2e/workflow_cloture_caisse.e2e-spec.ts`, `apps/flutter/integration_test/cloture_caisse_offline_test.dart`.

### Squelette JSON (cible)

```json
{
  "schema_version": "1.0.0",
  "workflow_id": "workflow_cloture_caisse",
  "i18n_key": "workflow.cloture_caisse.name",
  "version": "1.0.0",
  "applies_to_module": "module_cloture_caisse",
  "triggered_by_roles": ["COMMERCIAL", "OWNER"],
  "validators_roles": ["MANAGER", "OWNER"],

  "config_refs": {
    "auto_threshold": "tenant.config.cloture_auto_threshold",
    "warning_thresholds": "tenant.config.cloture_warning_thresholds",
    "currency": "tenant.config.currency"
  },

  "data_aggregations": [
    {
      "id": "theoretical_cash",
      "source_module": "module_ventes",
      "query": { "filter": { "payment_method": "cash", "created_at": { "$between": ["@start_of_day", "@end_of_day"] } }, "aggregate": "sum(total_amount)" }
    },
    {
      "id": "theoretical_deductions",
      "source_module": "module_pertes",
      "query": { "filter": { "cash_impact": true, "created_at": { "$between": ["@start_of_day", "@end_of_day"] } }, "aggregate": "sum(cash_value)" }
    }
  ],

  "steps": [
    {
      "id": "saisie_fond_restant",
      "type": "action",
      "initial": true,
      "executor_role": "COMMERCIAL",
      "screen_ref": "cloture_form",
      "next": "reconciliation_auto",
      "i18n_key": "workflow.cloture.step.saisie"
    },
    {
      "id": "reconciliation_auto",
      "type": "condition",
      "rule": {
        "operator": "<=",
        "field": "abs(theoretical_cash - declared_cash - theoretical_deductions)",
        "value": "@config_refs.auto_threshold"
      },
      "next": { "true": "cloture_confirmee", "false": "validation_manager" }
    },
    {
      "id": "validation_manager",
      "type": "approval",
      "executor_role": "MANAGER",
      "screen_ref": "cloture_validation_manager",
      "next": {
        "validate": "cloture_confirmee",
        "request_correction": "saisie_fond_restant",
        "reject": "litige"
      },
      "notification_on_enter": { "to_role": "MANAGER", "i18n_key": "notif.cloture.pending_validation" }
    },
    {
      "id": "cloture_confirmee",
      "type": "final",
      "screen_ref": "cloture_confirmee",
      "outcome": "success",
      "audit_action": "log_full_state"
    },
    {
      "id": "litige",
      "type": "final",
      "screen_ref": "cloture_litige",
      "outcome": "failure",
      "notification_on_enter": { "to_role": "OWNER", "i18n_key": "notif.cloture.litige" }
    }
  ],

  "screens": [
    { "screen": "cloture_form", "layout": "form", "zones": { "...": "..." } },
    { "screen": "cloture_validation_manager", "layout": "form", "zones": { "...": "..." } },
    { "screen": "cloture_confirmee", "layout": "detail", "zones": { "...": "..." } },
    { "screen": "cloture_litige", "layout": "detail", "zones": { "...": "..." } }
  ]
}
```

### Matrice transitions XState

| From state | Event | To state | RBAC |
|---|---|---|---|
| (start) | START_WORKFLOW | saisie_fond_restant | COMMERCIAL or OWNER |
| saisie_fond_restant | SUBMIT | reconciliation_auto | COMMERCIAL or OWNER |
| reconciliation_auto | (auto, écart=0) | cloture_confirmee | system |
| reconciliation_auto | (auto, écart>0) | validation_manager | system |
| validation_manager | VALIDATE | cloture_confirmee | MANAGER or OWNER |
| validation_manager | REQUEST_CORRECTION | saisie_fond_restant | MANAGER or OWNER |
| validation_manager | REJECT | litige | MANAGER or OWNER |
| cloture_confirmee | * | (rejeté 409) | — |
| litige | * | (rejeté 409) | — |

### Conflits de spec — résolutions

- **Sprint plan AC-01 liste 4 étapes** (`saisie_fond_restant` → `reconciliation` → `validation_manager` → `cloture_confirmee`) ; cette story en ajoute **2** : `reconciliation_auto` (le système le fait déjà implicitement, mais on l'explicite comme step `condition` pour la traçabilité audit) et `litige` (terminal négatif). **Décision :** la 4-step shorthand du sprint plan reste **utilisateur-visible** (4 écrans), mais le DAG interne en a **5** (4 user-facing + 1 condition system). Documenter dans la PR.
- **Architecture mention `WorkflowEngine` côté NestJS uniquement** : cette story ne fait **pas** d'XState côté Flutter. Le Flutter affiche le screen courant que le serveur lui dit. La FSM source de vérité est le serveur (cohérent FR-018, NFR-005).
- **Workflow vs Module** : décision de STORY-039 — `module_cloture_caisse` n'est **pas** un module avec entities propres. L'état est porté par `workflow_states`. Cette story confirme cette approche en mettant les screens directement dans le workflow JSON.
- **Notification soir Blandine** mentionnée Phase 1 (FR-022) : ce n'est **pas** ce workflow. C'est un workflow séparé `workflow_notification_soir` qui s'exécute à la fin de la journée et qui agrège toutes les clôtures. Reporté Phase 2 — Gate 0 ne le couvre pas. Documenté.

### Edge cases

- **Multi-devices commercial** : si Aïcha a 2 téléphones et soumet 2 fois, `start_workflow` est idempotent par `(tenant, user, date)`. Le second appel retourne le `workflow_state_id` existant. Pas de duplicat.
- **Mid-day attempt** : un COMMERCIAL ne peut pas démarrer la clôture avant la fin de sa session. Phase 1 = pas de garde-fou ; Phase 2 = config `min_session_duration`.
- **Vente créée après clôture confirmée** : la nouvelle vente est rejetée 409 par le `ModuleEngine` (vérification : `if exists workflow_state(cloture_confirmee, user, today) → reject create_vente`). Documenté dans STORY-040 mais l'enforcement est dans cette story.
- **Manager indisponible** : si MANAGER ne valide pas dans 24h, OWNER peut valider à sa place (rôle élargi). Pas de timeout auto Phase 1 — manuel.
- **Offline submit + serveur down** : la mutation reste en Drift queue jusqu'à reconnexion. UI montre "En attente d'envoi" + indicateur sync_bar (STORY-009).
- **Devise non-XOF** : tous les affichages monétaires passent par `intl.NumberFormat.currency(symbol: tenant.config.currency)`. Si tenant en EUR, l'écran montre `12,50 €` au lieu de `12 500 FCFA`. **Aucun XOF ni FCFA en dur dans le JSON workflow.**

### Sécurité

- `RbacGuard` enforce les `executor_role` à chaque action. Documenté STORY-013.
- L'audit log (`audit_logs`) est insert-only — pas de delete possible même par OWNER.
- Le payload des transitions inclut un hash de l'état précédent (anti-replay simple). Phase 2 = signature HMAC.

---

## Dependencies

**Prérequis (techniques) :**
- STORY-029 — DAG validator + table `workflow_states`.
- STORY-031 — XState FSM generator depuis JSON.
- STORY-032 — Integration Workflow ↔ ModuleEngine (transitions appellent ModuleEngine pour aggregations).
- STORY-040 — `module_ventes` (lecture théorique cash) et `module_pertes` (déductions cash).
- STORY-007 — BDUIEngine workflow_screen renderer Flutter.
- STORY-009 — SyncBar (UI offline).

**Stories bloquées par celle-ci :**
- STORY-043 — Validation E2E Gate 0 (test Blandine doit faire 1 clôture complète).

**Externes :** Aucune. Pas de dépendance à un service mobile money pour ce workflow (le `payment_provider` est juste un label dans la vente, pas un appel API ici).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-041-workflow-cloture-caisse`.
- [ ] Fichier `catalog/workflows/workflow_cloture_caisse.json` valide JSON + valide Zod + valide DAG.
- [ ] CI `validate-catalogue.yml` vert.
- [ ] Tests verts :
  - DAG validation + cycle detection (AC-09 à AC-11).
  - XState FSM transitions légales/illégales (AC-12 à AC-14).
  - E2E nominal écart=0 (AC-20).
  - E2E écart + validation manager (AC-21).
  - E2E écart + rejet → litige (AC-22).
  - Integration offline Flutter (AC-23).
  - RBAC enforcement (AC-19).
- [ ] `npm run lint` (NestJS) + `flutter analyze` verts.
- [ ] Aucune string hardcodée.
- [ ] Aucune valeur business en dur (`XOF`, `FCFA`, seuils).
- [ ] Code review : `/codex review` + auto-review Carlos.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-041 status `completed`, sprint 4 `completed_points += 3`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Workflow JSON (5 steps + screens + aggregations) | 0.75 | Précision sur les `next` conditionnels et la matrice transitions. |
| Intégration DAG validator + tests négatifs cycle/inaccessible | 0.5 | Réutilise STORY-029. 2 tests négatifs critiques. |
| FSM XState générée + transitions légales/illégales testées | 0.5 | Réutilise STORY-031. Test 409 sur transition illégale. |
| Endpoints NestJS (`start_workflow`, `submit_step`, `validate_step`, `reject_step`) + idempotence | 0.5 | DTOs Zod + idempotence par `(tenant, user, date)`. |
| Tests E2E nominal + écart + rejet + audit log | 0.5 | 3 scénarios E2E fixturés, 12 assertions chacun. |
| Test offline (Drift mutation queue → sync) | 0.25 | Réutilise STORY-008/009. |
| **Total** | **3** | Fibonacci 3 — moderate, mais c'est le workflow le plus critique de Gate 0. |

**Rationale :** Le workflow lui-même est **simple structurellement** (5 steps, transitions claires). La complexité vient de la **rigueur d'enforcement** : une transition illégale qui passerait casserait la confiance Blandine ↔ Aïcha. Les 3 tests E2E sont le filet — ils doivent couvrir nominal, écart-validation, écart-rejet. Sans ce filet, Gate 0 prend un risque.

---

## Notes additionnelles

- **Lien Blandine ↔ workflow :** la phase 7 du workflow Blandine ("Clôture caisse quotidienne : CA confrontation gestionnaire vs commerciaux") est **pile** ce que ce workflow modélise. La validation Manager n'est pas un détail — c'est ce qui transforme la confiance abstraite en chiffres tracés.
- **Référence UX :** `design-process/C-UX-Scenarios/03-blandine-commercial-caisse-close/` (sketch S21, S22, S23 si présents).
- **Compteur live écart** dans `cloture_form` : composant DS `KPIDelta` (ou équivalent — vérifier dans `composites/`). S'il manque, ouvrir story DS plutôt qu'inventer.
- **Roboto Mono** sur tous les montants : les valeurs FCFA doivent s'aligner verticalement. Cf STORY-001 typography tokens.
- **i18n FR primaire** : tous les libellés en FR via les clés (les strings réelles sont dans STORY-042). `litige` reste un terme métier — gardé en FR (`workflow.cloture.litige.label = "Litige"`).
- **Pas de PaymentAdapter ici** : ce workflow ne fait pas d'appel à Wave/OM/MoMo. Il agrège des ventes déjà enregistrées. Le PaymentAdapter intervient au moment de la vente (STORY-040) pas de la clôture.
- **Logo Scalario :** non concerné.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
