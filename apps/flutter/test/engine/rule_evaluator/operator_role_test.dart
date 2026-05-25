import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  const evaluator = ScalarioCanvasRule();

  const manager = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'MANAGER'},
  );

  const managerDg = UserContext(
    userId: 'u2',
    tenantId: 't1',
    roles: {'MANAGER', 'DG'},
  );

  const cashier = UserContext(
    userId: 'u3',
    tenantId: 't1',
    roles: {'CASHIER'},
  );

  const emptyRoles = UserContext(
    userId: 'u4',
    tenantId: 't1',
    roles: {},
  );

  group('AC-10 — single role match', () {
    test('user with matching role returns true', () {
      final rule = Rule.fromJson(const {'role': <Object?>['MANAGER']});
      expect(evaluator.evaluate(rule, manager), isTrue);
    });

    test('user without matching role returns false', () {
      final rule = Rule.fromJson(const {'role': <Object?>['MANAGER']});
      expect(evaluator.evaluate(rule, cashier), isFalse);
    });

    test('role as string shortcut parses and evaluates', () {
      final rule = Rule.fromJson(const {'role': 'MANAGER'});
      expect(evaluator.evaluate(rule, manager), isTrue);
      expect(evaluator.evaluate(rule, cashier), isFalse);
    });
  });

  group('AC-11 — multi-role list (any-match)', () {
    test('user with one of the roles returns true', () {
      final rule = Rule.fromJson(const {
        'role': <Object?>['MANAGER', 'DG'],
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
    });

    test('user with both roles returns true', () {
      final rule = Rule.fromJson(const {
        'role': <Object?>['MANAGER', 'DG'],
      });
      expect(evaluator.evaluate(rule, managerDg), isTrue);
    });

    test('user with none of the roles returns false', () {
      final rule = Rule.fromJson(const {
        'role': <Object?>['MANAGER', 'DG'],
      });
      expect(evaluator.evaluate(rule, cashier), isFalse);
    });
  });

  group('Edge cases', () {
    test('empty roles set returns false for any role rule', () {
      final rule = Rule.fromJson(const {'role': 'MANAGER'});
      expect(evaluator.evaluate(rule, emptyRoles), isFalse);
    });

    test('unknown role in rule list returns false', () {
      final rule = Rule.fromJson(const {
        'role': <Object?>['UNKNOWN_ROLE_XYZ'],
      });
      expect(evaluator.evaluate(rule, manager), isFalse);
    });

    test('role rule with empty list returns false', () {
      // Empty list of roles — no role can match, always false.
      const rule = Rule(operator: 'role', value: <Object?>[]);
      expect(evaluator.evaluate(rule, manager), isFalse);
    });
  });

  group('retail_dashboard fixture — MANAGER vs CASHIER visibility', () {
    final kpiRule = Rule.fromJson(const {
      'role': <Object?>['MANAGER', 'DG'],
    });
    final cashierPosRule = Rule.fromJson(const {
      'OR': <Object?>[
        {'role': <Object?>['CASHIER']},
        {'role': <Object?>['MANAGER']},
      ],
    });
    final notGuestRule = Rule.fromJson(const {
      'NOT': {'role': <Object?>['GUEST']},
    });

    test('MANAGER sees kpi_revenue_panel', () {
      expect(evaluator.evaluate(kpiRule, manager), isTrue);
    });

    test('CASHIER does not see kpi_revenue_panel', () {
      expect(evaluator.evaluate(kpiRule, cashier), isFalse);
    });

    test('both MANAGER and CASHIER see cashier_pos_panel', () {
      expect(evaluator.evaluate(cashierPosRule, manager), isTrue);
      expect(evaluator.evaluate(cashierPosRule, cashier), isTrue);
    });

    test('MANAGER is not blocked by not-guest rule', () {
      expect(evaluator.evaluate(notGuestRule, manager), isTrue);
    });

    test('CASHIER is not blocked by not-guest rule', () {
      expect(evaluator.evaluate(notGuestRule, cashier), isTrue);
    });

    test('GUEST is blocked by not-guest rule', () {
      const guest = UserContext(
        userId: 'u5',
        tenantId: 't1',
        roles: {'GUEST'},
      );
      expect(evaluator.evaluate(notGuestRule, guest), isFalse);
    });
  });
}
