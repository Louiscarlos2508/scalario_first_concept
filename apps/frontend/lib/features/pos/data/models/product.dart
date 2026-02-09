import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Product();

  Id id = Isar.autoIncrement; // local ID

  // Removed Index for Web compatibility (Isar generator has issues with 64-bit int literals in JS)
  // @Index(unique: true, replace: true) 
  String? remoteId; // UUID from Supabase

  late String name;
  late double price;
  String? category;
  double stockQuantity = 0;
  String? tenantId;

  Map<String, dynamic> toJson() {
    return {
      'remoteId': remoteId,
      'name': name,
      'price': price,
      'category': category,
      'stockQuantity': stockQuantity,
      'tenantId': tenantId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product()
      ..remoteId = json['id'] as String?
      ..name = json['name'] as String
      ..price = (json['price'] is num) ? (json['price'] as num).toDouble() : double.parse(json['price'].toString())
      ..category = json['category'] as String?
      ..stockQuantity = (json['stock_quantity'] is num) ? (json['stock_quantity'] as num).toDouble() : double.parse(json['stock_quantity']?.toString() ?? '0')
      ..tenantId = json['tenant_id'] as String?;
  }
}
