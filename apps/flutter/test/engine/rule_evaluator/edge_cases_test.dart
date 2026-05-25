/// Targeted tests for paths not hit by the main operator test suites.
///
/// Covers:
///  - Rule.fromJson exception paths (role invalid type, empty field, non-string op, non-Map child)
///  - Rule.== edge cases (children one-null/one-not, different lengths)
///  - Rule._deepEquals for non-List non-equal values
///  - Rule.toString()
///  - FieldResolver unknown prefix + user.roles
///  - ScalarioCanvasRule._evaluateRole with direct String value
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  const evaluator = ScalarioCanvasRule();
  const resolver = FieldResolver();
  const ctx = UserContext(userId: 'u', tenantId: 't', roles: {'MANAGER'});

  // ---------------------------------------------------------------------------
  // Rule.fromJson — additional exception paths
  // ---------------------------------------------------------------------------

  group('Rule.fromJson — additional error paths', () {
    test('role with invalid type (int) throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {'role': 42}),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('field with empty string throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'field': '',
          'operator': '==',
          'value': 1,
        }),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('field with non-string type throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'field': 123,
          'operator': '==',
          'value': 1,
        }),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('operator with non-string type throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'field': 'record.x',
          'operator': 99,
          'value': 1,
        }),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('AND with non-Map child throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'AND': <Object?>['not_a_map'],
        }),
        throwsA(isA<RuleParseException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule.== edge cases
  // ---------------------------------------------------------------------------

  group('Rule.== edge cases', () {
    test('rule with children vs rule without children → not equal', () {
      final withChildren = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
        ],
      });
      const withoutChildren = Rule(operator: 'AND');
      expect(withChildren, isNot(equals(withoutChildren)));
      expect(withoutChildren, isNot(equals(withChildren)));
    });

    test('rules with same operator but different children lengths → not equal',
        () {
      final two = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
          {'role': 'DG'},
        ],
      });
      final one = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
        ],
      });
      expect(two, isNot(equals(one)));
    });

    test('rules with same value (non-List) are equal', () {
      const a = Rule(operator: '==', field: 'record.x', value: 'hello');
      const b = Rule(operator: '==', field: 'record.x', value: 'hello');
      expect(a, equals(b));
    });

    test('rules with different non-List values are not equal', () {
      const a = Rule(operator: '==', field: 'record.x', value: 'hello');
      const b = Rule(operator: '==', field: 'record.x', value: 'world');
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // Rule.toString()
  // ---------------------------------------------------------------------------

  group('Rule.toString()', () {
    test('toString contains operator and field', () {
      const rule = Rule(operator: '>', field: 'record.montant', value: 500000);
      final str = rule.toString();
      expect(str, contains('>'));
      expect(str, contains('record.montant'));
    });
  });

  // ---------------------------------------------------------------------------
  // FieldResolver — unknown prefix + user.roles
  // ---------------------------------------------------------------------------

  group('FieldResolver additional paths', () {
    test('user.roles returns roles as list', () {
      const richCtx = UserContext(
        userId: 'u',
        tenantId: 't',
        roles: {'MANAGER', 'CASHIER'},
      );
      final result = resolver.resolve('user.roles', richCtx);
      expect(result, isA<List<Object?>>());
      expect(result as List<Object?>, containsAll(<String>['MANAGER', 'CASHIER']));
    });

    test('unknown prefix treated as record key chain — returns null when no data',
        () {
      // path that starts with neither 'user' nor 'record'
      final result = resolver.resolve('external.field', ctx);
      expect(result, isNull);
    });

    test('unknown prefix resolves from provided recordData', () {
      final result = resolver.resolve(
        'external.field',
        ctx,
        const {'external': <String, Object?>{'field': 'found'}},
      );
      // best-effort: treats 'external' as first key, 'field' as second
      expect(result, 'found');
    });
  });

  // ---------------------------------------------------------------------------
  // ScalarioCanvasRule._evaluateRole — String branch (direct Rule construction)
  // ---------------------------------------------------------------------------

  group('ScalarioCanvasRule._evaluateRole with direct Rule(value: String)', () {
    test('String value matching a role returns true', () {
      // Parser normalises 'role' strings to List, but the evaluator also
      // handles raw String values for defensive robustness.
      const rule = Rule(operator: 'role', value: 'MANAGER');
      expect(evaluator.evaluate(rule, ctx), isTrue);
    });

    test('String value not matching any role returns false', () {
      const rule = Rule(operator: 'role', value: 'DG');
      expect(evaluator.evaluate(rule, ctx), isFalse);
    });
  });
}
