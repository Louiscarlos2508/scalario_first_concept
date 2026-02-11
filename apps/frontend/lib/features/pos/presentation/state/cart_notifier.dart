import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      // Increment quantity
      newItems = List.from(state.items);
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      // Add new item
      newItems = [...state.items, CartItem(product: product, quantity: 1)];
    }

    state = state.copyWith(items: newItems);
  }

  void removeProduct(Product product) {
     final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
     if (existingIndex == -1) return;

     List<CartItem> newItems = List.from(state.items);
     final existingItem = newItems[existingIndex];

     if (existingItem.quantity > 1) {
       newItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity - 1);
     } else {
       newItems.removeAt(existingIndex);
     }

     state = state.copyWith(items: newItems);
  }

  void updateItemDiscount(String productId, double discount, String type) {
    final index = state.items.indexWhere((item) => item.product.remoteId == productId);
    if (index == -1) return;

    final newItems = List<CartItem>.from(state.items);
    newItems[index] = newItems[index].copyWith(
      discountAmount: discount,
      discountType: type,
    );

    state = state.copyWith(items: newItems);
  }

  void replaceCart(CartState newState) {
    state = newState;
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void updatePaymentSplits(Map<String, double> splits) {
    state = state.copyWith(paymentSplits: splits);
  }

  void clearCart() {
    state = state.copyWith(items: [], name: null, createdAt: null);
  }
}
