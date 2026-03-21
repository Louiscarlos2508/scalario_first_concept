import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';

final clientOrderKpisProvider =
    FutureProvider<ClientOrderKpis>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return ClientOrderKpis.zero;
  try {
    final repo = ref.watch(clientOrderRepositoryProvider);
    return repo.getKpis(tenantId: tenantId);
  } catch (_) {
    return ClientOrderKpis.zero;
  }
});
