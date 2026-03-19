import 'package:frontend/features/retail/pos/data/models/product.dart';

class CartItem {
  final Product product;
  final double quantity;
  final double discountAmount;
  final String discountType; // 'FIXED', 'PERCENTAGE'

  CartItem({
    required this.product,
    required this.quantity,
    this.discountAmount = 0.0,
    this.discountType = 'FIXED',
  });

  /// Effective unit price: pricePerUnit for weight/volume/length, price for piece.
  double get unitPrice =>
      (product.unitType != 'piece' && product.pricePerUnit != null)
          ? product.pricePerUnit!
          : product.price;

  double get subtotal => unitPrice * quantity;

  double get total {
    final raw = discountType == 'PERCENTAGE'
        ? subtotal * (1 - (discountAmount / 100))
        : (subtotal - discountAmount).clamp(0.0, double.infinity);
    // Round to nearest 5 FCFA
    return (raw / 5).round() * 5.0;
  }

  CartItem copyWith({
    Product? product,
    double? quantity,
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
