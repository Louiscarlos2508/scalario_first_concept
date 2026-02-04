import 'package:frontend/features/pos/data/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}
