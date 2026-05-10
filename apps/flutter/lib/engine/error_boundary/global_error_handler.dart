import 'package:flutter/foundation.dart'
    show FlutterError, FlutterErrorDetails, PlatformDispatcher, kDebugMode;
import 'package:flutter/material.dart';

import 'error_logger.dart';
import 'error_payload.dart';

/// Global error sink — Level 3 of the 3-tier error strategy (AC-09, AC-10).
///
/// Catches everything that escapes Levels 1 (per-component [ErrorBoundary])
/// and 2 (per-screen [BDUIErrorBoundary]):
/// - Flutter framework errors via [FlutterError.onError].
/// - Dart platform errors via [PlatformDispatcher.instance.onError].
/// - Unhandled async exceptions via the [runZonedGuarded] zone in `main.dart`.
///
/// Call [install] exactly once in `main()` before [runApp]:
/// ```dart
/// void main() {
///   final key = GlobalObjectKey<NavigatorState>('root_navigator');
///   GlobalErrorHandler.install(navigatorKey: key);
///   runZonedGuarded(
///     () { _setupDependencies(); runApp(ScalarioApp(navigatorKey: key)); },
///     GlobalErrorHandler.handleZoneError,
///   );
/// }
/// ```
abstract final class GlobalErrorHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;

  // ---------------------------------------------------------------------------
  // Install
  // ---------------------------------------------------------------------------

  /// Wire up all three global error hooks (AC-09).
  ///
  /// Must be called before [runApp]. [navigatorKey] is required only in
  /// release mode (SnackBar display); it may be null in debug/tests.
  static void install({GlobalKey<NavigatorState>? navigatorKey}) {
    _navigatorKey = navigatorKey;

    FlutterError.onError = (FlutterErrorDetails details) {
      _handle(details.exception, details.stack ?? StackTrace.empty);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _handle(error, stack);
      return true; // Prevent the platform from crashing the isolate.
    };
  }

  /// Zone error callback — pass directly to [runZonedGuarded] second argument.
  static void handleZoneError(Object error, StackTrace stack) =>
      _handle(error, stack);

  // ---------------------------------------------------------------------------
  // Core handler
  // ---------------------------------------------------------------------------

  static void _handle(Object error, StackTrace stack) {
    try {
      ErrorLogger.instance.log(ErrorPayload.fromGlobal(error, stack));
    } catch (_) {
      // Logger itself failed — last resort print.
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('\x1B[31m[GlobalErrorHandler] ${error.runtimeType}: $error'
          '\n$stack\x1B[0m');
    } else {
      _showSnackBar('Erreur technique signalée');
    }
  }

  // ---------------------------------------------------------------------------
  // SnackBar (release only — requires a live Navigator)
  // ---------------------------------------------------------------------------

  static void _showSnackBar(String message) {
    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;
    try {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      // ScaffoldMessenger not available — silently ignore.
    }
  }
}
