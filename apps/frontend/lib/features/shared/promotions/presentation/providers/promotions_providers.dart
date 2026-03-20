import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/promotions/data/models/promotion.dart';
import 'package:frontend/features/shared/promotions/data/repositories/promotions_repository.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepository(),
);

/// All promotions for the active tenant.
final promotionsProvider =
    FutureProvider.family<List<Promotion>, String?>((ref, status) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  return ref
      .watch(promotionsRepositoryProvider)
      .listPromotions(tenantId, status: status);
});
