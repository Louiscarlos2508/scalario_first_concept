import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/catalog/data/repositories/catalog_repository.dart';
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

/// Count of products whose stockQuantity < minStockLevel (Epic 22).
/// Products with no minStockLevel are excluded.
final lowStockCountProvider = FutureProvider<int>((ref) async {
  final products = await ref.watch(catalogProvider.future);
  return products.where((p) {
    final minStock = p['minStockLevel'];
    if (minStock == null) return false;
    final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0.0;
    final min = (minStock as num).toDouble();
    return stock < min;
  }).length;
});
