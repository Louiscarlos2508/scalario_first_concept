import 'package:frontend/features/pos/data/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double discountAmount;
  final String discountType; // 'FIXED', 'PERCENTAGE'

  CartItem({
    required this.product,
    required this.quantity,
    this.discountAmount = 0.0,
    this.discountType = 'FIXED',
  });

  double get subtotal => product.price * quantity;

  double get total {
    if (discountType == 'PERCENTAGE') {
      return subtotal * (1 - (discountAmount / 100));
    }
    return (subtotal - discountAmount).clamp(0.0, double.infinity);
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discountAmount,
    String? discountType,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
    );
  }
}

class CartState {
  final int? id; // Isar ID for parked carts
  final List<CartItem> items;
  final String paymentMethod;
  final Map<String, double> paymentSplits;
  final String? name; // For parked carts
  final DateTime? createdAt;

  CartState({
    this.id,
    this.items = const [],
    this.paymentMethod = 'CASH',
    this.paymentSplits = const {},
    this.name,
    this.createdAt,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  CartState copyWith({
    int? id,
    List<CartItem>? items,
    String? paymentMethod,
    Map<String, double>? paymentSplits,
    String? name,
    DateTime? createdAt,
  }) {
    return CartState(
      id: id ?? this.id,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentSplits: paymentSplits ?? this.paymentSplits,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
