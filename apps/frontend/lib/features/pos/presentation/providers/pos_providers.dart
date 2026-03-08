import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:frontend/core/services/barcode_scanner_service.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/repositories/category_repository.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/pos/data/models/pos_session.dart';
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/features/pos/presentation/state/session_notifier.dart';
import 'package:frontend/features/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/pos/presentation/state/checkout_controller.dart';
import 'package:frontend/features/pos/presentation/state/parked_carts_notifier.dart';

// Services & Repositories
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
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

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<PosSession?>>((ref) {
      final repo = ref.watch(sessionRepositoryProvider);
      final orderRepo = ref.watch(orderRepositoryProvider);
      return SessionNotifier(repo, orderRepo);
    });

final syncServiceProvider = Provider<SyncService>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);

  return SyncService(
    orderRepo,
    productRepo,
    sessionRepo,
    customerRepo,
    categoryRepo,
  );
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

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final tenantId = ref.watch(activeTenantProvider);
  return repo.getProducts(categoryId: categoryId, tenantId: tenantId);
});

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

  return repo.getProductsRemote(
    query: query,
    page: page,
    limit: limit,
    tenantId: tenantId,
  );
});

final stockHistoryDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final stockHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  const baseUrl = 'http://127.0.0.1:3000';
  final range = ref.watch(stockHistoryDateRangeProvider);
  final tenantId = ref.watch(activeTenantProvider);

  String url = '$baseUrl/pos/stock-movements';
  final queryParams = <String, String>{};

  if (range != null) {
    queryParams['start'] = DateFormat('yyyy-MM-dd').format(range.start);
    queryParams['end'] = DateFormat('yyyy-MM-dd').format(range.end);
  }

  if (tenantId != null) {
    queryParams['tenantId'] = tenantId;
  }

  final uri = Uri.parse(url).replace(queryParameters: queryParams);
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch stock history: ${response.statusCode}');
  }
});
