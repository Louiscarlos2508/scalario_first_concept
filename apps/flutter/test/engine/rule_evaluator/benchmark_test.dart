/// AC-20 & AC-21 — Performance benchmark for RuleEvaluator.
///
/// Ensures that evaluating a 5-level nested Rule against a UserContext
/// with 10 attributes completes in < 1ms per evaluation on any CI runner.
///
/// The test runs 1000 iterations and fails if the *average* exceeds 1ms,
/// which is far more lenient than the Snapdragon 680 target (Dart VM on
/// CI x86 is 10-20x faster). The real device check is handled by the
/// CI matrix in `benchmark_device.yml` (outside this story scope).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

void main() {
  const evaluator = RuleEvaluator();

  // 5-level deeply nested rule: AND(OR(NOT(AND), role), comparison)
  final deepRule = Rule.fromJson(const {
    'AND': <Object?>[
      {
        'OR': <Object?>[
          {
            'NOT': {
              'AND': <Object?>[
                {'role': <Object?>['GUEST']},
                {
                  'field': 'record.blocked',
                  'operator': '==',
                  'value': true,
                },
              ],
            },
          },
          {'role': <Object?>['MANAGER', 'DG']},
        ],
      },
      {
        'AND': <Object?>[
          {
            'field': 'record.montant',
            'operator': '>',
            'value': 0,
          },
          {
            'field': 'record.status',
            'operator': 'in',
            'value': <Object?>['active', 'pending', 'draft'],
          },
        ],
      },
    ],
  });

  // UserContext with 10 attributes (AC-20 spec)
  const richCtx = UserContext(
    userId: 'bench-user',
    tenantId: 'bench-tenant',
    roles: {'MANAGER'},
    departmentId: 'dept-finance',
    attributes: {
      'attr_1': 'value_1',
      'attr_2': 42,
      'attr_3': true,
      'attr_4': 'value_4',
      'attr_5': 100.5,
      'attr_6': false,
      'attr_7': 'value_7',
      'attr_8': 0,
      'attr_9': 'value_9',
      'attr_10': 'value_10',
    },
  );

  const record = <String, Object?>{
    'montant': 750000,
    'status': 'active',
    'blocked': false,
    'lines': <Object?>[
      <String, Object?>{'qty': 5, 'sku': 'SKU-001'},
    ],
  };

  test('AC-20 — 5-level rule evaluates in < 1ms average over 1000 iterations',
      () {
    const iterations = 1000;

    // Warm-up (JIT / tree-shaking)
    for (var i = 0; i < 50; i++) {
      evaluator.evaluate(deepRule, richCtx, record);
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      evaluator.evaluate(deepRule, richCtx, record);
    }
    sw.stop();

    final avgMicros = sw.elapsedMicroseconds / iterations;
    final avgMs = avgMicros / 1000;

    // ignore: avoid_print
    print(
      'RuleEvaluator benchmark: avg ${avgMicros.toStringAsFixed(2)}µs '
      '(${avgMs.toStringAsFixed(3)}ms) over $iterations iterations',
    );

    expect(
      avgMs,
      lessThan(1.0),
      reason:
          'evaluate() must complete in < 1ms on average. '
          'Got ${avgMs.toStringAsFixed(3)}ms. '
          'Check for unexpected allocations in the hot path.',
    );
  });

  test('AC-21 — result is correct (sanity check for benchmark rule)', () {
    // MANAGER with high montant and active status → true
    expect(evaluator.evaluate(deepRule, richCtx, record), isTrue);

    // GUEST with blocked=true → false (blocked by NOT(AND(GUEST, blocked==true)))
    const guestCtx = UserContext(
      userId: 'guest-user',
      tenantId: 'bench-tenant',
      roles: {'GUEST'},
    );
    const blockedRecord = <String, Object?>{
      'montant': 750000,
      'status': 'active',
      'blocked': true,
    };
    expect(evaluator.evaluate(deepRule, guestCtx, blockedRecord), isFalse);
  });
}
