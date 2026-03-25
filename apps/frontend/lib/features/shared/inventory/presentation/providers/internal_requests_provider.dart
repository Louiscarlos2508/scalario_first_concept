import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/inventory/data/repositories/internal_requests_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

final internalRequestsRepositoryProvider =
    Provider<InternalRequestsRepository>((ref) {
  return InternalRequestsRepository(
    tokenGetter: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
});

/// Filtre de statut — null = tous
final internalRequestsStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Liste des demandes (toutes ou filtrées par statut)
final internalRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final status = ref.watch(internalRequestsStatusFilterProvider);
  final repo = ref.watch(internalRequestsRepositoryProvider);

  return repo.list(tenantId: tenantId, status: status);
});

/// Nombre de demandes en attente d'action selon le rôle
/// - manager: compte les pending
/// - owner: compte les prepared
final internalRequestsPendingCountProvider =
    FutureProvider.family<int, String>((ref, role) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return 0;

  final repo = ref.watch(internalRequestsRepositoryProvider);
  final statusToWatch = (role == 'owner') ? 'prepared' : 'pending';

  final items = await repo.list(tenantId: tenantId, status: statusToWatch);
  return items.length;
});
