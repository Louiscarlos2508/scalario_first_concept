import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/form_validation/form_validation.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

void main() {
  const messages = ValidationMessages();

  // ---------------------------------------------------------------------------
  // Default French messages (AC-17)
  // ---------------------------------------------------------------------------

  group('ValidationMessages.defaultFor — AC-17', () {
    test('required returns French message', () {
      expect(messages.defaultFor('required'), 'Ce champ est requis');
    });

    test('required_if returns same message as required', () {
      expect(
        messages.defaultFor('required_if'),
        equals(messages.defaultFor('required')),
      );
    });

    test('min returns template with {min} placeholder', () {
      expect(messages.defaultFor('min'), contains('{min}'));
    });

    test('max returns template with {max} placeholder', () {
      expect(messages.defaultFor('max'), contains('{max}'));
    });

    test('minLength returns template with {min} placeholder', () {
      expect(messages.defaultFor('minLength'), contains('{min}'));
    });

    test('maxLength returns template with {max} placeholder', () {
      expect(messages.defaultFor('maxLength'), contains('{max}'));
    });

    test('regex returns format-invalid message', () {
      expect(messages.defaultFor('regex'), 'Format invalide');
    });

    test('enum returns non-allowed message', () {
      expect(messages.defaultFor('enum'), 'Valeur non autorisée');
    });

    test('type returns template with {type} placeholder', () {
      expect(messages.defaultFor('type'), contains('{type}'));
    });

    test('unknown type returns generic fallback', () {
      expect(messages.defaultFor('unknownType'), 'Valeur invalide');
    });
  });

  // ---------------------------------------------------------------------------
  // Message interpolation via ValidatorFactory (AC-18)
  // ---------------------------------------------------------------------------

  group('ValidatorFactory — message interpolation (AC-18)', () {
    final factory = ValidatorFactory();
    final ctx = _buildCtx();

    test('min message interpolates numeric value', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'min', 'value': 100}),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      final error = validator(50);
      expect(error, contains('100'));
    });

    test('max message interpolates numeric value', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'max', 'value': 1000}),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      final error = validator(2000);
      expect(error, contains('1000'));
    });

    test('minLength message interpolates length value', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'minLength', 'value': 8}),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      final error = validator('abc');
      expect(error, contains('8'));
    });

    test('type message interpolates type name', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'type', 'value': 'number'}),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      final error = validator('notANumber');
      expect(error, contains('number'));
    });

    test('custom errorMessage overrides fallback', () {
      final rules = [
        ValidationRule.fromJson(const {
          'type': 'required',
          'errorMessage': 'Veuillez renseigner ce champ',
        }),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      expect(validator(null), 'Veuillez renseigner ce champ');
    });

    test('custom errorMessage supports {min} placeholder', () {
      final rules = [
        ValidationRule.fromJson(const {
          'type': 'min',
          'value': 500,
          'errorMessage': 'Montant minimum requis : {min} FCFA',
        }),
      ];
      final validator = factory.fromRules<dynamic>(rules, ctx);
      final error = validator(100);
      expect(error, 'Montant minimum requis : 500 FCFA');
    });
  });
}

FieldContext _buildCtx() => const FieldContext(
      userCtx: UserContext(
        userId: 'u1',
        tenantId: 't1',
        roles: {'CASHIER'},
      ),
      formData: {},
      evaluator: RuleEvaluator(),
    );
