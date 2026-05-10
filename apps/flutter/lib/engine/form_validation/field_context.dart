library;

import 'package:meta/meta.dart';

import '../rule_evaluator/rule_evaluator.dart';

/// Runtime context passed to [ValidatorFactory.fromRules] for each form field.
///
/// Carries the three pieces of state a validator may need:
///   - [userCtx]  — identity and roles for role-based rules.
///   - [formData] — sibling field values, so `required_if` can inspect them.
///   - [evaluator] — the shared [RuleEvaluator] from STORY-006.
///
/// [formData] must be kept up-to-date by the owning form widget as the user
/// fills in fields — each entry key is the field `id` from the JSON config.
@immutable
final class FieldContext {
  const FieldContext({
    required this.userCtx,
    required this.formData,
    required this.evaluator,
  });

  /// Authenticated user snapshot — consumed by [RuleEvaluator] for role/attribute rules.
  final UserContext userCtx;

  /// Current values of all form fields keyed by their `id`.
  /// Used by `required_if` to evaluate cross-field conditions.
  final Map<String, Object?> formData;

  /// Shared rule evaluator — must be the same instance used by the rest of the
  /// BDUI engine so that `visible_if` and `required_if` share evaluation logic.
  final RuleEvaluator evaluator;

  FieldContext copyWith({
    UserContext? userCtx,
    Map<String, Object?>? formData,
    RuleEvaluator? evaluator,
  }) {
    return FieldContext(
      userCtx: userCtx ?? this.userCtx,
      formData: formData ?? this.formData,
      evaluator: evaluator ?? this.evaluator,
    );
  }
}
