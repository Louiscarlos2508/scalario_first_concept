/// Resolves a dotted field path to a runtime value.
///
/// Supported prefixes:
///   user.role             → userCtx.roles.first (or null if empty)
///   user.roles            → userCtx.roles as List
///   user.userId           → userCtx.userId
///   user.tenantId         → userCtx.tenantId
///   user.departmentId     → userCtx.departmentId
///   user.attributes.foo   → userCtx.attributes['foo'] (arbitrary depth)
///   record.montant        → recordData['montant']
///   record.lines[0].qty   → recordData nested with array index
///
/// AC-15 to AC-19: null-safe — absent fields return null, never throw.
library;

import 'dart:developer' as developer;

import 'user_context.dart';

/// Pure stateless resolver — safe to share as a const singleton.
///
/// AC-21: no transitory allocations in the hot path beyond iteration.
final class FieldResolver {
  const FieldResolver();

  /// Resolves [path] to a value using [userCtx] and optional [recordData].
  ///
  /// Returns `null` for any absent or out-of-bounds segment.
  Object? resolve(
    String path,
    UserContext userCtx, [
    Map<String, Object?>? recordData,
  ]) {
    final segments = _parsePath(path);
    if (segments.isEmpty) return null;

    final prefix = segments[0];

    if (prefix == 'user') {
      return _resolveUser(segments, 1, userCtx);
    }

    if (prefix == 'record') {
      if (recordData == null) {
        developer.log(
          'record.* field "$path" accessed without recordData — returning null',
          name: 'BDUI.RuleEvaluator',
          level: 900,
        );
        return null;
      }
      return _resolveNested(recordData, segments, 1);
    }

    // Unknown prefix: treat entire path as a record key chain (best-effort).
    return _resolveNested(recordData ?? const {}, segments, 0);
  }

  Object? _resolveUser(
    List<String> segments,
    int offset,
    UserContext ctx,
  ) {
    if (offset >= segments.length) return null;
    final key = segments[offset];
    switch (key) {
      case 'role':
        // AC-15: returns roles.first or null.
        return ctx.roles.isEmpty ? null : ctx.roles.first;
      case 'roles':
        return ctx.roles.toList(growable: false);
      case 'userId':
        return ctx.userId;
      case 'tenantId':
        return ctx.tenantId;
      case 'departmentId':
        return ctx.departmentId;
      case 'attributes':
        // AC-16: arbitrary depth inside attributes map.
        if (offset + 1 >= segments.length) return ctx.attributes;
        return _resolveNested(ctx.attributes, segments, offset + 1);
      default:
        return null;
    }
  }

  /// Walks [data] following [segments] starting at [offset].
  Object? _resolveNested(
    Map<String, Object?> data,
    List<String> segments,
    int offset,
  ) {
    Object? current = data;
    for (var i = offset; i < segments.length; i++) {
      if (current == null) return null;

      final seg = segments[i];
      final bracketIdx = seg.indexOf('[');

      if (bracketIdx >= 0) {
        // AC-18: array-index notation "lines[0]"
        final key = seg.substring(0, bracketIdx);
        final idxStr = seg.substring(bracketIdx + 1, seg.length - 1);
        final idx = int.tryParse(idxStr);
        if (idx == null) return null;

        if (current is Map) {
          current = current[key];
        } else {
          return null;
        }
        if (current is List) {
          if (idx < 0 || idx >= current.length) return null; // AC-18 OOB
          current = current[idx];
        } else {
          return null;
        }
      } else {
        if (current is Map) {
          current = current[seg];
        } else {
          return null;
        }
      }
    }
    return current;
  }

  /// Splits a dotted path into segments, keeping array-index tokens attached
  /// to their key (e.g. "lines[0]" stays as one segment).
  List<String> _parsePath(String path) {
    final result = <String>[];
    final buf = StringBuffer();
    var inBracket = false;

    for (var i = 0; i < path.length; i++) {
      final ch = path[i];
      if (ch == '[') {
        inBracket = true;
        buf.write(ch);
      } else if (ch == ']') {
        inBracket = false;
        buf.write(ch);
      } else if (ch == '.' && !inBracket) {
        if (buf.isNotEmpty) {
          result.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) result.add(buf.toString());
    return result;
  }
}
