import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/retention_service.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:frontend/core/services/barcode_scanner_service.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/repositories/category_repository.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/product_repository.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/presentation/state/session_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/state/checkout_controller.dart';
import 'package:frontend/features/retail/pos/presentation/state/parked_carts_notifier.dart';
import 'package:frontend/features/shared/returns/data/repositories/returns_repository.dart';

// Services & Repositories
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final retentionServiceProvider = Provider<RetentionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return RetentionService(isarService);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductRepository(isarService);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CategoryRepository(isarService);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return OrderRepository(isarService);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return SessionRepository(isarService);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CustomerRepository(isarService);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return InventoryRepository(
    isarService: isarService,
    tokenGetter: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
});

/// Stream of pending inventory movement count — drives the outbox badge.
final inventoryOutboxCountProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(inventoryRepositoryProvider);
  // Poll every 10 seconds to refresh the count.
  while (true) {
    final pending = await repo.getPendingMovements();
    yield pending.length;
    await Future.delayed(const Duration(seconds: 10));
  }
});

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<PosSession?>>((ref) {
      final repo = ref.watch(sessionRepositoryProvider);
      final orderRepo = ref.watch(orderRepositoryProvider);
      final userId = ref.watch(userProfileProvider).valueOrNull?.id ?? '';
      return SessionNotifier(repo, orderRepo, userId: userId);
    });

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final syncStatusProvider = StreamProvider<SyncUiStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final supabase = Supabase.instance.client;
  final syncService = ref.watch(syncServiceProvider);
  return RealtimeService(supabase, syncService, ref);
});

final barcodeScannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final cart = ref.watch(cartProvider.notifier);
  final service = BarcodeScannerService(repo, cart);

  ref.onDispose(() => service.dispose());

  return service;
});

// UI State
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

final parkedCartsProvider =
    StateNotifierProvider<ParkedCartsNotifier, List<CartState>>((ref) {
      final isarService = ref.watch(isarServiceProvider);
      return ParkedCartsNotifier(isarService);
    });

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, AsyncValue<void>>((ref) {
      final orderRepo = ref.watch(orderRepositoryProvider);
      final productRepo = ref.watch(productRepositoryProvider);
      final cartNotifier = ref.watch(cartProvider.notifier);
      return CheckoutController(orderRepo, productRepo, cartNotifier, ref);
    });

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final posSearchQueryProvider = StateProvider<String>((ref) => '');

// Epic 24 — Freshness filter state (persisted for POS session duration)
final urgentOnlyFilterProvider = StateProvider<bool>((ref) => false);

// Epic 24 — Freshness thresholds (configurable per tenant; defaults match backend)
class FreshnessThresholds {
  final double greenThreshold;
  final double orangeThreshold;
  const FreshnessThresholds({
    this.greenThreshold = 50.0,
    this.orangeThreshold = 20.0,
  });
}

final freshnessThresholdsProvider = StateProvider<FreshnessThresholds>(
  (ref) => const FreshnessThresholds(),
);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  return repo.getCategories(tenantId);
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final products = await repo.getProducts(
    categoryId: categoryId,
    tenantId: tenantId,
  );
  // AC3 — Mark parent products (hasChildren) based on parentItemId references
  final parentIds = products
      .where((p) => p.parentItemId != null)
      .map((p) => p.parentItemId!)
      .toSet();
  for (final p in products) {
    if (p.remoteId != null && parentIds.contains(p.remoteId)) {
      p.hasChildren = true;
    }
  }

  // AC5 (Story 24-2) — Merge batch freshness data (fails gracefully offline)
  try {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/batches/expiring',
    ).replace(queryParameters: {'tenantId': tenantId, 'days': '365'});
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final batches = jsonDecode(response.body) as List<dynamic>;
      // Build map: catalogItemId → earliest batch (already sorted by expiresAt ASC)
      final batchMap = <String, Map<String, dynamic>>{};
      for (final b in batches) {
        final itemId = b['catalogItemId']?.toString();
        if (itemId != null && !batchMap.containsKey(itemId)) {
          batchMap[itemId] = b as Map<String, dynamic>;
        }
      }
      for (final p in products) {
        if (p.remoteId != null && batchMap.containsKey(p.remoteId)) {
          final b = batchMap[p.remoteId]!;
          p.nearestExpiryDate = b['expiresAt'] != null
              ? DateTime.tryParse(b['expiresAt'].toString())
              : null;
        }
      }
    }
  } catch (_) {
    // Offline or error — products shown without freshness indicator
  }

  return products;
});

/// AC2 — Warning message shown after checkout when parent stock drops low.
final parentStockWarningProvider = StateProvider<String?>((ref) => null);

final inventorySearchProvider = StateProvider<String>((ref) => '');
final inventoryPageProvider = StateProvider<int>((ref) => 1);
final inventoryLimitProvider = StateProvider<int>((ref) => 20);

final paginatedProductListProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(productRepositoryProvider);
  final query = ref.watch(inventorySearchProvider);
  final page = ref.watch(inventoryPageProvider);
  final limit = ref.watch(inventoryLimitProvider);
  final tenantId = ref.watch(activeTenantProvider);

  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  return repo.getProductsRemote(
    query: query,
    page: page,
    limit: limit,
    tenantId: tenantId,
    token: token,
  );
});

final stockHistoryDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

/// History filtered by a specific catalog item (used from CatalogScreen).
final stockHistoryByItemProvider = FutureProvider.family<List<dynamic>, String>(
  (ref, catalogItemId) async {
    final range = ref.watch(stockHistoryDateRangeProvider);
    final tenantId = ref.watch(activeTenantProvider);
    final queryParams = <String, String>{'catalogItemId': catalogItemId};
    if (range != null) queryParams['since'] = range.start.toIso8601String();
    if (tenantId != null) queryParams['tenantId'] = tenantId;

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/inventory/movements',
    ).replace(queryParameters: queryParams);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-tenant-id': ?tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List<dynamic>?) ?? [];
    }
    throw Exception('Failed to fetch item history: ${response.statusCode}');
  },
);

final stockHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final range = ref.watch(stockHistoryDateRangeProvider);
  final tenantId = ref.watch(activeTenantProvider);

  String url = '${ApiConstants.baseUrl}/inventory/movements';
  final queryParams = <String, String>{};

  if (range != null) {
    queryParams['since'] = range.start.toIso8601String();
  }

  if (tenantId != null) {
    queryParams['tenantId'] = tenantId;
  }

  final uri = Uri.parse(url).replace(queryParameters: queryParams);
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'x-tenant-id': ?tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['items'] as List<dynamic>?) ?? [];
  } else {
    throw Exception('Failed to fetch stock history: ${response.statusCode}');
  }
});

// Epic 27 — Returns repository (online-only, no Isar)
final returnsRepositoryProvider = Provider<ReturnsRepository>((ref) {
  return ReturnsRepository(
    tokenGetter: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
});
