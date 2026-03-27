import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/data/client_order_repository.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';

class ClientOrdersFilter {
  final String? status;
  final String? customerName;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? createdBy;

  const ClientOrdersFilter({
    this.status,
    this.customerName,
    this.dateFrom,
    this.dateTo,
    this.createdBy,
  });

  @override
  bool operator ==(Object other) =>
      other is ClientOrdersFilter &&
      other.status == status &&
      other.customerName == customerName &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.createdBy == createdBy;

  @override
  int get hashCode =>
      Object.hash(status, customerName, dateFrom, dateTo, createdBy);
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
    customerName: filter.customerName?.isEmpty == true ? null : filter.customerName,
    createdBy: filter.createdBy,
    dateFrom: filter.dateFrom,
    dateTo: filter.dateTo,
  );
});
