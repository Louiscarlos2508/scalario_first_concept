# STORY-V14-002 : JSON Schema BDUI v1.1.0 — Ajout `variant`, `actions[]`, `children[]`

**Epic :** EPIC-V14-002 — Scalario Canvas (BDUI v14)
**Priorité :** Must Have
**Story Points :** 3
**Status :** defined
**Sprint :** v14-1 (2026-05-26 → 2026-06-08)
**Dépendances :** V14-001 (migration nomenclature) ; STORY-023 v13 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant qu'**intégrateur Scalario certifié (Phase 1) ou Config Agent IA (Phase 2+),
> **je veux** que `ComponentConfig` JSON expose `variant: string`, `actions: ActionStep[]` et `children: ComponentConfig[]`,
> **so that** un même composant DS (KPICard, DataTable…) peut être rendu sous N variantes contextuelles + déclencher des pipelines + composer récursivement — **sans dupliquer N types** dans le registre.

---

## Description

### Background

Le PRD v14 §8.5 introduit le système de variantes : `KPICard + variant='compact'` au lieu de `KPICardCompact` séparé. La variante `'auto'` laisse Flutter résoudre selon le contexte (taille écran, rôle, nb d'éléments). Le PRD §12.5 ajoute aussi `actions[]` (pipelines déclenchés sur événement) et `children[]` (composition récursive).

Cette story met à jour 3 contrats alignés :
1. `catalog/schemas/component-config.schema.json` — JSON Schema Draft 2020-12
2. `apps/nestjs/src/catalogue/validators/component-config.zod.ts` — Zod NestJS
3. `apps/flutter/lib/core/canvas/component-config.dart` — Dart validator côté Flutter

### Scope

**In scope :**
- Schema bump `schema_version: '1.1.0'` (backward-compat avec 1.0.0 via `variant` default `'default'`)
- Champ `variant: string` requis (default `'default'`)
- Champ `actions?: ActionStep[]` (nouveau, optionnel)
- Champ `children?: ComponentConfig[]` (récursif, optionnel)
- 6 nouveaux fichiers d'exemples JSON (valid + invalid)
- Tests Zod (NestJS) + tests Dart parser (Flutter) parsing équivalent

**Out of scope :**
- Implémentation du dispatch par variante côté Flutter — fait par V14-003
- Catalogue des variantes autorisées par composant — fait par V14-004
- `actions[]` runtime executor — fait par V14-007 (Scalario Flow refactored)

---

## Acceptance Criteria

### Schema JSON Draft 2020-12

- [ ] **AC-01** — `catalog/schemas/component-config.schema.json` accepte `schema_version: '1.1.0'` (literal const).
- [ ] **AC-02** — `variant: string` ajouté avec `default: 'default'` et `minLength: 1`.
- [ ] **AC-03** — `actions: array of ActionStep` ajouté (optionnel), avec sous-schéma `{ registry, fn, inputs?, output?, on_error? }`.
- [ ] **AC-04** — `children: array of ComponentConfig` ajouté (récursif via `$ref`).
- [ ] **AC-05** — 6 fichiers d'exemples : `valid_with_variant_default.json`, `valid_with_variant_auto.json`, `valid_with_actions.json`, `valid_with_children_nested.json`, `invalid_variant_number.json`, `invalid_actions_wrong_shape.json`.

### Zod NestJS

- [ ] **AC-06** — `component-config.zod.ts` ajoute `variant: z.string().min(1).default('default')`.
- [ ] **AC-07** — `actions: z.array(ActionStepZod).optional()`.
- [ ] **AC-08** — `children: z.lazy(() => z.array(ComponentConfigZod)).optional()` (récursif).
- [ ] **AC-09** — Backward compat : un JSON v1.0.0 (sans `variant`) parse OK avec `variant: 'default'` injecté par Zod.

### Dart parser Flutter

- [ ] **AC-10** — `ComponentConfig.fromJson()` Dart accepte `variant`, `actions`, `children`.
- [ ] **AC-11** — `ScalarioCanvasResolver.resolveVariant(variant, ctx)` retourne `'compact' | 'default' | 'hero' | ...` selon `variant: 'auto'` + contexte (screen size, role).

### Tests

- [ ] **AC-12** — `component-config.zod.spec.ts` : 8 cas (6 examples + 2 backward-compat tests).
- [ ] **AC-13** — `component_config_dart_test.dart` : parsing équivalent à Zod NestJS sur les 6 examples.

---

## Technical Notes

### Contrat TypeScript cible

```typescript
interface ComponentConfig {
  schema_version: '1.0.0' | '1.1.0';
  type: string;
  variant: string;
  id?: string;
  props: Record<string, unknown>;
  visible_if?: Rule;
  source?: DataSource;
  validation?: ValidationRule[];
  actions?: ActionStep[];       // NOUVEAU v1.1.0
  children?: ComponentConfig[]; // NOUVEAU v1.1.0
  i18n_key?: string;
}

interface ActionStep {
  registry: 'canvas' | 'form' | 'calc' | 'sense' | 'vault' | 'live';
  fn: string;
  inputs?: Record<string, unknown>;
  output?: string;
  on_error?: Record<string, 'skip' | 'retry' | 'notify' | 'fail'>;
}
```

### Edge cases

- `variant: ''` (empty string) → rejeté par `minLength: 1`
- `variant: 'auto'` → accepté ; Flutter résout au runtime
- `children` profondeur infinie → limiter à 5 niveaux via custom Zod refine (anti-abuse)
- Backward-compat : `schema_version: '1.0.0'` sans `variant` → injection automatique `variant: 'default'`

---

## Dependencies

- **Prérequis :** V14-001 (migration nomenclature — pour avoir `apps/flutter/lib/core/canvas/`)
- **Stories bloquées :** V14-003 (ComponentRegistry dispatch), V14-004 (Catalogue variantes), V14-007 (6 moteurs ERP qui consomment `actions[]`)

---

## Definition of Done

- [ ] Schema JSON + Zod + Dart alignés
- [ ] 13 tests verts (8 Jest + 5 Dart)
- [ ] `catalog/README.md` section "Variantes" + section "Actions" + section "Composition"
- [ ] Memory `feedback_scalario_variants.md` (1 type + N variantes + auto resolution)
- [ ] sprint-status.yaml V14-002 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Schema JSON v1.1.0 + 6 examples | 1.0 |
| Zod NestJS + tests (8 cas) | 1.0 |
| Dart parser + tests (5 cas) | 0.75 |
| Docs catalog/README + memory | 0.25 |
| **Total** | **3** |

---

## Progress Tracking

**Status History :**
- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
