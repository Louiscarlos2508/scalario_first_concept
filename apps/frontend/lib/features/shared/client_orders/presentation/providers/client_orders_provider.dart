import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/data/client_order_repository.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';

class ClientOrdersFilter {
  final String? status;
  final String? customerId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ClientOrdersFilter({
    this.status,
    this.customerId,
    this.dateFrom,
    this.dateTo,
  });

  @override
  bool operator ==(Object other) =>
      other is ClientOrdersFilter &&
      other.status == status &&
      other.customerId == customerId &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode =>
      Object.hash(status, customerId, dateFrom, dateTo);
}

final clientOrderRepositoryProvider = Provider<ClientOrderRepository>((ref) {
  return ClientOrderRepository();
});

final clientOrderDetailProvider =
    FutureProvider.family<ClientOrder, String>((ref, id) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) throw Exception('No active tenant');
  final repo = ref.watch(clientOrderRepositoryProvider);
  return repo.getOrder(id, tenantId: tenantId);
});

final clientOrdersProvider =
    FutureProvider.family<List<ClientOrder>, ClientOrdersFilter>(
        (ref, filter) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final repo = ref.watch(clientOrderRepositoryProvider);
  return repo.getOrders(
    tenantId: tenantId,
    status: filter.status,
    customerId: filter.customerId?.isEmpty == true ? null : filter.customerId,
    dateFrom: filter.dateFrom,
    dateTo: filter.dateTo,
  );
});
