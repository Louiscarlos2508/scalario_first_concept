class ProductVariant {
  final String id;
  final String catalogItemId;
  final String? sku;
  final String? barcode;
  final double price;
  final double stockQuantity;
  final Map<String, String> attributes;
  final bool isActive;

  const ProductVariant({
    required this.id,
    required this.catalogItemId,
    this.sku,
    this.barcode,
    required this.price,
    required this.stockQuantity,
    required this.attributes,
    this.isActive = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['attributes'];
    final Map<String, String> attrs = {};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) => attrs[k.toString()] = v.toString());
    }
    return ProductVariant(
      id: json['id'].toString(),
      catalogItemId: (json['catalogItemId'] ?? json['catalog_item_id']).toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      price: _toDouble(json['price']),
      stockQuantity: _toDouble(json['stockQuantity'] ?? json['stock_quantity']),
      attributes: attrs,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'catalogItemId': catalogItemId,
        'sku': sku,
        'barcode': barcode,
        'price': price,
        'stockQuantity': stockQuantity,
        'attributes': attributes,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
