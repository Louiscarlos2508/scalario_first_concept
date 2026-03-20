import 'package:isar/isar.dart';

part 'cart_item.g.dart';

@embedded
class PosCartItem {
  String? productId;
  String? name;
  double quantity = 1;
  double price = 0;
  double discountAmount = 0;
  String discountType = 'FIXED';

  // Epic 20 — unit type support
  String? unitType;   // 'piece' | 'weight' | 'volume' | 'length'
  String? unitLabel;  // 'kg', 'g', 'L', 'm', …
  double? pricePerUnit;
  String? catalogItemId;

  // Epic 25 — Variant
  String? variantId;
  String? variantLabel;

  // Epic 26 — Serial number tracking
  String? serialNumber;

  // Calculate total price for this item
  double get subtotal => quantity * price;

  double get total {
    if (discountType == 'PERCENTAGE') {
      return subtotal * (1 - (discountAmount / 100));
    }
    return (subtotal - discountAmount).clamp(0.0, double.infinity);
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (catalogItemId != null) 'catalogItemId': catalogItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'discountAmount': discountAmount,
      'discountType': discountType,
      if (unitType != null) 'unitType': unitType,
      if (unitLabel != null) 'unitLabel': unitLabel,
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      if (variantId != null) 'variantId': variantId,
      if (variantLabel != null) 'variantLabel': variantLabel,
      if (serialNumber != null) 'serialNumber': serialNumber,
    };
  }
}
