import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';

final businessTypeConfigRepositoryProvider =
    Provider<BusinessTypeConfigRepository>(
  (ref) => BusinessTypeConfigRepository(),
);

/// Loads the BusinessTypeDefinition for the current tenant.
/// Cached by Riverpod for the session duration.
/// Falls back to the 'generaliste' config if the tenant has no type or config unavailable.
final businessTypeConfigProvider =
    FutureProvider<BusinessTypeConfig>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return BusinessTypeConfig.fallback;
  final repo = ref.watch(businessTypeConfigRepositoryProvider);
  return repo.getMyConfig(tenantId);
});
