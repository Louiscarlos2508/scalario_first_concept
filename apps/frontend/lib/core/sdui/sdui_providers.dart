import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/services/sdui_service.dart';

/// Provides a singleton [SduiService].
final sduiServiceProvider = Provider<SduiService>(
  (ref) => SduiService(),
);

/// Fetches and caches the SDUI layout for a given [screen].
///
/// Usage:
/// ```dart
/// final layoutAsync = ref.watch(sduiLayoutProvider('pos'));
/// ```
///
/// Behaviour:
/// - Valid cache (< 1 hour): returns cached layout without network call
/// - Stale cache: fetches fresh layout; on failure returns stale cache
/// - No cache + offline: throws (caller should fall back to default)
final sduiLayoutProvider =
    FutureProvider.family<SduiLayout, String>((ref, screen) async {
  final service = ref.watch(sduiServiceProvider);
  final tenantId = ref.watch(activeTenantProvider);
  return service.fetchLayout(screen, tenantId: tenantId);
});
