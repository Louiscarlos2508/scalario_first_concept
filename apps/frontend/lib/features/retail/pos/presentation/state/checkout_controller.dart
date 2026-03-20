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
      final session = _ref.read(sessionProvider).valueOrNull;
      final selectedCustomer = _ref.read(selectedCustomerProvider);
      
      final order = Order()
        ..totalAmount = cart.totalAmount
        ..sessionId = sessionId
        ..tenantId = session?.tenantId
        ..paymentMethod = cart.paymentMethod
        ..paymentSplits = cart.paymentSplits.isNotEmpty ? jsonEncode(cart.paymentSplits) : null
        ..customerId = selectedCustomer?.remoteId
        ..items = cart.items.map((e) {
          final isWeighted = e.product.unitType != 'piece';
          final effectivePrice = isWeighted && e.product.pricePerUnit != null
              ? e.product.pricePerUnit! * e.quantity
              : e.product.price * e.quantity;
          return model.PosCartItem()
            ..productId = e.product.remoteId
            ..catalogItemId = e.product.remoteId
            ..name = e.variantLabel != null ? '${e.product.name} — ${e.variantLabel}' : e.product.name
            ..quantity = e.quantity
            ..price = effectivePrice / e.quantity // unit price for receipt
            ..unitType = e.product.unitType
            ..unitLabel = isWeighted ? (e.product.weightUnit ?? e.product.unitType) : null
            ..pricePerUnit = isWeighted ? e.product.pricePerUnit : null
            ..variantId = e.variantId
            ..variantLabel = e.variantLabel
            ..serialNumber = e.serialNumber;
        }).toList()
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

      // AC4 — Decrement parent stock locally for child items
      String? parentStockWarning;
      for (final item in cart.items) {
        final parentId = item.product.parentItemId;
        final convRate = item.product.conversionRate ?? 1.0;
        if (parentId == null) continue;
        final parentQty = item.quantity * convRate;
        await _productRepository.decrementStock(parentId, parentQty);
        // AC2 — check if parent stock dropped below minStockLevel
        final parentProduct = await _productRepository.getProductById(parentId);
        if (parentProduct != null &&
            parentProduct.minStockLevel != null &&
            parentProduct.stockQuantity <= parentProduct.minStockLevel!) {
          parentStockWarning =
              'Stock faible : ${parentProduct.name} — ${parentProduct.stockQuantity.toStringAsFixed(2)} restant(s)';
        }
      }

      if (parentStockWarning != null) {
        _ref.read(parentStockWarningProvider.notifier).state = parentStockWarning;
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
