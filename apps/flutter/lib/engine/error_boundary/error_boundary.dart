import 'package:flutter/material.dart';

import 'error_capture.dart';
import 'error_fallback.dart';
import 'error_logger.dart';
import 'error_payload.dart';

/// Isolates a single BDUI component so that a build exception never
/// propagates to the rest of the screen (AC-01 → AC-05).
///
/// ## How it works
///
/// Flutter has no native per-subtree error boundary. We intercept build
/// failures by temporarily overriding [ErrorWidget.builder] each time
/// [_ErrorCatcher.build] runs. The override is active for the duration of
/// the child's build pass and is restored immediately after (error or not).
///
/// Limitation: between two sibling [ErrorBoundary] widgets building in the
/// same frame, only the last one to build "owns" the override. This is
/// acceptable for the Sprint 1 use case (components build sequentially in
/// depth-first order). Async errors are caught by [GlobalErrorHandler].
///
/// ## API contract (backward-compatible with STORY-005 stub)
///
/// New optional props: [screenId], [fallbackBuilder].
/// All existing call sites compile unchanged.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.componentType,
    this.componentId,
    this.screenId,
    required this.child,
    this.fallbackBuilder,
  });

  /// Type string from [ComponentConfig] — used in fallback + log payload.
  final String componentType;

  /// Optional stable identifier for the component instance.
  final String? componentId;

  /// Screen that owns this component (forwarded to log payload).
  final String? screenId;

  final Widget child;

  /// Custom fallback — receives `(context, error, stack)`.
  /// If null, [ErrorFallback] is shown (AC-03).
  final Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  void _onError(Object error, StackTrace stack) {
    ErrorLogger.instance.log(
      ErrorPayload(
        error: error,
        stack: stack,
        componentType: widget.componentType,
        componentId: widget.componentId,
        screenId: widget.screenId,
      ),
    );
    // setState during a build frame is illegal — defer to post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() { _error = error; _stack = stack; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final builder = widget.fallbackBuilder;
      if (builder != null) {
        return builder(context, _error!, _stack ?? StackTrace.empty);
      }
      return ErrorFallback(
        componentType: widget.componentType,
        error: _error,
        stack: _stack,
      );
    }

    return _ErrorCatcher(
      componentType: widget.componentType,
      onError: _onError,
      child: widget.child,
    );
  }
}

/// Internal widget that installs a scoped [ErrorWidget.builder] override
/// for the duration of its child's build pass (AC-02).
///
/// Uses [ErrorCapture] to coordinate with sibling catchers in the same frame:
/// restoration only happens when the last active catcher's post-frame callback
/// fires (depth → 0), so the true original builder is always recovered.
class _ErrorCatcher extends StatelessWidget {
  const _ErrorCatcher({
    required this.child,
    required this.componentType,
    required this.onError,
  });

  final Widget child;
  final String componentType;
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
      return ErrorFallback(componentType: componentType);
    };

    // Leave the scope after this frame (success or error).
    WidgetsBinding.instance.addPostFrameCallback((_) => ErrorCapture.leave());

    return child;
  }
}
