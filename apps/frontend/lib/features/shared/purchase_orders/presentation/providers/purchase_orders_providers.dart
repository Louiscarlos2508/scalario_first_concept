import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/data/repositories/purchase_orders_repository.dart';

final purchaseOrdersRepositoryProvider =
    Provider<PurchaseOrdersRepository>((ref) {
  return PurchaseOrdersRepository();
});

/// Current status filter — null means "all"
final purchaseOrdersFilterProvider = StateProvider<String?>((ref) => null);

final purchaseOrdersProvider =
    FutureProvider<List<PurchaseOrderLocal>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final status = ref.watch(purchaseOrdersFilterProvider);
  final repo = ref.watch(purchaseOrdersRepositoryProvider);

  return repo.listOrders(tenantId: tenantId, status: status);
});

final purchaseOrderStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};

  final repo = ref.watch(purchaseOrdersRepositoryProvider);
  return repo.getStats(tenantId);
});
