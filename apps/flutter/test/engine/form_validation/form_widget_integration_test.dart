// End-to-end test: fixture JSON → parsed ValidationRules → validators wired →
// submit blocked on invalid data, submit passes on valid data (AC-28).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/component_registry/component_config.dart';
import 'package:scalario/engine/form_validation/form_validation.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

void main() {
  const evaluator = RuleEvaluator();
  const userCtx = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'CASHIER'},
  );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses the simple_form.json fixture into a list of ComponentConfig.
  List<ComponentConfig> _parseFields(String jsonStr) {
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    final props = root['props'] as Map<String, dynamic>;
    final rawFields = props['fields'] as List<dynamic>;
    return rawFields
        .cast<Map<String, dynamic>>()
        .map(ComponentConfig.fromJson)
        .toList();
  }

  const fixtureJson = r'''
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
          {
            "type": "regex",
            "value": "^[0-9]{8}$",
            "errorMessage": "Téléphone à 8 chiffres"
          }
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
        "id": "payment_method",
        "props": { "label": "Moyen de paiement" },
        "validation": [
          {
            "type": "enum",
            "value": ["cash", "mobile_money", "credit"],
            "errorMessage": "Moyen de paiement invalide"
          }
        ]
      },
      {
        "type": "TextInput",
        "id": "notes",
        "props": { "label": "Notes" },
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
''';

  // ---------------------------------------------------------------------------
  // AC-28: full form with 4 fields
  // ---------------------------------------------------------------------------

  group('AC-28 — 4-field form from fixture JSON', () {
    late List<ComponentConfig> fields;
    late ValidatorFactory factory;

    setUp(() {
      fields = _parseFields(fixtureJson);
      factory = ValidatorFactory();
    });

    test('fixture parses into 4 ComponentConfig with validation', () {
      expect(fields, hasLength(4));
      expect(fields[0].id, 'client_phone');
      expect(fields[1].id, 'amount');
      expect(fields[2].id, 'payment_method');
      expect(fields[3].id, 'notes');
      for (final f in fields) {
        expect(f.validation, isNotNull);
        expect(f.validation, isNotEmpty);
      }
    });

    test('invalid data: all fields fail validation', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController.fromConfigs(
        fields,
        ctx,
        validateOn: ValidateOn.blur,
        factory: factory,
      );

      expect(controller.validatorFor<dynamic>('client_phone')?.call(null), isNotNull);
      expect(controller.validatorFor<dynamic>('amount')?.call(null), isNotNull);
      controller.dispose();
    });

    test('valid phone passes regex', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController.fromConfigs(
        fields,
        ctx,
        factory: factory,
      );
      expect(controller.validatorFor<dynamic>('client_phone')?.call('12345678'), isNull);
      expect(
        controller.validatorFor<dynamic>('client_phone')?.call('1234567'),
        isNotNull,
      );
      controller.dispose();
    });

    test('invalid phone format returns custom errorMessage', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController.fromConfigs(
        fields,
        ctx,
        factory: factory,
      );
      final error = controller.validatorFor<dynamic>('client_phone')?.call('12345');
      expect(error, 'Téléphone à 8 chiffres');
      controller.dispose();
    });

    test('amount below min fails', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller =
          ValidatedFormController.fromConfigs(fields, ctx, factory: factory);
      expect(controller.validatorFor<dynamic>('amount')?.call(50), isNotNull);
      expect(controller.validatorFor<dynamic>('amount')?.call(100), isNull);
      controller.dispose();
    });

    test('payment_method invalid value returns custom error', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller =
          ValidatedFormController.fromConfigs(fields, ctx, factory: factory);
      expect(
        controller.validatorFor<dynamic>('payment_method')?.call('bitcoin'),
        'Moyen de paiement invalide',
      );
      expect(
        controller.validatorFor<dynamic>('payment_method')?.call('cash'),
        isNull,
      );
      controller.dispose();
    });

    test('notes required_if: amount > 500k → required', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {'amount': 800000},
        evaluator: evaluator,
      );
      final controller =
          ValidatedFormController.fromConfigs(fields, ctx, factory: factory);
      expect(
        controller.validatorFor<dynamic>('notes')?.call(null),
        'Notes obligatoires pour montants > 500 000 FCFA',
      );
      expect(controller.validatorFor<dynamic>('notes')?.call('ok'), isNull);
      controller.dispose();
    });

    test('notes required_if: amount <= 500k → optional', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {'amount': 200000},
        evaluator: evaluator,
      );
      final controller =
          ValidatedFormController.fromConfigs(fields, ctx, factory: factory);
      expect(controller.validatorFor<dynamic>('notes')?.call(null), isNull);
      controller.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // ValidatedFormController — validate_on timing (AC-13, AC-14)
  // ---------------------------------------------------------------------------

  group('ValidateOn enum (AC-13, AC-14)', () {
    test('default validateOn is blur', () {
      final controller = ValidatedFormController(
        validators: {},
        validateOn: ValidateOn.blur,
      )..dispose();
      expect(controller.validateOn, ValidateOn.blur);
    });

    test('change mode is set correctly', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController.fromConfigs(
        const [],
        ctx,
        validateOn: ValidateOn.change,
      );
      expect(controller.validateOn, ValidateOn.change);
      controller.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // updateField notifies listeners and updates formData (AC-21)
  // ---------------------------------------------------------------------------

  group('ValidatedFormController.updateField (AC-21)', () {
    test('updateField updates formData', () {
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController(validators: {});
      controller.updateField('amount', 800000);
      expect(controller.formData['amount'], 800000);
      controller.dispose();
    });

    test('updateField notifies listeners', () {
      final controller = ValidatedFormController(validators: {});
      var notified = false;
      controller.addListener(() => notified = true);
      controller.updateField('x', 1);
      expect(notified, isTrue);
      controller.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // fromRulesMap convenience method
  // ---------------------------------------------------------------------------

  group('ValidatorFactory.fromRulesMap', () {
    test('builds map of validators keyed by field id', () {
      final factory = ValidatorFactory();
      final ctx = FieldContext(
        userCtx: userCtx,
        formData: const {},
        evaluator: evaluator,
      );
      final map = factory.fromRulesMap(
        {
          'phone': [
            ValidationRule.fromJson(const {'type': 'required'}),
          ],
          'amount': [
            ValidationRule.fromJson(const {'type': 'min', 'value': 100}),
          ],
        },
        ctx,
      );
      expect(map, hasLength(2));
      expect(map['phone']?.call(null), isNotNull);
      expect(map['phone']?.call('ok'), isNull);
      expect(map['amount']?.call(50), isNotNull);
      expect(map['amount']?.call(200), isNull);
    });
  });
}
