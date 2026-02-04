import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/isar_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/models/order.dart';

// Services
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// Repositories
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return ProductRepository(isar);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return OrderRepository(isar);
});

// State Notifier for Cart
class CartNotifier extends StateNotifier<List<OrderItem>> {
  CartNotifier() : super([]);

  void addItem(OrderItem item) {
    state = [...state, item];
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

final cartProvider = StateNotifierProvider<CartNotifier, List<OrderItem>>((ref) {
  return CartNotifier();
});
