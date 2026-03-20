import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/promotions/data/models/promotion.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addProduct(Product product) {
    if (product.unitType != 'piece') {
      // Weight/volume/length items always add as a new line (no aggregation)
      final newItems = [...state.items, CartItem(product: product, quantity: 1.0)];
      state = state.copyWith(items: newItems);
      return;
    }
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      // Increment quantity
      newItems = List.from(state.items);
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      // Add new item
      newItems = [...state.items, CartItem(product: product, quantity: 1.0)];
    }

    state = state.copyWith(items: newItems);
  }

  /// Add a weight/volume/length product with an explicit quantity.
  void addProductWithQuantity(Product product, double quantity) {
    final newItems = [...state.items, CartItem(product: product, quantity: quantity)];
    state = state.copyWith(items: newItems);
  }

  /// AC2 (Story 25-3) — Add a product variant to the cart with its own price and label.
  void addProductWithVariant(Product product, ProductVariant variant, [double quantity = 1.0]) {
    final label = variant.attributes.entries.map((e) => '${e.key} ${e.value}').join(', ');
    // Each variant is a distinct line (no aggregation with other variants or the base product)
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.variantId == variant.id,
    );
    List<CartItem> newItems;
    if (existingIndex >= 0) {
      newItems = List.from(state.items);
      final existing = newItems[existingIndex];
      newItems[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      newItems = [
        ...state.items,
        CartItem(
          product: product,
          quantity: quantity,
          variantId: variant.id,
          variantLabel: label,
          variantPrice: variant.price,
        ),
      ];
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

  /// AC3/AC4 (Story 25-7) — Add a product with a promotion pre-applied.
  /// Handles PERCENT, CROSSED_PRICE (discount on item) and BUY_N_GET_M (free item line).
  void addProductWithPromo(Product product, Promotion promo) {
    final items = List<CartItem>.from(state.items);

    if (promo.type == 'BUY_N_GET_M') {
      // Add regular item
      final existingIndex =
          items.indexWhere((i) => i.product.id == product.id && !i.isFreeItem);
      if (existingIndex >= 0) {
        items[existingIndex] =
            items[existingIndex].copyWith(quantity: items[existingIndex].quantity + 1);
      } else {
        items.add(CartItem(
          product: product,
          quantity: 1,
          appliedPromoId: promo.id,
          appliedPromoLabel: promo.typeLabel,
        ));
      }
      _recalculateFreeItems(items, product, promo);
    } else {
      // PERCENT or CROSSED_PRICE — apply as discount on the line
      final basePrice = product.price;
      final disc = promo.discountAmount(basePrice, 1);
      final discType = promo.type == 'PERCENT' ? 'PERCENTAGE' : 'FIXED';
      final discValue = promo.type == 'PERCENT'
          ? (promo.value['percent'] as num?)?.toDouble() ?? 0
          : disc;

      final existingIndex =
          items.indexWhere((i) => i.product.id == product.id && !i.isFreeItem);
      if (existingIndex >= 0) {
        items[existingIndex] =
            items[existingIndex].copyWith(quantity: items[existingIndex].quantity + 1);
      } else {
        items.add(CartItem(
          product: product,
          quantity: 1,
          discountAmount: discValue,
          discountType: discType,
          appliedPromoId: promo.id,
          appliedPromoLabel: promo.typeLabel,
        ));
      }
    }

    state = state.copyWith(items: items);
  }

  void _recalculateFreeItems(
      List<CartItem> items, Product product, Promotion promo) {
    final buyN = (promo.value['buyN'] as num?)?.toInt() ?? 1;
    final getM = (promo.value['getM'] as num?)?.toInt() ?? 1;

    final regularQty = items
        .where((i) => i.product.id == product.id && !i.isFreeItem)
        .fold(0.0, (sum, i) => sum + i.quantity);

    final freeQty = (regularQty / buyN).floor() * getM;

    // Remove existing free line, then re-add if needed
    items.removeWhere((i) => i.product.id == product.id && i.isFreeItem);
    if (freeQty > 0) {
      items.add(CartItem(
        product: product,
        quantity: freeQty.toDouble(),
        isFreeItem: true,
        appliedPromoId: promo.id,
        appliedPromoLabel: promo.typeLabel,
      ));
    }
  }

  /// AC4 (Story 25-5) — Apply a forced price level to a cart line item.
  void applyPriceLevel(int index, PriceLevel level) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = List<CartItem>.from(state.items);
    newItems[index] = newItems[index].copyWith(
      forcedPriceLevelCode: level.levelCode,
      appliedPriceLevelLabel: level.label,
      overridePrice: level.price,
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
