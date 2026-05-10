import 'package:flutter/material.dart';

/// Stub Sprint 1 — wraps a child widget with error isolation.
///
/// STORY-010 replaces this with a real implementation that captures
/// exceptions, logs context (tenant_id + screen_id + component_type),
/// and renders a localized fallback UI. This stub is a pass-through so
/// the ComponentRegistry (STORY-005) can reference the API contract
/// without a circular dependency.
///
/// AC-10: no runZonedGuarded or FlutterError.onError here — those hooks
/// belong to STORY-010.
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({
    super.key,
    required this.componentType,
    this.componentId,
    required this.child,
  });

  final String componentType;
  final String? componentId;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
