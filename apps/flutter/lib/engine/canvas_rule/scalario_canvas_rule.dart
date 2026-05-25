// SECURITY: Le ScalarioCanvasRule filtre l'UI côté client. Il N'EST PAS une
// garantie de sécurité. Toute action protégée par visible_if doit AUSSI
// être protégée côté backend (FR-010, FR-011, FR-012). Voir architecture
// ligne 858 (NFR-003 Isolation Multi-tenant).
//
// Pas de `eval`, pas de `dart:mirrors` — les expressions sont des données.

library;

import 'dart:developer' as developer;

import 'package:meta/meta.dart';

import 'field_resolver.dart';
import 'rule.dart';
import 'user_context.dart';

export 'field_resolver.dart';
export 'rule.dart';
export 'user_context.dart';

/// Pure, stateless BDUI rule evaluator.
///
/// A single `const ScalarioCanvasRule()` instance is safe to share across the
/// entire widget tree — it holds no mutable state (AC-22).
///
/// Usage:
/// ```dart
/// const evaluator = ScalarioCanvasRule();
///
/// // visible_if / enabled_if
/// final visible = evaluator.evaluate(config.visibleIfRule, userCtx);
///
/// // required_if with form record data
/// final required = evaluator.evaluate(field.requiredIfRule, userCtx, record);
/// ```
///
/// Supported operators:
///   AND  OR  NOT         — logical combinators
///   role                 — shortcut for `user.roles contains value`
///   ==  !=               — equality (String, num, bool, null)
///   >  <  >=  <=         — numeric comparison (non-numeric → false + warning)
///   in  not_in           — membership in a List
@immutable
final class ScalarioCanvasRule {
  const ScalarioCanvasRule();

  static const _resolver = FieldResolver();

  /// Evaluates [rule] against [userCtx] and optional [recordData].
  ///
  /// Returns `true` when [rule] is `null` — component is always visible
  /// when no rule is declared (AC-05, fail-safe default).
  ///
  /// AC-21: no transitory List/Map allocations in the hot path.
  bool evaluate(
    Rule? rule,
    UserContext userCtx, [
    Map<String, Object?>? recordData,
  ]) {
    if (rule == null) return true;

    return switch (rule.operator) {
      // --- Logical operators (AC-06, AC-07, AC-08) ---
      'AND' => rule.children!.every(
          (child) => evaluate(child, userCtx, recordData),
        ),
      'OR' => rule.children!.any(
          (child) => evaluate(child, userCtx, recordData),
        ),
      'NOT' => !evaluate(rule.children!.first, userCtx, recordData),

      // --- Role alias (AC-10, AC-11) ---
      'role' => _evaluateRole(rule.value, userCtx),

      // --- Comparison operators (AC-12, AC-13, AC-14) ---
      '==' || '!=' || '>' || '<' || '>=' || '<=' || 'in' || 'not_in' =>
        _evaluateComparison(rule, userCtx, recordData),

      // --- Unknown operator — fail-safe false + warning log ---
      _ => _logUnknownAndReturnFalse(rule.operator),
    };
  }

  bool _evaluateRole(Object? value, UserContext ctx) {
    if (value is List) {
      for (final v in value) {
        if (ctx.roles.contains(v)) return true;
      }
      return false;
    }
    if (value is String) return ctx.roles.contains(value);
    return false;
  }

  bool _evaluateComparison(
    Rule rule,
    UserContext userCtx,
    Map<String, Object?>? recordData,
  ) {
    final fieldValue = _resolver.resolve(rule.field!, userCtx, recordData);
    final ruleValue = rule.value;
    final op = rule.operator;

    // Membership operators (AC-14)
    if (op == 'in') {
      if (ruleValue is! List) return false;
      return ruleValue.contains(fieldValue);
    }
    if (op == 'not_in') {
      if (ruleValue is! List) return false;
      return !ruleValue.contains(fieldValue);
    }

    // Equality operators — work on any type including null (AC-12)
    if (op == '==') return fieldValue == ruleValue;
    if (op == '!=') return fieldValue != ruleValue;

    // Numeric comparisons — type mismatch → false + warning (AC-13)
    final a = _toNum(fieldValue);
    final b = _toNum(ruleValue);
    if (a == null || b == null) {
      developer.log(
        'Non-numeric operand for operator "$op": '
        'field=${rule.field} resolved to ${fieldValue?.runtimeType}, '
        'rule value is ${ruleValue?.runtimeType} — returning false',
        name: 'BDUI.ScalarioCanvasRule',
        level: 900, // warning
      );
      return false;
    }

    return switch (op) {
      '>' => a > b,
      '<' => a < b,
      '>=' => a >= b,
      '<=' => a <= b,
      _ => false,
    };
  }

  num? _toNum(Object? value) => value is num ? value : null;

  bool _logUnknownAndReturnFalse(String op) {
    developer.log(
      'Unknown operator "$op" — evaluating to false (fail-safe)',
      name: 'BDUI.ScalarioCanvasRule',
      level: 900,
    );
    return false;
  }
}
