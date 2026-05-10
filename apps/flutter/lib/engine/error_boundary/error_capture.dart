import 'package:flutter/material.dart';

/// Frame-scoped coordinator for [ErrorWidget.builder] overrides.
///
/// Multiple [ErrorBoundary] / [BDUIErrorBoundary] widgets may build in the
/// same frame. This coordinator tracks the active count and restores
/// [ErrorWidget.builder] to its original value exactly once, when the last
/// active boundary calls [leave] (depth reaches 0).
///
/// This is an internal utility — not part of the package's public API.
class ErrorCapture {
  ErrorCapture._();

  static ErrorWidgetBuilder? _original;
  static int _depth = 0;

  /// Called at the start of each [_ErrorCatcher] / [_BDUIErrorCatcher] build.
  ///
  /// Saves the true original [ErrorWidget.builder] on the first call per frame
  /// (when [_depth] == 0), then increments the depth counter.
  static void enter() {
    if (_depth == 0) _original = ErrorWidget.builder;
    _depth++;
  }

  /// Called from a [WidgetsBinding.addPostFrameCallback] after each catcher
  /// completes (success or error path).
  ///
  /// Decrements depth; restores [ErrorWidget.builder] when depth reaches 0.
  static void leave() {
    if (_depth <= 0) return;
    _depth--;
    if (_depth == 0 && _original != null) {
      ErrorWidget.builder = _original!;
      _original = null;
    }
  }

  /// Resets state — used in tests only.
  static void reset() {
    _depth = 0;
    _original = null;
  }
}
