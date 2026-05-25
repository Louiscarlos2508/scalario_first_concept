import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  const evaluator = ScalarioCanvasRule();

  const ctx = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'MANAGER'},
  );

  group('AC-12 — == and != operators', () {
    test('== matches equal string', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': '==',
        'value': 'active',
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'active'}),
        isTrue,
      );
    });

    test('== fails on different string', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': '==',
        'value': 'active',
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'inactive'}),
        isFalse,
      );
    });

    test('!= returns true when values differ', () {
      final rule = Rule.fromJson(const {
        'field': 'record.payment_method',
        'operator': '!=',
        'value': 'cash',
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'payment_method': 'mobile_money'}),
        isTrue,
      );
    });

    test('!= returns false when values equal', () {
      final rule = Rule.fromJson(const {
        'field': 'record.payment_method',
        'operator': '!=',
        'value': 'cash',
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'payment_method': 'cash'}),
        isFalse,
      );
    });

    test('== works with bool value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.is_verified',
        'operator': '==',
        'value': true,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'is_verified': true}),
        isTrue,
      );
      expect(
        evaluator.evaluate(rule, ctx, const {'is_verified': false}),
        isFalse,
      );
    });

    test('== null == null returns true (AC-19)', () {
      final rule = Rule.fromJson(const {
        'field': 'record.optional_field',
        'operator': '==',
        'value': null,
      });
      // field absent → resolves to null; null == null = true
      expect(evaluator.evaluate(rule, ctx, const {}), isTrue);
    });
  });

  group('AC-13 — numeric comparison operators', () {
    test('> returns true when field > value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.montant',
        'operator': '>',
        'value': 500000,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'montant': 600000}),
        isTrue,
      );
    });

    test('> returns false when field <= value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.montant',
        'operator': '>',
        'value': 500000,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'montant': 500000}),
        isFalse,
      );
    });

    test('< returns true when field < value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.stock_qty',
        'operator': '<',
        'value': 5,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'stock_qty': 3}),
        isTrue,
      );
    });

    test('>= boundary — equal is true', () {
      final rule = Rule.fromJson(const {
        'field': 'record.qty',
        'operator': '>=',
        'value': 10,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'qty': 10}),
        isTrue,
      );
    });

    test('<= boundary — equal is true', () {
      final rule = Rule.fromJson(const {
        'field': 'record.qty',
        'operator': '<=',
        'value': 10,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'qty': 10}),
        isTrue,
      );
    });

    test('non-numeric field with numeric operator returns false + no throw', () {
      final rule = Rule.fromJson(const {
        'field': 'record.name',
        'operator': '>',
        'value': 5,
      });
      // type mismatch: String vs num — fail-safe false (AC-13)
      expect(
        evaluator.evaluate(rule, ctx, const {'name': 'Alice'}),
        isFalse,
      );
    });

    test('null field with numeric operator returns false (AC-19)', () {
      final rule = Rule.fromJson(const {
        'field': 'record.missing',
        'operator': '>',
        'value': 0,
      });
      expect(evaluator.evaluate(rule, ctx, const {}), isFalse);
    });

    test('double value works', () {
      final rule = Rule.fromJson(const {
        'field': 'record.rate',
        'operator': '>=',
        'value': 0.5,
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'rate': 0.75}),
        isTrue,
      );
    });
  });

  group('AC-14 — in / not_in operators', () {
    test('in returns true when field is in list', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'in',
        'value': <Object?>['draft', 'pending'],
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'pending'}),
        isTrue,
      );
    });

    test('in returns false when field is not in list', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'in',
        'value': <Object?>['draft', 'pending'],
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'completed'}),
        isFalse,
      );
    });

    test('not_in returns true when field is absent from list', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'not_in',
        'value': <Object?>['closed', 'cancelled'],
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'active'}),
        isTrue,
      );
    });

    test('not_in returns false when field is in excluded list', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'not_in',
        'value': <Object?>['closed', 'cancelled'],
      });
      expect(
        evaluator.evaluate(rule, ctx, const {'status': 'cancelled'}),
        isFalse,
      );
    });
  });

  group('Unknown operator', () {
    test('unknown operator evaluates to false without throwing', () {
      // Bypass parser validation by constructing Rule directly
      const rule = Rule(operator: 'BETWEEN', field: 'record.x', value: 0);
      expect(evaluator.evaluate(rule, ctx, const {'x': 5}), isFalse);
    });
  });
}
