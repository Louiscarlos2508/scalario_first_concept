import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/prescription_input_dialog.dart';

class CartItem {
  final Product product;
  final double quantity;
  final double discountAmount;
  final String discountType; // 'FIXED', 'PERCENTAGE'
  // Epic 25 — Variant
  final String? variantId;
  final String? variantLabel; // e.g. "Taille M, Bleu"
  final double? variantPrice;
  // Epic 25 — Price level override
  final String? forcedPriceLevelCode;
  final String? appliedPriceLevelLabel;
  final double? overridePrice;
  // Epic 25 — Promotion
  final String? appliedPromoId;
  final String? appliedPromoLabel; // e.g. "Remise 20%"
  final bool isFreeItem; // true for BUY_N_GET_M free item lines
  // Epic 26 — Serial number tracking
  final String? serialNumber;

  CartItem({
    required this.product,
    required this.quantity,
    this.discountAmount = 0.0,
    this.discountType = 'FIXED',
    this.variantId,
    this.variantLabel,
    this.variantPrice,
    this.forcedPriceLevelCode,
    this.appliedPriceLevelLabel,
    this.overridePrice,
    this.appliedPromoId,
    this.appliedPromoLabel,
    this.isFreeItem = false,
    this.serialNumber,
  });

  /// Effective unit price: overridePrice (price level) > variantPrice > pricePerUnit > product.price.
  double get unitPrice {
    if (overridePrice != null) return overridePrice!;
    if (variantPrice != null) return variantPrice!;
    return (product.unitType != 'piece' && product.pricePerUnit != null)
        ? product.pricePerUnit!
        : product.price;
  }

  double get subtotal => unitPrice * quantity;

  double get total {
    if (isFreeItem) return 0.0;
    final raw = discountType == 'PERCENTAGE'
        ? subtotal * (1 - (discountAmount / 100))
        : (subtotal - discountAmount).clamp(0.0, double.infinity);
    // Round to nearest 5 FCFA
    return (raw / 5).round() * 5.0;
  }

  /// Original subtotal before any discount (for strikethrough display).
  double get originalSubtotal => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? discountAmount,
    String? discountType,
    String? variantId,
    String? variantLabel,
    double? variantPrice,
    String? forcedPriceLevelCode,
    String? appliedPriceLevelLabel,
    double? overridePrice,
    String? appliedPromoId,
    String? appliedPromoLabel,
    bool? isFreeItem,
    String? serialNumber,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      variantId: variantId ?? this.variantId,
      variantLabel: variantLabel ?? this.variantLabel,
      variantPrice: variantPrice ?? this.variantPrice,
      forcedPriceLevelCode: forcedPriceLevelCode ?? this.forcedPriceLevelCode,
      appliedPriceLevelLabel: appliedPriceLevelLabel ?? this.appliedPriceLevelLabel,
      overridePrice: overridePrice ?? this.overridePrice,
      appliedPromoId: appliedPromoId ?? this.appliedPromoId,
      appliedPromoLabel: appliedPromoLabel ?? this.appliedPromoLabel,
      isFreeItem: isFreeItem ?? this.isFreeItem,
      serialNumber: serialNumber ?? this.serialNumber,
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
  // Epic 26 — Prescription data (FR94)
  final PrescriptionData? prescriptionData;

  CartState({
    this.id,
    this.items = const [],
    this.paymentMethod = 'CASH',
    this.paymentSplits = const {},
    this.name,
    this.createdAt,
    this.prescriptionData,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  CartState copyWith({
    int? id,
    List<CartItem>? items,
    String? paymentMethod,
    Map<String, double>? paymentSplits,
    String? name,
    DateTime? createdAt,
    PrescriptionData? prescriptionData,
  }) {
    return CartState(
      id: id ?? this.id,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentSplits: paymentSplits ?? this.paymentSplits,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      prescriptionData: prescriptionData ?? this.prescriptionData,
    );
  }
}
