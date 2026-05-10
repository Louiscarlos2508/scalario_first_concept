import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode;

/// Structured error payload logged by [ErrorLogger].
///
/// Schema aligns with AC-11. All fields are JSON-serializable.
/// PII rule (AC-15): `message` is sanitized before storage — never contains
/// raw user data. Stack traces are NOT stored; only a short hash (AC-12).
final class ErrorPayload {
  ErrorPayload({
    required Object error,
    required StackTrace stack,
    required this.componentType,
    this.componentId,
    this.screenId,
    this.tenantId,
    this.userId,
    this.userRole,
  })  : timestamp = DateTime.now().toUtc(),
        errorType = error.runtimeType.toString(),
        message = _sanitize(_extractMessage(error)),
        stackHash = _hashStack(stack),
        debugStack = kDebugMode ? stack : null;

  ErrorPayload._fromGlobal({
    required Object error,
    required StackTrace stack,
  })  : timestamp = DateTime.now().toUtc(),
        componentType = 'global',
        componentId = null,
        screenId = null,
        tenantId = null,
        userId = null,
        userRole = null,
        errorType = error.runtimeType.toString(),
        message = _sanitize(_extractMessage(error)),
        stackHash = _hashStack(stack),
        debugStack = kDebugMode ? stack : null;

  factory ErrorPayload.fromGlobal(Object error, StackTrace stack) =>
      ErrorPayload._fromGlobal(error: error, stack: stack);

  final DateTime timestamp;
  final String componentType;
  final String? componentId;
  final String? screenId;
  final String? tenantId;
  final String? userId;
  final String? userRole;
  final String errorType;
  final String message;
  final String stackHash;

  /// Full stack — kept in memory in debug mode only, never serialized (AC-12).
  final StackTrace? debugStack;

  static const String _appVersion = '0.1.0+1';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ts': timestamp.toIso8601String(),
        'level': 'error',
        'tenant_id': tenantId,
        'user_id': userId,
        'screen_id': screenId,
        'component_type': componentType,
        'component_id': componentId,
        'error_type': errorType,
        'message': message,
        'stack_hash': stackHash,
        'app_version': _appVersion,
        'platform': defaultTargetPlatform.name.toLowerCase(),
      };

  @override
  String toString() => jsonEncode(toJson());

  // ---------------------------------------------------------------------------
  // Sanitization — AC-15, AC-16
  // ---------------------------------------------------------------------------

  /// Strips PII patterns from an error message before logging.
  ///
  /// Removes: email addresses, 7+-digit numbers (amounts / IBAN fragments).
  static String sanitize(String message) => _sanitize(message);

  static String _sanitize(String message) {
    var result = message.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'),
      '[email]',
    );
    result = result.replaceAll(RegExp(r'\d{7,}'), '[number]');
    return result;
  }

  static String _extractMessage(Object error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) return str.substring(11);
    return str;
  }

  /// Non-cryptographic fingerprint of the top 10 stack frames (AC-12).
  ///
  /// 8-char hex digest — sufficient for backend deduplication.
  static String _hashStack(StackTrace stack) {
    final lines = stack.toString().split('\n').take(10).join('\n');
    return lines.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }
}
