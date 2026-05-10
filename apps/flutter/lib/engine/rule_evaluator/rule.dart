/// Rule value object + parser for the Scalario BDUI expression language.
///
/// Three JSON forms are supported:
///   Logical   : { "AND": [...] }  |  { "OR": [...] }  |  { "NOT": {...} }
///   Comparison: { "field": "record.montant", "operator": ">", "value": 500000 }
///   Role alias: { "role": ["MANAGER", "DG"] }
///
/// AC-01: immutable, == / hashCode correct for memoization.
/// AC-02: Rule.fromJson handles all 3 forms.
/// AC-03: malformed JSON → RuleParseException with node path.
library;

import 'package:meta/meta.dart';

/// Thrown when [Rule.fromJson] encounters an invalid structure.
///
/// [message] always includes the JSON path of the offending node so the
/// caller (or test) can pinpoint the error without inspecting the full tree.
final class RuleParseException implements Exception {
  const RuleParseException(this.message);

  final String message;

  @override
  String toString() => 'RuleParseException: $message';
}

/// Immutable expression node for the BDUI rule system.
///
/// Operators:
///   Logical    : AND, OR, NOT
///   Role alias : role   (shortcut for `user.roles contains value`)
///   Comparison : ==  !=  >  <  >=  <=  in  not_in
@immutable
final class Rule {
  const Rule({
    required this.operator,
    this.children,
    this.field,
    this.value,
  });

  /// Logical or comparison operator (e.g. 'AND', '==', 'role').
  final String operator;

  /// Child rules for logical operators (AND/OR/NOT).
  final List<Rule>? children;

  /// Dotted field path for comparison operators (e.g. 'record.montant').
  final String? field;

  /// RHS value for comparison, or list of roles for the 'role' operator.
  final Object? value;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses a JSON map into a [Rule].
  ///
  /// [path] is used in error messages to identify the offending node.
  factory Rule.fromJson(Map<String, dynamic> json, [String path = 'root']) {
    // --- Logical operators ---
    if (json.containsKey('AND')) {
      return _parseLogical(json['AND'], 'AND', path);
    }
    if (json.containsKey('OR')) {
      return _parseLogical(json['OR'], 'OR', path);
    }
    if (json.containsKey('NOT')) {
      final raw = json['NOT'];
      if (raw is! Map<String, dynamic>) {
        throw RuleParseException(
          '[$path.NOT] child must be a single rule object, not a list or scalar',
        );
      }
      return Rule(
        operator: 'NOT',
        children: [Rule.fromJson(raw, '$path.NOT')],
      );
    }

    // --- Role shortcut: { "role": "MANAGER" } or { "role": ["MANAGER", "DG"] } ---
    if (json.containsKey('role')) {
      final raw = json['role'];
      final List<Object?> roles;
      if (raw is String) {
        roles = <Object?>[raw];
      } else if (raw is List) {
        roles = raw.cast<Object?>();
      } else {
        throw RuleParseException(
          '[$path] "role" must be a String or List<String>, got ${raw.runtimeType}',
        );
      }
      return Rule(operator: 'role', value: roles);
    }

    // --- Comparison: { "field": "...", "operator": "...", "value": ... } ---
    if (json.containsKey('field')) {
      final field = json['field'];
      if (field is! String || field.isEmpty) {
        throw RuleParseException(
          '[$path] "field" must be a non-empty string, got ${field.runtimeType}',
        );
      }
      final op = json['operator'];
      if (op is! String) {
        throw RuleParseException(
          '[$path] "operator" must be a string, got ${op?.runtimeType}',
        );
      }
      const validOps = {
        '==', '!=', '>', '<', '>=', '<=', 'in', 'not_in',
      };
      if (!validOps.contains(op)) {
        throw RuleParseException(
          '[$path] unknown comparison operator "$op". '
          'Valid operators: ${validOps.join(", ")}',
        );
      }
      return Rule(operator: op, field: field, value: json['value']);
    }

    throw RuleParseException(
      '[$path] unrecognized rule structure — no recognized key found. '
      'Keys present: ${json.keys.join(", ")}',
    );
  }

  static Rule _parseLogical(
    dynamic raw,
    String op,
    String path,
  ) {
    if (raw is! List || raw.isEmpty) {
      throw RuleParseException(
        '[$path.$op] children must be a non-empty List, got '
        '${raw is List ? "empty List" : raw.runtimeType}',
      );
    }
    final children = <Rule>[];
    for (var i = 0; i < raw.length; i++) {
      final child = raw[i];
      if (child is! Map<String, dynamic>) {
        throw RuleParseException(
          '[$path.$op[$i]] each child must be a rule object, got ${child.runtimeType}',
        );
      }
      children.add(Rule.fromJson(child, '$path.$op[$i]'));
    }
    return Rule(operator: op, children: List.unmodifiable(children));
  }

  // ---------------------------------------------------------------------------
  // Equality & hash — required for memoization (AC-01)
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Rule) return false;
    if (operator != other.operator) return false;
    if (field != other.field) return false;
    if (!_deepEquals(value, other.value)) return false;
    final a = children;
    final b = other.children;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(
        operator,
        field,
        value is List ? Object.hashAll(value! as List) : value,
        children?.length,
      );

  @override
  String toString() => 'Rule(op: $operator, field: $field, value: $value)';
}
