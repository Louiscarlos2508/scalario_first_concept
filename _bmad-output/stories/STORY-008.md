# STORY-008 : BDUIEngine Orchestrateur

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 6
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-005 (ComponentRegistry), STORY-006 (RuleEvaluator), STORY-007 (LayoutResolver), STORY-010 (Error Boundaries — version complète Sprint 1), STORY-033 (Drift cache — résolution data sources). En Sprint 1, data sources mockées via fixtures sandbox ; bascule vers Drift en Sprint 3.

---

## User Story

> **En tant que** client Flutter Scalario,
> **je veux** un `BDUIEngine` qui prend un `ScreenConfig` JSON et retourne un widget tree complet entièrement fonctionnel,
> **so that** n'importe quel JSON valide du catalogue devient un screen Flutter rendu — sans une seule ligne de logique métier dans l'app, en < 200ms cold et < 50ms hot.

---

## Description

### Background

Le BDUIEngine est le **chef d'orchestre** du Backend-Driven UI. Il assemble en une pipeline les 3 briques livrées en Sprint 1 (`ComponentRegistry`, `RuleEvaluator`, `LayoutResolver`) et y ajoute la résolution des sources de données.

Sans cette story, les briques existent mais ne servent à rien — il faut un point d'entrée qui transforme un screen JSON en widget tree. **C'est la story la plus structurante de l'EPIC-002**, et c'est aussi celle qui garantit le respect du principe non-négociable de Scalario : `zero business logic in the engine` (PRD §FR-001 ligne 246, architecture ligne 34).

L'Engine doit aussi tenir un budget de performance strict (NFR-001 architecture ligne 1157) :
- **Cold render** (depuis Drift cache local) : **< 200ms** sur Android mid-range Snapdragon 680.
- **Hot render** (depuis cache mémoire après une 1re lecture) : **< 50ms**.
- **Évaluation de règle** : **< 1ms par composant** (déjà enforcé par STORY-006).

Le respect de ces budgets en CI est ce qui empêche l'Engine de devenir lent au fil des stories. Sans benchmark continu, l'app finit à 800ms par render après 3 mois de développement.

### Scope

**In scope :**

- Package `lib/engine/bdui_engine/` avec :
  - `bdui_engine.dart` — classe `BDUIEngine` injectée via `get_it`. API publique : `Widget render(ScreenConfig config, BuildContext ctx)`.
  - `bdui_screen.dart` — `BDUIScreen` widget consommé par les routes Flutter (`MaterialPageRoute(builder: (_) => BDUIScreen(screenId: 'dashboard'))`).
  - `data_source_resolver.dart` — `DataSourceResolver` qui, à partir d'un `DataSource` config (cf. contrat partagé), retourne les données : Phase 1 = mockées via fixtures locales ; Sprint 3 = Drift cache.
  - `screen_cache.dart` — cache mémoire LRU `Map<screenId, ScreenConfig>` pour le hot path.
- Pipeline complet `render(config, ctx)` :
  1. **Parse** : `ScreenConfig.fromJson` (déjà disponible, contrat partagé).
  2. **Validation** : JSON Schema validation (`json_schema_dart` package — STORY-023 fournit le schema). Échec → `BDUIErrorScreen` localisé.
  3. **RuleEvaluator** : itère les zones, filtre les composants dont `visible_if` est `false`.
  4. **DataSourceResolver** : pour chaque composant qui a un `source`, résout les données (mocked en S2, Drift en S3).
  5. **ComponentRegistry.build** : instancie chaque composant restant avec ses props + données résolues.
  6. **LayoutResolver.resolve** : structure les zones selon le layout.
  7. Retourne le widget tree, le tout enveloppé dans un `BDUIErrorBoundary` global (STORY-010).
- Cache mémoire : LRU 20 entries (configurable). Hit → skip parse + validation, va direct à RuleEvaluator (qui peut changer si `UserContext` a changé).
- Métriques de performance : chaque `render` mesure le temps total + le temps de chaque étape, log via `dart:developer` `Timeline.startSync('BDUI.render')`.
- Tests d'intégration : 3 JSON différents (`retail_dashboard.json`, `simple_form.json`, `transactions_list.json`) → rendent 3 screens corrects.
- Benchmark CI : cold < 200ms, hot < 50ms, mesuré sur émulateur Snapdragon 680.
- Lint custom : aucune logique métier dans `lib/engine/bdui_engine/` (vérifié par grep CI).

**Out of scope (autres stories) :**

- Récupération JSON depuis le backend NestJS → STORY-022 (Layout endpoint) Sprint 2 ; en Sprint 2, le BDUIEngine consomme les fixtures sandbox.
- Persistence Drift offline → STORY-033 Sprint 3 ; le `DataSourceResolver` aura un constructeur Phase 1 qui retourne des fixtures, et un constructeur Phase 3 (DI swap) qui lit Drift.
- Sync queue offline → STORY-034 / EPIC-006.
- Hot reload du JSON dev → STORY-009.
- Error boundary par composant complet → STORY-010 (le BDUIEngine consomme l'API).
- Validation forms data-driven runtime → STORY-011 (le BDUIEngine ne valide pas les inputs ; il rend les FormWidget qui ont leurs propres validators).
- Multi-plateforme builds → STORY-012.
- Authentification + UserContext production → STORY-009 (Auth) ; en Sprint 2, le BDUIEngine consomme un `UserContextProvider` injecté qui retourne un mock.

### Runtime Flow

1. Utilisateur navigue vers `/dashboard` → route Flutter monte `BDUIScreen(screenId: 'retail_dashboard')`.
2. `BDUIScreen.initState` appelle `bduiEngine.loadScreen('retail_dashboard')` :
   - Cache hit mémoire ? → fournit le `ScreenConfig` direct.
   - Cache miss ? → lit depuis `DataSourceResolver` (fixture/Drift) → `ScreenConfig.fromJson` → store cache.
3. `BDUIScreen.build` appelle `bduiEngine.render(screenConfig, ctx)`.
4. `render` exécute le pipeline (parse → validate → rules → data → components → layout) avec `Timeline.startSync` pour profiling.
5. Retourne un widget tree. Si une étape échoue, `BDUIErrorBoundary` capture et affiche un `BDUIErrorScreen` (alertBanner + retry).
6. Hot render : si `loadScreen` est rappelé (refresh), cache mémoire hit → seul le RuleEvaluator + DataSourceResolver re-rolent (les rules dépendent du UserContext qui peut changer si l'utilisateur a switché de rôle).

---

## Acceptance Criteria

### API & Pipeline

- [ ] AC-01 — `BDUIEngine.render(ScreenConfig config, BuildContext ctx) → Widget` orchestre la pipeline complète : parse → validate → rules → data → components → layout.
- [ ] AC-02 — `BDUIEngine.loadScreen(String screenId) → Future<ScreenConfig>` charge depuis cache mémoire LRU, sinon depuis `DataSourceResolver` (fixture en S2, Drift en S3 via DI).
- [ ] AC-03 — `BDUIScreen` widget public consommé par les routes Flutter via `BDUIScreen(screenId: '...')`. Gère le `FutureBuilder` autour de `loadScreen` + affiche `Skeleton` (composant DS) pendant le chargement.
- [ ] AC-04 — Pipeline traversée dans cet ordre exact : (1) JSON Schema validation, (2) RuleEvaluator filter, (3) DataSourceResolver, (4) ComponentRegistry.build, (5) LayoutResolver.resolve. Documenté en commentaire de `bdui_engine.dart`.
- [ ] AC-05 — `BDUIEngine` est un singleton injecté via `get_it`. `BDUIEngineModule.register(GetIt)` enregistre les dépendances (registry, evaluator, layoutResolver, dataSourceResolver, screenCache).
- [ ] AC-06 — Aucune logique métier dans `lib/engine/bdui_engine/` (vérifié par lint CI : grep contre `MANAGER`, `OWNER`, `tenant_id` hardcodé, ou nom d'entité métier).

### Performance — Budgets enforced

- [ ] AC-07 — **Cold render** (cache mémoire vide → fixture lue → render complet) : **< 200ms** sur émulateur Snapdragon 680 pour `retail_dashboard.json` (8 KPIs + 1 DataTable + 2 ActionButton + 3 AlertBanner = ~14 composants). Benchmark CI échoue si dépassement ≥ 5 fois sur 100 itérations.
- [ ] AC-08 — **Hot render** (cache mémoire hit) : **< 50ms** sur même config. Benchmark CI échoue si dépassement.
- [ ] AC-09 — Profiling intégré : chaque `render` ouvre une `Timeline.startSync('BDUI.render')` avec sub-events `parse`, `validate`, `rules`, `data`, `components`, `layout`. Visible dans Flutter DevTools Performance.
- [ ] AC-10 — Cache mémoire LRU : taille max 20 entries (configurable via `BDUIEngineConfig`). Eviction LRU testée.

### Validation JSON Schema

- [ ] AC-11 — Tout `ScreenConfig` est validé contre `screen-config.schema.json` avant exécution (package `json_schema_dart`).
- [ ] AC-12 — Validation échoue → `render` retourne `BDUIErrorScreen` avec :
  - Titre i18n : "Écran indisponible".
  - Détail (debug only, `kDebugMode`) : chemin du nœud + raison.
  - Bouton "Réessayer" qui relance `loadScreen`.
  - Tap "Signaler" → log structuré envoyé au sink local (Audit Log via STORY-026).

### Error handling

- [ ] AC-13 — Toute exception non-gérée dans le pipeline → capturée par `BDUIErrorBoundary` global (STORY-010), affiche `BDUIErrorScreen`. Aucun crash propagé au root widget.
- [ ] AC-14 — Composant individuel qui throw → ErrorBoundary par-composant (STORY-010) capture ; le reste du screen reste fonctionnel.
- [ ] AC-15 — `DataSourceResolver` qui throw (ex: fixture corrompue) → l'Engine logge + insère un `EmptyState` à la place du composant qui dépendait de cette source. Pas de crash.
- [ ] AC-16 — Toutes les erreurs sont loguées avec contexte structuré : `tenant_id`, `screen_id`, `component_type`, `component_id`, `step` (parse/validate/rules/data/components/layout). Format JSON pour ingestion future.

### Tests d'intégration

- [ ] AC-17 — 3 fixtures JSON dans `assets/sandbox/` :
  - `retail_dashboard.json` — dashboard OWNER, 8 KPIs + DataTable + 2 boutons (utilisé aussi par STORY-009).
  - `simple_form.json` — formulaire 4 champs (TextInput, NumberInput, DatePicker, Toggle) + ActionButton submit.
  - `transactions_list.json` — list layout avec FilterChips et 20 MouvementItem.
- [ ] AC-18 — 3 tests d'intégration `flutter_test` qui :
  - Montent `BDUIScreen(screenId: 'X')` avec un `UserContext` mock.
  - Vérifient que les composants attendus sont rendus (find.byType pour chaque type).
  - Vérifient que `visible_if` est appliqué (un composant avec `role: ['OWNER']` est rendu pour OWNER, masqué pour CASHIER).
- [ ] AC-19 — Test idempotence : `render` 2 fois le même screen avec même `UserContext` → résultat identique pixel-perfect (golden test).
- [ ] AC-20 — Test rebuild user context : `render` avec `UserContext(roles: {'OWNER'})` puis avec `UserContext(roles: {'CASHIER'})` → composants masqués correctement.

### Tests unitaires

- [ ] AC-21 — Tests unitaires (`test/engine/bdui_engine/`) couvrent :
  - `loadScreen` cache hit / miss.
  - LRU eviction (21e screen → 1er évincé).
  - JSON Schema validation : config invalide → BDUIErrorScreen.
  - DataSourceResolver mock injecté → données passées aux composants.
  - Aucun composant rendu si tous filtrés par `visible_if`.
- [ ] AC-22 — Couverture ≥ 90% sur `lib/engine/bdui_engine/`.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/bdui_engine/`.
- **Dépend de :** `component_registry/` (STORY-005), `rule_evaluator/` (STORY-006), `layout_resolver/` (STORY-007), `error_boundary/` (STORY-010).
- **Stub :** `DataSourceResolver` Phase 2 = lit fixtures sous `assets/sandbox/data/`. Phase 3 (STORY-033) = lit Drift. L'API reste identique → swap par DI.

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── engine/
│       └── bdui_engine/
│           ├── bdui_engine.dart                # BDUIEngine + render() + loadScreen()
│           ├── bdui_engine_config.dart         # cache size, perf budgets
│           ├── bdui_engine_module.dart         # DI registration
│           ├── bdui_screen.dart                # BDUIScreen widget
│           ├── bdui_error_screen.dart          # fallback global
│           ├── data_source_resolver.dart       # interface + FixtureResolver impl S2
│           ├── screen_cache.dart               # LRU
│           └── perf_metrics.dart               # Timeline wrapper
├── assets/
│   └── sandbox/
│       ├── retail_dashboard.json
│       ├── simple_form.json
│       ├── transactions_list.json
│       └── data/                                # Fixtures pour DataSource Phase 2
│           ├── kpi_ventes.json
│           └── transactions.json
├── test/
│   └── engine/
│       └── bdui_engine/
│           ├── bdui_engine_test.dart
│           ├── data_source_resolver_test.dart
│           ├── screen_cache_test.dart
│           ├── benchmark_test.dart
│           └── integration/
│               ├── retail_dashboard_integration_test.dart
│               ├── simple_form_integration_test.dart
│               └── transactions_list_integration_test.dart
```

### Pattern Dart recommandé

```dart
class BDUIEngine {
  BDUIEngine({
    required this.registry,
    required this.evaluator,
    required this.layoutResolver,
    required this.dataResolver,
    required this.userContextProvider,
    required this.config,
  });

  final ComponentRegistry registry;
  final RuleEvaluator evaluator;
  final LayoutResolver layoutResolver;
  final DataSourceResolver dataResolver;
  final UserContextProvider userContextProvider;
  final BDUIEngineConfig config;

  final ScreenCache _cache = ScreenCache(maxSize: 20);

  Future<ScreenConfig> loadScreen(String screenId) async {
    final cached = _cache.get(screenId);
    if (cached != null) return cached;
    final json = await dataResolver.loadScreenJson(screenId);
    JsonSchemaValidator.validateScreen(json); // throws BDUIValidationException
    final config = ScreenConfig.fromJson(json);
    _cache.put(screenId, config);
    return config;
  }

  Widget render(ScreenConfig config, BuildContext ctx) {
    return Timeline.timeSync('BDUI.render', () {
      final userCtx = userContextProvider.current;

      final filteredZones = Timeline.timeSync('rules', () {
        return _applyVisibleIf(config.zones, userCtx);
      });

      final dataMap = Timeline.timeSync('data', () {
        return _resolveAllDataSources(filteredZones);
      });

      // Components built lazily inside layouts via registry.build
      return BDUIErrorBoundary(
        screenId: config.screen,
        child: layoutResolver.resolve(config.layout, /* enriched config */, ctx),
      );
    });
  }
}
```

### Spec source — résolution des conflits

**1. Cache architecture** : le PRD §FR-004 (ligne 245) parle de "rendu < 50ms (hot, layout déjà en mémoire)". Le sprint plan ligne 216 dit "depuis cache Drift". L'architecture ligne 1162 distingue "cold (Drift) < 200ms" et implicitement "hot (mémoire) < 50ms".

**Décision :** deux niveaux de cache distincts :
- **Cache mémoire LRU** (cette story, 20 entries) → hot path < 50ms.
- **Cache Drift persistant** (STORY-033) → cold path < 200ms.
La 1re lecture passe par Drift puis remplit le cache mémoire ; la 2e va directement en mémoire. Documenté dans `screen_cache.dart`.

**2. JSON Schema validation timing** : on valide à `loadScreen` (parse-time), pas à `render` (chaque rebuild). Validation cachée avec le ScreenConfig. Si STORY-023 fournit un validator stream, on l'utilise ; sinon, validation synchrone classique.

### Edge cases

- **Cache stale (UserContext change)** : le `ScreenConfig` est statique mais le rendu dépend du `UserContext` (rules). On cache le **ScreenConfig parsé**, pas le widget tree. Chaque `render` re-évalue les règles. Comportement correct.
- **Rebuild fréquent (StreamBuilder dépendant)** : si un composant interne se reconstruit (ex: KPI live), `render` lui-même n'est pas appelé — seul le sub-tree concerné rebuild. Pas d'impact pipeline.
- **Screen vide (toutes zones null)** : pipeline retourne un `EmptyState` DS avec message i18n "Aucun contenu disponible". Pas de crash, pas de NaN.
- **Fixture JSON corrompue** : JSON Schema validation lève → `BDUIErrorScreen` avec retry. En dev, le `BDUIErrorScreen` affiche le path du nœud fautif (`zones.kpis[2].props.value: expected number, got string`).
- **Memory pressure** : sur Android low-memory, le cache LRU est volontairement petit (20 entries) → ~50KB. Acceptable même en bas de gamme.
- **Récursion / nested screens** : pas dans cette story. Phase 1, un screen est plat. Si un composant a un sous-composant (ex: ExpandableSection), c'est l'affaire du ComponentRegistry, pas de l'Engine.

### Sécurité

- **Trust boundary** : le BDUIEngine s'exécute côté client. Le JSON peut avoir été manipulé localement. La sécurité réelle est côté backend (ModuleEngine FR-016 + RBAC Guards FR-010). Le BDUIEngine est une couche UX, pas de sécurité.
- **Pas de `eval` ni de code distant** : tous les composants sont compilés AOT (cf. STORY-005).
- **Logs sans PII** : les logs structurés contiennent `tenant_id`, `screen_id`, `component_type`, mais **jamais** les données utilisateur (montants, noms, emails). À enforcer par revue de code + lint regex.

### Performance — Budgets détaillés

Budget total cold render < 200ms décomposé :
- JSON Schema validation : ~30ms (parser `json_schema_dart` n'est pas optimal, à benchmarker, possibilité de basculer vers `dart_json_schema` Phase 2).
- `ScreenConfig.fromJson` : ~10ms.
- `RuleEvaluator` (15 composants × 1ms) : ~15ms.
- `DataSourceResolver` (fixtures S2, Drift S3) : ~30ms (Drift SQLite query).
- `ComponentRegistry.build` (15 widgets) : ~50ms.
- `LayoutResolver.resolve` + Flutter layout pass : ~50ms.
- Marge : ~15ms.

**Hot render < 50ms** :
- Cache hit ScreenConfig : 0ms.
- RuleEvaluator + DataResolver (si UserContext inchangé, on peut memoize) : ~10ms.
- ComponentRegistry.build + Layout : ~35ms.
- Marge : ~5ms.

Si on dépasse en CI, ajouter des optimisations :
- Memoize `RuleEvaluator(rule, ctx)` par hash.
- Pre-compile fixtures en `const ScreenConfig` (S3+).
- Réduire les widgets `StatefulWidget` au profit de `StatelessWidget` dans les composants DS.

---

## Dependencies

**Prérequis :**

- STORY-005 (ComponentRegistry) — `merged`.
- STORY-006 (RuleEvaluator) — `merged`.
- STORY-007 (LayoutResolver) — `merged`.
- STORY-010 (Error Boundaries) — `merged` Sprint 1 (cette story consomme l'API complète).
- STORY-023 (JSON Schema partagé) — `merged` Sprint 2 (sinon validation faiblement typée Phase 2).

**Stories bloquées par celle-ci :**

- STORY-009 (Sandbox) — directe.
- STORY-011 (Validation forms) — indirecte (FormWidget rendu par l'Engine).
- STORY-012 (Multi-plateforme) — indirecte.
- STORY-022 (Layout endpoint backend) — collaborative ; l'Engine consomme l'API.
- STORY-033 (Drift cache) — collaborative ; le DataSourceResolver swap d'implémentation.
- Toutes les stories d'EPIC-007 (Sprint Demo) — directes.

**Externes :**

- `json_schema_dart: ^x.x` (validation runtime).
- `get_it: ^7.x` (DI, déjà ajouté par STORY-005).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-008-bdui-engine`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/bdui_engine/`.
- [ ] `flutter test test/engine/bdui_engine/` vert avec ≥ 90% coverage.
- [ ] 3 tests d'intégration passent sur les 3 fixtures.
- [ ] Benchmark cold < 200ms et hot < 50ms vérifiés en CI sur émulateur Snapdragon 680.
- [ ] Aucune logique métier dans le dossier (vérifié par grep CI).
- [ ] Profiling Timeline.timeSync visible dans Flutter DevTools (manuel test, screenshot dans la PR).
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-008 status `completed`, completed_points sprint 2 += 6).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `BDUIEngine` core (pipeline render + loadScreen + DI module) | 1.5 | Orchestration des 3 briques + cache. |
| `DataSourceResolver` interface + `FixtureResolver` Phase 2 | 0.5 | Lit `assets/sandbox/data/*.json`, swap Drift en S3. |
| `ScreenCache` LRU + tests éviction | 0.5 | Implémentation simple + tests boundary. |
| JSON Schema validation intégration (`json_schema_dart`) | 0.75 | Choix package, wrapper `JsonSchemaValidator`, error→BDUIErrorScreen. |
| `BDUIScreen` widget + `BDUIErrorScreen` + Skeleton loading | 0.75 | Wrapper FutureBuilder, gestion erreur, retry. |
| 3 fixtures JSON (retail_dashboard, simple_form, transactions_list) | 0.5 | Réalistes, couvrent layout + visible_if + sources. |
| 3 tests d'intégration + golden idempotence | 1 | Le filet le plus important — preuves bout en bout. |
| Benchmark CI cold + hot + Timeline profiling | 0.5 | Setup harness Snapdragon emulator + assertion < 200ms. |
| Lint custom no-business-logic + grep CI | 0.25 | Script bash. |
| Logs structurés JSON + sink local | 0.25 | Préparation Audit Log STORY-026. |
| **Total** | **6** | Fibonacci 6 (=5+1) — la story la plus structurante de l'EPIC. |

**Rationale :** 5 points = c'est de l'orchestration de briques existantes. **+1 point pour le filet de performance** : sans benchmark CI cold + hot dès le sprint 2, l'Engine devient lent en sprint 4 et personne ne s'en rend compte avant la démo. Le benchmark + profiling Timeline est ce qui rend la promesse "< 200ms" tenable sur la durée. C'est aussi la story la plus visible — les 3 tests d'intégration sont la preuve bout en bout que **n'importe quel JSON devient un screen**, sur laquelle se base toute la stratégie data-driven de Scalario.

---

## Notes additionnelles

- **DataSourceResolver swap pattern** : on définit l'interface dans cette story. `FixtureResolver` est l'implémentation Sprint 2. `DriftResolver` arrive en STORY-033 et remplace `FixtureResolver` au DI bootstrap. Aucun autre code ne change. C'est la propriété de découplage la plus précieuse de cet Engine.
- **UserContextProvider mock Sprint 2** : avant STORY-009 (Auth), on injecte un `UserContextProvider` qui retourne `UserContext(userId: 'dev', tenantId: 'demo', roles: {'OWNER'})`. À swap dès STORY-009 mergée.
- **Budget perf ≠ cible perf** : 200ms cold est un **plafond**, pas une cible. La cible idéale est ~120ms. Si on hit 180ms en S2 et 195ms en S4, c'est un signal d'alerte → triage.
- **Profiling en prod** : par défaut, `Timeline.startSync` est disabled en `kReleaseMode`. C'est correct — on ne veut pas l'overhead. Pour debug prod (Phase 2), un build profile sera utilisé.
- **Sandbox JSON dev (STORY-009)** : consomme directement le BDUIEngine via une route `/dev/sandbox?file=retail_dashboard.json`. L'Engine ne sait pas qu'il est en sandbox — il fonctionne identique.
- **Logo Scalario / branding** : non concerné.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
