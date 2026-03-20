import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/reservations/data/repositories/reservations_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(
    tokenGetter: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
});

final reservationsListProvider =
    FutureProvider.family<List<dynamic>, String>((ref, status) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final repo = ref.watch(reservationsRepositoryProvider);
  final result = await repo.listReservations(tenantId: tenantId, status: status);
  return (result['items'] as List<dynamic>?) ?? [];
});

final reservationsKpiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {'pendingCount': 0, 'totalDepositAmount': 0};
  final repo = ref.watch(reservationsRepositoryProvider);
  return repo.getKpi(tenantId: tenantId);
});
