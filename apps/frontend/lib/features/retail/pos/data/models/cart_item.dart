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
      'name': name,
      'quantity': quantity,
      'price': price,
      'discountAmount': discountAmount,
      'discountType': discountType,
    };
  }
}
