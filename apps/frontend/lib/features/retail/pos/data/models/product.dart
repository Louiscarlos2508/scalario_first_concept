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
  String? category; // Name (legacy/convenience)
  String? categoryId; // UUID
  String? barcode;
  double stockQuantity = 0;
  String? tenantId;

  // CatalogItem + RetailProduct shape (added Story 8.2)
  String? itemType; // 'physical', 'service', etc.
  double? minStockLevel;
  String? weightUnit;

  DateTime? lastUpdated;
  bool isDeleted = false;

  Map<String, dynamic> toJson() {
    return {
      'remoteId': remoteId,
      'name': name,
      'price': price,
      'category': category,
      'categoryId': categoryId,
      'barcode': barcode,
      'stockQuantity': stockQuantity,
      'tenantId': tenantId,
      'itemType': itemType,
      'minStockLevel': minStockLevel,
      'weightUnit': weightUnit,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product()
        ..remoteId = json['id']?.toString()
        ..name = json['name']?.toString() ?? 'Unknown'
        ..price = _toDouble(json['price'])
        ..category = json['category'] != null
            ? (json['category'] is Map
                ? json['category']['name']
                : json['category'].toString())
            : null
        ..categoryId =
            json['categoryId']?.toString() ?? json['category_id']?.toString()
        ..barcode = json['barcode']?.toString()
        ..stockQuantity =
            _toDouble(json['stockQuantity'] ?? json['stock_quantity'])
        ..tenantId = (json['tenantId'] ?? json['tenant_id'])?.toString()
        ..itemType = json['itemType']?.toString() ??
            json['item_type']?.toString() ??
            'physical'
        ..minStockLevel = json['minStockLevel'] != null
            ? _toDouble(json['minStockLevel'])
            : (json['min_stock_level'] != null
                ? _toDouble(json['min_stock_level'])
                : null)
        ..weightUnit =
            json['weightUnit']?.toString() ?? json['weight_unit']?.toString()
        ..isDeleted = json['isDeleted'] ?? json['is_deleted'] ?? false
        ..lastUpdated = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null;
    } catch (e) {
      print('Mapping error in Product.fromJson: $e for JSON: $json');
      rethrow;
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
