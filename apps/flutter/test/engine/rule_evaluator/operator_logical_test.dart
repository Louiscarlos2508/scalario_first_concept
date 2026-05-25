import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  const evaluator = ScalarioCanvasRule();

  const manager = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'MANAGER'},
  );

  const guest = UserContext(
    userId: 'u2',
    tenantId: 't1',
    roles: {'GUEST'},
  );

  const noRole = UserContext(
    userId: 'u3',
    tenantId: 't1',
    roles: {},
  );

  group('AC-05 — null rule', () {
    test('evaluate(null, ctx) returns true', () {
      expect(evaluator.evaluate(null, manager), isTrue);
      expect(evaluator.evaluate(null, guest), isTrue);
      expect(evaluator.evaluate(null, noRole), isTrue);
    });
  });

  group('AC-06 — AND operator', () {
    test('AND true+true = true', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
          {'field': 'record.x', 'operator': '==', 'value': 1},
        ],
      });
      expect(
        evaluator.evaluate(rule, manager, const {'x': 1}),
        isTrue,
      );
    });

    test('AND true+false = false', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
          {'field': 'record.x', 'operator': '==', 'value': 99},
        ],
      });
      expect(
        evaluator.evaluate(rule, manager, const {'x': 1}),
        isFalse,
      );
    });

    test('AND false+true = false (short-circuit)', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'GUEST'},
          {'field': 'record.x', 'operator': '==', 'value': 1},
        ],
      });
      expect(
        evaluator.evaluate(rule, manager, const {'x': 1}),
        isFalse,
      );
    });

    test('AND false+false = false', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'GUEST'},
          {'field': 'record.x', 'operator': '>', 'value': 100},
        ],
      });
      expect(
        evaluator.evaluate(rule, manager, const {'x': 0}),
        isFalse,
      );
    });
  });

  group('AC-07 — OR operator', () {
    test('OR true+false = true', () {
      final rule = Rule.fromJson(const {
        'OR': <Object?>[
          {'role': 'MANAGER'},
          {'role': 'DG'},
        ],
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
    });

    test('OR false+false = false', () {
      final rule = Rule.fromJson(const {
        'OR': <Object?>[
          {'role': 'DG'},
          {'role': 'OWNER'},
        ],
      });
      expect(evaluator.evaluate(rule, manager), isFalse);
    });

    test('OR false+true = true (second branch)', () {
      final rule = Rule.fromJson(const {
        'OR': <Object?>[
          {'role': 'DG'},
          {'role': 'MANAGER'},
        ],
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
    });
  });

  group('AC-08 — NOT operator', () {
    test('NOT GUEST = true for MANAGER', () {
      final rule = Rule.fromJson(const {
        'NOT': {'role': 'GUEST'},
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
    });

    test('NOT GUEST = false for GUEST user', () {
      final rule = Rule.fromJson(const {
        'NOT': {'role': 'GUEST'},
      });
      expect(evaluator.evaluate(rule, guest), isFalse);
    });

    test('NOT(NOT(role)) double negation', () {
      final rule = Rule.fromJson(const {
        'NOT': {
          'NOT': {'role': 'MANAGER'},
        },
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
      expect(evaluator.evaluate(rule, guest), isFalse);
    });
  });

  group('Deep nesting — AND(OR(NOT)) 4+ levels', () {
    test('AND(OR(MANAGER, DG), NOT(GUEST)) — MANAGER passes', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {
            'OR': <Object?>[
              {'role': 'MANAGER'},
              {'role': 'DG'},
            ],
          },
          {
            'NOT': {'role': 'GUEST'},
          },
        ],
      });
      expect(evaluator.evaluate(rule, manager), isTrue);
    });

    test('AND(OR(MANAGER, DG), NOT(GUEST)) — GUEST fails', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {
            'OR': <Object?>[
              {'role': 'MANAGER'},
              {'role': 'DG'},
            ],
          },
          {
            'NOT': {'role': 'GUEST'},
          },
        ],
      });
      expect(evaluator.evaluate(rule, guest), isFalse);
    });

    test('5-level nested rule evaluates correctly', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {
            'OR': <Object?>[
              {
                'NOT': {
                  'AND': <Object?>[
                    {'role': 'GUEST'},
                    {'role': 'DG'},
                  ],
                },
              },
              {'role': 'MANAGER'},
            ],
          },
          {'field': 'record.active', 'operator': '==', 'value': true},
        ],
      });
      expect(
        evaluator.evaluate(rule, manager, const {'active': true}),
        isTrue,
      );
      expect(
        evaluator.evaluate(rule, guest, const {'active': true}),
        isTrue, // guest is not (GUEST AND DG) simultaneously
      );
    });
  });
}
