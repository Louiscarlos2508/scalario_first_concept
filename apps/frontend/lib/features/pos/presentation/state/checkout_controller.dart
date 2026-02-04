import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/data/models/order.dart';
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart';

import 'cart_notifier.dart';

class CheckoutController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _orderRepository;
  final CartNotifier _cartNotifier;

  CheckoutController(this._orderRepository, this._cartNotifier) : super(const AsyncData(null));

  Future<void> checkout(CartState cart) async {
    if (cart.items.isEmpty) return;

    state = const AsyncLoading();
    try {
      final order = Order()
        ..totalAmount = cart.totalAmount
        ..itemNames = cart.items.map((e) => '${e.product.name} (x${e.quantity})').toList();

      await _orderRepository.saveOrder(order);
      
      _cartNotifier.clearCart();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
