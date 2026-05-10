import 'dart:collection';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;

import 'error_payload.dart';

/// Local error sink for BDUI runtime errors.
///
/// Stores up to [capacity] entries in a FIFO ring buffer (AC-13).
/// Entries are never persisted here — they wait for Drift queue (STORY-033)
/// and the Audit Log backend (STORY-026) to be available. That gap is
/// intentional in Sprint 1 (AC-14).
///
/// Usage:
/// ```dart
/// ErrorLogger.instance.log(ErrorPayload(...));
/// ErrorLogger.instance.recentErrors; // for debug overlay
/// ErrorLogger.instance.clear();      // called on logout (AC-17)
/// ```
class ErrorLogger {
  ErrorLogger._({this.capacity = _defaultCapacity});

  /// Creates an isolated logger for tests (does not replace [instance]).
  @visibleForTesting
  factory ErrorLogger.forTesting({int capacity = 10}) =>
      ErrorLogger._(capacity: capacity);

  static final ErrorLogger instance = ErrorLogger._();

  static const int _defaultCapacity = 200;

  /// Maximum entries in the ring buffer (AC-13).
  final int capacity;

  final Queue<ErrorPayload> _buffer = Queue<ErrorPayload>();

  /// Ordered from oldest to newest.
  List<ErrorPayload> get recentErrors => List<ErrorPayload>.unmodifiable(_buffer);

  int get length => _buffer.length;

  /// Log [payload] to the ring buffer.
  ///
  /// Silently drops the oldest entry when at capacity.
  /// Never throws (AC-edge-case: if THIS method crashes, we print to stderr).
  void log(ErrorPayload payload) {
    try {
      while (_buffer.length >= capacity) {
        _buffer.removeFirst();
      }
      _buffer.addLast(payload);

      if (kDebugMode) {
        // ignore: avoid_print
        print('[ErrorLogger] ${payload.errorType} in ${payload.componentType}'
            '${payload.componentId != null ? "#${payload.componentId}" : ""}'
            ' — ${payload.message}');
      }
    } catch (e, s) {
      // Observability must never crash the app.
      // ignore: avoid_print
      print('[ErrorLogger] CRITICAL: logger itself failed: $e\n$s');
    }
  }

  /// Purge all entries — called on user logout (AC-17).
  void clear() => _buffer.clear();
}
