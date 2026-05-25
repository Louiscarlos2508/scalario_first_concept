import 'package:flutter/material.dart';

import 'error_capture.dart';
import 'error_logger.dart';
import 'error_payload.dart';
import 'error_screen.dart';

// ---------------------------------------------------------------------------
// BDUI-specific exceptions (consumed by ScalarioCanvas — STORY-008)
// ---------------------------------------------------------------------------

/// Thrown when the incoming JSON fails structural or semantic validation.
class BDUIValidationException implements Exception {
  const BDUIValidationException(this.message, {this.jsonPath});

  final String message;

  /// Dot-notation path of the failing node, e.g. `"components[2].props.value"`.
  final String? jsonPath;

  @override
  String toString() =>
      'BDUIValidationException: $message'
      '${jsonPath != null ? " at $jsonPath" : ""}';
}

/// Thrown when a validated layout fails to render (internal BDUI engine error).
class BDUIRenderException implements Exception {
  const BDUIRenderException(this.message);

  final String message;

  @override
  String toString() => 'BDUIRenderException: $message';
}

// ---------------------------------------------------------------------------
// BDUIErrorBoundary — per-screen level (AC-06 → AC-08)
// ---------------------------------------------------------------------------

/// Wraps an entire BDUI screen so that a full pipeline failure
/// (parse → validate → layout) shows [BDUIErrorScreen] with a retry
/// button instead of crashing the app (AC-06, AC-07, AC-08).
///
/// Usage (STORY-008 will wire this):
/// ```dart
/// BDUIErrorBoundary(
///   screenId: config.screenId,
///   onRetry: () => ref.invalidate(screenProvider(config.screenId)),
///   child: ScalarioCanvas.render(config, context),
/// )
/// ```
class BDUIErrorBoundary extends StatefulWidget {
  const BDUIErrorBoundary({
    super.key,
    required this.screenId,
    required this.child,
    this.onRetry,
  });

  final String screenId;
  final Widget child;

  /// Called when the user taps "Réessayer". Typically invalidates a cache
  /// or re-triggers the screen load. If null, the retry button is hidden.
  final VoidCallback? onRetry;

  @override
  State<BDUIErrorBoundary> createState() => _BDUIErrorBoundaryState();
}

class _BDUIErrorBoundaryState extends State<BDUIErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  void _onError(Object error, StackTrace stack) {
    ErrorLogger.instance.log(
      ErrorPayload(
        error: error,
        stack: stack,
        componentType: 'BDUIScreen',
        screenId: widget.screenId,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() { _error = error; _stack = stack; });
    });
  }

  void _retry() {
    setState(() { _error = null; _stack = null; });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return BDUIErrorScreen(
        screenId: widget.screenId,
        onRetry: _retry,
        error: _error,
        stack: _stack,
      );
    }

    return _BDUIErrorCatcher(
      screenId: widget.screenId,
      onError: _onError,
      child: widget.child,
    );
  }
}

/// Scoped [ErrorWidget.builder] override for the screen-level boundary.
///
/// Uses [ErrorCapture] for coordinated frame-scoped restoration (same
/// mechanism as [_ErrorCatcher] in error_boundary.dart).
class _BDUIErrorCatcher extends StatelessWidget {
  const _BDUIErrorCatcher({
    required this.screenId,
    required this.child,
    required this.onError,
  });

  final String screenId;
  final Widget child;
  final void Function(Object, StackTrace) onError;

  @override
  Widget build(BuildContext context) {
    ErrorCapture.enter();
    bool handled = false;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!handled) {
        handled = true;
        onError(details.exception, details.stack ?? StackTrace.empty);
      }
      return BDUIErrorScreen(screenId: screenId);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => ErrorCapture.leave());

    return child;
  }
}
