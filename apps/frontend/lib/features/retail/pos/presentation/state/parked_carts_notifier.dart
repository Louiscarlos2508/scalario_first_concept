import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/parked_cart.dart';
import 'package:frontend/features/retail/pos/data/models/cart_item.dart' as model;
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'cart_state.dart';

class ParkedCartsNotifier extends StateNotifier<List<CartState>> {
  final IsarService _isarService;

  ParkedCartsNotifier(this._isarService) : super([]) {
    loadCarts();
  }

  Future<void> loadCarts() async {
    final parked = await _isarService.getAllParkedCarts();
    state = parked.map((p) => CartState(
      name: p.name,
      createdAt: p.createdAt,
      paymentMethod: p.paymentMethod ?? 'CASH',
      items: p.items.map((i) => CartItem(
        product: Product()
          ..remoteId = i.productId
          ..name = i.name!
          ..price = i.price,
        quantity: i.quantity.toInt(),
        discountAmount: i.discountAmount,
        discountType: i.discountType,
      )).toList(),
      id: p.id,
    )).toList();
  }

  Future<void> parkCart(CartState cart, String name) async {
    if (cart.items.isEmpty) return;
    
    final parkedModel = ParkedCart()
      ..name = name
      ..createdAt = DateTime.now()
      ..paymentMethod = cart.paymentMethod
      ..totalAmount = cart.totalAmount
      ..items = cart.items.map((i) => model.PosCartItem()
        ..productId = i.product.remoteId
        ..name = i.product.name
        ..quantity = i.quantity.toDouble()
        ..price = i.product.price
        ..discountAmount = i.discountAmount
        ..discountType = i.discountType
      ).toList();

    await _isarService.saveParkedCart(parkedModel);
    await loadCarts();
  }

  Future<void> removeParkedCart(CartState cart) async {
    if (cart.id != null) {
      await _isarService.deleteParkedCart(cart.id!);
      await loadCarts();
    }
  }
}
