import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/stock_alerts/data/repositories/stock_alerts_repository.dart';

final stockAlertsRepositoryProvider = Provider<StockAlertsRepository>((ref) {
  return StockAlertsRepository();
});

final stockAlertsProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final repo = ref.watch(stockAlertsRepositoryProvider);
  return repo.getAlerts(tenantId: tenantId);
});

final stockAlertCountProvider = AutoDisposeFutureProvider<int>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return 0;
  final repo = ref.watch(stockAlertsRepositoryProvider);
  return repo.getCount(tenantId: tenantId);
});
