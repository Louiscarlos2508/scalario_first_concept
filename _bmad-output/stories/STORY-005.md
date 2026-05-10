# STORY-005 : ComponentRegistry

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-001 (tokens), STORY-002 (ThemeData), STORY-003 (composants DS Phase 1) — pour les builders concrets ; STORY-023 (JSON Schema `ComponentConfig`) en parallèle pour le contrat d'entrée

---

## User Story

> **En tant que** BDUIEngine Scalario,
> **je veux** un registry extensible qui mappe un `type` string JSON vers un widget Flutter builder,
> **so that** n'importe quel composant du catalogue DS est instancié depuis JSON sans modifier l'Engine — et qu'ajouter un nouveau composant tient en une ligne `register("type", builder)`.

---

## Description

### Background

Scalario rend des screens 100% data-driven : un `ScreenConfig` JSON contient une liste de `ComponentConfig` avec un champ `type` (`"KPICard"`, `"DataTable"`, `"AlertBanner"`…). Pour transformer ce string en widget Flutter, il faut un point d'indirection : le **ComponentRegistry**.

Sans ce registry, l'Engine devrait contenir un `switch (type)` géant — ce qui violerait le principe non-négociable "**zéro logique métier dans l'Engine**" (PRD §FR-001 ligne 246) et empêcherait l'extensibilité (impossible d'ajouter un composant sans toucher à l'Engine).

Le registry est la **seule liste de composants disponibles** : un type non enregistré ne peut pas être rendu — il tombe sur le fallback `UnknownComponent`. C'est un contrat fort : aucune surprise au runtime.

L'architecture (cf. `_bmad-output/architecture-scalario-2026-05-09.md` lignes 308-417) prévoit **73 composants DS canoniques** répartis en 10 groupes (Feedback · Data Display · Inputs · Selection · Lists · Actions · Spécialisés · Navigation · Loading States · Documents & Session). Cette story enregistre **les 7 composants Phase 1** (KPICard, DataTable, AlertBanner, FAB/ActionButton, ListTile, FormSection/FormWidget, ChartWidget) et prépare l'extension pour les 66 autres au fil des stories EPIC-001/002.

### Scope

**In scope :**

- Création du package `lib/engine/component_registry/` avec :
  - `component_config.dart` — value object DTO mappé sur `ComponentConfig` du contrat partagé (cf. `architecture` ligne 955).
  - `component_builder.dart` — typedef `ComponentBuilder = Widget Function(ComponentConfig config, BuildContext ctx)`.
  - `component_registry.dart` — classe `ComponentRegistry` avec `register`, `unregister`, `build`, `isRegistered`, `registeredTypes`.
  - `unknown_component.dart` — fallback widget affiché pour un `type` non enregistré.
- Singleton DI-friendly via `get_it` (`GetIt.I<ComponentRegistry>()`) — pas de `static` global non testable.
- Bootstrap d'enregistrement Phase 1 dans `lib/engine/component_registry/registry_bootstrap.dart` :
  - `KPICard`, `DataTable`, `AlertBanner`, `ActionButton` (FAB), `ListTile` (ou équivalent DS — cf. `MouvementItem`/`StockListItem`), `FormWidget` (FormSection), `ChartWidget`.
- Convention `Component.fromConfig(config, ctx)` factory côté chaque widget DS (les widgets eux-mêmes existent via STORY-003).
- Intégration explicite du wrapper `ErrorBoundary` autour de chaque rendu — préparation hook pour STORY-010 (qui implémentera la classe `ErrorBoundary` complète ; cette story expose juste le point d'extension).
- Tests unitaires (≥ 90% coverage sur `lib/engine/component_registry/`) :
  - `register` + lookup nominal pour chaque composant Phase 1.
  - `type` inconnu → `UnknownComponent` (jamais throw).
  - `props` null/vide → fallback gracieux par chaque builder (pas un crash registry-level).
  - `register` deux fois sur même type → comportement défini (override + warning log).
  - `registeredTypes` retourne la liste alphabétique pour debug.

**Out of scope (autres stories) :**

- Implémentation des widgets DS eux-mêmes (`KPICard.fromConfig` etc.) → STORY-003.
- Évaluation des `visible_if` → STORY-006 (RuleEvaluator).
- Layout des composants → STORY-007 (LayoutResolver).
- Pipeline d'orchestration (parse JSON → registry → layout) → STORY-008 (BDUIEngine).
- Implémentation complète d'`ErrorBoundary` (logging, fallback localisé) → STORY-010.
- Validation forms data-driven → STORY-011.
- Enregistrement des 66 autres composants DS → stories EPIC-001 ultérieures (ils s'ajoutent en 1 ligne chacun).

### User Flow (Runtime)

1. App démarre → `main()` appelle `RegistryBootstrap.registerPhase1(GetIt.I<ComponentRegistry>())`.
2. BDUIEngine reçoit un `ScreenConfig` JSON depuis Drift cache (Sprint 2 via STORY-008 ; pour Sprint 1 c'est la sandbox STORY-009 qui injecte).
3. Pour chaque `ComponentConfig` dans `zones.kpis`, l'Engine appelle `registry.build(config, ctx)`.
4. Le registry lit `config.type` → cherche dans la map → trouve le builder → `builder(config, ctx)` retourne le widget.
5. Si `config.type == "UnknownGadget"` (typo, composant futur, cassure de schéma) → `UnknownComponent` rendu avec le message `Composant "UnknownGadget" indisponible`.
6. Aucun crash, aucun écran blanc — le screen reste fonctionnel autour du composant fautif.

---

## Acceptance Criteria

### Contrat d'entrée

- [ ] AC-01 — `ComponentConfig` est un POJO Dart immutable conforme au contrat partagé (`type: String`, `id: String?`, `props: Map<String, dynamic>`, `visibleIf: Rule?`, `source: DataSource?`, `validation: List<ValidationRule>?`, `i18nKey: String?`). Compatible JSON via `fromJson`/`toJson`.
- [ ] AC-02 — `ComponentConfig.copyWith(...)` disponible (utilisé par les alias `TicketPreview`/`InvoicePreview` cf. `architecture` ligne 403).
- [ ] AC-03 — Typedef public `ComponentBuilder = Widget Function(ComponentConfig config, BuildContext ctx)`.

### Registry — API

- [ ] AC-04 — `ComponentRegistry.register(String type, ComponentBuilder builder)` ajoute un type. Idempotent : second `register` sur le même type override silencieusement avec un warning `dart:developer` log (pas d'exception — utile en hot reload dev).
- [ ] AC-05 — `ComponentRegistry.unregister(String type)` retire un type. Utilisé en tests.
- [ ] AC-06 — `ComponentRegistry.build(ComponentConfig config, BuildContext ctx) → Widget` retourne le widget construit ou `UnknownComponent(config.type)` si non enregistré. **Ne throw jamais.**
- [ ] AC-07 — `ComponentRegistry.isRegistered(String type) → bool` pour tests et tooling.
- [ ] AC-08 — `ComponentRegistry.registeredTypes → List<String>` retourne la liste triée alphabétiquement (utile pour debug screen + Widgetbook STORY-004).

### Registry — Intégration ErrorBoundary

- [ ] AC-09 — `build` enveloppe systématiquement le widget retourné dans un `ErrorBoundary(componentType: config.type, child: builder(...))`. Pour cette story, `ErrorBoundary` peut être un stub simple qui se contente de capturer l'exception et retourner le child ; l'implémentation complète est livrée par STORY-010.
- [ ] AC-10 — Aucun appel direct à `runZonedGuarded` ou `FlutterError.onError` dans cette story — ces hooks sont la responsabilité de STORY-010.

### Bootstrap Phase 1 — composants enregistrés

- [ ] AC-11 — `RegistryBootstrap.registerPhase1(registry)` enregistre **au moins** ces 7 builders, qui correspondent à la liste FR-001 :
  - `KPICard`, `DataTable`, `AlertBanner`, `ActionButton` (alias `FAB` mappé sur le même builder), `MouvementItem` (en lieu et place du `ListTile` générique — choix DS, cf. spec source ci-dessous), `FormWidget` (alias `FormSection`), `ChartWidget` (alias `ChartBar`).
- [ ] AC-12 — Chaque builder Phase 1 délègue à `Composant.fromConfig(config, ctx)` du widget DS (les widgets eux-mêmes sont livrés par STORY-003 ; cette story se borne à câbler le registry).
- [ ] AC-13 — Les alias `FAB` → `ActionButton`, `FormSection` → `FormWidget`, `ChartBar` → `ChartWidget`, `TicketPreview` → `ReceiptPreview` (avec `props.type='ticket'`) sont enregistrés explicitement.

### Comportement type inconnu

- [ ] AC-14 — `registry.build(ComponentConfig(type: "DoesNotExist", props: {}), ctx)` retourne un widget `UnknownComponent` qui :
  - Affiche un `AlertBanner` (variant warning, livré par STORY-003) avec le texte `Composant "DoesNotExist" indisponible`.
  - Loggue via `dart:developer` `log('UnknownComponent: DoesNotExist', name: 'BDUI')`.
  - Hauteur min = 56dp ; padding = `ScalarioSpacing.space4`.
- [ ] AC-15 — `UnknownComponent` ne crash jamais même si `props` est null/vide.

### Tests

- [ ] AC-16 — Tests unitaires (`test/engine/component_registry/`) couvrent :
  - `register` + `isRegistered` + `build` nominal pour chacun des 7 builders Phase 1 (mock widgets DS si STORY-003 pas encore mergée).
  - Type inconnu → `UnknownComponent` rendu (golden test `pumpWidget`).
  - `register` du même type 2 fois → 2e gagne, warning loggué (capturé via `IOOverrides`).
  - `unregister` → `isRegistered` retourne `false`.
  - `registeredTypes` ordre alphabétique vérifié.
  - `ComponentConfig.fromJson(jsonRetailDashboard)` → 7 composants parsés sans erreur.
- [ ] AC-17 — Couverture ≥ 90% sur `lib/engine/component_registry/` (Gate 0 BDUI).

### Hygiène architecture

- [ ] AC-18 — Aucun `if`/`switch` sur un domaine métier (rôle utilisateur, type entité, statut sale…) dans `lib/engine/component_registry/` — vérifié par grep en CI : pattern `if.*role|if.*MANAGER|if.*OWNER|switch.*module` dans le dossier engine doit retourner zéro match.
- [ ] AC-19 — Aucun import de `lib/features/` depuis `lib/engine/` — vérifié par lint custom (le moteur ne dépend jamais des features métier).
- [ ] AC-20 — `flutter analyze` passe sans warning.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/component_registry/`
- **Bootstrap :** appelé depuis `lib/main.dart` au démarrage avant `runApp`.
- **DI :** `get_it` (déjà à ajouter au `pubspec.yaml` ; partagé avec STORY-008 pour l'injection BDUIEngine).
- **Stub ErrorBoundary :** `lib/engine/error_boundary/error_boundary.dart` — stub minimal ici, complet en STORY-010.

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── engine/
│       ├── component_registry/
│       │   ├── component_config.dart
│       │   ├── component_builder.dart
│       │   ├── component_registry.dart
│       │   ├── registry_bootstrap.dart
│       │   └── unknown_component.dart
│       └── error_boundary/
│           └── error_boundary.dart   # stub Sprint 1, complet STORY-010
├── test/
│   └── engine/
│       └── component_registry/
│           ├── component_registry_test.dart
│           ├── registry_bootstrap_test.dart
│           ├── unknown_component_test.dart
│           └── fixtures/
│               └── retail_dashboard_minimal.json
└── pubspec.yaml                       # +get_it
```

### Pattern Dart recommandé

```dart
typedef ComponentBuilder =
    Widget Function(ComponentConfig config, BuildContext ctx);

class ComponentRegistry {
  ComponentRegistry();

  final Map<String, ComponentBuilder> _builders = {};

  void register(String type, ComponentBuilder builder) {
    if (_builders.containsKey(type)) {
      developer.log(
        'Override builder for type "$type"',
        name: 'BDUI',
        level: 900, // warning
      );
    }
    _builders[type] = builder;
  }

  void unregister(String type) => _builders.remove(type);

  bool isRegistered(String type) => _builders.containsKey(type);

  List<String> get registeredTypes =>
      _builders.keys.toList()..sort();

  Widget build(ComponentConfig config, BuildContext ctx) {
    final builder = _builders[config.type];
    if (builder == null) return UnknownComponent(config.type);
    return ErrorBoundary(
      componentType: config.type,
      componentId: config.id,
      child: builder(config, ctx),
    );
  }
}
```

Bootstrap :

```dart
abstract final class RegistryBootstrap {
  static void registerPhase1(ComponentRegistry r) {
    // 02 — Data Display
    r.register('KPICard',     (c, ctx) => KPICard.fromConfig(c, ctx));
    r.register('DataTable',   (c, ctx) => DataTable.fromConfig(c, ctx));
    r.register('ChartWidget', (c, ctx) => ChartWidget.fromConfig(c, ctx));
    r.register('ChartBar',    (c, ctx) => ChartWidget.fromConfig(c, ctx)); // alias

    // 01 — Feedback
    r.register('AlertBanner', (c, ctx) => AlertBanner.fromConfig(c, ctx));

    // 06 — Actions
    r.register('ActionButton', (c, ctx) => ActionButton.fromConfig(c, ctx));
    r.register('FAB',          (c, ctx) => ActionButton.fromConfig(c, ctx)); // alias

    // 03 — Inputs
    r.register('FormWidget',   (c, ctx) => FormWidget.fromConfig(c, ctx));
    r.register('FormSection',  (c, ctx) => FormWidget.fromConfig(c, ctx)); // alias

    // 02 — Lists métier (substitut de "ListTile" générique)
    r.register('MouvementItem', (c, ctx) => MouvementItem.fromConfig(c, ctx));
  }
}
```

### Spec source — résolution du conflit PRD ↔ DS

Le PRD §FR-001 (ligne 199) et le sprint plan listent `ListTile` parmi les composants initiaux. **Le DS ne contient pas de `ListTile` générique** — les listes métier sont matérialisées par `MouvementItem`, `StockListItem`, `OperationItem`, `LogItem`, `TransactionList` (cf. `design-process/D-Design-System/components/02-data-display.md` et `06-lists.md`).

**Décision :** enregistrer `MouvementItem` comme représentant Phase 1 du pattern "élément de liste". Les autres list items rejoignent le registry au fur et à mesure des stories EPIC-001. **DS gagne** sur la nomenclature ; PR de mise à jour PRD à ouvrir.

De même, `FAB` du PRD ↔ `ActionButton` du DS (variant `floating`) : on enregistre les deux strings comme alias du même builder. Documenté en commentaire dans `registry_bootstrap.dart`.

### Edge cases

- **`type` vide ou null dans le JSON** : `ComponentConfig.fromJson` doit déjà valider via JSON Schema (STORY-023). Si malgré tout un type vide arrive, traiter comme `UnknownComponent` avec message `Composant sans type`.
- **`props` null** : registry passe le config tel quel ; chaque builder doit être défensif côté DS (responsabilité STORY-003).
- **`config.id` doublon dans le même screen** : pas la responsabilité du registry — c'est l'Engine STORY-008 qui logge un warning. Ici, on enregistre tout sans dédupliquer.
- **Hot reload override** : en dev, modifier un builder et hot reload doit re-register sans crasher. Le warning suffit ; pas d'erreur.
- **DI singleton vs instance par tenant** : Phase 1, le registry est un singleton process. Phase 2, si on permet aux tenants d'enregistrer des composants custom, on instanciera un registry par tenant — pas dans le scope ici, mais l'API `register/unregister` le permet déjà.

### Sécurité

- Le registry ne charge **aucun code distant**. Pas de `eval`, pas de plugin dynamique, pas de `dlopen`. Tous les builders sont compilés AOT dans le binaire Flutter.
- Le `type` JSON est une string opaque pour le registry — il ne sert qu'à un lookup map. Aucune injection possible.
- `UnknownComponent` n'affiche pas la stack trace ni le `props` — uniquement le `type` (l'utilisateur ne fuit pas de données sensibles via un composant cassé).

### Performance

- Lookup `Map<String, ComponentBuilder>` : O(1), HashMap Dart natif. Mesuré < 0.01ms par lookup sur Snapdragon 680.
- Bootstrap Phase 1 : 10-15 `register` synchrones, < 1ms total.
- Ce composant ne contribue pas significativement au budget cold render < 200ms (cf. STORY-008). Le poids vient des builders DS eux-mêmes.

---

## Dependencies

**Prérequis :**

- STORY-001 (Design Tokens) — `merged`.
- STORY-002 (ThemeData) — `merged` (couleurs sémantiques pour `UnknownComponent`).
- STORY-003 (Composants DS Phase 1) — `merged` ou en parallèle ; au minimum stubs `KPICard.fromConfig` etc. disponibles.
- STORY-023 (JSON Schema `ComponentConfig`) — peut être en parallèle ; cette story implémente une version Dart manuelle qui sera regénérée par quicktype quand le schema sera figé.

**Stories bloquées par celle-ci :**

- STORY-008 (BDUIEngine) — directe.
- STORY-009 (Sandbox) — via STORY-008.
- STORY-010 (Error Boundaries) — extend le stub livré ici.
- STORY-011 (Validation forms) — utilise le registry pour `FormWidget`.
- Toutes les stories d'EPIC-001 livrant un nouveau composant DS doivent étendre le registry.

**Externes :**

- `get_it: ^7.x` — DI container.
- Pas d'API tierce.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-005-component-registry`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/component_registry/`.
- [ ] `flutter test test/engine/component_registry/` vert avec ≥ 90% coverage.
- [ ] Bootstrap Phase 1 enregistre les 7+ builders requis (10 entrées avec alias).
- [ ] Aucune logique métier dans le dossier engine (vérifié par grep CI).
- [ ] `lib/main.dart` appelle `RegistryBootstrap.registerPhase1` au démarrage avant `runApp`.
- [ ] Code review passé (auto-review Carlos + `/codex review` ou `/review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-005 status `completed`, completed_points sprint 1 += 5).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `ComponentConfig` + `Rule` + `DataSource` DTO + `fromJson`/`toJson` | 1 | Translation contrat partagé → Dart immutable. Préparé pour quicktype regen. |
| `ComponentRegistry` core (register, build, lookup, list types) | 1 | Map<String, Builder> + warning override + tests nominal. |
| `UnknownComponent` widget + i18n message + golden test | 0.5 | Réutilise AlertBanner DS. |
| Stub `ErrorBoundary` (wrapper passe-through) | 0.5 | API only — implémentation logée par STORY-010. |
| `RegistryBootstrap.registerPhase1` (7 builders + 3 alias) | 0.5 | Câblage déclaratif. |
| Tests unitaires + fixtures JSON | 1 | 6 tests core + golden + fixture retail dashboard minimal. |
| Lint custom (no-business-logic in engine) + grep CI | 0.5 | Script bash + intégration `flutter test` ou Dart custom_lint. |
| **Total** | **5** | Fibonacci 5 — moderate, infrastructural. |

**Rationale :** La logique pure est simple (HashMap + lookup), mais le poids vient du contrat (`ComponentConfig` doit être stable pour 73 composants), des tests (chaque builder Phase 1 + edge cases), et du **filet anti-régression** (lint qui empêche un dev de mettre du métier dans `lib/engine/`). Sans ce filet, l'Engine se transforme en god-class en sprint 3. Le registry porte aussi la responsabilité opérationnelle pour 66 stories à venir → on prend 5 points pour blinder.

---

## Notes additionnelles

- **Convention extension future :** quand une nouvelle story livre un composant DS (par ex. STORY-PD-XX `BluetoothDeviceSelector`), elle ajoute **une seule ligne** à `registry_bootstrap.dart`. Pas de modification de `ComponentRegistry` lui-même. Cette propriété est testable : si une PR modifie `component_registry.dart` pour ajouter un type, le reviewer doit pousser un refus.
- **Widgetbook (STORY-004) :** consomme `registry.registeredTypes` pour générer dynamiquement la liste des composants documentés — pas de duplication de la liste à maintenir.
- **JSON Schema codegen (STORY-023) :** quand le schéma sera figé, regénérer `component_config.dart` via quicktype. Le `fromJson` manuel actuel sert de pont en attendant.
- **Logo Scalario :** non concerné par cette story.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
