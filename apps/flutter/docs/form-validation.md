# Form Validation Data-driven — STORY-011

> **Defense in depth:** La validation client décrite ici est UX-only (retour utilisateur immédiat). La véritable barrière de sécurité est le backend NestJS Zod (FR-014, STORY-014). Tout formulaire peut être bypassé côté client — ne jamais prendre de décision de sécurité sur la seule validation Flutter.

---

## Vue d'ensemble

Le package `lib/engine/form_validation/` transforme des déclarations JSON en `FormFieldValidator<T>` Flutter standards. Résultat : **zero logique de validation dans le code Dart** — un nouveau formulaire = un nouveau JSON.

---

## Règles supportées

| Type | Valeur `value` | Comportement |
|------|----------------|--------------|
| `required` | — | Null, `""`, `[]` → erreur. `false`, `0` sont valides. |
| `type` | `string\|number\|integer\|date\|boolean` | Type mismatch → erreur. `null` → skip. |
| `min` | `num` | Valeur < min → erreur (inclusif : `>=` min est valide). |
| `max` | `num` | Valeur > max → erreur (inclusif : `<=` max est valide). |
| `minLength` | `int` | Longueur en **runes** (code points UTF-8) < min → erreur. |
| `maxLength` | `int` | Longueur en **runes** > max → erreur. |
| `regex` | `String` pattern | String ne matchant pas → erreur. `null` ou `""` → skip. |
| `enum` | `List<dynamic>` | Valeur absente de la liste → erreur. |
| `required_if` | — | Délègue à `RuleEvaluator` (STORY-006) via `requiredIf` rule. |

### Edge cases critiques

- **Toggle `false`** : `required` accepte `false` comme valeur valide (l'utilisateur a explicitement décliné). Seul `null` est absent.
- **NumberInput `0`** : `required` accepte `0`. Beaucoup d'implémentations se font piéger sur ce cas.
- **Champ optionnel + regex** : si `value == null` et `required` absent, `regex` est skippé — champ vide ≠ format invalide.
- **UTF-8 multi-byte** : `minLength`/`maxLength` utilisent `.runes.length` (code points), pas `.length` (code units). `"🇧🇫".runes.length == 2`.
- **`type: integer`** : `5.0` (double sans partie fractionnaire) est valide comme integer.

---

## Messages d'erreur

Priorité de résolution (AC-16) :

1. `errorMessage` direct dans `ValidationRule` (string brut, supports placeholders).
2. `errorKey` → clé ARB i18n (stub Phase 1 — STORY-042 câble le système i18n complet).
3. Fallback générique FR (`ValidationMessages.defaultFor(type)`).

### Fallbacks FR

| Type | Message |
|------|---------|
| `required` / `required_if` | "Ce champ est requis" |
| `min` | "Valeur minimum : {min}" |
| `max` | "Valeur maximum : {max}" |
| `minLength` | "Au moins {min} caractères" |
| `maxLength` | "Maximum {max} caractères" |
| `regex` | "Format invalide" |
| `enum` | "Valeur non autorisée" |
| `type` | "Type {type} attendu" |

Les placeholders `{min}`, `{max}`, `{type}`, `{value}` sont remplacés par la valeur de la règle.

---

## Sécurité

### ReDoS

- Pattern regex capé à **1024 caractères** au parse-time (`ValidationRule.fromJson`) → `ValidationParseException` si dépassé.
- Input capé à **10 000 caractères** avant matching.
- Timer 50 ms : si le matching dépasse 50 ms, la validation client est skippée + warning loggé. Le backend Zod (FR-014) reste la safety net.

### Pas d'injection de code

- Aucun `eval`, aucun `dart:mirrors` — uniquement comparaison de données.

---

## Utilisation

### 1. Règles simples

```dart
final factory = ValidatorFactory();
final ctx = FieldContext(
  userCtx: userCtx,
  formData: currentFormData,
  evaluator: const RuleEvaluator(),
);

final validator = factory.fromRules<String>([
  ValidationRule.fromJson({'type': 'required'}),
  ValidationRule.fromJson({'type': 'minLength', 'value': 8}),
  ValidationRule.fromJson({'type': 'regex', 'value': r'^[0-9]{8}$'}),
], ctx);

TextFormField(validator: validator, ...)
```

### 2. Depuis un FormWidget JSON (usage BDUI normal)

```dart
final fields = componentConfigs; // parsed from backend JSON
final controller = ValidatedFormController.fromConfigs(
  fields,
  fieldCtx,
  validateOn: ValidateOn.blur, // or ValidateOn.change
);

// In your widget:
TextFormField(
  validator: controller.validatorFor<String>('client_phone'),
  onChanged: (v) => controller.updateField('client_phone', v),
)

// Submit guard:
ElevatedButton(
  onPressed: () {
    if (controller.validateAll(_formKey)) {
      // dispatch action
    }
  },
)
```

### 3. required_if + asterisque dynamique

```dart
// Dans le build() du widget label :
ListenableBuilder(
  listenable: controller,
  builder: (ctx, _) {
    final isRequired = controller.isRequiredIf('notes', fieldCtx);
    return Text('Notes${isRequired ? ' *' : ''}');
  },
)
```

---

## JSON Schema — exemple complet

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
        "validation": [
          { "type": "required" },
          {
            "type": "regex",
            "value": "^[0-9]{8}$",
            "errorKey": "validation.phone.eight_digits",
            "errorMessage": "Téléphone à 8 chiffres"
          }
        ]
      },
      {
        "type": "NumberInput",
        "id": "amount",
        "validation": [
          { "type": "required" },
          { "type": "min", "value": 100 },
          { "type": "max", "value": 10000000 }
        ]
      },
      {
        "type": "TextInput",
        "id": "notes",
        "validation": [
          {
            "type": "required_if",
            "requiredIf": { "field": "amount", "operator": ">", "value": 500000 },
            "errorMessage": "Notes obligatoires pour montants > 500 000 FCFA"
          }
        ]
      }
    ]
  }
}
```

---

## Architecture

```
lib/engine/form_validation/
├── validation_exception.dart      # ValidationParseException (parse-time errors)
├── validation_rule.dart           # ValidationRule DTO + fromJson (9 types)
├── validation_messages.dart       # French fallback messages + {key} templates
├── field_context.dart             # Runtime context: userCtx + formData + evaluator
├── validator_factory.dart         # Core: fromRules() → FormFieldValidator<T>
├── form_widget_validation_extension.dart  # ValidatedFormController + ValidateOn
└── form_validation.dart           # Barrel export
```

### Dépendances

- `lib/engine/rule_evaluator/` (STORY-006) — pour `required_if`
- `lib/engine/component_registry/component_config.dart` — pour `fromConfigs`
- Flutter `widgets.dart` — pour `FormFieldValidator`, `ChangeNotifier`, `GlobalKey<FormState>`

### Ce qui n'est PAS dans ce package

- Composants DS (`TextInput`, `NumberInput`, etc.) → STORY-003
- Validation async serveur (unicité email) → Phase 2
- i18n complet (`errorKey` lookup) → STORY-042
- Backend Zod validation → STORY-014
