import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/catalog/data/repositories/catalog_repository.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    isarService: ref.watch(isarServiceProvider),
  ),
);

/// Catalog items read from local Isar database (offline-first).
final catalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProducts(tenantId: tenantId);
});
