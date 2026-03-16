import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import '../../data/models/cart_item.dart' as model;
import 'dart:convert';
import 'cart_notifier.dart';

class CheckoutController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  final CartNotifier _cartNotifier;
  final Ref _ref;

  CheckoutController(this._orderRepository, this._productRepository, this._cartNotifier, this._ref) : super(const AsyncData(null));

  Future<Order?> checkout(CartState cart, String? sessionId) async {
    if (cart.items.isEmpty) return null;

    state = const AsyncLoading();
    try {
      final session = _ref.read(sessionProvider).value;
      final selectedCustomer = _ref.read(selectedCustomerProvider);
      
      final order = Order()
        ..totalAmount = cart.totalAmount
        ..sessionId = sessionId
        ..tenantId = session?.tenantId
        ..paymentMethod = cart.paymentMethod
        ..paymentSplits = cart.paymentSplits.isNotEmpty ? jsonEncode(cart.paymentSplits) : null
        ..customerId = selectedCustomer?.remoteId
        ..items = cart.items.map((e) => model.PosCartItem()
          ..productId = e.product.remoteId
          ..name = e.product.name
          ..quantity = e.quantity.toDouble()
          ..price = e.product.price
        ).toList()
        ..createdAt = DateTime.now();

      // Save order locally
      await _orderRepository.saveOrder(order);
      
      // Handle Credit Payment local update
      if (selectedCustomer?.remoteId != null) {
        if (cart.paymentMethod == 'CREDIT') {
          await _ref.read(customerRepositoryProvider).incrementLocalBalance(
            selectedCustomer!.remoteId!, 
            cart.totalAmount,
          );
        } else if (cart.paymentMethod == 'SPLIT' && cart.paymentSplits.containsKey('CREDIT')) {
          final creditAmount = cart.paymentSplits['CREDIT'] ?? 0.0;
          if (creditAmount > 0) {
            await _ref.read(customerRepositoryProvider).incrementLocalBalance(
              selectedCustomer!.remoteId!, 
              creditAmount,
            );
          }
        }
      }
      
      // Decrement stock locally (Real-time deduction as per PRD)
      for (final item in cart.items) {
        if (item.product.remoteId != null) {
          await _productRepository.decrementStock(item.product.remoteId!, item.quantity.toDouble());
        }
      }
      
      _cartNotifier.clearCart();
      _ref.read(selectedCustomerProvider.notifier).state = null;
      state = const AsyncData(null);
      return order;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
