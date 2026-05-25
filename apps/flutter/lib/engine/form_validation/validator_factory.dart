// SECURITY: This validation is UX-only — it provides user-facing feedback.
// Any client-side validator can be bypassed by a malicious actor (e.g. modified
// APK, intercepted HTTP request). The NestJS Zod backend (FR-014, STORY-014)
// is the real security barrier. Never make authorization or data-integrity
// decisions based on client-side validation alone.
//
// REDOS PROTECTION: Regex patterns are capped at 1024 chars at parse time
// (ValidationRule.fromJson). Input strings are capped at 10 000 chars before
// matching. Elapsed time is measured; if a pattern exceeds 50 ms the validator
// skips the check and logs a warning — the backend Zod layer remains the safety net.

library;

import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'field_context.dart';
import 'validation_messages.dart';
import 'validation_rule.dart';

/// Transforms a list of [ValidationRule] objects into a Flutter
/// [FormFieldValidator] that can be plugged directly into any [FormField]
/// (TextFormField, DropdownButtonFormField, etc.).
///
/// Rules are evaluated **in order**; the first error short-circuits the rest
/// (AC-26 — early return on first failure).
///
/// Usage:
/// ```dart
/// final factory = ValidatorFactory();
/// final validator = factory.fromRules(field.validationRules, fieldCtx);
/// TextFormField(validator: validator, ...)
/// ```
///
/// A single [ValidatorFactory] instance is safe to share across the widget tree
/// — it holds no mutable state.
final class ValidatorFactory {
  ValidatorFactory({ValidationMessages? messages})
      : _messages = messages ?? const ValidationMessages();

  final ValidationMessages _messages;

  static const int _maxInputLength = 10000;
  static const int _regexTimeoutMs = 50;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Builds a [FormFieldValidator] from [rules] that chains all checks.
  ///
  /// [fieldCtx] must reflect the current form-data state at the time each
  /// validator call fires (keep [FieldContext.formData] updated on change).
  FormFieldValidator<T> fromRules<T>(
    List<ValidationRule> rules,
    FieldContext fieldCtx,
  ) {
    return (T? value) {
      for (final rule in rules) {
        final error = _check(rule, value, fieldCtx);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Convenience: builds validators for a map of field-id → rules.
  Map<String, FormFieldValidator<dynamic>> fromRulesMap(
    Map<String, List<ValidationRule>> fieldRules,
    FieldContext fieldCtx,
  ) {
    return {
      for (final entry in fieldRules.entries)
        entry.key: fromRules(entry.value, fieldCtx),
    };
  }

  // ---------------------------------------------------------------------------
  // Rule dispatch
  // ---------------------------------------------------------------------------

  String? _check(
    ValidationRule rule,
    dynamic value,
    FieldContext ctx,
  ) {
    return switch (rule.type) {
      'required' => _checkRequired(value, rule),
      'type' => _checkType(value, rule),
      'min' => _checkMin(value, rule),
      'max' => _checkMax(value, rule),
      'minLength' => _checkMinLength(value, rule),
      'maxLength' => _checkMaxLength(value, rule),
      'regex' => _checkRegex(value, rule),
      'enum' => _checkEnum(value, rule),
      'required_if' => _checkRequiredIf(value, rule, ctx),
      _ => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Individual checks
  // ---------------------------------------------------------------------------

  /// AC-04: null, empty string, and empty list are invalid.
  /// Toggle `false` and NumberInput `0` are valid — only null is absent.
  String? _checkRequired(dynamic value, ValidationRule rule) {
    final isAbsent = value == null ||
        (value is String && value.isEmpty) ||
        (value is List && value.isEmpty);
    if (isAbsent) {
      return _resolveMessage(rule, _messages.defaultFor('required'), rule.value);
    }
    return null;
  }

  /// AC-05: type coercion for number/integer from String; ISO-8601 for date.
  String? _checkType(dynamic value, ValidationRule rule) {
    if (value == null) return null;
    final expected = rule.value;
    if (expected is! String) return null;

    final isValid = switch (expected) {
      'string' => value is String,
      'number' => value is num ||
          (value is String && num.tryParse(value) != null),
      'integer' => value is int ||
          (value is num && value == value.truncate()) ||
          (value is String && int.tryParse(value) != null),
      'date' => value is DateTime ||
          (value is String && _tryParseDate(value) != null),
      'boolean' => value is bool,
      _ => true,
    };

    if (!isValid) {
      return _resolveMessage(
        rule,
        _messages.defaultFor('type'),
        expected,
      );
    }
    return null;
  }

  /// AC-06: inclusive lower bound for numeric values.
  String? _checkMin(dynamic value, ValidationRule rule) {
    if (value == null) return null;
    final min = rule.value;
    if (min is! num) return null;
    final n = _toNum(value);
    if (n == null) return null;
    if (n < min) {
      return _resolveMessage(rule, _messages.defaultFor('min'), min);
    }
    return null;
  }

  /// AC-06: inclusive upper bound for numeric values.
  String? _checkMax(dynamic value, ValidationRule rule) {
    if (value == null) return null;
    final max = rule.value;
    if (max is! num) return null;
    final n = _toNum(value);
    if (n == null) return null;
    if (n > max) {
      return _resolveMessage(rule, _messages.defaultFor('max'), max);
    }
    return null;
  }

  /// AC-07: length counted in Unicode code points (runes), not UTF-16 code units.
  /// "🇧🇫".runes.length == 2 (two regional-indicator scalars).
  String? _checkMinLength(dynamic value, ValidationRule rule) {
    if (value is! String) return null;
    final min = rule.value;
    if (min is! int) return null;
    if (value.runes.length < min) {
      return _resolveMessage(rule, _messages.defaultFor('minLength'), min);
    }
    return null;
  }

  String? _checkMaxLength(dynamic value, ValidationRule rule) {
    if (value is! String) return null;
    final max = rule.value;
    if (max is! int) return null;
    if (value.runes.length > max) {
      return _resolveMessage(rule, _messages.defaultFor('maxLength'), max);
    }
    return null;
  }

  /// AC-08: optional field with no value skips regex (empty ≠ invalid format).
  /// AC-23: input capped at [_maxInputLength] chars; elapsed time guarded at [_regexTimeoutMs] ms.
  String? _checkRegex(dynamic value, ValidationRule rule) {
    if (value is! String || value.isEmpty) return null;
    final pattern = rule.value;
    if (pattern is! String) return null;

    // ReDoS: truncate long inputs before matching.
    final input =
        value.length > _maxInputLength ? value.substring(0, _maxInputLength) : value;

    final regex = RegExp(pattern);
    final sw = Stopwatch()..start();
    final matched = regex.hasMatch(input);
    sw.stop();

    if (sw.elapsedMilliseconds > _regexTimeoutMs) {
      // Pattern is too slow — skip client-side check. Backend Zod (FR-014)
      // remains the source of truth.
      developer.log(
        'Regex exceeded ${_regexTimeoutMs}ms: pattern.length=${pattern.length}, '
        'input.length=${input.length}. Skipping client-side check.',
        name: 'BDUI.ValidatorFactory',
        level: 900,
      );
      return null;
    }

    if (!matched) {
      return _resolveMessage(rule, _messages.defaultFor('regex'), null);
    }
    return null;
  }

  /// AC-09: membership check using == equality.
  String? _checkEnum(dynamic value, ValidationRule rule) {
    if (value == null) return null;
    final allowed = rule.value;
    if (allowed is! List) return null;
    if (!allowed.contains(value)) {
      return _resolveMessage(rule, _messages.defaultFor('enum'), null);
    }
    return null;
  }

  /// AC-10/11: delegates to [ScalarioCanvasRule]; if condition is true, behaves as required.
  String? _checkRequiredIf(
    dynamic value,
    ValidationRule rule,
    FieldContext ctx,
  ) {
    final isRequired =
        ctx.evaluator.evaluate(rule.requiredIf, ctx.userCtx, ctx.formData);
    if (!isRequired) return null;
    return _checkRequired(value, rule);
  }

  // ---------------------------------------------------------------------------
  // Message resolution (AC-16, AC-17, AC-18)
  // ---------------------------------------------------------------------------

  /// Priority: errorMessage → fallback FR. (errorKey is an i18n stub for STORY-042.)
  ///
  /// [ruleValue] is used for placeholder interpolation ({min}, {max}, {type}).
  String _resolveMessage(
    ValidationRule rule,
    String fallback,
    Object? ruleValue,
  ) {
    final template = rule.errorMessage ?? fallback;
    return _interpolate(template, ruleValue);
  }

  /// Replaces {min}, {max}, {type}, {value} with [value].
  String _interpolate(String template, Object? value) {
    final s = value?.toString() ?? '';
    return template
        .replaceAll('{min}', s)
        .replaceAll('{max}', s)
        .replaceAll('{type}', s)
        .replaceAll('{value}', s);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  num? _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
