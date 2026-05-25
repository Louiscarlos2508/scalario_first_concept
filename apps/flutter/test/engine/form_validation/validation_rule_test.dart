import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/form_validation/form_validation.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ValidationRule.fromJson — 9 types (AC-02)
  // ---------------------------------------------------------------------------

  group('ValidationRule.fromJson — valid types', () {
    test('required parses without value', () {
      final rule = ValidationRule.fromJson(const {'type': 'required'});
      expect(rule.type, 'required');
      expect(rule.value, isNull);
    });

    test('type parses with string value', () {
      final rule =
          ValidationRule.fromJson(const {'type': 'type', 'value': 'number'});
      expect(rule.type, 'type');
      expect(rule.value, 'number');
    });

    test('min parses with numeric value', () {
      final rule =
          ValidationRule.fromJson(const {'type': 'min', 'value': 100});
      expect(rule.type, 'min');
      expect(rule.value, 100);
    });

    test('max parses with numeric value', () {
      final rule =
          ValidationRule.fromJson(const {'type': 'max', 'value': 10000000});
      expect(rule.value, 10000000);
    });

    test('minLength parses with int value', () {
      final rule =
          ValidationRule.fromJson(const {'type': 'minLength', 'value': 8});
      expect(rule.value, 8);
    });

    test('maxLength parses with int value', () {
      final rule =
          ValidationRule.fromJson(const {'type': 'maxLength', 'value': 100});
      expect(rule.value, 100);
    });

    test('regex parses valid pattern', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'regex',
        'value': r'^[0-9]{8}$',
      });
      expect(rule.type, 'regex');
      expect(rule.value, r'^[0-9]{8}$');
    });

    test('enum parses with list value', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'enum',
        'value': <dynamic>['draft', 'pending', 'paid'],
      });
      expect(rule.value, ['draft', 'pending', 'paid']);
    });

    test('required_if parses with valid requiredIf rule', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'required_if',
        'requiredIf': {
          'field': 'amount',
          'operator': '>',
          'value': 500000,
        },
      });
      expect(rule.type, 'required_if');
      expect(rule.requiredIf, isNotNull);
      expect(rule.requiredIf!.operator, '>');
    });

    test('errorMessage and errorKey are preserved', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'required',
        'errorMessage': 'Ce champ ne peut pas être vide',
        'errorKey': 'validation.required',
      });
      expect(rule.errorMessage, 'Ce champ ne peut pas être vide');
      expect(rule.errorKey, 'validation.required');
    });
  });

  // ---------------------------------------------------------------------------
  // ValidationParseException cases (AC-02)
  // ---------------------------------------------------------------------------

  group('ValidationRule.fromJson — ValidationParseException', () {
    test('unknown type throws', () {
      expect(
        () => ValidationRule.fromJson(const {'type': 'notAType'}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('missing type throws', () {
      expect(
        () => ValidationRule.fromJson(const {}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('null type throws', () {
      expect(
        () => ValidationRule.fromJson(const {'type': null}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('required_if without requiredIf field throws', () {
      expect(
        () => ValidationRule.fromJson(const {'type': 'required_if'}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('required_if with non-map requiredIf throws', () {
      expect(
        () => ValidationRule.fromJson(const {
          'type': 'required_if',
          'requiredIf': 'bad',
        }),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('regex with non-string value throws', () {
      expect(
        () => ValidationRule.fromJson(const {'type': 'regex', 'value': 42}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('regex with invalid pattern throws (AC-08)', () {
      expect(
        () => ValidationRule.fromJson(const {
          'type': 'regex',
          'value': r'[invalid',
        }),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('regex with pattern > 1024 chars throws (AC-23)', () {
      final longPattern = 'a' * 1025;
      expect(
        () => ValidationRule.fromJson({'type': 'regex', 'value': longPattern}),
        throwsA(isA<ValidationParseException>()),
      );
    });

    test('required_if with invalid requiredIf rule throws', () {
      expect(
        () => ValidationRule.fromJson(const {
          'type': 'required_if',
          'requiredIf': {'unknownKey': 'x'},
        }),
        throwsA(isA<ValidationParseException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Equality and hashCode (AC-03)
  // ---------------------------------------------------------------------------

  group('ValidationRule — == and hashCode (AC-03)', () {
    test('identical rules are equal', () {
      final a = ValidationRule.fromJson(const {'type': 'required'});
      final b = ValidationRule.fromJson(const {'type': 'required'});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different type → not equal', () {
      final a = ValidationRule.fromJson(const {'type': 'required'});
      final b =
          ValidationRule.fromJson(const {'type': 'min', 'value': 0});
      expect(a, isNot(equals(b)));
    });

    test('different value → not equal', () {
      final a =
          ValidationRule.fromJson(const {'type': 'min', 'value': 100});
      final b =
          ValidationRule.fromJson(const {'type': 'min', 'value': 200});
      expect(a, isNot(equals(b)));
    });

    test('enum rules with same list are equal', () {
      final a = ValidationRule.fromJson(const {
        'type': 'enum',
        'value': <dynamic>['a', 'b'],
      });
      final b = ValidationRule.fromJson(const {
        'type': 'enum',
        'value': <dynamic>['a', 'b'],
      });
      expect(a, equals(b));
    });

    test('regex 1024-char boundary is valid', () {
      final borderPattern = 'a' * 1024;
      final rule =
          ValidationRule.fromJson({'type': 'regex', 'value': borderPattern});
      expect(rule.value, borderPattern);
    });
  });

  // ---------------------------------------------------------------------------
  // required_if requiredIf rule is correctly parsed as Rule
  // ---------------------------------------------------------------------------

  group('ValidationRule — required_if rule integration', () {
    test('requiredIf resolves to a valid Rule', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'required_if',
        'requiredIf': {
          'field': 'payment_method',
          'operator': '==',
          'value': 'credit',
        },
      });
      expect(rule.requiredIf, isA<Rule>());
      expect(rule.requiredIf!.field, 'payment_method');
      expect(rule.requiredIf!.value, 'credit');
    });

    test('requiredIf supports logical AND', () {
      final rule = ValidationRule.fromJson(const {
        'type': 'required_if',
        'requiredIf': {
          'AND': <dynamic>[
            {'field': 'amount', 'operator': '>', 'value': 500000},
            {'field': 'client_type', 'operator': '==', 'value': 'business'},
          ],
        },
      });
      expect(rule.requiredIf!.operator, 'AND');
      expect(rule.requiredIf!.children, hasLength(2));
    });
  });
}
