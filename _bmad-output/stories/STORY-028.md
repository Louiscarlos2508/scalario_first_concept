# STORY-028 : Tests Coverage Moteur ≥ 90 %

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have *(STRETCH — Sprint 4)*
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-005 (BDUIEngine + ComponentRegistry), STORY-006 (RuleEvaluator), STORY-007 (LayoutResolver), STORY-008 (ErrorBoundary), STORY-022 (ModuleEngine 2 endpoints)

---

## User Story

> **En tant que** dev solo Carlos sur Scalario (qui itère seul, sans QA dédié, et qui doit garder la vélocité long terme),
> **je veux** une couverture de tests ≥ 90 % sur le moteur BDUI (Flutter `engine/`, `bdui/`) et ≥ 85 % sur le moteur backend (NestJS `module-engine/`, `bdui/`, `workflow/`),
> **so that** je puisse refactorer agressivement, ajouter des features rapidement, et **détecter les régressions silencieuses avant qu'elles n'atteignent un tenant en prod**.

---

## Description

### Background — Pourquoi un coverage gate explicite

Chaque story d'EPIC-001 et EPIC-004 inclut "tests unitaires ≥ 80-90 %" dans sa DoD. Le risque : du coverage local par story, sans **vue d'ensemble**, peut laisser des **trous transverses** invisibles. Cette story est **le filet final** :

1. Mesurer la couverture **globale** sur les zones critiques (moteur BDUI Flutter + moteurs NestJS).
2. Identifier les trous par fichier / fonction.
3. Combler les manques (fonctions privées, branches d'erreur, edge cases inter-composants).
4. Activer un **gate CI bloquant** : PR qui descend en dessous des seuils → rejetée.

Sans ce gate, le coverage dérive lentement vers 70 % puis 60 %. Avec, il reste à 90 %+ par construction.

### Pourquoi STRETCH ?

- Chaque story upstream a déjà ses tests inclus. Cette story est le **complément + l'enforcement**.
- La couverture peut être proche de 90 % naturellement à la fin de Sprint 3 si les stories sont bien faites.
- Si Sprint 4 est saturé, le gate CI peut être ajouté plus tard ; le coverage continue d'être mesuré (non-bloquant) → décision Gate 0 indépendante.

Choix : **livrer en sprint 4 si capacité**, sinon différer. Le gate CI lui-même peut être ajouté en 1 jour le moment venu.

### Scope

**In scope :**

- **Audit coverage actuel** : exécuter `flutter test --coverage` et `bun test --coverage` ; produire un rapport par fichier dans les zones cibles.
- **Combler les trous** identifiés :
  - Flutter `lib/core/bdui/engine/` (BDUIEngine, ComponentRegistry, RuleEvaluator, LayoutResolver, DataSourceResolver) — cible **≥ 90 %**.
  - NestJS `src/module-engine/` — cible **≥ 85 %**.
  - NestJS `src/bdui/` — cible **≥ 90 %** (sécurité : filtrage RBAC).
  - NestJS `src/workflow/` — cible **≥ 85 %**.
- **Tests d'intégration ModuleEngine** (Jest + supertest) :
  - GET + POST sur 3 modules différents (`pos`, `stock`, `fournisseurs`).
  - Idempotence X-Client-Mutation-Id (replay → même résultat).
  - ABAC denial.
  - Action inconnue → 422.
  - Module inconnu → 404.
- **Tests d'intégration BDUIService** :
  - 2 rôles différents reçoivent des payloads différents.
  - Cache HIT vs MISS.
  - Bulk endpoint.
  - Invalidation pub/sub.
- **Snapshot tests Flutter (Goldens)** — le Widgetbook (STORY-004) sert de référence visuelle. Cette story branche les goldens en CI :
  - Chaque WidgetbookUseCase a un golden test.
  - Diff visuel en CI échoue si un widget change d'apparence sans mise à jour explicite du golden.
- **Configuration CI** :
  - `flutter test --coverage` en CI → publish `coverage/lcov.info`.
  - `bun test --coverage` en CI → publish `coverage/coverage-summary.json`.
  - Gate Flutter : zones cibles ≥ 90 % (extrait via `lcov --extract` + script).
  - Gate NestJS : zones cibles ≥ 85 % (Jest `coverageThreshold` config).
  - Échec CI si en dessous.
- **Badge coverage** (optionnel mais recommandé) : `README.md` racine affiche un badge Codecov ou shield.io.

**Out of scope (autres stories) :**

- Tests E2E Playwright/Cypress sur l'app Web → Phase 2 ou story dédiée hors EPIC-004.
- Tests de charge / performance → STORY (perf benchmarks) hors EPIC-004.
- Tests d'intrusion sécurité multi-tenant → couverts par story sécurité dédiée.
- Tests Flutter integration_test (smoke E2E sur device) → Phase 2.

### User Flow (CI on PR)

1. Carlos ouvre une PR (n'importe quelle story).
2. CI lance `flutter-tests` job :
   - `flutter test --coverage` produit `coverage/lcov.info`.
   - Script `scripts/coverage-gate.sh` extrait coverage des zones cibles.
   - Si `lib/core/bdui/engine/` < 90 % → CI rouge `"BDUI engine coverage 87% < 90% threshold"`.
3. CI lance `nestjs-tests` job :
   - `bun test --coverage` → Jest `coverageThreshold` config échoue si `module-engine` < 85 %.
4. CI lance `golden-tests` job :
   - `flutter test --update-goldens=false` compare avec les baselines.
   - Si diff visuel non explicite → CI rouge.
5. PR merge bloquée jusqu'à conformité.

---

## Acceptance Criteria

### Audit & rapport

- [ ] AC-01 — Rapport coverage initial produit (markdown ou commentaire PR) listant : zone cible, % actuel, % cible, lignes manquantes top 10. Sert de baseline.

### Coverage Flutter (≥ 90 %)

- [ ] AC-02 — `lib/core/bdui/engine/bdui_engine.dart` ≥ 90 % lines, ≥ 85 % branches.
- [ ] AC-03 — `lib/core/bdui/engine/component_registry.dart` ≥ 90 %. Test : type connu → builder appelé ; type inconnu → `UnknownComponent`.
- [ ] AC-04 — `lib/core/bdui/engine/rule_evaluator.dart` ≥ 90 %. Couvre tous les operators (`AND`, `OR`, `role`, `>`, `<`, `==`, `!=`, `>=`, `<=`, `in`, `not_in`), imbrication 3+ niveaux, cas null/undefined.
- [ ] AC-05 — `lib/core/bdui/engine/layout_resolver.dart` ≥ 90 %. Test : 4 layouts (`dashboard`, `list`, `form`, `detail`) × 3 breakpoints (mobile, tablet, desktop) = 12 cas explicites.
- [ ] AC-06 — `lib/core/bdui/error_boundary.dart` (STORY-008) ≥ 90 %. Couvre throw au build → fallback localisé.
- [ ] AC-07 — `lib/core/bdui/validation/` (STORY-026) ≥ 90 %. Couvre validator + fallback screen.

### Coverage NestJS (≥ 85 %)

- [ ] AC-08 — `src/module-engine/` ≥ 85 % global, ≥ 90 % sur `data-dispatcher.service.ts` et `action-dispatcher.service.ts`.
- [ ] AC-09 — `src/bdui/` ≥ 90 % (sécurité critique).
- [ ] AC-10 — `src/workflow/` ≥ 85 % (DAG validation Kahn's, XState transitions).
- [ ] AC-11 — `src/catalogue/validators/` ≥ 90 % (déjà ciblé STORY-024).

### Tests d'intégration ModuleEngine

- [ ] AC-12 — Test "3 modules génériques" (cf STORY-022 AC-14) consolidé dans la suite : `pos`, `stock`, `fournisseurs` répondent via les 2 endpoints sans code spécifique.
- [ ] AC-13 — Test idempotence : `POST /action` avec même `X-Client-Mutation-Id` x2 → 1 entité créée + 1 réponse identique au 2e appel.
- [ ] AC-14 — Test ABAC : COMMERCIAL appelle `POST /pos/action { action: 'apply_discount' }` → 403 (CASL deny).
- [ ] AC-15 — Test action inconnue → 422 avec message `"Unknown action 'foo' for module 'pos'"`.
- [ ] AC-16 — Test concurrent même mutation_id : 2e requête arrivée pendant que la 1ère est `pending` → 409.

### Tests d'intégration BDUIService

- [ ] AC-17 — Test 2 rôles : OWNER reçoit `KPICard CA`, COMMERCIAL ne le reçoit pas → assertion sur la liste des `type` dans `zones.kpis`.
- [ ] AC-18 — Test cache : 1er appel cache MISS (latence > seuil), 2e appel cache HIT (latence < seuil), invalidation via pub/sub → MISS de nouveau.
- [ ] AC-19 — Test bulk : `?screens=s1,s2,s3` retourne les 3.

### Goldens Flutter

- [ ] AC-20 — Pour chaque WidgetbookUseCase (STORY-004), un golden test généré dans `apps/flutter/test/goldens/`. Baseline initiale commitée.
- [ ] AC-21 — Diff visuel automatique en CI : si un widget change sans `--update-goldens` explicite → CI rouge.

### Gate CI

- [ ] AC-22 — Configuration `coverageThreshold` dans `backend/nestjs/jest.config.ts` enforce les seuils par chemin :
  ```ts
  coverageThreshold: {
    'src/module-engine/': { lines: 85 },
    'src/bdui/': { lines: 90 },
    'src/workflow/': { lines: 85 },
  }
  ```
  Et script `scripts/coverage-gate.sh` (Flutter) qui extrait `lcov.info` et fail si zones cibles < 90 %.

---

## Technical Notes

### Composants concernés

- **Pas de nouveau code applicatif** — cette story ajoute des **tests** + de la **configuration CI**.
- **Modifs :** `backend/nestjs/jest.config.ts`, `apps/flutter/test/`, `.github/workflows/ci.yml`, racine `package.json` scripts, ajout `scripts/coverage-gate.sh`.

### Structure de fichiers (cible)

```
backend/nestjs/
├── jest.config.ts                              # + coverageThreshold per-path
└── test/
    └── integration/
        ├── module-engine.integration.spec.ts   # 3 modules génériques
        ├── bdui-service.integration.spec.ts    # 2 rôles, cache, bulk
        ├── idempotency.integration.spec.ts
        └── workflow.integration.spec.ts

apps/flutter/
├── test/
│   ├── core/bdui/engine/                        # Existing per-story tests
│   ├── goldens/
│   │   ├── widgetbook_goldens_test.dart        # Diff visuel Goldens
│   │   └── baselines/                           # PNG baselines commitées
│   └── coverage/
│       └── coverage_gate_test.dart              # Smoke test : sait lire lcov

scripts/
└── coverage-gate.sh                             # Extract coverage par zone, fail si < seuil

.github/workflows/
└── ci.yml                                       # + coverage gate steps + golden diff
```

### Code patterns

**`backend/nestjs/jest.config.ts` (extrait) :**

```typescript
import type { Config } from '@jest/types';

const config: Config.InitialOptions = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'json-summary'],
  coverageThreshold: {
    'src/module-engine/**/*.ts': { lines: 85, branches: 80 },
    'src/bdui/**/*.ts': { lines: 90, branches: 85 },
    'src/workflow/**/*.ts': { lines: 85, branches: 80 },
    'src/catalogue/validators/**/*.ts': { lines: 90, branches: 85 },
  },
};

export default config;
```

**`scripts/coverage-gate.sh` (Flutter) :**

```bash
#!/usr/bin/env bash
set -euo pipefail

LCOV_FILE="apps/flutter/coverage/lcov.info"

declare -A THRESHOLDS=(
  ["lib/core/bdui/engine"]=90
  ["lib/core/bdui/validation"]=90
  ["lib/core/bdui/error_boundary.dart"]=90
)

failures=0
for path in "${!THRESHOLDS[@]}"; do
  threshold="${THRESHOLDS[$path]}"
  pct=$(lcov --extract "$LCOV_FILE" "*${path}*" -o /tmp/extract.info 2>/dev/null \
        | tail -1 | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%')
  if (( $(echo "$pct < $threshold" | bc -l) )); then
    echo "❌ $path: $pct% < $threshold%"
    failures=$((failures + 1))
  else
    echo "✅ $path: $pct% ≥ $threshold%"
  fi
done

[[ $failures -eq 0 ]] || exit 1
```

**Test golden Widgetbook :**

```dart
void main() {
  testGoldens('widgetbook usecases golden snapshot', (tester) async {
    final widgetbook = WidgetbookApp(/* … */);
    await tester.pumpWidget(widgetbook);
    await screenMatchesGolden(tester, 'widgetbook_full');
  });
}
```

**Test intégration "3 modules génériques" :**

```typescript
describe('ModuleEngine — généricité 3 modules', () => {
  let app: INestApplication;
  beforeAll(async () => {
    app = await createTestApp({
      catalog: [
        loadFixture('domain-with-pos.json'),
        loadFixture('domain-with-stock.json'),
        loadFixture('domain-with-fournisseurs.json'),
      ],
    });
  });

  test.each(['pos', 'stock', 'fournisseurs'])(
    'GET /:moduleId/data fonctionne pour %s',
    async (moduleId) => {
      const res = await request(app.getHttpServer())
        .get(`/api/v1/test-tenant/${moduleId}/data`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(200);
      expect(res.body).toHaveProperty('items');
      expect(res.body).toHaveProperty('total');
    },
  );

  test('Aucun import domain-spécifique dans src/module-engine/', () => {
    const files = glob.sync('src/module-engine/**/*.ts');
    for (const file of files) {
      const content = fs.readFileSync(file, 'utf8');
      expect(content).not.toMatch(/case ['"](?:pos|stock|fournisseurs)['"]/);
      expect(content).not.toMatch(/if.*moduleId.*===.*['"]pos['"]/);
    }
  });
});
```

### Edge cases

- **Coverage flat-line à 89.9 %** : `(89.9 < 90)`. Choix : seuils stricts (`< 90`) pour garder la discipline. Un PR à 89 % est un signal d'alarme, pas un édulcoré.
- **Zones avec faux positifs** (ex: code `// istanbul ignore next` justifié) : tagger explicitement, documenter en commentaire pour audit.
- **Tests qui montent le coverage sans tester** (ex: `expect(true).toBe(true)`) : revue humaine + `/codex review` orienté "ces tests testent-ils vraiment ?".
- **Goldens fragiles** (anti-aliasing diff par OS) : utiliser `flutter test --tag=goldens` en CI sur image Linux fixe (Docker) ; ne pas committer de goldens générés sur Mac/Windows.
- **Migration coverage en cours** : si pendant la story on découvre que `engine/` est à 70 %, prioriser les tests qui couvrent les **branches d'erreur** d'abord (cas où ça crashe en prod), pas les happy paths déjà couverts.
- **Temps CI** : ajouter ces tests peut faire passer la CI de 5 min à 15 min. Acceptable Phase 1 ; paralléliser via matrix Phase 2.

### Sécurité

- **Pas de secret en fixture** : les `loadFixture('domain-with-pos.json')` sont des données fictives.
- **Tests d'idempotence et ABAC sont sécurité critique** — couverture > 95 % attendue sur ces fichiers spécifiquement (peut être un seuil sub-étiqueté).
- **Test partagé STORY-026 AC-21** (Zod NestJS ↔ json_schema Flutter) inclus dans cette suite — garantit le contrat partagé.

---

## Dependencies

**Prérequis :**

- STORY-005 — BDUIEngine (existant à tester).
- STORY-006 — RuleEvaluator (existant).
- STORY-007 — LayoutResolver (existant).
- STORY-008 — ErrorBoundary (existant).
- STORY-022 — ModuleEngine 2 endpoints (cible des intégrations).
- STORY-021 — BDUIService (cible des intégrations).
- STORY-004 — Widgetbook (sources des goldens).

**Stories bloquées par celle-ci :**

- Aucune — c'est un filet, pas un prérequis.
- Mais : Gate 0 (qualité gate du MVP) **devrait** consumer ces seuils. Si stretch non-livré, Gate 0 utilise les coverages individuels par story et accepte l'inconnue transverse.

**Externes :**

- `lcov` (système, pour Flutter).
- `golden_toolkit` (Flutter pub) ou `flutter_test` natif Goldens.
- Codecov ou shield.io pour badges (optionnel).

---

## Definition of Done

- [ ] Code commité sur `feat/story-028-coverage-90-gate`.
- [ ] Audit coverage initial documenté dans la PR (commentaire ou fichier).
- [ ] Tous les seuils AC-02 à AC-11 atteints en CI.
- [ ] Tests d'intégration AC-12 à AC-19 écrits et passants.
- [ ] Goldens Widgetbook commités, diff CI fonctionnel.
- [ ] `jest.config.ts` `coverageThreshold` configuré avec les chemins cibles.
- [ ] `scripts/coverage-gate.sh` exécutable, intégré CI.
- [ ] Test PR drift : enlever volontairement un test → CI rouge avec message coverage clair (preuve que le gate est actif).
- [ ] Badge coverage (optionnel) sur README racine.
- [ ] PR review (`/codex review`) — focus "qualité des tests > quantité".
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-028 status `completed` (ou `deferred` si stretch non livré), sprint 4 completed_points += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Audit coverage initial + identification trous | 0.5 | Run + analyse rapport. |
| Combler trous Flutter `engine/` (RuleEvaluator branches, LayoutResolver breakpoints) | 1.5 | Le poste le plus lourd — les branches RuleEvaluator sont nombreuses. |
| Combler trous NestJS `module-engine/`, `bdui/`, `workflow/` | 1 | Quelques edge cases d'erreur, idempotence corner cases. |
| Tests intégration ModuleEngine (3 modules + idempotence + ABAC + actions inconnues) | 1 | 5 scénarios bien testés. |
| Tests intégration BDUIService (2 rôles + cache + bulk) | 0.5 | 3 scénarios. |
| Goldens Widgetbook + baselines | 0.25 | Une fois Widgetbook OK, c'est mécanique. |
| Configuration CI `coverageThreshold` + `coverage-gate.sh` + tests drift | 0.25 | Yaml + bash + un test smoke. |
| **Total** | **5** | Fibonacci 5 — moderate-complex. |

**Rationale :** La complexité est dans **combler les trous** (1.5 + 1 = 2.5 points sur 5) — c'est du test-writing pur, où chaque cas demande de comprendre la logique testée. Le reste (intégrations + CI) est mécanique mais essentiel. Stretch parce qu'on peut Gate 0 avec coverages individuels par story (chaque DoD individuelle).

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` lignes 1715-1744 (testing strategy + cibles de coverage). PRD §FR-055.
- **Cibles différenciées par zone** :
  - Flutter `engine/` : 90 % — c'est le cœur.
  - NestJS `module-engine/`, `workflow/` : 85 % — tests d'intégration coûtent cher, 85 % est réaliste.
  - NestJS `bdui/`, `auth/`, `security/` : 90 % — sécurité critique.
  - Global : 80 %.
- **Goldens utiles ou fragiles ?** Goldens Flutter sont **utiles** pour détecter les régressions visuelles silencieuses (un padding qui passe de 16 à 12 sans bruit). **Fragiles** sur multi-OS. Mitigation : CI sur image Linux fixe + commits goldens uniquement après revue visuelle humaine (`flutter test --update-goldens` en local + diff humain dans la PR).
- **Test partagé Zod ↔ json_schema (STORY-026 AC-21)** : à inclure dans cette suite — garantit le contrat partagé. C'est **le** test qui détecte une divergence de validateurs.
- **Coverage `// istanbul ignore`** : à utiliser avec parcimonie. Chaque ignore commenté avec une justification (ex: `// istanbul ignore next: defensive — bootstrap fail-fast covered by manual test`).
- **Suite à cette story** : si le coverage stagne à 90 %, considérer **mutation testing** (Phase 2, `Stryker.js` pour TS, package Dart custom). C'est le niveau au-dessus — détecter les tests qui ne testent rien.
- **Si non-livré** (stretch sauté) :
  - Le coverage individuel par story (≥ 80-90 % par DoD) reste appliqué.
  - Le Gate 0 utilise les artifacts par story.
  - On revisite en post-Gate 0, idéalement avant le 1er onboarding intégrateur externe.
  - Ajouter une dette tech tracker `tech-debt:coverage-gate` dans le backlog.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
