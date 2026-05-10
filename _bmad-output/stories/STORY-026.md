# STORY-026 : Validation Bidirectionnelle JSON Runtime

**Epic :** EPIC-004 — Module Engine & Catalogue JSON
**Priorité :** Must Have
**Story Points :** 2
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 3 (2026-06-09 → 2026-06-20)
**Dependencies :** STORY-008 (BDUIEngine + ErrorBoundary), STORY-023 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant que** BDUIEngine Flutter (et en tant qu'utilisateur final qui ne doit jamais voir un crash),
> **je veux** valider chaque payload JSON reçu du backend **avant** de le parser,
> **so that** un JSON inattendu (cassé, malformé, ou d'une version inconnue) **ne crashe jamais** l'app — il déclenche un fallback UI propre + un log d'erreur.

---

## Description

### Background — Le filet de sécurité côté client

Le backend NestJS est censé envoyer du JSON valide (Zod en CI + bootstrap fail-fast — STORY-024). Mais "censé" n'est pas "garanti" :

- Bug dans `BDUIService` après filtrage RBAC.
- Cache Redis corrompu.
- Tenant config patché à la main par un admin pressé.
- Un test E2E qui injecte un JSON malicieux.
- Un déploiement avec des versions désynchronisées (backend en `v1.1.0`, Flutter en `v1.0.0`).

Si l'app crashe sur un de ces cas, Blandine perd la fenêtre de vente. Le pari **offline-first / zero crash** (cf §FR-053, NFR-004) impose :

> **Le Flutter valide ce qu'il reçoit. Toujours. Et fallback gracieusement.**

C'est une **double validation** : NestJS valide en sortie (Zod), Flutter valide en entrée (JSON Schema). Le contrat est le même (STORY-023) — donc cohérence garantie tant que les deux dérivent du même `catalog/schemas/*.json`.

### Scope

**In scope :**

- Layer Dart `apps/flutter/lib/core/bdui/validation/` :
  - `schema_validator.dart` — wrapper de `json_schema_dart` (validation contre les fichiers `*.schema.json`).
  - `validation_result.dart` — type union `Valid | Invalid(errors)`.
  - `bdui_validator.dart` — facade : valide selon le type (`ScreenConfig`, `ComponentConfig`, `ModuleConfig`).
- Embedding des fichiers `catalog/schemas/*.schema.json` dans les assets Flutter (`pubspec.yaml > flutter > assets`) — chargés une fois au démarrage, parsés en singleton.
- Intégration dans le pipeline `BDUIEngine.render()` (STORY-005) : validation **avant** parsing en `ScreenConfig`. Si invalide, retour `FallbackScreen` widget + log structuré.
- Intégration dans le pipeline `ApiClient` (STORY-009 / STORY-010) : tout body de réponse `/layout/*` ou `/data` ou `/action` validé avant parsing.
- `FallbackScreen` widget : affiche "Quelque chose s'est mal passé. Nous avons enregistré le problème" + bouton `Réessayer` + détails techniques en mode dev (caché en prod).
- Log structuré envoyé via `LoggingService` (STORY-019 ou équivalent) avec `event: bdui.invalid_payload`, `screen_id`, `errors[]`.
- Tests E2E : backend mocké renvoie un JSON intentionnellement invalide → app affiche `FallbackScreen`, log capturé.

**Out of scope (autres stories) :**

- Validation Zod côté NestJS → STORY-024.
- ErrorBoundary par composant individuel (chaque widget BDUI) → STORY-008.
- L'écriture des JSON Schemas → STORY-023.
- La réconciliation de version `schema_version` mismatch (Phase 2 — pour Phase 1, mismatch = invalid).

### User Flow

1. App Flutter démarre, charge les schémas en mémoire (assets bundle).
2. Blandine ouvre `/ventes`.
3. `ApiClient` appelle `GET /api/v1/blandine/layout/ventes`.
4. Réponse JSON arrive → `BduiValidator.validate(json, type: 'screen-config')`.
5. **Cas valide** → parsing en `ScreenConfig` → `BDUIEngine.render()` → UI affichée.
6. **Cas invalide** (ex: `zones` manquant, `layout` enum inconnu) → `BduiValidator` retourne `Invalid(errors)` → :
   - Log : `bdui.invalid_payload` avec `screen_id`, `errors[]`, `payload_hash`.
   - UI : `FallbackScreen` avec message FR + bouton réessayer.
   - Pas de crash, pas d'écran blanc, pas de stack trace user-facing.

---

## Acceptance Criteria

### Validator Dart

- [ ] AC-01 — Layer `lib/core/bdui/validation/` créé avec les fichiers `schema_validator.dart`, `validation_result.dart`, `bdui_validator.dart`, `fallback_screen.dart`.
- [ ] AC-02 — Package `json_schema` (Dart pub.dev) ajouté dans `pubspec.yaml`.
- [ ] AC-03 — Les fichiers `catalog/schemas/component-config.schema.json`, `screen-config.schema.json`, `module-config.schema.json`, `workflow.schema.json` sont **embarqués dans les assets** Flutter (`flutter > assets > [...]`) — chemin `assets/bdui-schemas/`.
- [ ] AC-04 — `BduiValidator` est un singleton DI-injectable, charge les schémas une seule fois au démarrage (`init()` async) et expose une API synchrone pour la validation (les schémas sont compilés une fois).

### API validation

- [ ] AC-05 — `BduiValidator.validate(Map<String, dynamic> json, BduiType type) → ValidationResult` où `BduiType ∈ { screenConfig, componentConfig, moduleConfig, workflow }`.
- [ ] AC-06 — `ValidationResult` est un sealed class : `Valid()` ou `Invalid(List<ValidationError> errors)`.
- [ ] AC-07 — `ValidationError` contient : `path` (string, ex: `.zones.kpis[2].type`), `message` (string FR), `keyword` (string, ex: `required`, `enum`).
- [ ] AC-08 — `BduiValidator.init()` doit être appelé avant la première validation (sinon throw `BduiValidatorNotInitialized`). Idéalement appelé dans le `main()` Flutter ou via la DI bootstrap.

### Intégration BDUIEngine

- [ ] AC-09 — `BDUIEngine.render(json, ctx)` (STORY-005) valide le JSON via `BduiValidator.validate(...screenConfig)` avant de parser.
- [ ] AC-10 — Si invalide : retourne `FallbackScreen` widget, **jamais throw**. Log via `LoggingService.error('bdui.invalid_payload', ...)`.
- [ ] AC-11 — Le `FallbackScreen` :
  - Affiche un message FR : "Cet écran n'a pas pu être chargé. Nous avons enregistré le problème."
  - Affiche un bouton "Réessayer" qui re-déclenche le fetch.
  - En mode debug (`kDebugMode`), affiche les `errors[]` en dépliable.
  - En mode release, masque les détails (juste un ID d'incident affiché : `error_id: abc123`).

### Intégration ApiClient

- [ ] AC-12 — Le client HTTP (Dio interceptor ou wrapper) valide les réponses des endpoints connus :
  - `GET /layout/:id` → `BduiType.screenConfig`.
  - `GET /:moduleId/data` → schema `DataResponse` (à définir, mais pour Phase 1 on valide juste la structure top-level `{items, total, kpis?, meta}`).
  - `POST /:moduleId/action` → schema `ActionResponse`.
- [ ] AC-13 — Si invalide, l'interceptor convertit la réponse en `Failure(BduiInvalidPayloadException)` — pas d'exception non typée qui remonte.

### Logs & observabilité

- [ ] AC-14 — Log structuré `event: 'bdui.invalid_payload'` avec : `screen_id` ou `endpoint`, `errors_count`, `errors[].path` (limité à 10), `payload_hash` (SHA-256 hex 16 chars), `schema_version_received`.
- [ ] AC-15 — Le `payload` brut **n'est jamais loggé** (RGPD + taille). Seul le hash + les paths d'erreur.
- [ ] AC-16 — Métrique compteur : `bdui.invalid_payload.count` taggée `endpoint` — visible côté observabilité (Phase 2 stretch, mais l'event log doit être cohérent dès Phase 1).

### Tests

- [ ] AC-17 — Test unitaire : `BduiValidator.validate` accepte le payload `valid_minimal.json` (de STORY-023) → retourne `Valid()`.
- [ ] AC-18 — Test unitaire : `BduiValidator.validate` rejette un payload avec `zones` manquant → retourne `Invalid` avec un error path `.zones`.
- [ ] AC-19 — Test widget : `BDUIEngine.render(invalidJson, ctx)` retourne un `FallbackScreen` (pumpWidget assertion) — pas de exception remontée.
- [ ] AC-20 — Test E2E : mock `ApiClient` qui renvoie un JSON cassé → l'écran affiche `FallbackScreen` (golden test ou widget test).
- [ ] AC-21 — Cohérence backend ↔ frontend : test partagé qui charge les fichiers `valid_*.json` de STORY-023 (côté backend examples) et les passe au validator Flutter → tous OK. Garantit que les deux validators sont d'accord.

### Contrat partagé

- [ ] AC-22 — Référence dans `catalog/schemas/README.md` : "le contrat est partagé — Zod (NestJS) ET json_schema (Flutter) dérivent des mêmes fichiers `*.schema.json`. Si vous voyez une divergence, c'est un bug."

---

## Technical Notes

### Composants concernés

- **Nouveau layer :** `apps/flutter/lib/core/bdui/validation/`.
- **Nouveau widget :** `apps/flutter/lib/core/bdui/fallback_screen.dart`.
- **Modifs :** `apps/flutter/pubspec.yaml` (assets + dependency `json_schema`), `apps/flutter/lib/core/bdui/bdui_engine.dart` (intégration), `apps/flutter/lib/core/api/api_client.dart` (interceptor).

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── core/
│       └── bdui/
│           ├── validation/
│           │   ├── bdui_validator.dart           # Facade
│           │   ├── schema_validator.dart         # Wrap json_schema
│           │   ├── validation_result.dart        # sealed Valid | Invalid
│           │   └── bdui_type.dart                # enum
│           ├── fallback_screen.dart              # Widget UI fallback
│           └── bdui_engine.dart                  # Modifié — validation gate
├── assets/
│   └── bdui-schemas/                              # Embedded copies of catalog/schemas/*
│       ├── component-config.schema.json
│       ├── screen-config.schema.json
│       ├── module-config.schema.json
│       └── workflow.schema.json
├── pubspec.yaml                                   # + json_schema, + assets
└── test/
    └── core/bdui/validation/
        ├── bdui_validator_test.dart
        ├── fallback_screen_test.dart
        └── e2e_invalid_payload_test.dart

scripts/
└── sync-schemas-to-flutter.sh                     # Copy catalog/schemas/*.json → assets/bdui-schemas/
```

### Code patterns (Dart)

**`validation_result.dart` :**

```dart
sealed class ValidationResult {
  const ValidationResult();
}

final class Valid extends ValidationResult {
  const Valid();
}

final class Invalid extends ValidationResult {
  final List<ValidationError> errors;
  const Invalid(this.errors);
}

class ValidationError {
  final String path;       // ex: '.zones.kpis[2].type'
  final String message;    // FR
  final String keyword;    // ex: 'required', 'enum'

  const ValidationError({
    required this.path,
    required this.message,
    required this.keyword,
  });
}
```

**`bdui_validator.dart` :**

```dart
class BduiValidator {
  static BduiValidator? _instance;
  static BduiValidator get I {
    if (_instance == null) {
      throw StateError('BduiValidator not initialized. Call init() in main().');
    }
    return _instance!;
  }

  final Map<BduiType, JsonSchema> _schemas;

  BduiValidator._(this._schemas);

  static Future<void> init() async {
    final loaders = {
      BduiType.componentConfig: 'assets/bdui-schemas/component-config.schema.json',
      BduiType.screenConfig:    'assets/bdui-schemas/screen-config.schema.json',
      BduiType.moduleConfig:    'assets/bdui-schemas/module-config.schema.json',
      BduiType.workflow:        'assets/bdui-schemas/workflow.schema.json',
    };
    final schemas = <BduiType, JsonSchema>{};
    for (final entry in loaders.entries) {
      final raw = await rootBundle.loadString(entry.value);
      schemas[entry.key] = JsonSchema.create(jsonDecode(raw));
    }
    _instance = BduiValidator._(schemas);
  }

  ValidationResult validate(Object? json, BduiType type) {
    final schema = _schemas[type];
    if (schema == null) {
      return Invalid([ValidationError(
        path: '',
        message: 'Type de schéma inconnu : $type',
        keyword: 'internal',
      )]);
    }
    final result = schema.validate(json);
    if (result.isValid) return const Valid();
    return Invalid(result.errors.map(_toValidationError).toList());
  }

  ValidationError _toValidationError(ValidationError srcErr) {
    // Map keyword → message FR (parallèle au mapping Zod côté NestJS)
    return ValidationError(
      path: srcErr.instancePath ?? '',
      message: _frMessage(srcErr),
      keyword: srcErr.schemaPath ?? '',
    );
  }
}
```

**Intégration `BDUIEngine.render` :**

```dart
class BDUIEngine {
  Widget render(Map<String, dynamic> rawJson, BuildContext ctx) {
    final result = BduiValidator.I.validate(rawJson, BduiType.screenConfig);
    if (result is Invalid) {
      LoggingService.I.error('bdui.invalid_payload', meta: {
        'screen_id': rawJson['screen'] ?? '<unknown>',
        'errors_count': result.errors.length,
        'errors_paths': result.errors.take(10).map((e) => e.path).toList(),
        'payload_hash': sha256.convert(utf8.encode(jsonEncode(rawJson))).toString().substring(0, 16),
        'schema_version_received': rawJson['schema_version'],
      });
      return FallbackScreen(errors: result.errors);
    }
    final config = ScreenConfig.fromJson(rawJson);
    return _renderConfig(config, ctx);
  }
}
```

**`fallback_screen.dart` :**

```dart
class FallbackScreen extends StatelessWidget {
  final List<ValidationError> errors;
  final VoidCallback? onRetry;
  const FallbackScreen({super.key, required this.errors, this.onRetry});

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: ScalarioColors.warning500),
            const SizedBox(height: 16),
            Text(
              "Cet écran n'a pas pu être chargé.\nNous avons enregistré le problème.",
              textAlign: TextAlign.center,
              style: ScalarioTypography.bodyLg,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                title: const Text('Détails techniques (debug)'),
                children: errors.map((e) => ListTile(
                  title: Text(e.path),
                  subtitle: Text('${e.keyword}: ${e.message}'),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Edge cases

- **Schémas non chargés** : si `init()` n'a pas été appelé, premier accès throw `StateError` clair. Documenté dans le README et dans le `main()`.
- **`schema_version` mismatch** : Phase 1, traité comme invalid (le `const "1.0.0"` du schema rejette toute autre valeur). Phase 2, accepter v1.1.0 si Flutter sait gérer.
- **Cycle deep-nested** : un payload artificiellement profond peut faire boucler le validator. `json_schema` package a des protections, mais on ajoute un check préliminaire de taille (`> 1 MB` → reject sans validation).
- **Performance** : la validation d'un screen-config typique (< 100 KB) prend < 5 ms — négligeable dans un fetch HTTP. Mesurer via un test perf si dépasse 20 ms.
- **Différence Ajv (NestJS) vs json_schema (Flutter)** : les deux supportent Draft 2020-12 mais peuvent diverger sur des cas exotiques (`if/then/else` complexes). Restreindre les schémas à un subset compatible des deux. Tester via AC-21.

### Sécurité

- **Pas de payload brut dans logs** — uniquement hash + paths.
- **Pas de leak en prod** — `kDebugMode` gate sur les détails techniques.
- **DoS protection** — taille max payload 1 MB (paramétrable).
- **Le validator ne fait pas confiance au backend** — c'est le principe même de cette story. Aucun fast-path "skip if from trusted host".

---

## Dependencies

**Prérequis :**

- STORY-008 — BDUIEngine + ErrorBoundary par composant. Cette story ajoute la validation **en amont** ; STORY-008 gère la résilience par widget en aval.
- STORY-023 — JSON Schemas (sources des fichiers embarqués).
- STORY-002 — ThemeData (pour `FallbackScreen` UI).
- STORY-005 — BDUIEngine (intégration de la validation gate).

**Stories bloquées par celle-ci :**

- STORY-039 (template retail_fresh_produce.json) — sa qualité est testable car le filet existe.
- STORY-005, STORY-008 finalisations — le contrat de fallback est défini ici.

**Externes :**

- `json_schema` (pub.dev) — package Dart, mature, supporte Draft 2020-12.
- `crypto` (pub.dev) pour SHA-256.

---

## Definition of Done

- [ ] Code commité sur `feat/story-026-bidirectional-validation`.
- [ ] `flutter analyze` 0 warning sur `lib/core/bdui/validation/`.
- [ ] `flutter test apps/flutter/test/core/bdui/validation/` ≥ 90% coverage.
- [ ] Schémas embarqués vérifiables : `flutter run` charge les assets sans erreur.
- [ ] Test E2E "JSON cassé → FallbackScreen" passe.
- [ ] Test partagé "examples STORY-023 valid → Flutter valide" passe.
- [ ] Script `sync-schemas-to-flutter.sh` documenté (ou alternative : symlink, ou copy pre-commit hook).
- [ ] PR review (`/codex review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` : STORY-026 status `completed`, sprint 3 completed_points += 2.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Layer validation Dart (`BduiValidator` singleton + `init()` async) | 0.5 | Wrap `json_schema`, mapping FR. |
| `FallbackScreen` widget (debug + release modes) | 0.25 | Soin sur le copy FR + UX retry. |
| Embedding schémas dans assets + script `sync-schemas-to-flutter.sh` | 0.25 | Bash + pubspec asset entry. |
| Intégration BDUIEngine + ApiClient interceptor | 0.5 | Modifier 2 entry points existants. |
| Logs structurés + payload hash | 0.25 | Pattern standard. |
| Tests unitaires + widget + E2E + cohérence cross-validator | 0.25 | Le test cohérence (AC-21) est le plus précieux. |
| **Total** | **2** | Fibonacci 2 — light. |

**Rationale :** Story chirurgicale : peu de surface mais haute valeur (zéro crash bdui = NFR-004). La complexité est dans la **cohérence cross-validator** (Zod NestJS ↔ json_schema Flutter) — d'où le test partagé AC-21 obligatoire.

---

## Notes additionnelles

- **Spec source :** `architecture-scalario-2026-05-09.md` ligne 49 (validation bidirectionnelle), ligne 1214 (NestJS Zod + Flutter JSON Schema = double validation), ligne 158 (`json_schema_dart` package). PRD §FR-053.
- **Nom du package Dart :** la spec mentionne `json_schema_dart` mais le package canonique sur pub.dev est `json_schema`. Utiliser `json_schema` (Workiva fork ou packages mainstream) ; documenter le choix.
- **Sync schemas** : 3 options pour propager `catalog/schemas/*.json` vers `apps/flutter/assets/bdui-schemas/` :
  - **Option A — script manuel** (`scripts/sync-schemas-to-flutter.sh`) appelé en pre-commit ou pré-build. Simple, friable.
  - **Option B — symlink Unix** (`apps/flutter/assets/bdui-schemas → ../../catalog/schemas`). Pas de duplication mais ne fonctionne pas sur Windows ni dans certains bundlers Flutter.
  - **Option C — pre-build hook Flutter** via `dart run` script qui copie au build. Plus robuste, plus complexe.
  - **Choix Phase 1** : Option A (script + git pre-commit hook). Option C en Phase 2 si friction.
- **Si `json_schema` (pub.dev) ne supporte pas tous les cas Draft 2020-12** : restreindre les schémas à un subset, ou utiliser un autre package (`json_schema_validator`). Test AC-21 validera empiriquement.
- **Évolution future (Phase 2)** : remplacer la validation runtime par des **types Dart générés** (STORY-027 quicktype) + `freezed` `fromJson` strict. Le runtime validator devient un filet de sécurité en debug seulement.
- **Interaction avec STORY-008 ErrorBoundary** : 
  - STORY-026 (cette story) : validation **avant** parsing → si invalide, `FallbackScreen` global.
  - STORY-008 : `ErrorBoundary` autour de **chaque composant** instancié → si un composant individuel throw au runtime, fallback localisé (`UnknownComponent` ou message d'erreur dans la zone).
  - Les deux sont complémentaires, pas redondants.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
