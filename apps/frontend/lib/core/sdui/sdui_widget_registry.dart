import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Factory function type: receives panel props and returns a Widget.
typedef SduiPanelFactory = Widget Function(Map<String, dynamic> props);

/// Global registry mapping SDUI panel type strings to widget factories.
///
/// Factories are registered at app startup (Story 10-5).
/// Unknown types render [SizedBox.shrink] — silent graceful degradation.
///
/// Example:
/// ```dart
/// SduiWidgetRegistry.register('product_grid', (_) => const ProductGrid());
/// SduiWidgetRegistry.register('cart_panel',   (_) => const CartPanel());
/// ```
class SduiWidgetRegistry {
  SduiWidgetRegistry._(); // prevent instantiation

  static final Map<String, SduiPanelFactory> _registry = {};

  /// Register a factory for [type].
  static void register(String type, SduiPanelFactory factory) {
    _registry[type] = factory;
  }

  /// Build a widget for [type] with [props].
  /// Returns [SizedBox.shrink] for unknown types — never crashes.
  static Widget build(String type, Map<String, dynamic> props) {
    final factory = _registry[type];
    if (factory != null) return factory(props);

    // Fail silently; log in debug mode only.
    if (kDebugMode) {
      debugPrint(
        'SduiWidgetRegistry: unknown panel type "$type". '
        'Register it before rendering.',
      );
    }
    return const SizedBox.shrink();
  }

  /// Returns true if [type] is registered.
  static bool hasType(String type) => _registry.containsKey(type);

  /// Clear all registrations (use in tests only).
  static void reset() => _registry.clear();
}
