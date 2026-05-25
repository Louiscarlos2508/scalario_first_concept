import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  group('Rule.fromJson — logical forms', () {
    test('AND form parses list of children', () {
      final rule = Rule.fromJson(const {
        'AND': <Object?>[
          {'role': 'MANAGER'},
          {'field': 'record.montant', 'operator': '>', 'value': 0},
        ],
      });
      expect(rule.operator, 'AND');
      expect(rule.children, hasLength(2));
      expect(rule.children![0].operator, 'role');
      expect(rule.children![1].operator, '>');
    });

    test('OR form parses list of children', () {
      final rule = Rule.fromJson(const {
        'OR': <Object?>[
          {'role': 'CASHIER'},
          {'role': 'MANAGER'},
        ],
      });
      expect(rule.operator, 'OR');
      expect(rule.children, hasLength(2));
    });

    test('NOT form parses single child object', () {
      final rule = Rule.fromJson(const {
        'NOT': {'role': 'GUEST'},
      });
      expect(rule.operator, 'NOT');
      expect(rule.children, hasLength(1));
      expect(rule.children![0].operator, 'role');
    });

    test('nested AND(OR(NOT)) at 4 levels parses correctly', () {
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
      expect(rule.operator, 'AND');
      expect(rule.children![0].operator, 'OR');
      expect(rule.children![1].operator, 'NOT');
    });
  });

  group('Rule.fromJson — role shortcut', () {
    test('role with string value normalises to list', () {
      final rule = Rule.fromJson(const {'role': 'MANAGER'});
      expect(rule.operator, 'role');
      expect(rule.value, ['MANAGER']);
    });

    test('role with list value', () {
      final rule = Rule.fromJson(const {
        'role': <Object?>['MANAGER', 'DG'],
      });
      expect(rule.operator, 'role');
      expect(rule.value, ['MANAGER', 'DG']);
    });
  });

  group('Rule.fromJson — comparison form', () {
    test('== operator', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': '==',
        'value': 'active',
      });
      expect(rule.operator, '==');
      expect(rule.field, 'record.status');
      expect(rule.value, 'active');
    });

    test('> operator with numeric value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.montant',
        'operator': '>',
        'value': 500000,
      });
      expect(rule.operator, '>');
      expect(rule.value, 500000);
    });

    test('in operator with list value', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'in',
        'value': <Object?>['draft', 'pending'],
      });
      expect(rule.operator, 'in');
      expect(rule.value, ['draft', 'pending']);
    });

    test('not_in operator', () {
      final rule = Rule.fromJson(const {
        'field': 'record.status',
        'operator': 'not_in',
        'value': <Object?>['closed', 'cancelled'],
      });
      expect(rule.operator, 'not_in');
    });

    test('all comparison operators are accepted', () {
      const ops = <String>[
        '==', '!=', '>', '<', '>=', '<=', 'in', 'not_in',
      ];
      for (final op in ops) {
        final isListOp = op == 'in' || op == 'not_in';
        final rule = Rule.fromJson({
          'field': 'record.val',
          'operator': op,
          'value': isListOp ? <Object?>[] : 0,
        });
        expect(rule.operator, op, reason: 'operator $op should parse');
      }
    });
  });

  group('Rule.fromJson — AC-03 exceptions', () {
    test('AND with empty list throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {'AND': <Object?>[]}),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('OR with empty list throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {'OR': <Object?>[]}),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('NOT with a list instead of object throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'NOT': <Object?>[
            {'role': 'GUEST'},
          ],
        }),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('comparison with unknown operator throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {
          'field': 'record.x',
          'operator': 'BETWEEN',
          'value': 0,
        }),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('comparison with missing field throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {'operator': '==', 'value': 1}),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('completely unrecognized structure throws RuleParseException', () {
      expect(
        () => Rule.fromJson(const {'unknown_key': 'foo'}),
        throwsA(isA<RuleParseException>()),
      );
    });

    test('exception message contains node path', () {
      try {
        Rule.fromJson(const {
          'AND': <Object?>[
            {'BETWEEN': <Object?>[]},
          ],
        });
        fail('should have thrown');
      } on RuleParseException catch (e) {
        expect(e.message, contains('root.AND[0]'));
      }
    });
  });

  group('Rule — equality and hashCode (AC-01)', () {
    test('identical rules are equal', () {
      final a = Rule.fromJson(const {'role': 'MANAGER'});
      final b = Rule.fromJson(const {'role': 'MANAGER'});
      expect(a, equals(b));
    });

    test('different operators are not equal', () {
      final a = Rule.fromJson(const {
        'field': 'record.x',
        'operator': '==',
        'value': 1,
      });
      final b = Rule.fromJson(const {
        'field': 'record.x',
        'operator': '!=',
        'value': 1,
      });
      expect(a, isNot(equals(b)));
    });

    test('equal rules have same hashCode', () {
      final a = Rule.fromJson(const {'role': 'MANAGER'});
      final b = Rule.fromJson(const {'role': 'MANAGER'});
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
