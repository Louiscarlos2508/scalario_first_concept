import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/form_validation/form_validation.dart';
import 'package:scalario/engine/canvas_rule/scalario_canvas_rule.dart';

void main() {
  const evaluator = ScalarioCanvasRule();
  const userCtx = UserContext(
    userId: 'u1',
    tenantId: 't1',
    roles: {'CASHIER'},
  );
  final factory = ValidatorFactory();

  // Build a validator for the 'notes' field with a required_if rule:
  // "required if amount > 500000"
  final requiredIfRule = ValidationRule.fromJson(const {
    'type': 'required_if',
    'requiredIf': {'field': 'amount', 'operator': '>', 'value': 500000},
  });

  // ---------------------------------------------------------------------------
  // AC-10 / AC-11: required_if conditional behaviour
  // ---------------------------------------------------------------------------

  group('required_if — condition false (AC-11)', () {
    // amount = 100 000 → condition false → field is optional
    const ctx = FieldContext(
      userCtx: userCtx,
      formData: {'amount': 100000},
      evaluator: evaluator,
    );
    late FormFieldValidator<dynamic> v;
    setUpAll(() => v = factory.fromRules<dynamic>([requiredIfRule], ctx));

    test('null value → valid (field is optional)', () {
      expect(v(null), isNull);
    });

    test('empty string → valid (field is optional)', () {
      expect(v(''), isNull);
    });

    test('non-empty value → valid', () {
      expect(v('some notes'), isNull);
    });
  });

  group('required_if — condition true (AC-10)', () {
    // amount = 800 000 → condition true → field behaves like required
    const ctx = FieldContext(
      userCtx: userCtx,
      formData: {'amount': 800000},
      evaluator: evaluator,
    );
    late FormFieldValidator<dynamic> v;
    setUpAll(() => v = factory.fromRules<dynamic>([requiredIfRule], ctx));

    test('null → error (required)', () {
      expect(v(null), isNotNull);
    });

    test('empty string → error', () {
      expect(v(''), isNotNull);
    });

    test('non-empty value → valid', () {
      expect(v('important notes here'), isNull);
    });
  });

  group('required_if — boundary: amount exactly 500 000', () {
    // 500 000 is NOT > 500 000 → condition false
    const ctx = FieldContext(
      userCtx: userCtx,
      formData: {'amount': 500000},
      evaluator: evaluator,
    );
    test('at boundary → optional', () {
      final v = factory.fromRules<dynamic>([requiredIfRule], ctx);
      expect(v(null), isNull);
    });
  });

  group('required_if — missing sibling field', () {
    // amount not in formData → FieldResolver returns null → 'null > 500000' = false
    const ctx = FieldContext(
      userCtx: userCtx,
      formData: {},
      evaluator: evaluator,
    );
    test('absent sibling → condition false → optional', () {
      final v = factory.fromRules<dynamic>([requiredIfRule], ctx);
      expect(v(null), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // required_if with AND condition
  // ---------------------------------------------------------------------------

  group('required_if — AND condition', () {
    final andRule = ValidationRule.fromJson(const {
      'type': 'required_if',
      'requiredIf': {
        'AND': <dynamic>[
          {'field': 'amount', 'operator': '>', 'value': 500000},
          {'field': 'client_type', 'operator': '==', 'value': 'business'},
        ],
      },
    });

    test('both conditions true → required', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 600000, 'client_type': 'business'},
        evaluator: evaluator,
      );
      final v = factory.fromRules<dynamic>([andRule], ctx);
      expect(v(null), isNotNull);
    });

    test('one condition false → optional', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 600000, 'client_type': 'individual'},
        evaluator: evaluator,
      );
      final v = factory.fromRules<dynamic>([andRule], ctx);
      expect(v(null), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // required_if error message uses required fallback (AC-17)
  // ---------------------------------------------------------------------------

  group('required_if — error message', () {
    test('default message equals required message', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 800000},
        evaluator: evaluator,
      );
      final v = factory.fromRules<dynamic>([requiredIfRule], ctx);
      const messages = ValidationMessages();
      expect(v(null), equals(messages.defaultFor('required')));
    });

    test('custom errorMessage is used when condition is true', () {
      final customRule = ValidationRule.fromJson(const {
        'type': 'required_if',
        'requiredIf': {'field': 'amount', 'operator': '>', 'value': 500000},
        'errorMessage': 'Notes obligatoires pour montants élevés',
      });
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 900000},
        evaluator: evaluator,
      );
      final v = factory.fromRules<dynamic>([customRule], ctx);
      expect(v(null), 'Notes obligatoires pour montants élevés');
    });
  });

  // ---------------------------------------------------------------------------
  // AC-12: isRequiredIf on ValidatedFormController
  // ---------------------------------------------------------------------------

  group('ValidatedFormController.isRequiredIf (AC-12)', () {
    test('returns true when condition is met', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 800000},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController(
        validators: {
          'notes': factory.fromRules<dynamic>([requiredIfRule], ctx),
        },
      );
      expect(controller.isRequiredIf('notes', ctx), isTrue);
      controller.dispose();
    });

    test('returns false when condition is not met', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {'amount': 100000},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController(
        validators: {
          'notes': factory.fromRules<dynamic>([requiredIfRule], ctx),
        },
      );
      expect(controller.isRequiredIf('notes', ctx), isFalse);
      controller.dispose();
    });

    test('returns false for unknown field', () {
      const ctx = FieldContext(
        userCtx: userCtx,
        formData: {},
        evaluator: evaluator,
      );
      final controller = ValidatedFormController(validators: {});
      expect(controller.isRequiredIf('unknown', ctx), isFalse);
      controller.dispose();
    });
  });
}

// Flutter's FormFieldValidator typedef is from widgets.dart — keep it visible.
typedef FormFieldValidator<T> = String? Function(T?);
