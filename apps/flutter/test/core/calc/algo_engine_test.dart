import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/calc/algo_engine.dart';

void main() {
  late AlgoEngine engine;

  setUp(() {
    engine = AlgoEngine();
  });

  group('Math primitives', () {
    test('add', () => expect(engine.eval({'fn': 'add', 'args': [2, 3]}, {}).value, 5));
    test('sub', () => expect(engine.eval({'fn': 'sub', 'args': [10, 3]}, {}).value, 7));
    test('mul', () => expect(engine.eval({'fn': 'mul', 'args': [4, 5]}, {}).value, 20));
    test('div', () => expect(engine.eval({'fn': 'div', 'args': [10, 2]}, {}).value, 5));
    test('div/0 throws', () {
      expect(() => engine.eval({'fn': 'div', 'args': [5, 0]}, {}), throwsException);
    });
    test('round', () => expect(engine.eval({'fn': 'round', 'args': [3.14159, 2]}, {}).value, 3.14));
    test('floor', () => expect(engine.eval({'fn': 'floor', 'args': [3.9]}, {}).value, 3));
    test('ceil', () => expect(engine.eval({'fn': 'ceil', 'args': [3.1]}, {}).value, 4));
    test('abs', () => expect(engine.eval({'fn': 'abs', 'args': [-5]}, {}).value, 5));
    test('min', () => expect(engine.eval({'fn': 'min', 'args': [2, 5]}, {}).value, 2));
    test('max', () => expect(engine.eval({'fn': 'max', 'args': [2, 5]}, {}).value, 5));
  });

  group('Logic primitives', () {
    test('if true', () => expect(engine.eval({'fn': 'if', 'args': [true, 'yes', 'no']}, {}).value, 'yes'));
    test('gt', () => expect(engine.eval({'fn': 'gt', 'args': [5, 3]}, {}).value, true));
    test('lt', () => expect(engine.eval({'fn': 'lt', 'args': [3, 5]}, {}).value, true));
    test('eq', () => expect(engine.eval({'fn': 'eq', 'args': [42, 42]}, {}).value, true));
    test('and', () => expect(engine.eval({'fn': 'and', 'args': [true, false]}, {}).value, false));
    test('not', () => expect(engine.eval({'fn': 'not', 'args': [false]}, {}).value, true));
  });

  group('List primitives', () {
    test('sum', () => expect(engine.eval({'fn': 'sum', 'args': [
      [1, 2, 3, 4]
    ]}, {}).value, 10));
    test('avg', () => expect(engine.eval({'fn': 'avg', 'args': [
      [2, 4, 6]
    ]}, {}).value, 4));
    test('count', () => expect(engine.eval({'fn': 'count', 'args': [
      ['a', 'b', 'c']
    ]}, {}).value, 3));
    test('unique', () => expect(engine.eval({'fn': 'unique', 'args': [
      [1, 2, 2, 3]
    ]}, {}).value, [1, 2, 3]));
  });

  group('Text primitives', () {
    test('concat', () => expect(engine.eval({'fn': 'concat', 'args': ['Hello ', 'World']}, {}).value, 'Hello World'));
    test('upper', () => expect(engine.eval({'fn': 'upper', 'args': ['hello']}, {}).value, 'HELLO'));
    test('format_currency XOF', () {
      final r = engine.eval({'fn': 'format_currency', 'args': [125000, 'XOF']}, {});
      expect((r.value as String).contains('FCFA'), true);
    });
    test('slugify', () => expect(engine.eval({'fn': 'slugify', 'args': ['Pharmacie Kossyam']}, {}).value, 'pharmacie-kossyam'));
  });

  group('Variable resolution', () {
    test('resolves \$variable from inputs', () {
      expect(engine.eval('\$quantite', {'quantite': 10}).value, 10);
    });
    test('throws on missing variable', () {
      expect(() => engine.eval('\$missing', {}), throwsException);
    });
  });

  group('Nested formulas', () {
    test('(10 * 1000 - (10*1000*5/100)) * 1.18 = 11210', () {
      final formula = {
        'fn': 'mul',
        'args': [
          {
            'fn': 'sub',
            'args': [
              {'fn': 'mul', 'args': ['\$quantite', '\$prix_unitaire']},
              {
                'fn': 'mul',
                'args': [
                  {'fn': 'mul', 'args': ['\$quantite', '\$prix_unitaire']},
                  {'fn': 'div', 'args': ['\$remise', 100]},
                ],
              },
            ],
          },
          1.18,
        ],
      };
      final r = engine.eval(formula, {'quantite': 10, 'prix_unitaire': 1000, 'remise': 5});
      expect(r.value, 11210);
    });
  });

  group('Debug mode', () {
    test('returns steps when debug: true', () {
      final r = engine.eval({'fn': 'add', 'args': [2, 3]}, {}, debug: true);
      expect(r.steps, isNotNull);
      expect(r.steps!.length, greaterThan(0));
      expect(r.steps![0].fn, 'add');
      expect(r.steps![0].result, 5);
    });
  });

  group('Edge cases', () {
    test('throws on unknown function', () {
      expect(() => engine.eval({'fn': 'unknown_fn', 'args': []}, {}), throwsException);
    });
  });
}
