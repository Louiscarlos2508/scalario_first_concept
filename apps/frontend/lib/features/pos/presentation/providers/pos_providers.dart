import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/pos/presentation/state/checkout_controller.dart';

// Services & Repositories
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductRepository(isarService);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return OrderRepository(isarService);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  return SyncService(orderRepo, productRepo);
});

// UI State
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final checkoutControllerProvider = StateNotifierProvider<CheckoutController, AsyncValue<void>>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final cartNotifier = ref.watch(cartProvider.notifier);
  return CheckoutController(orderRepo, cartNotifier);
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  // In a real app, we might watch a stream or use a StreamProvider
  // For now, we fetch once.
  return repo.getProducts();
});
