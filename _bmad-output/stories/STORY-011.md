# STORY-011 : Validation Formulaires Data-driven

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-003 (composants `FormWidget`, `TextInput`, `NumberInput`, `DatePicker`, `Toggle`), STORY-006 (RuleEvaluator — pour `required_if`), STORY-023 (JSON Schema — types `ValidationRule`)

---

## User Story

> **En tant que** `FormWidget` BDUI rendu depuis JSON,
> **je veux** que toutes mes règles de validation (required, min, max, regex, enum, required_if conditionnel) soient lues depuis le JSON et évaluées en temps réel,
> **so that** je n'ai **jamais** à coder de validation métier dans Flutter — un nouveau formulaire = un nouveau JSON, pas une ligne de Dart.

---

## Description

### Background

Le principe non-négociable Scalario : zéro logique métier dans le code Flutter. Les formulaires sont historiquement le piège n°1 — chaque dev veut écrire `if (email.isEmpty) return 'Email requis'` "vite fait". Cette story livre la **machinerie qui rend ce raccourci impossible** : un `ValidatorFactory` qui transforme une déclaration JSON en `FormFieldValidator<T>` Flutter standard.

L'architecture (`_bmad-output/architecture-scalario-2026-05-09.md` ligne 961) précise dans le contrat partagé :

```typescript
export interface ComponentConfig {
  // ...
  validation?: ValidationRule[];
}
```

Le PRD §FR-051 (ligne 303) liste les règles : `required`, `type`, `min`, `max`, `minLength`, `maxLength`, `regex`, `enum`. Le sprint plan ligne 268 ajoute `onBlur` vs `onChange` (timing).

Cette story complète le tableau avec :
- **`required_if`** — branche sur `RuleEvaluator` (STORY-006). Ex: "obligatoire si payment_method == 'credit'".
- **Messages d'erreur localisables** depuis le JSON (`error_messages: { required: "Ce champ est requis" }`) — par défaut, fallback sur des messages standard FR.
- **Validation backend miroir** documentée — la même `ValidationRule` est validée par Zod côté NestJS (FR-014). Ce story Flutter livre le côté UX ; le backend bloque toute requête malformée même si le client a contourné.

### Scope

**In scope :**

- Package `lib/engine/form_validation/` :
  - `validation_rule.dart` — DTO `ValidationRule` mappé sur le contrat partagé. Champs : `type` (`'required' | 'min' | 'max' | 'minLength' | 'maxLength' | 'regex' | 'enum' | 'required_if'`), `value: dynamic`, `errorKey: String?`, `errorMessage: String?`, `requiredIf: Rule?`.
  - `validator_factory.dart` — `ValidatorFactory.fromRules(List<ValidationRule>, BuildContext, FieldContext) → FormFieldValidator<T>` qui retourne un `String?` (message d'erreur ou null).
  - `field_context.dart` — passe le `UserContext`, le `formData` courant (autres champs du form), et le `RuleEvaluator` au validator pour évaluer `required_if`.
  - `validation_messages.dart` — fallback FR par défaut si `error_messages` JSON absent.
  - `form_widget_validation_extension.dart` — extension sur `FormWidget` (STORY-003) qui consomme `ValidatorFactory`.
- Validation timing : `validateOnBlur` (défaut) ou `validateOnChange` selon le JSON (`form.config.validate_on: 'blur' | 'change'`).
- Composants concernés : `TextInput`, `NumberInput`, `DatePicker`, `TimePicker`, `Toggle`, `ChipSelector` (single-select), `ProductSelector`. Chaque widget DS expose un `validator` prop qui consomme le résultat de `ValidatorFactory`.
- `FormWidget.submit()` (STORY-003) appelle `validateAll()` avant de déclencher l'action — bloque le submit si invalide, affiche les erreurs.
- Tests : chaque règle individuellement, combinaisons (required + minLength + regex), `required_if` avec `RuleEvaluator`, edge cases (null, empty string, type mismatch).

**Out of scope (autres stories) :**

- Composants form eux-mêmes (`TextInput`, `FormWidget`, etc.) → STORY-003.
- Validation backend Zod / NestJS → STORY-014.
- Async validators (vérification serveur d'unicité email) → backlog Phase 2.
- Validation cross-field complexe (autre que `required_if` qui passe par RuleEvaluator) → Phase 2 si besoin avéré ; Phase 1, suffisant.
- Affichage UX du message d'erreur (rouge sous le champ) → c'est le composant DS lui-même qui gère son `errorText` ; cette story livre juste la string.
- i18n complet du fallback FR → STORY-042 ; cette story livre les clés ARB préparées.

### Runtime Flow

1. Backend NestJS retourne un `FormWidget` JSON :

```json
{
  "type": "FormWidget",
  "id": "create_sale_form",
  "config": { "validate_on": "blur" },
  "props": {
    "fields": [
      {
        "type": "TextInput",
        "id": "client_phone",
        "props": { "label": "Téléphone client" },
        "validation": [
          { "type": "required" },
          { "type": "regex", "value": "^[0-9]{8}$", "errorKey": "phone_8_digits" }
        ]
      },
      {
        "type": "NumberInput",
        "id": "amount",
        "props": { "label": "Montant" },
        "validation": [
          { "type": "required" },
          { "type": "min", "value": 100 },
          { "type": "max", "value": 10000000 }
        ]
      },
      {
        "type": "TextInput",
        "id": "notes",
        "props": { "label": "Notes" },
        "validation": [
          { "type": "required_if", "requiredIf": { "field": "amount", "operator": ">", "value": 500000 } }
        ]
      }
    ],
    "submit_action": "create_sale"
  }
}
```

2. `FormWidget.fromConfig` parse les fields. Pour chaque field, `ValidatorFactory.fromRules(field.validation, ctx, fieldCtx)` retourne un `FormFieldValidator<dynamic>`.
3. L'utilisateur tape "12345" dans `client_phone` → onBlur déclenche le validator → regex échoue → message "Téléphone à 8 chiffres" (depuis `errorKey: phone_8_digits` ou fallback FR).
4. L'utilisateur saisit `amount: 800000` → champ `notes` devient required (via `required_if` qui consomme `RuleEvaluator.evaluate`). Le label `Notes` ajoute un asterisque rouge dynamiquement.
5. L'utilisateur clique submit → `FormWidget.submit()` itère les fields, appelle chaque validator → si tout est null (pas d'erreur), POST l'action `create_sale`. Sinon, bloque et affiche les erreurs.
6. Backend NestJS re-valide via Zod (FR-014). Si client a bypassé, backend bloque (defense in depth).

---

## Acceptance Criteria

### Modèle ValidationRule

- [ ] AC-01 — `ValidationRule` immutable avec champs : `type: String`, `value: dynamic`, `errorKey: String?`, `errorMessage: String?`, `requiredIf: Rule?`.
- [ ] AC-02 — `ValidationRule.fromJson(Map)` parse les 8 types : `required`, `type`, `min`, `max`, `minLength`, `maxLength`, `regex`, `enum`, `required_if`. Type inconnu → `ValidationParseException`.
- [ ] AC-03 — `==` + `hashCode` corrects pour mémoization éventuelle.

### Règles de base

- [ ] AC-04 — **`required`** : valeur null, vide string, ou empty list → erreur. `false` pour `Toggle` est valide (c'est une valeur), pas null.
- [ ] AC-05 — **`type`** : `string`, `number`, `integer`, `date`, `boolean`. Mismatch → erreur.
- [ ] AC-06 — **`min` / `max`** : sur `num`. `value < min` ou `value > max` → erreur. Inclusif (`>=` / `<=`).
- [ ] AC-07 — **`minLength` / `maxLength`** : sur `String`. Comptage en `length` runes (pas bytes — gère UTF-8 correctement).
- [ ] AC-08 — **`regex`** : sur `String`. Match RE2-compatible. Regex invalide en JSON → `ValidationParseException` au parse-time.
- [ ] AC-09 — **`enum`** : `value: List<dynamic>`. Valeur non-incluse → erreur. Comparaison `==` standard.

### Règle conditionnelle `required_if`

- [ ] AC-10 — `required_if` consomme `RuleEvaluator.evaluate(rule, userCtx, formData)` où `formData` est la `Map<String, dynamic>` des autres champs du form courant.
- [ ] AC-11 — Si `RuleEvaluator` retourne `true` → `required_if` se comporte comme `required`. Si `false` → la règle est skip (champ optionnel).
- [ ] AC-12 — Le label du field a un asterisque dynamique : présent quand `required_if` évalue à `true`. Pas de re-render coûteux — `setState` minimal sur change.

### Timing

- [ ] AC-13 — `form.config.validate_on: 'blur'` (défaut) → validator appelé sur perte de focus du field.
- [ ] AC-14 — `form.config.validate_on: 'change'` → validator appelé à chaque keystroke.
- [ ] AC-15 — `FormWidget.submit()` appelle `validateAll()` indépendamment du `validate_on` — bloque le submit si invalide.

### Messages d'erreur

- [ ] AC-16 — Priorité de résolution du message :
  1. `errorMessage` direct dans `ValidationRule` (string brut).
  2. `errorKey` qui pointe vers un `arb_key` i18n (ex: `validation.phone.eight_digits`).
  3. Fallback générique FR (`ValidationMessages.defaultFor(type)`).
- [ ] AC-17 — `ValidationMessages` français par défaut :
  - `required` → "Ce champ est requis".
  - `min` → "Valeur minimum : {min}" (interpolation).
  - `max` → "Valeur maximum : {max}".
  - `minLength` → "Au moins {min} caractères".
  - `maxLength` → "Maximum {max} caractères".
  - `regex` → "Format invalide".
  - `enum` → "Valeur non autorisée".
  - `type` → "Type {type} attendu".
  - `required_if` → même message que `required`.
- [ ] AC-18 — Interpolation `{key}` dans les messages remplace par la valeur de la rule.

### Intégration FormWidget

- [ ] AC-19 — `FormWidget.fromConfig` (livré par STORY-003) accepte un nouveau prop `validators: Map<String, FormFieldValidator>` injecté par `ValidatorFactory`.
- [ ] AC-20 — `FormWidget.validateAll() → bool` — itère tous les fields, appelle leur validator, retourne `false` si au moins une erreur, met à jour les `errorText` des composants DS.
- [ ] AC-21 — Le rendu du formulaire intègre l'état "valid/invalid" sans re-render full screen — granularité au champ.

### Sécurité

- [ ] AC-22 — **Defense in depth** documenté : un commentaire en tête de `validator_factory.dart` rappelle que cette validation est UX-only, et que le backend NestJS Zod (FR-014) est la véritable barrière.
- [ ] AC-23 — Regex côté client : capper la longueur du pattern à 1024 caractères et la longueur de l'input à 10000 caractères pour éviter ReDoS sur appareils bas de gamme. Documenter.
- [ ] AC-24 — Aucune `eval` ni interprétation de code dans les validators — uniquement données vs données.

### Tests

- [ ] AC-25 — Tests unitaires pour chaque règle (8 tests minimum) :
  - `required` : null, "", [], {} → erreur ; `0`, `false`, "x", `[1]` → OK.
  - `type` : tous les mismatchs.
  - `min/max` : boundary (=min, =max, juste sous, juste au-dessus).
  - `minLength/maxLength` : UTF-8 émoji "🇧🇫" comme test (1 rune ou 2 runes ?).
  - `regex` : pattern invalide → exception parse-time ; valide → match correct.
  - `enum` : valeur non-incluse, valeur null.
  - `required_if` : RuleEvaluator true vs false.
- [ ] AC-26 — Test combinaisons : `required + minLength: 8 + regex: phone` sur `client_phone` — ordre d'évaluation : required → length → regex (early return au premier échec).
- [ ] AC-27 — Test timing : `validate_on: 'change'` déclenche validator chaque keystroke ; `validate_on: 'blur'` seulement au focus loss.
- [ ] AC-28 — Test de bout en bout : fixture `simple_form.json` avec 4 fields → 4 validators câblés → submit avec données invalides bloque, données valides passe.
- [ ] AC-29 — Couverture ≥ 90% sur `lib/engine/form_validation/`.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/form_validation/`.
- **Dépend de :** `RuleEvaluator` (STORY-006) — pour `required_if`.
- **Étend :** `FormWidget` + composants input DS (STORY-003).

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── engine/
│       └── form_validation/
│           ├── validation_rule.dart
│           ├── validator_factory.dart
│           ├── field_context.dart
│           ├── validation_messages.dart
│           ├── validation_exception.dart
│           └── form_validation.dart   # barrel
├── test/
│   └── engine/
│       └── form_validation/
│           ├── validation_rule_test.dart
│           ├── validator_factory_test.dart
│           ├── required_if_test.dart
│           ├── validation_messages_test.dart
│           └── form_widget_integration_test.dart
```

### Pattern Dart recommandé

```dart
@immutable
final class ValidationRule {
  const ValidationRule({
    required this.type,
    this.value,
    this.errorKey,
    this.errorMessage,
    this.requiredIf,
  });
  final String type;
  final Object? value;
  final String? errorKey;
  final String? errorMessage;
  final Rule? requiredIf;

  factory ValidationRule.fromJson(Map<String, dynamic> json) { /* ... */ }
}

class ValidatorFactory {
  ValidatorFactory({required this.evaluator, required this.messages});
  final RuleEvaluator evaluator;
  final ValidationMessages messages;

  FormFieldValidator<T> fromRules<T>(
    List<ValidationRule> rules,
    FieldContext fieldCtx,
  ) {
    return (T? value) {
      for (final rule in rules) {
        final error = _check(rule, value, fieldCtx);
        if (error != null) return error;
      }
      return null;
    };
  }

  String? _check(ValidationRule rule, dynamic value, FieldContext ctx) {
    return switch (rule.type) {
      'required'    => _checkRequired(value, rule),
      'min'         => _checkMin(value, rule),
      'max'         => _checkMax(value, rule),
      'minLength'   => _checkMinLength(value, rule),
      'maxLength'   => _checkMaxLength(value, rule),
      'regex'       => _checkRegex(value, rule),
      'enum'        => _checkEnum(value, rule),
      'type'        => _checkType(value, rule),
      'required_if' => _checkRequiredIf(value, rule, ctx),
      _             => null,
    };
  }

  String? _checkRequiredIf(dynamic value, ValidationRule rule, FieldContext ctx) {
    final isRequired = evaluator.evaluate(rule.requiredIf, ctx.userCtx, ctx.formData);
    if (!isRequired) return null;
    return _checkRequired(value, rule);
  }
}
```

### Spec source — résolution du conflit

Le PRD §FR-051 et le sprint plan ligne 268 listent : `required`, `type`, `min`, `max`, `minLength`, `maxLength`, `regex`, `enum`. **La DS (`design-process/D-Design-System/components/03-inputs.md`) parle de `validation_rule` (string singulier — regex ou règle backend)**.

**Conflit :**
- PRD/sprint = liste de règles structurées (8 types).
- DS = un string unique.

**Décision :** la DS est obsolète sur ce point — elle est antérieure à la finalisation du contrat shared. Le contrat shared `ValidationRule[]` (architecture ligne 961) gagne. **Suivre le contrat shared.** PR de mise à jour DS à ouvrir en parallèle pour aligner `03-inputs.md` sur le tableau prop : `validation_rule: string` → `validation: ValidationRule[]`.

Pour `required_if` : le sprint plan ne le mentionne pas explicitement, mais STORY-011 dépend de STORY-006 (RuleEvaluator). Le besoin est clair (formulaires conditionnels = pattern majeur en B2B). **Décision :** ajouter `required_if` dans cette story — coût marginal faible car RuleEvaluator est déjà fait en STORY-006. Ce qui ferait économiser une story Phase 2. Documenté.

### Edge cases

- **Champ Toggle = `false`** : `required` doit accepter `false` comme valeur valide (l'utilisateur a explicitement décliné). Seul `null` est invalide. C'est subtil — toujours tester ce cas.
- **Champ NumberInput = `0`** : idem — `0` est une valeur valide, pas null. Beaucoup d'implémentations classiques se font piéger.
- **String "0"** vs **number 0** : si `type: number`, on parse en num. `"0"` valide passe en `0` ; `"abc"` invalide → erreur `type`.
- **Date format** : `type: date` accepte ISO 8601 (`2026-05-12`) ou un timestamp millisecondes. Documenter dans le JSON Schema. Phase 1, supporter ISO 8601 + un mapping `Locale fr_BF` (DD/MM/YYYY).
- **Regex ReDoS** : un regex naïf comme `^(a+)+$` peut bloquer 2 secondes sur Snapdragon 680. Capper longueur regex + input + timer 50ms en safety net (si dépassement, reject le pattern + log warning).
- **Multi-byte UTF-8** : "Bénin" = 5 runes mais 6 bytes UTF-8. Toujours utiliser `.runes.length` ou `.characters.length` (du package `characters`), jamais `.length`.
- **Champ optionnel avec regex** : si `value == null` et `required` absent, regex skip — un champ vide n'est pas un format invalide.
- **Submit pendant `validate_on: 'blur'`** : si l'utilisateur n'a jamais touché un field (pas de blur), le validator n'a pas tourné. `validateAll()` doit forcer une validation initiale de tous les fields.

### Sécurité

- **Backend Zod = source de vérité** : commenté dans `validator_factory.dart`. Toute validation client peut être bypassée.
- **Pas de pattern `eval` ni `dart:mirrors`** — uniquement comparaison de données.
- **Regex DoS protection** : timer de 50ms + cap de 1024 chars sur le pattern.
- **PII dans les messages d'erreur** : un message comme `"Email Aïssata@x.com déjà utilisé"` est un leak. Toujours messages génériques (`"Email déjà utilisé"`).

### Performance

- Validators sont des closures pures, pas de coût d'allocation par appel.
- `validate_on: 'change'` peut être coûteux si validators lourds (regex complexe). Documenter et préférer `'blur'` par défaut.
- `validateAll()` au submit : O(N) sur N fields, chaque validator < 1ms. Pour N=20 fields, ~20ms — imperceptible.

---

## Dependencies

**Prérequis :**

- STORY-003 (composants form DS : `FormWidget`, `TextInput`, `NumberInput`, `DatePicker`, `Toggle`, `ChipSelector`) — `merged`.
- STORY-006 (RuleEvaluator) — `merged`.
- STORY-023 (JSON Schema) — peut être en parallèle ; cette story implémente `ValidationRule.fromJson` manuellement.

**Stories bloquées par celle-ci :**

- STORY-008 (BDUIEngine) — indirecte (rend les FormWidget qui utilisent ces validators).
- STORY-014 (Backend Zod) — collaborative (mêmes règles côté NestJS).
- Toutes les stories EPIC-007 livrant un formulaire (Pharmacie, Retail, BTP) — directes.

**Externes :**

- Aucun.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-011-form-validation`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/form_validation/`.
- [ ] `flutter test test/engine/form_validation/` vert avec ≥ 90% coverage.
- [ ] Test combinaisons : 8 règles individuelles + 3 combinaisons + `required_if` avec RuleEvaluator.
- [ ] Test ReDoS protection : pattern dangereux + input long → timeout ou rejection en < 50ms.
- [ ] Documentation : table des règles dans `docs/form-validation.md` (référence dev + référence générateur IA de templates).
- [ ] Fixture sandbox `simple_form.json` (STORY-009) inclut un `required_if` pour démontrer.
- [ ] Code review passé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-011 status `completed`, completed_points sprint 1 += 3).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `ValidationRule` DTO + fromJson + 8 types parsing | 0.5 | Translation directe du contrat. |
| `ValidatorFactory` + 9 méthodes `_check*` | 1 | Logique pure — coeur de la story. |
| `required_if` integration RuleEvaluator + asterisque dynamique label | 0.5 | Tricky — dynamique sur change d'autre field. |
| `ValidationMessages` FR + interpolation `{key}` | 0.25 | Trivial. |
| Wiring FormWidget + composants input (`validator` prop) | 0.25 | Petit câblage, mais à propager sur 7 widgets DS. |
| Tests unitaires (8 règles + combos + required_if + ReDoS) | 0.5 | Filet critique — sans, on ne peut pas faire confiance aux validators. |
| **Total** | **3** | Fibonacci 3 — petit mais structurant. |

**Rationale :** Logique pure, mais beaucoup d'edge cases à blinder (Toggle false, NumberInput 0, runes vs bytes, ReDoS, required_if dynamique). La rigueur des tests est ce qui rend les futurs formulaires fiables. 3 points est juste — et les économies viennent du fait que RuleEvaluator (STORY-006) fait déjà 90% du boulot pour `required_if`.

---

## Notes additionnelles

- **Defense in depth (NestJS Zod, FR-014) :** documentation explicite que la validation client est UX-only. Une PR de STORY-014 (backend) doit livrer la même grammaire de règles côté Zod — les deux schémas sont générés depuis le même JSON Schema (STORY-023). Cette propriété "grammaire partagée" est ce qui évite les divergences front/back.
- **Génération IA de templates :** une fois cette story livrée, l'IA peut générer des formulaires complets (`{ "type": "FormWidget", "props": {"fields": [...]} }`) sans qu'aucun code Dart ne change. C'est la **preuve clé** du pattern data-driven.
- **i18n complet (STORY-042) :** cette story livre les `arb_key` et le fallback FR. Quand i18n est complet, les messages s'affichent dans la langue de l'utilisateur sans changement ici.
- **Async validators Phase 2 :** vérification serveur (email unique, code-barre existant) → ajouter un type `ValidationRule.async` qui POST une route NestJS de check. Pas dans cette story.
- **Logo Scalario / branding :** non concerné.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
