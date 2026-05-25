/// Immutable data-driven validation rule — mirrors the shared JSON Schema
/// `ValidationRule` contract (STORY-023, architecture line 961).
///
/// The 9 supported types:
///   required    — value must not be null / empty / empty-list.
///   type        — value must match declared type (`string|number|integer|date|boolean`).
///   min         — numeric value >= rule value (inclusive).
///   max         — numeric value <= rule value (inclusive).
///   minLength   — string length (runes) >= rule value.
///   maxLength   — string length (runes) <= rule value.
///   regex       — string matches RE2-compatible pattern.
///   enum        — value is member of allowed list.
///   required_if — conditionally required via ScalarioCanvasRule (STORY-006).
///
/// AC-01: immutable.
/// AC-02: fromJson handles 9 types; unknown → ValidationParseException.
/// AC-03: == / hashCode correct for memoization.
library;

import 'package:meta/meta.dart';

import '../canvas_rule/scalario_canvas_rule.dart';
import 'validation_exception.dart';

@immutable
final class ValidationRule {
  const ValidationRule({
    required this.type,
    this.value,
    this.errorKey,
    this.errorMessage,
    this.requiredIf,
  });

  final String type;

  /// The constraint value — semantics depend on [type]:
  ///   min/max       → num
  ///   minLength/maxLength → int
  ///   regex         → String (regex pattern)
  ///   enum          → `List<dynamic>`
  ///   type          → String ('string'|'number'|'integer'|'date'|'boolean')
  final Object? value;

  /// ARB i18n key for the error message (e.g. 'validation.phone.eight_digits').
  /// Phase 1: returned as-is when no i18n system is wired; STORY-042 completes this.
  final String? errorKey;

  /// Raw string message override — takes priority over [errorKey] and fallback FR.
  /// Supports {min}, {max}, {type}, {value} interpolation placeholders.
  final String? errorMessage;

  /// Condition rule for 'required_if' — evaluated by ScalarioCanvasRule (STORY-006).
  final Rule? requiredIf;

  // ---------------------------------------------------------------------------
  // Supported types
  // ---------------------------------------------------------------------------

  static const _validTypes = <String>{
    'required',
    'type',
    'min',
    'max',
    'minLength',
    'maxLength',
    'regex',
    'enum',
    'required_if',
  };

  static const int _maxRegexPatternLength = 1024;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String || !_validTypes.contains(type)) {
      throw ValidationParseException(
        'Unknown or missing validation type: "$type". '
        'Valid types: ${_validTypes.join(", ")}',
      );
    }

    Rule? requiredIf;
    if (type == 'required_if') {
      final rif = json['requiredIf'];
      if (rif is! Map<String, dynamic>) {
        throw ValidationParseException(
          'required_if rule must include a "requiredIf" rule object '
          '(e.g. {"field": "amount", "operator": ">", "value": 500000}), '
          'got ${rif?.runtimeType}',
        );
      }
      try {
        requiredIf = Rule.fromJson(rif);
      } on RuleParseException catch (e) {
        throw ValidationParseException(
          'required_if.requiredIf parse error: ${e.message}',
        );
      }
    }

    // Validate regex at parse time (AC-08) to surface bad patterns immediately.
    if (type == 'regex') {
      final pattern = json['value'];
      if (pattern is! String) {
        throw ValidationParseException(
          'regex rule "value" must be a String, got ${pattern?.runtimeType}',
        );
      }
      if (pattern.length > _maxRegexPatternLength) {
        throw ValidationParseException(
          'regex pattern exceeds maximum length of $_maxRegexPatternLength chars '
          '(got ${pattern.length}) — ReDoS protection.',
        );
      }
      try {
        RegExp(pattern);
      } catch (e) {
        throw ValidationParseException('Invalid regex pattern: $e');
      }
    }

    return ValidationRule(
      type: type,
      value: json['value'] as Object?,
      errorKey: json['errorKey'] as String?,
      errorMessage: json['errorMessage'] as String?,
      requiredIf: requiredIf,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hash (AC-03)
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ValidationRule) return false;
    return type == other.type &&
        _deepEquals(value, other.value) &&
        errorKey == other.errorKey &&
        errorMessage == other.errorMessage &&
        requiredIf == other.requiredIf;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(
        type,
        value is List ? Object.hashAll(value! as List) : value,
        errorKey,
        errorMessage,
        requiredIf,
      );

  @override
  String toString() =>
      'ValidationRule(type: $type, value: $value, errorKey: $errorKey)';
}
