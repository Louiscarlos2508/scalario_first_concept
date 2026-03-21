import 'package:isar/isar.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';

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

  // Epic 20 — Vente au poids + unités configurables
  String unitType = 'piece'; // 'piece' | 'weight' | 'volume' | 'length'
  double? pricePerUnit;
  double? conversionRate;

  // Epic 23 — Parent-child reconditionnement
  @ignore
  String? parentItemId;
  @ignore
  bool hasChildren = false;

  // Epic 24 — Fraîcheur + code couleur
  @ignore
  DateTime? nearestExpiryDate;
  @ignore
  int? expiryDays;

  // Epic 25 — Variantes
  @ignore
  bool hasVariants = false;

  // Epic 26 — Traçabilité
  @ignore
  bool trackSerialNumbers = false;
  @ignore
  int? warrantyMonths;
  @ignore
  bool requiresPrescription = false;
  @ignore
  bool dynamicPricing = false;
  @ignore
  bool isUnique = false;
  @ignore
  List<ProductVariant> variants = [];
  @ignore
  List<PriceLevel> priceLevels = [];

  // Photo produit
  @ignore
  String? imageUrl;

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
      'unitType': unitType,
      'pricePerUnit': pricePerUnit,
      'conversionRate': conversionRate,
      'parentItemId': parentItemId,
      'imageUrl': imageUrl,
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
        ..unitType = json['unitType']?.toString() ??
            json['unit_type']?.toString() ??
            'piece'
        ..pricePerUnit = json['pricePerUnit'] != null
            ? _toDouble(json['pricePerUnit'])
            : (json['price_per_unit'] != null
                ? _toDouble(json['price_per_unit'])
                : null)
        ..conversionRate = json['conversionRate'] != null
            ? _toDouble(json['conversionRate'])
            : (json['conversion_rate'] != null
                ? _toDouble(json['conversion_rate'])
                : null)
        ..parentItemId = json['parentItemId']?.toString() ??
            json['parent_item_id']?.toString()
        ..nearestExpiryDate = json['nearestExpiryDate'] != null
            ? DateTime.tryParse(json['nearestExpiryDate'].toString())
            : (json['nearest_expiry_date'] != null
                ? DateTime.tryParse(json['nearest_expiry_date'].toString())
                : null)
        ..expiryDays = json['expiryDays'] as int? ?? json['expiry_days'] as int?
        ..hasVariants = json['hasVariants'] ?? json['has_variants'] ?? false
        ..trackSerialNumbers = json['trackSerialNumbers'] ?? json['track_serial_numbers'] ?? false
        ..warrantyMonths = json['warrantyMonths'] as int? ?? json['warranty_months'] as int?
        ..requiresPrescription = json['requiresPrescription'] ?? json['requires_prescription'] ?? false
        ..dynamicPricing = json['dynamicPricing'] ?? json['dynamic_pricing'] ?? false
        ..isUnique = json['isUnique'] ?? json['is_unique'] ?? false
        ..variants = (json['variants'] as List<dynamic>?)
                ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
                .toList() ??
            []
        ..priceLevels = (json['priceLevels'] as List<dynamic>?)
                ?.map((p) => PriceLevel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            []
        ..imageUrl = json['imageUrl']?.toString() ?? json['image_url']?.toString()
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
