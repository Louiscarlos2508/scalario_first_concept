import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

void main() {
  const base = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'MANAGER', 'CASHIER'},
    departmentId: 'dept-sales',
    attributes: {'plan': 'pro', 'flag': true},
  );

  group('UserContext.== (AC-04)', () {
    test('identical instance is equal to itself', () {
      // ignore: unrelated_type_equality_checks
      expect(base == base, isTrue);
    });

    test('two equal instances are equal', () {
      const other = UserContext(
        userId: 'u1',
        tenantId: 't1',
        roles: {'MANAGER', 'CASHIER'},
        departmentId: 'dept-sales',
        attributes: {'plan': 'pro', 'flag': true},
      );
      expect(base, equals(other));
    });

    test('different userId → not equal', () {
      const other = UserContext(
        userId: 'u2',
        tenantId: 't1',
        roles: {'MANAGER', 'CASHIER'},
        departmentId: 'dept-sales',
        attributes: {'plan': 'pro', 'flag': true},
      );
      expect(base, isNot(equals(other)));
    });

    test('different tenantId → not equal', () {
      const other = UserContext(
        userId: 'u1',
        tenantId: 't2',
        roles: {'MANAGER', 'CASHIER'},
        attributes: {'plan': 'pro', 'flag': true},
      );
      expect(base, isNot(equals(other)));
    });

    test('different roles → not equal', () {
      const other = UserContext(
        userId: 'u1',
        tenantId: 't1',
        roles: {'GUEST'},
        departmentId: 'dept-sales',
        attributes: {'plan': 'pro', 'flag': true},
      );
      expect(base, isNot(equals(other)));
    });

    test('different attributes → not equal', () {
      const other = UserContext(
        userId: 'u1',
        tenantId: 't1',
        roles: {'MANAGER', 'CASHIER'},
        departmentId: 'dept-sales',
        attributes: {'plan': 'free'},
      );
      expect(base, isNot(equals(other)));
    });

    test('different departmentId → not equal', () {
      const other = UserContext(
        userId: 'u1',
        tenantId: 't1',
        roles: {'MANAGER', 'CASHIER'},
        departmentId: 'dept-finance',
        attributes: {'plan': 'pro', 'flag': true},
      );
      expect(base, isNot(equals(other)));
    });

    test('compared to non-UserContext object → not equal', () {
      // ignore: unrelated_type_equality_checks
      expect(base == 'not a context', isFalse);
    });

    test('roles sets with same content in different order are equal', () {
      const a = UserContext(userId: 'u', tenantId: 't', roles: {'A', 'B'});
      const b = UserContext(userId: 'u', tenantId: 't', roles: {'B', 'A'});
      expect(a, equals(b));
    });

    test('roles set with extra element → not equal', () {
      const a = UserContext(userId: 'u', tenantId: 't', roles: {'A'});
      const b = UserContext(userId: 'u', tenantId: 't', roles: {'A', 'B'});
      expect(a, isNot(equals(b)));
    });
  });

  group('UserContext.hashCode', () {
    test('equal contexts have same hashCode', () {
      const a = UserContext(userId: 'u1', tenantId: 't1', roles: {'MANAGER'});
      const b = UserContext(userId: 'u1', tenantId: 't1', roles: {'MANAGER'});
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('UserContext.toString()', () {
    test('toString contains userId and tenantId', () {
      final str = base.toString();
      expect(str, contains('u1'));
      expect(str, contains('t1'));
    });
  });
}
