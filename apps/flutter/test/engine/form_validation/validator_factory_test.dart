import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/form_validation/form_validation.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  final factory = ValidatorFactory();
  const ctx = FieldContext(
    userCtx: UserContext(userId: 'u1', tenantId: 't1', roles: {'CASHIER'}),
    formData: {},
    evaluator: ScalarioCanvasRule(),
  );

  FormFieldValidator<dynamic> build(Map<String, dynamic> ruleJson) =>
      factory.fromRules<dynamic>(
        [ValidationRule.fromJson(ruleJson)],
        ctx,
      );

  // ---------------------------------------------------------------------------
  // required (AC-04)
  // ---------------------------------------------------------------------------

  group('required (AC-04)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {'type': 'required'}));

    test('null → error', () => expect(v(null), isNotNull));
    test('empty string → error', () => expect(v(''), isNotNull));
    test('empty list → error', () => expect(v(<dynamic>[]), isNotNull));

    test('false (Toggle) → valid', () => expect(v(false), isNull));
    test('0 (NumberInput) → valid', () => expect(v(0), isNull));
    test('non-empty string → valid', () => expect(v('x'), isNull));
    test('non-empty list → valid', () => expect(v([1]), isNull));
    test('zero double → valid', () => expect(v(0.0), isNull));
  });

  // ---------------------------------------------------------------------------
  // type (AC-05)
  // ---------------------------------------------------------------------------

  group('type (AC-05)', () {
    test('string: String → valid', () {
      final v = build(const {'type': 'type', 'value': 'string'});
      expect(v('hello'), isNull);
    });
    test('string: num → error', () {
      final v = build(const {'type': 'type', 'value': 'string'});
      expect(v(42), isNotNull);
    });

    test('number: num → valid', () {
      final v = build(const {'type': 'type', 'value': 'number'});
      expect(v(3.14), isNull);
    });
    test('number: parseable string → valid', () {
      final v = build(const {'type': 'type', 'value': 'number'});
      expect(v('3.14'), isNull);
    });
    test('number: non-numeric string → error', () {
      final v = build(const {'type': 'type', 'value': 'number'});
      expect(v('abc'), isNotNull);
    });

    test('integer: int → valid', () {
      final v = build(const {'type': 'type', 'value': 'integer'});
      expect(v(5), isNull);
    });
    test('integer: double with fractional → error', () {
      final v = build(const {'type': 'type', 'value': 'integer'});
      expect(v(5.5), isNotNull);
    });
    test('integer: double without fractional → valid', () {
      final v = build(const {'type': 'type', 'value': 'integer'});
      expect(v(5.0), isNull);
    });

    test('date: DateTime → valid', () {
      final v = build(const {'type': 'type', 'value': 'date'});
      expect(v(DateTime(2026, 5, 12)), isNull);
    });
    test('date: ISO string → valid', () {
      final v = build(const {'type': 'type', 'value': 'date'});
      expect(v('2026-05-12'), isNull);
    });
    test('date: invalid string → error', () {
      final v = build(const {'type': 'type', 'value': 'date'});
      expect(v('not-a-date'), isNotNull);
    });

    test('boolean: bool → valid', () {
      final v = build(const {'type': 'type', 'value': 'boolean'});
      expect(v(true), isNull);
      expect(v(false), isNull);
    });
    test('boolean: String → error', () {
      final v = build(const {'type': 'type', 'value': 'boolean'});
      expect(v('true'), isNotNull);
    });

    test('null value skips type check', () {
      final v = build(const {'type': 'type', 'value': 'string'});
      expect(v(null), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // min / max (AC-06) — inclusive boundaries
  // ---------------------------------------------------------------------------

  group('min (AC-06)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {'type': 'min', 'value': 100}));

    test('value == min → valid (inclusive)', () => expect(v(100), isNull));
    test('value > min → valid', () => expect(v(101), isNull));
    test('value < min → error', () => expect(v(99), isNotNull));
    test('null → skip', () => expect(v(null), isNull));
    test('parseable string num → valid', () => expect(v('200'), isNull));
  });

  group('max (AC-06)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {'type': 'max', 'value': 10000000}));

    test('value == max → valid (inclusive)', () => expect(v(10000000), isNull));
    test('value < max → valid', () => expect(v(9999999), isNull));
    test('value > max → error', () => expect(v(10000001), isNotNull));
    test('null → skip', () => expect(v(null), isNull));
  });

  // ---------------------------------------------------------------------------
  // minLength / maxLength (AC-07) — rune counting
  // ---------------------------------------------------------------------------

  group('minLength (AC-07)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {'type': 'minLength', 'value': 8}));

    test('length == min → valid', () => expect(v('abcdefgh'), isNull));
    test('length > min → valid', () => expect(v('abcdefghi'), isNull));
    test('length < min → error', () => expect(v('abc'), isNotNull));
    test('null → skip', () => expect(v(null), isNull));

    test('UTF-8 emoji 🇧🇫 counts as 2 runes', () {
      // '🇧🇫' = regional indicator B + regional indicator F = 2 code points.
      // minLength: 8 → "abcdef🇧🇫" = 6 chars + 2 runes = 8 runes total → valid.
      final v8 = build(const {'type': 'minLength', 'value': 8});
      expect(v8('abcdef🇧🇫'), isNull);
      // 7 runes → still one short.
      expect(v8('abcde🇧🇫'), isNotNull);
    });
  });

  group('maxLength (AC-07)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {'type': 'maxLength', 'value': 5}));

    test('length == max → valid', () => expect(v('abcde'), isNull));
    test('length < max → valid', () => expect(v('abc'), isNull));
    test('length > max → error', () => expect(v('abcdef'), isNotNull));
    test('null → skip', () => expect(v(null), isNull));

    test('multi-byte: "Bénin" = 5 runes → valid at max 5', () {
      // 'é' is a single code point U+00E9 → 1 rune, not 2 bytes.
      // "Bénin".runes.length == 5.
      expect(v('Bénin'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // regex (AC-08)
  // ---------------------------------------------------------------------------

  group('regex (AC-08)', () {
    test('matching string → valid', () {
      final v = build(const {'type': 'regex', 'value': r'^[0-9]{8}$'});
      expect(v('12345678'), isNull);
    });

    test('non-matching string → error', () {
      final v = build(const {'type': 'regex', 'value': r'^[0-9]{8}$'});
      expect(v('12345'), isNotNull);
    });

    test('null → skip (optional field)', () {
      final v = build(const {'type': 'regex', 'value': r'^[0-9]{8}$'});
      expect(v(null), isNull);
    });

    test('empty string → skip', () {
      final v = build(const {'type': 'regex', 'value': r'^[0-9]{8}$'});
      expect(v(''), isNull);
    });

    test('non-string value → skip', () {
      final v = build(const {'type': 'regex', 'value': r'^[0-9]{8}$'});
      expect(v(42), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // enum (AC-09)
  // ---------------------------------------------------------------------------

  group('enum (AC-09)', () {
    late FormFieldValidator<dynamic> v;
    setUp(() => v = build(const {
          'type': 'enum',
          'value': <dynamic>['draft', 'pending', 'paid'],
        }));

    test('allowed value → valid', () => expect(v('paid'), isNull));
    test('disallowed value → error', () => expect(v('unknown'), isNotNull));
    test('null → skip', () => expect(v(null), isNull));
    test('case-sensitive: DRAFT != draft', () => expect(v('DRAFT'), isNotNull));
  });

  // ---------------------------------------------------------------------------
  // Early return — first rule fails, others skipped (AC-26)
  // ---------------------------------------------------------------------------

  group('early return on first error (AC-26)', () {
    test('required fails before minLength fires', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'required'}),
        ValidationRule.fromJson(const {'type': 'minLength', 'value': 8}),
        ValidationRule.fromJson(const {
          'type': 'regex',
          'value': r'^[0-9]{8}$',
        }),
      ];
      final v = factory.fromRules<dynamic>(rules, ctx);
      // Empty string → 'required' fires first
      final error = v('');
      expect(error, isNotNull);
      expect(error, equals(const ValidationMessages().defaultFor('required')));
    });

    test('required passes, minLength fires next', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'required'}),
        ValidationRule.fromJson(const {'type': 'minLength', 'value': 8}),
        ValidationRule.fromJson(const {
          'type': 'regex',
          'value': r'^[0-9]{8}$',
        }),
      ];
      final v = factory.fromRules<dynamic>(rules, ctx);
      // 'abc' → required passes, minLength fails
      final error = v('abc');
      expect(error, isNotNull);
      expect(error, contains('8'));
    });

    test('all rules pass → null', () {
      final rules = [
        ValidationRule.fromJson(const {'type': 'required'}),
        ValidationRule.fromJson(const {'type': 'minLength', 'value': 8}),
        ValidationRule.fromJson(const {
          'type': 'regex',
          'value': r'^[0-9]{8}$',
        }),
      ];
      final v = factory.fromRules<dynamic>(rules, ctx);
      expect(v('12345678'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ReDoS protection (AC-23)
  // ---------------------------------------------------------------------------

  group('ReDoS protection (AC-23)', () {
    test('input over 10000 chars is capped and evaluated', () {
      // A pathological pattern on a long input — validator must not hang.
      // The stopwatch guard caps evaluation at 50ms; result must come back quickly.
      final v = build(const {'type': 'regex', 'value': r'^a*$'});
      final longInput = 'a' * 50000;
      final sw = Stopwatch()..start();
      v(longInput);
      sw.stop();
      // Should complete well within 5 seconds even on slow CI.
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });
  });
}
