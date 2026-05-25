# STORY-V14-011 : Scalario Calc — ~30 fonctions atomiques + AlgoEngine.eval (dual runtime TypeScript + Dart)

**Epic :** EPIC-V14-006 — Scalario Calc (AlgoEngine)
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-3 (2026-06-23 → 2026-07-06)
**Dépendances :** V14-001 (nomenclature), V14-005 (restructure NestJS)

---

## User Story

> **En tant que** Scalario Form (saisie temps réel) et Scalario Flow (pipelines server-side),
> **je veux** un AlgoEngine qui évalue des formules JSON composées de fonctions atomiques typées Zod/Dart, **dual runtime** (TypeScript côté serveur, Dart côté Flutter), avec exactement le même résultat,
> **so that** un total de ligne se calcule en temps réel côté client (offline-safe) ET le calcul de paie se fait côté serveur (sécurisé) — avec la garantie qu'aucune divergence n'est possible.

---

## Description

### Background

PRD v14 §10 + §22 dit clairement :
- L'AlgoEngine évalue des formules JSON composées de fonctions atomiques (déclaratif, données driven)
- ~30 fonctions atomiques : math (add, sub, mul, div, round), logique (if, gt, lt), listes (sum, avg, filter), dates (today, diff_jours), texte (concat)
- Chaque fonction est typée Zod (NestJS) + Dart-typed (Flutter) — signature stricte, échec au déploiement si `add('5', 3)`
- Mode debug : `AlgoEngine.eval(formula, inputs, { debug: true })` retourne l'arbre d'évaluation complet
- 6 pièges à anticiper (§10.3) : formules profondes illisibles → debug step-by-step obligatoire, typage strict Zod jamais skipped, etc.

### Scope

**In scope :**
- `catalog/algo/primitives/` : 30 fonctions atomiques avec signature Zod côté NestJS
- `apps/flutter/lib/core/calc/primitives.dart` : équivalent Dart
- `AlgoEngine.eval(formula, inputs)` :
  - NestJS : `apps/nestjs/src/engines/algo/algo-engine.service.ts`
  - Flutter : `apps/flutter/lib/core/calc/algo_engine.dart`
- Property-based testing (fast_check NestJS + glados Dart) sur les fonctions critiques (math + listes)
- Mode debug : trace d'évaluation step-by-step
- Tests d'équivalence : 50 formules échantillon, résultat NestJS == résultat Dart

**Out of scope :**
- Memoization Phase 3 (V14-033)
- Compilation closure Dart (>1000 lignes calculées) — V14-033
- DataSourceRegistry dans formulas (V14-007 6 moteurs)

---

## Acceptance Criteria

### Fonctions atomiques (30 fonctions)

- [ ] **AC-01** — Math : `add`, `sub`, `mul`, `div` (gère div/0 throw), `round`, `floor`, `ceil`, `abs`, `min`, `max`.
- [ ] **AC-02** — Logique : `if`, `gt`, `lt`, `eq`, `ne`, `gte`, `lte`, `and`, `or`, `not`.
- [ ] **AC-03** — Listes : `sum`, `avg`, `count`, `filter` (avec field + value), `map_field`, `unique`.
- [ ] **AC-04** — Dates : `today`, `diff_jours`, `add_days`, `format_date`.
- [ ] **AC-05** — Texte : `concat`, `upper`, `lower`, `format_currency` (utilise tenant.config.currency).

### Signature typée

- [ ] **AC-06** — Chaque primitive NestJS exposée avec Zod signature : `add: { args: z.tuple([z.number(), z.number()]), returns: z.number() }`.
- [ ] **AC-07** — Validation `add('5', 3)` au déploiement (parse JSON formula) → erreur explicite avant runtime.
- [ ] **AC-08** — Équivalent Dart : `addFn: (List<num> args) => args[0] + args[1]` avec validation à l'eval.

### AlgoEngine.eval

- [ ] **AC-09** — `AlgoEngine.eval(formula, inputs)` retourne `{ value, type }` où value est le résultat typé.
- [ ] **AC-10** — `AlgoEngine.eval(formula, inputs, { debug: true })` retourne `{ value, steps: [{ fn, args, result }, ...] }` — arbre complet.
- [ ] **AC-11** — Référence `$variable` résolue depuis `inputs` (ex: `$quantite * $prix_unitaire`).
- [ ] **AC-12** — Erreur runtime claire : `'div/0 at step 2 of compute_total'` avec contexte.

### Dual runtime parity

- [ ] **AC-13** — 50 formules échantillon : NestJS et Dart retournent exactement le même résultat.
- [ ] **AC-14** — Property-based testing : `add(a, b) == b + a` (commutative) sur 1000 cas générés (fast_check + glados).
- [ ] **AC-15** — Edge cases tests : `0`, `-0`, `Infinity`, `NaN`, very large/small numbers.

---

## Technical Notes

### Exemple de formule

```json
{
  "function_id": "calc_facture",
  "formula": {
    "fn": "mul",
    "args": [
      {
        "fn": "sub",
        "args": [
          { "fn": "mul", "args": ["$quantite", "$prix_unitaire"] },
          { "fn": "mul", "args": [
              { "fn": "mul", "args": ["$quantite", "$prix_unitaire"] },
              { "fn": "div", "args": ["$remise", 100] }
            ]}
        ]
      },
      1.18
    ]
  }
}
```

Inputs : `{ quantite: 10, prix_unitaire: 1000, remise: 5 }`
Résultat attendu : `(10 * 1000 - (10 * 1000 * 5/100)) * 1.18 = 11210`

### NestJS — `algo-engine.service.ts`

```typescript
@Injectable()
export class AlgoEngineService {
  eval(formula: AlgoFormula, inputs: Record<string, unknown>, opts?: { debug?: boolean }) {
    if (typeof formula === 'string' && formula.startsWith('$')) {
      return inputs[formula.slice(1)];
    }
    if (typeof formula !== 'object' || !formula.fn) {
      return formula; // literal
    }
    const args = formula.args.map((arg) => this.eval(arg, inputs, opts));
    const primitive = this.primitives[formula.fn];
    if (!primitive) throw new Error(`Unknown function: ${formula.fn}`);
    const result = primitive(...args);
    if (opts?.debug) {
      this.debugSteps.push({ fn: formula.fn, args, result });
    }
    return result;
  }
}
```

### Edge cases

- Récursion infinie via références circulaires (`$a = $b + 1` et `$b = $a`) → détection cycle + throw
- Très grandes listes (1000+ éléments) → mode batch pour `sum`, `avg`
- Formula JSON malformée → Zod parse au déploiement, erreur explicite

---

## Dependencies

- **Prérequis :** V14-001 (nomenclature), V14-005 (`src/engines/algo/`)
- **Stories bloquées :** V14-007 (6 moteurs ERP — utilisent AlgoEngine pour computed fields), V14-023 (Scalario Form)

---

## Definition of Done

- [ ] 30 fonctions atomiques NestJS + Dart
- [ ] AlgoEngine.eval (NestJS + Dart) avec mode debug
- [ ] 50 formules d'équivalence testées (parité NestJS/Dart)
- [ ] Property-based tests (fast_check + glados)
- [ ] Docs `engines/algo/README.md`
- [ ] sprint-status.yaml V14-011 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| 30 fonctions atomiques NestJS Zod | 1.5 |
| 30 fonctions atomiques Dart | 1.5 |
| AlgoEngine.eval + mode debug (NestJS + Dart) | 1.0 |
| Tests équivalence + property-based | 0.75 |
| Docs | 0.25 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
