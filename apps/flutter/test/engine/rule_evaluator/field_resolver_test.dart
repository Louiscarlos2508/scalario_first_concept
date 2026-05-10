import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

void main() {
  const resolver = FieldResolver();

  const ctx = UserContext(
    userId: 'user-42',
    tenantId: 'tenant-abc',
    roles: {'MANAGER', 'CASHIER'},
    departmentId: 'dept-sales',
    attributes: {
      'is_admin': true,
      'plan': 'pro',
      'nested': {'level': 2},
      'feature_flag_xyz': true,
    },
  );

  group('AC-15 — user.role', () {
    test('user.role returns first role when set is non-empty', () {
      final value = resolver.resolve('user.role', ctx);
      // Set iteration order in Dart is insertion order; first = 'MANAGER'.
      expect(value, isNotNull);
      expect(ctx.roles, contains(value));
    });

    test('user.role returns null when roles set is empty', () {
      const emptyCtx = UserContext(
        userId: 'u',
        tenantId: 't',
        roles: {},
      );
      expect(resolver.resolve('user.role', emptyCtx), isNull);
    });
  });

  group('user.* standard fields', () {
    test('user.userId', () {
      expect(resolver.resolve('user.userId', ctx), 'user-42');
    });

    test('user.tenantId', () {
      expect(resolver.resolve('user.tenantId', ctx), 'tenant-abc');
    });

    test('user.departmentId', () {
      expect(resolver.resolve('user.departmentId', ctx), 'dept-sales');
    });

    test('user.departmentId is null when not set', () {
      const noDepCtx = UserContext(
        userId: 'u',
        tenantId: 't',
        roles: {},
      );
      expect(resolver.resolve('user.departmentId', noDepCtx), isNull);
    });

    test('unknown user.* subfield returns null', () {
      expect(resolver.resolve('user.unknownField', ctx), isNull);
    });
  });

  group('AC-16 — user.attributes.* arbitrary depth', () {
    test('user.attributes.is_admin', () {
      expect(resolver.resolve('user.attributes.is_admin', ctx), isTrue);
    });

    test('user.attributes.plan', () {
      expect(resolver.resolve('user.attributes.plan', ctx), 'pro');
    });

    test('user.attributes.feature_flag_xyz', () {
      expect(
        resolver.resolve('user.attributes.feature_flag_xyz', ctx),
        isTrue,
      );
    });

    test('absent attribute key returns null (AC-19)', () {
      expect(resolver.resolve('user.attributes.nonexistent', ctx), isNull);
    });
  });

  group('AC-17 — record.* fields', () {
    const record = <String, Object?>{
      'montant': 750000,
      'status': 'pending',
      'client_name': 'Blandine',
    };

    test('record.montant', () {
      expect(resolver.resolve('record.montant', ctx, record), 750000);
    });

    test('record.status', () {
      expect(resolver.resolve('record.status', ctx, record), 'pending');
    });

    test('record.* without recordData returns null + no throw', () {
      expect(resolver.resolve('record.montant', ctx), isNull);
    });

    test('absent record field returns null (AC-19)', () {
      expect(resolver.resolve('record.missing', ctx, record), isNull);
    });
  });

  group('AC-18 — array-index notation', () {
    const recordWithList = <String, Object?>{
      'lines': <Object?>[
        <String, Object?>{'qty': 3, 'sku': 'A1'},
        <String, Object?>{'qty': 7, 'sku': 'B2'},
      ],
    };

    test('record.lines[0].qty', () {
      expect(
        resolver.resolve('record.lines[0].qty', ctx, recordWithList),
        3,
      );
    });

    test('record.lines[1].sku', () {
      expect(
        resolver.resolve('record.lines[1].sku', ctx, recordWithList),
        'B2',
      );
    });

    test('out-of-bounds index returns null — no exception (AC-18)', () {
      expect(
        resolver.resolve('record.lines[99].qty', ctx, recordWithList),
        isNull,
      );
    });

    test('negative index returns null — no exception', () {
      expect(
        resolver.resolve('record.lines[-1].qty', ctx, recordWithList),
        isNull,
      );
    });
  });

  group('AC-19 — null safety and absent fields', () {
    test('empty path returns null', () {
      expect(resolver.resolve('', ctx), isNull);
    });

    test('deeply nested absent key returns null', () {
      expect(
        resolver.resolve('record.a.b.c.d', ctx, const {'a': <String, Object?>{}}),
        isNull,
      );
    });

    test('null == null comparison via evaluator (AC-19)', () {
      const evaluator = RuleEvaluator();
      final rule = Rule.fromJson(const {
        'field': 'record.optional',
        'operator': '==',
        'value': null,
      });
      // absent field resolves to null; null == null → true
      expect(evaluator.evaluate(rule, ctx, const {}), isTrue);
    });

    test('null > 0 returns false (AC-19)', () {
      const evaluator = RuleEvaluator();
      final rule = Rule.fromJson(const {
        'field': 'record.optional',
        'operator': '>',
        'value': 0,
      });
      expect(evaluator.evaluate(rule, ctx, const {}), isFalse);
    });
  });
}
